# 0103 — Counterpoint Profile Orchard

> Dependencies: 0102
> Follow-up: none

Status: In progress

## Summary

Extend the live MIDI counterpoint scene with a profile-contrast view that shows how the same focused or pinned move blooms differently under each counterpoint rule profile, so composers can compare style-dependent next steps without losing the current musical moment.

## Why

The live scene already shows one ranked future under the currently selected profile. That is useful for committing to one stylistic lens, but it hides an important musical question: what changes if the same move is heard through a different rule world?

A profile orchard makes that contrast explicit. Instead of choosing a style blindly and only then seeing the outcome, the gallery can show species, tonal chorale, modal polyphony, jazz close-leading, and free contemporary continuations side by side.

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the profile-orchard host, styles, runtime wiring, and Playwright coverage.
- gallery validation must verify that:
  - the orchard renders from the focused or pinned move
  - all declared profiles get populated cards
  - the currently selected profile is visually highlighted
  - profile changes update the highlighted card and keep the orchard populated
  - piano/fret mini modes render terminal mini previews in the orchard

### Profile Contrast Runtime

Reuse the existing library-owned counterpoint engine; do not introduce a separate JS-only ranking policy.

For each declared profile:

- reuse the focused move as the shared root
- ask the library for the next-step ranking from that committed state
- summarize at least:
  - top immediate continuation
  - strongest cadence destination / arrival tendency
  - representative warning load
  - small terminal preview using the active mini instrument mode

### Gallery View

Add a dedicated gallery card that shows:

- one card per counterpoint profile
- active-profile highlighting
- next-move and cadence summaries close together
- terminal clock preview and mini instrument preview per profile
- compact reasons and warnings so differences are legible, not decorative

## Exit Criteria

- live MIDI scene includes a profile-orchard view driven by the focused candidate
- the orchard reuses the library-owned ranking and cadence helpers for each profile
- the selected profile is highlighted, but all profiles remain visible for comparison
- hover, pin, clear-pin, context changes, profile changes, and mini instrument changes keep the orchard synchronized
- gallery validation proves the behavior
- `./verify.sh` passes
