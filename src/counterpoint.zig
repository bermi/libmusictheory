const std = @import("std");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const mode = @import("mode.zig");
const key = @import("key.zig");
const keyboard = @import("keyboard.zig");
const cluster = @import("cluster.zig");
const evenness = @import("evenness.zig");

pub const MAX_VOICES: usize = 8;
pub const HISTORY_CAPACITY: usize = 4;
const ASSIGNMENT_COST_SCALE: i16 = 4;
const INSERT_DELETE_COST: i16 = 24;

pub const MetricPosition = struct {
    beat_in_bar: u8 = 0,
    beats_per_bar: u8 = 4,
    subdivision: u8 = 0,

    pub fn normalized(beat_in_bar: u8, beats_per_bar: u8, subdivision: u8) MetricPosition {
        const bar_beats = if (beats_per_bar == 0) 4 else beats_per_bar;
        return .{
            .beat_in_bar = beat_in_bar % bar_beats,
            .beats_per_bar = bar_beats,
            .subdivision = subdivision,
        };
    }
};

pub const CadenceState = enum(u8) {
    none,
    stable,
    pre_dominant,
    dominant,
    cadential_six_four,
    authentic_arrival,
    half_arrival,
    deceptive_pull,
};

pub const CadenceDestination = enum(u8) {
    stable_continuation,
    pre_dominant_arrival,
    dominant_arrival,
    authentic_arrival,
    half_arrival,
    deceptive_pull,
};

pub const SuspensionState = enum(u8) {
    none,
    preparation,
    suspension,
    resolution,
    unresolved,
};

pub const VoiceMotionClass = enum(u8) {
    stationary,
    step,
    leap,
};

pub const PairMotionClass = enum(u8) {
    none,
    contrary,
    similar,
    parallel,
    oblique,
};

pub const CounterpointRuleProfile = enum(u8) {
    species,
    tonal_chorale,
    modal_polyphony,
    jazz_close_leading,
    free_contemporary,
};

pub const VoiceMotion = struct {
    voice_id: u8,
    from_midi: pitch.MidiNote,
    to_midi: pitch.MidiNote,
    delta: i8,
    abs_delta: u8,
    motion_class: VoiceMotionClass,
    retained: bool,
};

pub const MotionSummary = struct {
    voice_motion_count: u8,
    common_tone_count: u8,
    step_count: u8,
    leap_count: u8,
    contrary_count: u8,
    similar_count: u8,
    parallel_count: u8,
    oblique_count: u8,
    crossing_count: u8,
    overlap_count: u8,
    total_motion: u16,
    outer_interval_before: i8,
    outer_interval_after: i8,
    outer_motion: PairMotionClass,
    previous_cadence_state: CadenceState,
    current_cadence_state: CadenceState,
    voice_motions: [MAX_VOICES]VoiceMotion,

    pub fn init() MotionSummary {
        return .{
            .voice_motion_count = 0,
            .common_tone_count = 0,
            .step_count = 0,
            .leap_count = 0,
            .contrary_count = 0,
            .similar_count = 0,
            .parallel_count = 0,
            .oblique_count = 0,
            .crossing_count = 0,
            .overlap_count = 0,
            .total_motion = 0,
            .outer_interval_before = 0,
            .outer_interval_after = 0,
            .outer_motion = .none,
            .previous_cadence_state = .none,
            .current_cadence_state = .none,
            .voice_motions = [_]VoiceMotion{emptyVoiceMotion()} ** MAX_VOICES,
        };
    }
};

pub const MotionEvaluation = struct {
    score: i32,
    preferred_score: i16,
    penalty_score: i16,
    cadence_score: i16,
    spacing_penalty: i16,
    leap_penalty: i16,
    disallowed_count: u8,
    disallowed: bool,
};

pub const MAX_CADENCE_DESTINATIONS: usize = 6;

pub const CADENCE_DESTINATION_NAMES = [_][]const u8{
    "stable-continuation",
    "pre-dominant-arrival",
    "dominant-arrival",
    "authentic-arrival",
    "half-arrival",
    "deceptive-pull",
};

pub const CadenceDestinationScore = struct {
    destination: CadenceDestination,
    score: i32,
    candidate_count: u8,
    warning_count: u8,
    current_match: bool,
    tension_bias: i8,
};

pub const SUSPENSION_STATE_NAMES = [_][]const u8{
    "none",
    "preparation",
    "suspension",
    "resolution",
    "unresolved",
};

pub const SuspensionMachineSummary = struct {
    state: SuspensionState,
    tracked_voice_id: u8,
    held_midi: u8,
    expected_resolution_midi: u8,
    resolution_direction: i8,
    obligation_count: u8,
    warning_count: u8,
    retained_count: u8,
    current_tension: i16,
    previous_tension: i16,
    candidate_resolution_count: u8,

    pub fn init() SuspensionMachineSummary {
        return .{
            .state = .none,
            .tracked_voice_id = 255,
            .held_midi = 255,
            .expected_resolution_midi = 255,
            .resolution_direction = 0,
            .obligation_count = 0,
            .warning_count = 0,
            .retained_count = 0,
            .current_tension = 0,
            .previous_tension = 0,
            .candidate_resolution_count = 0,
        };
    }
};

pub const MAX_NEXT_STEP_SUGGESTIONS: usize = 8;

pub const NEXT_STEP_REASON_MINIMAL_MOTION: u32 = 1 << 0;
pub const NEXT_STEP_REASON_CONTRARY_MOTION: u32 = 1 << 1;
pub const NEXT_STEP_REASON_COMMON_TONE_RETENTION: u32 = 1 << 2;
pub const NEXT_STEP_REASON_CADENCE_PULL: u32 = 1 << 3;
pub const NEXT_STEP_REASON_PRESERVES_SPACING: u32 = 1 << 4;
pub const NEXT_STEP_REASON_RELEASES_TENSION: u32 = 1 << 5;
pub const NEXT_STEP_REASON_BUILDS_TENSION: u32 = 1 << 6;
pub const NEXT_STEP_REASON_LEAP_COMPENSATION: u32 = 1 << 7;

pub const NEXT_STEP_WARNING_PARALLELS: u32 = 1 << 0;
pub const NEXT_STEP_WARNING_CROSSING: u32 = 1 << 1;
pub const NEXT_STEP_WARNING_OVERLAP: u32 = 1 << 2;
pub const NEXT_STEP_WARNING_WIDE_SPACING: u32 = 1 << 3;
pub const NEXT_STEP_WARNING_CONSECUTIVE_LEAP: u32 = 1 << 4;
pub const NEXT_STEP_WARNING_OUTSIDE_CONTEXT: u32 = 1 << 5;
pub const NEXT_STEP_WARNING_CLUSTER_PRESSURE: u32 = 1 << 6;

