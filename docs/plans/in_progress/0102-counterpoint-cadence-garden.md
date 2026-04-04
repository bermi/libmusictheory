# 0102 — Counterpoint Cadence Garden

> Dependencies: 0101
> Follow-up: none

Status: In progress

## Summary

Extend the live MIDI counterpoint scene with a cadence-oriented branch view that groups the short recursively ranked paths by their reachable arrival type, so a composer can see not just local continuations but what kinds of destinations those branches actually tend toward.

## Why

`0101` made the live scene capable of showing a few short ranked paths from the focused move. That is useful, but it still reads like several neighboring path strips.

A cadence-oriented garden answers a more compositional question: given this present state and the currently focused next move, which arrival regions are really open over the next couple of steps, and which paths get there cleanly under the selected rule profile?

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the cadence-garden host, styles, runtime wiring, and Playwright coverage.
- gallery validation must verify that:
  - the cadence garden renders from the focused candidate
  - cadence groups stay populated when hover, pin, clear-pin, context, and profile change
  - at least one group shows a representative terminal clock and mini instrument preview
  - SVG and bitmap preview modes both keep the garden populated

### Cadence Garden Grouping

Use the existing recursive path expansion from `0101` and group the resulting terminal branches by cadence outcome:

- treat the focused or pinned next move as the root
- reuse the recursively ranked short paths already built from the library-owned next-step engine
- cluster terminal paths by cadence label / cadence effect
- summarize each cadence group with:
  - representative best path
  - branch count
  - tension trend
  - warnings / cleanliness signal

### Gallery View

Add a dedicated gallery card that shows:

- cadence groups as reachable destination beds
- representative short paths per group
- terminal clock preview and terminal mini instrument preview per representative path
- profile-aware reasons and warnings close to each destination group

## Exit Criteria

- live MIDI scene includes a cadence-garden view driven by the focused candidate
- cadence groups are derived from recursive library ranking, not a separate JS-only theory policy
- hover, pin, clear-pin, context changes, profile changes, and preview-mode changes keep the view synchronized
- representative terminal previews honor the global mini instrument mode
- gallery validation proves the behavior
- `./verify.sh` passes
