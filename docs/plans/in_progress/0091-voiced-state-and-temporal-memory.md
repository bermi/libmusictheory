# 0091 — Voiced State And Temporal Memory

> Dependencies: 0010, 0011, 0090
> Follow-up: 0092, 0093

Status: Draft

## Summary

Introduce a real time-aware counterpoint state object that preserves voice identity, recent history, tonal context, metric position, and cadence state as reusable library primitives.

## Why

Current library analyses are mostly snapshot-oriented. Counterpoint and serious voice-leading require a model where meaning depends on what happened just before.

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

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain checks for the new experimental ABI exposure and docs classification
- tests must cover deterministic voice assignment and history roll-forward behavior

## Exit Criteria

- `VoicedState` exists in core Zig
- temporal memory exists and is testable
- current-state + recent-history reconstruction is deterministic for the same input sequence
- experimental ABI/docs are explicit about status and buffer ownership
- `./verify.sh` passes
