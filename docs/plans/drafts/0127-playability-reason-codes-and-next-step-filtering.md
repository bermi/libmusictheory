# 0127 - Playability Reason Codes And Next-Step Filtering

Status: Draft

## Summary

Connect the new playability engine to existing theory and counterpoint ranking surfaces without contaminating theory-first semantics.

This slice is where `libmusictheory` becomes able to say not just "this next step fits" but also "this next step fits and remains playable from the current instrument state."

## Why

This is the bridge from assessment to product value. Practice tools and LLM generators do not just need fingering annotations after the fact; they need candidate filtering and ranking that avoids impossible moves before presenting them.

## Deliverables

1. Shared reason and warning taxonomy for playability
2. Policy modes such as:
- `balanced`
- `minimax_bottleneck`
- `cumulative_strain`
3. Opt-in next-step filtering and reranking helpers for existing candidate sets
4. Integration points with current counterpoint and context-suggestion flows

## Recommended file work

Create:
- `/Users/bermi/code/libmusictheory/src/playability/ranking.zig`
- `/Users/bermi/code/libmusictheory/src/tests/playability_ranking_test.zig`

Modify:
- `/Users/bermi/code/libmusictheory/src/counterpoint.zig`
- `/Users/bermi/code/libmusictheory/src/keyboard.zig`
- `/Users/bermi/code/libmusictheory/src/guitar.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/counterpoint_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`

## Experimental ABI direction

Reason and policy helpers:
- `lmt_playability_policy_count`
- `lmt_playability_policy_name`
- `lmt_playability_reason_count`
- `lmt_playability_reason_name`

Filtering/ranking helpers:
- `lmt_filter_next_steps_by_playability`
- `lmt_rank_realized_next_steps_by_playability`

## API semantics guardrail

Do not silently change existing `lmt_rank_next_steps` semantics. Existing theory-first surfaces should remain theory-first until a caller explicitly requests playability-aware evaluation.

## Explainability check

An LLM should be able to say:
- "These three continuations are harmonically valid, but two are filtered out because they exceed the configured hand span from the current state."
- "This candidate is still shown, but it is deprioritized because it creates the hardest move in the phrase so far."

## Scope

M

## Verification gates

- opt-in only behavior changes
- stable ordering for ties under each named policy
- gallery and C ABI smoke coverage once implemented
- `./verify.sh`
