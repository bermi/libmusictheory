# 0100 — Counterpoint Continuation Ladder

> Dependencies: 0099
> Follow-up: none

Status: Completed

## Summary

Extend the live MIDI counterpoint scene with a second-step continuation view that answers a follow-up composing question: if we actually take the currently focused next move, what are the strongest moves after that?

## Why

`0095` through `0099` made the gallery much better at answering “what fits next?”, but the scene still stops one move too early.

Composers often need to know whether a good-looking next move actually opens a convincing continuation. The gallery should therefore expose a short, ranked continuation ladder for the currently focused or pinned candidate without moving counterpoint policy back into JavaScript.

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the continuation ladder host, runtime hooks, styles, and Playwright validation wiring.
- gallery validation must verify that:
  - the continuation ladder renders once a focused candidate exists
  - hover and pin update the continuation source
  - clearing the pin restores default focus and continuation context
  - continuation previews stay coherent with the global mini instrument mode

### Focused Continuation Context

Use the existing library-owned next-step ranker recursively:

- append the currently focused next move to the effective voiced history window
- rebuild the voiced history through the existing ABI
- ask the library ranker for the next best continuations from that derived state
- keep JavaScript limited to orchestration, rendering, and focus state

### Continuation Ladder View

Add a dedicated gallery card that shows:

- the focused source move as the continuation root
- the top follow-up moves as a short ranked ladder
- score, cadence, tension, reasons, and warnings for each follow-up
- a compact clock preview for each follow-up

### Mini Instrument Carry-Through

When the global mini instrument mode is enabled:

- continuation cards should render matching piano or fret previews
- `off` mode should degrade to explanatory text instead of empty boxes

## Exit Criteria

- live MIDI scene includes a continuation ladder driven by the focused candidate
- continuation ranking is produced by the library through the existing ranker, not a new JS-only policy
- hover, pin, clear-pin, context changes, and profile changes all keep the continuation ladder in sync
- continuation cards honor the global mini instrument setting
- gallery validation proves the new behavior
- `./verify.sh` passes

## Verification Commands

- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `./verify.sh`

## Implementation History (Point-in-Time)

- `af05bb47224ffa4e9bf4a654beae6ad3e8c558a3` — 2026-03-31
  - shipped a live `Continuation Ladder` card in the MIDI counterpoint scene that ranks the best second-step continuations from the currently focused or pinned next move
  - reused the existing library-owned voiced-history builder and `lmt_rank_next_steps` flow recursively instead of adding a new JavaScript-only counterpoint policy
  - rendered compact clock previews and mini piano/fret previews for the continuation cards, honoring the global mini instrument mode
  - tightened Playwright and `./verify.sh` guardrails so hover, pin, clear-pin, context changes, profile changes, and mini instrument changes all keep the continuation view in sync
  - verification gates: `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, `./verify.sh`
