const std = @import("std");
const pitch = @import("../pitch.zig");
const types = @import("types.zig");
const topology = @import("keyboard_topology.zig");

pub const MAX_FINGERING_NOTES: usize = 5;
pub const MAX_RANKED_FINGERINGS: usize = 16;

pub const HandRole = enum(u8) {
    left = 0,
    right = 1,
};

pub const HAND_ROLE_NAMES = [_][]const u8{
    "left hand",
    "right hand",
};

pub const BlockerKind = enum(u8) {
    span_hard_limit = 0,
    note_count_exceeds_fingers = 1,
    shift_hard_limit = 2,
    impossible_thumb_crossing = 3,
};

pub const BLOCKER_NAMES = [_][]const u8{
    "span hard limit",
    "note count exceeds fingers",
    "shift hard limit",
    "impossible thumb crossing",
};

pub const RealizationAssessment = struct {
    state: topology.PlayState,
    hand: HandRole,
    note_count: u8,
    outer_black_count: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    recommended_fingers: [MAX_FINGERING_NOTES]u8,
};

pub const TransitionAssessment = struct {
    from_state: topology.PlayState,
    to_state: topology.PlayState,
    hand: HandRole,
    note_count: u8,
    anchor_delta_semitones: u8,
    reserved0: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    from_fingers: [MAX_FINGERING_NOTES]u8,
    to_fingers: [MAX_FINGERING_NOTES]u8,
};

pub const RankedFingering = struct {
    hand: HandRole,
    note_count: u8,
    reserved0: u8,
    reserved1: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    fingers: [MAX_FINGERING_NOTES]u8,
};

const BaseFlags = struct {
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
};

const MonophonicPair = struct {
    from_finger: u8,
    to_finger: u8,
    blocker_bits: u32,
    warning_bits: u32,
    cumulative_cost: u16,
    bottleneck_cost: u16,
};

pub fn fromInt(raw: u8) ?HandRole {
    return switch (raw) {
        0 => .left,
        1 => .right,
        else => null,
    };
}

pub fn assessRealization(
    notes: []const pitch.MidiNote,
    hand: HandRole,
    profile: types.HandProfile,
    previous_load: ?types.TemporalLoadState,
) RealizationAssessment {
    const state = topology.describeState(notes, profile, previous_load);
    const clipped_count = @as(u8, @intCast(@min(notes.len, MAX_FINGERING_NOTES)));
    var sorted_buf: [MAX_FINGERING_NOTES]pitch.MidiNote = [_]pitch.MidiNote{0} ** MAX_FINGERING_NOTES;
    const sorted = copySortedNotes(notes, &sorted_buf);
    const base = baseFlags(state, notes.len, profile);
    var ranked_buf: [MAX_RANKED_FINGERINGS]RankedFingering = undefined;
    const ranked = rankFingeringsWithState(sorted, hand, profile, state, base, ranked_buf[0..]);

    var outer_black_count: u8 = 0;
    if (sorted.len > 0) {
        if (topology.isBlackKey(@as(pitch.PitchClass, @intCast(sorted[0] % 12)))) outer_black_count += 1;
        if (sorted.len > 1 and topology.isBlackKey(@as(pitch.PitchClass, @intCast(sorted[sorted.len - 1] % 12)))) outer_black_count += 1;
    }

    var out = RealizationAssessment{
        .state = state,
        .hand = hand,
        .note_count = clipped_count,
        .outer_black_count = outer_black_count,
        .bottleneck_cost = @as(u16, state.span_semitones),
        .cumulative_cost = @as(u16, state.span_semitones),
        .blocker_bits = base.blocker_bits,
        .warning_bits = base.warning_bits,
        .reason_bits = base.reason_bits,
        .recommended_fingers = [_]u8{0} ** MAX_FINGERING_NOTES,
    };

    if (ranked.len > 0) {
        const best = ranked[0];
        out.bottleneck_cost = best.bottleneck_cost;
        out.cumulative_cost = best.cumulative_cost;
        out.blocker_bits |= best.blocker_bits;
        out.warning_bits |= best.warning_bits;
        out.reason_bits |= best.reason_bits;
        out.recommended_fingers = best.fingers;
    }

    return out;
}

