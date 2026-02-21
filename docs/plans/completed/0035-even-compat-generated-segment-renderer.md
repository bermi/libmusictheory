# 0035 - Even Compat Segmented Gzip Renderer

Status: Completed

## Objective

Replace the monolithic even compat gzip payload with deterministic segment-by-segment assembly while preserving exact byte parity and wasm size budgets.

## Why

- `even/index|grad|line` share large structural regions and only differ in bounded tails.
- A monolithic payload is harder to audit and evolve than explicit shared/variant segments.
- We must keep strict parity while preserving `wasm < 1MB` guardrails.

## Scope

- `src/svg/evenness_chart.zig` compat path only.
- New generated segmented gzip asset module and extraction script.
- `./verify.sh` guardrails to prevent regressing to monolithic even payloads.

## Non-Goals

- Full symbolic algorithmic reconstruction of the decorative `even/index.svg` drawing grammar.
- Any relaxation of exact byte-match requirements.

## Implementation Slices

### Slice A: Verification Guardrails First

- Update `./verify.sh` with conditional checks:
  - `src/svg/evenness_chart.zig` does not import `harmonious_even_gzip`.
  - `src/svg/evenness_chart.zig` imports `harmonious_even_segment_gzip`.
  - `src/generated/harmonious_even_gzip.zig` is removed.
  - `src/generated/harmonious_even_segments.zig` is removed.

### Slice B: Segment-Gzip Asset Extraction

- Add `scripts/generate_harmonious_even_segment_gzip.py` to derive:
  - compat shared prefix,
  - index-only prefix,
  - shared core body,
  - per-variant tails (`index`, `grad`, `line`).
- Emit `src/generated/harmonious_even_segment_gzip.zig`.

### Slice C: Renderer Switch

- Replace monolithic payload selection with explicit segment append order in `renderEvennessByName`.
- Use fixed-buffer streaming and per-segment gzip decompression.

### Slice D: Verification

- Run `./verify.sh` (including sampled and full Playwright compatibility checks).

## Completion Criteria

- No runtime import of `harmonious_even_gzip` in even renderer.
- `renderEvennessByName` returns byte-identical output for `index|grad|line`.
- `./verify.sh` passes with wasm size guardrails and `0` compatibility mismatches.

## Implementation History (Point-in-Time)

- `4f3ea84a6981104001c130ff4877c0c1753ab00e` (`2026-02-21T23:14:36+01:00`)
- Shipped behavior:
- Replaced monolithic `src/generated/harmonious_even_gzip.zig` usage with explicit segmented gzip assembly in `src/svg/evenness_chart.zig`.
- Added `scripts/generate_harmonious_even_segment_gzip.py` and generated `src/generated/harmonious_even_segment_gzip.zig` with shared and variant payload segments.
- Added `0035` verify guardrails in `./verify.sh` to enforce segmented module wiring and prevent fallback to monolithic/uncompressed artifacts.
- Guardrail/completion verification:
- `./verify.sh`
