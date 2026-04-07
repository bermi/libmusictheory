# 0124 - Instrument Topology And Biomechanical State

Status: Draft

## Summary

Create the foundation needed by every later playability algorithm:
- explicit hand profiles
- explicit current play state
- recent-load memory
- topology helpers that map notes to physical coordinates on keyboard and stringed instruments

This slice should not attempt to solve fingering globally. It should make later assessment possible without hidden assumptions.

## Why

The cited papers converge on one point: fingering quality is contextual and stateful. Without explicit hand state and instrument topology, later ranking and overlay work will either become JS heuristics again or bury assumptions inside a black-box search.

## Deliverables

1. A new internal `playability` module family in `/Users/bermi/code/libmusictheory/src/playability/`
2. Shared playability enums, reason scaffolding, and profile scaffolding
3. Stringed-instrument topology primitives:
- tuning vector
- redundant pitch location lookup
- position window descriptors
4. Keyboard geometry primitives:
- key coordinates
- hand-anchor positions
- left/right hand span descriptors
5. Stateful structs:
- current hand anchor
- active finger assignments when known
- recent shift/load memory for the last few events

## Recommended file work

Create:
- `/Users/bermi/code/libmusictheory/src/playability/types.zig`
- `/Users/bermi/code/libmusictheory/src/playability/fret_topology.zig`
- `/Users/bermi/code/libmusictheory/src/playability/keyboard_topology.zig`
- `/Users/bermi/code/libmusictheory/src/tests/playability_types_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/playability_topology_test.zig`

Modify:
- `/Users/bermi/code/libmusictheory/src/root.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`

## Experimental ABI direction

Shared structs:
- `lmt_hand_profile`
- `lmt_temporal_load_state`
- `lmt_playability_reason`
- `lmt_playability_warning`

Instrument-specific state structs:
- `lmt_fret_play_state`
- `lmt_keyboard_play_state`

Reflection helpers:
- `lmt_playability_reason_count`
- `lmt_playability_reason_name`
- `lmt_playability_warning_count`
- `lmt_playability_warning_name`

## Explainability check

An LLM should be able to say:
- "This note is reachable in three places on the fretboard in this tuning, but from the current hand position only one lies inside the current comfort window."
- "The right hand is already centered near E4-G4, so this next chord expands the span rather than merely shifting position."

## Scope

L

## Verification gates

- topology mapping tests for arbitrary tunings and keyboard coordinates
- C ABI layout tests for new structs
- no-allocation audit for core assessment helpers
- `./verify.sh`
