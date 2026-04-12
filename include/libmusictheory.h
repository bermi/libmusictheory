#ifndef LIBMUSICTHEORY_H
#define LIBMUSICTHEORY_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Stable public C ABI for libmusictheory.
 *
 * Detailed release-surface classification lives in
 * docs/release/stability-matrix.md.
 *
 * Surface classes:
 * - Stable public C ABI: declarations in this header, except those marked as
 *   experimental.
 * - Experimental APIs: lmt_raster_is_enabled, lmt_raster_demo_rgba,
 *   lmt_counterpoint_max_voices, lmt_build_voiced_state,
 *   lmt_classify_motion, lmt_rank_next_steps,
 *   lmt_rank_cadence_destinations, lmt_analyze_suspension_machine,
 *   lmt_playability_reason_count, lmt_playability_reason_name,
 *   lmt_playability_warning_count, lmt_playability_warning_name,
 *   lmt_playability_policy_count, lmt_playability_policy_name,
 *   lmt_playability_profile_preset_count,
 *   lmt_playability_profile_preset_name,
 *   lmt_playability_profile_from_preset,
 *   lmt_playability_phrase_issue_scope_count,
 *   lmt_playability_phrase_issue_scope_name,
 *   lmt_playability_phrase_issue_severity_count,
 *   lmt_playability_phrase_issue_severity_name,
 *   lmt_playability_phrase_family_domain_count,
 *   lmt_playability_phrase_family_domain_name,
 *   lmt_playability_phrase_strain_bucket_count,
 *   lmt_playability_phrase_strain_bucket_name,
 *   lmt_sizeof_hand_profile, lmt_sizeof_temporal_load_state,
 *   lmt_sizeof_playability_difficulty_summary,
 *   lmt_sizeof_keyboard_phrase_event,
 *   lmt_sizeof_fret_phrase_event,
 *   lmt_sizeof_playability_phrase_issue,
 *   lmt_sizeof_playability_phrase_summary,
 *   lmt_sizeof_fret_candidate_location, lmt_sizeof_fret_play_state,
 *   lmt_sizeof_keybed_key_coord, lmt_sizeof_keyboard_play_state,
 *   lmt_sizeof_ranked_keyboard_context_suggestion,
 *   lmt_sizeof_ranked_keyboard_next_step,
 *   lmt_default_fret_hand_profile, lmt_default_keyboard_hand_profile,
 *   lmt_summarize_fret_realization_difficulty_n,
 *   lmt_summarize_fret_transition_difficulty_n,
 *   lmt_summarize_keyboard_realization_difficulty_n,
 *   lmt_summarize_keyboard_transition_difficulty_n,
 *   lmt_summarize_playability_phrase_issues,
 *   lmt_suggest_easier_fret_realization_n,
 *   lmt_suggest_easier_keyboard_fingering_n,
 *   lmt_suggest_safer_keyboard_next_step_by_playability,
 *   lmt_describe_fret_play_state, lmt_windowed_fret_positions_n,
 *   lmt_keyboard_key_coord, lmt_describe_keyboard_play_state,
 *   lmt_filter_next_steps_by_playability,
 *   lmt_rank_keyboard_next_steps_by_playability,
 *   lmt_rank_keyboard_context_suggestions_by_playability,
 *   lmt_satb_voice_count, lmt_satb_voice_name,
 *   lmt_sizeof_satb_register_violation,
 *   lmt_satb_range_low, lmt_satb_range_high,
 *   lmt_satb_range_contains, lmt_check_satb_registers,
 *   lmt_orbifold_triad_node_count, lmt_orbifold_triad_node_at,
 *   lmt_orbifold_triad_edge_count, lmt_orbifold_triad_edge_at,
 *   lmt_find_orbifold_triad_node,
 *   lmt_mode_type_count, lmt_mode_type_name,
 *   lmt_ordered_scale_pattern_count, lmt_ordered_scale_pattern_name,
 *   lmt_ordered_scale_degree_count, lmt_ordered_scale_pitch_class_set,
 *   lmt_barry_harris_parity,
 *   lmt_scale_degree, lmt_transpose_diatonic,
 *   lmt_nearest_scale_tones, lmt_snap_to_scale,
 *   lmt_find_containing_modes,
 *   lmt_chord_pattern_count, lmt_chord_pattern_name,
 *   lmt_chord_pattern_formula, lmt_detect_chord_matches,
 *   lmt_mode_spelling_quality, lmt_rank_context_suggestions,
 *   lmt_preferred_voicing_n, and the method-specific RGBA bitmap renderers
 *   below.
 * - Internal Harmonious verification/proof APIs: declarations in
 *   libmusictheory_compat.h.
 *
 * Ownership and lifetime:
 * - Caller-owned output buffers are required for list, fret-position, guide,
 *   URL, SVG, and RGBA output APIs.
 * - String-returning APIs return pointers into shared internal rotating
 *   storage. Copy the bytes you need before another string-returning call.
 *   Returned pointers must not be freed and are not thread-safe.
 * - SVG writers return the total SVG length required. Passing buf = NULL and
 *   buf_size = 0 is the supported size-query path for those APIs.
 * - Count-returning APIs may be used as sizing passes where supported by the
 *   specific function contract.
 */

typedef uint16_t lmt_pitch_class_set;
typedef uint8_t lmt_pitch_class;
typedef uint8_t lmt_midi_note;
typedef uint8_t lmt_interval;
typedef uint8_t lmt_interval_class;

typedef uint8_t lmt_scale_type;
enum {
    LMT_SCALE_DIATONIC = 0,
    LMT_SCALE_ACOUSTIC = 1,
    LMT_SCALE_DIMINISHED = 2,
    LMT_SCALE_WHOLE_TONE = 3,
    LMT_SCALE_HARMONIC_MINOR = 4,
    LMT_SCALE_HARMONIC_MAJOR = 5,
    LMT_SCALE_DOUBLE_AUGMENTED_HEXATONIC = 6,
};

typedef uint8_t lmt_mode_type;
enum {
    LMT_MODE_IONIAN = 0,
    LMT_MODE_DORIAN = 1,
    LMT_MODE_PHRYGIAN = 2,
    LMT_MODE_LYDIAN = 3,
    LMT_MODE_MIXOLYDIAN = 4,
    LMT_MODE_AEOLIAN = 5,
    LMT_MODE_LOCRIAN = 6,
    LMT_MODE_MELODIC_MINOR = 7,
    LMT_MODE_DORIAN_B2 = 8,
    LMT_MODE_LYDIAN_AUG = 9,
    LMT_MODE_LYDIAN_DOM = 10,
    LMT_MODE_MIXOLYDIAN_B6 = 11,
    LMT_MODE_LOCRIAN_NAT2 = 12,
    LMT_MODE_SUPER_LOCRIAN = 13,
    LMT_MODE_HARMONIC_MINOR = 14,
    LMT_MODE_LOCRIAN_NAT6 = 15,
    LMT_MODE_IONIAN_AUG = 16,
    LMT_MODE_DORIAN_SHARP4 = 17,
    LMT_MODE_PHRYGIAN_DOMINANT = 18,
    LMT_MODE_LYDIAN_SHARP2 = 19,
    LMT_MODE_SUPER_LOCRIAN_DIM = 20,
    LMT_MODE_HALF_WHOLE = 21,
    LMT_MODE_WHOLE_HALF = 22,
    LMT_MODE_WHOLE_TONE = 23,
    LMT_MODE_DOUBLE_HARMONIC = 24,
    LMT_MODE_HUNGARIAN_MINOR = 25,
    LMT_MODE_ENIGMATIC = 26,
    LMT_MODE_NEAPOLITAN_MINOR = 27,
    LMT_MODE_NEAPOLITAN_MAJOR = 28,
};

