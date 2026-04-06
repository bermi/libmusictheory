# 0117 — Degree-Aware Note Primitives

> Dependencies: contrapunk-theory-integration, 0116, 0008, 0020
> Follow-up: 0118, 0122

Status: In progress

## Summary

Add the first note-level ordered-scale APIs: scale-degree lookup, diatonic transposition, and explicit nearest-scale-note helpers with no hidden tie policy.

## Scope

- extend `/Users/bermi/code/libmusictheory/src/ordered_scale.zig` with:
  - degree lookup for MIDI notes in a tonic/mode context
  - diatonic transposition by signed degree offset
  - nearest lower/higher in-scale note search
  - explicit snap tie-policy handling
- add experimental C ABI structs/enums/functions for those operations
- add property tests proving inversion and in-scale guarantees
- update `/Users/bermi/code/libmusictheory/verify.sh` before behavior lands

## Explainability Check

An LLM should be able to say: `E4 is degree 3 in C Ionian, so moving up two scale degrees lands on G4.`

## Exit Criteria

- `lmt_scale_degree` reports 1-based degree numbers and `0` for chromatic notes
- `lmt_transpose_diatonic` round-trips for in-scale notes under `+N` then `-N`
- nearest-scale helpers expose both sides and never hide a tie policy
- `./verify.sh` passes