pub const NEXT_STEP_REASON_NAMES = [_][]const u8{
    "minimal-motion",
    "contrary-motion",
    "common-tone-retention",
    "cadence-pull",
    "preserves-spacing",
    "releases-tension",
    "builds-tension",
    "leap-compensation",
};

pub const NEXT_STEP_WARNING_NAMES = [_][]const u8{
    "parallels",
    "crossing",
    "overlap",
    "wide-spacing",
    "consecutive-leap",
    "outside-context",
    "cluster-pressure",
};

pub const NextStepSuggestion = struct {
    score: i32,
    reason_mask: u32,
    warning_mask: u32,
    cadence_effect: CadenceState,
    tension_delta: i8,
    note_count: u8,
    set_value: pcs.PitchClassSet,
    notes: [MAX_VOICES]pitch.MidiNote,
    motion: MotionSummary,
    evaluation: MotionEvaluation,
};

pub const Voice = struct {
    id: u8,
    midi: pitch.MidiNote,
    pitch_class: pitch.PitchClass,
    octave: i8,
    sustained: bool,
};

pub const VoicedState = struct {
    set_value: pcs.PitchClassSet,
    voice_count: u8,
    tonic: pitch.PitchClass,
    mode_type: mode.ModeType,
    key_quality: key.KeyQuality,
    metric: MetricPosition,
    cadence_state: CadenceState,
    state_index: u8,
    next_voice_id: u8,
    voices: [MAX_VOICES]Voice,

    pub fn initEmpty(tonic: pitch.PitchClass, mode_type: mode.ModeType, metric: MetricPosition) VoicedState {
        return .{
            .set_value = 0,
            .voice_count = 0,
            .tonic = tonic,
            .mode_type = mode_type,
            .key_quality = keyboard.modeSpellingQuality(tonic, mode_type),
            .metric = metric,
            .cadence_state = .none,
            .state_index = 0,
            .next_voice_id = 0,
            .voices = [_]Voice{emptyVoice()} ** MAX_VOICES,
        };
    }

    pub fn slice(self: *const VoicedState) []const Voice {
        return self.voices[0..self.voice_count];
    }
};

pub const VoicedHistoryWindow = struct {
    states: [HISTORY_CAPACITY]VoicedState,
    len: u8,
    next_voice_id: u8,

    pub fn init() VoicedHistoryWindow {
        return .{
            .states = [_]VoicedState{VoicedState.initEmpty(0, .ionian, MetricPosition.normalized(0, 4, 0))} ** HISTORY_CAPACITY,
            .len = 0,
            .next_voice_id = 0,
        };
    }

    pub fn reset(self: *VoicedHistoryWindow) void {
        self.* = init();
    }

    pub fn current(self: *const VoicedHistoryWindow) ?*const VoicedState {
        if (self.len == 0) return null;
        return &self.states[self.len - 1];
    }

    pub fn previous(self: *const VoicedHistoryWindow) ?*const VoicedState {
        if (self.len < 2) return null;
        return &self.states[self.len - 2];
    }

    pub fn push(
        self: *VoicedHistoryWindow,
        notes: []const pitch.MidiNote,
        sustained_notes: []const pitch.MidiNote,
        tonic: pitch.PitchClass,
        mode_type: mode.ModeType,
        metric: MetricPosition,
        cadence_hint: ?CadenceState,
    ) VoicedState {
        const prior = self.current();
        const next = buildVoicedState(notes, sustained_notes, tonic, mode_type, metric, cadence_hint, prior, self.next_voice_id);
        if (self.len < HISTORY_CAPACITY) {
            self.states[self.len] = next;
            self.len += 1;
        } else {
            var index: usize = 1;
            while (index < HISTORY_CAPACITY) : (index += 1) {
                self.states[index - 1] = self.states[index];
            }
            self.states[HISTORY_CAPACITY - 1] = next;
        }
        self.next_voice_id = next.next_voice_id;
        return next;
    }
};

pub fn buildVoicedState(
    notes: []const pitch.MidiNote,
    sustained_notes: []const pitch.MidiNote,
    tonic: pitch.PitchClass,
    mode_type: mode.ModeType,
    metric: MetricPosition,
    cadence_hint: ?CadenceState,
    previous: ?*const VoicedState,
    next_voice_id_seed: u8,
) VoicedState {
    var normalized_notes: [MAX_VOICES]pitch.MidiNote = [_]pitch.MidiNote{0} ** MAX_VOICES;
    var sustained_flags: [MAX_VOICES]bool = [_]bool{false} ** MAX_VOICES;
    const note_count = normalizeNotes(notes, sustained_notes, &normalized_notes, &sustained_flags);

    var state = VoicedState.initEmpty(tonic, mode_type, metric);
    state.key_quality = keyboard.modeSpellingQuality(tonic, mode_type);
    state.state_index = if (previous) |prev| prev.state_index + 1 else 0;
    state.set_value = keyboard.notesPitchClassSet(normalized_notes[0..note_count]);

    var assigned_ids: [MAX_VOICES]u8 = [_]u8{0} ** MAX_VOICES;
    state.next_voice_id = assignVoiceIds(normalized_notes[0..note_count], previous, next_voice_id_seed, &assigned_ids);
    state.voice_count = @as(u8, @intCast(note_count));

    var index: usize = 0;
    while (index < note_count) : (index += 1) {
        const midi = normalized_notes[index];
        state.voices[index] = .{
            .id = assigned_ids[index],
            .midi = midi,
            .pitch_class = pitch.midiToPC(midi),
            .octave = pitch.midiToOctave(midi),
            .sustained = sustained_flags[index],
        };
    }
    while (index < MAX_VOICES) : (index += 1) {
        state.voices[index] = emptyVoice();
    }

    state.cadence_state = cadence_hint orelse inferCadenceState(state.set_value, tonic, state.key_quality, metric);
    return state;
}

pub fn inferCadenceState(
    set_value: pcs.PitchClassSet,
    tonic: pitch.PitchClass,
    quality: key.KeyQuality,
    metric: MetricPosition,
) CadenceState {
    _ = quality;
    if (set_value == 0) return .none;

    const normalized = pcs.transposeDown(set_value, tonic);
    const has_root = containsPc(normalized, 0);
    const has_third = containsPc(normalized, 3) or containsPc(normalized, 4);
    const has_fourth = containsPc(normalized, 5);
    const has_second = containsPc(normalized, 2);
    const has_fifth = containsPc(normalized, 7);
    const has_leading = containsPc(normalized, 11);
    const on_strong_arrival = metric.beats_per_bar > 0 and metric.beat_in_bar + 1 == metric.beats_per_bar;

    if (has_fifth and has_fourth and containsPc(normalized, 0)) return .cadential_six_four;
    if (has_root and has_third and on_strong_arrival) return .authentic_arrival;
    if (has_fifth and has_leading) return .dominant;
    if (has_second and has_fourth) return .pre_dominant;
    if (has_fifth and on_strong_arrival) return .half_arrival;
    if (has_root and has_third) return .stable;
    return .none;
}