typedef uint8_t lmt_snap_tie_policy;
enum {
    LMT_SNAP_TIE_LOWER = 0,
    LMT_SNAP_TIE_HIGHER = 1,
};

typedef uint8_t lmt_barry_harris_parity_kind;
enum {
    LMT_BARRY_HARRIS_NOT_APPLICABLE = 0,
    LMT_BARRY_HARRIS_CHORD_TONE = 1,
    LMT_BARRY_HARRIS_PASSING_TONE = 2,
};

typedef uint8_t lmt_chord_type;
enum {
    LMT_CHORD_MAJOR = 0,
    LMT_CHORD_MINOR = 1,
    LMT_CHORD_DIMINISHED = 2,
    LMT_CHORD_AUGMENTED = 3,
};

typedef uint8_t lmt_key_quality;
enum {
    LMT_KEY_MAJOR = 0,
    LMT_KEY_MINOR = 1,
};

typedef struct {
    uint8_t tonic;
    uint8_t quality;
} lmt_key_context;

typedef struct {
    uint8_t string;
    uint8_t fret;
} lmt_fret_pos;

typedef struct {
    lmt_fret_pos position;
    uint8_t pitch_class;
    float opacity;
} lmt_guide_dot;

typedef struct {
    int32_t score;
    lmt_pitch_class_set expanded_set;
    uint8_t pitch_class;
    uint8_t overlap;
    uint8_t outside_count;
    uint8_t in_context;
    uint8_t cluster_free;
    uint8_t reads_as_named_chord;
} lmt_context_suggestion;

typedef struct {
    uint8_t in_scale;
    uint8_t has_lower;
    uint8_t has_upper;
    uint8_t reserved0;
    lmt_midi_note lower;
    lmt_midi_note upper;
    uint8_t lower_distance;
    uint8_t upper_distance;
} lmt_scale_snap_candidates;

typedef struct {
    uint8_t mode;
    uint8_t degree;
    uint8_t reserved0;
    uint8_t reserved1;
} lmt_containing_mode_match;

typedef struct {
    uint8_t root;
    uint8_t bass;
    uint8_t pattern;
    uint8_t interval_count;
    uint8_t bass_known;
    uint8_t root_is_bass;
    uint8_t bass_degree;
    uint8_t reserved0;
} lmt_chord_match;

typedef uint8_t lmt_playability_reason;
enum {
    LMT_PLAYABILITY_REASON_REACHABLE_LOCATION = 0,
    LMT_PLAYABILITY_REASON_REACHABLE_IN_CURRENT_WINDOW = 1,
    LMT_PLAYABILITY_REASON_MULTIPLE_LOCATIONS_AVAILABLE = 2,
    LMT_PLAYABILITY_REASON_EXPANDS_CURRENT_WINDOW = 3,
    LMT_PLAYABILITY_REASON_OPEN_STRING_RELIEF = 4,
    LMT_PLAYABILITY_REASON_REUSES_CURRENT_ANCHOR = 5,
    LMT_PLAYABILITY_REASON_BOTTLENECK_REDUCED = 6,
    LMT_PLAYABILITY_REASON_TECHNIQUE_PROFILE_APPLIED = 7,
    LMT_PLAYABILITY_REASON_HAND_CONTINUITY_RESET = 8,
};

typedef uint8_t lmt_playability_warning;
enum {
    LMT_PLAYABILITY_WARNING_SHIFT_REQUIRED = 0,
    LMT_PLAYABILITY_WARNING_COMFORT_WINDOW_EXCEEDED = 1,
    LMT_PLAYABILITY_WARNING_HARD_LIMIT_EXCEEDED = 2,
    LMT_PLAYABILITY_WARNING_AMBIGUOUS_HAND_ASSIGNMENT = 3,
    LMT_PLAYABILITY_WARNING_EXCESSIVE_LONGITUDINAL_SHIFT = 4,
    LMT_PLAYABILITY_WARNING_REPEATED_MAXIMAL_STRETCH = 5,
    LMT_PLAYABILITY_WARNING_WEAK_FINGER_STRESS = 6,
    LMT_PLAYABILITY_WARNING_UNSUPPORTED_EXTENSION = 7,
    LMT_PLAYABILITY_WARNING_THUMB_ON_BLACK_UNDER_STRETCH = 8,
    LMT_PLAYABILITY_WARNING_AWKWARD_THUMB_CROSSING = 9,
    LMT_PLAYABILITY_WARNING_REPEATED_WEAK_ADJACENT_FINGER_SEQUENCE = 10,
    LMT_PLAYABILITY_WARNING_FLUENCY_DEGRADATION_FROM_RECENT_MOTION = 11,
};

typedef uint8_t lmt_playability_policy;
enum {
    LMT_PLAYABILITY_POLICY_BALANCED = 0,
    LMT_PLAYABILITY_POLICY_MINIMAX_BOTTLENECK = 1,
    LMT_PLAYABILITY_POLICY_CUMULATIVE_STRAIN = 2,
};

typedef uint8_t lmt_playability_profile_preset;
enum {
    LMT_PLAYABILITY_PROFILE_COMPACT_BEGINNER = 0,
    LMT_PLAYABILITY_PROFILE_BALANCED_STANDARD = 1,
    LMT_PLAYABILITY_PROFILE_SPAN_TOLERANT = 2,
    LMT_PLAYABILITY_PROFILE_SHIFT_TOLERANT = 3,
};

typedef uint8_t lmt_playability_phrase_issue_scope;
enum {
    LMT_PLAYABILITY_PHRASE_ISSUE_EVENT = 0,
    LMT_PLAYABILITY_PHRASE_ISSUE_TRANSITION = 1,
};

typedef uint8_t lmt_playability_phrase_issue_severity;
enum {
    LMT_PLAYABILITY_PHRASE_SEVERITY_ADVISORY = 0,
    LMT_PLAYABILITY_PHRASE_SEVERITY_WARNING = 1,
    LMT_PLAYABILITY_PHRASE_SEVERITY_BLOCKED = 2,
};

