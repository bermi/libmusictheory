# 0133 — Phrase Event Model And Audit Summaries

## Status

- Draft: 2026-04-12
- In Progress: 2026-04-12
- Completed: 2026-04-12

## Goal

Create the shared phrase-audit foundation for playability so later slices can reason about a whole passage without inventing incompatible event or summary semantics.

## Scope

1. Define phrase event structs for keyboard and fret audit inputs.
2. Define phrase issue records with explicit event/transition indexing.
3. Define phrase summary structs:
   - first blocked event
   - first blocked transition
   - bottleneck severity
   - cumulative cost
   - dominant reason and warning
   - issue counts by severity
4. Expose reflection and sizeof helpers through the experimental C ABI.

## Files

- `/Users/bermi/code/libmusictheory/src/playability/types.zig`
- `/Users/bermi/code/libmusictheory/src/playability/phrase.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to say:
- "The first blocked point in the phrase is transition 4 → 5, and the phrase bottleneck is a shift overload rather than a span overload."

## Verification

- focused phrase-struct and summary tests
- C ABI reflection/sizeof coverage
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Implementation History (Point-in-Time)

- Commit: `48e5567a4aa04130e0308ff1fe3e34959cb53f36`
- Date: `2026-04-12`
- Shipped behavior:
  - added `/Users/bermi/code/libmusictheory/src/playability/phrase.zig` with fixed-size fret and keyboard phrase events, explicit event-versus-transition issue rows, and aggregate phrase summaries
  - wired the new phrase helpers into the public Zig surface through `/Users/bermi/code/libmusictheory/src/playability.zig` and the focused test suite through `/Users/bermi/code/libmusictheory/src/root.zig`
  - extended `/Users/bermi/code/libmusictheory/include/libmusictheory.h` and `/Users/bermi/code/libmusictheory/src/c_api.zig` with phrase issue/severity reflection, struct size helpers, and assessment-sequence wrappers for fret and keyboard phrases
  - added focused Zig and C ABI coverage in `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig` and `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
  - updated `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md`, `/Users/bermi/code/libmusictheory/docs/api.md`, and `/Users/bermi/code/libmusictheory/verify.sh` so the phrase audit foundation is documented and programmatically guarded
- Verification commands:
  - `/Users/bermi/code/libmusictheory/./zigw build test`
  - `/Users/bermi/code/libmusictheory/./verify.sh`
