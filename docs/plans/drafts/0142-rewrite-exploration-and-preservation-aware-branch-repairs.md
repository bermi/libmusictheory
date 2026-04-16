# 0142 — Rewrite Exploration And Preservation-Aware Branch Repairs

## Status

- Draft: 2026-04-16

## Goal

Extend the repair-policy surface from single phrase repairs to branch-aware rewrite exploration so callers can ask for minimal, explainable alternatives across a short continuation window.

## Scope

1. Reuse the existing repair-policy boundary:
   - realization-only
   - register-adjusted
   - texture-reduced
2. Evaluate rewrite candidates over branch windows rather than isolated local events.
3. Return ranked branch repairs with explicit preservation metadata:
   - events touched
   - notes changed
   - first relieved bottleneck
   - new dominant strain family, if any
4. Do not silently mix preservation classes in one ranked list.

## Files

- `/Users/bermi/code/libmusictheory/src/playability/phrase.zig`
- `/Users/bermi/code/libmusictheory/src/playability/ranking.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/playability_ranking_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md`
- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to say:
- "This repair keeps the same sounding notes but changes the physical realization across the branch."
- "This second repair changes the voicing register, and that is why the bottleneck disappears at step three."

## Verification

- policy-boundary tests proving preservation classes stay separate
- ranked branch-repair tests with explicit bottleneck relief metadata
- `/Users/bermi/code/libmusictheory/./zigw build test`
- `/Users/bermi/code/libmusictheory/./verify.sh`
