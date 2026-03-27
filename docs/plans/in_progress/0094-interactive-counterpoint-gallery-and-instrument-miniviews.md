# 0094 — Interactive Counterpoint Gallery And Instrument Miniviews

> Dependencies: 0077, 0087, 0093
> Follow-up: none

Status: In Progress

## Summary

Expose the counterpoint/voice-leading system in the standalone gallery with an above-the-fold interactive scene and optional linked instrument mini visualizations on every relevant gallery scene.

## Scope

### Live Counterpoint Scene

Add a new gallery surface that shows:

- current voiced state
- recent temporal context
- ranked next moves with reasons
- linked harmonic/counterpoint views
- MIDI-driven updates where applicable
- progressive disclosure from local to global:
  - default view: current state + 3-5 best next moves
  - expanded view: wider motion field / graph neighborhood only on demand

### Optional Mini Instrument Visualization

All gallery scenes that present a selected note set or voiced state should support an optional compact linked instrument pane.

Global setting:

- `mini instrument: piano | fret`

Requirements:

- mini views render the selected notes from the same underlying state as the main graph
- current-state and next-step suggestions both render through the chosen mini instrument
- fret notes use the same pitch-class color coding as clocks, keyboard, and other set graphics
- the mini view must be optional, not forced on scenes where it would add clutter

### Verification Surfaces

- gallery Playwright must verify the new live scene exists and updates coherently
- gallery Playwright must verify both mini instrument modes
- docs/QA capture should expose at least one representative counterpoint image path if any new public image method is added

## Anti-Slop UX Constraints

- no giant unreadable dashboard
- always show “current” before “next”
- reasons must remain visible near suggestions
- mini instrument panes must clarify, not decorate
- the same state should be legible from graph + instrument simultaneously
- default to the relevant local slice instead of the total graph
- if a graph expansion is shown, keep the active path and current node visually dominant

## Exit Criteria

- gallery exposes a counterpoint/voice-leading scene backed by library state/ranking
- gallery scenes support an optional `piano` or `fret` mini-view setting where relevant
- fret mini views and piano mini views share the same pitch-class palette logic
- verification proves both modes render and stay in sync with the main graph state
- `./verify.sh` passes
