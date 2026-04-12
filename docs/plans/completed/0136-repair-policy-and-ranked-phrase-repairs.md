# 0136 — Repair Policy And Ranked Phrase Repairs

## Status

- Draft: 2026-04-12
- In Progress: 2026-04-12
- Completed: 2026-04-12

## Goal

Add explicit repair-policy semantics and ranked phrase repairs without blurring the boundary between alternate realization and changed music.

## Scope

1. Define the repair-policy struct and reflection helpers.
2. Keep repair classes distinct:
   - `realization_only`
   - `register_adjusted`
   - `texture_reduced`
3. Add ranked phrase repair helpers for keyboard and fret phrases.
4. Ensure every repair reports:
   - what changed
   - what was preserved
   - the playability lift
   - whether the repair crossed a musical-change boundary

## Files

- `/Users/bermi/code/libmusictheory/src/playability/repair.zig`
- `/Users/bermi/code/libmusictheory/src/playability/phrase.zig`
- `/Users/bermi/code/libmusictheory/src/playability/profile.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to say:
- "This is not just a refingering: it preserves the bass and top voice, but it moves one inner note by octave to remove the phrase bottleneck."

## Verification

- repair-policy boundary tests
- preservation-flag tests
- ranked repair-class separation tests
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Verification Commands

- `/Users/bermi/code/libmusictheory/./zigw build test`
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Implementation History (Point-in-Time)

- `f4054471014d28c2d2d8e90426188ef85771185f` — 2026-04-12
  - Added `/Users/bermi/code/libmusictheory/src/playability/repair.zig` with explicit `RepairPolicy`, `RepairClass`, ranked keyboard/fret phrase repair rows, and preservation/change reporting.
  - Extended `/Users/bermi/code/libmusictheory/include/libmusictheory.h` and `/Users/bermi/code/libmusictheory/src/c_api.zig` with experimental repair-policy structs, reflection helpers, `sizeof` helpers, and phrase-repair ranking exports.
  - Added focused Zig and C ABI coverage in `/Users/bermi/code/libmusictheory/src/tests/playability_repair_test.zig` and `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`, then documented the repair-policy boundary in `/Users/bermi/code/libmusictheory/docs/api.md` and `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md`.
  - Verification gates:
    - `/Users/bermi/code/libmusictheory/./zigw build test`
    - `/Users/bermi/code/libmusictheory/./verify.sh`