typedef uint8_t lmt_playability_phrase_family_domain;
enum {
    LMT_PLAYABILITY_PHRASE_DOMAIN_NONE = 0,
    LMT_PLAYABILITY_PHRASE_DOMAIN_REASON = 1,
    LMT_PLAYABILITY_PHRASE_DOMAIN_WARNING = 2,
    LMT_PLAYABILITY_PHRASE_DOMAIN_FRET_BLOCKER = 3,
    LMT_PLAYABILITY_PHRASE_DOMAIN_KEYBOARD_BLOCKER = 4,
};

typedef uint8_t lmt_playability_phrase_strain_bucket;
enum {
    LMT_PLAYABILITY_PHRASE_STRAIN_NEUTRAL = 0,
    LMT_PLAYABILITY_PHRASE_STRAIN_ELEVATED = 1,
    LMT_PLAYABILITY_PHRASE_STRAIN_HIGH = 2,
    LMT_PLAYABILITY_PHRASE_STRAIN_BLOCKED = 3,
};

typedef uint8_t lmt_fret_playability_blocker;
enum {
    LMT_FRET_PLAYABILITY_BLOCKER_SPAN_HARD_LIMIT = 0,
    LMT_FRET_PLAYABILITY_BLOCKER_SHIFT_HARD_LIMIT = 1,
    LMT_FRET_PLAYABILITY_BLOCKER_STRING_SPAN_HARD_LIMIT = 2,
    LMT_FRET_PLAYABILITY_BLOCKER_FINGER_OVERLOAD = 3,
    LMT_FRET_PLAYABILITY_BLOCKER_UNSUPPORTED_EXTENSION = 4,
};

typedef uint8_t lmt_fret_technique_profile;
enum {
    LMT_FRET_TECHNIQUE_GENERIC_GUITAR = 0,
    LMT_FRET_TECHNIQUE_BASS_SIMANDL = 1,
    LMT_FRET_TECHNIQUE_BASS_OFPF = 2,
    LMT_FRET_TECHNIQUE_EXTENDED_RANGE_CLASSICAL_THUMB = 3,
};

typedef uint8_t lmt_keyboard_hand;
enum {
    LMT_KEYBOARD_HAND_LEFT = 0,
    LMT_KEYBOARD_HAND_RIGHT = 1,
};

typedef uint8_t lmt_keyboard_playability_blocker;
enum {
    LMT_KEYBOARD_PLAYABILITY_BLOCKER_SPAN_HARD_LIMIT = 0,
    LMT_KEYBOARD_PLAYABILITY_BLOCKER_NOTE_COUNT_EXCEEDS_FINGERS = 1,
    LMT_KEYBOARD_PLAYABILITY_BLOCKER_SHIFT_HARD_LIMIT = 2,
    LMT_KEYBOARD_PLAYABILITY_BLOCKER_IMPOSSIBLE_THUMB_CROSSING = 3,
};

enum {
    LMT_MAX_FRET_PLAYABILITY_STRINGS = 16,
    LMT_MAX_KEYBOARD_FINGERING_NOTES = 5,
    LMT_MAX_PHRASE_EVENTS = 64,
};

typedef struct {
    uint8_t finger_count;
    uint8_t comfort_span_steps;
    uint8_t limit_span_steps;
    uint8_t comfort_shift_steps;
    uint8_t limit_shift_steps;
    uint8_t prefers_low_tension;
    uint8_t reserved0;
    uint8_t reserved1;
} lmt_hand_profile;

typedef struct {
    uint8_t accepted;
    uint8_t blocker_count;
    uint8_t warning_count;
    uint8_t reason_count;
    uint16_t bottleneck_cost;
    uint16_t cumulative_cost;
    uint8_t span_steps;
    uint8_t shift_steps;
    uint8_t load_event_count;
    uint8_t peak_recent_span_steps;
    uint8_t peak_recent_shift_steps;
    uint8_t reserved0;
    int16_t comfort_span_margin;
    int16_t limit_span_margin;
    int16_t comfort_shift_margin;
    int16_t limit_shift_margin;
} lmt_playability_difficulty_summary;

typedef struct {
    uint8_t note_count;
    uint8_t hand;
    uint8_t reserved0;
    uint8_t reserved1;
    uint8_t notes[LMT_MAX_KEYBOARD_FINGERING_NOTES];
} lmt_keyboard_phrase_event;

typedef struct {
    uint8_t fret_count;
    uint8_t reserved0;
    uint8_t reserved1;
    uint8_t reserved2;
    int8_t frets[LMT_MAX_FRET_PLAYABILITY_STRINGS];
} lmt_fret_phrase_event;

typedef struct {
    uint8_t scope;
    uint8_t severity;
    uint8_t family_domain;
    uint8_t family_index;
    uint16_t event_index;
    uint16_t related_event_index;
    uint16_t magnitude;
    uint16_t reserved0;
} lmt_playability_phrase_issue;

typedef struct {
    uint16_t event_count;
    uint16_t issue_count;
    uint16_t first_blocked_event_index;
    uint16_t first_blocked_transition_from_index;
    uint16_t first_blocked_transition_to_index;
    uint16_t bottleneck_issue_index;
    uint16_t bottleneck_magnitude;
    uint8_t bottleneck_severity;
    uint8_t bottleneck_domain;
    uint8_t bottleneck_family_index;
    uint8_t strain_bucket;
    uint8_t dominant_reason_family;
    uint8_t dominant_warning_family;
    uint8_t reserved0;
    uint16_t severity_counts[3];
    uint16_t reason_family_counts[9];
    uint16_t warning_family_counts[12];
    uint16_t recovery_deficit_start_index;
    uint16_t recovery_deficit_end_index;
    uint16_t longest_recovery_deficit_run;
} lmt_playability_phrase_summary;

typedef struct {
    uint8_t event_count;
    uint8_t last_anchor_step;
    uint8_t last_span_steps;
    uint8_t last_shift_steps;
    uint8_t peak_span_steps;
    uint8_t peak_shift_steps;
    uint16_t cumulative_span_steps;
    uint16_t cumulative_shift_steps;
} lmt_temporal_load_state;

typedef struct {
    lmt_fret_pos position;
    uint8_t in_window;
    uint8_t shift_steps;
} lmt_fret_candidate_location;

typedef struct {
    uint8_t anchor_fret;
    uint8_t window_start;
    uint8_t window_end;
    uint8_t lowest_string;
    uint8_t highest_string;
    uint8_t active_string_count;
    uint8_t fretted_note_count;
    uint8_t open_string_count;
    uint8_t span_steps;
    uint8_t comfort_fit;
    uint8_t limit_fit;
    uint8_t reserved0;
    lmt_temporal_load_state load;
} lmt_fret_play_state;

typedef struct {
    lmt_fret_play_state state;
    uint8_t string_span_steps;
    uint8_t profile;
    uint16_t bottleneck_cost;
    uint16_t cumulative_cost;
    uint32_t blocker_bits;
    uint32_t warning_bits;
    uint32_t reason_bits;
    uint8_t recommended_fingers[LMT_MAX_FRET_PLAYABILITY_STRINGS];
} lmt_fret_realization_assessment;

