# 0099 — Counterpoint Inspector And Candidate Pinning

> Dependencies: 0098
> Follow-up: none

Status: Completed

## Summary

Make the live counterpoint gallery easier to read by adding a single focused candidate inspector, persistent candidate pinning, and instrument-synced current/next previews.

## Why

`0095` through `0098` added multiple linked counterpoint visuals, but the live MIDI scene still depends too heavily on transient hover state and spreads the explanation of a next move across too many cards.

The next step is to make one candidate feel intentionally selected:

- hover can still preview
- click should pin
- the gallery should explain why the selected move is ranked well or poorly
- the current/next instrument previews should respect the global mini instrument choice instead of hardcoding fret output in the live scene

## Scope

### Candidate Focus Model

Add a focused-candidate model for the live MIDI scene:

- hovered candidate previews still work
- clicked candidate pins until cleared or invalidated by live-state changes
- all linked counterpoint visuals use the focused candidate first, then hover fallback, then default best candidate

### Counterpoint Inspector

Add a dedicated inspector card for the selected candidate that exposes:

- note names
- score
- cadence effect
- tension delta
- top reasons
- warnings
- compact motion summary
- plain-language profile-aware interpretation

### Instrument-Synced Compare View

Update the live scene so the current and focused-next previews:

- honor the global mini instrument setting (`off`, `piano`, `fret`)
- render side by side when a candidate is focused
- degrade to helpful text when mini view is off or no candidate exists

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the new inspector host and focused preview host in the live MIDI scene
- gallery Playwright must verify:
  - click pins a candidate
  - pin survives mouseleave
  - clearing or invalidating the pin returns to default focus behavior
  - focused inspector content updates when the focused candidate changes
  - current and next instrument previews render in both piano and fret modes

## Exit Criteria

- live MIDI scene has a dedicated counterpoint inspector
- live MIDI scene supports persistent candidate pinning
- focused candidate state drives the linked counterpoint visuals coherently
- current and next instrument previews honor the global mini instrument setting
- gallery validation proves pin/focus/preview behavior
- `./verify.sh` passes

## Verification Commands

- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `./verify.sh`

## Implementation History (Point-in-Time)

- `19e4379b2259fe64379919a02d90475a80865bd8` — 2026-03-31
  - shipped a dedicated live MIDI counterpoint inspector with pinned-candidate UX
  - made hover, pin, clear-pin, and linked visual focus state coherent across horizon, braid, weather, radar, orbifold, and constellation views
  - added a focused next mini-instrument preview and made current/next mini previews honor the global `off` / `piano` / `fret` setting
  - tightened gallery Playwright and `./verify.sh` guardrails around inspector metadata, focus state, and mini preview coverage
  - verification gates: `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, `./verify.sh`
