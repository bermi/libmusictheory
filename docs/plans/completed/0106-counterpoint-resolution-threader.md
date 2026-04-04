# 0106 — Counterpoint Resolution Threader

> Dependencies: 0105, 0101, 0099
> Follow-up: none

Status: Completed

## Summary

Extend the live MIDI counterpoint scene with a `Resolution Threader` that projects the current obligation ledger through the strongest short continuation paths, so composers can see not only what the present state is asking for, but when those duties actually resolve, stay open, or worsen if the line keeps moving.

## Why

`0105` made the current moment's obligations readable, but it still leaves a practical gap:

- a focused move may support an obligation without resolving it
- several short paths can diverge sharply in whether they actually cash out the obligation
- the composer still has to mentally combine the ledger with the path views

This slice should bridge that gap with one compact answer: if we keep following the strongest local continuations after the focused move, which duties settle quickly, which stay open, and which turn into trouble?

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the resolution-threader host, styles, runtime wiring, and Playwright coverage.
- gallery validation must verify that:
  - the threader renders multiple obligation rows for a populated live MIDI state
  - each visible row includes the focused move verdict plus at least one projected short-path thread
  - hover, pin, clear-pin, context, profile, preview-mode, and mini-mode changes keep the threader synchronized with the active focused move

### Thread Model

Reuse existing derived data:

- obligation-ledger entries from `0105`
- short continuation paths from `0101`
- focused or pinned next move from `0099`

Do not introduce a second JS-only ranking engine. The threader may summarize and regroup the existing continuation paths, but it must not invent alternate futures outside the library-owned ranked field.

### Gallery View

Add a dedicated `Resolution Threader` card that shows:

- the current duty label
- the focused move's immediate verdict
- a small set of projected path threads showing whether that duty:
  - resolves now
  - resolves or is supported on the next step(s)
  - stays open
  - aggravates along a branch

## Exit Criteria

- live MIDI scene includes a populated resolution-threader view driven by the focused move, the current obligation ledger, and the short continuation paths
- the threader stays synchronized with hover, pin, clear-pin, context, profile, preview-mode, and mini-mode changes
- gallery validation proves that the threader renders populated rows and projected path outcomes
- `./verify.sh` passes

## Verification Commands

- `./zigw build wasm-gallery`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `./verify.sh`

## Implementation History (Point-in-Time)

- Pending final implementation hash/date; filled in immediately after the implementation commit so the completed plan points at the exact shipped change.
