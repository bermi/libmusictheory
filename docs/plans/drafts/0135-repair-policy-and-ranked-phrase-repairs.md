# 0135 — Repair Policy And Ranked Phrase Repairs

## Status

- Draft: 2026-04-12

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
