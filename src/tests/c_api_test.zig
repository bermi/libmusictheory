const std = @import("std");
const testing = std.testing;

const pcs = @import("../pitch_class_set.zig");
const counterpoint = @import("../counterpoint.zig");
const keyboard = @import("../keyboard.zig");
const playability = @import("../playability.zig");

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
const LmtHandProfile = api.LmtHandProfile;
const LmtPlayabilityDifficultySummary = api.LmtPlayabilityDifficultySummary;
const LmtKeyboardPhraseEvent = api.LmtKeyboardPhraseEvent;
const LmtFretPhraseEvent = api.LmtFretPhraseEvent;
const LmtKeyboardPhraseBranch = api.LmtKeyboardPhraseBranch;
const LmtFretPhraseBranch = api.LmtFretPhraseBranch;
const LmtKeyboardPhraseStepCandidates = api.LmtKeyboardPhraseStepCandidates;
const LmtFretPhraseStepCandidates = api.LmtFretPhraseStepCandidates;
const LmtKeyboardPhraseCandidateWindow = api.LmtKeyboardPhraseCandidateWindow;
const LmtFretPhraseCandidateWindow = api.LmtFretPhraseCandidateWindow;
const LmtKeyboardCommittedPhraseMemory = api.LmtKeyboardCommittedPhraseMemory;
const LmtFretCommittedPhraseMemory = api.LmtFretCommittedPhraseMemory;
const LmtPlayabilityPhraseIssue = api.LmtPlayabilityPhraseIssue;
const LmtPlayabilityPhraseSummary = api.LmtPlayabilityPhraseSummary;
const LmtPlayabilityPhraseBranchSummary = api.LmtPlayabilityPhraseBranchSummary;
const LmtPhraseBranchBiasSummary = api.LmtPhraseBranchBiasSummary;
const LmtRankedKeyboardPhraseBranch = api.LmtRankedKeyboardPhraseBranch;
const LmtRankedFretPhraseBranch = api.LmtRankedFretPhraseBranch;
const LmtPlayabilityRepairPolicy = api.LmtPlayabilityRepairPolicy;
const LmtRankedKeyboardPhraseRepair = api.LmtRankedKeyboardPhraseRepair;
const LmtRankedFretPhraseRepair = api.LmtRankedFretPhraseRepair;
const LmtTemporalLoadState = api.LmtTemporalLoadState;
const LmtFretCandidateLocation = api.LmtFretCandidateLocation;
const LmtFretPlayState = api.LmtFretPlayState;
const LmtFretRealizationAssessment = api.LmtFretRealizationAssessment;
const LmtFretTransitionAssessment = api.LmtFretTransitionAssessment;
const LmtRankedFretRealization = api.LmtRankedFretRealization;
const LmtKeybedKeyCoord = api.LmtKeybedKeyCoord;
const LmtKeyboardPlayState = api.LmtKeyboardPlayState;
const LmtKeyboardRealizationAssessment = api.LmtKeyboardRealizationAssessment;
const LmtKeyboardTransitionAssessment = api.LmtKeyboardTransitionAssessment;
const LmtRankedKeyboardFingering = api.LmtRankedKeyboardFingering;
const LmtRankedKeyboardContextSuggestion = api.LmtRankedKeyboardContextSuggestion;
const LmtVoicedState = api.LmtVoicedState;
const LmtVoicedHistory = api.LmtVoicedHistory;
const LmtMotionSummary = api.LmtMotionSummary;
const LmtMotionEvaluation = api.LmtMotionEvaluation;
const LmtVoicePairViolation = api.LmtVoicePairViolation;
const LmtMotionIndependenceSummary = api.LmtMotionIndependenceSummary;
const LmtSatbRegisterViolation = api.LmtSatbRegisterViolation;
const LmtNextStepSuggestion = api.LmtNextStepSuggestion;
const LmtRankedKeyboardNextStep = api.LmtRankedKeyboardNextStep;
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
const lmt_ordered_scale_pattern_count = api.lmt_ordered_scale_pattern_count;
const lmt_ordered_scale_pattern_name = api.lmt_ordered_scale_pattern_name;
const lmt_ordered_scale_degree_count = api.lmt_ordered_scale_degree_count;
const lmt_ordered_scale_pitch_class_set = api.lmt_ordered_scale_pitch_class_set;
const lmt_barry_harris_parity = api.lmt_barry_harris_parity;
const lmt_playability_reason_count = api.lmt_playability_reason_count;
const lmt_playability_reason_name = api.lmt_playability_reason_name;
const lmt_playability_warning_count = api.lmt_playability_warning_count;
const lmt_playability_warning_name = api.lmt_playability_warning_name;
const lmt_playability_policy_count = api.lmt_playability_policy_count;
const lmt_playability_policy_name = api.lmt_playability_policy_name;
const lmt_playability_phrase_branch_class_count = api.lmt_playability_phrase_branch_class_count;
const lmt_playability_phrase_branch_class_name = api.lmt_playability_phrase_branch_class_name;
const lmt_playability_phrase_branch_visibility_count = api.lmt_playability_phrase_branch_visibility_count;
const lmt_playability_phrase_branch_visibility_name = api.lmt_playability_phrase_branch_visibility_name;
const lmt_playability_phrase_branch_bias_reason_count = api.lmt_playability_phrase_branch_bias_reason_count;
const lmt_playability_phrase_branch_bias_reason_name = api.lmt_playability_phrase_branch_bias_reason_name;
const lmt_playability_profile_preset_count = api.lmt_playability_profile_preset_count;
const lmt_playability_profile_preset_name = api.lmt_playability_profile_preset_name;
const lmt_playability_profile_from_preset = api.lmt_playability_profile_from_preset;
const lmt_playability_phrase_issue_scope_count = api.lmt_playability_phrase_issue_scope_count;
const lmt_playability_phrase_issue_scope_name = api.lmt_playability_phrase_issue_scope_name;
const lmt_playability_phrase_issue_severity_count = api.lmt_playability_phrase_issue_severity_count;
const lmt_playability_phrase_issue_severity_name = api.lmt_playability_phrase_issue_severity_name;
const lmt_playability_phrase_family_domain_count = api.lmt_playability_phrase_family_domain_count;
const lmt_playability_phrase_family_domain_name = api.lmt_playability_phrase_family_domain_name;
const lmt_playability_phrase_strain_bucket_count = api.lmt_playability_phrase_strain_bucket_count;
const lmt_playability_phrase_strain_bucket_name = api.lmt_playability_phrase_strain_bucket_name;
const lmt_playability_repair_class_count = api.lmt_playability_repair_class_count;
const lmt_playability_repair_class_name = api.lmt_playability_repair_class_name;
const lmt_fret_playability_blocker_count = api.lmt_fret_playability_blocker_count;
const lmt_fret_playability_blocker_name = api.lmt_fret_playability_blocker_name;
const lmt_fret_technique_profile_count = api.lmt_fret_technique_profile_count;
const lmt_fret_technique_profile_name = api.lmt_fret_technique_profile_name;
const lmt_keyboard_hand_count = api.lmt_keyboard_hand_count;
const lmt_keyboard_hand_name = api.lmt_keyboard_hand_name;
const lmt_keyboard_playability_blocker_count = api.lmt_keyboard_playability_blocker_count;
const lmt_keyboard_playability_blocker_name = api.lmt_keyboard_playability_blocker_name;
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
const lmt_satb_voice_count = api.lmt_satb_voice_count;
const lmt_satb_voice_name = api.lmt_satb_voice_name;
const lmt_sizeof_hand_profile = api.lmt_sizeof_hand_profile;
const lmt_sizeof_temporal_load_state = api.lmt_sizeof_temporal_load_state;
const lmt_sizeof_fret_candidate_location = api.lmt_sizeof_fret_candidate_location;
const lmt_sizeof_fret_play_state = api.lmt_sizeof_fret_play_state;
const lmt_sizeof_fret_realization_assessment = api.lmt_sizeof_fret_realization_assessment;
const lmt_sizeof_fret_transition_assessment = api.lmt_sizeof_fret_transition_assessment;
const lmt_sizeof_ranked_fret_realization = api.lmt_sizeof_ranked_fret_realization;
const lmt_sizeof_keybed_key_coord = api.lmt_sizeof_keybed_key_coord;
const lmt_sizeof_keyboard_play_state = api.lmt_sizeof_keyboard_play_state;
const lmt_sizeof_keyboard_realization_assessment = api.lmt_sizeof_keyboard_realization_assessment;
const lmt_sizeof_keyboard_transition_assessment = api.lmt_sizeof_keyboard_transition_assessment;
const lmt_sizeof_ranked_keyboard_fingering = api.lmt_sizeof_ranked_keyboard_fingering;
const lmt_sizeof_ranked_keyboard_context_suggestion = api.lmt_sizeof_ranked_keyboard_context_suggestion;
const lmt_sizeof_ranked_keyboard_next_step = api.lmt_sizeof_ranked_keyboard_next_step;
const lmt_sizeof_playability_difficulty_summary = api.lmt_sizeof_playability_difficulty_summary;
const lmt_sizeof_keyboard_phrase_event = api.lmt_sizeof_keyboard_phrase_event;
const lmt_sizeof_fret_phrase_event = api.lmt_sizeof_fret_phrase_event;
const lmt_sizeof_keyboard_phrase_branch = api.lmt_sizeof_keyboard_phrase_branch;
const lmt_sizeof_fret_phrase_branch = api.lmt_sizeof_fret_phrase_branch;
const lmt_sizeof_keyboard_phrase_step_candidates = api.lmt_sizeof_keyboard_phrase_step_candidates;
const lmt_sizeof_fret_phrase_step_candidates = api.lmt_sizeof_fret_phrase_step_candidates;
const lmt_sizeof_keyboard_phrase_candidate_window = api.lmt_sizeof_keyboard_phrase_candidate_window;
const lmt_sizeof_fret_phrase_candidate_window = api.lmt_sizeof_fret_phrase_candidate_window;
const lmt_sizeof_keyboard_committed_phrase_memory = api.lmt_sizeof_keyboard_committed_phrase_memory;
const lmt_sizeof_fret_committed_phrase_memory = api.lmt_sizeof_fret_committed_phrase_memory;
const lmt_sizeof_playability_phrase_issue = api.lmt_sizeof_playability_phrase_issue;
const lmt_sizeof_playability_phrase_summary = api.lmt_sizeof_playability_phrase_summary;
const lmt_sizeof_playability_phrase_branch_summary = api.lmt_sizeof_playability_phrase_branch_summary;
const lmt_sizeof_playability_phrase_branch_bias_summary = api.lmt_sizeof_playability_phrase_branch_bias_summary;
const lmt_sizeof_ranked_keyboard_phrase_branch = api.lmt_sizeof_ranked_keyboard_phrase_branch;
const lmt_sizeof_ranked_fret_phrase_branch = api.lmt_sizeof_ranked_fret_phrase_branch;
const lmt_sizeof_playability_repair_policy = api.lmt_sizeof_playability_repair_policy;
const lmt_sizeof_ranked_keyboard_phrase_repair = api.lmt_sizeof_ranked_keyboard_phrase_repair;
const lmt_sizeof_ranked_fret_phrase_repair = api.lmt_sizeof_ranked_fret_phrase_repair;
const lmt_sizeof_voiced_state = api.lmt_sizeof_voiced_state;
const lmt_sizeof_voiced_history = api.lmt_sizeof_voiced_history;
const lmt_sizeof_next_step_suggestion = api.lmt_sizeof_next_step_suggestion;
const lmt_sizeof_voice_pair_violation = api.lmt_sizeof_voice_pair_violation;
const lmt_sizeof_motion_independence_summary = api.lmt_sizeof_motion_independence_summary;
const lmt_sizeof_satb_register_violation = api.lmt_sizeof_satb_register_violation;
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
const lmt_default_fret_hand_profile = api.lmt_default_fret_hand_profile;
const lmt_default_fret_hand_profile_for_technique = api.lmt_default_fret_hand_profile_for_technique;
const lmt_default_keyboard_hand_profile = api.lmt_default_keyboard_hand_profile;
const lmt_default_playability_repair_policy = api.lmt_default_playability_repair_policy;
const lmt_summarize_playability_phrase_issues = api.lmt_summarize_playability_phrase_issues;
const lmt_summarize_playability_phrase_branch_issues = api.lmt_summarize_playability_phrase_branch_issues;
const lmt_keyboard_committed_phrase_reset = api.lmt_keyboard_committed_phrase_reset;
const lmt_keyboard_committed_phrase_push = api.lmt_keyboard_committed_phrase_push;
const lmt_keyboard_committed_phrase_len = api.lmt_keyboard_committed_phrase_len;
const lmt_fret_committed_phrase_reset = api.lmt_fret_committed_phrase_reset;
const lmt_fret_committed_phrase_push = api.lmt_fret_committed_phrase_push;
const lmt_fret_committed_phrase_len = api.lmt_fret_committed_phrase_len;
const lmt_audit_fret_phrase_n = api.lmt_audit_fret_phrase_n;
const lmt_audit_keyboard_phrase_n = api.lmt_audit_keyboard_phrase_n;
const lmt_summarize_fret_phrase_branch_n = api.lmt_summarize_fret_phrase_branch_n;
const lmt_summarize_keyboard_phrase_branch_n = api.lmt_summarize_keyboard_phrase_branch_n;
const lmt_audit_committed_fret_phrase_n = api.lmt_audit_committed_fret_phrase_n;
const lmt_audit_committed_keyboard_phrase_n = api.lmt_audit_committed_keyboard_phrase_n;
const lmt_rank_keyboard_phrase_branches_by_committed_phrase = api.lmt_rank_keyboard_phrase_branches_by_committed_phrase;
const lmt_rank_fret_phrase_branches_by_committed_phrase = api.lmt_rank_fret_phrase_branches_by_committed_phrase;
const lmt_hard_filter_keyboard_phrase_branches_by_committed_phrase = api.lmt_hard_filter_keyboard_phrase_branches_by_committed_phrase;
const lmt_hard_filter_fret_phrase_branches_by_committed_phrase = api.lmt_hard_filter_fret_phrase_branches_by_committed_phrase;
const lmt_describe_fret_play_state = api.lmt_describe_fret_play_state;
const lmt_windowed_fret_positions_n = api.lmt_windowed_fret_positions_n;
const lmt_assess_fret_realization_n = api.lmt_assess_fret_realization_n;
const lmt_assess_fret_transition_n = api.lmt_assess_fret_transition_n;
const lmt_summarize_fret_realization_difficulty_n = api.lmt_summarize_fret_realization_difficulty_n;
const lmt_summarize_fret_transition_difficulty_n = api.lmt_summarize_fret_transition_difficulty_n;
const lmt_rank_fret_realizations_n = api.lmt_rank_fret_realizations_n;
const lmt_suggest_easier_fret_realization_n = api.lmt_suggest_easier_fret_realization_n;
const lmt_keyboard_key_coord = api.lmt_keyboard_key_coord;
const lmt_describe_keyboard_play_state = api.lmt_describe_keyboard_play_state;
const lmt_assess_keyboard_realization_n = api.lmt_assess_keyboard_realization_n;
const lmt_assess_keyboard_transition_n = api.lmt_assess_keyboard_transition_n;
const lmt_summarize_keyboard_realization_difficulty_n = api.lmt_summarize_keyboard_realization_difficulty_n;
const lmt_summarize_keyboard_transition_difficulty_n = api.lmt_summarize_keyboard_transition_difficulty_n;
const lmt_rank_keyboard_fingerings_n = api.lmt_rank_keyboard_fingerings_n;
const lmt_suggest_easier_keyboard_fingering_n = api.lmt_suggest_easier_keyboard_fingering_n;
const lmt_rank_keyboard_phrase_repairs_n = api.lmt_rank_keyboard_phrase_repairs_n;
const lmt_rank_fret_phrase_repairs_n = api.lmt_rank_fret_phrase_repairs_n;
const lmt_filter_next_steps_by_playability = api.lmt_filter_next_steps_by_playability;
const lmt_rank_keyboard_next_steps_by_playability = api.lmt_rank_keyboard_next_steps_by_playability;
const lmt_rank_keyboard_next_steps_by_committed_phrase = api.lmt_rank_keyboard_next_steps_by_committed_phrase;
const lmt_suggest_safer_keyboard_next_step_by_playability = api.lmt_suggest_safer_keyboard_next_step_by_playability;
const lmt_suggest_safer_keyboard_next_step_by_committed_phrase = api.lmt_suggest_safer_keyboard_next_step_by_committed_phrase;
const lmt_voiced_history_reset = api.lmt_voiced_history_reset;
const lmt_build_voiced_state = api.lmt_build_voiced_state;
const lmt_voiced_history_push = api.lmt_voiced_history_push;
const lmt_classify_motion = api.lmt_classify_motion;
const lmt_evaluate_motion_profile = api.lmt_evaluate_motion_profile;
const lmt_check_parallel_perfects = api.lmt_check_parallel_perfects;
const lmt_check_voice_crossing = api.lmt_check_voice_crossing;
const lmt_check_spacing = api.lmt_check_spacing;
const lmt_check_motion_independence = api.lmt_check_motion_independence;
const lmt_satb_range_low = api.lmt_satb_range_low;
const lmt_satb_range_high = api.lmt_satb_range_high;
const lmt_satb_range_contains = api.lmt_satb_range_contains;
const lmt_check_satb_registers = api.lmt_check_satb_registers;
const lmt_rank_next_steps = api.lmt_rank_next_steps;
const lmt_rank_keyboard_context_suggestions_by_playability = api.lmt_rank_keyboard_context_suggestions_by_playability;
const lmt_rank_keyboard_context_suggestions_by_committed_phrase = api.lmt_rank_keyboard_context_suggestions_by_committed_phrase;
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
    try testing.expectEqual(@sizeOf(c.lmt_hand_profile), @sizeOf(LmtHandProfile));
    try testing.expectEqual(@sizeOf(c.lmt_playability_difficulty_summary), @sizeOf(LmtPlayabilityDifficultySummary));
    try testing.expectEqual(@sizeOf(c.lmt_keyboard_phrase_event), @sizeOf(LmtKeyboardPhraseEvent));
    try testing.expectEqual(@sizeOf(c.lmt_fret_phrase_event), @sizeOf(LmtFretPhraseEvent));
    try testing.expectEqual(@sizeOf(c.lmt_keyboard_phrase_branch), @sizeOf(LmtKeyboardPhraseBranch));
    try testing.expectEqual(@sizeOf(c.lmt_fret_phrase_branch), @sizeOf(LmtFretPhraseBranch));
    try testing.expectEqual(@sizeOf(c.lmt_keyboard_phrase_step_candidates), @sizeOf(LmtKeyboardPhraseStepCandidates));
    try testing.expectEqual(@sizeOf(c.lmt_fret_phrase_step_candidates), @sizeOf(LmtFretPhraseStepCandidates));
    try testing.expectEqual(@sizeOf(c.lmt_keyboard_phrase_candidate_window), @sizeOf(LmtKeyboardPhraseCandidateWindow));
    try testing.expectEqual(@sizeOf(c.lmt_fret_phrase_candidate_window), @sizeOf(LmtFretPhraseCandidateWindow));
    try testing.expectEqual(@sizeOf(c.lmt_keyboard_committed_phrase_memory), @sizeOf(LmtKeyboardCommittedPhraseMemory));
    try testing.expectEqual(@sizeOf(c.lmt_fret_committed_phrase_memory), @sizeOf(LmtFretCommittedPhraseMemory));
    try testing.expectEqual(@sizeOf(c.lmt_playability_phrase_issue), @sizeOf(LmtPlayabilityPhraseIssue));
    try testing.expectEqual(@sizeOf(c.lmt_playability_phrase_summary), @sizeOf(LmtPlayabilityPhraseSummary));
    try testing.expectEqual(@sizeOf(c.lmt_playability_phrase_branch_summary), @sizeOf(LmtPlayabilityPhraseBranchSummary));
    try testing.expectEqual(@sizeOf(c.lmt_playability_phrase_branch_bias_summary), @sizeOf(LmtPhraseBranchBiasSummary));
    try testing.expectEqual(@sizeOf(c.lmt_ranked_keyboard_phrase_branch), @sizeOf(LmtRankedKeyboardPhraseBranch));
    try testing.expectEqual(@sizeOf(c.lmt_ranked_fret_phrase_branch), @sizeOf(LmtRankedFretPhraseBranch));
    try testing.expectEqual(@sizeOf(c.lmt_playability_repair_policy), @sizeOf(LmtPlayabilityRepairPolicy));
    try testing.expectEqual(@sizeOf(c.lmt_ranked_keyboard_phrase_repair), @sizeOf(LmtRankedKeyboardPhraseRepair));
    try testing.expectEqual(@sizeOf(c.lmt_ranked_fret_phrase_repair), @sizeOf(LmtRankedFretPhraseRepair));
    try testing.expectEqual(@sizeOf(c.lmt_temporal_load_state), @sizeOf(LmtTemporalLoadState));
    try testing.expectEqual(@sizeOf(c.lmt_fret_candidate_location), @sizeOf(LmtFretCandidateLocation));
    try testing.expectEqual(@sizeOf(c.lmt_fret_play_state), @sizeOf(LmtFretPlayState));
    try testing.expectEqual(@sizeOf(c.lmt_fret_realization_assessment), @sizeOf(LmtFretRealizationAssessment));
    try testing.expectEqual(@sizeOf(c.lmt_fret_transition_assessment), @sizeOf(LmtFretTransitionAssessment));
    try testing.expectEqual(@sizeOf(c.lmt_ranked_fret_realization), @sizeOf(LmtRankedFretRealization));
    try testing.expectEqual(@sizeOf(c.lmt_keybed_key_coord), @sizeOf(LmtKeybedKeyCoord));
    try testing.expectEqual(@sizeOf(c.lmt_keyboard_play_state), @sizeOf(LmtKeyboardPlayState));
    try testing.expectEqual(@sizeOf(c.lmt_keyboard_realization_assessment), @sizeOf(LmtKeyboardRealizationAssessment));
    try testing.expectEqual(@sizeOf(c.lmt_keyboard_transition_assessment), @sizeOf(LmtKeyboardTransitionAssessment));
    try testing.expectEqual(@sizeOf(c.lmt_ranked_keyboard_fingering), @sizeOf(LmtRankedKeyboardFingering));
    try testing.expectEqual(@sizeOf(c.lmt_ranked_keyboard_context_suggestion), @sizeOf(LmtRankedKeyboardContextSuggestion));
    try testing.expectEqual(@as(usize, 12), @sizeOf(c.lmt_context_suggestion));
    try testing.expectEqual(@as(usize, 4), @sizeOf(c.lmt_metric_position));
    try testing.expectEqual(@as(usize, 8), @sizeOf(c.lmt_voice));
    try testing.expectEqual(@as(usize, 8), @sizeOf(c.lmt_voice_motion));
    try testing.expectEqual(@sizeOf(c.lmt_cadence_destination_score), @sizeOf(LmtCadenceDestinationScore));
    try testing.expectEqual(@sizeOf(c.lmt_suspension_machine_summary), @sizeOf(LmtSuspensionMachineSummary));
    try testing.expectEqual(@sizeOf(c.lmt_voice_pair_violation), @sizeOf(LmtVoicePairViolation));
    try testing.expectEqual(@sizeOf(c.lmt_motion_independence_summary), @sizeOf(LmtMotionIndependenceSummary));
    try testing.expectEqual(@sizeOf(c.lmt_satb_register_violation), @sizeOf(LmtSatbRegisterViolation));
    try testing.expectEqual(@sizeOf(c.lmt_ranked_keyboard_next_step), @sizeOf(LmtRankedKeyboardNextStep));
    try testing.expectEqual(@sizeOf(c.lmt_orbifold_triad_node), @sizeOf(LmtOrbifoldTriadNode));
    try testing.expectEqual(@sizeOf(c.lmt_orbifold_triad_edge), @sizeOf(LmtOrbifoldTriadEdge));
    try testing.expectEqual(@as(usize, 0), @offsetOf(c.lmt_key_context, "tonic"));
    try testing.expectEqual(@as(usize, 1), @offsetOf(c.lmt_key_context, "quality"));
    try testing.expectEqual(@as(usize, 0), @offsetOf(c.lmt_guide_dot, "position"));
    try testing.expectEqual(@as(usize, 2), @offsetOf(c.lmt_guide_dot, "pitch_class"));
    try testing.expectEqual(@as(usize, 4), @offsetOf(c.lmt_guide_dot, "opacity"));
    try testing.expectEqual(@as(usize, 0), @offsetOf(c.lmt_hand_profile, "finger_count"));
    try testing.expectEqual(@as(usize, 6), @offsetOf(c.lmt_hand_profile, "reserved0"));
    try testing.expectEqual(@as(usize, 6), @offsetOf(c.lmt_temporal_load_state, "cumulative_span_steps"));
    try testing.expectEqual(@as(usize, 12), @offsetOf(c.lmt_fret_play_state, "load"));
    try testing.expectEqual(@offsetOf(c.lmt_fret_realization_assessment, "recommended_fingers"), @offsetOf(LmtFretRealizationAssessment, "recommended_fingers"));
    try testing.expectEqual(@offsetOf(c.lmt_fret_transition_assessment, "recommended_fingers"), @offsetOf(LmtFretTransitionAssessment, "recommended_fingers"));
    try testing.expectEqual(@offsetOf(c.lmt_ranked_fret_realization, "recommended_finger"), @offsetOf(LmtRankedFretRealization, "recommended_finger"));
    try testing.expectEqual(@as(usize, 4), @offsetOf(c.lmt_keybed_key_coord, "x"));
    try testing.expectEqual(@as(usize, 10), @offsetOf(c.lmt_keyboard_play_state, "load"));
    try testing.expectEqual(@offsetOf(c.lmt_keyboard_realization_assessment, "recommended_fingers"), @offsetOf(LmtKeyboardRealizationAssessment, "recommended_fingers"));
    try testing.expectEqual(@offsetOf(c.lmt_keyboard_transition_assessment, "to_fingers"), @offsetOf(LmtKeyboardTransitionAssessment, "to_fingers"));
    try testing.expectEqual(@offsetOf(c.lmt_ranked_keyboard_fingering, "fingers"), @offsetOf(LmtRankedKeyboardFingering, "fingers"));
    try testing.expectEqual(@as(usize, 4), @offsetOf(c.lmt_context_suggestion, "expanded_set"));
    try testing.expectEqual(@as(usize, 6), @offsetOf(c.lmt_context_suggestion, "pitch_class"));
    try testing.expectEqual(@as(usize, 10), @offsetOf(c.lmt_voiced_state, "cadence_state"));
    try testing.expectEqual(@as(usize, 17), @offsetOf(c.lmt_motion_summary, "voice_motions"));
    try testing.expectEqual(@as(usize, 3), @offsetOf(c.lmt_voice_pair_violation, "previous_interval_semitones"));
    try testing.expectEqual(@as(usize, 1), @offsetOf(c.lmt_motion_independence_summary, "direction"));
    try testing.expectEqual(@as(c_int, 0), c.LMT_SCALE_DIATONIC);
    try testing.expectEqual(@as(c_int, 28), c.LMT_MODE_NEAPOLITAN_MAJOR);
    try testing.expectEqual(@as(c_int, 3), c.LMT_CHORD_AUGMENTED);
    try testing.expectEqual(@as(c_int, 8), c.LMT_MAX_PHRASE_BRANCH_STEPS);
    try testing.expectEqual(@as(c_int, 8), c.LMT_MAX_BRANCH_STEP_CANDIDATES);
    try testing.expectEqual(@as(c_int, 3), c.LMT_PLAYABILITY_REASON_EXPANDS_CURRENT_WINDOW);
    try testing.expectEqual(@as(c_int, 2), c.LMT_PLAYABILITY_WARNING_HARD_LIMIT_EXCEEDED);
    try testing.expectEqual(@as(c_int, 4), c.LMT_PLAYABILITY_REASON_OPEN_STRING_RELIEF);
    try testing.expectEqual(@as(c_int, 8), c.LMT_PLAYABILITY_REASON_HAND_CONTINUITY_RESET);
    try testing.expectEqual(@as(c_int, 7), c.LMT_PLAYABILITY_WARNING_UNSUPPORTED_EXTENSION);
    try testing.expectEqual(@as(c_int, 8), c.LMT_PLAYABILITY_WARNING_THUMB_ON_BLACK_UNDER_STRETCH);
    try testing.expectEqual(@as(c_int, 11), c.LMT_PLAYABILITY_WARNING_FLUENCY_DEGRADATION_FROM_RECENT_MOTION);
    try testing.expectEqual(@as(c_int, 4), c.LMT_FRET_PLAYABILITY_BLOCKER_UNSUPPORTED_EXTENSION);
    try testing.expectEqual(@as(c_int, 1), c.LMT_FRET_TECHNIQUE_BASS_SIMANDL);
    try testing.expectEqual(@as(c_int, 1), c.LMT_KEYBOARD_HAND_RIGHT);
    try testing.expectEqual(@as(c_int, 3), c.LMT_KEYBOARD_PLAYABILITY_BLOCKER_IMPOSSIBLE_THUMB_CROSSING);
    try testing.expectEqual(@as(c_int, 1), c.LMT_PLAYABILITY_POLICY_MINIMAX_BOTTLENECK);
    try testing.expectEqual(@as(c_int, 1), c.LMT_PLAYABILITY_PHRASE_BRANCH_PLAYABLE_RECOVERY_DEFICIT);
    try testing.expectEqual(@as(c_int, 1), c.LMT_PLAYABILITY_PHRASE_BRANCH_HARD_FILTER_BLOCKED);
    try testing.expectEqual(@as(c_int, 4), c.LMT_PLAYABILITY_PHRASE_BRANCH_BIAS_PEAK_STRAIN_INCREASED);
    try testing.expectEqual(@as(c_int, 2), c.LMT_PLAYABILITY_PROFILE_SPAN_TOLERANT);
    try testing.expectEqual(@as(c_int, 1), c.LMT_PLAYABILITY_PHRASE_ISSUE_TRANSITION);
    try testing.expectEqual(@as(c_int, 2), c.LMT_PLAYABILITY_PHRASE_SEVERITY_BLOCKED);
    try testing.expectEqual(@as(c_int, 4), c.LMT_PLAYABILITY_PHRASE_DOMAIN_KEYBOARD_BLOCKER);
    try testing.expectEqual(@as(c_int, 3), c.LMT_PLAYABILITY_PHRASE_STRAIN_BLOCKED);
    try testing.expectEqual(@as(u32, playability.types.REASON_NAMES.len), lmt_playability_reason_count());
    try testing.expectEqual(@as(u32, playability.types.WARNING_NAMES.len), lmt_playability_warning_count());
    try testing.expectEqual(@as(u32, playability.ranking.POLICY_NAMES.len), lmt_playability_policy_count());
    try testing.expectEqual(@as(u32, playability.ranking.PHRASE_BRANCH_CLASSIFICATION_NAMES.len), lmt_playability_phrase_branch_class_count());
    try testing.expectEqual(@as(u32, playability.ranking.PHRASE_BRANCH_VISIBILITY_NAMES.len), lmt_playability_phrase_branch_visibility_count());
    try testing.expectEqual(@as(u32, playability.ranking.PHRASE_BRANCH_BIAS_REASON_NAMES.len), lmt_playability_phrase_branch_bias_reason_count());
    try testing.expectEqual(@as(u32, playability.profile.PRESET_NAMES.len), lmt_playability_profile_preset_count());
    try testing.expectEqual(@as(u32, playability.phrase.ISSUE_SCOPE_NAMES.len), lmt_playability_phrase_issue_scope_count());
    try testing.expectEqual(@as(u32, playability.phrase.ISSUE_SEVERITY_NAMES.len), lmt_playability_phrase_issue_severity_count());
    try testing.expectEqual(@as(u32, playability.phrase.FAMILY_DOMAIN_NAMES.len), lmt_playability_phrase_family_domain_count());
    try testing.expectEqual(@as(u32, playability.phrase.STRAIN_BUCKET_NAMES.len), lmt_playability_phrase_strain_bucket_count());
    try testing.expectEqual(@as(u32, playability.fret_assessment.BLOCKER_NAMES.len), lmt_fret_playability_blocker_count());
    try testing.expectEqual(@as(u32, playability.fret_assessment.PROFILE_NAMES.len), lmt_fret_technique_profile_count());
    try testing.expectEqual(@as(u32, playability.keyboard_assessment.HAND_ROLE_NAMES.len), lmt_keyboard_hand_count());
    try testing.expectEqual(@as(u32, playability.keyboard_assessment.BLOCKER_NAMES.len), lmt_keyboard_playability_blocker_count());
    try testing.expectEqualStrings("reachable in current window", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_reason_name(c.LMT_PLAYABILITY_REASON_REACHABLE_IN_CURRENT_WINDOW))), 0));
    try testing.expectEqualStrings("hand continuity reset", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_reason_name(c.LMT_PLAYABILITY_REASON_HAND_CONTINUITY_RESET))), 0));
    try testing.expectEqualStrings("hard limit exceeded", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_warning_name(c.LMT_PLAYABILITY_WARNING_HARD_LIMIT_EXCEEDED))), 0));
    try testing.expectEqualStrings("minimax-bottleneck", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_policy_name(c.LMT_PLAYABILITY_POLICY_MINIMAX_BOTTLENECK))), 0));
    try testing.expectEqualStrings("playable-recovery-improving", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_phrase_branch_class_name(c.LMT_PLAYABILITY_PHRASE_BRANCH_PLAYABLE_RECOVERY_IMPROVING))), 0));
    try testing.expectEqualStrings("hard-filter-blocked", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_phrase_branch_visibility_name(c.LMT_PLAYABILITY_PHRASE_BRANCH_HARD_FILTER_BLOCKED))), 0));
    try testing.expectEqualStrings("dominant reason reinforced", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_phrase_branch_bias_reason_name(c.LMT_PLAYABILITY_PHRASE_BRANCH_BIAS_DOMINANT_REASON_REINFORCED))), 0));
    try testing.expectEqualStrings("span-tolerant", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_profile_preset_name(c.LMT_PLAYABILITY_PROFILE_SPAN_TOLERANT))), 0));
    try testing.expectEqualStrings("transition", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_phrase_issue_scope_name(c.LMT_PLAYABILITY_PHRASE_ISSUE_TRANSITION))), 0));
    try testing.expectEqualStrings("blocked", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_phrase_issue_severity_name(c.LMT_PLAYABILITY_PHRASE_SEVERITY_BLOCKED))), 0));
    try testing.expectEqualStrings("keyboard blocker", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_phrase_family_domain_name(c.LMT_PLAYABILITY_PHRASE_DOMAIN_KEYBOARD_BLOCKER))), 0));
    try testing.expectEqualStrings("high", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_playability_phrase_strain_bucket_name(c.LMT_PLAYABILITY_PHRASE_STRAIN_HIGH))), 0));
    try testing.expectEqualStrings("unsupported extension", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_fret_playability_blocker_name(c.LMT_FRET_PLAYABILITY_BLOCKER_UNSUPPORTED_EXTENSION))), 0));
    try testing.expectEqualStrings("bass simandl", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_fret_technique_profile_name(c.LMT_FRET_TECHNIQUE_BASS_SIMANDL))), 0));
    try testing.expectEqualStrings("right hand", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_keyboard_hand_name(c.LMT_KEYBOARD_HAND_RIGHT))), 0));
    try testing.expectEqualStrings("shift hard limit", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_keyboard_playability_blocker_name(c.LMT_KEYBOARD_PLAYABILITY_BLOCKER_SHIFT_HARD_LIMIT))), 0));
    try testing.expectEqual(@as(u32, @sizeOf(LmtHandProfile)), lmt_sizeof_hand_profile());
    try testing.expectEqual(@as(u32, @sizeOf(LmtTemporalLoadState)), lmt_sizeof_temporal_load_state());
    try testing.expectEqual(@as(u32, @sizeOf(LmtFretCandidateLocation)), lmt_sizeof_fret_candidate_location());
    try testing.expectEqual(@as(u32, @sizeOf(LmtFretPlayState)), lmt_sizeof_fret_play_state());
    try testing.expectEqual(@as(u32, @sizeOf(LmtFretRealizationAssessment)), lmt_sizeof_fret_realization_assessment());
    try testing.expectEqual(@as(u32, @sizeOf(LmtFretTransitionAssessment)), lmt_sizeof_fret_transition_assessment());
    try testing.expectEqual(@as(u32, @sizeOf(LmtRankedFretRealization)), lmt_sizeof_ranked_fret_realization());
    try testing.expectEqual(@as(u32, @sizeOf(LmtKeybedKeyCoord)), lmt_sizeof_keybed_key_coord());
    try testing.expectEqual(@as(u32, @sizeOf(LmtKeyboardPlayState)), lmt_sizeof_keyboard_play_state());
    try testing.expectEqual(@as(u32, @sizeOf(LmtKeyboardRealizationAssessment)), lmt_sizeof_keyboard_realization_assessment());
    try testing.expectEqual(@as(u32, @sizeOf(LmtKeyboardTransitionAssessment)), lmt_sizeof_keyboard_transition_assessment());
    try testing.expectEqual(@as(u32, @sizeOf(LmtRankedKeyboardFingering)), lmt_sizeof_ranked_keyboard_fingering());
    try testing.expectEqual(@as(u32, @sizeOf(LmtRankedKeyboardContextSuggestion)), lmt_sizeof_ranked_keyboard_context_suggestion());
    try testing.expectEqual(@as(u32, @sizeOf(LmtRankedKeyboardNextStep)), lmt_sizeof_ranked_keyboard_next_step());
    try testing.expectEqual(@as(u32, @sizeOf(LmtPlayabilityDifficultySummary)), lmt_sizeof_playability_difficulty_summary());
    try testing.expectEqual(@as(u32, @sizeOf(LmtKeyboardPhraseEvent)), lmt_sizeof_keyboard_phrase_event());
    try testing.expectEqual(@as(u32, @sizeOf(LmtFretPhraseEvent)), lmt_sizeof_fret_phrase_event());
    try testing.expectEqual(@as(u32, @sizeOf(LmtKeyboardPhraseBranch)), lmt_sizeof_keyboard_phrase_branch());
    try testing.expectEqual(@as(u32, @sizeOf(LmtFretPhraseBranch)), lmt_sizeof_fret_phrase_branch());
    try testing.expectEqual(@as(u32, @sizeOf(LmtKeyboardPhraseStepCandidates)), lmt_sizeof_keyboard_phrase_step_candidates());
    try testing.expectEqual(@as(u32, @sizeOf(LmtFretPhraseStepCandidates)), lmt_sizeof_fret_phrase_step_candidates());
    try testing.expectEqual(@as(u32, @sizeOf(LmtKeyboardPhraseCandidateWindow)), lmt_sizeof_keyboard_phrase_candidate_window());
    try testing.expectEqual(@as(u32, @sizeOf(LmtFretPhraseCandidateWindow)), lmt_sizeof_fret_phrase_candidate_window());
    try testing.expectEqual(@as(u32, @sizeOf(LmtKeyboardCommittedPhraseMemory)), lmt_sizeof_keyboard_committed_phrase_memory());
    try testing.expectEqual(@as(u32, @sizeOf(LmtFretCommittedPhraseMemory)), lmt_sizeof_fret_committed_phrase_memory());
    try testing.expectEqual(@as(u32, @sizeOf(LmtPlayabilityPhraseIssue)), lmt_sizeof_playability_phrase_issue());
    try testing.expectEqual(@as(u32, @sizeOf(LmtPlayabilityPhraseSummary)), lmt_sizeof_playability_phrase_summary());
    try testing.expectEqual(@as(u32, @sizeOf(LmtPlayabilityPhraseBranchSummary)), lmt_sizeof_playability_phrase_branch_summary());
    try testing.expectEqual(@as(u32, @sizeOf(LmtPhraseBranchBiasSummary)), lmt_sizeof_playability_phrase_branch_bias_summary());
    try testing.expectEqual(@as(u32, @sizeOf(LmtRankedKeyboardPhraseBranch)), lmt_sizeof_ranked_keyboard_phrase_branch());
    try testing.expectEqual(@as(u32, @sizeOf(LmtRankedFretPhraseBranch)), lmt_sizeof_ranked_fret_phrase_branch());
    try testing.expectEqual(@as(u32, @sizeOf(LmtPlayabilityRepairPolicy)), lmt_sizeof_playability_repair_policy());
    try testing.expectEqual(@as(u32, @sizeOf(LmtRankedKeyboardPhraseRepair)), lmt_sizeof_ranked_keyboard_phrase_repair());
    try testing.expectEqual(@as(u32, @sizeOf(LmtRankedFretPhraseRepair)), lmt_sizeof_ranked_fret_phrase_repair());
    try testing.expectEqual(@as(u32, counterpoint.MAX_VOICES), lmt_counterpoint_max_voices());
    try testing.expectEqual(@as(u32, counterpoint.HISTORY_CAPACITY), lmt_counterpoint_history_capacity());
    try testing.expectEqual(@as(u32, @sizeOf(LmtVoicedState)), lmt_sizeof_voiced_state());
    try testing.expectEqual(@as(u32, @sizeOf(LmtVoicedHistory)), lmt_sizeof_voiced_history());
    try testing.expectEqual(@as(u32, @sizeOf(LmtNextStepSuggestion)), lmt_sizeof_next_step_suggestion());
    try testing.expectEqual(@as(u32, @sizeOf(LmtVoicePairViolation)), lmt_sizeof_voice_pair_violation());
    try testing.expectEqual(@as(u32, @sizeOf(LmtMotionIndependenceSummary)), lmt_sizeof_motion_independence_summary());
    try testing.expectEqual(@as(u32, @sizeOf(LmtSatbRegisterViolation)), lmt_sizeof_satb_register_violation());
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
    try testing.expectEqual(@as(u32, 12), lmt_ordered_scale_pattern_count());
    try testing.expectEqualStrings("Barry Harris Major 6th Diminished", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_ordered_scale_pattern_name(10))), 0));
    try testing.expectEqual(@as(u8, 8), lmt_ordered_scale_degree_count(10));
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 2, 4, 5, 7, 8, 9, 11 })), lmt_ordered_scale_pitch_class_set(10, 0));
    try testing.expect(lmt_ordered_scale_pattern_name(lmt_ordered_scale_pattern_count()) == null);
    var bh_degree: u8 = 255;
    try testing.expectEqual(@as(u8, c.LMT_BARRY_HARRIS_CHORD_TONE), lmt_barry_harris_parity(10, 0, 60, @ptrCast(&bh_degree)));
    try testing.expectEqual(@as(u8, 0), bh_degree);
    try testing.expectEqual(@as(u8, c.LMT_BARRY_HARRIS_PASSING_TONE), lmt_barry_harris_parity(10, 0, 62, @ptrCast(&bh_degree)));
    try testing.expectEqual(@as(u8, 1), bh_degree);
    try testing.expectEqual(@as(u8, c.LMT_BARRY_HARRIS_NOT_APPLICABLE), lmt_barry_harris_parity(10, 0, 61, @ptrCast(&bh_degree)));
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

