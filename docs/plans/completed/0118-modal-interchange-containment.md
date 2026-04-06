# 0118 — Modal Interchange Containment

> Dependencies: contrapunk-theory-integration, 0116, 0117, 0020
> Follow-up: 0119

Status: Completed

## Summary

Add a narrow, explainable modal-interchange surface that reports which parallel modes contain an outside pitch class and what degree that pitch class occupies in each match.

## Scope

- create `/Users/bermi/code/libmusictheory/src/modal_interchange.zig`
- return all containing-mode matches, with no hidden ordering preference
- expose the result through an experimental C ABI struct
- cross-check facts against the Contrapunk containment logic and the expanded mode table
- update `/Users/bermi/code/libmusictheory/verify.sh` before implementation lands

## Explainability Check

An LLM should be able to say: `F# is outside C Ionian, but it belongs to C Lydian as degree #4.`

## Exit Criteria

- returned matches actually contain the queried pitch class
- degree numbers are present for each match
- there is no library-imposed borrowing priority
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./zigw build test`

## Implementation History (Point-in-Time)

- `128fa7f` (2026-04-06):
  - Shipped behavior: added `src/modal_interchange.zig`, pitch-class degree lookup for modes, and the experimental C ABI surface `lmt_find_containing_modes` with structured `(mode, degree)` matches that preserve caller order and do not impose any internal borrowing preference.
  - Verification: `./verify.sh`, `./zigw build test`
