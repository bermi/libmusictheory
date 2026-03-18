# 0070 — Shell-Form Live History For Interactive Routes

## Summary

Keep interactive keyboard and fretboard edits on shell-form history entries so the Harmonious SPA remains truly single-entry after live user interaction. Keyboard and fretboard page logic may continue using the original client modules, but browser-visible URLs and history entries must stay on `index.html?route=...` while back/forward behavior remains correct.

## Goals

- Keep keyboard live edits on shell-form URLs.
- Keep fretboard live edits on shell-form URLs.
- Preserve keyboard and fretboard back/forward behavior.
- Extend Playwright verification to cover interactive route edits and shell-form URL persistence.

## Scope

- Add SPA-side history normalization for interactive keyboard and fretboard edits.
- Patch keyboard and fretboard on-pop handling so shell-form browser URLs still resolve to the intended raw route state.
- Extend the SPA validator to mutate keyboard and fretboard state through the original client surface and assert shell-form URL persistence.
- Add `./verify.sh` guardrails for the new shell-history behavior.

## Non-Goals

- No rewrite of the original keyboard or fretboard interaction model.
- No change to compat image generation.
- No broader canonical URL policy beyond interactive shell-form persistence.

## Verification-First Guardrails

- `./verify.sh` must assert that the SPA runtime contains explicit shell-history handling for keyboard/fretboard interactive routes.
- `./verify.sh` must assert that the SPA Playwright validator exercises keyboard and fretboard live edits while checking the browser URL remains shell-form.

## Exit Criteria

- Live keyboard edits keep the browser URL on `/index.html?route=/keyboard/...`.
- Live fretboard edits keep the browser URL on `/index.html?route=/eadgbe-frets/...`.
- Keyboard/fretboard back and forward continue to resolve the intended interactive route state.
- `node scripts/validate_harmonious_spa_playwright.mjs` passes.
- `./verify.sh` passes.

## Completion Status

- Completed and verified:
  - SPA history writes for shell page routes now preserve shell-form browser URLs while storing absolute raw routes in `history.state` for the original client modules
  - interactive keyboard and fretboard edits keep the address bar on `index.html?route=...` instead of switching to raw `/keyboard/...` or `/eadgbe-frets/...`
  - keyboard and fretboard `popstate` handling now resolves shell-form history transitions back into the raw route semantics expected by the original clients
  - SPA Playwright validation now mutates keyboard and fretboard selections, then exercises back/forward while asserting shell-form URL persistence and interactive state restoration
  - `./verify.sh` enforces the shell-history guardrail through both code presence and browser validation

## Implementation History (Point-in-Time)

- Commit: `ecfff01`
- Date: `2026-03-18`
- Shipped behavior:
  - added shell-history normalization for interactive SPA routes so browser-visible URLs remain on `index.html?route=...` during keyboard and fretboard live edits
  - preserved raw-route semantics for the legacy client modules by storing absolute raw interactive URLs in `history.state`
  - patched keyboard and fretboard `popstate` handling to restore interactive state correctly under shell-form browser URLs
  - extended the SPA Playwright validator to mutate both interactive clients and verify shell-form URL persistence through back/forward navigation
- Verification commands:
  - `node scripts/validate_harmonious_spa_playwright.mjs`
  - `./verify.sh`
