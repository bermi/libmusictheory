const counterpoint = @import("counterpoint.zig");

pub const MAX_VOICE_PAIR_VIOLATIONS: usize = (counterpoint.MAX_VOICES * (counterpoint.MAX_VOICES - 1)) / 2;

pub const ViolationKind = enum(u8) {
    parallel_fifth,
    parallel_octave_or_unison,
    voice_crossing,
    upper_spacing,
};

pub const VIOLATION_KIND_NAMES = [_][]const u8{
    "parallel-fifth",
    "parallel-octave-or-unison",
    "voice-crossing",
    "upper-spacing",
};

pub const VoicePairViolation = struct {
    kind: ViolationKind,
    lower_voice_id: u8,
    upper_voice_id: u8,
    previous_interval_semitones: i8,
    current_interval_semitones: i8,
};

pub const MotionIndependenceSummary = struct {
    collapsed: bool,
    direction: i8,
    moving_voice_count: u8,
    stationary_voice_count: u8,
    ascending_count: u8,
    descending_count: u8,
    retained_voice_count: u8,

    pub fn init() MotionIndependenceSummary {
        return .{
            .collapsed = false,
            .direction = 0,
            .moving_voice_count = 0,
            .stationary_voice_count = 0,
            .ascending_count = 0,
            .descending_count = 0,
            .retained_voice_count = 0,
        };
    }
};

pub fn detectParallelPerfects(
    previous: *const counterpoint.VoicedState,
    current: *const counterpoint.VoicedState,
    out: []VoicePairViolation,
) u8 {
    const summary = counterpoint.classifyMotion(previous, current);
    var total: u8 = 0;
    var written: usize = 0;

    const retained = summary.voice_motions[0..summary.voice_motion_count];
    for (retained, 0..) |a, i| {
        var j: usize = i + 1;
        while (j < retained.len) : (j += 1) {
            const ordered = orderPair(a, retained[j]);
            const lower = ordered[0];
            const upper = ordered[1];
            if (!sameNonZeroDirection(lower.delta, upper.delta)) continue;

            const before_interval = @as(i16, upper.from_midi) - @as(i16, lower.from_midi);
            const after_interval = @as(i16, upper.to_midi) - @as(i16, lower.to_midi);

            if (before_interval <= 0 or after_interval <= 0) continue;

            const kind = perfectParallelKind(before_interval, after_interval) orelse continue;
            appendViolation(out, &written, &total, .{
                .kind = kind,
                .lower_voice_id = lower.voice_id,
                .upper_voice_id = upper.voice_id,
                .previous_interval_semitones = @as(i8, @intCast(before_interval)),
                .current_interval_semitones = @as(i8, @intCast(after_interval)),
            });
        }
    }

    return total;
}

pub fn detectVoiceCrossings(
    previous: *const counterpoint.VoicedState,
    current: *const counterpoint.VoicedState,
    out: []VoicePairViolation,
) u8 {
    const summary = counterpoint.classifyMotion(previous, current);
    var total: u8 = 0;
    var written: usize = 0;

    const retained = summary.voice_motions[0..summary.voice_motion_count];
    for (retained, 0..) |a, i| {
        var j: usize = i + 1;
        while (j < retained.len) : (j += 1) {
            const ordered = orderPair(a, retained[j]);
            const lower = ordered[0];
            const upper = ordered[1];
            const after_interval = @as(i16, upper.to_midi) - @as(i16, lower.to_midi);
            if (after_interval >= 0) continue;

            const before_interval = @as(i16, upper.from_midi) - @as(i16, lower.from_midi);
            appendViolation(out, &written, &total, .{
                .kind = .voice_crossing,
                .lower_voice_id = lower.voice_id,
                .upper_voice_id = upper.voice_id,
                .previous_interval_semitones = @as(i8, @intCast(before_interval)),
                .current_interval_semitones = @as(i8, @intCast(after_interval)),
            });
        }
    }

    return total;
}

pub fn detectSpacingViolations(
    state: *const counterpoint.VoicedState,
    out: []VoicePairViolation,
) u8 {
    var total: u8 = 0;
    var written: usize = 0;

    const voices = state.slice();
    if (voices.len < 3) return 0;

    var lower_index: usize = 1;
    while (lower_index + 1 < voices.len) : (lower_index += 1) {
        const lower = voices[lower_index];
        const upper = voices[lower_index + 1];
        const span = @as(i16, upper.midi) - @as(i16, lower.midi);
        if (span <= 12) continue;

        appendViolation(out, &written, &total, .{
            .kind = .upper_spacing,
            .lower_voice_id = lower.id,
            .upper_voice_id = upper.id,
            .previous_interval_semitones = 0,
            .current_interval_semitones = @as(i8, @intCast(span)),
        });
    }

    return total;
}

pub fn detectMotionIndependence(
    previous: *const counterpoint.VoicedState,
    current: *const counterpoint.VoicedState,
) MotionIndependenceSummary {
    const summary = counterpoint.classifyMotion(previous, current);
    var out = MotionIndependenceSummary.init();
    out.retained_voice_count = summary.voice_motion_count;

    for (summary.voice_motions[0..summary.voice_motion_count]) |motion| {
        if (motion.delta > 0) {
            out.ascending_count += 1;
            out.moving_voice_count += 1;
        } else if (motion.delta < 0) {
            out.descending_count += 1;
            out.moving_voice_count += 1;
        } else {
            out.stationary_voice_count += 1;
        }
    }

    if (out.moving_voice_count < 2 or out.stationary_voice_count != 0) return out;

    if (out.ascending_count == out.moving_voice_count) {
        out.collapsed = true;
        out.direction = 1;
    } else if (out.descending_count == out.moving_voice_count) {
        out.collapsed = true;
        out.direction = -1;
    }

    return out;
}

fn appendViolation(out: []VoicePairViolation, written: *usize, total: *u8, violation: VoicePairViolation) void {
    total.* +%= 1;
    if (written.* >= out.len) return;
    out[written.*] = violation;
    written.* += 1;
}

fn sameNonZeroDirection(a: i8, b: i8) bool {
    if (a == 0 or b == 0) return false;
    return (a > 0 and b > 0) or (a < 0 and b < 0);
}

fn perfectParallelKind(before_interval: i16, after_interval: i16) ?ViolationKind {
    const before_class = @mod(before_interval, 12);
    const after_class = @mod(after_interval, 12);
    if (before_class == 7 and after_class == 7) return .parallel_fifth;
    if (before_class == 0 and after_class == 0) return .parallel_octave_or_unison;
    return null;
}

fn orderPair(a: counterpoint.VoiceMotion, b: counterpoint.VoiceMotion) [2]counterpoint.VoiceMotion {
    if (a.from_midi < b.from_midi) return .{ a, b };
    if (a.from_midi > b.from_midi) return .{ b, a };
    if (a.voice_id < b.voice_id) return .{ a, b };
    return .{ b, a };
}