pub fn classifyMotion(previous: *const VoicedState, current: *const VoicedState) MotionSummary {
    var summary = MotionSummary.init();
    summary.previous_cadence_state = previous.cadence_state;
    summary.current_cadence_state = current.cadence_state;

    var retained: [MAX_VOICES]VoiceMotion = [_]VoiceMotion{emptyVoiceMotion()} ** MAX_VOICES;
    var retained_count: usize = 0;

    for (current.slice()) |current_voice| {
        if (findVoiceById(previous, current_voice.id)) |previous_voice| {
            const delta_wide = @as(i16, current_voice.midi) - @as(i16, previous_voice.midi);
            const abs_delta = @as(u8, @intCast(@abs(delta_wide)));
            const motion_class = classifyVoiceMotion(abs_delta);
            retained[retained_count] = .{
                .voice_id = current_voice.id,
                .from_midi = previous_voice.midi,
                .to_midi = current_voice.midi,
                .delta = std.math.cast(i8, delta_wide) orelse if (delta_wide < 0) std.math.minInt(i8) else std.math.maxInt(i8),
                .abs_delta = abs_delta,
                .motion_class = motion_class,
                .retained = true,
            };
            summary.voice_motions[retained_count] = retained[retained_count];
            summary.voice_motion_count += 1;
            summary.total_motion += abs_delta;
            switch (motion_class) {
                .stationary => summary.common_tone_count += 1,
                .step => summary.step_count += 1,
                .leap => summary.leap_count += 1,
            }
            retained_count += 1;
        }
    }

    if (retained_count >= 2) {
        const lower = lowestPreviousMotion(retained[0..retained_count]);
        const upper = highestPreviousMotion(retained[0..retained_count]);
        summary.outer_interval_before = @as(i8, @intCast(@as(i16, upper.from_midi) - @as(i16, lower.from_midi)));
        summary.outer_interval_after = @as(i8, @intCast(@as(i16, upper.to_midi) - @as(i16, lower.to_midi)));
        summary.outer_motion = classifyPairMotion(lower, upper);
    }

    var i: usize = 0;
    while (i < retained_count) : (i += 1) {
        var j: usize = i + 1;
        while (j < retained_count) : (j += 1) {
            const lower, const upper = orderPair(retained[i], retained[j]);
            switch (classifyPairMotion(lower, upper)) {
                .contrary => summary.contrary_count += 1,
                .similar => summary.similar_count += 1,
                .parallel => summary.parallel_count += 1,
                .oblique => summary.oblique_count += 1,
                .none => {},
            }
            if (isCrossing(lower, upper)) summary.crossing_count += 1;
            if (isOverlap(lower, upper)) summary.overlap_count += 1;
        }
    }

    return summary;
}

pub fn evaluateMotionProfile(summary: MotionSummary, profile: CounterpointRuleProfile) MotionEvaluation {
    const spec = profileSpec(profile);
    var preferred_score: i16 = 0;
    var penalty_score: i16 = 0;
    var cadence_score: i16 = 0;
    var spacing_penalty: i16 = 0;
    var leap_penalty: i16 = 0;
    var disallowed_count: u8 = 0;

    preferred_score += @as(i16, summary.contrary_count) * spec.contrary_weight;
    preferred_score += @as(i16, summary.oblique_count) * spec.oblique_weight;
    preferred_score += @as(i16, summary.common_tone_count) * spec.common_tone_weight;
    preferred_score += @as(i16, summary.similar_count) * spec.similar_weight;
    preferred_score += @as(i16, summary.parallel_count) * spec.parallel_weight;

    if (summary.parallel_count > 0 and spec.parallel_disallowed) {
        disallowed_count +%= summary.parallel_count;
    }
    if (summary.crossing_count > 0 and spec.crossing_disallowed) {
        disallowed_count +%= summary.crossing_count;
    }

    penalty_score += @as(i16, summary.crossing_count) * spec.crossing_penalty;
    penalty_score += @as(i16, summary.overlap_count) * spec.overlap_penalty;

    leap_penalty = @as(i16, summary.leap_count) * spec.leap_penalty;

    if (summary.outer_interval_after > spec.max_outer_interval) {
        spacing_penalty = (summary.outer_interval_after - spec.max_outer_interval) * spec.spacing_penalty;
    }

    cadence_score = cadenceTransitionBonus(spec, summary.previous_cadence_state, summary.current_cadence_state);

    return .{
        .score = preferred_score - penalty_score - spacing_penalty - leap_penalty + cadence_score,
        .preferred_score = preferred_score,
        .penalty_score = penalty_score,
        .cadence_score = cadence_score,
        .spacing_penalty = spacing_penalty,
        .leap_penalty = leap_penalty,
        .disallowed_count = disallowed_count,
        .disallowed = disallowed_count != 0,
    };
}

