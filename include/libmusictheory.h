#ifndef LIBMUSICTHEORY_H
#define LIBMUSICTHEORY_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

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

lmt_pitch_class_set lmt_chord(lmt_chord_type type, lmt_pitch_class root);
const char *lmt_chord_name(lmt_pitch_class_set set);
const char *lmt_roman_numeral(lmt_pitch_class_set chord, lmt_key_context key);

lmt_midi_note lmt_fret_to_midi(uint8_t string, uint8_t fret, const uint8_t *tuning);
uint8_t lmt_midi_to_fret_positions(lmt_midi_note note, const uint8_t *tuning, lmt_fret_pos *out);

uint32_t lmt_svg_clock_optc(lmt_pitch_class_set set, char *buf, uint32_t buf_size);
uint32_t lmt_svg_fret(const int8_t *frets, char *buf, uint32_t buf_size);
uint32_t lmt_svg_chord_staff(lmt_chord_type type, lmt_pitch_class root, char *buf, uint32_t buf_size);

#ifdef __cplusplus
}
#endif

#endif