test "c abi satb register helpers" {
    try testing.expectEqual(@as(u32, 4), lmt_satb_voice_count());
    try testing.expectEqualStrings("alto", std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_satb_voice_name(c.LMT_SATB_ALTO))), 0));
    try testing.expect(lmt_satb_voice_name(lmt_satb_voice_count()) == null);

    try testing.expectEqual(@as(u8, 40), lmt_satb_range_low(c.LMT_SATB_BASS));
    try testing.expectEqual(@as(u8, 64), lmt_satb_range_high(c.LMT_SATB_BASS));
    try testing.expect(lmt_satb_range_contains(c.LMT_SATB_ALTO, 60));
    try testing.expect(!lmt_satb_range_contains(c.LMT_SATB_ALTO, 54));

    var chorale = manualVoicedState(&[_]ManualVoicedVoice{
        .{ .id = 0, .midi = 36 },
        .{ .id = 1, .midi = 50 },
        .{ .id = 2, .midi = 57 },
        .{ .id = 3, .midi = 84 },
    });
    var violations: [4]LmtSatbRegisterViolation = undefined;
    const total = lmt_check_satb_registers(@ptrCast(&chorale), @ptrCast(&violations), violations.len);
    try testing.expectEqual(@as(u32, 2), total);
    try testing.expectEqual(@as(u8, c.LMT_SATB_BASS), violations[0].satb_voice);
    try testing.expectEqual(@as(i8, -1), violations[0].direction);
    try testing.expectEqual(@as(u8, c.LMT_SATB_SOPRANO), violations[1].satb_voice);
    try testing.expectEqual(@as(i8, 1), violations[1].direction);
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

    const satb_voice_count = lmt_satb_voice_count();
    try testing.expectEqual(@as(u32, 4), satb_voice_count);
    const satb_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_satb_voice_name(0))), 0);
    try testing.expectEqualStrings("soprano", satb_name);
    try testing.expect(lmt_satb_voice_name(satb_voice_count) == null);
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

