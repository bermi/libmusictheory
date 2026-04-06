const std = @import("std");
const testing = std.testing;

const pcs = @import("../pitch_class_set.zig");
const counterpoint = @import("../counterpoint.zig");

const c = @cImport({
    @cInclude("libmusictheory.h");
    @cInclude("libmusictheory_compat.h");
});

const api = @import("../c_api.zig");
const LmtKeyContext = api.LmtKeyContext;
const LmtFretPos = api.LmtFretPos;
const LmtGuideDot = api.LmtGuideDot;
const LmtScaleSnapCandidates = api.LmtScaleSnapCandidates;
const LmtContainingModeMatch = api.LmtContainingModeMatch;
const LmtChordMatch = api.LmtChordMatch;
const LmtVoicedState = api.LmtVoicedState;
const LmtVoicedHistory = api.LmtVoicedHistory;
const LmtMotionSummary = api.LmtMotionSummary;
const LmtMotionEvaluation = api.LmtMotionEvaluation;
const LmtVoicePairViolation = api.LmtVoicePairViolation;
const LmtMotionIndependenceSummary = api.LmtMotionIndependenceSummary;
const LmtNextStepSuggestion = api.LmtNextStepSuggestion;
const LmtCadenceDestinationScore = api.LmtCadenceDestinationScore;
const LmtSuspensionMachineSummary = api.LmtSuspensionMachineSummary;
const LmtOrbifoldTriadNode = api.LmtOrbifoldTriadNode;
const LmtOrbifoldTriadEdge = api.LmtOrbifoldTriadEdge;

const lmt_pcs_from_list = api.lmt_pcs_from_list;
const lmt_pcs_to_list = api.lmt_pcs_to_list;
const lmt_pcs_cardinality = api.lmt_pcs_cardinality;
const lmt_pcs_transpose = api.lmt_pcs_transpose;
const lmt_pcs_invert = api.lmt_pcs_invert;
const lmt_pcs_complement = api.lmt_pcs_complement;
const lmt_pcs_is_subset = api.lmt_pcs_is_subset;
const lmt_prime_form = api.lmt_prime_form;
const lmt_forte_prime = api.lmt_forte_prime;
const lmt_is_cluster_free = api.lmt_is_cluster_free;
const lmt_evenness_distance = api.lmt_evenness_distance;
const lmt_scale = api.lmt_scale;
const lmt_mode = api.lmt_mode;
const lmt_mode_type_count = api.lmt_mode_type_count;
const lmt_mode_type_name = api.lmt_mode_type_name;
const lmt_scale_degree = api.lmt_scale_degree;
const lmt_transpose_diatonic = api.lmt_transpose_diatonic;
const lmt_nearest_scale_tones = api.lmt_nearest_scale_tones;
const lmt_snap_to_scale = api.lmt_snap_to_scale;
const lmt_find_containing_modes = api.lmt_find_containing_modes;
const lmt_chord_pattern_count = api.lmt_chord_pattern_count;
const lmt_chord_pattern_name = api.lmt_chord_pattern_name;
const lmt_chord_pattern_formula = api.lmt_chord_pattern_formula;
const lmt_detect_chord_matches = api.lmt_detect_chord_matches;
const lmt_mode_spelling_quality = api.lmt_mode_spelling_quality;
const lmt_spell_note = api.lmt_spell_note;
const lmt_chord = api.lmt_chord;
const lmt_chord_name = api.lmt_chord_name;
const lmt_roman_numeral = api.lmt_roman_numeral;
const lmt_fret_to_midi = api.lmt_fret_to_midi;
const lmt_fret_to_midi_n = api.lmt_fret_to_midi_n;
const lmt_midi_to_fret_positions = api.lmt_midi_to_fret_positions;
const lmt_midi_to_fret_positions_n = api.lmt_midi_to_fret_positions_n;
const lmt_generate_voicings_n = api.lmt_generate_voicings_n;
const lmt_rank_context_suggestions = api.lmt_rank_context_suggestions;
const lmt_preferred_voicing_n = api.lmt_preferred_voicing_n;
const lmt_pitch_class_guide_n = api.lmt_pitch_class_guide_n;
const lmt_frets_to_url_n = api.lmt_frets_to_url_n;
const lmt_url_to_frets_n = api.lmt_url_to_frets_n;
const lmt_svg_clock_optc = api.lmt_svg_clock_optc;
const lmt_svg_optic_k_group = api.lmt_svg_optic_k_group;
const lmt_svg_evenness_chart = api.lmt_svg_evenness_chart;
const lmt_svg_evenness_field = api.lmt_svg_evenness_field;
const lmt_svg_fret = api.lmt_svg_fret;
const lmt_svg_fret_n = api.lmt_svg_fret_n;
const lmt_svg_chord_staff = api.lmt_svg_chord_staff;
const lmt_svg_key_staff = api.lmt_svg_key_staff;
const lmt_svg_keyboard = api.lmt_svg_keyboard;
const lmt_svg_piano_staff = api.lmt_svg_piano_staff;
const lmt_raster_is_enabled = api.lmt_raster_is_enabled;
const lmt_raster_demo_rgba = api.lmt_raster_demo_rgba;
const lmt_counterpoint_max_voices = api.lmt_counterpoint_max_voices;
const lmt_counterpoint_history_capacity = api.lmt_counterpoint_history_capacity;
const lmt_counterpoint_rule_profile_count = api.lmt_counterpoint_rule_profile_count;
const lmt_counterpoint_rule_profile_name = api.lmt_counterpoint_rule_profile_name;
const lmt_voice_leading_violation_kind_count = api.lmt_voice_leading_violation_kind_count;
const lmt_voice_leading_violation_kind_name = api.lmt_voice_leading_violation_kind_name;
const lmt_sizeof_voiced_state = api.lmt_sizeof_voiced_state;
const lmt_sizeof_voiced_history = api.lmt_sizeof_voiced_history;
const lmt_sizeof_next_step_suggestion = api.lmt_sizeof_next_step_suggestion;
const lmt_sizeof_voice_pair_violation = api.lmt_sizeof_voice_pair_violation;
const lmt_sizeof_motion_independence_summary = api.lmt_sizeof_motion_independence_summary;
const lmt_cadence_destination_count = api.lmt_cadence_destination_count;
const lmt_cadence_destination_name = api.lmt_cadence_destination_name;
const lmt_suspension_state_count = api.lmt_suspension_state_count;
const lmt_suspension_state_name = api.lmt_suspension_state_name;
const lmt_sizeof_cadence_destination_score = api.lmt_sizeof_cadence_destination_score;
const lmt_sizeof_suspension_machine_summary = api.lmt_sizeof_suspension_machine_summary;
const lmt_orbifold_triad_node_count = api.lmt_orbifold_triad_node_count;
const lmt_sizeof_orbifold_triad_node = api.lmt_sizeof_orbifold_triad_node;
const lmt_orbifold_triad_node_at = api.lmt_orbifold_triad_node_at;
const lmt_find_orbifold_triad_node = api.lmt_find_orbifold_triad_node;
const lmt_orbifold_triad_edge_count = api.lmt_orbifold_triad_edge_count;
const lmt_sizeof_orbifold_triad_edge = api.lmt_sizeof_orbifold_triad_edge;
const lmt_orbifold_triad_edge_at = api.lmt_orbifold_triad_edge_at;
const lmt_voiced_history_reset = api.lmt_voiced_history_reset;
const lmt_build_voiced_state = api.lmt_build_voiced_state;
const lmt_voiced_history_push = api.lmt_voiced_history_push;
const lmt_classify_motion = api.lmt_classify_motion;
const lmt_evaluate_motion_profile = api.lmt_evaluate_motion_profile;
const lmt_check_parallel_perfects = api.lmt_check_parallel_perfects;
const lmt_check_voice_crossing = api.lmt_check_voice_crossing;
const lmt_check_spacing = api.lmt_check_spacing;
const lmt_check_motion_independence = api.lmt_check_motion_independence;
const lmt_rank_next_steps = api.lmt_rank_next_steps;
const lmt_rank_cadence_destinations = api.lmt_rank_cadence_destinations;
const lmt_analyze_suspension_machine = api.lmt_analyze_suspension_machine;
const lmt_next_step_reason_count = api.lmt_next_step_reason_count;
const lmt_next_step_reason_name = api.lmt_next_step_reason_name;
const lmt_next_step_warning_count = api.lmt_next_step_warning_count;
const lmt_next_step_warning_name = api.lmt_next_step_warning_name;
const lmt_bitmap_clock_optc_rgba = api.lmt_bitmap_clock_optc_rgba;
const lmt_bitmap_optic_k_group_rgba = api.lmt_bitmap_optic_k_group_rgba;
const lmt_bitmap_evenness_chart_rgba = api.lmt_bitmap_evenness_chart_rgba;
const lmt_bitmap_evenness_field_rgba = api.lmt_bitmap_evenness_field_rgba;
const lmt_bitmap_fret_rgba = api.lmt_bitmap_fret_rgba;
const lmt_bitmap_fret_n_rgba = api.lmt_bitmap_fret_n_rgba;
const lmt_svg_fret_tuned_n = api.lmt_svg_fret_tuned_n;
const lmt_bitmap_fret_tuned_n_rgba = api.lmt_bitmap_fret_tuned_n_rgba;
const lmt_bitmap_chord_staff_rgba = api.lmt_bitmap_chord_staff_rgba;
const lmt_bitmap_key_staff_rgba = api.lmt_bitmap_key_staff_rgba;
const lmt_bitmap_keyboard_rgba = api.lmt_bitmap_keyboard_rgba;
const lmt_bitmap_piano_staff_rgba = api.lmt_bitmap_piano_staff_rgba;
const lmt_wasm_scratch_ptr = api.lmt_wasm_scratch_ptr;
const lmt_wasm_scratch_size = api.lmt_wasm_scratch_size;
const lmt_svg_compat_kind_count = api.lmt_svg_compat_kind_count;
const lmt_svg_compat_kind_name = api.lmt_svg_compat_kind_name;
const lmt_svg_compat_kind_directory = api.lmt_svg_compat_kind_directory;
const lmt_svg_compat_image_count = api.lmt_svg_compat_image_count;
const lmt_svg_compat_image_name = api.lmt_svg_compat_image_name;
const lmt_svg_compat_generate = api.lmt_svg_compat_generate;