pub fn assessTransition(
    from_notes: []const pitch.MidiNote,
    to_notes: []const pitch.MidiNote,
    hand: HandRole,
    profile: types.HandProfile,
    previous_load: ?types.TemporalLoadState,
) TransitionAssessment {
    const from_real = assessRealization(from_notes, hand, profile, previous_load);
    const to_real = assessRealization(to_notes, hand, profile, from_real.state.load);
    const anchor_delta: u8 = if (from_notes.len == 0 or to_notes.len == 0)
        0
    else
        @as(u8, @intCast(@abs(@as(i16, to_real.state.anchor_midi) - @as(i16, from_real.state.anchor_midi))));

    var blocker_bits: u32 = from_real.blocker_bits | to_real.blocker_bits;
    var warning_bits: u32 = from_real.warning_bits | to_real.warning_bits;
    const reason_bits: u32 = from_real.reason_bits | to_real.reason_bits;

    if (anchor_delta > 0) setWarning(&warning_bits, .shift_required);
    if (anchor_delta > profile.comfort_shift_steps) setWarning(&warning_bits, .excessive_longitudinal_shift);
    if (anchor_delta > profile.limit_shift_steps) {
        setWarning(&warning_bits, .hard_limit_exceeded);
        setBlocker(&blocker_bits, .shift_hard_limit);
    }
    if (from_real.state.span_semitones >= profile.comfort_span_steps and to_real.state.span_semitones >= profile.comfort_span_steps) {
        setWarning(&warning_bits, .repeated_maximal_stretch);
    }
    if (from_real.state.load.event_count > 1 and from_real.state.load.peak_shift_steps >= profile.comfort_shift_steps and anchor_delta > 0) {
        setWarning(&warning_bits, .fluency_degradation_from_recent_motion);
    }

    var out = TransitionAssessment{
        .from_state = from_real.state,
        .to_state = to_real.state,
        .hand = hand,
        .note_count = @as(u8, @intCast(@min(to_notes.len, MAX_FINGERING_NOTES))),
        .anchor_delta_semitones = anchor_delta,
        .reserved0 = 0,
        .bottleneck_cost = @max(@max(from_real.bottleneck_cost, to_real.bottleneck_cost), @as(u16, anchor_delta)),
        .cumulative_cost = from_real.cumulative_cost + to_real.cumulative_cost + @as(u16, anchor_delta),
        .blocker_bits = blocker_bits,
        .warning_bits = warning_bits,
        .reason_bits = reason_bits,
        .from_fingers = from_real.recommended_fingers,
        .to_fingers = to_real.recommended_fingers,
    };

    if (from_notes.len == 1 and to_notes.len == 1) {
        const pair = bestMonophonicPair(from_notes[0], to_notes[0], hand, profile);
        out.blocker_bits |= pair.blocker_bits;
        out.warning_bits |= pair.warning_bits;
        out.bottleneck_cost = @max(out.bottleneck_cost, pair.bottleneck_cost);
        out.cumulative_cost += pair.cumulative_cost;
        out.from_fingers[0] = pair.from_finger;
        out.to_fingers[0] = pair.to_finger;
    }

    return out;
}

pub fn rankFingerings(
    notes: []const pitch.MidiNote,
    hand: HandRole,
    profile: types.HandProfile,
    out: []RankedFingering,
) []RankedFingering {
    const state = topology.describeState(notes, profile, null);
    const base = baseFlags(state, notes.len, profile);
    var sorted_buf: [MAX_FINGERING_NOTES]pitch.MidiNote = [_]pitch.MidiNote{0} ** MAX_FINGERING_NOTES;
    const sorted = copySortedNotes(notes, &sorted_buf);
    return rankFingeringsWithState(sorted, hand, profile, state, base, out);
}

