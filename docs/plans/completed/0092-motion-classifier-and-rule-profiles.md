# 0092 — Motion Classifier And Rule Profiles

> Dependencies: 0091
> Follow-up: 0093, 0094

Status: Completed

## Summary

Build the adjacent-state motion semantics and style-profile system needed to distinguish good counterpoint from merely short voice-leading distance.

## Scope

### MotionClassifier

Per adjacent state pair, classify:

- contrary motion
- similar motion
- parallel motion
- oblique motion
- voice crossing
- voice overlap
- step vs leap magnitude
- common-tone retention
- outer-voice interval trajectory

### CounterpointRuleProfile

Provide multiple reusable profiles instead of one hidden rule set:

- species
- tonal chorale
- modal polyphony
- jazz close-leading
- free contemporary

Each profile specifies at least:

- which motion classes are preferred, penalized, or disallowed
- spacing expectations
- leap handling expectations
- cadence weighting hooks
- dissonance/tendency-tone expectations where already available

## Exit Criteria

- adjacent-state motion classes are available as deterministic library results
- multiple rule profiles exist and change evaluation behavior in tests
- the library can explain motion semantics without relying on gallery JS heuristics
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./zigw build test`

## Implementation History (Point-in-Time)

- `5b0a7ef` — 2026-03-27
- Shipped behavior:
  - added deterministic motion classification, profile evaluation, and exported profile metadata in `/Users/bermi/code/libmusictheory/src/counterpoint.zig`, `/Users/bermi/code/libmusictheory/src/c_api.zig`, `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, `/Users/bermi/code/libmusictheory/build.zig`, and `/Users/bermi/code/libmusictheory/scripts/check_wasm_exports.mjs`
  - shipped profile-sensitive fixtures covering contrary, similar, parallel, oblique, crossing, overlap, leaps, and common-tone retention in `/Users/bermi/code/libmusictheory/src/tests/counterpoint_test.zig` and `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
  - documented the library-side motion semantics in `/Users/bermi/code/libmusictheory/docs/research/algorithms/voice-leading.md`
- Completion gates used:
  - `./verify.sh`
  - `./zigw build test`
