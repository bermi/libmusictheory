# WASM Footprint Audit

## Current Snapshot (2026-03-10)

`zig-out/wasm-demo/libmusictheory.wasm`

- Total size: `671,101` bytes
- `CODE` section: `133,707` bytes
- `DATA` section: `536,055` bytes

Reachable generated files (`9`) total `1,511,555` source bytes.
Coordinate-like reachable generated files total `13,586` bytes.

Notable deltas from the prior baseline:

- `src/generated/harmonious_majmin_compat_xz.zig` is no longer reachable from wasm.
- `src/generated/harmonious_majmin_scene_pack_xz.zig` replaced the old majmin compat payload.
- Strict compatibility still holds (`8634/8634`, `0` mismatches) while shrinking wasm footprint.

## Baseline (2026-02-19)

`zig-out/wasm-demo/libmusictheory.wasm`

- Total size: `829,547` bytes
- `CODE` section: `120,191` bytes
- `DATA` section: `708,087` bytes

The wasm is data-dominated, so size reduction work should prioritize generated data elimination and algorithmic rendering.

## Reachable Generated Payload (from `src/root.zig` import graph)

Current reachable generated files (`9`) total `1,511,555` source bytes.
Top contributors:

- `src/generated/harmonious_majmin_scene_pack_xz.zig` (`988,786`)
- `src/generated/harmonious_manifest.zig` (`236,976`)
- `src/generated/harmonious_even_segment_gzip.zig` (`161,003`)
- `src/generated/harmonious_oc_templates.zig` (`39,463`)
- `src/generated/harmonious_chord_compat_assets.zig` (`34,869`)
- `src/generated/harmonious_text_primitives.zig` (`22,553`)
- `src/generated/harmonious_scale_nomod_assets.zig` (`13,586`)
- `src/generated/harmonious_scale_mod_offset_assets.zig` (`10,300`)
- `src/generated/harmonious_optc_templates.zig` (`4,019`)

Coordinate-like reachable generated files total `13,586` bytes:

- `src/generated/harmonious_scale_nomod_assets.zig`

## Guardrails

`./verify.sh` now runs `scripts/wasm_size_audit.py` with enforced budgets:

- wasm total: `< 900,000` bytes
- wasm `DATA` section: `< 760,000` bytes
- reachable generated footprint: `< 1,800,000` bytes
- reachable coordinate-like generated footprint: `< 170,000` bytes

Additional anti-replay guardrails block reintroduction of chord replay table imports:

- forbidden in `src/svg/chord_compat.zig`:
- `harmonious_chord_mod_x_lookup`
- `harmonious_chord_mod_y_lookup`
- `harmonious_whole_note_x_lookup`
- `harmonious_whole_note_y_lookup`
- `harmonious_chord_mod_patches`
- `harmonious_chord_mod_ulpshim`
- `harmonious_whole_note_patches`
- `harmonious_whole_note_ulpshim`
- forbidden in `src/generated/harmonious_scale_mod_assets.zig`:
- `ModPatch`
- `SHARP_PATCH`
- `FLAT_PATCH`
- `NATURAL_PATCH`
- `DOUBLE_FLAT_PATCH`
- `SHARP_OFFSETS`
- `FLAT_OFFSETS`
- `NATURAL_OFFSETS`
- `DOUBLE_FLAT_OFFSETS`

## Reduction Priorities

1. Replace `majmin` scene-pack remap payload with direct computed scene geometry/routing.
2. Replace `even` packed payload with algorithmic rendering.
3. Reduce compatibility manifest payload by deriving image arguments/names algorithmically where possible.
4. Continue removing residual coordinate-like tables as strict parity formulas become available.
