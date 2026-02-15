#include "libmusictheory.h"

#include <assert.h>
#include <stddef.h>
#include <string.h>

_Static_assert(sizeof(lmt_pitch_class_set) == 2, "lmt_pitch_class_set size");
_Static_assert(sizeof(lmt_key_context) == 2, "lmt_key_context size");
_Static_assert(offsetof(lmt_key_context, tonic) == 0, "lmt_key_context tonic offset");
_Static_assert(offsetof(lmt_key_context, quality) == 1, "lmt_key_context quality offset");
_Static_assert(sizeof(lmt_fret_pos) == 2, "lmt_fret_pos size");

int main(void) {
    const lmt_pitch_class triad_pcs[3] = {0, 4, 7};
    lmt_pitch_class_set c_major = lmt_pcs_from_list(triad_pcs, 3);
    assert(c_major == 0x091);

    lmt_pitch_class out[12] = {0};
    uint8_t out_count = lmt_pcs_to_list(c_major, out);
    assert(out_count == 3);
    assert(out[0] == 0 && out[1] == 4 && out[2] == 7);

    assert(lmt_pcs_cardinality(c_major) == 3);
    assert(lmt_pcs_transpose(c_major, 2) == lmt_pcs_from_list((lmt_pitch_class[]){2, 6, 9}, 3));
    assert(lmt_pcs_invert(c_major) == lmt_pcs_from_list((lmt_pitch_class[]){0, 5, 8}, 3));
    assert(lmt_pcs_is_subset(lmt_pcs_from_list((lmt_pitch_class[]){0, 7}, 2), c_major));
    assert(!lmt_pcs_is_subset(lmt_pcs_from_list((lmt_pitch_class[]){1, 7}, 2), c_major));

    lmt_pitch_class_set complement = lmt_pcs_complement(c_major);
    assert(lmt_pcs_cardinality(complement) == 9);

    assert(lmt_prime_form(c_major) == c_major);
    assert(lmt_forte_prime(c_major) == lmt_pcs_from_list((lmt_pitch_class[]){0, 3, 7}, 3));
    assert(lmt_is_cluster_free(c_major));
    assert(lmt_evenness_distance(c_major) > 0.0f);

    assert(lmt_scale(LMT_SCALE_DIATONIC, 0) == 0x0AB5);
    assert(lmt_mode(LMT_MODE_DORIAN, 0) == lmt_pcs_from_list((lmt_pitch_class[]){0, 2, 3, 5, 7, 9, 10}, 7));

    const lmt_key_context c_major_ctx = {.tonic = 0, .quality = LMT_KEY_MAJOR};
    assert(strcmp(lmt_spell_note(1, c_major_ctx), "C#") == 0);

    lmt_pitch_class_set c_minor = lmt_chord(LMT_CHORD_MINOR, 0);
    assert(c_minor == lmt_pcs_from_list((lmt_pitch_class[]){0, 3, 7}, 3));
    assert(strcmp(lmt_chord_name(c_major), "Major") == 0);
    assert(strcmp(lmt_roman_numeral(c_major, c_major_ctx), "I") == 0);

    const uint8_t tuning[6] = {40, 45, 50, 55, 59, 64};
    assert(lmt_fret_to_midi(0, 0, tuning) == 40);

    lmt_fret_pos pos[6] = {0};
    uint8_t pos_count = lmt_midi_to_fret_positions(60, tuning, pos);
    assert(pos_count > 0);

    char svg[8192] = {0};
    uint32_t svg_len = lmt_svg_clock_optc(c_major, svg, sizeof(svg));
    assert(svg_len > 0);
    assert(strncmp(svg, "<svg", 4) == 0);

    const int8_t frets[6] = {-1, 3, 2, 0, 1, 0};
    svg_len = lmt_svg_fret(frets, svg, sizeof(svg));
    assert(svg_len > 0);
    assert(strncmp(svg, "<svg", 4) == 0);

    svg_len = lmt_svg_chord_staff(LMT_CHORD_MAJOR, 0, svg, sizeof(svg));
    assert(svg_len > 0);
    assert(strncmp(svg, "<svg", 4) == 0);

    return 0;
}