test "c abi header layout and constants" {
    try testing.expectEqual(@as(usize, 2), @sizeOf(c.lmt_pitch_class_set));
    try testing.expectEqual(@as(usize, 2), @sizeOf(c.lmt_key_context));
    try testing.expectEqual(@as(usize, 8), @sizeOf(c.lmt_guide_dot));
    try testing.expectEqual(@sizeOf(c.lmt_scale_snap_candidates), @sizeOf(LmtScaleSnapCandidates));
    try testing.expectEqual(@sizeOf(c.lmt_containing_mode_match), @sizeOf(LmtContainingModeMatch));
    try testing.expectEqual(@sizeOf(c.lmt_chord_match), @sizeOf(LmtChordMatch));
    try testing.expectEqual(@as(usize, 12), @sizeOf(c.lmt_context_suggestion));
    try testing.expectEqual(@as(usize, 4), @sizeOf(c.lmt_metric_position));
    try testing.expectEqual(@as(usize, 8), @sizeOf(c.lmt_voice));
    try testing.expectEqual(@as(usize, 8), @sizeOf(c.lmt_voice_motion));
    try testing.expectEqual(@sizeOf(c.lmt_cadence_destination_score), @sizeOf(LmtCadenceDestinationScore));
    try testing.expectEqual(@sizeOf(c.lmt_suspension_machine_summary), @sizeOf(LmtSuspensionMachineSummary));
    try testing.expectEqual(@sizeOf(c.lmt_voice_pair_violation), @sizeOf(LmtVoicePairViolation));
    try testing.expectEqual(@sizeOf(c.lmt_motion_independence_summary), @sizeOf(LmtMotionIndependenceSummary));
    try testing.expectEqual(@sizeOf(c.lmt_orbifold_triad_node), @sizeOf(LmtOrbifoldTriadNode));
    try testing.expectEqual(@sizeOf(c.lmt_orbifold_triad_edge), @sizeOf(LmtOrbifoldTriadEdge));
    try testing.expectEqual(@as(usize, 0), @offsetOf(c.lmt_key_context, "tonic"));
    try testing.expectEqual(@as(usize, 1), @offsetOf(c.lmt_key_context, "quality"));
    try testing.expectEqual(@as(usize, 0), @offsetOf(c.lmt_guide_dot, "position"));
    try testing.expectEqual(@as(usize, 2), @offsetOf(c.lmt_guide_dot, "pitch_class"));
    try testing.expectEqual(@as(usize, 4), @offsetOf(c.lmt_guide_dot, "opacity"));
    try testing.expectEqual(@as(usize, 4), @offsetOf(c.lmt_context_suggestion, "expanded_set"));
    try testing.expectEqual(@as(usize, 6), @offsetOf(c.lmt_context_suggestion, "pitch_class"));
    try testing.expectEqual(@as(usize, 10), @offsetOf(c.lmt_voiced_state, "cadence_state"));
    try testing.expectEqual(@as(usize, 17), @offsetOf(c.lmt_motion_summary, "voice_motions"));
    try testing.expectEqual(@as(usize, 3), @offsetOf(c.lmt_voice_pair_violation, "previous_interval_semitones"));
    try testing.expectEqual(@as(usize, 1), @offsetOf(c.lmt_motion_independence_summary, "direction"));
    try testing.expectEqual(@as(c_int, 0), c.LMT_SCALE_DIATONIC);
    try testing.expectEqual(@as(c_int, 28), c.LMT_MODE_NEAPOLITAN_MAJOR);
    try testing.expectEqual(@as(c_int, 3), c.LMT_CHORD_AUGMENTED);
    try testing.expectEqual(@as(u32, counterpoint.MAX_VOICES), lmt_counterpoint_max_voices());
    try testing.expectEqual(@as(u32, counterpoint.HISTORY_CAPACITY), lmt_counterpoint_history_capacity());
    try testing.expectEqual(@as(u32, @sizeOf(LmtVoicedState)), lmt_sizeof_voiced_state());
    try testing.expectEqual(@as(u32, @sizeOf(LmtVoicedHistory)), lmt_sizeof_voiced_history());
    try testing.expectEqual(@as(u32, @sizeOf(LmtNextStepSuggestion)), lmt_sizeof_next_step_suggestion());
    try testing.expectEqual(@as(u32, @sizeOf(LmtVoicePairViolation)), lmt_sizeof_voice_pair_violation());
    try testing.expectEqual(@as(u32, @sizeOf(LmtMotionIndependenceSummary)), lmt_sizeof_motion_independence_summary());
    try testing.expectEqual(@as(u32, @sizeOf(LmtCadenceDestinationScore)), lmt_sizeof_cadence_destination_score());
    try testing.expectEqual(@as(u32, @sizeOf(LmtSuspensionMachineSummary)), lmt_sizeof_suspension_machine_summary());
    try testing.expectEqual(@as(u32, @sizeOf(LmtOrbifoldTriadNode)), lmt_sizeof_orbifold_triad_node());
    try testing.expectEqual(@as(u32, @sizeOf(LmtOrbifoldTriadEdge)), lmt_sizeof_orbifold_triad_edge());
}

