# 0101 — Counterpoint Path Weaver

> Dependencies: 0100
> Follow-up: none

Status: In Progress

## Summary

Extend the live MIDI counterpoint scene from one follow-up hop to short ranked multi-step paths, so the focused next move can be evaluated by where it naturally leads over the next few local continuations.

## Why

`0100` answered a useful follow-up question: after the currently focused move, what tends to fit next?

The next composing question is slightly larger: which of those continuations actually opens a convincing short path? A compact path view makes the gallery feel less like a flat list of suggestions and more like a small counterpoint navigator.

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the path-weaver host, runtime hooks, styles, and Playwright wiring.
- gallery validation must verify that:
  - the path view renders from the focused candidate
  - hover and pin update the path root
  - context and profile changes keep paths populated
  - mini instrument mode propagates into the path terminal previews

### Recursive Path Building

Use the existing library-owned next-step ranker recursively:

- treat the focused next move as the first committed step
- rank follow-up continuations from that derived state
- follow each leading branch a few steps deep using the same ranker
- keep JS limited to history orchestration and rendering

### Path Weaver View

Add a dedicated gallery card that shows:

- the focused source move
- several short ranked continuation paths
- step-by-step note labels, cadence/tension context, and reasons
- a terminal clock preview plus a terminal mini instrument preview per path

## Exit Criteria

- live MIDI scene includes a path-weaver view driven by the focused candidate
- multi-step paths are built from recursive library ranking, not a new JS-only theory policy
- hover, pin, clear-pin, context changes, and profile changes keep the path view in sync
- path terminal previews honor the global mini instrument setting
- gallery validation proves the new behavior
- `./verify.sh` passes

## Verification Commands

- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `./verify.sh`
