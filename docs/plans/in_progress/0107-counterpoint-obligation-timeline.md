# 0107 — Counterpoint Obligation Timeline

> Dependencies: 0105, 0106, 0091
> Follow-up: none

Status: In progress

## Summary

Extend the live MIDI counterpoint scene with an `Obligation Timeline` that shows how the current duties emerged across the recent temporal-memory frames and how the currently focused move would answer those same duties now.

## Why

`0105` made the present duties explicit.
`0106` projected those duties through the strongest short continuations.

What is still missing is the bridge backward in time:

- which of the current duties have been with us for several moves?
- which ones appeared only recently?
- have the actual recent moves been resolving those duties or feeding them?
- how does the focused move compare with what we actually did in the last few steps?

A timeline view answers those questions in one place and turns the temporal-memory model into something composers can read at a glance.

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the obligation-timeline host, styles, runtime wiring, and Playwright coverage.
- gallery validation must verify that:
  - the timeline renders multiple current-duty rows for a populated live MIDI state
  - the timeline includes at least two recent historical columns plus the focused column
  - the focused column stays synchronized with hover, pin, clear-pin, context, profile, preview-mode, mini-mode, and snapshot changes
  - at least one historical column is populated from an actual recent move match

### Timeline Model

Reuse the existing counterpoint engine and gallery derivations:

- temporal-memory frames from `VoicedState`
- obligation-ledger entries from `0105`
- focused move from `0099`
- ranked next-step field from `0093`

Do not introduce a second ranking engine.
The historical columns should be reconstructed from recent prefixes of the existing history window and matched against the actual next move that followed each prefix.

### Gallery View

Add a dedicated `Obligation Timeline` card that shows:

- current-duty rows as the stable y-axis
- several recent historical columns showing how actual moves treated those same duties
- one focused column showing how the active focused or pinned move would treat them now
- clear status cells for:
  - resolves
  - supports
  - delays
  - aggravates
  - inactive / not yet active

## Exit Criteria

- live MIDI scene includes a populated obligation-timeline view driven by the current duty set, recent temporal memory, and the focused move
- historical columns are derived from actual recent moves rather than a new JS-only future generator
- the focused column stays synchronized with hover, pin, clear-pin, context, profile, preview-mode, mini-mode, and snapshot changes
- gallery validation proves the timeline renders multiple rows, historical columns, and a synchronized focused column
- `./verify.sh` passes
