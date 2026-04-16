# 0140 — Phrase Branch State And Fixed-Horizon Candidate Windows

## Status

- In progress: 2026-04-16

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
