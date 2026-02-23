# 0037 - Text Compat Symbolic Renderer

Status: In Progress

## Objective

Replace `vert-text-black` / `vert-text-b2t-black` per-stem path lookup with a symbol-level renderer that composes each label from a compact primitive grammar while preserving exact SVG byte parity.

## Why

- `0036` proved all vertical labels decompose into a fixed primitive alphabet with deterministic segmentation.
- Current implementation still carries large per-stem path payload tables.
- Symbol-level composition reduces replay-like data dependence and tightens algorithmic rendering integrity.

## Scope

- Implement symbolic vertical label generation in `src/svg/text_misc.zig`.
- Add generated primitive model assets (symbol primitives + orientation layout parameters).
- Keep `center-square-text` exact behavior unchanged (still exact path lookup).
- Add verify guardrails for symbolic path usage and removal of vertical per-stem template dependency.

## Non-Goals

- Reworking `center-square-text` in this slice.
- Generic arbitrary-font text shaping.

## Implementation Slices

### Slice A: Guardrails First

- Update `./verify.sh` so that when symbolic text primitive assets exist:
  - `src/svg/text_misc.zig` must import symbolic text primitive module.
  - `src/svg/text_misc.zig` must not reference `VERT_TEXT_BLACK` or `VERT_TEXT_B2T_BLACK` template arrays.

### Slice B: Primitive Asset Generation

- Add `scripts/generate_harmonious_text_primitives.py` to emit:
  - vertical text primitive bodies and symbol decomposition model.
  - center-square template paths in a dedicated module.

### Slice C: Renderer Switch

- Replace vertical per-stem lookup in `renderVerticalLabel` with symbol composition.
- Preserve exact wrapper/header/transform strings and output formatting.

### Slice D: Verification

- Run `./verify.sh` (includes sampled/full Playwright parity checks).

## Completion Criteria

- Vertical text output remains exact (`0` mismatches across all compat kinds).
- No vertical dependence on per-stem template arrays.
- `./verify.sh` remains green, including wasm size and Playwright gates.