pub fn rankNextSteps(history: *const VoicedHistoryWindow, profile: CounterpointRuleProfile, out: []NextStepSuggestion) []NextStepSuggestion {
    if (out.len == 0) return out[0..0];
    const current = history.current() orelse return out[0..0];
    if (current.voice_count == 0) return out[0..0];

    var generated: [MAX_NEXT_STEP_SUGGESTIONS * 8]NextStepSuggestion = undefined;
    var generated_count: usize = 0;
    const context_set = keyboard.modeSet(current.tonic, current.mode_type);
    const next_metric = advanceMetric(current.metric);

    var note_buf: [MAX_VOICES]pitch.MidiNote = [_]pitch.MidiNote{0} ** MAX_VOICES;

    for (0..current.voice_count) |index| {
        for ([_]i8{ -2, -1, 1, 2 }) |delta| {
            const candidate = makeSingleVoiceCandidate(current, index, delta, &note_buf) orelse continue;
            appendRankedCandidate(history, profile, context_set, next_metric, candidate, &generated, &generated_count);
        }
    }

    if (current.voice_count >= 2) {
        const low_index: usize = 0;
        const high_index: usize = current.voice_count - 1;
        for ([_]i8{ 1, 2 }) |delta| {
            if (makeDoubleVoiceCandidate(current, low_index, delta, high_index, -delta, &note_buf)) |candidate| {
                appendRankedCandidate(history, profile, context_set, next_metric, candidate, &generated, &generated_count);
            }
            if (makeDoubleVoiceCandidate(current, low_index, -delta, high_index, delta, &note_buf)) |candidate| {
                appendRankedCandidate(history, profile, context_set, next_metric, candidate, &generated, &generated_count);
            }
            if (makeDoubleVoiceCandidate(current, low_index, delta, high_index, delta, &note_buf)) |candidate| {
                appendRankedCandidate(history, profile, context_set, next_metric, candidate, &generated, &generated_count);
            }
            if (makeDoubleVoiceCandidate(current, low_index, -delta, high_index, -delta, &note_buf)) |candidate| {
                appendRankedCandidate(history, profile, context_set, next_metric, candidate, &generated, &generated_count);
            }
        }
    }

    if (current.cadence_state == .dominant or current.cadence_state == .cadential_six_four) {
        if (makeCadentialResolutionCandidate(current, &note_buf)) |candidate| {
            appendRankedCandidate(history, profile, context_set, next_metric, candidate, &generated, &generated_count);
        }
    }

    std.sort.insertion(NextStepSuggestion, generated[0..generated_count], {}, nextStepLessThan);
    const write_len = @min(generated_count, out.len);
    @memcpy(out[0..write_len], generated[0..write_len]);
    return out[0..write_len];
}

pub fn rankCadenceDestinations(
    history: *const VoicedHistoryWindow,
    profile: CounterpointRuleProfile,
    out: []CadenceDestinationScore,
) []CadenceDestinationScore {
    if (out.len == 0) return out[0..0];
    const current = history.current() orelse return out[0..0];

    var tallies = [_]CadenceDestinationScore{
        .{ .destination = .stable_continuation, .score = 0, .candidate_count = 0, .warning_count = 0, .current_match = false, .tension_bias = 0 },
        .{ .destination = .pre_dominant_arrival, .score = 0, .candidate_count = 0, .warning_count = 0, .current_match = false, .tension_bias = 0 },
        .{ .destination = .dominant_arrival, .score = 0, .candidate_count = 0, .warning_count = 0, .current_match = false, .tension_bias = 0 },
        .{ .destination = .authentic_arrival, .score = 0, .candidate_count = 0, .warning_count = 0, .current_match = false, .tension_bias = 0 },
        .{ .destination = .half_arrival, .score = 0, .candidate_count = 0, .warning_count = 0, .current_match = false, .tension_bias = 0 },
        .{ .destination = .deceptive_pull, .score = 0, .candidate_count = 0, .warning_count = 0, .current_match = false, .tension_bias = 0 },
    };

    const current_destination = cadenceDestinationForCurrentState(current.cadence_state);
    if (current_destination) |destination| {
        const index = @intFromEnum(destination);
        tallies[index].current_match = true;
        tallies[index].score += 120;
    } else {
        tallies[@intFromEnum(CadenceDestination.stable_continuation)].current_match = true;
        tallies[@intFromEnum(CadenceDestination.stable_continuation)].score += 60;
    }

    var suggestion_buf: [MAX_NEXT_STEP_SUGGESTIONS]NextStepSuggestion = undefined;
    const ranked = rankNextSteps(history, profile, suggestion_buf[0..]);

    for (ranked, 0..) |suggestion, rank_index| {
        const destination = cadenceDestinationForSuggestion(suggestion);
        const index = @intFromEnum(destination);
        const placement_bonus = @as(i32, @intCast(@max(0, @as(isize, @intCast(6)) - @as(isize, @intCast(rank_index))))) * 14;
        tallies[index].candidate_count +%= 1;
        tallies[index].warning_count +%= if (suggestion.warning_mask != 0) 1 else 0;
        tallies[index].score += @divTrunc(suggestion.score, 3) + placement_bonus;
        tallies[index].tension_bias = accumulateTensionBias(tallies[index].tension_bias, suggestion.tension_delta);
        if (suggestion.evaluation.cadence_score > 0) {
            tallies[index].score += @as(i32, suggestion.evaluation.cadence_score) * 2;
        }
        if (suggestion.warning_mask != 0) {
            tallies[index].score -= 12;
        }
    }

    std.sort.insertion(CadenceDestinationScore, tallies[0..], {}, cadenceDestinationLessThan);

    const mutating_count = @min(tallies.len, out.len);
    @memcpy(out[0..mutating_count], tallies[0..mutating_count]);
    return out[0..mutating_count];
}

pub fn analyzeSuspensionMachine(
    history: *const VoicedHistoryWindow,
    profile: CounterpointRuleProfile,
) SuspensionMachineSummary {
    const current = history.current() orelse return SuspensionMachineSummary.init();
    const previous = history.previous() orelse return SuspensionMachineSummary.init();

    const context_set = keyboard.modeSet(current.tonic, current.mode_type);
    const previous_tension = tensionScore(previous.set_value, context_set);
    const current_tension = tensionScore(current.set_value, context_set);
    const current_motion = classifyMotion(previous, current);

    var summary = SuspensionMachineSummary.init();
    summary.retained_count = current_motion.common_tone_count;
    summary.current_tension = current_tension;
    summary.previous_tension = previous_tension;

    if (history.len >= 3) {
        const older = &history.states[history.len - 3];
        const older_motion = classifyMotion(older, previous);
        if (findResolutionVoice(older_motion, current_motion)) |resolution| {
            summary.state = .resolution;
            summary.tracked_voice_id = resolution.voice_id;
            summary.held_midi = resolution.from_midi;
            summary.expected_resolution_midi = resolution.to_midi;
            summary.resolution_direction = if (resolution.delta < 0) -1 else if (resolution.delta > 0) 1 else 0;
            return summary;
        }
    }

    if (findHeldSuspensionVoice(current_motion, previous, current)) |held| {
        summary.tracked_voice_id = held.voice_id;
        summary.held_midi = held.to_midi;

        var suggestion_buf: [MAX_NEXT_STEP_SUGGESTIONS]NextStepSuggestion = undefined;
        const ranked = rankNextSteps(history, profile, suggestion_buf[0..]);
        var resolution_candidates: u8 = 0;
        for (ranked) |suggestion| {
            if (findVoiceMotionById(suggestion.motion, held.voice_id)) |voice_motion| {
                if (voice_motion.motion_class == .step and voice_motion.delta != 0) {
                    resolution_candidates +%= 1;
                    if (summary.expected_resolution_midi == 255) {
                        summary.expected_resolution_midi = voice_motion.to_midi;
                        summary.resolution_direction = if (voice_motion.delta < 0) -1 else 1;
                    }
                }
            }
        }

        summary.candidate_resolution_count = resolution_candidates;
        summary.obligation_count = if (resolution_candidates > 0) 1 else 0;

        const suspension_like = current_tension > previous_tension or switch (current.cadence_state) {
            .pre_dominant, .dominant, .cadential_six_four => true,
            else => false,
        };

        if (resolution_candidates == 0) {
            summary.state = .unresolved;
            summary.warning_count = 1;
        } else if (suspension_like) {
            summary.state = .suspension;
        } else {
            summary.state = .preparation;
        }
    }

    return summary;
}

