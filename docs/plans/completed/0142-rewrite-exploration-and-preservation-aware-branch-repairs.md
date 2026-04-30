# 0142 — Rewrite Exploration And Preservation-Aware Branch Repairs

## Status

- Completed: 2026-04-30

## Goal

Extend the repair-policy surface from single phrase repairs to branch-aware rewrite exploration so callers can ask for minimal, explainable alternatives across a short continuation window.

## Scope

1. Reuse the existing repair-policy boundary:
   - realization-only
   - register-adjusted
   - texture-reduced
2. Evaluate rewrite candidates over branch windows rather than isolated local events.
3. Return ranked branch repairs with explicit preservation metadata:
   - events touched
   - notes changed
   - first relieved bottleneck
   - new dominant strain family, if any
4. Do not silently mix preservation classes in one ranked list.

## Files

- `/Users/bermi/code/libmusictheory/src/playability/repair.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_repair_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/build.zig`
- `/Users/bermi/code/libmusictheory/scripts/check_wasm_exports.mjs`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md`
- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to say:
- "This repair keeps the same sounding notes but changes the physical realization across the branch."
- "This second repair changes the voicing register, and that is why the bottleneck disappears at step three."

## Verification

- policy-boundary tests proving preservation classes stay separate
- ranked branch-repair tests with explicit bottleneck relief metadata
- `/Users/bermi/code/libmusictheory/./zigw build test`
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Implementation History (Point-in-Time)

- `803fd72` — 2026-04-30
  - Added preservation-aware keyboard and fret branch-repair ranking so callers can request one repair class at a time without silently widening from realization-only to register-adjusted or texture-reduced rewrites.
  - Added ranked branch-repair metadata covering touched events, changed notes, first relieved bottleneck step, dominant-family shifts, and full replacement branches, then exposed that surface through the experimental C ABI and wasm export guardrails.
  - Added focused Zig and C ABI coverage plus research/API documentation showing how branch rewrites stay explainable as physical realization changes versus genuine musical changes.
  - Verification commands:
    - `/Users/bermi/code/libmusictheory/./zigw build test`
    - `/Users/bermi/code/libmusictheory/./verify.sh`