test "c abi playability foundation helpers" {
    var fret_profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_fret_hand_profile(@ptrCast(&fret_profile)));
    try testing.expectEqual(@as(u8, 4), fret_profile.finger_count);
    try testing.expectEqual(@as(u8, 4), fret_profile.comfort_span_steps);
    try testing.expectEqual(@as(u8, 5), fret_profile.limit_span_steps);
    try testing.expectEqual(@as(u8, 1), fret_profile.prefers_low_tension);

    var keyboard_profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&keyboard_profile)));
    try testing.expectEqual(@as(u8, 5), keyboard_profile.finger_count);
    try testing.expectEqual(@as(u8, 12), keyboard_profile.comfort_span_steps);

    const frets = [_]i8{ -1, 3, 2, 0, 1, 0 };
    var fret_state: LmtFretPlayState = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_describe_fret_play_state(@ptrCast(&frets), frets.len, @ptrCast(&fret_profile), null, @ptrCast(&fret_state)));
    try testing.expectEqual(@as(u8, 1), fret_state.anchor_fret);
    try testing.expectEqual(@as(u8, 5), fret_state.active_string_count);
    try testing.expectEqual(@as(u8, 3), fret_state.fretted_note_count);
    try testing.expectEqual(@as(u8, 2), fret_state.open_string_count);
    try testing.expectEqual(@as(u8, 2), fret_state.span_steps);
    try testing.expectEqual(@as(u8, 1), fret_state.comfort_fit);
    try testing.expectEqual(@as(u8, 1), fret_state.limit_fit);
    try testing.expectEqual(@as(u8, 1), fret_state.load.event_count);
    try testing.expectEqual(@as(u8, 1), fret_state.load.last_anchor_step);

    const tuning = [_]u8{ 40, 45, 50, 55, 59, 64 };
    var locations: [8]LmtFretCandidateLocation = undefined;
    const location_count = lmt_windowed_fret_positions_n(60, @ptrCast(&tuning), tuning.len, 7, @ptrCast(&fret_profile), @ptrCast(&locations), locations.len);
    try testing.expectEqual(@as(u32, 5), location_count);
    try testing.expectEqual(@as(u8, 1), locations[1].position.string);
    try testing.expectEqual(@as(u8, 15), locations[1].position.fret);
    try testing.expectEqual(@as(u8, 0), locations[1].in_window);
    try testing.expectEqual(@as(u8, 4), locations[1].shift_steps);
    try testing.expectEqual(@as(u8, 1), locations[2].in_window);

    var coord: LmtKeybedKeyCoord = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_keyboard_key_coord(61, @ptrCast(&coord)));
    try testing.expectEqual(@as(u8, 61), coord.midi);
    try testing.expectEqual(@as(u8, 1), coord.is_black);
    try testing.expectApproxEqAbs(@as(f32, 35.65), coord.x, 0.0001);

    const notes = [_]u8{ 60, 64, 67 };
    var load: LmtTemporalLoadState = .{
        .event_count = 1,
        .last_anchor_step = 60,
        .last_span_steps = 4,
        .last_shift_steps = 0,
        .peak_span_steps = 4,
        .peak_shift_steps = 0,
        .cumulative_span_steps = 4,
        .cumulative_shift_steps = 0,
    };
    var keyboard_state: LmtKeyboardPlayState = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_describe_keyboard_play_state(@ptrCast(&notes), notes.len, @ptrCast(&keyboard_profile), @ptrCast(&load), @ptrCast(&keyboard_state)));
    try testing.expectEqual(@as(u8, 63), keyboard_state.anchor_midi);
    try testing.expectEqual(@as(u8, 7), keyboard_state.span_semitones);
    try testing.expectEqual(@as(u8, 0), keyboard_state.black_key_count);
    try testing.expectEqual(@as(u8, 3), keyboard_state.white_key_count);
    try testing.expectEqual(@as(u8, 2), keyboard_state.load.event_count);
    try testing.expectEqual(@as(u8, 3), keyboard_state.load.last_shift_steps);
}

