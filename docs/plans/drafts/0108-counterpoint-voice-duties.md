# 0108 — Counterpoint Voice Duties

> Dependencies: 0105, 0107, 0091
> Follow-up: none

Status: Draft

## Summary

Extend the live MIDI counterpoint scene with a `Voice Duties` panel that turns the current global obligation state into per-voice responsibilities. Each row should identify the persistent voice, show its recent motion, name the pressure it is carrying now, and grade how the currently focused move treats that exact voice.

## Why

The current counterpoint scene already tells us:

- what the global duties are (`0105`)
- how recent actual moves treated those duties (`0107`)
- how the focused move compares to nearby alternatives (`0099`, `0100`, `0106`)

What it does not yet show clearly is:

- which exact voice is carrying which duty
- which voice wants to hold, step, recover a leap, or resolve a suspension
- whether the focused move solves the right voice-level problem or only improves the state globally

This slice makes the counterpoint engine easier to read as music rather than only as ranked state transitions.

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the `Voice Duties` host, styles, runtime wiring, and Playwright coverage.
- gallery validation must verify that:
  - the panel renders multiple persistent voices for a populated live MIDI state
  - each row includes current-note and focused-note evidence
  - the panel stays synchronized with hover, pin, clear-pin, context, profile, mini-mode, and snapshot changes
  - at least one row carries a non-neutral duty label for the seeded MIDI test state

### Duty Derivation

Reuse the existing counterpoint and gallery state:

- persistent voice identities from `VoicedState`
- recent history from the temporal-memory window
- suspension tracking from `0107`
- focused candidate state from the current next-step selection

Do not create a second voice-assignment engine.
Voice rows must be matched by persistent voice id between the current state, recent memory, and the focused candidate state.

### Gallery View

Add a dedicated `Voice Duties` card that shows, per current voice:

- voice color / identity
- recent motion from the previous temporal-memory frame
- current note
- current duty label and target direction
- focused move result for that same voice
- compact status grading:
  - resolves
  - supports
  - delays
  - aggravates

## Exit Criteria

- live MIDI scene includes a populated `Voice Duties` view driven from persistent voices and the focused move
- at least one real duty source is visible for the seeded validation state
- the focused outcome stays synchronized with hover, pin, clear-pin, context, profile, mini-mode, and snapshot changes
- gallery validation proves the panel exposes multiple voices, non-empty duty labels, and synchronized focus state
- `./verify.sh` passes
