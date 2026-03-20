#include "libmusictheory_compat.h"

#include <assert.h>

int main(void) {
    assert(lmt_wasm_scratch_ptr() != 0);
    assert(lmt_wasm_scratch_size() >= (1024u * 1024u));
    assert(lmt_svg_compat_kind_count() > 0);
    assert(lmt_bitmap_proof_scale_numerator() > 0);
    assert(lmt_bitmap_compat_kind_supported(0) == 0 || lmt_bitmap_compat_kind_supported(0) == 1);
    return 0;
}