fn emptyVoice() Voice {
    return .{
        .id = 0,
        .midi = 0,
        .pitch_class = 0,
        .octave = -1,
        .sustained = false,
    };
}

fn emptyVoiceMotion() VoiceMotion {
    return .{
        .voice_id = 0,
        .from_midi = 0,
        .to_midi = 0,
        .delta = 0,
        .abs_delta = 0,
        .motion_class = .stationary,
        .retained = false,
    };
}

fn normalizeNotes(
    notes: []const pitch.MidiNote,
    sustained_notes: []const pitch.MidiNote,
    out_notes: *[MAX_VOICES]pitch.MidiNote,
    out_sustained: *[MAX_VOICES]bool,
) usize {
    var sorted: [MAX_VOICES]pitch.MidiNote = [_]pitch.MidiNote{0} ** MAX_VOICES;
    var count: usize = 0;
    for (notes) |note| {
        if (count >= MAX_VOICES) break;
        if (containsMidi(sorted[0..count], note)) continue;
        sorted[count] = note;
        count += 1;
    }

    std.sort.heap(pitch.MidiNote, sorted[0..count], {}, lessThanMidi);

    for (sorted[0..count], 0..) |note, index| {
        out_notes[index] = note;
        out_sustained[index] = containsMidi(sustained_notes, note);
    }
    return count;
}

fn assignVoiceIds(
    current_notes: []const pitch.MidiNote,
    previous: ?*const VoicedState,
    next_voice_id_seed: u8,
    out_ids: *[MAX_VOICES]u8,
) u8 {
    if (current_notes.len == 0) return next_voice_id_seed;
    if (previous == null or previous.?.voice_count == 0) {
        var next_id = next_voice_id_seed;
        for (current_notes, 0..) |_, index| {
            out_ids[index] = next_id;
            next_id +%= 1;
        }
        return next_id;
    }

    const prev = previous.?;
    const m = @as(usize, prev.voice_count);
    const n = current_notes.len;
    const size = @max(m, n);

    var cost: [MAX_VOICES][MAX_VOICES]i16 = [_][MAX_VOICES]i16{[_]i16{0} ** MAX_VOICES} ** MAX_VOICES;
    var row: usize = 0;
    while (row < size) : (row += 1) {
        var col: usize = 0;
        while (col < size) : (col += 1) {
            const real_row = row < m;
            const real_col = col < n;
            cost[row][col] = switch (@as(u2, @intFromBool(real_row)) << 1 | @as(u2, @intFromBool(real_col))) {
                0b11 => @as(i16, @intCast(@abs(@as(i16, prev.voices[row].midi) - @as(i16, current_notes[col])) * ASSIGNMENT_COST_SCALE)),
                0b10 => INSERT_DELETE_COST,
                0b01 => INSERT_DELETE_COST,
                else => 0,
            };
        }
    }

    var assignment: [MAX_VOICES]usize = [_]usize{0} ** MAX_VOICES;
    hungarianAssign(size, &cost, &assignment);

    var matched_ids: [MAX_VOICES]?u8 = [_]?u8{null} ** MAX_VOICES;
    row = 0;
    while (row < m) : (row += 1) {
        const col = assignment[row];
        if (col < n) matched_ids[col] = prev.voices[row].id;
    }

    var next_id = next_voice_id_seed;
    for (current_notes, 0..) |_, index| {
        if (matched_ids[index]) |id| {
            out_ids[index] = id;
        } else {
            out_ids[index] = next_id;
            next_id +%= 1;
        }
    }
    return next_id;
}

fn hungarianAssign(size: usize, cost: *const [MAX_VOICES][MAX_VOICES]i16, assignment: *[MAX_VOICES]usize) void {
    if (size == 0) return;

    var u: [MAX_VOICES + 1]i16 = [_]i16{0} ** (MAX_VOICES + 1);
    var v: [MAX_VOICES + 1]i16 = [_]i16{0} ** (MAX_VOICES + 1);
    var p: [MAX_VOICES + 1]usize = [_]usize{0} ** (MAX_VOICES + 1);
    var way: [MAX_VOICES + 1]usize = [_]usize{0} ** (MAX_VOICES + 1);

    var row: usize = 1;
    while (row <= size) : (row += 1) {
        p[0] = row;
        var minv: [MAX_VOICES + 1]i16 = [_]i16{std.math.maxInt(i16)} ** (MAX_VOICES + 1);
        var used: [MAX_VOICES + 1]bool = [_]bool{false} ** (MAX_VOICES + 1);
        var col0: usize = 0;

        while (true) {
            used[col0] = true;
            const row0 = p[col0];
            var delta: i16 = std.math.maxInt(i16);
            var col1: usize = 0;

            var col: usize = 1;
            while (col <= size) : (col += 1) {
                if (used[col]) continue;
                const cur = cost[row0 - 1][col - 1] - u[row0] - v[col];
                if (cur < minv[col]) {
                    minv[col] = cur;
                    way[col] = col0;
                }
                if (minv[col] < delta) {
                    delta = minv[col];
                    col1 = col;
                }
            }

            var col_adjust: usize = 0;
            while (col_adjust <= size) : (col_adjust += 1) {
                if (used[col_adjust]) {
                    u[p[col_adjust]] += delta;
                    v[col_adjust] -= delta;
                } else {
                    minv[col_adjust] -= delta;
                }
            }

            col0 = col1;
            if (p[col0] == 0) break;
        }

        while (true) {
            const col1 = way[col0];
            p[col0] = p[col1];
            col0 = col1;
            if (col0 == 0) break;
        }
    }

    var col: usize = 1;
    while (col <= size) : (col += 1) {
        if (p[col] != 0) assignment[p[col] - 1] = col - 1;
    }
}

fn containsPc(set_value: pcs.PitchClassSet, pc: u4) bool {
    return (set_value & (@as(pcs.PitchClassSet, 1) << pc)) != 0;
}

fn containsMidi(notes: []const pitch.MidiNote, midi: pitch.MidiNote) bool {
    for (notes) |note| {
        if (note == midi) return true;
    }
    return false;
}