test "c abi playability profile presets and summaries" {
    var keyboard_profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&keyboard_profile)));

    var compact_profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_playability_profile_from_preset(
        c.LMT_PLAYABILITY_PROFILE_COMPACT_BEGINNER,
        @ptrCast(&keyboard_profile),
        @ptrCast(&compact_profile),
    ));
    try testing.expectEqual(keyboard_profile.finger_count, compact_profile.finger_count);
    try testing.expect(compact_profile.comfort_span_steps < keyboard_profile.comfort_span_steps);
    try testing.expect(compact_profile.comfort_shift_steps < keyboard_profile.comfort_shift_steps);

    const from_notes = [_]u8{60};
    const to_notes = [_]u8{72};
    var summary: LmtPlayabilityDifficultySummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_summarize_keyboard_transition_difficulty_n(
        @ptrCast(&from_notes),
        from_notes.len,
        @ptrCast(&to_notes),
        to_notes.len,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&compact_profile),
        null,
        @ptrCast(&summary),
    ));
    try testing.expectEqual(@as(u8, 0), summary.accepted);
    try testing.expect(summary.blocker_count > 0);
    try testing.expect(summary.limit_shift_margin < 0);
    try testing.expectEqual(@as(u8, 12), summary.shift_steps);
}

test "c abi phrase issue summaries" {
    const issues = [_]LmtPlayabilityPhraseIssue{
        .{
            .scope = c.LMT_PLAYABILITY_PHRASE_ISSUE_EVENT,
            .severity = c.LMT_PLAYABILITY_PHRASE_SEVERITY_ADVISORY,
            .family_domain = c.LMT_PLAYABILITY_PHRASE_DOMAIN_REASON,
            .family_index = c.LMT_PLAYABILITY_REASON_REACHABLE_IN_CURRENT_WINDOW,
            .event_index = 0,
            .related_event_index = playability.phrase.NONE_EVENT_INDEX,
            .magnitude = 0,
            .reserved0 = 0,
        },
        .{
            .scope = c.LMT_PLAYABILITY_PHRASE_ISSUE_EVENT,
            .severity = c.LMT_PLAYABILITY_PHRASE_SEVERITY_WARNING,
            .family_domain = c.LMT_PLAYABILITY_PHRASE_DOMAIN_WARNING,
            .family_index = c.LMT_PLAYABILITY_WARNING_SHIFT_REQUIRED,
            .event_index = 1,
            .related_event_index = playability.phrase.NONE_EVENT_INDEX,
            .magnitude = 3,
            .reserved0 = 0,
        },
        .{
            .scope = c.LMT_PLAYABILITY_PHRASE_ISSUE_TRANSITION,
            .severity = c.LMT_PLAYABILITY_PHRASE_SEVERITY_BLOCKED,
            .family_domain = c.LMT_PLAYABILITY_PHRASE_DOMAIN_KEYBOARD_BLOCKER,
            .family_index = c.LMT_KEYBOARD_PLAYABILITY_BLOCKER_SHIFT_HARD_LIMIT,
            .event_index = 1,
            .related_event_index = 2,
            .magnitude = 9,
            .reserved0 = 0,
        },
    };

    var summary: LmtPlayabilityPhraseSummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_summarize_playability_phrase_issues(
        3,
        @ptrCast(&issues),
        issues.len,
        @ptrCast(&summary),
    ));
    try testing.expectEqual(@as(u16, 3), summary.event_count);
    try testing.expectEqual(@as(u16, 3), summary.issue_count);
    try testing.expectEqual(@as(u16, 1), summary.first_blocked_transition_from_index);
    try testing.expectEqual(@as(u16, 2), summary.first_blocked_transition_to_index);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_PHRASE_SEVERITY_BLOCKED), summary.bottleneck_severity);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_PHRASE_DOMAIN_KEYBOARD_BLOCKER), summary.bottleneck_domain);
    try testing.expectEqual(@as(u8, c.LMT_KEYBOARD_PLAYABILITY_BLOCKER_SHIFT_HARD_LIMIT), summary.bottleneck_family_index);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_PHRASE_STRAIN_BLOCKED), summary.strain_bucket);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_REASON_REACHABLE_IN_CURRENT_WINDOW), summary.dominant_reason_family);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_WARNING_SHIFT_REQUIRED), summary.dominant_warning_family);
    try testing.expectEqual(@as(u16, 1), summary.severity_counts[c.LMT_PLAYABILITY_PHRASE_SEVERITY_ADVISORY]);
    try testing.expectEqual(@as(u16, 1), summary.severity_counts[c.LMT_PLAYABILITY_PHRASE_SEVERITY_WARNING]);
    try testing.expectEqual(@as(u16, 1), summary.severity_counts[c.LMT_PLAYABILITY_PHRASE_SEVERITY_BLOCKED]);
    try testing.expectEqual(@as(u16, 1), summary.recovery_deficit_start_index);
    try testing.expectEqual(@as(u16, 2), summary.recovery_deficit_end_index);
    try testing.expectEqual(@as(u16, 2), summary.longest_recovery_deficit_run);
}

