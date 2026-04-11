# 0134 — Fixed-Realization Phrase Audit Engines

## Status

- Draft: 2026-04-12

## Goal

Implement phrase-level audit passes for already-chosen keyboard and fret realizations by composing the existing local realization and transition assessment engines across an explicit event stream.

## Scope

1. Audit fixed fret phrases.
2. Audit fixed keyboard phrases.
3. Emit phrase issue lists that point to:
   - event-local blockers
   - transition-local blockers
   - repeated warning clusters
   - recovery-deficit runs
4. Summarize the passage without changing the music.

## Files

- `/Users/bermi/code/libmusictheory/src/playability/phrase.zig`
- `/Users/bermi/code/libmusictheory/src/playability/fret_assessment.zig`
- `/Users/bermi/code/libmusictheory/src/playability/keyboard_assessment.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to say:
- "Every event is locally reachable, but the phrase becomes strained because the hand never recovers from the previous two shifts."

## Verification

- phrase-level keyboard and fret audit tests
- issue-list indexing tests
- summary consistency tests
- `/Users/bermi/code/libmusictheory/./verify.sh`
