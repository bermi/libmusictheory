# 0133 — Phrase Event Model And Audit Summaries

## Status

- Completed: 2026-04-12

## Goal

Create the shared phrase-audit foundation for playability so later slices can reason about a whole passage without inventing incompatible event or summary semantics.

## Important Boundary

This slice is structural only.

It does:
- define the event model
- define issue rows and phrase summaries
- define the vocabulary later audit engines and committed-memory helpers will reuse

It does not:
- perform phrase auditing yet
- introduce committed phrase memory
- bias future ranking
- carry host preview or pin state into the library

## Scope

1. Define phrase event structs for keyboard and fret audit inputs.
2. Define phrase issue records with explicit event/transition indexing.
3. Define phrase summary structs:
   - first blocked event
   - first blocked transition
   - bottleneck severity
   - cumulative strain bucket
   - dominant reason and warning family
   - issue counts by severity and family
   - recovery-deficit run metadata
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
- "The phrase is not blocked yet, but it stays in a high-strain bucket for three consecutive events with no recovery."

## Verification

- focused phrase-struct and summary tests
- summary bucket/family tests
- C ABI reflection/sizeof coverage
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Verification Commands

- `/Users/bermi/code/libmusictheory/./zigw build test`
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Implementation History (Point-in-Time)

- `525dfc9` — 2026-04-12
  - added `/Users/bermi/code/libmusictheory/src/playability/phrase.zig` with fixed-size keyboard/fret phrase events, issue rows, summary accumulator logic, and named phrase-summary vocabulary
  - exported the phrase surface through `/Users/bermi/code/libmusictheory/src/playability.zig`, `/Users/bermi/code/libmusictheory/src/c_api.zig`, `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, `/Users/bermi/code/libmusictheory/build.zig`, and `/Users/bermi/code/libmusictheory/scripts/check_wasm_exports.mjs`
  - added focused Zig and C ABI coverage in `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig` and `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
  - documented the phrase-foundation boundary in `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md` and `/Users/bermi/code/libmusictheory/docs/api.md`
  - verification gates: `/Users/bermi/code/libmusictheory/./zigw build test`, `/Users/bermi/code/libmusictheory/./verify.sh`