typedef struct {
    lmt_fret_play_state from_state;
    lmt_fret_play_state to_state;
    uint8_t anchor_delta_steps;
    uint8_t changed_string_count;
    uint8_t profile;
    uint8_t reserved0;
    uint16_t bottleneck_cost;
    uint16_t cumulative_cost;
    uint32_t blocker_bits;
    uint32_t warning_bits;
    uint32_t reason_bits;
    uint8_t recommended_fingers[LMT_MAX_FRET_PLAYABILITY_STRINGS];
} lmt_fret_transition_assessment;

typedef struct {
    lmt_fret_candidate_location location;
    uint16_t bottleneck_cost;
    uint16_t cumulative_cost;
    uint32_t blocker_bits;
    uint32_t warning_bits;
    uint32_t reason_bits;
    uint8_t recommended_finger;
    uint8_t profile;
    uint8_t reserved0;
    uint8_t reserved1;
} lmt_ranked_fret_realization;

typedef struct {
    uint8_t midi;
    uint8_t is_black;
    uint8_t octave;
    uint8_t degree_in_octave;
    float x;
    float y;
} lmt_keybed_key_coord;

typedef struct {
    uint8_t anchor_midi;
    uint8_t low_midi;
    uint8_t high_midi;
    uint8_t active_note_count;
    uint8_t black_key_count;
    uint8_t white_key_count;
    uint8_t span_semitones;
    uint8_t comfort_fit;
    uint8_t limit_fit;
    uint8_t reserved0;
    lmt_temporal_load_state load;
} lmt_keyboard_play_state;

typedef struct {
    lmt_keyboard_play_state state;
    uint8_t hand;
    uint8_t note_count;
    uint8_t outer_black_count;
    uint8_t reserved0;
    uint16_t bottleneck_cost;
    uint16_t cumulative_cost;
    uint32_t blocker_bits;
    uint32_t warning_bits;
    uint32_t reason_bits;
    uint8_t recommended_fingers[LMT_MAX_KEYBOARD_FINGERING_NOTES];
} lmt_keyboard_realization_assessment;

typedef struct {
    lmt_keyboard_play_state from_state;
    lmt_keyboard_play_state to_state;
    uint8_t hand;
    uint8_t note_count;
    uint8_t anchor_delta_semitones;
    uint8_t reserved0;
    uint16_t bottleneck_cost;
    uint16_t cumulative_cost;
    uint32_t blocker_bits;
    uint32_t warning_bits;
    uint32_t reason_bits;
    uint8_t from_fingers[LMT_MAX_KEYBOARD_FINGERING_NOTES];
    uint8_t to_fingers[LMT_MAX_KEYBOARD_FINGERING_NOTES];
} lmt_keyboard_transition_assessment;

typedef struct {
    uint8_t hand;
    uint8_t note_count;
    uint8_t reserved0;
    uint8_t reserved1;
    uint16_t bottleneck_cost;
    uint16_t cumulative_cost;
    uint32_t blocker_bits;
    uint32_t warning_bits;
    uint32_t reason_bits;
    uint8_t fingers[LMT_MAX_KEYBOARD_FINGERING_NOTES];
} lmt_ranked_keyboard_fingering;

typedef uint8_t lmt_cadence_state;
enum {
    LMT_CADENCE_NONE = 0,
    LMT_CADENCE_STABLE = 1,
    LMT_CADENCE_PRE_DOMINANT = 2,
    LMT_CADENCE_DOMINANT = 3,
    LMT_CADENCE_CADENTIAL_SIX_FOUR = 4,
    LMT_CADENCE_AUTHENTIC_ARRIVAL = 5,
    LMT_CADENCE_HALF_ARRIVAL = 6,
    LMT_CADENCE_DECEPTIVE_PULL = 7,
};

typedef uint8_t lmt_cadence_destination;
enum {
    LMT_CADENCE_DESTINATION_STABLE_CONTINUATION = 0,
    LMT_CADENCE_DESTINATION_PRE_DOMINANT_ARRIVAL = 1,
    LMT_CADENCE_DESTINATION_DOMINANT_ARRIVAL = 2,
    LMT_CADENCE_DESTINATION_AUTHENTIC_ARRIVAL = 3,
    LMT_CADENCE_DESTINATION_HALF_ARRIVAL = 4,
    LMT_CADENCE_DESTINATION_DECEPTIVE_PULL = 5,
};

typedef uint8_t lmt_suspension_state;
enum {
    LMT_SUSPENSION_NONE = 0,
    LMT_SUSPENSION_PREPARATION = 1,
    LMT_SUSPENSION_SUSPENSION = 2,
    LMT_SUSPENSION_RESOLUTION = 3,
    LMT_SUSPENSION_UNRESOLVED = 4,
};

typedef struct {
    uint8_t beat_in_bar;
    uint8_t beats_per_bar;
    uint8_t subdivision;
    uint8_t reserved;
} lmt_metric_position;

typedef struct {
    uint8_t id;
    uint8_t midi;
    int8_t octave;
    uint8_t pitch_class;
    uint8_t sustained;
    uint8_t reserved0;
    uint8_t reserved1;
    uint8_t reserved2;
} lmt_voice;

typedef struct {
    lmt_pitch_class_set set_value;
    uint8_t voice_count;
    uint8_t tonic;
    uint8_t mode_type;
    uint8_t key_quality;
    lmt_metric_position metric;
    uint8_t cadence_state;
    uint8_t state_index;
    uint8_t next_voice_id;
    uint8_t reserved;
    lmt_voice voices[8];
} lmt_voiced_state;

typedef struct {
    uint8_t len;
    uint8_t next_voice_id;
    uint8_t reserved0;
    uint8_t reserved1;
    lmt_voiced_state states[4];
} lmt_voiced_history;

typedef enum {
    LMT_VOICE_MOTION_STATIONARY = 0,
    LMT_VOICE_MOTION_STEP = 1,
    LMT_VOICE_MOTION_LEAP = 2,
} lmt_voice_motion_class;

typedef enum {
    LMT_PAIR_MOTION_NONE = 0,
    LMT_PAIR_MOTION_CONTRARY = 1,
    LMT_PAIR_MOTION_SIMILAR = 2,
    LMT_PAIR_MOTION_PARALLEL = 3,
    LMT_PAIR_MOTION_OBLIQUE = 4,
} lmt_pair_motion_class;

typedef uint8_t lmt_satb_voice;
enum {
    LMT_SATB_SOPRANO = 0,
    LMT_SATB_ALTO = 1,
    LMT_SATB_TENOR = 2,
    LMT_SATB_BASS = 3,
};

typedef enum {
    LMT_COUNTERPOINT_SPECIES = 0,
    LMT_COUNTERPOINT_TONAL_CHORALE = 1,
    LMT_COUNTERPOINT_MODAL_POLYPHONY = 2,
    LMT_COUNTERPOINT_JAZZ_CLOSE_LEADING = 3,
    LMT_COUNTERPOINT_FREE_CONTEMPORARY = 4,
} lmt_counterpoint_rule_profile;

