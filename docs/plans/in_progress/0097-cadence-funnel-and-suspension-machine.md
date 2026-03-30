# 0097 — Cadence Funnel And Suspension Machine

> Dependencies: 0096
> Follow-up: none

Status: In progress

## Summary

Extend the live counterpoint gallery with two phrase-aware visuals that turn local next-step ranking into temporal expectation:

- `Cadence Funnel`: show the strongest cadential destinations implied by the current voiced history and profile
- `Suspension Machine`: show whether the current texture is preparing, holding, or resolving a contrapuntal dissonance, and what obligations remain

## Why

`0095` and `0096` made local motion readable: next moves, pressure fields, and contrapuntal risk are now visible. The next missing piece is phrase direction.

Composers need more than “what is smooth next.” They also need:

- where this texture is trying to arrive
- whether the current dissonance is an intentional suspension state or just unstable clutter
- which next moves reinforce, delay, or derail a cadence

These visuals should build intuition without collapsing into a giant theory dashboard.

## Scope

### Cadence Funnel

Render a compact destination view driven by the current `VoicedState`, temporal memory, and selected counterpoint profile.

The funnel should summarize:

- strongest cadential pull from the current state
- at least several destination classes, such as stable continuation, pre-dominant, dominant arrival, authentic arrival, half arrival, and deceptive pull
- how each ranked next-step candidate reinforces or weakens those outcomes
- local reasons near the branch, not only in text lists

The funnel stays local and phrase-aware:

- the current state remains explicit
- only near-term destination pressure is shown
- it must stay synchronized with the existing ranked next-step cards, horizon, braid, weather map, and risk radar

### Suspension Machine

Render a small state machine for contrapuntal dissonance handling across recent states.

The machine should expose:

- preparation
- held dissonance / suspension
- expected resolution direction
- unresolved warning states
- profile-specific tolerance differences

The machine must look back through temporal memory rather than classifying only the current chord in isolation.

### Gallery Integration

Expose both visuals in the live counterpoint scene and keep them synchronized with:

- live MIDI updates
- counterpoint profile changes
- snapshot recall
- global mini instrument mode (`off | piano | fret`)
- current SVG / bitmap preview-mode toggle

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain explicit checks for the cadence-funnel and suspension-machine gallery hosts, runtime wiring, styles, and validation coverage
- gallery Playwright must assert that:
  - the cadence funnel renders at least one current-state anchor plus multiple destination branches
  - the funnel changes under profile and context changes
  - the suspension machine renders a concrete state label and at least one obligation or warning when a suspension-like motion is active
  - both visuals remain coherent under SVG and bitmap preview modes and snapshot recall

## Exit Criteria

- the live counterpoint gallery scene renders a `Cadence Funnel`
- the live counterpoint gallery scene renders a `Suspension Machine`
- both are driven by library-owned counterpoint state and temporal memory, not JS-only heuristics
- gallery validation proves they respond coherently to live MIDI, profile changes, and snapshot recall
- `./verify.sh` passes