test "c abi set operations" {
    const triad = [_]u8{ 0, 4, 7 };
    const set = lmt_pcs_from_list(@ptrCast(&triad), @intCast(triad.len));

    try testing.expectEqual(@as(u16, 0x091), set);
    try testing.expectEqual(@as(u8, 3), lmt_pcs_cardinality(set));

    var out: [12]u8 = undefined;
    const count = lmt_pcs_to_list(set, @ptrCast(&out));
    try testing.expectEqual(@as(u8, 3), count);
    try testing.expectEqualSlices(u8, &[_]u8{ 0, 4, 7 }, out[0..count]);

    const transposed = lmt_pcs_transpose(set, 2);
    try testing.expectEqual(@as(u16, 0x244), transposed);

    const inverted = lmt_pcs_invert(set);
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 5, 8 })), inverted);

    const complement = lmt_pcs_complement(set);
    try testing.expectEqual(@as(u8, 9), lmt_pcs_cardinality(complement));

    try testing.expect(lmt_pcs_is_subset(lmt_pcs_from_list(@ptrCast(&[_]u8{ 0, 7 }), 2), set));
    try testing.expect(!lmt_pcs_is_subset(lmt_pcs_from_list(@ptrCast(&[_]u8{ 1, 7 }), 2), set));
}

test "c abi classification" {
    const set = lmt_pcs_from_list(@ptrCast(&[_]u8{ 0, 4, 7 }), 3);
    try testing.expectEqual(set, lmt_prime_form(set));
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 3, 7 })), lmt_forte_prime(set));
    try testing.expect(lmt_is_cluster_free(set));
    try testing.expect(lmt_evenness_distance(set) > 0.0);
}

test "c abi scales modes and spelling" {
    const diatonic = lmt_scale(c.LMT_SCALE_DIATONIC, 0);
    try testing.expectEqual(@as(u16, 0x0AB5), diatonic);

    const dorian = lmt_mode(c.LMT_MODE_DORIAN, 0);
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 2, 3, 5, 7, 9, 10 })), dorian);
    const phrygian_dominant = lmt_mode(c.LMT_MODE_PHRYGIAN_DOMINANT, 0);
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 1, 4, 5, 7, 8, 10 })), phrygian_dominant);
    try testing.expectEqual(@as(u32, 29), lmt_mode_type_count());
    try testing.expectEqualStrings("Phrygian Dominant", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_mode_type_name(c.LMT_MODE_PHRYGIAN_DOMINANT))), 0));
    try testing.expectEqual(@as(u8, 3), lmt_scale_degree(0, c.LMT_MODE_IONIAN, 64));
    try testing.expectEqual(@as(u8, 0), lmt_scale_degree(0, c.LMT_MODE_IONIAN, 66));
    var transposed: u8 = 0;
    try testing.expectEqual(@as(u32, 1), lmt_transpose_diatonic(0, c.LMT_MODE_IONIAN, 64, 2, @ptrCast(&transposed)));
    try testing.expectEqual(@as(u8, 67), transposed);
    var neighbors = std.mem.zeroes(c.lmt_scale_snap_candidates);
    try testing.expectEqual(@as(u32, 1), lmt_nearest_scale_tones(0, c.LMT_MODE_IONIAN, 66, @ptrCast(&neighbors)));
    try testing.expectEqual(@as(u8, 0), neighbors.in_scale);
    try testing.expectEqual(@as(u8, 1), neighbors.has_lower);
    try testing.expectEqual(@as(u8, 1), neighbors.has_upper);
    try testing.expectEqual(@as(u8, 65), neighbors.lower);
    try testing.expectEqual(@as(u8, 67), neighbors.upper);
    try testing.expectEqual(@as(u8, 1), neighbors.lower_distance);
    try testing.expectEqual(@as(u8, 1), neighbors.upper_distance);
    var snapped: u8 = 0;
    try testing.expectEqual(@as(u32, 1), lmt_snap_to_scale(0, c.LMT_MODE_IONIAN, 66, c.LMT_SNAP_TIE_LOWER, @ptrCast(&snapped)));
    try testing.expectEqual(@as(u8, 65), snapped);
    try testing.expectEqual(@as(u32, 1), lmt_snap_to_scale(0, c.LMT_MODE_IONIAN, 66, c.LMT_SNAP_TIE_HIGHER, @ptrCast(&snapped)));
    try testing.expectEqual(@as(u8, 67), snapped);
    const borrowed_modes = [_]u8{ c.LMT_MODE_IONIAN, c.LMT_MODE_LYDIAN, c.LMT_MODE_MIXOLYDIAN };
    var matches: [4]c.lmt_containing_mode_match = undefined;
    const match_total = lmt_find_containing_modes(6, 0, @ptrCast(&borrowed_modes), borrowed_modes.len, @ptrCast(&matches), matches.len);
    try testing.expectEqual(@as(u8, 1), match_total);
    try testing.expectEqual(@as(u8, c.LMT_MODE_LYDIAN), matches[0].mode);
    try testing.expectEqual(@as(u8, 4), matches[0].degree);
    try testing.expectEqual(@as(u8, c.LMT_KEY_MAJOR), lmt_mode_spelling_quality(0, c.LMT_MODE_IONIAN));
    try testing.expectEqual(@as(u8, c.LMT_KEY_MINOR), lmt_mode_spelling_quality(2, c.LMT_MODE_DORIAN));

    const key_ctx = LmtKeyContext{ .tonic = 0, .quality = c.LMT_KEY_MAJOR };
    const spelled = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_spell_note(1, key_ctx))), 0);
    try testing.expectEqualStrings("C#", spelled);
}

