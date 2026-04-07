# 0126 - Keyboard Fingering And Hand-Span Models

Status: In Progress

## Summary

Implement a first explainable playability engine for the keyboard side of the library.

The first wave should model what the cited piano papers support best:
- one-hand and two-hand span limits
- local finger-transition plausibility
- thumb crossing and black-key exposure warnings
- vertical chord reachability
- recent-motion fluency warnings

The first implementation should prefer structured assessment over a huge end-to-end search engine.

## Why

The piano papers show that local transitions, recent history, and vertical span matter more than isolated note labels. They also show that exact global optimization rapidly becomes expensive in dense polyphony. For `libmusictheory`, the right first move is an explainable assessment layer, not an all-or-nothing merged HMM solver.

## Deliverables

1. Keyboard realization assessment for:
- one-hand melodic transitions
- one-hand chord spans
- simple two-hand partition assessment when hands are explicit
2. Structured warnings such as:
- exceeds comfort span
- exceeds hard span
- thumb on black key under stretch
- awkward thumb crossing
- repeated weak adjacent-finger sequence
- fluency degradation from recent motion
3. Experimental fingering suggestions where the local context is sufficiently constrained

## Recommended file work

Create:
- `/Users/bermi/code/libmusictheory/src/playability/keyboard_assessment.zig`
- `/Users/bermi/code/libmusictheory/src/tests/keyboard_playability_test.zig`

Modify:
- `/Users/bermi/code/libmusictheory/src/keyboard.zig`
- `/Users/bermi/code/libmusictheory/src/counterpoint.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/keyboard_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/keyboard-interaction.md`

## Experimental ABI direction

Assessment helpers:
- `lmt_assess_keyboard_realization`
- `lmt_assess_keyboard_transition`
- `lmt_rank_keyboard_fingerings`

Optional later helper, not required in first wave:
- `lmt_partition_voiced_state_for_keyboard`

## Critical review guardrail

Do not collapse this slice into opaque HMM state ids exposed over the ABI. If HMM-like or DP logic is used internally, the public result still needs named reasons and plain structs.

## Explainability check

An LLM should be able to say:
- "This right-hand chord exceeds the configured comfortable span, even though the notes are theoretically correct."
- "This fingering asks the thumb to move onto a black key while the hand is already maximally stretched, so it is flagged as strained."

## Scope

L

## Verification gates

- explicit span fact tests
- transition fluency tests using recent-history windows
- no hidden behavior changes to existing keyboard APIs
- `./verify.sh`