typedef enum {
    LMT_VOICE_LEADING_PARALLEL_FIFTH = 0,
    LMT_VOICE_LEADING_PARALLEL_OCTAVE_OR_UNISON = 1,
    LMT_VOICE_LEADING_VOICE_CROSSING = 2,
    LMT_VOICE_LEADING_UPPER_SPACING = 3,
} lmt_voice_leading_violation_kind;

typedef struct {
    uint8_t voice_id;
    uint8_t from_midi;
    uint8_t to_midi;
    int8_t delta;
    uint8_t abs_delta;
    uint8_t motion_class;
    uint8_t retained;
    uint8_t reserved;
} lmt_voice_motion;

typedef struct {
    uint8_t voice_motion_count;
    uint8_t common_tone_count;
    uint8_t step_count;
    uint8_t leap_count;
    uint8_t contrary_count;
    uint8_t similar_count;
    uint8_t parallel_count;
    uint8_t oblique_count;
    uint8_t crossing_count;
    uint8_t overlap_count;
    uint16_t total_motion;
    int8_t outer_interval_before;
    int8_t outer_interval_after;
    uint8_t outer_motion;
    uint8_t previous_cadence_state;
    uint8_t current_cadence_state;
    lmt_voice_motion voice_motions[8];
} lmt_motion_summary;

typedef struct {
    int32_t score;
    int16_t preferred_score;
    int16_t penalty_score;
    int16_t cadence_score;
    int16_t spacing_penalty;
    int16_t leap_penalty;
    uint8_t disallowed_count;
    uint8_t disallowed;
} lmt_motion_evaluation;

typedef struct {
    uint8_t kind;
    uint8_t lower_voice_id;
    uint8_t upper_voice_id;
    int8_t previous_interval_semitones;
    int8_t current_interval_semitones;
    uint8_t reserved0;
    uint8_t reserved1;
    uint8_t reserved2;
} lmt_voice_pair_violation;

typedef struct {
    uint8_t collapsed;
    int8_t direction;
    uint8_t moving_voice_count;
    uint8_t stationary_voice_count;
    uint8_t ascending_count;
    uint8_t descending_count;
    uint8_t retained_voice_count;
    uint8_t reserved0;
} lmt_motion_independence_summary;

typedef struct {
    uint8_t voice_id;
    uint8_t satb_voice;
    uint8_t midi;
    int8_t direction;
    uint8_t low;
    uint8_t high;
    uint8_t reserved0;
    uint8_t reserved1;
} lmt_satb_register_violation;

typedef struct {
    int32_t score;
    uint32_t reason_mask;
    uint32_t warning_mask;
    uint8_t cadence_effect;
    int8_t tension_delta;
    uint8_t note_count;
    uint8_t reserved0;
    uint8_t reserved1;
    lmt_pitch_class_set set_value;
    lmt_midi_note notes[8];
    lmt_motion_summary motion;
    lmt_motion_evaluation evaluation;
} lmt_next_step_suggestion;

typedef struct {
    lmt_context_suggestion candidate;
    lmt_keyboard_transition_assessment transition;
    uint8_t realized_note;
    uint8_t candidate_index;
    uint8_t hand;
    uint8_t policy;
    uint8_t accepted;
    uint8_t reserved0;
} lmt_ranked_keyboard_context_suggestion;

typedef struct {
    lmt_next_step_suggestion candidate;
    lmt_keyboard_transition_assessment transition;
    uint8_t candidate_index;
    uint8_t hand;
    uint8_t policy;
    uint8_t accepted;
} lmt_ranked_keyboard_next_step;

typedef struct {
    int32_t score;
    uint8_t destination;
    uint8_t candidate_count;
    uint8_t warning_count;
    uint8_t current_match;
    int8_t tension_bias;
    uint8_t reserved0;
    uint8_t reserved1;
} lmt_cadence_destination_score;

typedef struct {
    uint8_t state;
    uint8_t tracked_voice_id;
    uint8_t held_midi;
    uint8_t expected_resolution_midi;
    int8_t resolution_direction;
    uint8_t obligation_count;
    uint8_t warning_count;
    uint8_t retained_count;
    int16_t current_tension;
    int16_t previous_tension;
    uint8_t candidate_resolution_count;
    uint8_t reserved0;
    uint8_t reserved1;
    uint8_t reserved2;
} lmt_suspension_machine_summary;

typedef struct {
    lmt_pitch_class_set set_value;
    uint8_t root;
    uint8_t quality;
    float x;
    float y;
} lmt_orbifold_triad_node;

typedef struct {
    uint8_t from_index;
    uint8_t to_index;
    uint8_t reserved0;
    uint8_t reserved1;
} lmt_orbifold_triad_edge;

lmt_pitch_class_set lmt_pcs_from_list(const lmt_pitch_class *pcs, uint8_t count);
uint8_t lmt_pcs_to_list(lmt_pitch_class_set set, lmt_pitch_class *out);
uint8_t lmt_pcs_cardinality(lmt_pitch_class_set set);
lmt_pitch_class_set lmt_pcs_transpose(lmt_pitch_class_set set, uint8_t semitones);
lmt_pitch_class_set lmt_pcs_invert(lmt_pitch_class_set set);
lmt_pitch_class_set lmt_pcs_complement(lmt_pitch_class_set set);
bool lmt_pcs_is_subset(lmt_pitch_class_set small, lmt_pitch_class_set big);

lmt_pitch_class_set lmt_prime_form(lmt_pitch_class_set set);
lmt_pitch_class_set lmt_forte_prime(lmt_pitch_class_set set);
bool lmt_is_cluster_free(lmt_pitch_class_set set);
float lmt_evenness_distance(lmt_pitch_class_set set);

lmt_pitch_class_set lmt_scale(lmt_scale_type type, lmt_pitch_class tonic);
lmt_pitch_class_set lmt_mode(lmt_mode_type type, lmt_pitch_class root);
uint32_t lmt_mode_type_count(void);
const char *lmt_mode_type_name(uint32_t index);
uint8_t lmt_scale_degree(lmt_pitch_class tonic, lmt_mode_type mode, lmt_midi_note note);
uint32_t lmt_transpose_diatonic(lmt_pitch_class tonic, lmt_mode_type mode, lmt_midi_note note, int8_t degrees, lmt_midi_note *out);
uint32_t lmt_nearest_scale_tones(lmt_pitch_class tonic, lmt_mode_type mode, lmt_midi_note note, lmt_scale_snap_candidates *out);
uint32_t lmt_snap_to_scale(lmt_pitch_class tonic, lmt_mode_type mode, lmt_midi_note note, lmt_snap_tie_policy policy, lmt_midi_note *out);
uint8_t lmt_find_containing_modes(lmt_pitch_class note_pc, lmt_pitch_class tonic, const lmt_mode_type *modes, uint8_t mode_count, lmt_containing_mode_match *out, uint8_t out_len);
const char *lmt_spell_note(lmt_pitch_class pc, lmt_key_context key);
const char *lmt_spell_note_parts(lmt_pitch_class pc, lmt_pitch_class tonic, lmt_key_quality quality);