test "c abi context suggestion ranking" {
    const notes = [_]u8{ 60, 64, 67 };
    var out: [12]c.lmt_context_suggestion = undefined;
    const total = lmt_rank_context_suggestions(pcs.C_MAJOR_TRIAD, @ptrCast(&notes), notes.len, 0, c.LMT_MODE_IONIAN, @ptrCast(&out), out.len);

    try testing.expect(total >= 4);
    try testing.expectEqual(@as(u8, 1), out[0].in_context);
    try testing.expect(out[0].score >= out[1].score);

    var pcs_found = [_]bool{false} ** 12;
    for (out[0..4]) |row| pcs_found[row.pitch_class] = true;
    try testing.expect(pcs_found[2]);
    try testing.expect(pcs_found[5]);
    try testing.expect(pcs_found[9]);
    try testing.expect(pcs_found[11]);
}

test "c abi structured chord detection" {
    try testing.expectEqual(@as(u32, 37), lmt_chord_pattern_count());
    try testing.expectEqualStrings("maj7", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_chord_pattern_name(20))), 0));
    try testing.expectEqualStrings("1 3 5 7", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_chord_pattern_formula(20))), 0));

    var matches: [8]c.lmt_chord_match = undefined;
    const total = lmt_detect_chord_matches(pcs.fromList(&[_]u4{ 0, 4, 7, 11 }), 4, true, @ptrCast(&matches), matches.len);
    try testing.expectEqual(@as(u16, 1), total);
    try testing.expectEqual(@as(u8, 0), matches[0].root);
    try testing.expectEqual(@as(u8, 4), matches[0].bass);
    try testing.expectEqual(@as(u8, 20), matches[0].pattern);
    try testing.expectEqual(@as(u8, 4), matches[0].interval_count);
    try testing.expectEqual(@as(u8, 1), matches[0].bass_known);
    try testing.expectEqual(@as(u8, 0), matches[0].root_is_bass);
    try testing.expectEqual(@as(u8, 2), matches[0].bass_degree);
}

test "c abi voiced state and history" {
    var state: LmtVoicedState = undefined;
    const first_notes = [_]u8{ 60, 64, 67 };
    try testing.expectEqual(@as(u32, 3), lmt_build_voiced_state(
        @ptrCast(&first_notes),
        first_notes.len,
        null,
        0,
        0,
        c.LMT_MODE_IONIAN,
        0,
        4,
        0,
        255,
        null,
        @ptrCast(&state),
    ));
    try testing.expectEqual(@as(u8, 3), state.voice_count);
    try testing.expectEqual(@as(u8, 0), state.voices[0].id);
    try testing.expectEqual(@as(u8, c.LMT_CADENCE_STABLE), state.cadence_state);

    var history: LmtVoicedHistory = undefined;
    lmt_voiced_history_reset(@ptrCast(&history));
    try testing.expectEqual(@as(u8, 0), history.len);

    const second_notes = [_]u8{ 59, 60, 64, 67 };
    var pushed: LmtVoicedState = undefined;
    try testing.expectEqual(@as(u32, 4), lmt_voiced_history_push(
        @ptrCast(&history),
        @ptrCast(&second_notes),
        second_notes.len,
        @ptrCast(&[_]u8{59}),
        1,
        0,
        c.LMT_MODE_IONIAN,
        1,
        4,
        0,
        255,
        @ptrCast(&pushed),
    ));
    try testing.expectEqual(@as(u8, 1), history.len);
    try testing.expectEqual(@as(u8, 4), pushed.voice_count);
    try testing.expectEqual(@as(u8, 1), pushed.voices[0].sustained);
}

test "c abi motion summary and profile evaluation" {
    var previous: LmtVoicedState = undefined;
    var current: LmtVoicedState = undefined;
    var summary: LmtMotionSummary = undefined;
    var evaluation: LmtMotionEvaluation = undefined;

    const previous_notes = [_]u8{ 60, 67 };
    const current_notes = [_]u8{ 62, 69 };

    try testing.expectEqual(@as(u32, 2), lmt_build_voiced_state(
        @ptrCast(&previous_notes),
        previous_notes.len,
        null,
        0,
        0,
        c.LMT_MODE_IONIAN,
        2,
        4,
        0,
        c.LMT_CADENCE_DOMINANT,
        null,
        @ptrCast(&previous),
    ));

    try testing.expectEqual(@as(u32, 2), lmt_build_voiced_state(
        @ptrCast(&current_notes),
        current_notes.len,
        null,
        0,
        0,
        c.LMT_MODE_IONIAN,
        3,
        4,
        0,
        c.LMT_CADENCE_AUTHENTIC_ARRIVAL,
        @ptrCast(&previous),
        @ptrCast(&current),
    ));

    try testing.expectEqual(@as(u32, 1), lmt_classify_motion(@ptrCast(&previous), @ptrCast(&current), @ptrCast(&summary)));
    try testing.expectEqual(@as(u8, 2), summary.voice_motion_count);
    try testing.expectEqual(@as(u8, 1), summary.parallel_count);
    try testing.expectEqual(@as(u8, c.LMT_PAIR_MOTION_PARALLEL), summary.outer_motion);

    try testing.expectEqual(@as(u32, 1), lmt_evaluate_motion_profile(c.LMT_COUNTERPOINT_SPECIES, @ptrCast(&summary), @ptrCast(&evaluation)));
    try testing.expect(evaluation.disallowed != 0);
    try testing.expect(evaluation.disallowed_count > 0);

    try testing.expectEqual(@as(u32, 1), lmt_evaluate_motion_profile(c.LMT_COUNTERPOINT_JAZZ_CLOSE_LEADING, @ptrCast(&summary), @ptrCast(&evaluation)));
    try testing.expect(evaluation.disallowed == 0);
}

