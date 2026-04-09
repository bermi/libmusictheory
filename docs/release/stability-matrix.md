# Stability Matrix

This document is the authoritative classification for the standalone release surface.

## Stable Contract

These are the surfaces that `0.1.0` promises as the stable embedding contract:

- public C ABI declarations in `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, except the APIs explicitly marked experimental in that header
- source-based Zig integration through `/Users/bermi/code/libmusictheory/src/root.zig`
- native build/install path through `./zigw build`
- verification/build path through `./zigw build test`, `./zigw build verify`, and `./verify.sh`
- standalone docs bundle from `./zigw build wasm-docs`

Stable API families include:

- scalar PCS, scale, mode, chord, key, harmony, and naming helpers
- public fret semantics and URL helpers
- public SVG helpers:
  - `lmt_svg_clock_optc`
  - `lmt_svg_optic_k_group`
  - `lmt_svg_evenness_chart`
  - `lmt_svg_evenness_field`
  - `lmt_svg_fret`
  - `lmt_svg_fret_n`
  - `lmt_svg_chord_staff`
  - `lmt_svg_key_staff`
  - `lmt_svg_piano_staff`
  - `lmt_svg_keyboard`

## Experimental Public Surface

These helpers are intentionally public and reviewed, but they are not part of the stable embedding contract for `0.1.0`:

- raster/backend probes:
  - `lmt_raster_is_enabled`
  - `lmt_raster_demo_rgba`
- counterpoint state, ranking, cadence, suspension, and orbifold helpers:
  - `lmt_counterpoint_*`
  - `lmt_build_voiced_state`
  - `lmt_voiced_history_*`
  - `lmt_classify_motion`
  - `lmt_evaluate_motion_profile`
  - `lmt_satb_*`
  - `lmt_rank_next_steps`
  - `lmt_rank_cadence_destinations`
  - `lmt_analyze_suspension_machine`
  - `lmt_orbifold_triad_*`
  - `lmt_find_orbifold_triad_node`
- live-gallery policy helpers:
  - `lmt_mode_spelling_quality`
  - `lmt_rank_context_suggestions`
  - `lmt_preferred_voicing_n`
- ordered-scale pedagogy helpers:
  - `lmt_ordered_scale_*`
  - `lmt_barry_harris_parity`
- playability profile and practice-feedback helpers:
  - `lmt_playability_profile_preset_*`
  - `lmt_playability_profile_from_preset`
  - `lmt_summarize_*_playability_difficulty_*`
  - `lmt_suggest_easier_*`
  - `lmt_suggest_safer_keyboard_next_step_by_playability`
- direct RGBA bitmap renderers:
  - all `lmt_bitmap_*_rgba` methods

These helpers are valid to ship, document, and review. They are useful for demos, hardware-oriented rendering paths, and exploratory composition tooling. They should still be described as experimental anywhere they appear publicly.

Their current review interpretation is defined in `/Users/bermi/code/libmusictheory/docs/release/image-review-matrix.md`: the QA atlas and gallery preview toggle are proof tools for these helpers, not stable promises of exact bitmap parity.

## Supported Standalone Example Surface

The standalone gallery bundle is supported as a release artifact and review surface:

- `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/`

But it is not the stable embedding contract by itself. The gallery intentionally mixes:

- stable public SVG APIs
- experimental counterpoint helpers
- experimental direct bitmap preview helpers

Review the gallery for bundle quality, coherence, and regression safety. Do not treat every helper required by the live gallery as automatically stable.

## Internal Regression Infrastructure

These surfaces are internal verification infrastructure and not part of the standalone release contract:

- `/Users/bermi/code/libmusictheory/include/libmusictheory_compat.h`
- Harmonious parity/proof/SPA regression bundles
- local Harmonious reference trees used only for regression work
- internal compat namespaces such as:
  - `harmonious_svg_compat`
  - `bitmap_compat`
  - `svg_*_compat`

## Review Interpretation

For stable-release signoff:

- stable contract surfaces must be defensible as `0.1.0`
- experimental public helpers must be clearly marked experimental
- internal regression infrastructure must remain available without being presented as public product API
