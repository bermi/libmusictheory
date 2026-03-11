# WASM Footprint Audit

## Current Snapshot (2026-03-11)

`zig-out/wasm-demo/libmusictheory.wasm`

- Total size: `517,223` bytes
- `CODE` section: `137,670` bytes
- `DATA` section: `378,211` bytes

Reachable generated files (`10`) total `1,558,179` source bytes.
Coordinate-like reachable generated files total `13,586` bytes.

Notable deltas from the prior baseline:

- `src/generated/harmonious_manifest.zig` is no longer reachable from wasm runtime path.
- New compact name-pack payload `src/generated/harmonious_name_pack_xz.zig` replaces pointer-heavy manifest name arrays for non-majmin enumeration.
- Strict compatibility still holds (`8634/8634`, `0` mismatches) while shrinking wasm footprint below `512 KiB`.

## Baseline (2026-02-19)

`zig-out/wasm-demo/libmusictheory.wasm`

- Total size: `829,547` bytes
- `CODE` section: `120,191` bytes
- `DATA` section: `708,087` bytes

The wasm is data-dominated, so size reduction work should prioritize generated data elimination and algorithmic rendering.

## Reachable Generated Payload (from `src/root.zig` import graph)

Current reachable generated files (`10`) total `1,558,179` source bytes.
Top contributors:

- `src/generated/harmonious_majmin_scene_pack_xz.zig` (`989,501`)
- `src/generated/harmonious_majmin_modes_geometry_refs.zig` (`172,026`)
- `src/generated/harmonious_even_segment_gzip.zig` (`161,003`)
- `src/generated/harmonious_name_pack_xz.zig` (`110,859`)
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

- wasm total: `< 524,288` bytes
- wasm `DATA` section: `< 480,000` bytes
- reachable generated footprint: `< 1,600,000` bytes
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

1. Replace `harmonious_name_pack_xz` driven enumeration with per-kind algorithmic image-name generation.
2. Continue reducing `majmin` scene-pack payload through numeric/algorithmic decomposition.
3. Replace remaining packed compatibility payloads (`even`, `oc`, `optc`, staff/fret families) with audited algorithmic emitters.
4. Continue removing residual coordinate-like tables as strict parity formulas become available.