test "c abi voice-leading rule detectors" {
    var previous = manualVoicedState(&[_]ManualVoicedVoice{
        .{ .id = 0, .midi = 60 },
        .{ .id = 1, .midi = 67 },
    });
    var current_parallel = manualVoicedState(&[_]ManualVoicedVoice{
        .{ .id = 0, .midi = 62 },
        .{ .id = 1, .midi = 69 },
    });

    var violations: [8]LmtVoicePairViolation = undefined;
    const parallel_total = lmt_check_parallel_perfects(@ptrCast(&previous), @ptrCast(&current_parallel), @ptrCast(&violations), violations.len);
    try testing.expectEqual(@as(u32, 1), parallel_total);
    try testing.expectEqual(@as(u8, c.LMT_VOICE_LEADING_PARALLEL_FIFTH), violations[0].kind);
    try testing.expectEqual(@as(i8, 7), violations[0].previous_interval_semitones);
    try testing.expectEqual(@as(i8, 7), violations[0].current_interval_semitones);

    var previous_cross = manualVoicedState(&[_]ManualVoicedVoice{
        .{ .id = 0, .midi = 60 },
        .{ .id = 1, .midi = 64 },
    });
    var current_cross = manualVoicedState(&[_]ManualVoicedVoice{
        .{ .id = 0, .midi = 67 },
        .{ .id = 1, .midi = 62 },
    });
    const crossing_total = lmt_check_voice_crossing(@ptrCast(&previous_cross), @ptrCast(&current_cross), @ptrCast(&violations), violations.len);
    try testing.expectEqual(@as(u32, 1), crossing_total);
    try testing.expectEqual(@as(u8, c.LMT_VOICE_LEADING_VOICE_CROSSING), violations[0].kind);
    try testing.expect(violations[0].current_interval_semitones < 0);

    var spaced = manualVoicedState(&[_]ManualVoicedVoice{
        .{ .id = 0, .midi = 40 },
        .{ .id = 1, .midi = 57 },
        .{ .id = 2, .midi = 74 },
        .{ .id = 3, .midi = 88 },
    });
    const spacing_total = lmt_check_spacing(@ptrCast(&spaced), @ptrCast(&violations), violations.len);
    try testing.expectEqual(@as(u32, 2), spacing_total);
    try testing.expectEqual(@as(u8, c.LMT_VOICE_LEADING_UPPER_SPACING), violations[0].kind);
    try testing.expectEqual(@as(i8, 17), violations[0].current_interval_semitones);

    var current_collapsed = manualVoicedState(&[_]ManualVoicedVoice{
        .{ .id = 0, .midi = 62 },
        .{ .id = 1, .midi = 69 },
    });
    var independence: LmtMotionIndependenceSummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_check_motion_independence(@ptrCast(&previous), @ptrCast(&current_collapsed), @ptrCast(&independence)));
    try testing.expectEqual(@as(u8, 1), independence.collapsed);
    try testing.expectEqual(@as(i8, 1), independence.direction);
    try testing.expectEqual(@as(u8, 2), independence.moving_voice_count);
}

test "c abi next step ranker and reason tables" {
    var history: LmtVoicedHistory = undefined;
    var current: LmtVoicedState = undefined;
    lmt_voiced_history_reset(@ptrCast(&history));

    const previous_notes = [_]u8{ 60, 67 };
    const current_notes = [_]u8{ 64, 69 };
    _ = lmt_voiced_history_push(
        @ptrCast(&history),
        @ptrCast(&previous_notes),
        previous_notes.len,
        null,
        0,
        0,
        c.LMT_MODE_IONIAN,
        0,
        4,
        0,
        c.LMT_CADENCE_STABLE,
        null,
    );
    _ = lmt_voiced_history_push(
        @ptrCast(&history),
        @ptrCast(&current_notes),
        current_notes.len,
        null,
        0,
        0,
        c.LMT_MODE_IONIAN,
        1,
        4,
        0,
        c.LMT_CADENCE_DOMINANT,
        @ptrCast(&current),
    );

    var suggestions: [8]LmtNextStepSuggestion = undefined;
    const total = lmt_rank_next_steps(@ptrCast(&history), c.LMT_COUNTERPOINT_SPECIES, @ptrCast(&suggestions), suggestions.len);
    try testing.expect(total > 0);
    try testing.expect(suggestions[0].score != 0);
    try testing.expect(suggestions[0].note_count > 0);

    const reason_count = lmt_next_step_reason_count();
    try testing.expect(reason_count >= 4);
    const reason_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_next_step_reason_name(0))), 0);
    try testing.expect(reason_name.len > 0);

    const warning_count = lmt_next_step_warning_count();
    try testing.expect(warning_count >= 4);
    const warning_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_next_step_warning_name(0))), 0);
    try testing.expect(warning_name.len > 0);
}

test "c abi counterpoint helper metadata" {
    const profile_count = lmt_counterpoint_rule_profile_count();
    try testing.expectEqual(@as(u32, 5), profile_count);

    const expected = [_][]const u8{
        "species",
        "tonal-chorale",
        "modal-polyphony",
        "jazz-close-leading",
        "free-contemporary",
    };
    for (expected, 0..) |name, index| {
        const actual = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_counterpoint_rule_profile_name(@intCast(index)))), 0);
        try testing.expectEqualStrings(name, actual);
    }
    try testing.expect(lmt_counterpoint_rule_profile_name(profile_count) == null);

    const cadence_destination_count = lmt_cadence_destination_count();
    try testing.expectEqual(@as(u32, counterpoint.CADENCE_DESTINATION_NAMES.len), cadence_destination_count);
    const first_destination = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_cadence_destination_name(0))), 0);
    try testing.expectEqualStrings("stable-continuation", first_destination);
    try testing.expect(lmt_cadence_destination_name(cadence_destination_count) == null);

    const suspension_state_count = lmt_suspension_state_count();
    try testing.expectEqual(@as(u32, counterpoint.SUSPENSION_STATE_NAMES.len), suspension_state_count);
    const suspension_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_suspension_state_name(2))), 0);
    try testing.expectEqualStrings("suspension", suspension_name);
    try testing.expect(lmt_suspension_state_name(suspension_state_count) == null);

    const violation_kind_count = lmt_voice_leading_violation_kind_count();
    try testing.expectEqual(@as(u32, 4), violation_kind_count);
    const violation_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_voice_leading_violation_kind_name(0))), 0);
    try testing.expectEqualStrings("parallel-fifth", violation_name);
    try testing.expect(lmt_voice_leading_violation_kind_name(violation_kind_count) == null);
}

test "c abi cadence destination and suspension helpers" {
    var history: LmtVoicedHistory = undefined;
    var out_state: LmtVoicedState = undefined;
    lmt_voiced_history_reset(@ptrCast(&history));

    const first_notes = [_]u8{ 60, 64, 67 };
    const second_notes = [_]u8{ 60, 65, 67 };
    const third_notes = [_]u8{ 59, 65, 67 };

    _ = lmt_voiced_history_push(
        @ptrCast(&history),
        @ptrCast(&first_notes),
        first_notes.len,
        null,
        0,
        0,
        c.LMT_MODE_IONIAN,
        0,
        4,
        0,
        c.LMT_CADENCE_STABLE,
        @ptrCast(&out_state),
    );
    _ = lmt_voiced_history_push(
        @ptrCast(&history),
        @ptrCast(&second_notes),
        second_notes.len,
        null,
        0,
        0,
        c.LMT_MODE_IONIAN,
        1,
        4,
        0,
        c.LMT_CADENCE_DOMINANT,
        @ptrCast(&out_state),
    );

    var destinations: [counterpoint.MAX_CADENCE_DESTINATIONS]LmtCadenceDestinationScore = undefined;
    const destination_count = lmt_rank_cadence_destinations(@ptrCast(&history), c.LMT_COUNTERPOINT_SPECIES, @ptrCast(&destinations), destinations.len);
    try testing.expect(destination_count > 0);
    try testing.expectEqual(@as(u8, c.LMT_CADENCE_DESTINATION_DOMINANT_ARRIVAL), destinations[0].destination);
    try testing.expectEqual(@as(u8, 1), destinations[0].current_match);

    var held_summary: LmtSuspensionMachineSummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_analyze_suspension_machine(@ptrCast(&history), c.LMT_COUNTERPOINT_SPECIES, @ptrCast(&held_summary)));
    try testing.expect(held_summary.state != c.LMT_SUSPENSION_NONE);
    try testing.expect(held_summary.candidate_resolution_count > 0);

    _ = lmt_voiced_history_push(
        @ptrCast(&history),
        @ptrCast(&third_notes),
        third_notes.len,
        null,
        0,
        0,
        c.LMT_MODE_IONIAN,
        2,
        4,
        0,
        c.LMT_CADENCE_STABLE,
        @ptrCast(&out_state),
    );

    var resolved_summary: LmtSuspensionMachineSummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_analyze_suspension_machine(@ptrCast(&history), c.LMT_COUNTERPOINT_SPECIES, @ptrCast(&resolved_summary)));
    try testing.expectEqual(@as(u8, c.LMT_SUSPENSION_RESOLUTION), resolved_summary.state);
    try testing.expectEqual(@as(u8, 0), resolved_summary.tracked_voice_id);
    try testing.expectEqual(@as(u8, 60), resolved_summary.held_midi);
    try testing.expectEqual(@as(u8, 59), resolved_summary.expected_resolution_midi);
}