fn rankFingeringsWithState(
    sorted_notes: []const pitch.MidiNote,
    hand: HandRole,
    profile: types.HandProfile,
    state: topology.PlayState,
    base: BaseFlags,
    out: []RankedFingering,
) []RankedFingering {
    if (sorted_notes.len == 0 or out.len == 0) return out[0..0];

    var combo: [MAX_FINGERING_NOTES]u8 = [_]u8{0} ** MAX_FINGERING_NOTES;
    var count: usize = 0;

    const Context = struct {
        sorted_notes: []const pitch.MidiNote,
        hand: HandRole,
        profile: types.HandProfile,
        state: topology.PlayState,
        base: BaseFlags,
        out: []RankedFingering,
        count: *usize,
        combo: *[MAX_FINGERING_NOTES]u8,

        fn evaluate(self: *@This()) void {
            if (self.count.* >= self.out.len) return;

            var assigned: [MAX_FINGERING_NOTES]u8 = [_]u8{0} ** MAX_FINGERING_NOTES;
            if (self.hand == .right) {
                @memcpy(assigned[0..self.sorted_notes.len], self.combo[0..self.sorted_notes.len]);
            } else {
                var i: usize = 0;
                while (i < self.sorted_notes.len) : (i += 1) {
                    assigned[i] = self.combo[self.sorted_notes.len - 1 - i];
                }
            }

            self.out[self.count.*] = evaluateAssignment(self.sorted_notes, assigned, self.hand, self.profile, self.state, self.base);
            self.count.* += 1;
        }

        fn walk(self: *@This(), depth: usize, start_finger: u8) void {
            if (depth == self.sorted_notes.len) {
                self.evaluate();
                return;
            }

            const remaining = self.sorted_notes.len - depth;
            var finger = start_finger;
            const max_start = @as(u8, @intCast(6 - remaining));
            while (finger <= max_start) : (finger += 1) {
                self.combo[depth] = finger;
                self.walk(depth + 1, finger + 1);
            }
        }
    };

    var ctx = Context{
        .sorted_notes = sorted_notes,
        .hand = hand,
        .profile = profile,
        .state = state,
        .base = base,
        .out = out,
        .count = &count,
        .combo = &combo,
    };
    ctx.walk(0, 1);

    insertionSortRanked(out[0..count]);
    return out[0..count];
}

fn evaluateAssignment(
    sorted_notes: []const pitch.MidiNote,
    assigned: [MAX_FINGERING_NOTES]u8,
    hand: HandRole,
    profile: types.HandProfile,
    state: topology.PlayState,
    base: BaseFlags,
) RankedFingering {
    const blocker_bits = base.blocker_bits;
    var warning_bits = base.warning_bits;
    const reason_bits = base.reason_bits;
    var cumulative_cost: u16 = @as(u16, state.span_semitones);
    var bottleneck_cost: u16 = @as(u16, state.span_semitones);

    if (sorted_notes.len == 1) {
        const target = idealSingleFinger(topology.isBlackKey(@as(pitch.PitchClass, @intCast(sorted_notes[0] % 12))));
        const mismatch: u16 = @as(u16, absDiff(assigned[0], target));
        cumulative_cost += mismatch;
        bottleneck_cost = @max(bottleneck_cost, mismatch);
    } else {
        const outer_x = roundedKeyDelta(sorted_notes[0], sorted_notes[sorted_notes.len - 1]);
        const outer_gap: u16 = @as(u16, absDiff(assigned[sorted_notes.len - 1], assigned[0]));
        const outer_mismatch = absDiff(outer_x, outer_gap);
        cumulative_cost += outer_mismatch;
        bottleneck_cost = @max(bottleneck_cost, outer_mismatch);

        var i: usize = 0;
        while (i + 1 < sorted_notes.len) : (i += 1) {
            const step_x = roundedKeyDelta(sorted_notes[i], sorted_notes[i + 1]);
            const finger_gap: u16 = @as(u16, absDiff(assigned[i + 1], assigned[i]));
            const mismatch = absDiff(step_x, finger_gap);
            cumulative_cost += mismatch;
            bottleneck_cost = @max(bottleneck_cost, mismatch);

            if (isWeakPair(assigned[i], assigned[i + 1]) and step_x >= 2) {
                setWarning(&warning_bits, .weak_finger_stress);
                cumulative_cost += 1;
            }
        }
    }

    var i: usize = 0;
    while (i < sorted_notes.len) : (i += 1) {
        const is_black = topology.isBlackKey(@as(pitch.PitchClass, @intCast(sorted_notes[i] % 12)));
        if (assigned[i] == 1 and is_black and state.span_semitones >= @min(profile.comfort_span_steps, @as(u8, 6))) {
            setWarning(&warning_bits, .thumb_on_black_under_stretch);
            cumulative_cost += 2;
            bottleneck_cost = @max(bottleneck_cost, 2);
        }
    }

    return .{
        .hand = hand,
        .note_count = @as(u8, @intCast(sorted_notes.len)),
        .reserved0 = 0,
        .reserved1 = 0,
        .bottleneck_cost = bottleneck_cost,
        .cumulative_cost = cumulative_cost,
        .blocker_bits = blocker_bits,
        .warning_bits = warning_bits,
        .reason_bits = reason_bits,
        .fingers = assigned,
    };
}

