# 0103 — Counterpoint Profile Orchard

> Dependencies: 0102
> Follow-up: none

Status: Completed

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


## Verification Commands

- `./zigw build wasm-gallery`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `./verify.sh`

## Implementation History (Point-in-Time)

- `701f9209965451e29c54fff07feca6c034011976` — `2026-04-04`
  - shipped the live `Profile Orchard` card in the interactive gallery, contrasting the same focused or pinned move across all counterpoint rule profiles side by side
  - added per-profile continuation, cadence, warning, clock, and mini-instrument summaries so composers can compare stylistic outcomes without changing the current musical moment
  - tightened gallery and `verify.sh` guardrails so hover, pin, clear-pin, context changes, profile changes, preview-mode changes, and mini instrument changes must keep all profile cards populated and synchronized
  - verification gates used: `./zigw build wasm-gallery`, `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, `./verify.sh`