test "c abi phrase branch summaries" {
    const issues = [_]LmtPlayabilityPhraseIssue{
        .{
            .scope = c.LMT_PLAYABILITY_PHRASE_ISSUE_EVENT,
            .severity = c.LMT_PLAYABILITY_PHRASE_SEVERITY_ADVISORY,
            .family_domain = c.LMT_PLAYABILITY_PHRASE_DOMAIN_REASON,
            .family_index = c.LMT_PLAYABILITY_REASON_OPEN_STRING_RELIEF,
            .event_index = 0,
            .related_event_index = playability.phrase.NONE_EVENT_INDEX,
            .magnitude = 0,
            .reserved0 = 0,
        },
        .{
            .scope = c.LMT_PLAYABILITY_PHRASE_ISSUE_EVENT,
            .severity = c.LMT_PLAYABILITY_PHRASE_SEVERITY_WARNING,
            .family_domain = c.LMT_PLAYABILITY_PHRASE_DOMAIN_WARNING,
            .family_index = c.LMT_PLAYABILITY_WARNING_SHIFT_REQUIRED,
            .event_index = 1,
            .related_event_index = playability.phrase.NONE_EVENT_INDEX,
            .magnitude = 3,
            .reserved0 = 0,
        },
        .{
            .scope = c.LMT_PLAYABILITY_PHRASE_ISSUE_TRANSITION,
            .severity = c.LMT_PLAYABILITY_PHRASE_SEVERITY_BLOCKED,
            .family_domain = c.LMT_PLAYABILITY_PHRASE_DOMAIN_KEYBOARD_BLOCKER,
            .family_index = c.LMT_KEYBOARD_PLAYABILITY_BLOCKER_SHIFT_HARD_LIMIT,
            .event_index = 1,
            .related_event_index = 2,
            .magnitude = 8,
            .reserved0 = 0,
        },
    };

    var summary: LmtPlayabilityPhraseBranchSummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_summarize_playability_phrase_branch_issues(
        3,
        @ptrCast(&issues),
        issues.len,
        @ptrCast(&summary),
    ));
    try testing.expectEqual(@as(u16, 3), summary.step_count);
    try testing.expectEqual(@as(u16, 2), summary.first_blocked_step_index);
    try testing.expectEqual(@as(u16, 1), summary.first_blocked_transition_from_index);
    try testing.expectEqual(@as(u16, 2), summary.first_blocked_transition_to_index);
    try testing.expectEqual(@as(u16, 2), summary.peak_strain_step_index);
    try testing.expectEqual(@as(u16, 8), summary.peak_strain_magnitude);
    try testing.expectEqual(@as(u16, 1), summary.improving_window_count);
    try testing.expectEqual(@as(u16, 2), summary.deficit_window_count);
    try testing.expectEqual(@as(u16, 0), summary.neutral_window_count);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_PHRASE_STRAIN_BLOCKED), summary.strain_bucket);
}

test "c abi playability repair reflection and defaults" {
    try testing.expectEqual(@as(u32, 3), lmt_playability_repair_class_count());
    try testing.expectEqualStrings("realization-only", std.mem.span(lmt_playability_repair_class_name(0).?));
    try testing.expectEqualStrings("register-adjusted", std.mem.span(lmt_playability_repair_class_name(1).?));
    try testing.expectEqualStrings("texture-reduced", std.mem.span(lmt_playability_repair_class_name(2).?));
    try testing.expectEqual(@as(?[*:0]const u8, null), lmt_playability_repair_class_name(9));

    var policy: LmtPlayabilityRepairPolicy = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_playability_repair_policy(
        c.LMT_PLAYABILITY_REPAIR_TEXTURE_REDUCED,
        @ptrCast(&policy),
    ));
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_REPAIR_TEXTURE_REDUCED), policy.max_class);
    try testing.expectEqual(@as(u8, 1), policy.preserve_bass);
    try testing.expectEqual(@as(u8, 1), policy.preserve_top_voice);
    try testing.expectEqual(@as(u8, 1), policy.prefer_inner_changes);
    try testing.expectEqual(@as(u8, 1), policy.allow_hand_reassignment);
}