fn lessThanMidi(_: void, a: pitch.MidiNote, b: pitch.MidiNote) bool {
    return a < b;
}

fn findVoiceById(state: *const VoicedState, id: u8) ?Voice {
    for (state.slice()) |voice| {
        if (voice.id == id) return voice;
    }
    return null;
}

fn classifyVoiceMotion(abs_delta: u8) VoiceMotionClass {
    if (abs_delta == 0) return .stationary;
    if (abs_delta <= 2) return .step;
    return .leap;
}

fn orderPair(a: VoiceMotion, b: VoiceMotion) struct { VoiceMotion, VoiceMotion } {
    if (a.from_midi < b.from_midi) return .{ a, b };
    if (a.from_midi > b.from_midi) return .{ b, a };
    if (a.voice_id < b.voice_id) return .{ a, b };
    return .{ b, a };
}

fn classifyPairMotion(lower: VoiceMotion, upper: VoiceMotion) PairMotionClass {
    const lower_delta = lower.delta;
    const upper_delta = upper.delta;
    const lower_stationary = lower_delta == 0;
    const upper_stationary = upper_delta == 0;

    if (lower_stationary and upper_stationary) return .none;
    if (lower_stationary != upper_stationary) return .oblique;
    if (std.math.sign(lower_delta) != std.math.sign(upper_delta)) return .contrary;

    const previous_interval = @abs(@as(i16, upper.from_midi) - @as(i16, lower.from_midi));
    const current_interval = @abs(@as(i16, upper.to_midi) - @as(i16, lower.to_midi));
    if (previous_interval == current_interval and lower_delta == upper_delta) return .parallel;
    return .similar;
}

fn isCrossing(lower: VoiceMotion, upper: VoiceMotion) bool {
    return lower.to_midi > upper.to_midi;
}

fn isOverlap(lower: VoiceMotion, upper: VoiceMotion) bool {
    if (isCrossing(lower, upper)) return false;
    return lower.to_midi > upper.from_midi or upper.to_midi < lower.from_midi;
}

fn lowestPreviousMotion(retained: []const VoiceMotion) VoiceMotion {
    var best = retained[0];
    for (retained[1..]) |motion| {
        if (motion.from_midi < best.from_midi) best = motion;
    }
    return best;
}

fn highestPreviousMotion(retained: []const VoiceMotion) VoiceMotion {
    var best = retained[0];
    for (retained[1..]) |motion| {
        if (motion.from_midi > best.from_midi) best = motion;
    }
    return best;
}

const ProfileSpec = struct {
    contrary_weight: i16,
    oblique_weight: i16,
    similar_weight: i16,
    parallel_weight: i16,
    common_tone_weight: i16,
    crossing_penalty: i16,
    overlap_penalty: i16,
    leap_penalty: i16,
    spacing_penalty: i16,
    max_outer_interval: i8,
    arrival_bonus: i16,
    dominant_bonus: i16,
    parallel_disallowed: bool,
    crossing_disallowed: bool,
};

fn profileSpec(profile: CounterpointRuleProfile) ProfileSpec {
    return switch (profile) {
        .species => .{
            .contrary_weight = 6,
            .oblique_weight = 4,
            .similar_weight = 0,
            .parallel_weight = -8,
            .common_tone_weight = 2,
            .crossing_penalty = 7,
            .overlap_penalty = 5,
            .leap_penalty = 3,
            .spacing_penalty = 2,
            .max_outer_interval = 24,
            .arrival_bonus = 4,
            .dominant_bonus = 2,
            .parallel_disallowed = true,
            .crossing_disallowed = true,
        },
        .tonal_chorale => .{
            .contrary_weight = 5,
            .oblique_weight = 3,
            .similar_weight = 1,
            .parallel_weight = -9,
            .common_tone_weight = 2,
            .crossing_penalty = 8,
            .overlap_penalty = 6,
            .leap_penalty = 2,
            .spacing_penalty = 2,
            .max_outer_interval = 24,
            .arrival_bonus = 6,
            .dominant_bonus = 3,
            .parallel_disallowed = true,
            .crossing_disallowed = true,
        },
        .modal_polyphony => .{
            .contrary_weight = 5,
            .oblique_weight = 4,
            .similar_weight = 0,
            .parallel_weight = -5,
            .common_tone_weight = 3,
            .crossing_penalty = 6,
            .overlap_penalty = 4,
            .leap_penalty = 2,
            .spacing_penalty = 1,
            .max_outer_interval = 26,
            .arrival_bonus = 3,
            .dominant_bonus = 1,
            .parallel_disallowed = false,
            .crossing_disallowed = true,
        },
        .jazz_close_leading => .{
            .contrary_weight = 0,
            .oblique_weight = 3,
            .similar_weight = 5,
            .parallel_weight = 2,
            .common_tone_weight = 6,
            .crossing_penalty = 2,
            .overlap_penalty = 1,
            .leap_penalty = 4,
            .spacing_penalty = 3,
            .max_outer_interval = 14,
            .arrival_bonus = 2,
            .dominant_bonus = 1,
            .parallel_disallowed = false,
            .crossing_disallowed = false,
        },
        .free_contemporary => .{
            .contrary_weight = 1,
            .oblique_weight = 1,
            .similar_weight = 1,
            .parallel_weight = 0,
            .common_tone_weight = 1,
            .crossing_penalty = 1,
            .overlap_penalty = 1,
            .leap_penalty = 1,
            .spacing_penalty = 1,
            .max_outer_interval = 36,
            .arrival_bonus = 1,
            .dominant_bonus = 1,
            .parallel_disallowed = false,
            .crossing_disallowed = false,
        },
    };
}

fn cadenceTransitionBonus(spec: ProfileSpec, previous_state: CadenceState, current_state: CadenceState) i16 {
    var score: i16 = 0;
    if (current_state == .authentic_arrival or current_state == .half_arrival) score += spec.arrival_bonus;
    if (previous_state == .dominant and current_state == .authentic_arrival) score += spec.dominant_bonus;
    if (previous_state == .pre_dominant and current_state == .dominant) score += spec.dominant_bonus;
    return score;
}

fn advanceMetric(metric: MetricPosition) MetricPosition {
    return MetricPosition.normalized(metric.beat_in_bar +% 1, metric.beats_per_bar, metric.subdivision);
}

fn makeSingleVoiceCandidate(current: *const VoicedState, index: usize, delta: i8, out: *[MAX_VOICES]pitch.MidiNote) ?[]const pitch.MidiNote {
    const len = @as(usize, current.voice_count);
    if (index >= len) return null;

    for (current.slice(), 0..) |voice, i| out[i] = voice.midi;
    out[index] = offsetMidi(out[index], delta) orelse return null;
    if (!normalizeCandidateNotes(out, len)) return null;
    if (sameMidiSlice(current.slice(), out[0..len])) return null;
    return out[0..len];
}