fn bestMonophonicPair(
    from_note: pitch.MidiNote,
    to_note: pitch.MidiNote,
    hand: HandRole,
    _: types.HandProfile,
) MonophonicPair {
    var best: ?MonophonicPair = null;

    var from_finger: u8 = 1;
    while (from_finger <= 5) : (from_finger += 1) {
        var to_finger: u8 = 1;
        while (to_finger <= 5) : (to_finger += 1) {
            var blocker_bits: u32 = 0;
            var warning_bits: u32 = 0;
            var cumulative_cost: u16 = 0;
            var bottleneck_cost: u16 = 0;

            const interval_x = roundedKeyDelta(from_note, to_note);
            const finger_gap: u16 = @as(u16, absDiff(from_finger, to_finger));
            const gap_mismatch = absDiff(interval_x, finger_gap);
            cumulative_cost += gap_mismatch;
            bottleneck_cost = @max(bottleneck_cost, gap_mismatch);

            const direction = signedDirection(from_note, to_note);
            const finger_direction = signedFingerDirection(from_finger, to_finger);
            const natural = isNaturalMotion(hand, direction, finger_direction);
            if (direction != 0 and !natural) {
                setWarning(&warning_bits, .awkward_thumb_crossing);
                if (from_finger == 1 or to_finger == 1) {
                    cumulative_cost += 2;
                    bottleneck_cost = @max(bottleneck_cost, 2);
                } else {
                    setBlocker(&blocker_bits, .impossible_thumb_crossing);
                    cumulative_cost += 6;
                    bottleneck_cost = @max(bottleneck_cost, 6);
                }
            }

            if (direction == 0 and from_finger != to_finger) {
                cumulative_cost += 1;
            }
            if (interval_x <= 1 and finger_gap > 1) cumulative_cost += 1;
            if (interval_x >= 3 and finger_gap == 0) cumulative_cost += 2;
            if (isWeakPair(from_finger, to_finger) and interval_x >= 1) {
                setWarning(&warning_bits, .repeated_weak_adjacent_finger_sequence);
                cumulative_cost += 1;
            }
            if (to_finger == 1 and topology.isBlackKey(@as(pitch.PitchClass, @intCast(to_note % 12))) and interval_x >= 2) {
                setWarning(&warning_bits, .thumb_on_black_under_stretch);
                cumulative_cost += 2;
            }

            const candidate = MonophonicPair{
                .from_finger = from_finger,
                .to_finger = to_finger,
                .blocker_bits = blocker_bits,
                .warning_bits = warning_bits,
                .cumulative_cost = cumulative_cost,
                .bottleneck_cost = bottleneck_cost,
            };
            if (best == null or monophonicPairLessThan(candidate, best.?)) {
                best = candidate;
            }
        }
    }

    return best orelse .{
        .from_finger = 0,
        .to_finger = 0,
        .blocker_bits = 0,
        .warning_bits = 0,
        .cumulative_cost = 0,
        .bottleneck_cost = 0,
    };
}

fn baseFlags(state: topology.PlayState, note_count: usize, profile: types.HandProfile) BaseFlags {
    var blocker_bits: u32 = 0;
    var warning_bits: u32 = 0;
    var reason_bits: u32 = 0;

    if (note_count > 0) setReason(&reason_bits, .reachable_location);
    if (note_count > 0 and state.comfort_fit and note_count <= profile.finger_count) {
        setReason(&reason_bits, .reachable_in_current_window);
    }
    if (state.span_semitones > profile.comfort_span_steps) {
        setWarning(&warning_bits, .comfort_window_exceeded);
    }
    if (state.span_semitones > profile.limit_span_steps) {
        setWarning(&warning_bits, .hard_limit_exceeded);
        setBlocker(&blocker_bits, .span_hard_limit);
    }
    if (note_count > profile.finger_count or note_count > MAX_FINGERING_NOTES) {
        setBlocker(&blocker_bits, .note_count_exceeds_fingers);
    }
    if (state.load.event_count > 1 and state.load.last_shift_steps > profile.comfort_shift_steps) {
        setWarning(&warning_bits, .fluency_degradation_from_recent_motion);
    }

    return .{
        .blocker_bits = blocker_bits,
        .warning_bits = warning_bits,
        .reason_bits = reason_bits,
    };
}

