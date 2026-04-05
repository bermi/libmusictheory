# Public Image Review Matrix

This document is the authoritative release-review interpretation for the standalone image surfaces.

## Stable SVG Contract Surfaces

The stable contract covers the public SVG-producing methods and their appearance in the standalone docs bundle:

- `lmt_svg_clock_optc`
- `lmt_svg_optic_k_group`
- `lmt_svg_evenness_chart`
- `lmt_svg_evenness_field`
- `lmt_svg_fret`
- `lmt_svg_fret_n`
- `lmt_svg_chord_staff`
- `lmt_svg_key_staff`
- `lmt_svg_keyboard`
- `lmt_svg_piano_staff`

Stable review bar:

- these methods must stay available through `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- they must render in `wasm-docs`
- they must remain covered by the docs QA atlas and browser validation

## Experimental Bitmap Parity Review

The direct bitmap companions remain experimental public APIs:

- `lmt_bitmap_clock_optc_rgba`
- `lmt_bitmap_optic_k_group_rgba`
- `lmt_bitmap_evenness_chart_rgba`
- `lmt_bitmap_evenness_field_rgba`
- `lmt_bitmap_fret_rgba`
- `lmt_bitmap_fret_n_rgba`
- `lmt_bitmap_chord_staff_rgba`
- `lmt_bitmap_key_staff_rgba`
- `lmt_bitmap_keyboard_rgba`
- `lmt_bitmap_piano_staff_rgba`

Review bar:

- the docs QA atlas renders direct PNGs encoded from these RGBA buffers
- `/Users/bermi/code/libmusictheory/scripts/validate_wasm_docs_bitmap_playwright.mjs` enforces a default max drift of `0.005`
- this is the experimental bitmap regression bar, not a stable promise of exact SVG-vs-bitmap parity

## Gallery Preview Toggle Review

The gallery preview toggle is a supported review tool for the standalone example bundle.

Review bar:

- the gallery can switch the large visualization hosts between SVG and direct bitmap previews
- `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs` enforces a default critical-host drift threshold of `0.07`
- this validates bundle-level coherence for the example surface after browser layout/normalization
- it does not promote the direct bitmap helpers or the gallery preview comparison to the stable embedding contract

Current critical hosts:

- `midi-clock`
- `midi-optic-k`
- `midi-evenness`
- `set-clock`
- `set-optic-k`
- `set-evenness`

## Review Interpretation

- stable release signoff is about the SVG contract and the docs bundle behavior
- experimental bitmap APIs are still important and must stay reviewable, but they are governed by the QA atlas drift bar rather than a stable exact-parity promise
- the gallery preview toggle is a proof tool for the supported example surface, not a claim of exact `1:1` bitmap parity across all hosts
- if a future release wants to promise exact or near-exact bitmap parity as stable behavior, both the thresholds and this matrix must be tightened first
