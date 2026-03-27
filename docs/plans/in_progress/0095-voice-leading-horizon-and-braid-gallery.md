# 0095 — Voice-Leading Horizon And Braid Gallery

> Dependencies: 0094
> Follow-up: none

Status: In Progress

## Summary

Extend the live counterpoint gallery with two linked visualizations that turn ranked next-step data into something composers can read at a glance:

- `Voice-Leading Horizon`: current voiced state plus the best next moves in a local motion field
- `Voice Braid`: recent voice history plus ghosted continuation strands for the strongest candidates

## Why

`0094` made the counterpoint engine available in the gallery, but the current scene still reads mostly as text, chips, and independent diagrams. The next useful step is a real counterpoint picture:

- current state first
- next options visibly related to the current state
- motion legible through time, not only as score/reason text

## Scope

- add a `Voice-Leading Horizon` visualization to the live MIDI scene
- add a `Voice Braid` visualization to the live MIDI scene
- derive both from the existing counterpoint ABI, not a second JS-only ranking policy
- keep them as local-slice views rather than giant totalizing graphs
- preserve existing mini instrument views and next-step cards

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain explicit checks for the new horizon and braid hosts and their gallery validation wiring
- gallery Playwright must assert that:
  - the horizon renders a current node plus candidate nodes
  - the braid renders history columns plus candidate ghost columns
  - both stay in sync with live MIDI/profile changes

## Exit Criteria

- the live MIDI gallery scene renders a `Voice-Leading Horizon`
- the live MIDI gallery scene renders a `Voice Braid`
- both are fed by library-owned voiced history and ranked next-step data
- gallery validation proves they update coherently under live MIDI and profile changes
- `./verify.sh` passes
