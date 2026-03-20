#ifndef LIBMUSICTHEORY_COMPAT_H
#define LIBMUSICTHEORY_COMPAT_H

#include "libmusictheory.h"

#ifdef __cplusplus
extern "C" {
#endif

uint32_t lmt_bitmap_proof_scale_numerator(void);
uint32_t lmt_bitmap_proof_scale_denominator(void);
uint32_t lmt_bitmap_compat_kind_supported(uint32_t kind_index);
const char *lmt_bitmap_compat_candidate_backend_name(uint32_t kind_index);
uint32_t lmt_bitmap_compat_target_width_scaled(uint32_t kind_index, uint32_t image_index, uint32_t scale_numerator, uint32_t scale_denominator);
uint32_t lmt_bitmap_compat_target_width(uint32_t kind_index, uint32_t image_index);
uint32_t lmt_bitmap_compat_target_height_scaled(uint32_t kind_index, uint32_t image_index, uint32_t scale_numerator, uint32_t scale_denominator);
uint32_t lmt_bitmap_compat_target_height(uint32_t kind_index, uint32_t image_index);
uint32_t lmt_bitmap_compat_required_rgba_bytes_scaled(uint32_t kind_index, uint32_t image_index, uint32_t scale_numerator, uint32_t scale_denominator);
uint32_t lmt_bitmap_compat_required_rgba_bytes(uint32_t kind_index, uint32_t image_index);
uint32_t lmt_bitmap_compat_render_candidate_rgba_scaled(uint32_t kind_index, uint32_t image_index, uint32_t scale_numerator, uint32_t scale_denominator, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_compat_render_candidate_rgba(uint32_t kind_index, uint32_t image_index, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_compat_render_reference_svg_rgba_scaled(uint32_t kind_index, uint32_t scale_numerator, uint32_t scale_denominator, const char *svg_ptr, uint32_t svg_len, uint8_t *out_rgba, uint32_t out_rgba_size);
uint32_t lmt_bitmap_compat_render_reference_svg_rgba(uint32_t kind_index, const char *svg_ptr, uint32_t svg_len, uint8_t *out_rgba, uint32_t out_rgba_size);
char *lmt_wasm_scratch_ptr(void);
uint32_t lmt_wasm_scratch_size(void);
uint32_t lmt_svg_compat_kind_count(void);
const char *lmt_svg_compat_kind_name(uint32_t kind_index);
const char *lmt_svg_compat_kind_directory(uint32_t kind_index);
uint32_t lmt_svg_compat_image_count(uint32_t kind_index);
uint32_t lmt_svg_compat_image_name(uint32_t kind_index, uint32_t image_index, char *buf, uint32_t buf_size);
uint32_t lmt_svg_compat_generate(uint32_t kind_index, uint32_t image_index, char *buf, uint32_t buf_size);

#ifdef __cplusplus
}
#endif

#endif