test "c abi orbifold metadata helpers" {
    const node_count = lmt_orbifold_triad_node_count();
    try testing.expect(node_count >= 40);

    var node: LmtOrbifoldTriadNode = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_orbifold_triad_node_at(0, @ptrCast(&node)));
    try testing.expectEqual(@as(u16, pcs.C_MAJOR_TRIAD), node.set_value);
    try testing.expectEqual(@as(u8, c.LMT_CHORD_MAJOR), node.quality);
    try testing.expect(node.x > 0);
    try testing.expect(node.y > 0);

    try testing.expectEqual(@as(u32, 0), lmt_find_orbifold_triad_node(pcs.C_MAJOR_TRIAD));
    try testing.expectEqual(@as(u32, 0), lmt_find_orbifold_triad_node(pcs.fromList(&[_]u4{ 0, 4, 7, 11 })));
    try testing.expectEqual(node_count, lmt_find_orbifold_triad_node(pcs.fromList(&[_]u4{ 0, 1, 2 })));

    const edge_count = lmt_orbifold_triad_edge_count();
    try testing.expect(edge_count > 0);

    var edge: LmtOrbifoldTriadEdge = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_orbifold_triad_edge_at(0, @ptrCast(&edge)));
    try testing.expect(edge.from_index < node_count);
    try testing.expect(edge.to_index < node_count);
}

test "c abi chords and roman numerals" {
    const c_major = lmt_chord(c.LMT_CHORD_MAJOR, 0);
    const c_minor = lmt_chord(c.LMT_CHORD_MINOR, 0);

    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 4, 7 })), c_major);
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 3, 7 })), c_minor);

    const name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_chord_name(c_major))), 0);
    try testing.expectEqualStrings("Major", name);

    const key_ctx = LmtKeyContext{ .tonic = 0, .quality = c.LMT_KEY_MAJOR };
    const roman = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_roman_numeral(c_major, key_ctx))), 0);
    try testing.expectEqualStrings("I", roman);
}

test "c abi guitar functions" {
    const tuning = [_]u8{ 40, 45, 50, 55, 59, 64 };

    try testing.expectEqual(@as(u8, 40), lmt_fret_to_midi(0, 0, @ptrCast(&tuning)));

    var out: [6]LmtFretPos = undefined;
    const count = lmt_midi_to_fret_positions(60, @ptrCast(&tuning), @ptrCast(&out));
    try testing.expect(count > 0);
    try testing.expectEqual(@as(u8, 0), out[0].string);

    const alt_tuning = [_]u8{ 55, 60, 64, 69 };
    try testing.expectEqual(@as(u8, 69), lmt_fret_to_midi_n(3, 0, @ptrCast(&alt_tuning), alt_tuning.len));

    var out_n: [8]LmtFretPos = undefined;
    const count_n = lmt_midi_to_fret_positions_n(69, @ptrCast(&alt_tuning), alt_tuning.len, @ptrCast(&out_n), out_n.len);
    try testing.expectEqual(@as(u32, 4), count_n);
    try testing.expectEqual(@as(u8, 0), out_n[3].fret);
    try testing.expectEqual(@as(u8, 3), out_n[3].string);

    const four_string_voicing_tuning = [_]u8{ 48, 52, 55, 60 };
    var voicing_rows: [64 * 4]i8 = [_]i8{-1} ** (64 * 4);
    const voicing_count = lmt_generate_voicings_n(pcs.C_MAJOR_TRIAD, @ptrCast(&four_string_voicing_tuning), four_string_voicing_tuning.len, 12, 4, @ptrCast(&voicing_rows), 64);
    try testing.expect(voicing_count > 0);

    var found_open = false;
    var row: usize = 0;
    while (row < voicing_count) : (row += 1) {
        const start = row * four_string_voicing_tuning.len;
        if (std.mem.eql(i8, voicing_rows[start .. start + four_string_voicing_tuning.len], &[_]i8{ 0, 0, 0, 0 })) {
            found_open = true;
            break;
        }
    }
    try testing.expect(found_open);

    var preferred_frets: [6]i8 = [_]i8{-1} ** 6;
    const preferred_row_count = lmt_preferred_voicing_n(pcs.C_MAJOR_TRIAD, @ptrCast(&tuning), tuning.len, 12, 4, 255, @ptrCast(&preferred_frets), preferred_frets.len);
    try testing.expect(preferred_row_count > 0);
    try testing.expectEqualSlices(i8, &[_]i8{ 0, 3, 2, 0, 1, 0 }, preferred_frets[0..tuning.len]);

    const selected = [_]LmtFretPos{
        .{ .string = 0, .fret = 0 },
    };
    const guide_tuning = [_]u8{ 55, 60, 64, 67 };
    var guide_out: [32]LmtGuideDot = undefined;
    const guide_count = lmt_pitch_class_guide_n(@ptrCast(&selected), selected.len, 0, 12, @ptrCast(&guide_tuning), guide_tuning.len, @ptrCast(&guide_out), guide_out.len);
    try testing.expect(guide_count > 0);

    var has_open_g = false;
    var has_c_string_g = false;
    var guide_i: usize = 0;
    while (guide_i < @min(guide_count, guide_out.len)) : (guide_i += 1) {
        const dot = guide_out[guide_i];
        if (dot.position.string == 3 and dot.position.fret == 0) has_open_g = true;
        if (dot.position.string == 1 and dot.position.fret == 7) has_c_string_g = true;
    }
    try testing.expect(has_open_g);
    try testing.expect(has_c_string_g);
    try testing.expectApproxEqAbs(@as(f32, 0.35), guide_out[0].opacity, 0.0001);

    const frets = [_]i8{ 0, 2, 3, 2 };
    var url_buf: [64]u8 = [_]u8{0} ** 64;
    const url_len = lmt_frets_to_url_n(@ptrCast(&frets), frets.len, @ptrCast(&url_buf), url_buf.len);
    try testing.expectEqualStrings("0,2,3,2", url_buf[0..url_len]);

    const url_input = "0,2,3,2";
    var parsed_frets: [8]i8 = [_]i8{-1} ** 8;
    const parsed_count = lmt_url_to_frets_n(url_input.ptr, @ptrCast(&parsed_frets), parsed_frets.len);
    try testing.expectEqual(@as(u32, 4), parsed_count);
    try testing.expectEqualSlices(i8, frets[0..], parsed_frets[0..parsed_count]);
}

