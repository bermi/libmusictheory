# 0093 — Next Step Ranker And Reason Codes

> Dependencies: 0091, 0092
> Follow-up: 0094

Status: Completed

## Summary

Rank plausible next moves from a `VoicedState`, using recent history and a selected rule profile, while returning explicit reason codes and score components that the gallery can expose honestly.

## Scope

- define `NextStepRanker` over `VoicedState + TemporalMemory + CounterpointRuleProfile`
- rank candidate next moves using:
  - minimal total motion
  - avoidance of parallels and crossings
  - tendency-tone resolution
  - spacing preservation
  - tension increase/decrease
  - cadence effect
  - common-tone retention
- return explicit reasons, not just a scalar score
- support both strict and permissive policies depending on profile
- expose an experimental ABI suitable for WASM/gallery use

## Reason Model

Each ranked suggestion supports at least:

- total score
- dominant contributing reasons
- warnings / penalties
- cadence direction label
- tension delta label

## Exit Criteria

- ranked next moves are produced by the library rather than gallery policy code
- each suggestion carries explicit reasons and warnings
- temporal memory affects ranking in tests
- the gallery can consume the ABI without re-implementing ranking policy
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./zigw build test`

## Implementation History (Point-in-Time)

- `5b0a7ef` — 2026-03-27
- Shipped behavior:
  - added profile-aware next-step ranking, reason/warning tables, and cadence/tension labeling in `/Users/bermi/code/libmusictheory/src/counterpoint.zig`
  - exported ranked suggestion ABI surfaces and manifest helpers in `/Users/bermi/code/libmusictheory/src/c_api.zig`, `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, `/Users/bermi/code/libmusictheory/build.zig`, and `/Users/bermi/code/libmusictheory/scripts/check_wasm_exports.mjs`
  - proved temporal-memory-sensitive ranking and reason consistency in `/Users/bermi/code/libmusictheory/src/tests/counterpoint_test.zig`, `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`, and `/Users/bermi/code/libmusictheory/verify.sh`
- Completion gates used:
  - `./verify.sh`
  - `./zigw build test`
