# 0137 — Gallery Phrase Blackboard And Virtual Keyboard Fallback

## Status

- Draft: 2026-04-12
- In Progress: 2026-04-13
- Completed: 2026-04-13

## Goal

Adapt the gallery host so the live MIDI scene remains usable without hardware and so committed choices can be appended into library-backed phrase memory instead of being conflated with hover or pin UI state.

## Scope

1. Detect when Web MIDI is unavailable or when no MIDI inputs are connected.
2. Add a virtual keyboard interaction path that lets users toggle notes and emulate the current-state input flow.
3. Add explicit phrase-blackboard actions in the gallery:
   - preview a candidate
   - commit a candidate
   - commit the current input state
   - clear committed phrase memory
4. Use library-backed committed phrase memory for later ranking bias.
5. Keep browser-only logic outside the library:
   - hover
   - preview pin
   - localStorage snapshots
   - device permissions
   - virtual-keyboard transient toggles before commit

## Important UX Rule

The gallery must separate these two actions clearly:

- `Pin for preview`
  - JS-only
  - no library-memory effect

- `Commit to phrase`
  - appends to caller-owned library memory
  - changes later ranking and phrase analysis

## Files

- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css`
- `/Users/bermi/code/libmusictheory/scripts/lib/wasm_gallery_playwright_common.mjs`
- `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/keyboard-interaction.md`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

A host or LLM should be able to say:
- "This move is only pinned for preview; it has not been committed into the phrase."
- "This move is now part of the committed phrase memory, so later suggestions are being judged relative to it."
- "No MIDI device is connected, so the virtual keyboard is driving the same phrase-building path."

## Verification

- no-MIDI gallery fallback tests
- virtual-keyboard toggle tests
- commit-versus-pin interaction tests
- phrase-blackboard bias visibility tests
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Verification Commands

- `/Users/bermi/code/libmusictheory/./zigw build wasm-gallery`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `/Users/bermi/code/libmusictheory/./verify.sh`

## Implementation History (Point-in-Time)

- `045ac76154f1a5174a52e05c5463acf64363c241` — 2026-04-13
  - Added a virtual-keyboard fallback to `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html`, `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`, and `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css` so the live MIDI scene remains usable when Web MIDI is unavailable or no hardware inputs are connected.
  - Added a phrase blackboard to the gallery with explicit `Pin for preview` versus `Commit to phrase` semantics, wired committed choices into caller-owned library memory, and used committed phrase memory to bias later suggestion ranking without moving preview-only browser state into the C layer.
  - Extended `/Users/bermi/code/libmusictheory/scripts/lib/wasm_gallery_playwright_common.mjs`, `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, `/Users/bermi/code/libmusictheory/docs/api.md`, `/Users/bermi/code/libmusictheory/docs/research/algorithms/keyboard-interaction.md`, and `/Users/bermi/code/libmusictheory/verify.sh` so the no-MIDI fallback, phrase-blackboard interactions, and preview-versus-commit boundary are all documented and programmatically enforced.
  - Verification gates:
    - `/Users/bermi/code/libmusictheory/./zigw build wasm-gallery`
    - `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
    - `/Users/bermi/code/libmusictheory/./verify.sh`
