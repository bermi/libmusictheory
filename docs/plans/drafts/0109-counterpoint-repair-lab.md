# 0109 — Counterpoint Repair Lab

> Dependencies: 0108, 0105, 0099
> Follow-up: none

Status: Draft

## Summary

Extend the live MIDI counterpoint scene with a `Repair Lab` panel that proposes minimal, per-voice repairs for the currently focused move. Each repair should keep the focused move recognizable while showing the smallest note-level adjustment that would better satisfy the current duties.

## Why

The counterpoint scene can already explain:

- what the strongest next moves are
- which duties are open in the current state
- which persistent voices are carrying those duties

What it still does not do is answer the practical composer question:

- if I like this move, what is the smallest change that would make it behave better?

This slice turns the counterpoint scene from diagnosis into repair guidance.

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the `Repair Lab` host, styles, runtime wiring, and Playwright coverage.
- gallery validation must verify that:
  - a populated live MIDI state renders at least two repair candidates
  - each repair candidate is tied to a specific voice id
  - the panel stays synchronized with hover, pin, clear-pin, context, profile, mini-mode, and snapshot changes
  - at least one repair reduces or avoids a currently visible duty problem in the seeded MIDI test state

### Repair Generation

Repairs must reuse existing scene state:

- persistent voice ids from `VoicedState`
- current duties from `0108`
- focused candidate state from the ranked next-step field
- current counterpoint history and evaluation path already used in the gallery

Do not create a second ranking engine.
Repairs should be generated as focused-move variants that alter one persistent voice at a time, then be evaluated through the same motion/profile path already used elsewhere in the gallery.

### Gallery View

Add a dedicated `Repair Lab` card that shows:

- source focused move
- one repair row per suggested local fix
- target voice / target note
- short explanation of why the repair helps
- compact status summary of how the repair changes warnings, cadence pull, and duty pressure

## Exit Criteria

- live MIDI scene includes a populated `Repair Lab` view driven from persistent voice duties and focused-move variants
- repairs stay tied to specific voice ids and concrete target notes
- gallery validation proves the panel renders multiple repairs and stays synchronized with live interaction state
- `./verify.sh` passes