test "c abi svg generators" {
    var svg_buf: [128 * 1024]u8 = [_]u8{0} ** (128 * 1024);
    const c_major = lmt_chord(c.LMT_CHORD_MAJOR, 0);

    const len1 = lmt_svg_clock_optc(c_major, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(len1 > 0);
    try testing.expect(std.mem.startsWith(u8, svg_buf[0..4], "<svg"));

    const optic_k_len = lmt_svg_optic_k_group(c_major, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(optic_k_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..optic_k_len], "data-text=\"OPTIC/K\"") != null);
    try testing.expect(std.mem.count(u8, svg_buf[0..optic_k_len], "class=\"optic-k-ring\"") >= 2);

    const evenness_len = lmt_svg_evenness_chart(@ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(evenness_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..evenness_len], "class=\"ring\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..evenness_len], "class=\"dot\"") != null);

    const evenness_field_len = lmt_svg_evenness_field(c_major, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(evenness_field_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..evenness_field_len], "class=\"dot-highlight\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..evenness_field_len], "data-text=\"FOCUS ") != null);

    const frets = [_]i8{ -1, 3, 2, 0, 1, 0 };
    const len2 = lmt_svg_fret(@ptrCast(&frets), @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(len2 > 0);
    try testing.expect(std.mem.startsWith(u8, svg_buf[0..4], "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..len2], "marker-open") != null);

    const four_string = [_]i8{ 0, 0, 0, 3 };
    const len2n = lmt_svg_fret_n(@ptrCast(&four_string), four_string.len, 0, 4, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(len2n > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..len2n], "cx=\"80.00\" cy=\"57.50\"") != null);

    const tuned_frets = [_]i8{ 0, 2, 2, 1 };
    const tuned = [_]u8{ 48, 55, 60, 64 };
    const tuned_len = lmt_svg_fret_tuned_n(@ptrCast(&tuned_frets), tuned_frets.len, @ptrCast(&tuned), tuned.len, 0, 4, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(tuned_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..tuned_len], "fill=\"#0bb\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..tuned_len], "fill=\"#f0f\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..tuned_len], "fill=\"#f91\"") != null);

    const chord_staff_cases = [_]struct {
        chord_kind: u8,
        root: u8,
    }{
        .{ .chord_kind = c.LMT_CHORD_MAJOR, .root = 0 },
        .{ .chord_kind = c.LMT_CHORD_MINOR, .root = 9 },
        .{ .chord_kind = c.LMT_CHORD_DIMINISHED, .root = 11 },
        .{ .chord_kind = c.LMT_CHORD_AUGMENTED, .root = 8 },
    };
    for (chord_staff_cases) |case| {
        const len3 = lmt_svg_chord_staff(case.chord_kind, case.root, @ptrCast(&svg_buf), @intCast(svg_buf.len));
        try testing.expect(len3 > 0);
        try testing.expect(std.mem.startsWith(u8, svg_buf[0..4], "<svg"));
        try testing.expect(std.mem.indexOf(u8, svg_buf[0..len3], "shape-rendering=\"geometricPrecision\"") != null);
        try testing.expect(std.mem.indexOf(u8, svg_buf[0..len3], "class=\"clef clef-treble\"") != null);
        try testing.expect(std.mem.count(u8, svg_buf[0..len3], "class=\"notehead chord-notehead\"") >= 3);
        try testing.expect(std.mem.indexOf(u8, svg_buf[0..len3], "class=\"stem cluster-stem\"") != null);
    }

    const key_staff_len = lmt_svg_key_staff(0, c.LMT_KEY_MAJOR, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(key_staff_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..key_staff_len], "width=\"520\"") != null);
    try testing.expect(std.mem.count(u8, svg_buf[0..key_staff_len], "class=\"staff-barline\"") >= 2);
    try testing.expect(std.mem.count(u8, svg_buf[0..key_staff_len], "class=\"notehead key-notehead\"") >= 8);

    const keyboard_notes = [_]u8{ 61, 63, 64, 66, 68, 69, 71, 73 };
    const keyboard_len = lmt_svg_keyboard(@ptrCast(&keyboard_notes), keyboard_notes.len, 48, 72, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(keyboard_len > 0);
    try testing.expect(std.mem.count(u8, svg_buf[0..keyboard_len], "class=\"keyboard-key white-key is-selected\"") >= 2);
    try testing.expect(std.mem.count(u8, svg_buf[0..keyboard_len], "class=\"keyboard-key white-key is-echo\"") >= 2);
    try testing.expect(std.mem.count(u8, svg_buf[0..keyboard_len], "class=\"keyboard-key black-key black-key-base\"") >= 10);
    try testing.expect(std.mem.count(u8, svg_buf[0..keyboard_len], "class=\"keyboard-key black-key black-key-overlay is-selected\"") >= 1);
    try testing.expect(std.mem.count(u8, svg_buf[0..keyboard_len], "class=\"keyboard-key black-key black-key-overlay is-echo\"") >= 1);

    const piano_notes = [_]u8{ 43, 52, 60, 64 };
    const piano_staff_len = lmt_svg_piano_staff(@ptrCast(&piano_notes), piano_notes.len, 0, c.LMT_KEY_MAJOR, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(piano_staff_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..piano_staff_len], "class=\"staff-system staff-mode-grand\"") != null);
    try testing.expect(std.mem.count(u8, svg_buf[0..piano_staff_len], "class=\"clef ") >= 2);
}

