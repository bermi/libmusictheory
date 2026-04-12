# 0135 — Committed Phrase Memory And Choice Bias

## Status

- Draft: 2026-04-12

## Goal

Add caller-owned committed phrase memory so accepted choices can bias future ranking and phrase analysis without introducing hidden global library state.

## Scope

1. Define explicit committed-memory structs for:
   - keyboard realized events
   - fret realized events
   - compatibility with existing voiced-history usage where relevant
2. Add reset, append, and length helpers.
3. Add helpers that bias later ranking or phrase summaries from committed accepted history.
4. Keep preview-only host interactions out of library memory.

## Design Rule

This slice must follow the existing `libmusictheory` state style:
- caller-owned memory
- explicit reset and push
- deterministic outputs from explicit inputs
- no hidden global blackboard

## Explicit Pushback

A generic library "blackboard" object would be the wrong abstraction if it mixes:
- committed musical choices
- hover or preview focus
- browser device state
- persistence preferences

Only committed choices that change later musical or playability results belong here.

## Files

- `/Users/bermi/code/libmusictheory/src/playability/phrase.zig`
- `/Users/bermi/code/libmusictheory/src/playability/ranking.zig`
- `/Users/bermi/code/libmusictheory/src/counterpoint.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md`
- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to say:
- "This next move is favored because your committed phrase already established an anchor that avoids another large shift."
- "Pinned for preview does not change the phrase memory; committed choices do."

## Verification

- reset and append tests for committed phrase memory
- commit-versus-preview semantic tests
- bias-from-committed-history tests
- C ABI memory layout and push helper tests
- `/Users/bermi/code/libmusictheory/./verify.sh`
