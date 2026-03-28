# 0096 — Counterpoint Weather Map And Risk Radar

> Dependencies: 0095
> Follow-up: none

Status: Draft

## Summary

Add two linked counterpoint intuition surfaces to the standalone gallery:

- `Counterpoint Weather Map`: a local pressure field that shows which next moves are attracted, neutral, or unstable from the current voiced state
- `Parallel-Risk Radar`: a compact diagnostics view that makes interval-risk, crossing, overlap, and spacing failures visible before the user commits to a move

## Why

`0095` made next-step options legible as local geometry and voice history. The next gap is intuition. Composers still have to read chips and warnings to understand why one continuation feels smooth and another feels brittle.

This slice should make the system feel less like an inspector and more like a compositional instrument:

- show where the voices want to go
- show which risks are accumulating
- keep the explanation local to the current state
- avoid giant unreadable theory dashboards

## Scope

### Counterpoint Weather Map

Render a compact local field for the active profile that encodes:

- attraction toward stable continuations
- tension from unresolved tendency tones
- spacing pressure
- leap recovery pressure
- cadence pull
- penalties from cluster pressure or weak retention

The map stays local:

- current voiced state stays explicit
- only top candidate neighborhoods are shown by default
- wider field expansion is optional, not the default surface

### Parallel-Risk Radar

Render a compact per-state diagnostics panel that summarizes:

- parallel fifth risk
- parallel octave risk
- hidden perfect interval risk
- crossing risk
- overlap risk
- spacing/range strain
- common-tone retention strength

The radar must work for:

- current voiced state
- hovered next-step candidate
- selected profile

### Gallery Integration

Expose both visuals in the live counterpoint scene and keep them synchronized with:

- live MIDI updates
- profile changes
- snapshot recall
- existing mini instrument mode (`off | piano | fret`)

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain explicit checks for the new weather-map and risk-radar hosts and their gallery validation wiring
- gallery Playwright must assert that:
  - the weather map renders current-state anchoring plus at least one scored neighborhood cell
  - the risk radar renders at least four populated diagnostic axes
  - both visuals change under live MIDI/profile changes
  - both visuals stay coherent under SVG and bitmap preview modes

## Exit Criteria

- the live counterpoint gallery scene renders a `Counterpoint Weather Map`
- the live counterpoint gallery scene renders a `Parallel-Risk Radar`
- both are driven by library-owned counterpoint state/profile data
- gallery validation proves they respond coherently to live MIDI and profile changes
- `./verify.sh` passes
