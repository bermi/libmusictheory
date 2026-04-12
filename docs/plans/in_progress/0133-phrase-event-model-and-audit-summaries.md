# 0133 — Phrase Event Model And Audit Summaries

## Status

- In Progress: 2026-04-12

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