test "c abi keyboard phrase audit wrapper" {
    var profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&profile)));
    profile.comfort_span_steps = 4;
    profile.limit_span_steps = 12;
    profile.comfort_shift_steps = 12;
    profile.limit_shift_steps = 12;

    const events = [_]LmtKeyboardPhraseEvent{
        .{ .note_count = 2, .hand = c.LMT_KEYBOARD_HAND_RIGHT, .reserved0 = 0, .reserved1 = 0, .notes = .{ 60, 67, 0, 0, 0 } },
        .{ .note_count = 2, .hand = c.LMT_KEYBOARD_HAND_RIGHT, .reserved0 = 0, .reserved1 = 0, .notes = .{ 60, 67, 0, 0, 0 } },
        .{ .note_count = 2, .hand = c.LMT_KEYBOARD_HAND_RIGHT, .reserved0 = 0, .reserved1 = 0, .notes = .{ 60, 67, 0, 0, 0 } },
    };

    var issues: [64]LmtPlayabilityPhraseIssue = undefined;
    var summary: LmtPlayabilityPhraseSummary = undefined;
    const logical = lmt_audit_keyboard_phrase_n(
        @ptrCast(&events),
        events.len,
        @ptrCast(&profile),
        @ptrCast(&issues),
        issues.len,
        @ptrCast(&summary),
    );

    try testing.expect(logical > 0);
    try testing.expectEqual(@as(u16, 3), summary.event_count);
    try testing.expect(summary.longest_recovery_deficit_run >= 1);

    var found_transition_warning = false;
    for (issues[0..@min(logical, issues.len)]) |issue| {
        if (issue.scope == c.LMT_PLAYABILITY_PHRASE_ISSUE_TRANSITION and
            issue.family_domain == c.LMT_PLAYABILITY_PHRASE_DOMAIN_WARNING)
        {
            found_transition_warning = true;
        }
    }
    try testing.expect(found_transition_warning);
}

test "c abi keyboard phrase branch wrapper" {
    var profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&profile)));
    profile.comfort_span_steps = 4;
    profile.limit_span_steps = 12;
    profile.comfort_shift_steps = 12;
    profile.limit_shift_steps = 12;

    const event = LmtKeyboardPhraseEvent{
        .note_count = 2,
        .hand = c.LMT_KEYBOARD_HAND_RIGHT,
        .reserved0 = 0,
        .reserved1 = 0,
        .notes = .{ 60, 67, 0, 0, 0 },
    };
    var branch = std.mem.zeroes(LmtKeyboardPhraseBranch);
    branch.step_count = 3;
    branch.steps[0] = event;
    branch.steps[1] = event;
    branch.steps[2] = event;

    var summary: LmtPlayabilityPhraseBranchSummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_summarize_keyboard_phrase_branch_n(
        @ptrCast(&branch),
        @ptrCast(&profile),
        @ptrCast(&summary),
    ));
    try testing.expectEqual(@as(u16, 3), summary.step_count);
    try testing.expect(summary.deficit_window_count >= 2);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_PHRASE_STRAIN_HIGH), summary.strain_bucket);
}

test "c abi committed keyboard phrase memory helpers and audit wrapper" {
    var profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&profile)));
    profile.comfort_span_steps = 4;
    profile.limit_span_steps = 12;
    profile.comfort_shift_steps = 12;
    profile.limit_shift_steps = 12;

    var memory = std.mem.zeroes(LmtKeyboardCommittedPhraseMemory);
    lmt_keyboard_committed_phrase_reset(@ptrCast(&memory));
    try testing.expectEqual(@as(u32, 0), lmt_keyboard_committed_phrase_len(@ptrCast(&memory)));

    const event = LmtKeyboardPhraseEvent{
        .note_count = 2,
        .hand = c.LMT_KEYBOARD_HAND_RIGHT,
        .reserved0 = 0,
        .reserved1 = 0,
        .notes = .{ 60, 67, 0, 0, 0 },
    };
    try testing.expectEqual(@as(u32, 1), lmt_keyboard_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event)));
    try testing.expectEqual(@as(u32, 2), lmt_keyboard_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event)));
    try testing.expectEqual(@as(u32, 3), lmt_keyboard_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event)));
    try testing.expectEqual(@as(u32, 3), lmt_keyboard_committed_phrase_len(@ptrCast(&memory)));

    var issues: [64]LmtPlayabilityPhraseIssue = undefined;
    var summary: LmtPlayabilityPhraseSummary = undefined;
    const logical = lmt_audit_committed_keyboard_phrase_n(
        @ptrCast(&memory),
        @ptrCast(&profile),
        @ptrCast(&issues),
        issues.len,
        @ptrCast(&summary),
    );

    try testing.expect(logical > 0);
    try testing.expectEqual(@as(u16, 3), summary.event_count);
    try testing.expect(summary.longest_recovery_deficit_run >= 1);
}

test "c abi keyboard phrase branch ranking and hard filter wrappers" {
    var profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&profile)));
    profile.comfort_span_steps = 12;
    profile.limit_span_steps = 14;
    profile.comfort_shift_steps = 1;
    profile.limit_shift_steps = 1;

    var memory = std.mem.zeroes(LmtKeyboardCommittedPhraseMemory);
    lmt_keyboard_committed_phrase_reset(@ptrCast(&memory));
    const committed = LmtKeyboardPhraseEvent{
        .note_count = 1,
        .hand = c.LMT_KEYBOARD_HAND_RIGHT,
        .reserved0 = 0,
        .reserved1 = 0,
        .notes = .{ 72, 0, 0, 0, 0 },
    };
    try testing.expectEqual(@as(u32, 1), lmt_keyboard_committed_phrase_push(@ptrCast(&memory), @ptrCast(&committed)));

    var branches = std.mem.zeroes([3]LmtKeyboardPhraseBranch);
    branches[0].step_count = 1;
    branches[0].steps[0] = .{ .note_count = 1, .hand = c.LMT_KEYBOARD_HAND_RIGHT, .reserved0 = 0, .reserved1 = 0, .notes = .{ 48, 0, 0, 0, 0 } };
    branches[1].step_count = 1;
    branches[1].steps[0] = .{ .note_count = 1, .hand = c.LMT_KEYBOARD_HAND_RIGHT, .reserved0 = 0, .reserved1 = 0, .notes = .{ 73, 0, 0, 0, 0 } };
    branches[2].step_count = 1;
    branches[2].steps[0] = .{ .note_count = 1, .hand = c.LMT_KEYBOARD_HAND_LEFT, .reserved0 = 0, .reserved1 = 0, .notes = .{ 48, 0, 0, 0, 0 } };

    var ranked: [3]LmtRankedKeyboardPhraseBranch = undefined;
    const total = lmt_rank_keyboard_phrase_branches_by_committed_phrase(
        @ptrCast(&memory),
        @ptrCast(&branches),
        branches.len,
        @ptrCast(&profile),
        c.LMT_PLAYABILITY_POLICY_BALANCED,
        c.LMT_PLAYABILITY_PHRASE_BRANCH_KEEP_BLOCKED,
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expectEqual(@as(u32, 3), total);
    try testing.expectEqual(@as(u32, 2), ranked[0].candidate_index);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_PHRASE_BRANCH_PLAYABLE_RECOVERY_IMPROVING), ranked[0].classification);
    try testing.expect((ranked[0].bias.bias_reason_bits & (@as(u32, 1) << c.LMT_PLAYABILITY_PHRASE_BRANCH_BIAS_CONTINUITY_RESET_FROM_HAND_SWITCH)) != 0);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_PHRASE_BRANCH_BLOCKED), ranked[2].classification);

    var accepted_only = std.mem.zeroes([3]LmtKeyboardPhraseBranch);
    const filtered = lmt_hard_filter_keyboard_phrase_branches_by_committed_phrase(
        @ptrCast(&memory),
        @ptrCast(&branches),
        branches.len,
        @ptrCast(&profile),
        @ptrCast(&accepted_only),
        accepted_only.len,
    );
    try testing.expectEqual(@as(u32, 2), filtered);
    try testing.expectEqual(@as(u8, 73), accepted_only[0].steps[0].notes[0]);
    try testing.expectEqual(@as(u8, c.LMT_KEYBOARD_HAND_LEFT), accepted_only[1].steps[0].hand);
}

test "c abi keyboard phrase repair wrapper" {
    var profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&profile)));

    var memory = std.mem.zeroes(LmtKeyboardCommittedPhraseMemory);
    lmt_keyboard_committed_phrase_reset(@ptrCast(&memory));
    const events = [_]LmtKeyboardPhraseEvent{
        .{ .note_count = 1, .hand = c.LMT_KEYBOARD_HAND_RIGHT, .reserved0 = 0, .reserved1 = 0, .notes = .{ 72, 0, 0, 0, 0 } },
        .{ .note_count = 1, .hand = c.LMT_KEYBOARD_HAND_RIGHT, .reserved0 = 0, .reserved1 = 0, .notes = .{ 48, 0, 0, 0, 0 } },
    };
    for (events) |event| {
        try testing.expect(lmt_keyboard_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event)) > 0);
    }

    var policy: LmtPlayabilityRepairPolicy = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_playability_repair_policy(
        c.LMT_PLAYABILITY_REPAIR_REALIZATION_ONLY,
        @ptrCast(&policy),
    ));

    var ranked: [playability.repair.MAX_PHRASE_REPAIRS]LmtRankedKeyboardPhraseRepair = undefined;
    const total = lmt_rank_keyboard_phrase_repairs_n(
        @ptrCast(&memory),
        @ptrCast(&profile),
        @ptrCast(&policy),
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expect(total > 0);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_REPAIR_REALIZATION_ONLY), ranked[0].repair_class);
    try testing.expectEqual(@as(u8, 0), ranked[0].crossed_musical_change_boundary);
    try testing.expectEqual(@as(u8, c.LMT_KEYBOARD_HAND_LEFT), ranked[0].replacement_event.hand);
    try testing.expect(ranked[0].after_summary.bottleneck_magnitude <= ranked[0].before_summary.bottleneck_magnitude);
}

test "c abi fret phrase audit wrapper" {
    var profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_fret_hand_profile(@ptrCast(&profile)));
    profile.comfort_shift_steps = 2;
    profile.limit_shift_steps = 3;

    const tuning = [_]u8{ 40, 45, 50, 55 };
    const events = [_]LmtFretPhraseEvent{
        .{ .fret_count = 4, .reserved0 = 0, .reserved1 = 0, .reserved2 = 0, .frets = .{ 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 } },
        .{ .fret_count = 4, .reserved0 = 0, .reserved1 = 0, .reserved2 = 0, .frets = .{ 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 } },
        .{ .fret_count = 4, .reserved0 = 0, .reserved1 = 0, .reserved2 = 0, .frets = .{ 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 } },
    };

    var issues: [64]LmtPlayabilityPhraseIssue = undefined;
    var summary: LmtPlayabilityPhraseSummary = undefined;
    const logical = lmt_audit_fret_phrase_n(
        @ptrCast(&events),
        events.len,
        @ptrCast(&tuning),
        tuning.len,
        c.LMT_FRET_TECHNIQUE_GENERIC_GUITAR,
        @ptrCast(&profile),
        @ptrCast(&issues),
        issues.len,
        @ptrCast(&summary),
    );

    try testing.expect(logical > 0);
    try testing.expectEqual(@as(u16, 0), summary.first_blocked_transition_from_index);
    try testing.expectEqual(@as(u16, 1), summary.first_blocked_transition_to_index);

    var found_shift_blocker = false;
    for (issues[0..@min(logical, issues.len)]) |issue| {
        if (issue.scope == c.LMT_PLAYABILITY_PHRASE_ISSUE_TRANSITION and
            issue.family_domain == c.LMT_PLAYABILITY_PHRASE_DOMAIN_FRET_BLOCKER and
            issue.family_index == c.LMT_FRET_PLAYABILITY_BLOCKER_SHIFT_HARD_LIMIT)
        {
            found_shift_blocker = true;
        }
    }
    try testing.expect(found_shift_blocker);
}