lmt_pitch_class_set lmt_chord(lmt_chord_type type, lmt_pitch_class root);
uint32_t lmt_chord_pattern_count(void);
const char *lmt_chord_pattern_name(uint32_t index);
const char *lmt_chord_pattern_formula(uint32_t index);
uint16_t lmt_detect_chord_matches(lmt_pitch_class_set set, lmt_pitch_class bass, bool bass_known, lmt_chord_match *out, uint8_t out_len);
const char *lmt_chord_name(lmt_pitch_class_set set);
const char *lmt_roman_numeral(lmt_pitch_class_set chord, lmt_key_context key);
const char *lmt_roman_numeral_parts(lmt_pitch_class_set chord, lmt_pitch_class tonic, lmt_key_quality quality);

lmt_midi_note lmt_fret_to_midi(uint8_t string, uint8_t fret, const uint8_t *tuning);
uint8_t lmt_midi_to_fret_positions(lmt_midi_note note, const uint8_t *tuning, lmt_fret_pos *out);
lmt_midi_note lmt_fret_to_midi_n(uint32_t string, uint8_t fret, const uint8_t *tuning, uint32_t tuning_count);
uint32_t lmt_midi_to_fret_positions_n(lmt_midi_note note, const uint8_t *tuning, uint32_t tuning_count, lmt_fret_pos *out, uint32_t out_cap);
uint32_t lmt_generate_voicings_n(lmt_pitch_class_set chord_set, const uint8_t *tuning, uint32_t tuning_count, uint8_t max_fret, uint8_t max_span, int8_t *out_frets, uint32_t out_voicing_cap);
uint32_t lmt_pitch_class_guide_n(const lmt_fret_pos *selected, uint32_t selected_count, uint8_t min_fret, uint8_t max_fret, const uint8_t *tuning, uint32_t tuning_count, lmt_guide_dot *out, uint32_t out_cap);
uint32_t lmt_frets_to_url_n(const int8_t *frets, uint32_t fret_count, char *buf, uint32_t buf_size);
uint32_t lmt_url_to_frets_n(const char *url, int8_t *out, uint32_t out_cap);

uint32_t lmt_svg_clock_optc(lmt_pitch_class_set set, char *buf, uint32_t buf_size);
uint32_t lmt_svg_optic_k_group(lmt_pitch_class_set set, char *buf, uint32_t buf_size);
uint32_t lmt_svg_evenness_chart(char *buf, uint32_t buf_size);
uint32_t lmt_svg_evenness_field(lmt_pitch_class_set set, char *buf, uint32_t buf_size);
uint32_t lmt_svg_fret(const int8_t *frets, char *buf, uint32_t buf_size);
uint32_t lmt_svg_fret_n(const int8_t *frets, uint32_t string_count, uint32_t window_start, uint32_t visible_frets, char *buf, uint32_t buf_size);
uint32_t lmt_svg_fret_tuned_n(const int8_t *frets, uint32_t string_count, const uint8_t *tuning, uint32_t tuning_count, uint32_t window_start, uint32_t visible_frets, char *buf, uint32_t buf_size);
uint32_t lmt_svg_chord_staff(lmt_chord_type type, lmt_pitch_class root, char *buf, uint32_t buf_size);
uint32_t lmt_svg_key_staff(lmt_pitch_class tonic, lmt_key_quality quality, char *buf, uint32_t buf_size);
uint32_t lmt_svg_keyboard(const lmt_midi_note *notes, uint32_t note_count, lmt_midi_note range_low, lmt_midi_note range_high, char *buf, uint32_t buf_size);
uint32_t lmt_svg_piano_staff(const lmt_midi_note *notes, uint32_t note_count, lmt_pitch_class tonic, lmt_key_quality quality, char *buf, uint32_t buf_size);

