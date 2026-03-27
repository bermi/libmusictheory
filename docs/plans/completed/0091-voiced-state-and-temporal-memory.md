# 0091 — Voiced State And Temporal Memory

> Dependencies: 0010, 0011, 0090
> Follow-up: 0092, 0093

Status: Completed

## Summary

Introduce a real time-aware counterpoint state object that preserves voice identity, recent history, tonal context, metric position, and cadence state as reusable library primitives.

## Why

Current library analyses were mostly snapshot-oriented. Counterpoint and serious voice-leading require a model where meaning depends on what happened just before.

## Scope

- define `VoicedState` for the current vertical state
- define `VoicedEvent` / `VoicedHistoryWindow` for recent temporal memory
- include:
  - voice ids
  - per-voice MIDI note / spelling / register
  - active vs released/sustained note state where relevant
  - tonic / mode / key
  - metric position abstraction
  - cadence-state abstraction
- define cadence-state enums sufficient for future ranking, not a fully exhaustive cadence engine yet
- expose an experimental C ABI surface for caller-owned buffers

## Design Constraints

- no heap allocation in core state derivation
- state must be representable from arbitrary MIDI note arrays plus context
- voice identity assignment must be deterministic
- history window size should support at least the last 1-3 states

## Exit Criteria

- `VoicedState` exists in core Zig
- temporal memory exists and is testable
- current-state + recent-history reconstruction is deterministic for the same input sequence
- experimental ABI/docs are explicit about status and buffer ownership
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./zigw build test`

## Implementation History (Point-in-Time)

- `fc8998b` — 2026-03-27
- Shipped behavior:
  - added deterministic `VoicedState` and caller-owned `VoicedHistoryWindow` primitives plus cadence-state inference in `/Users/bermi/code/libmusictheory/src/counterpoint.zig`
  - exported experimental ABI helpers and size/manifest functions in `/Users/bermi/code/libmusictheory/src/c_api.zig`, `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, and `/Users/bermi/code/libmusictheory/build.zig`
  - added state/history verification in `/Users/bermi/code/libmusictheory/src/tests/counterpoint_test.zig`, `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`, and `/Users/bermi/code/libmusictheory/verify.sh`
- Completion gates used:
  - `./verify.sh`
  - `./zigw build test`
