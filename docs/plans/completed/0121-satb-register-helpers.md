# 0121 — SATB Register Helpers

> Dependencies: contrapunk-theory-integration, 0120, 0020
> Follow-up: 0122

Status: Completed

## Summary

Add choir-specific SATB range helpers as optional experimental tools, without turning them into global correctness gates for the rest of the library.

## Scope

- create `/Users/bermi/code/libmusictheory/src/choir.zig`
- model standard SATB range membership facts
- add optional register-check helpers over voiced states
- keep the feature explicitly choir-scoped in the docs and header comments
- update `/Users/bermi/code/libmusictheory/verify.sh` before implementation lands

## Explainability Check

An LLM should be able to say: `That note is outside the conventional alto range used in four-part chorale writing.`

## Exit Criteria

- range membership reflects standard SATB textbook bounds
- helpers are marked experimental and choir-specific
- no unrelated validator depends on them implicitly
- `./verify.sh` passes

## Verification Commands

- `./zigw build test`
- `./verify.sh`

## Implementation Notes

- Added `/Users/bermi/code/libmusictheory/src/choir.zig` as an explicitly choir-scoped helper layer for standard SATB range facts.
- Exposed experimental C ABI helpers for SATB voice metadata, per-range queries, and four-part register checks without promoting choir assumptions into global correctness logic.
- Kept the state checker honest: `lmt_check_satb_registers` only applies the conventional bass/tenor/alto/soprano mapping when a `VoicedState` contains exactly four voices ordered low-to-high.

## Implementation History (Point-in-Time)

- `d3bee17` (2026-04-06):
  - Shipped behavior: added textbook SATB range helpers and a four-part register checker through the experimental C ABI; documented and classified the feature as choir-specific rather than a library-wide validity rule.
  - Verification: `./zigw build test`, `./verify.sh`