fn makeDoubleVoiceCandidate(current: *const VoicedState, low_index: usize, low_delta: i8, high_index: usize, high_delta: i8, out: *[MAX_VOICES]pitch.MidiNote) ?[]const pitch.MidiNote {
    const len = @as(usize, current.voice_count);
    if (low_index >= len or high_index >= len or low_index == high_index) return null;

    for (current.slice(), 0..) |voice, i| out[i] = voice.midi;
    out[low_index] = offsetMidi(out[low_index], low_delta) orelse return null;
    out[high_index] = offsetMidi(out[high_index], high_delta) orelse return null;
    if (!normalizeCandidateNotes(out, len)) return null;
    if (sameMidiSlice(current.slice(), out[0..len])) return null;
    return out[0..len];
}

fn makeCadentialResolutionCandidate(current: *const VoicedState, out: *[MAX_VOICES]pitch.MidiNote) ?[]const pitch.MidiNote {
    const len = @as(usize, current.voice_count);
    for (current.slice(), 0..) |voice, i| out[i] = voice.midi;

    const leading_pc = @as(pitch.PitchClass, @intCast((@as(u8, current.tonic) + 11) % 12));
    const fourth_pc = @as(pitch.PitchClass, @intCast((@as(u8, current.tonic) + 5) % 12));
    var changed = false;
    for (out[0..len], 0..) |midi, index| {
        const pc = pitch.midiToPC(midi);
        if (pc == leading_pc) {
            out[index] = offsetMidi(midi, 1) orelse midi;
            changed = true;
        } else if (pc == fourth_pc) {
            out[index] = offsetMidi(midi, -1) orelse midi;
            changed = true;
        }
    }

    if (!changed) return null;
    if (!normalizeCandidateNotes(out, len)) return null;
    if (sameMidiSlice(current.slice(), out[0..len])) return null;
    return out[0..len];
}

fn offsetMidi(midi: pitch.MidiNote, delta: i8) ?pitch.MidiNote {
    const value = @as(i16, midi) + @as(i16, delta);
    if (value < 0 or value > 127) return null;
    return @as(pitch.MidiNote, @intCast(value));
}

fn normalizeCandidateNotes(notes: *[MAX_VOICES]pitch.MidiNote, len: usize) bool {
    std.sort.heap(pitch.MidiNote, notes[0..len], {}, lessThanMidi);
    var index: usize = 1;
    while (index < len) : (index += 1) {
        if (notes[index] == notes[index - 1]) return false;
    }
    return true;
}

fn sameMidiSlice(voices: []const Voice, notes: []const pitch.MidiNote) bool {
    if (voices.len != notes.len) return false;
    for (voices, notes) |voice, note| {
        if (voice.midi != note) return false;
    }
    return true;
}

fn appendRankedCandidate(
    history: *const VoicedHistoryWindow,
    profile: CounterpointRuleProfile,
    context_set: pcs.PitchClassSet,
    next_metric: MetricPosition,
    candidate_notes: []const pitch.MidiNote,
    generated: *[MAX_NEXT_STEP_SUGGESTIONS * 8]NextStepSuggestion,
    generated_count: *usize,
) void {
    if (generated_count.* >= generated.len) return;
    const current = history.current().?;
    if (containsCandidate(generated[0..generated_count.*], candidate_notes)) return;

    const next = buildVoicedState(
        candidate_notes,
        &[_]pitch.MidiNote{},
        current.tonic,
        current.mode_type,
        next_metric,
        null,
        current,
        current.next_voice_id,
    );

    const motion = classifyMotion(current, &next);
    const evaluation = evaluateMotionProfile(motion, profile);
    const scored = scoreNextStep(history, context_set, next, motion, evaluation);
    generated[generated_count.*] = scored;
    generated_count.* += 1;
}

fn containsCandidate(existing: []const NextStepSuggestion, candidate_notes: []const pitch.MidiNote) bool {
    for (existing) |suggestion| {
        if (suggestion.note_count != candidate_notes.len) continue;
        if (std.mem.eql(pitch.MidiNote, suggestion.notes[0..candidate_notes.len], candidate_notes)) return true;
    }
    return false;
}

fn scoreNextStep(
    history: *const VoicedHistoryWindow,
    context_set: pcs.PitchClassSet,
    next: VoicedState,
    motion: MotionSummary,
    evaluation: MotionEvaluation,
) NextStepSuggestion {
    const current = history.current().?;
    const current_tension = tensionScore(current.set_value, context_set);
    const next_tension = tensionScore(next.set_value, context_set);
    const tension_delta_wide = next_tension - current_tension;
    const tension_delta: i8 = std.math.cast(i8, tension_delta_wide) orelse blk: {
        break :blk if (tension_delta_wide < 0) std.math.minInt(i8) else std.math.maxInt(i8);
    };
    const outside_count = pcs.cardinality(next.set_value) - pcs.cardinality(next.set_value & context_set);

    var score = evaluation.score;
    var reason_mask: u32 = 0;
    var warning_mask: u32 = 0;

    score -= @as(i32, motion.total_motion) * 6;
    if (motion.total_motion <= 3) {
        score += 80;
        reason_mask |= NEXT_STEP_REASON_MINIMAL_MOTION;
    }
    if (motion.contrary_count > 0) {
        score += 60;
        reason_mask |= NEXT_STEP_REASON_CONTRARY_MOTION;
    }
    if (motion.common_tone_count > 0) {
        score += 45;
        reason_mask |= NEXT_STEP_REASON_COMMON_TONE_RETENTION;
    }
    if (evaluation.cadence_score > 0) {
        score += 50;
        reason_mask |= NEXT_STEP_REASON_CADENCE_PULL;
    }
    if (evaluation.spacing_penalty == 0) {
        score += 30;
        reason_mask |= NEXT_STEP_REASON_PRESERVES_SPACING;
    }
    if (tension_delta < 0) {
        score += 30;
        reason_mask |= NEXT_STEP_REASON_RELEASES_TENSION;
    } else if (tension_delta > 0) {
        reason_mask |= NEXT_STEP_REASON_BUILDS_TENSION;
    }

    if (motion.parallel_count > 0) warning_mask |= NEXT_STEP_WARNING_PARALLELS;
    if (motion.crossing_count > 0) warning_mask |= NEXT_STEP_WARNING_CROSSING;
    if (motion.overlap_count > 0) warning_mask |= NEXT_STEP_WARNING_OVERLAP;
    if (evaluation.spacing_penalty > 0) warning_mask |= NEXT_STEP_WARNING_WIDE_SPACING;
    if (outside_count > 0) {
        warning_mask |= NEXT_STEP_WARNING_OUTSIDE_CONTEXT;
        score -= @as(i32, outside_count) * 20;
    }
    if (cluster.hasCluster(next.set_value)) {
        warning_mask |= NEXT_STEP_WARNING_CLUSTER_PRESSURE;
        score -= 40;
    }

    const temporal = temporalMemoryScore(history, motion);
    score += temporal.score_delta;
    reason_mask |= temporal.reason_mask;
    warning_mask |= temporal.warning_mask;

    var suggestion = NextStepSuggestion{
        .score = score,
        .reason_mask = reason_mask,
        .warning_mask = warning_mask,
        .cadence_effect = next.cadence_state,
        .tension_delta = tension_delta,
        .note_count = next.voice_count,
        .set_value = next.set_value,
        .notes = [_]pitch.MidiNote{0} ** MAX_VOICES,
        .motion = motion,
        .evaluation = evaluation,
    };
    for (next.slice(), 0..) |voice, index| suggestion.notes[index] = voice.midi;
    return suggestion;
}

