# 0122 — Barry Harris Evaluation Gate And Master Closeout

> Dependencies: contrapunk-theory-integration, 0117, 0121

Status: Completed

## Summary

Make an explicit yes/no decision on Barry Harris support, document the reasoning, and close the Contrapunk integration master plan only after the accepted slices are fully verified.

## Scope

- evaluate Barry Harris against the ordered-scale semantics added in `0116` and `0117`
- decide whether Barry Harris belongs in:
  - `ScaleType`
  - `ModeType`
  - an experimental ordered-scale-only API
  - or a documented deferral
- if rejected or deferred, document the exact reason in research/docs
- if accepted, add a narrowly explainable parity API rather than overloading generic mode identification
- close `/Users/bermi/code/libmusictheory/docs/plans/completed/contrapunk-theory-integration.md` only after all accepted slices are complete and verified

## Explainability Check

An LLM should be able to say either `This belongs in the library because the parity rule is an explicit pedagogical claim` or `This is deferred because it would blur the semantics of the current mode API.`

## Exit Criteria

- Barry Harris has a documented resolution
- the master Contrapunk plan is moved to `completed` with implementation history
- `/Users/bermi/code/libmusictheory/./verify.sh` passes on the final tree

## Resolution

- Barry Harris support is accepted as an **experimental ordered-scale-only** surface.
- Barry Harris does **not** extend `ScaleType` or `ModeType`.
- The shipped public helpers expose only explainable ordered facts:
  - pattern count and names
  - degree counts
  - rooted pitch-class sets
  - parity classification for notes that belong to the selected Barry Harris pattern

## Verification Commands

- `/Users/bermi/code/libmusictheory/./zigw build test`
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Implementation Notes

- Added Barry Harris major and minor sixth-diminished ordered-scale patterns to `/Users/bermi/code/libmusictheory/src/ordered_scale.zig`.
- Exported the experimental ordered-scale discovery and parity ABI through `/Users/bermi/code/libmusictheory/src/c_api.zig` and `/Users/bermi/code/libmusictheory/include/libmusictheory.h`.
- Added focused Zig and C-ABI tests in `/Users/bermi/code/libmusictheory/src/tests/barry_harris_test.zig`, `/Users/bermi/code/libmusictheory/src/tests/property_test.zig`, and `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`.
- Documented the explicit Barry Harris placement decision in `/Users/bermi/code/libmusictheory/docs/research/algorithms/scale-mode-key.md`.

## Implementation History (Point-in-Time)

- `40e1664` (2026-04-06):
  - Shipped behavior:
    - exposed Barry Harris major/minor sixth-diminished as experimental ordered-scale patterns without polluting `ScaleType` or `ModeType`
    - added `lmt_ordered_scale_pattern_count`, `lmt_ordered_scale_pattern_name`, `lmt_ordered_scale_degree_count`, `lmt_ordered_scale_pitch_class_set`, and `lmt_barry_harris_parity`
    - added parity property coverage and fixed the shared C-string slot capacity so long ordered-scale names survive the public ABI intact
  - Verification:
    - `/Users/bermi/code/libmusictheory/./zigw build test`
    - `/Users/bermi/code/libmusictheory/./verify.sh`
