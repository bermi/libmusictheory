# 0072 — Shell-Form Fragment Links

## Summary

Make locally reconstructed fragment HTML honor the same shell URL contract as full page rewrites. Search results and key-slider cards currently emit raw `/p/...`, `/keyboard/...`, and `/eadgbe-frets/...` hrefs, which is inconsistent with the SPA’s canonical `index.html?route=...` model and breaks copy/new-tab correctness for fragment-generated links.

## Goals

- Rewrite SPA-generated fragment page-route links through the shell entry.
- Preserve non-page fragment links unchanged.
- Tag rewritten fragment links with `data-lmt-shell-route`.
- Verify fragment-link behavior in Playwright.

## Scope

- Add a shared helper for fragment anchor attributes.
- Apply it to keyboard search results, fret search results, and key-slider card entries.
- Extend the SPA validator to assert shell-form hrefs inside those fragments.
- Add `./verify.sh` guardrails for the new fragment-link behavior.

## Non-Goals

- No change to page-body rewrite behavior; that already uses shell-form links.
- No change to route recovery or canonical handling.
- No new server behavior.

## Verification-First Guardrails

- `./verify.sh` must assert that fragment-rendering code exposes explicit shell-link handling.
- `./verify.sh` must assert that the SPA Playwright validator checks shell-form hrefs inside reconstructed search and key-slider fragments.

## Exit Criteria

- Search result links for page routes use `index.html?route=...`.
- Key-slider card links for page routes use `index.html?route=...`.
- Rewritten fragment links include `data-lmt-shell-route`.
- `node scripts/validate_harmonious_spa_playwright.mjs` passes.
- `./verify.sh` passes.

## Completion Status

- Completed and verified:
  - locally reconstructed keyboard search fragments now emit shell-form page-route anchors instead of raw `/keyboard/...`, `/p/...`, or `/eadgbe-frets/...` hrefs
  - locally reconstructed fret search fragments now emit shell-form page-route anchors
  - locally reconstructed key-slider card anchors now emit shell-form page-route anchors
  - rewritten fragment anchors now carry `data-lmt-shell-route`, matching the full-page rewrite contract
  - SPA Playwright validation now explicitly fails if search or key-slider fragments leak raw page-route hrefs

## Implementation History (Point-in-Time)

- Commit: `PENDING`
- Date: `2026-03-19`
- Shipped behavior:
  - added shared shell-link attribute generation for locally rendered fragment HTML in the Harmonious SPA
  - applied shell-form routing to keyboard search, fret search, and key-slider fragment anchors
  - extended the SPA Playwright validator to assert `data-lmt-shell-route` plus shell-form hrefs for generated fragment anchors
  - tightened `./verify.sh` so fragment-link shell routing is now enforced as a first-class SPA guardrail
- Verification commands:
  - `node scripts/validate_harmonious_spa_playwright.mjs`
  - `./verify.sh`
