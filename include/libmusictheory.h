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
 * Surface classes:
 * - Stable public C ABI: declarations in this header, except those marked as
 *   experimental.
 * - Experimental APIs: lmt_raster_is_enabled, lmt_raster_demo_rgba,
 *   lmt_counterpoint_max_voices, lmt_build_voiced_state,
 *   lmt_classify_motion, lmt_rank_next_steps,
 *   lmt_rank_cadence_destinations, lmt_analyze_suspension_machine,
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
    LMT_MODE_HALF_WHOLE = 14,
    LMT_MODE_WHOLE_HALF = 15,
    LMT_MODE_WHOLE_TONE = 16,
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

typedef enum {
    LMT_COUNTERPOINT_SPECIES = 0,
    LMT_COUNTERPOINT_TONAL_CHORALE = 1,
    LMT_COUNTERPOINT_MODAL_POLYPHONY = 2,
    LMT_COUNTERPOINT_JAZZ_CLOSE_LEADING = 3,
    LMT_COUNTERPOINT_FREE_CONTEMPORARY = 4,
} lmt_counterpoint_rule_profile;

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
const char *lmt_spell_note(lmt_pitch_class pc, lmt_key_context key);
const char *lmt_spell_note_parts(lmt_pitch_class pc, lmt_pitch_class tonic, lmt_key_quality quality);

lmt_pitch_class_set lmt_chord(lmt_chord_type type, lmt_pitch_class root);
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
uint32_t lmt_sizeof_voiced_state(void);
uint32_t lmt_sizeof_voiced_history(void);
uint32_t lmt_sizeof_next_step_suggestion(void);
uint32_t lmt_cadence_destination_count(void);
const char *lmt_cadence_destination_name(uint32_t index);
uint32_t lmt_suspension_state_count(void);
const char *lmt_suspension_state_name(uint32_t index);
uint32_t lmt_sizeof_cadence_destination_score(void);
uint32_t lmt_sizeof_suspension_machine_summary(void);
void lmt_voiced_history_reset(lmt_voiced_history *history);
uint32_t lmt_build_voiced_state(const lmt_midi_note *notes, uint32_t note_count, const lmt_midi_note *sustained_notes, uint32_t sustained_count, lmt_pitch_class tonic, lmt_mode_type mode_type, uint8_t beat_in_bar, uint8_t beats_per_bar, uint8_t subdivision, lmt_cadence_state cadence_hint, const lmt_voiced_state *previous, lmt_voiced_state *out);
uint32_t lmt_voiced_history_push(lmt_voiced_history *history, const lmt_midi_note *notes, uint32_t note_count, const lmt_midi_note *sustained_notes, uint32_t sustained_count, lmt_pitch_class tonic, lmt_mode_type mode_type, uint8_t beat_in_bar, uint8_t beats_per_bar, uint8_t subdivision, lmt_cadence_state cadence_hint, lmt_voiced_state *out);
uint32_t lmt_classify_motion(const lmt_voiced_state *previous, const lmt_voiced_state *current, lmt_motion_summary *out);
uint32_t lmt_evaluate_motion_profile(lmt_counterpoint_rule_profile profile, const lmt_motion_summary *summary, lmt_motion_evaluation *out);
uint32_t lmt_rank_next_steps(const lmt_voiced_history *history, lmt_counterpoint_rule_profile profile, lmt_next_step_suggestion *out, uint32_t out_cap);
uint32_t lmt_rank_cadence_destinations(const lmt_voiced_history *history, lmt_counterpoint_rule_profile profile, lmt_cadence_destination_score *out, uint32_t out_cap);
uint32_t lmt_analyze_suspension_machine(const lmt_voiced_history *history, lmt_counterpoint_rule_profile profile, lmt_suspension_machine_summary *out);
uint32_t lmt_next_step_reason_count(void);
const char *lmt_next_step_reason_name(uint32_t index);
uint32_t lmt_next_step_warning_count(void);
const char *lmt_next_step_warning_name(uint32_t index);
uint8_t lmt_mode_spelling_quality(lmt_pitch_class tonic, lmt_mode_type mode_type);
uint32_t lmt_rank_context_suggestions(lmt_pitch_class_set set, const lmt_midi_note *midi_notes, uint32_t note_count, lmt_pitch_class tonic, lmt_mode_type mode_type, lmt_context_suggestion *out, uint32_t out_cap);
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