fn copySortedNotes(notes: []const pitch.MidiNote, out: *[MAX_FINGERING_NOTES]pitch.MidiNote) []const pitch.MidiNote {
    const len = @min(notes.len, MAX_FINGERING_NOTES);
    if (len == 0) return out[0..0];
    @memcpy(out[0..len], notes[0..len]);
    std.sort.heap(pitch.MidiNote, out[0..len], {}, midiLessThan);
    return out[0..len];
}

fn insertionSortRanked(items: []RankedFingering) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        const value = items[i];
        var j = i;
        while (j > 0 and rankedLessThan(value, items[j - 1])) : (j -= 1) {
            items[j] = items[j - 1];
        }
        items[j] = value;
    }
}

fn rankedLessThan(a: RankedFingering, b: RankedFingering) bool {
    const a_blocked = a.blocker_bits != 0;
    const b_blocked = b.blocker_bits != 0;
    if (a_blocked != b_blocked) return !a_blocked;

    const a_warning_count = bitCount(a.warning_bits);
    const b_warning_count = bitCount(b.warning_bits);
    if (a_warning_count != b_warning_count) return a_warning_count < b_warning_count;
    if (a.bottleneck_cost != b.bottleneck_cost) return a.bottleneck_cost < b.bottleneck_cost;
    if (a.cumulative_cost != b.cumulative_cost) return a.cumulative_cost < b.cumulative_cost;

    var i: usize = 0;
    while (i < MAX_FINGERING_NOTES) : (i += 1) {
        if (a.fingers[i] != b.fingers[i]) return a.fingers[i] < b.fingers[i];
    }
    return false;
}

fn monophonicPairLessThan(a: MonophonicPair, b: MonophonicPair) bool {
    const a_blocked = a.blocker_bits != 0;
    const b_blocked = b.blocker_bits != 0;
    if (a_blocked != b_blocked) return !a_blocked;

    const a_warning_count = bitCount(a.warning_bits);
    const b_warning_count = bitCount(b.warning_bits);
    if (a_warning_count != b_warning_count) return a_warning_count < b_warning_count;
    if (a.bottleneck_cost != b.bottleneck_cost) return a.bottleneck_cost < b.bottleneck_cost;
    if (a.cumulative_cost != b.cumulative_cost) return a.cumulative_cost < b.cumulative_cost;
    if (a.from_finger != b.from_finger) return a.from_finger < b.from_finger;
    return a.to_finger < b.to_finger;
}

fn midiLessThan(_: void, a: pitch.MidiNote, b: pitch.MidiNote) bool {
    return a < b;
}

fn roundedKeyDelta(a: pitch.MidiNote, b: pitch.MidiNote) u16 {
    const a_coord = topology.keyCoord(a);
    const b_coord = topology.keyCoord(b);
    return @as(u16, @intFromFloat(@round(@abs(a_coord.x - b_coord.x))));
}

fn absDiff(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if (a >= b) a - b else b - a;
}

fn idealSingleFinger(is_black: bool) u8 {
    return if (is_black) 2 else 3;
}

fn bitCount(bits: u32) u8 {
    return @as(u8, @intCast(@popCount(bits)));
}

fn signedDirection(from_note: pitch.MidiNote, to_note: pitch.MidiNote) i8 {
    return if (to_note > from_note)
        1
    else if (to_note < from_note)
        -1
    else
        0;
}

fn signedFingerDirection(from_finger: u8, to_finger: u8) i8 {
    return if (to_finger > from_finger)
        1
    else if (to_finger < from_finger)
        -1
    else
        0;
}

fn isNaturalMotion(hand: HandRole, note_direction: i8, finger_direction: i8) bool {
    if (note_direction == 0) return finger_direction == 0;
    return switch (hand) {
        .right => finger_direction == note_direction,
        .left => finger_direction == -note_direction,
    };
}

fn isWeakPair(a: u8, b: u8) bool {
    return (a == 3 and b == 4) or (a == 4 and b == 3);
}

fn setReason(bits: *u32, kind: types.ReasonKind) void {
    bits.* |= @as(u32, 1) << @as(u5, @intCast(@intFromEnum(kind)));
}

fn setWarning(bits: *u32, kind: types.WarningKind) void {
    bits.* |= @as(u32, 1) << @as(u5, @intCast(@intFromEnum(kind)));
}

fn setBlocker(bits: *u32, kind: BlockerKind) void {
    bits.* |= @as(u32, 1) << @as(u5, @intCast(@intFromEnum(kind)));
}
