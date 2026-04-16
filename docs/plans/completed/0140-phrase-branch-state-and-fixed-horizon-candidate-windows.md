# 0140 — Phrase Branch State And Fixed-Horizon Candidate Windows

## Status

- Completed: 2026-04-16

## Goal

Add the structural generation primitives needed to evaluate short continuation branches against committed phrase memory without introducing hidden search policy.

## Scope

1. Define fixed-size branch/window structs for phrase-aware generation.
2. Define explicit per-step candidate event containers for keyboard and fret phrases.
3. Add summary helpers that expose:
   - step count
   - first blocked step
   - first blocked transition inside the branch
   - peak strain step
   - recovery-improving versus recovery-deficit windows
4. Keep this slice structural only:
   - no ranking policy yet
   - no rewrite generation yet

## Files

- `/Users/bermi/code/libmusictheory/src/playability/phrase.zig`
- `/Users/bermi/code/libmusictheory/src/playability/types.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to say:
- "This branch is four events long, and the first blocked step is the third one."
- "The branch stays playable, but the worst strain appears at step two."

## Verification

- unit tests for branch and step metadata
- C ABI coverage for the new structs and summary helpers
- `/Users/bermi/code/libmusictheory/./zigw build test`
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Implementation History (Point-in-Time)

- `e9c5697` — 2026-04-16
  - Added fixed-size keyboard/fret phrase branch structs and per-step candidate windows for short fixed-horizon generation.
  - Added branch summary reducers that expose blocked-step, blocked-transition, peak-strain, and recovery-window facts without introducing ranking or rewrite policy.
  - Added experimental C ABI structs, size helpers, and branch summary wrappers, plus focused Zig/C ABI coverage and API/research documentation updates.
  - Verification commands:
    - `/Users/bermi/code/libmusictheory/./zigw build test`
    - `/Users/bermi/code/libmusictheory/./verify.sh`