/* Experimental APIs: useful for demos and renderer work, not yet stable ABI. */
uint32_t lmt_raster_is_enabled(void);
uint32_t lmt_raster_demo_rgba(uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_counterpoint_max_voices(void);
uint32_t lmt_counterpoint_history_capacity(void);
uint32_t lmt_counterpoint_rule_profile_count(void);
const char *lmt_counterpoint_rule_profile_name(uint32_t index);
uint32_t lmt_voice_leading_violation_kind_count(void);
const char *lmt_voice_leading_violation_kind_name(uint32_t index);
uint32_t lmt_ordered_scale_pattern_count(void);
const char *lmt_ordered_scale_pattern_name(uint32_t index);
uint8_t lmt_ordered_scale_degree_count(uint32_t index);
lmt_pitch_class_set lmt_ordered_scale_pitch_class_set(uint32_t index, lmt_pitch_class tonic);
uint8_t lmt_barry_harris_parity(uint32_t index, lmt_pitch_class tonic, lmt_midi_note note, uint8_t *out_degree);
uint32_t lmt_playability_reason_count(void);
const char *lmt_playability_reason_name(uint32_t index);
uint32_t lmt_playability_warning_count(void);
const char *lmt_playability_warning_name(uint32_t index);
uint32_t lmt_playability_policy_count(void);
const char *lmt_playability_policy_name(uint32_t index);
uint32_t lmt_playability_profile_preset_count(void);
const char *lmt_playability_profile_preset_name(uint32_t index);
uint32_t lmt_playability_profile_from_preset(uint32_t preset, const lmt_hand_profile *base_profile, lmt_hand_profile *out);
uint32_t lmt_playability_phrase_issue_scope_count(void);
const char *lmt_playability_phrase_issue_scope_name(uint32_t index);
uint32_t lmt_playability_phrase_issue_severity_count(void);
const char *lmt_playability_phrase_issue_severity_name(uint32_t index);
uint32_t lmt_playability_phrase_family_domain_count(void);
const char *lmt_playability_phrase_family_domain_name(uint32_t index);
uint32_t lmt_playability_phrase_strain_bucket_count(void);
const char *lmt_playability_phrase_strain_bucket_name(uint32_t index);
uint32_t lmt_fret_playability_blocker_count(void);
const char *lmt_fret_playability_blocker_name(uint32_t index);
uint32_t lmt_fret_technique_profile_count(void);
const char *lmt_fret_technique_profile_name(uint32_t index);
uint32_t lmt_keyboard_hand_count(void);
const char *lmt_keyboard_hand_name(uint32_t index);
uint32_t lmt_keyboard_playability_blocker_count(void);
const char *lmt_keyboard_playability_blocker_name(uint32_t index);
uint32_t lmt_sizeof_hand_profile(void);
uint32_t lmt_sizeof_temporal_load_state(void);
uint32_t lmt_sizeof_fret_candidate_location(void);
uint32_t lmt_sizeof_fret_play_state(void);
uint32_t lmt_sizeof_fret_realization_assessment(void);
uint32_t lmt_sizeof_fret_transition_assessment(void);
uint32_t lmt_sizeof_ranked_fret_realization(void);
uint32_t lmt_sizeof_keybed_key_coord(void);
uint32_t lmt_sizeof_keyboard_play_state(void);
uint32_t lmt_sizeof_keyboard_realization_assessment(void);
uint32_t lmt_sizeof_keyboard_transition_assessment(void);
uint32_t lmt_sizeof_ranked_keyboard_fingering(void);
uint32_t lmt_sizeof_ranked_keyboard_context_suggestion(void);
uint32_t lmt_sizeof_ranked_keyboard_next_step(void);
uint32_t lmt_sizeof_playability_difficulty_summary(void);
uint32_t lmt_sizeof_keyboard_phrase_event(void);
uint32_t lmt_sizeof_fret_phrase_event(void);
uint32_t lmt_sizeof_playability_phrase_issue(void);
uint32_t lmt_sizeof_playability_phrase_summary(void);
uint32_t lmt_default_fret_hand_profile(lmt_hand_profile *out);
uint32_t lmt_default_fret_hand_profile_for_technique(uint32_t profile, lmt_hand_profile *out);
uint32_t lmt_default_keyboard_hand_profile(lmt_hand_profile *out);
uint32_t lmt_summarize_playability_phrase_issues(uint32_t event_count, const lmt_playability_phrase_issue *issues, uint32_t issue_count, lmt_playability_phrase_summary *out);
uint32_t lmt_audit_fret_phrase_n(const lmt_fret_phrase_event *events, uint32_t event_count, const uint8_t *tuning, uint32_t tuning_count, uint32_t profile, const lmt_hand_profile *hand_profile, lmt_playability_phrase_issue *issues_out, uint32_t issues_cap, lmt_playability_phrase_summary *summary_out);
uint32_t lmt_audit_keyboard_phrase_n(const lmt_keyboard_phrase_event *events, uint32_t event_count, const lmt_hand_profile *profile, lmt_playability_phrase_issue *issues_out, uint32_t issues_cap, lmt_playability_phrase_summary *summary_out);
uint32_t lmt_describe_fret_play_state(const int8_t *frets, uint32_t fret_count, const lmt_hand_profile *profile, const lmt_temporal_load_state *previous_load, lmt_fret_play_state *out);
uint32_t lmt_windowed_fret_positions_n(lmt_midi_note note, const uint8_t *tuning, uint32_t tuning_count, uint8_t anchor_fret, const lmt_hand_profile *profile, lmt_fret_candidate_location *out, uint32_t out_cap);
uint32_t lmt_assess_fret_realization_n(const int8_t *frets, uint32_t fret_count, const uint8_t *tuning, uint32_t tuning_count, uint32_t profile, const lmt_hand_profile *hand_profile, const lmt_temporal_load_state *previous_load, lmt_fret_realization_assessment *out);
uint32_t lmt_assess_fret_transition_n(const int8_t *from_frets, const int8_t *to_frets, uint32_t fret_count, const uint8_t *tuning, uint32_t tuning_count, uint32_t profile, const lmt_hand_profile *hand_profile, lmt_fret_transition_assessment *out);
uint32_t lmt_summarize_fret_realization_difficulty_n(const int8_t *frets, uint32_t fret_count, const uint8_t *tuning, uint32_t tuning_count, uint32_t profile, const lmt_hand_profile *hand_profile, const lmt_temporal_load_state *previous_load, lmt_playability_difficulty_summary *out);
uint32_t lmt_summarize_fret_transition_difficulty_n(const int8_t *from_frets, const int8_t *to_frets, uint32_t fret_count, const uint8_t *tuning, uint32_t tuning_count, uint32_t profile, const lmt_hand_profile *hand_profile, lmt_playability_difficulty_summary *out);
uint32_t lmt_rank_fret_realizations_n(lmt_midi_note note, const uint8_t *tuning, uint32_t tuning_count, uint8_t anchor_fret, uint32_t profile, const lmt_hand_profile *hand_profile, lmt_ranked_fret_realization *out, uint32_t out_cap);
uint32_t lmt_suggest_easier_fret_realization_n(lmt_midi_note note, const uint8_t *tuning, uint32_t tuning_count, uint8_t anchor_fret, uint32_t profile, const lmt_hand_profile *hand_profile, lmt_ranked_fret_realization *out);
uint32_t lmt_keyboard_key_coord(lmt_midi_note note, lmt_keybed_key_coord *out);
uint32_t lmt_describe_keyboard_play_state(const lmt_midi_note *notes, uint32_t note_count, const lmt_hand_profile *profile, const lmt_temporal_load_state *previous_load, lmt_keyboard_play_state *out);
uint32_t lmt_assess_keyboard_realization_n(const lmt_midi_note *notes, uint32_t note_count, uint32_t hand, const lmt_hand_profile *profile, const lmt_temporal_load_state *previous_load, lmt_keyboard_realization_assessment *out);
uint32_t lmt_assess_keyboard_transition_n(const lmt_midi_note *from_notes, uint32_t from_count, const lmt_midi_note *to_notes, uint32_t to_count, uint32_t hand, const lmt_hand_profile *profile, const lmt_temporal_load_state *previous_load, lmt_keyboard_transition_assessment *out);
uint32_t lmt_summarize_keyboard_realization_difficulty_n(const lmt_midi_note *notes, uint32_t note_count, uint32_t hand, const lmt_hand_profile *profile, const lmt_temporal_load_state *previous_load, lmt_playability_difficulty_summary *out);
uint32_t lmt_summarize_keyboard_transition_difficulty_n(const lmt_midi_note *from_notes, uint32_t from_count, const lmt_midi_note *to_notes, uint32_t to_count, uint32_t hand, const lmt_hand_profile *profile, const lmt_temporal_load_state *previous_load, lmt_playability_difficulty_summary *out);
uint32_t lmt_rank_keyboard_fingerings_n(const lmt_midi_note *notes, uint32_t note_count, uint32_t hand, const lmt_hand_profile *profile, lmt_ranked_keyboard_fingering *out, uint32_t out_cap);
uint32_t lmt_suggest_easier_keyboard_fingering_n(const lmt_midi_note *notes, uint32_t note_count, uint32_t hand, const lmt_hand_profile *profile, lmt_ranked_keyboard_fingering *out);
uint32_t lmt_filter_next_steps_by_playability(const lmt_voiced_history *history, uint32_t profile, uint32_t hand, const lmt_hand_profile *hand_profile, uint32_t policy, lmt_next_step_suggestion *out, uint32_t out_cap);
uint32_t lmt_rank_keyboard_next_steps_by_playability(const lmt_voiced_history *history, uint32_t profile, uint32_t hand, const lmt_hand_profile *hand_profile, uint32_t policy, lmt_ranked_keyboard_next_step *out, uint32_t out_cap);
uint32_t lmt_suggest_safer_keyboard_next_step_by_playability(const lmt_voiced_history *history, uint32_t profile, uint32_t hand, const lmt_hand_profile *hand_profile, uint32_t policy, lmt_ranked_keyboard_next_step *out);
uint32_t lmt_satb_voice_count(void);
const char *lmt_satb_voice_name(uint32_t index);
uint32_t lmt_sizeof_voiced_state(void);
uint32_t lmt_sizeof_voiced_history(void);
uint32_t lmt_sizeof_next_step_suggestion(void);
uint32_t lmt_sizeof_voice_pair_violation(void);
uint32_t lmt_sizeof_motion_independence_summary(void);
uint32_t lmt_sizeof_satb_register_violation(void);
uint32_t lmt_cadence_destination_count(void);
const char *lmt_cadence_destination_name(uint32_t index);
uint32_t lmt_suspension_state_count(void);
const char *lmt_suspension_state_name(uint32_t index);
uint32_t lmt_sizeof_cadence_destination_score(void);
uint32_t lmt_sizeof_suspension_machine_summary(void);
uint32_t lmt_orbifold_triad_node_count(void);
uint32_t lmt_sizeof_orbifold_triad_node(void);
uint32_t lmt_orbifold_triad_node_at(uint32_t index, lmt_orbifold_triad_node *out);
uint32_t lmt_find_orbifold_triad_node(lmt_pitch_class_set set);
uint32_t lmt_orbifold_triad_edge_count(void);
uint32_t lmt_sizeof_orbifold_triad_edge(void);
uint32_t lmt_orbifold_triad_edge_at(uint32_t index, lmt_orbifold_triad_edge *out);
void lmt_voiced_history_reset(lmt_voiced_history *history);
uint32_t lmt_build_voiced_state(const lmt_midi_note *notes, uint32_t note_count, const lmt_midi_note *sustained_notes, uint32_t sustained_count, lmt_pitch_class tonic, lmt_mode_type mode_type, uint8_t beat_in_bar, uint8_t beats_per_bar, uint8_t subdivision, lmt_cadence_state cadence_hint, const lmt_voiced_state *previous, lmt_voiced_state *out);
uint32_t lmt_voiced_history_push(lmt_voiced_history *history, const lmt_midi_note *notes, uint32_t note_count, const lmt_midi_note *sustained_notes, uint32_t sustained_count, lmt_pitch_class tonic, lmt_mode_type mode_type, uint8_t beat_in_bar, uint8_t beats_per_bar, uint8_t subdivision, lmt_cadence_state cadence_hint, lmt_voiced_state *out);
uint32_t lmt_classify_motion(const lmt_voiced_state *previous, const lmt_voiced_state *current, lmt_motion_summary *out);
uint32_t lmt_evaluate_motion_profile(lmt_counterpoint_rule_profile profile, const lmt_motion_summary *summary, lmt_motion_evaluation *out);
uint32_t lmt_check_parallel_perfects(const lmt_voiced_state *previous, const lmt_voiced_state *current, lmt_voice_pair_violation *out, uint32_t out_cap);
uint32_t lmt_check_voice_crossing(const lmt_voiced_state *previous, const lmt_voiced_state *current, lmt_voice_pair_violation *out, uint32_t out_cap);
uint32_t lmt_check_spacing(const lmt_voiced_state *current, lmt_voice_pair_violation *out, uint32_t out_cap);
uint32_t lmt_check_motion_independence(const lmt_voiced_state *previous, const lmt_voiced_state *current, lmt_motion_independence_summary *out);
uint8_t lmt_satb_range_low(lmt_satb_voice voice);
uint8_t lmt_satb_range_high(lmt_satb_voice voice);
bool lmt_satb_range_contains(lmt_satb_voice voice, lmt_midi_note midi);
uint32_t lmt_check_satb_registers(const lmt_voiced_state *current, lmt_satb_register_violation *out, uint32_t out_cap);
uint32_t lmt_rank_next_steps(const lmt_voiced_history *history, lmt_counterpoint_rule_profile profile, lmt_next_step_suggestion *out, uint32_t out_cap);
uint32_t lmt_rank_cadence_destinations(const lmt_voiced_history *history, lmt_counterpoint_rule_profile profile, lmt_cadence_destination_score *out, uint32_t out_cap);
uint32_t lmt_analyze_suspension_machine(const lmt_voiced_history *history, lmt_counterpoint_rule_profile profile, lmt_suspension_machine_summary *out);
uint32_t lmt_next_step_reason_count(void);
const char *lmt_next_step_reason_name(uint32_t index);
uint32_t lmt_next_step_warning_count(void);
const char *lmt_next_step_warning_name(uint32_t index);
uint8_t lmt_mode_spelling_quality(lmt_pitch_class tonic, lmt_mode_type mode_type);
uint32_t lmt_rank_context_suggestions(lmt_pitch_class_set set, const lmt_midi_note *midi_notes, uint32_t note_count, lmt_pitch_class tonic, lmt_mode_type mode_type, lmt_context_suggestion *out, uint32_t out_cap);
uint32_t lmt_rank_keyboard_context_suggestions_by_playability(lmt_pitch_class_set set, const lmt_midi_note *midi_notes, uint32_t note_count, lmt_pitch_class tonic, lmt_mode_type mode_type, uint32_t hand, const lmt_hand_profile *hand_profile, const lmt_temporal_load_state *previous_load, uint32_t policy, lmt_ranked_keyboard_context_suggestion *out, uint32_t out_cap);
/* preferred_bass_pc >= 12 means “no preferred bass pitch class” */
uint32_t lmt_preferred_voicing_n(lmt_pitch_class_set chord_set, const uint8_t *tuning, uint32_t tuning_count, uint8_t max_fret, uint8_t max_span, uint8_t preferred_bass_pc, int8_t *out_frets, uint32_t out_fret_cap);
uint32_t lmt_bitmap_clock_optc_rgba(lmt_pitch_class_set set, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_optic_k_group_rgba(lmt_pitch_class_set set, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_evenness_chart_rgba(uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_evenness_field_rgba(lmt_pitch_class_set set, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_fret_rgba(const int8_t *frets, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_fret_n_rgba(const int8_t *frets, uint32_t string_count, uint32_t window_start, uint32_t visible_frets, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_fret_tuned_n_rgba(const int8_t *frets, uint32_t string_count, const uint8_t *tuning, uint32_t tuning_count, uint32_t window_start, uint32_t visible_frets, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_chord_staff_rgba(lmt_chord_type type, lmt_pitch_class root, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_key_staff_rgba(lmt_pitch_class tonic, lmt_key_quality quality, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_keyboard_rgba(const lmt_midi_note *notes, uint32_t note_count, lmt_midi_note range_low, lmt_midi_note range_high, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_piano_staff_rgba(const lmt_midi_note *notes, uint32_t note_count, lmt_pitch_class tonic, lmt_key_quality quality, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);

/* Internal Harmonious verification/proof APIs live in libmusictheory_compat.h. */

#ifdef __cplusplus
}
#endif

#endif
