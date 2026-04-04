# 0105 — Counterpoint Obligation Ledger

> Dependencies: 0104, 0097, 0099
> Follow-up: none

Status: Completed

## Summary

Extend the live MIDI counterpoint scene with an obligation-ledger view that makes the current state’s duties explicit and shows whether the focused next move resolves, delays, or aggravates them.

## Why

The gallery now exposes many rich local views, but the composer still has to mentally combine them to answer a practical question:

- what is this moment asking me to do next?
- and is the focused candidate actually helping?

The cadence funnel, suspension machine, inspector, and consensus atlas already expose the raw ingredients. A ledger should gather those into one readable place so the scene teaches obligations, not just options.

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the obligation-ledger host, styles, runtime wiring, and Playwright coverage.
- gallery validation must verify that:
  - the ledger renders multiple populated entries for a live voiced state
  - at least one entry is marked critical or cautionary
  - the focused or pinned candidate produces visible support/delay/aggravate outcomes
  - hover, pin, clear-pin, context, profile, preview-mode, and mini-mode changes keep the ledger synchronized with the active focused move

### Ledger Model

Reuse existing library-owned data:

- suspension-machine summary
- cadence destinations
- current motion analysis
- focused next-step reasons and warnings
- ranked next-step field

Do not introduce a second JS-only ranking engine. The ledger may summarize and regroup existing library outputs, but it must not replace them.

### Gallery View

Add a dedicated `Obligation Ledger` card that shows:

- a small set of current obligations and opportunities
- a readable explanation of why each entry exists
- the focused candidate’s verdict on each entry:
  - resolves
  - supports
  - delays
  - aggravates
  - neutral
- compact support counts where the ledger is derived from the ranked field

## Exit Criteria

- live MIDI scene includes an obligation-ledger view driven by the current voiced state and focused candidate
- the ledger reflects suspension/cadence/motion pressure plus top-field aggregation
- at least one critical/cautionary entry appears when the scene is populated
- the focused or pinned candidate visibly changes ledger outcomes
- gallery validation proves synchronization across hover, pin, clear-pin, context, profile, and preview/mini-mode changes
- `./verify.sh` passes


## Verification Commands

- `./zigw build wasm-gallery`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `./verify.sh`

## Implementation History (Point-in-Time)

- `25d282c` — 2026-04-04 — added the live MIDI obligation-ledger card, summarized current-state duties from suspension/cadence/motion pressure plus the ranked field, and tightened gallery validation so hover, pin, context, profile, preview, and mini-mode changes keep the ledger synchronized with the focused move.
- Completion gates: `./zigw build wasm-gallery`, `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, `./verify.sh`
