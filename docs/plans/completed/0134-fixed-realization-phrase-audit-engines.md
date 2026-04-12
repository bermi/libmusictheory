# 0134 — Fixed-Realization Phrase Audit Engines

## Status

- Completed: 2026-04-12
- Updated: 2026-04-12

## Goal

Implement phrase-level audit passes for already-chosen keyboard and fret realizations by composing the existing local realization and transition assessment engines across an explicit event stream.

## Scope

1. Audit fixed fret phrases from explicit realized event sequences.
2. Audit fixed keyboard phrases from explicit realized event sequences.
3. Emit phrase issue lists that point to:
   - event-local blockers
   - transition-local blockers
   - repeated warning clusters
   - recovery-deficit runs
4. Summarize the passage without changing the music.

## Important Boundary

This slice is audit only.

It does:
- compose local realization and transition assessors across a whole phrase
- identify phrase-local patterns that single-event checks miss
- return explainable issue rows and summaries

It does not:
- introduce committed phrase memory
- bias future next-step ranking
- treat UI pins or hover state as phrase memory
- repair or rewrite the music

Those concerns belong to later slices.

## Files

- `/Users/bermi/code/libmusictheory/src/playability/phrase.zig`
- `/Users/bermi/code/libmusictheory/src/playability/fret_assessment.zig`
- `/Users/bermi/code/libmusictheory/src/playability/keyboard_assessment.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md`
- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to say:
- "Every event is locally reachable, but the phrase becomes strained because the hand never recovers from the previous two shifts."
- "Nothing is individually blocked, but the repeated warning cluster shows a run of maximal stretches with no relief."

## Verification

- phrase-level keyboard and fret audit tests
- issue-list indexing tests
- repeated-warning-cluster tests
- recovery-deficit-run tests
- summary consistency tests
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Implementation History (Point-in-Time)

- `4bf6fb9` — 2026-04-12
  - Shipped fixed-realization keyboard and fret phrase audit passes on top of the `0133` phrase vocabulary.
  - Added explicit phrase-level issue emission for event-local blockers, transition-local blockers, repeated warning clusters, recovery-deficit runs, and keyboard hand-continuity resets without rewriting the music.
  - Exposed the new phrase audit surface through the experimental C ABI with export checks and focused Zig/C tests.
  - Completion gates:
    - `/Users/bermi/code/libmusictheory/./verify.sh`
    - `/Users/bermi/code/libmusictheory/./zigw build test`
