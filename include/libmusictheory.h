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
 * - Experimental APIs: lmt_raster_is_enabled, lmt_raster_demo_rgba, and the
 *   method-specific RGBA bitmap renderers below.
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
uint32_t lmt_svg_chord_staff(lmt_chord_type type, lmt_pitch_class root, char *buf, uint32_t buf_size);
uint32_t lmt_svg_key_staff(lmt_pitch_class tonic, lmt_key_quality quality, char *buf, uint32_t buf_size);
uint32_t lmt_svg_keyboard(const lmt_midi_note *notes, uint32_t note_count, lmt_midi_note range_low, lmt_midi_note range_high, char *buf, uint32_t buf_size);
uint32_t lmt_svg_piano_staff(const lmt_midi_note *notes, uint32_t note_count, lmt_pitch_class tonic, lmt_key_quality quality, char *buf, uint32_t buf_size);

/* Experimental APIs: useful for demos and renderer work, not yet stable ABI. */
uint32_t lmt_raster_is_enabled(void);
uint32_t lmt_raster_demo_rgba(uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_clock_optc_rgba(lmt_pitch_class_set set, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_optic_k_group_rgba(lmt_pitch_class_set set, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_evenness_chart_rgba(uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_evenness_field_rgba(lmt_pitch_class_set set, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_fret_rgba(const int8_t *frets, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_fret_n_rgba(const int8_t *frets, uint32_t string_count, uint32_t window_start, uint32_t visible_frets, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_chord_staff_rgba(lmt_chord_type type, lmt_pitch_class root, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_key_staff_rgba(lmt_pitch_class tonic, lmt_key_quality quality, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_keyboard_rgba(const lmt_midi_note *notes, uint32_t note_count, lmt_midi_note range_low, lmt_midi_note range_high, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_piano_staff_rgba(const lmt_midi_note *notes, uint32_t note_count, lmt_pitch_class tonic, lmt_key_quality quality, uint32_t width, uint32_t height, uint8_t *out_rgba, uint32_t out_rgba_size);

/* Internal Harmonious verification/proof APIs live in libmusictheory_compat.h. */

#ifdef __cplusplus
}
#endif

#endif