test "c abi committed fret phrase memory helpers and audit wrapper" {
    var profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_fret_hand_profile(@ptrCast(&profile)));
    profile.comfort_shift_steps = 2;
    profile.limit_shift_steps = 3;

    var memory = std.mem.zeroes(LmtFretCommittedPhraseMemory);
    lmt_fret_committed_phrase_reset(@ptrCast(&memory));
    try testing.expectEqual(@as(u32, 0), lmt_fret_committed_phrase_len(@ptrCast(&memory)));

    const event_a = LmtFretPhraseEvent{
        .fret_count = 4,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .frets = .{ 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
    };
    const event_b = LmtFretPhraseEvent{
        .fret_count = 4,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .frets = .{ 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
    };
    const event_c = LmtFretPhraseEvent{
        .fret_count = 4,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .frets = .{ 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
    };

    try testing.expectEqual(@as(u32, 1), lmt_fret_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event_a)));
    try testing.expectEqual(@as(u32, 2), lmt_fret_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event_b)));
    try testing.expectEqual(@as(u32, 3), lmt_fret_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event_c)));
    try testing.expectEqual(@as(u32, 3), lmt_fret_committed_phrase_len(@ptrCast(&memory)));

    const tuning = [_]u8{ 40, 45, 50, 55 };
    var issues: [64]LmtPlayabilityPhraseIssue = undefined;
    var summary: LmtPlayabilityPhraseSummary = undefined;
    const logical = lmt_audit_committed_fret_phrase_n(
        @ptrCast(&memory),
        @ptrCast(&tuning),
        tuning.len,
        c.LMT_FRET_TECHNIQUE_GENERIC_GUITAR,
        @ptrCast(&profile),
        @ptrCast(&issues),
        issues.len,
        @ptrCast(&summary),
    );

    try testing.expect(logical > 0);
    try testing.expectEqual(@as(u16, 3), summary.event_count);
    try testing.expectEqual(@as(u16, 0), summary.first_blocked_transition_from_index);
    try testing.expectEqual(@as(u16, 1), summary.first_blocked_transition_to_index);
}

test "c abi fret phrase branch wrapper" {
    var profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_fret_hand_profile(@ptrCast(&profile)));
    profile.comfort_shift_steps = 2;
    profile.limit_shift_steps = 3;

    const event_a = LmtFretPhraseEvent{
        .fret_count = 4,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .frets = .{ 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
    };
    const event_b = LmtFretPhraseEvent{
        .fret_count = 4,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .frets = .{ 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
    };
    const event_c = LmtFretPhraseEvent{
        .fret_count = 4,
        .reserved0 = 0,
        .reserved1 = 0,
        .reserved2 = 0,
        .frets = .{ 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
    };

    var branch = std.mem.zeroes(LmtFretPhraseBranch);
    branch.step_count = 3;
    branch.steps[0] = event_a;
    branch.steps[1] = event_b;
    branch.steps[2] = event_c;

    const tuning = [_]u8{ 40, 45, 50, 55 };
    var summary: LmtPlayabilityPhraseBranchSummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_summarize_fret_phrase_branch_n(
        @ptrCast(&branch),
        @ptrCast(&tuning),
        tuning.len,
        c.LMT_FRET_TECHNIQUE_GENERIC_GUITAR,
        @ptrCast(&profile),
        @ptrCast(&summary),
    ));
    try testing.expectEqual(@as(u16, 3), summary.step_count);
    try testing.expectEqual(@as(u16, 1), summary.first_blocked_step_index);
    try testing.expectEqual(@as(u16, 0), summary.first_blocked_transition_from_index);
    try testing.expectEqual(@as(u16, 1), summary.first_blocked_transition_to_index);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_PHRASE_STRAIN_BLOCKED), summary.strain_bucket);
}

test "c abi fret phrase branch ranking and hard filter wrappers" {
    const tuning = [_]u8{ 40, 45, 50, 55 };
    var hand_profile = LmtHandProfile{
        .finger_count = 4,
        .comfort_span_steps = 4,
        .limit_span_steps = 5,
        .comfort_shift_steps = 1,
        .limit_shift_steps = 3,
        .prefers_low_tension = 1,
        .reserved0 = 0,
        .reserved1 = 0,
    };

    var memory = std.mem.zeroes(LmtFretCommittedPhraseMemory);
    lmt_fret_committed_phrase_reset(@ptrCast(&memory));
    const committed_events = [_]LmtFretPhraseEvent{
        .{ .fret_count = 4, .reserved0 = 0, .reserved1 = 0, .reserved2 = 0, .frets = .{ 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 } },
        .{ .fret_count = 4, .reserved0 = 0, .reserved1 = 0, .reserved2 = 0, .frets = .{ 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 } },
    };
    for (committed_events) |event| {
        try testing.expect(lmt_fret_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event)) > 0);
    }

    var branches = std.mem.zeroes([2]LmtFretPhraseBranch);
    branches[0].step_count = 1;
    branches[0].steps[0] = .{ .fret_count = 4, .reserved0 = 0, .reserved1 = 0, .reserved2 = 0, .frets = .{ 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 } };
    branches[1].step_count = 1;
    branches[1].steps[0] = .{ .fret_count = 4, .reserved0 = 0, .reserved1 = 0, .reserved2 = 0, .frets = .{ 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 } };

    var ranked: [2]LmtRankedFretPhraseBranch = undefined;
    const total = lmt_rank_fret_phrase_branches_by_committed_phrase(
        @ptrCast(&memory),
        @ptrCast(&branches),
        branches.len,
        @ptrCast(&tuning),
        tuning.len,
        c.LMT_FRET_TECHNIQUE_GENERIC_GUITAR,
        @ptrCast(&hand_profile),
        c.LMT_PLAYABILITY_POLICY_CUMULATIVE_STRAIN,
        c.LMT_PLAYABILITY_PHRASE_BRANCH_KEEP_BLOCKED,
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expectEqual(@as(u32, 2), total);
    try testing.expect(ranked[0].summary.deficit_window_count <= ranked[1].summary.deficit_window_count);

    var accepted_only = std.mem.zeroes([2]LmtFretPhraseBranch);
    const filtered = lmt_hard_filter_fret_phrase_branches_by_committed_phrase(
        @ptrCast(&memory),
        @ptrCast(&branches),
        branches.len,
        @ptrCast(&tuning),
        tuning.len,
        c.LMT_FRET_TECHNIQUE_GENERIC_GUITAR,
        @ptrCast(&hand_profile),
        @ptrCast(&accepted_only),
        accepted_only.len,
    );
    try testing.expectEqual(@as(u32, 1), filtered);
    try testing.expectEqual(@as(i8, 12), accepted_only[0].steps[0].frets[0]);
}

test "c abi fret phrase repair wrapper" {
    const tuning = [_]u8{ 40, 45, 50, 55 };
    var hand_profile = LmtHandProfile{
        .finger_count = 4,
        .comfort_span_steps = 4,
        .limit_span_steps = 5,
        .comfort_shift_steps = 1,
        .limit_shift_steps = 3,
        .prefers_low_tension = 1,
        .reserved0 = 0,
        .reserved1 = 0,
    };

    var memory = std.mem.zeroes(LmtFretCommittedPhraseMemory);
    lmt_fret_committed_phrase_reset(@ptrCast(&memory));
    const events = [_]LmtFretPhraseEvent{
        .{ .fret_count = 4, .reserved0 = 0, .reserved1 = 0, .reserved2 = 0, .frets = .{ 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 } },
        .{ .fret_count = 4, .reserved0 = 0, .reserved1 = 0, .reserved2 = 0, .frets = .{ 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 } },
    };
    for (events) |event| {
        try testing.expect(lmt_fret_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event)) > 0);
    }

    var policy: LmtPlayabilityRepairPolicy = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_playability_repair_policy(
        c.LMT_PLAYABILITY_REPAIR_REALIZATION_ONLY,
        @ptrCast(&policy),
    ));

    var ranked: [playability.repair.MAX_PHRASE_REPAIRS]LmtRankedFretPhraseRepair = undefined;
    const total = lmt_rank_fret_phrase_repairs_n(
        @ptrCast(&memory),
        @ptrCast(&tuning),
        tuning.len,
        c.LMT_FRET_TECHNIQUE_GENERIC_GUITAR,
        @ptrCast(&hand_profile),
        @ptrCast(&policy),
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expect(total > 0);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_REPAIR_REALIZATION_ONLY), ranked[0].repair_class);
    try testing.expectEqual(@as(u8, 0), ranked[0].crossed_musical_change_boundary);
    try testing.expectEqual(@as(i8, -1), ranked[0].replacement_event.frets[0]);
    try testing.expectEqual(@as(i8, 5), ranked[0].replacement_event.frets[1]);
    try testing.expect(ranked[0].after_summary.bottleneck_magnitude <= ranked[0].before_summary.bottleneck_magnitude);
}

test "c abi fret playability assessment helpers" {
    var simandl_profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_fret_hand_profile_for_technique(c.LMT_FRET_TECHNIQUE_BASS_SIMANDL, @ptrCast(&simandl_profile)));
    try testing.expectEqual(@as(u8, 3), simandl_profile.finger_count);
    try testing.expectEqual(@as(u8, 2), simandl_profile.comfort_span_steps);

    const tuning = [_]u8{ 40, 45, 50, 55 };
    const frets = [_]i8{ 1, 4, -1, -1 };
    var realization: LmtFretRealizationAssessment = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_assess_fret_realization_n(
        @ptrCast(&frets),
        frets.len,
        @ptrCast(&tuning),
        tuning.len,
        c.LMT_FRET_TECHNIQUE_BASS_SIMANDL,
        @ptrCast(&simandl_profile),
        null,
        @ptrCast(&realization),
    ));
    try testing.expectEqual(@as(u8, 3), realization.state.span_steps);
    try testing.expectEqual(@as(u8, c.LMT_FRET_TECHNIQUE_BASS_SIMANDL), realization.profile);
    try testing.expect((realization.warning_bits & (@as(u32, 1) << c.LMT_PLAYABILITY_WARNING_UNSUPPORTED_EXTENSION)) != 0);
    try testing.expectEqual(@as(u8, 1), realization.recommended_fingers[0]);
    try testing.expectEqual(@as(u8, 4), realization.recommended_fingers[1]);

    const to_frets = [_]i8{ 5, 7, -1, -1 };
    var transition: LmtFretTransitionAssessment = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_assess_fret_transition_n(
        @ptrCast(&frets),
        @ptrCast(&to_frets),
        frets.len,
        @ptrCast(&tuning),
        tuning.len,
        c.LMT_FRET_TECHNIQUE_BASS_SIMANDL,
        @ptrCast(&simandl_profile),
        @ptrCast(&transition),
    ));
    try testing.expectEqual(@as(u8, 4), transition.anchor_delta_steps);
    try testing.expect((transition.warning_bits & (@as(u32, 1) << c.LMT_PLAYABILITY_WARNING_SHIFT_REQUIRED)) != 0);
    try testing.expect((transition.warning_bits & (@as(u32, 1) << c.LMT_PLAYABILITY_WARNING_EXCESSIVE_LONGITUDINAL_SHIFT)) != 0);

    var ranked: [8]LmtRankedFretRealization = undefined;
    const ranked_total = lmt_rank_fret_realizations_n(
        60,
        @ptrCast(&[_]u8{ 40, 45, 50, 55, 59, 64 }),
        6,
        7,
        c.LMT_FRET_TECHNIQUE_GENERIC_GUITAR,
        null,
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expectEqual(@as(u32, 5), ranked_total);
    try testing.expectEqual(@as(u8, 2), ranked[0].location.position.string);
    try testing.expectEqual(@as(u8, 10), ranked[0].location.position.fret);
    try testing.expectEqual(@as(u8, 4), ranked[0].recommended_finger);

    var summary: LmtPlayabilityDifficultySummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_summarize_fret_transition_difficulty_n(
        @ptrCast(&frets),
        @ptrCast(&to_frets),
        frets.len,
        @ptrCast(&tuning),
        tuning.len,
        c.LMT_FRET_TECHNIQUE_BASS_SIMANDL,
        @ptrCast(&simandl_profile),
        @ptrCast(&summary),
    ));
    try testing.expect(summary.warning_count > 0);
    try testing.expect(summary.shift_steps >= transition.anchor_delta_steps);

    var easier: LmtRankedFretRealization = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_suggest_easier_fret_realization_n(
        64,
        @ptrCast(&[_]u8{ 40, 45, 50, 55, 59, 64 }),
        6,
        0,
        c.LMT_FRET_TECHNIQUE_GENERIC_GUITAR,
        null,
        @ptrCast(&easier),
    ));
    try testing.expectEqual(@as(u8, 5), easier.location.position.string);
    try testing.expectEqual(@as(u8, 0), easier.location.position.fret);
}