const TemporalScore = struct {
    score_delta: i32,
    reason_mask: u32,
    warning_mask: u32,
};

fn temporalMemoryScore(history: *const VoicedHistoryWindow, motion: MotionSummary) TemporalScore {
    const previous_state = history.previous() orelse return .{ .score_delta = 0, .reason_mask = 0, .warning_mask = 0 };
    const current_state = history.current().?;
    const previous_motion = classifyMotion(previous_state, current_state);

    var score_delta: i32 = 0;
    var reason_mask: u32 = 0;
    var warning_mask: u32 = 0;

    for (motion.voice_motions[0..motion.voice_motion_count]) |next_motion| {
        const prior_motion = findVoiceMotionById(previous_motion, next_motion.voice_id) orelse continue;
        if (prior_motion.motion_class == .leap and next_motion.motion_class == .step and std.math.sign(prior_motion.delta) != std.math.sign(next_motion.delta)) {
            score_delta += 120;
            reason_mask |= NEXT_STEP_REASON_LEAP_COMPENSATION;
        }
        if (prior_motion.motion_class == .leap and next_motion.motion_class == .leap and std.math.sign(prior_motion.delta) == std.math.sign(next_motion.delta)) {
            score_delta -= 140;
            warning_mask |= NEXT_STEP_WARNING_CONSECUTIVE_LEAP;
        }
    }

    return .{ .score_delta = score_delta, .reason_mask = reason_mask, .warning_mask = warning_mask };
}

fn findVoiceMotionById(summary: MotionSummary, voice_id: u8) ?VoiceMotion {
    for (summary.voice_motions[0..summary.voice_motion_count]) |motion| {
        if (motion.voice_id == voice_id) return motion;
    }
    return null;
}

fn tensionScore(set_value: pcs.PitchClassSet, context_set: pcs.PitchClassSet) i16 {
    const overlap = pcs.cardinality(set_value & context_set);
    const outside = pcs.cardinality(set_value) - overlap;
    const cluster_penalty: i16 = if (cluster.hasCluster(set_value)) 6 else 0;
    const evenness_penalty: i16 = @as(i16, @intFromFloat(@round(evenness.evennessDistance(set_value) * 10.0)));
    return @as(i16, outside) * 3 + cluster_penalty + evenness_penalty;
}

fn cadenceDestinationForCurrentState(state: CadenceState) ?CadenceDestination {
    return switch (state) {
        .none => null,
        .stable => .stable_continuation,
        .pre_dominant => .pre_dominant_arrival,
        .dominant, .cadential_six_four => .dominant_arrival,
        .authentic_arrival => .authentic_arrival,
        .half_arrival => .half_arrival,
        .deceptive_pull => .deceptive_pull,
    };
}

fn cadenceDestinationForSuggestion(suggestion: NextStepSuggestion) CadenceDestination {
    if (cadenceDestinationForCurrentState(suggestion.cadence_effect)) |destination| return destination;
    if (suggestion.tension_delta > 0) {
        return .dominant_arrival;
    }
    if ((suggestion.reason_mask & NEXT_STEP_REASON_CADENCE_PULL) != 0 and suggestion.tension_delta < 0) {
        return .authentic_arrival;
    }
    return .stable_continuation;
}

fn accumulateTensionBias(current: i8, delta: i8) i8 {
    const wide = @as(i16, current) + @as(i16, delta);
    return std.math.cast(i8, wide) orelse if (wide < 0) std.math.minInt(i8) else std.math.maxInt(i8);
}

fn cadenceDestinationLessThan(_: void, a: CadenceDestinationScore, b: CadenceDestinationScore) bool {
    if (a.current_match != b.current_match) return a.current_match;
    if (a.score != b.score) return a.score > b.score;
    if (a.warning_count != b.warning_count) return a.warning_count < b.warning_count;
    if (a.candidate_count != b.candidate_count) return a.candidate_count > b.candidate_count;
    return @intFromEnum(a.destination) < @intFromEnum(b.destination);
}

fn findHeldSuspensionVoice(
    summary: MotionSummary,
    previous: *const VoicedState,
    current: *const VoicedState,
) ?VoiceMotion {
    if (previous.set_value == current.set_value) return null;

    var best: ?VoiceMotion = null;
    for (summary.voice_motions[0..summary.voice_motion_count]) |motion| {
        if (motion.motion_class != .stationary) continue;
        if (!motion.retained) continue;

        if (best == null) {
            best = motion;
            continue;
        }

        const incumbent = best.?;
        if (motion.to_midi > incumbent.to_midi) {
            best = motion;
        } else if (motion.to_midi == incumbent.to_midi and motion.voice_id < incumbent.voice_id) {
            best = motion;
        }
    }
    return best;
}

fn findResolutionVoice(previous_motion: MotionSummary, current_motion: MotionSummary) ?VoiceMotion {
    for (current_motion.voice_motions[0..current_motion.voice_motion_count]) |motion| {
        const prior_motion = findVoiceMotionById(previous_motion, motion.voice_id) orelse continue;
        if (prior_motion.motion_class != .stationary) continue;
        if (motion.motion_class != .step or motion.delta == 0) continue;
        return motion;
    }
    return null;
}

fn nextStepLessThan(_: void, a: NextStepSuggestion, b: NextStepSuggestion) bool {
    if (a.score != b.score) return a.score > b.score;
    if (a.warning_mask != b.warning_mask) return a.warning_mask < b.warning_mask;
    return a.set_value < b.set_value;
}
