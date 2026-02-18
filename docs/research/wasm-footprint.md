# WASM Footprint Audit

## Baseline (2026-02-18)

`zig-out/wasm-demo/libmusictheory.wasm`

- Total size: `856,729` bytes
- `CODE` section: `114,230` bytes
- `DATA` section: `741,231` bytes

The wasm is data-dominated, so size reduction work should prioritize generated data elimination and algorithmic rendering.

## Reachable Generated Payload (from `src/root.zig` import graph)

Current reachable generated files (`12`) total `1,751,084` source bytes.
Top contributors:

- `src/generated/harmonious_majmin_compat_xz.zig` (`774,450`)
- `src/generated/harmonious_even_gzip.zig` (`315,029`)
- `src/generated/harmonious_manifest.zig` (`248,324`)
- `src/generated/harmonious_text_templates.zig` (`187,309`)

Coordinate-like reachable generated files total `147,621` bytes:

- `src/generated/harmonious_chord_mod_patches.zig`
- `src/generated/harmonious_whole_note_patches.zig`
- `src/generated/harmonious_scale_mod_assets.zig`
- `src/generated/harmonious_scale_nomod_assets.zig`
- `src/generated/harmonious_scale_layout_ulpshim.zig`

## Guardrails

`./verify.sh` now runs `scripts/wasm_size_audit.py` with enforced budgets:

- wasm total: `< 900,000` bytes
- wasm `DATA` section: `< 760,000` bytes
- reachable generated footprint: `< 1,800,000` bytes
- reachable coordinate-like generated footprint: `< 170,000` bytes

Additional anti-replay guardrail blocks reintroduction of chord x/y lookup coordinate tables:

- forbidden in `src/svg/chord_compat.zig`:
- `harmonious_chord_mod_x_lookup`
- `harmonious_chord_mod_y_lookup`
- `harmonious_whole_note_x_lookup`
- `harmonious_whole_note_y_lookup`

## Reduction Priorities

1. Replace `majmin` packed templates with algorithmic renderer.
2. Replace `even` packed payload with algorithmic rendering.
3. Reduce compatibility manifest payload by deriving image arguments/names algorithmically where possible.
4. Continue removing coordinate-like patch/shim tables as strict parity formulas become available.