test "c abi raster generators" {
    const enabled = lmt_raster_is_enabled();
    try testing.expect(enabled == 0 or enabled == 1);
    if (enabled == 0) return error.SkipZigTest;

    var rgba: [64 * 64 * 4]u8 = [_]u8{0} ** (64 * 64 * 4);
    const written = lmt_raster_demo_rgba(64, 64, @ptrCast(&rgba), @intCast(rgba.len));
    try testing.expectEqual(@as(u32, rgba.len), written);

    const clock_set = lmt_chord(c.LMT_CHORD_MAJOR, 0);
    var clock_rgba: [240 * 240 * 4]u8 = [_]u8{0} ** (240 * 240 * 4);
    try testing.expectEqual(@as(u32, clock_rgba.len), lmt_bitmap_clock_optc_rgba(clock_set, 240, 240, @ptrCast(&clock_rgba), @intCast(clock_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &clock_rgba, &[_]u8{255}) != null);

    var optic_k_rgba: [320 * 160 * 4]u8 = [_]u8{0} ** (320 * 160 * 4);
    try testing.expectEqual(@as(u32, optic_k_rgba.len), lmt_bitmap_optic_k_group_rgba(clock_set, 320, 160, @ptrCast(&optic_k_rgba), @intCast(optic_k_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &optic_k_rgba, &[_]u8{255}) != null);

    var evenness_rgba: [240 * 312 * 4]u8 = [_]u8{0} ** (240 * 312 * 4);
    try testing.expectEqual(@as(u32, evenness_rgba.len), lmt_bitmap_evenness_chart_rgba(240, 312, @ptrCast(&evenness_rgba), @intCast(evenness_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &evenness_rgba, &[_]u8{255}) != null);

    var evenness_field_rgba: [240 * 312 * 4]u8 = [_]u8{0} ** (240 * 312 * 4);
    try testing.expectEqual(@as(u32, evenness_field_rgba.len), lmt_bitmap_evenness_field_rgba(clock_set, 240, 312, @ptrCast(&evenness_field_rgba), @intCast(evenness_field_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &evenness_field_rgba, &[_]u8{255}) != null);

    const frets = [_]i8{ -1, 3, 2, 0, 1, 0 };
    var fret_rgba: [320 * 320 * 4]u8 = [_]u8{0} ** (320 * 320 * 4);
    try testing.expectEqual(@as(u32, fret_rgba.len), lmt_bitmap_fret_rgba(@ptrCast(&frets), 320, 320, @ptrCast(&fret_rgba), @intCast(fret_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &fret_rgba, &[_]u8{255}) != null);

    const four_string = [_]i8{ 0, 0, 0, 3 };
    var fret_n_rgba: [320 * 320 * 4]u8 = [_]u8{0} ** (320 * 320 * 4);
    try testing.expectEqual(@as(u32, fret_n_rgba.len), lmt_bitmap_fret_n_rgba(@ptrCast(&four_string), four_string.len, 0, 4, 320, 320, @ptrCast(&fret_n_rgba), @intCast(fret_n_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &fret_n_rgba, &[_]u8{255}) != null);

    const tuned_frets = [_]i8{ 0, 2, 2, 1 };
    const tuned = [_]u8{ 48, 55, 60, 64 };
    var fret_tuned_rgba: [320 * 320 * 4]u8 = [_]u8{0} ** (320 * 320 * 4);
    try testing.expectEqual(@as(u32, fret_tuned_rgba.len), lmt_bitmap_fret_tuned_n_rgba(@ptrCast(&tuned_frets), tuned_frets.len, @ptrCast(&tuned), tuned.len, 0, 4, 320, 320, @ptrCast(&fret_tuned_rgba), @intCast(fret_tuned_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &fret_tuned_rgba, &[_]u8{255}) != null);

    var staff_rgba: [640 * 240 * 4]u8 = [_]u8{0} ** (640 * 240 * 4);
    try testing.expectEqual(@as(u32, staff_rgba.len), lmt_bitmap_chord_staff_rgba(c.LMT_CHORD_MAJOR, 0, 640, 240, @ptrCast(&staff_rgba), @intCast(staff_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &staff_rgba, &[_]u8{255}) != null);

    var key_staff_rgba: [960 * 240 * 4]u8 = [_]u8{0} ** (960 * 240 * 4);
    try testing.expectEqual(@as(u32, key_staff_rgba.len), lmt_bitmap_key_staff_rgba(0, c.LMT_KEY_MAJOR, 960, 240, @ptrCast(&key_staff_rgba), @intCast(key_staff_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &key_staff_rgba, &[_]u8{255}) != null);

    const keyboard_notes = [_]u8{ 61, 63, 64, 66, 68, 69, 71, 73 };
    var keyboard_rgba: [840 * 220 * 4]u8 = [_]u8{0} ** (840 * 220 * 4);
    try testing.expectEqual(@as(u32, keyboard_rgba.len), lmt_bitmap_keyboard_rgba(@ptrCast(&keyboard_notes), keyboard_notes.len, 48, 72, 840, 220, @ptrCast(&keyboard_rgba), @intCast(keyboard_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &keyboard_rgba, &[_]u8{255}) != null);

    const piano_notes = [_]u8{ 43, 52, 60, 64 };
    var piano_staff_rgba: [840 * 869 * 4]u8 = [_]u8{0} ** (840 * 869 * 4);
    try testing.expectEqual(@as(u32, piano_staff_rgba.len), lmt_bitmap_piano_staff_rgba(@ptrCast(&piano_notes), piano_notes.len, 0, c.LMT_KEY_MAJOR, 840, 869, @ptrCast(&piano_staff_rgba), @intCast(piano_staff_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &piano_staff_rgba, &[_]u8{255}) != null);
}

test "c abi harmonious compatibility surface" {
    try testing.expect(lmt_wasm_scratch_ptr() != null);
    try testing.expect(lmt_wasm_scratch_size() >= 4 * 1024 * 1024);

    const kind_count = lmt_svg_compat_kind_count();
    try testing.expect(kind_count >= 10);

    const kind_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_svg_compat_kind_name(0))), 0);
    try testing.expect(kind_name.len > 0);

    const kind_dir = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_svg_compat_kind_directory(0))), 0);
    try testing.expect(kind_dir.len > 0);

    const image_count = lmt_svg_compat_image_count(0);
    try testing.expect(image_count > 0);

    var name_buf: [512]u8 = [_]u8{0} ** 512;
    const name_len = lmt_svg_compat_image_name(0, 0, @ptrCast(&name_buf), @intCast(name_buf.len));
    try testing.expect(name_len > 0);
    try testing.expect(std.mem.indexOfScalar(u8, name_buf[0..name_len], '.') != null);

    var svg_buf: [4 * 1024 * 1024]u8 = [_]u8{0} ** (4 * 1024 * 1024);
    const svg_len = lmt_svg_compat_generate(0, 0, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(svg_len > 0);
    try testing.expect(std.mem.startsWith(u8, svg_buf[0..5], "<svg ") or std.mem.startsWith(u8, svg_buf[0..4], "<svg"));
}

const ManualVoicedVoice = struct {
    id: u8,
    midi: u8,
};

fn manualVoicedState(voices: []const ManualVoicedVoice) LmtVoicedState {
    var state = std.mem.zeroes(LmtVoicedState);
    state.voice_count = @intCast(voices.len);
    state.tonic = 0;
    state.mode_type = c.LMT_MODE_IONIAN;
    state.key_quality = c.LMT_KEY_MAJOR;
    state.metric = .{ .beat_in_bar = 0, .beats_per_bar = 4, .subdivision = 0, .reserved = 0 };
    state.cadence_state = c.LMT_CADENCE_STABLE;
    state.state_index = 0;
    state.next_voice_id = @intCast(voices.len);
    for (voices, 0..) |voice, index| {
        state.voices[index] = .{
            .id = voice.id,
            .midi = voice.midi,
            .octave = @as(i8, @intCast(@as(i16, @intCast(voice.midi / 12)) - 1)),
            .pitch_class = voice.midi % 12,
            .sustained = 0,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
        };
        state.set_value |= @as(u16, 1) << @intCast(voice.midi % 12);
    }
    return state;
}