test "c abi keyboard playability assessment helpers" {
    var keyboard_profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&keyboard_profile)));

    const notes = [_]u8{ 60, 64, 67 };
    var realization: LmtKeyboardRealizationAssessment = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_assess_keyboard_realization_n(
        @ptrCast(&notes),
        notes.len,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&keyboard_profile),
        null,
        @ptrCast(&realization),
    ));
    try testing.expectEqual(@as(u8, 3), realization.note_count);
    try testing.expectEqual(@as(u32, 0), realization.blocker_bits);
    try testing.expectEqual(@as(u8, 1), realization.recommended_fingers[0]);
    try testing.expectEqual(@as(u8, 3), realization.recommended_fingers[1]);
    try testing.expectEqual(@as(u8, 5), realization.recommended_fingers[2]);

    var previous_load: LmtTemporalLoadState = .{
        .event_count = 1,
        .last_anchor_step = 48,
        .last_span_steps = 0,
        .last_shift_steps = 0,
        .peak_span_steps = 0,
        .peak_shift_steps = 0,
        .cumulative_span_steps = 0,
        .cumulative_shift_steps = 0,
    };
    const from_notes = [_]u8{60};
    const to_notes = [_]u8{73};
    var transition: LmtKeyboardTransitionAssessment = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_assess_keyboard_transition_n(
        @ptrCast(&from_notes),
        from_notes.len,
        @ptrCast(&to_notes),
        to_notes.len,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&keyboard_profile),
        @ptrCast(&previous_load),
        @ptrCast(&transition),
    ));
    try testing.expectEqual(@as(u8, 13), transition.anchor_delta_semitones);
    try testing.expect((transition.blocker_bits & (@as(u32, 1) << c.LMT_KEYBOARD_PLAYABILITY_BLOCKER_SHIFT_HARD_LIMIT)) != 0);
    try testing.expect((transition.warning_bits & (@as(u32, 1) << c.LMT_PLAYABILITY_WARNING_EXCESSIVE_LONGITUDINAL_SHIFT)) != 0);
    try testing.expect((transition.warning_bits & (@as(u32, 1) << c.LMT_PLAYABILITY_WARNING_FLUENCY_DEGRADATION_FROM_RECENT_MOTION)) != 0);

    const black_note = [_]u8{61};
    var ranked: [8]LmtRankedKeyboardFingering = undefined;
    const ranked_total = lmt_rank_keyboard_fingerings_n(
        @ptrCast(&black_note),
        black_note.len,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&keyboard_profile),
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expectEqual(@as(u32, 5), ranked_total);
    try testing.expectEqual(@as(u8, 2), ranked[0].fingers[0]);

    var summary: LmtPlayabilityDifficultySummary = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_summarize_keyboard_realization_difficulty_n(
        @ptrCast(&notes),
        notes.len,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&keyboard_profile),
        null,
        @ptrCast(&summary),
    ));
    try testing.expectEqual(@as(u8, 1), summary.accepted);
    try testing.expectEqual(@as(u8, 7), summary.span_steps);
    try testing.expect(summary.comfort_span_margin >= 0);

    var easier: LmtRankedKeyboardFingering = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_suggest_easier_keyboard_fingering_n(
        @ptrCast(&notes),
        notes.len,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&keyboard_profile),
        @ptrCast(&easier),
    ));
    try testing.expectEqual(@as(u8, 1), easier.fingers[0]);
}

test "c abi playability-aware next-step wrappers" {
    var history: LmtVoicedHistory = undefined;
    lmt_voiced_history_reset(@ptrCast(&history));

    const current_notes = [_]u8{60};
    _ = lmt_voiced_history_push(
        @ptrCast(&history),
        @ptrCast(&current_notes),
        current_notes.len,
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

    var strict_profile = LmtHandProfile{
        .finger_count = 5,
        .comfort_span_steps = 12,
        .limit_span_steps = 14,
        .comfort_shift_steps = 1,
        .limit_shift_steps = 1,
        .prefers_low_tension = 1,
        .reserved0 = 0,
        .reserved1 = 0,
    };

    var filtered: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]LmtNextStepSuggestion = undefined;
    const filtered_total = lmt_filter_next_steps_by_playability(
        @ptrCast(&history),
        c.LMT_COUNTERPOINT_SPECIES,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&strict_profile),
        c.LMT_PLAYABILITY_POLICY_BALANCED,
        @ptrCast(&filtered),
        filtered.len,
    );
    try testing.expectEqual(@as(u32, 2), filtered_total);
    try testing.expectEqual(@as(u8, 59), filtered[0].notes[0]);
    try testing.expectEqual(@as(u8, 61), filtered[1].notes[0]);

    var ranked: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]LmtRankedKeyboardNextStep = undefined;
    const ranked_total = lmt_rank_keyboard_next_steps_by_playability(
        @ptrCast(&history),
        c.LMT_COUNTERPOINT_SPECIES,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&strict_profile),
        c.LMT_PLAYABILITY_POLICY_BALANCED,
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expectEqual(@as(u32, 4), ranked_total);
    try testing.expectEqual(@as(u8, 1), ranked[0].accepted);
    try testing.expectEqual(@as(u8, c.LMT_KEYBOARD_HAND_RIGHT), ranked[0].hand);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_POLICY_BALANCED), ranked[0].policy);
    try testing.expectEqual(@as(u32, 0), ranked[0].transition.blocker_bits);

    var safer: LmtRankedKeyboardNextStep = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_suggest_safer_keyboard_next_step_by_playability(
        @ptrCast(&history),
        c.LMT_COUNTERPOINT_SPECIES,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&strict_profile),
        c.LMT_PLAYABILITY_POLICY_BALANCED,
        @ptrCast(&safer),
    ));
    try testing.expectEqual(@as(u8, 1), safer.accepted);
    try testing.expectEqual(ranked[0].candidate_index, safer.candidate_index);
}

test "c abi committed phrase next step wrappers" {
    var history: LmtVoicedHistory = undefined;
    lmt_voiced_history_reset(@ptrCast(&history));
    _ = lmt_voiced_history_push(
        @ptrCast(&history),
        @ptrCast(&[_]u8{60}),
        1,
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

    var keyboard_profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&keyboard_profile)));

    var memory = std.mem.zeroes(LmtKeyboardCommittedPhraseMemory);
    lmt_keyboard_committed_phrase_reset(@ptrCast(&memory));
    const event = LmtKeyboardPhraseEvent{
        .note_count = 1,
        .hand = c.LMT_KEYBOARD_HAND_RIGHT,
        .reserved0 = 0,
        .reserved1 = 0,
        .notes = .{ 60, 0, 0, 0, 0 },
    };
    try testing.expectEqual(@as(u32, 1), lmt_keyboard_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event)));

    var ranked: [counterpoint.MAX_NEXT_STEP_SUGGESTIONS]LmtRankedKeyboardNextStep = undefined;
    const ranked_total = lmt_rank_keyboard_next_steps_by_committed_phrase(
        @ptrCast(&memory),
        @ptrCast(&history),
        c.LMT_COUNTERPOINT_SPECIES,
        @ptrCast(&keyboard_profile),
        c.LMT_PLAYABILITY_POLICY_BALANCED,
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expect(ranked_total > 0);
    try testing.expectEqual(@as(u8, c.LMT_KEYBOARD_HAND_RIGHT), ranked[0].hand);

    var safer: LmtRankedKeyboardNextStep = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_suggest_safer_keyboard_next_step_by_committed_phrase(
        @ptrCast(&memory),
        @ptrCast(&history),
        c.LMT_COUNTERPOINT_SPECIES,
        @ptrCast(&keyboard_profile),
        c.LMT_PLAYABILITY_POLICY_BALANCED,
        @ptrCast(&safer),
    ));
    try testing.expectEqual(@as(u8, c.LMT_KEYBOARD_HAND_RIGHT), safer.hand);
}

test "c abi playability-aware context suggestion wrapper" {
    var keyboard_profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&keyboard_profile)));

    const notes = [_]u8{60};
    var ranked: [keyboard.MAX_CONTEXT_SUGGESTIONS]LmtRankedKeyboardContextSuggestion = undefined;
    const total = lmt_rank_keyboard_context_suggestions_by_playability(
        pcs.fromList(&[_]u4{0}),
        @ptrCast(&notes),
        notes.len,
        0,
        c.LMT_MODE_IONIAN,
        c.LMT_KEYBOARD_HAND_RIGHT,
        @ptrCast(&keyboard_profile),
        null,
        c.LMT_PLAYABILITY_POLICY_MINIMAX_BOTTLENECK,
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expect(total > 0);
    try testing.expectEqual(@as(u8, c.LMT_KEYBOARD_HAND_RIGHT), ranked[0].hand);
    try testing.expectEqual(@as(u8, c.LMT_PLAYABILITY_POLICY_MINIMAX_BOTTLENECK), ranked[0].policy);
    try testing.expect(ranked[0].realized_note <= 127);
    try testing.expect(ranked[0].candidate.score != 0);
}

test "c abi committed phrase context suggestion wrapper" {
    var keyboard_profile: LmtHandProfile = undefined;
    try testing.expectEqual(@as(u32, 1), lmt_default_keyboard_hand_profile(@ptrCast(&keyboard_profile)));

    var memory = std.mem.zeroes(LmtKeyboardCommittedPhraseMemory);
    lmt_keyboard_committed_phrase_reset(@ptrCast(&memory));
    const event = LmtKeyboardPhraseEvent{
        .note_count = 1,
        .hand = c.LMT_KEYBOARD_HAND_RIGHT,
        .reserved0 = 0,
        .reserved1 = 0,
        .notes = .{ 72, 0, 0, 0, 0 },
    };
    try testing.expectEqual(@as(u32, 1), lmt_keyboard_committed_phrase_push(@ptrCast(&memory), @ptrCast(&event)));

    var ranked: [keyboard.MAX_CONTEXT_SUGGESTIONS]LmtRankedKeyboardContextSuggestion = undefined;
    const total = lmt_rank_keyboard_context_suggestions_by_committed_phrase(
        @ptrCast(&memory),
        pcs.fromList(&[_]u4{0}),
        0,
        c.LMT_MODE_IONIAN,
        @ptrCast(&keyboard_profile),
        c.LMT_PLAYABILITY_POLICY_BALANCED,
        @ptrCast(&ranked),
        ranked.len,
    );
    try testing.expect(total > 0);
    try testing.expect(ranked[0].realized_note >= 69);
    try testing.expect(ranked[0].realized_note <= 79);
    try testing.expectEqual(@as(u8, c.LMT_KEYBOARD_HAND_RIGHT), ranked[0].hand);
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
