# 0141 — Phrase-Biased Branch Ranking And Hard-Filter Helpers

## Status

- Draft: 2026-04-16

## Goal

Use committed phrase memory plus the fixed-horizon branch model to classify and rerank candidate continuations while keeping hard blockers and soft strain bias separate.

## Scope

1. Add helpers that classify branches into:
   - blocked
   - playable but recovery-deficit
   - playable and recovery-neutral
   - playable and recovery-improving
2. Add explicit hard-filter helpers that remove blocked branches only when the caller asks for it.
3. Add explicit reranking helpers that keep blocked branches visible when the caller asks for diagnostics rather than filtering.
4. Add reason summaries that surface which committed-memory facts changed the branch outcome.

## Files

- `/Users/bermi/code/libmusictheory/src/playability/ranking.zig`
- `/Users/bermi/code/libmusictheory/src/playability/phrase.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_ranking_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to say:
- "This branch was filtered only because you asked for hard blockers to be removed."
- "This option remains visible, but it ranks lower because it compounds the same shift strain already present in committed memory."

## Verification

- hard-filter versus rerank tests over the same candidate set
- committed-memory bias tests showing different results with and without prior accepted history
- `/Users/bermi/code/libmusictheory/./zigw build test`
- `/Users/bermi/code/libmusictheory/./verify.sh`
