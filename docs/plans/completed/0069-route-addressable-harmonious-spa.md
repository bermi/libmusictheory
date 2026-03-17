# 0069 — Route-Addressable Harmonious SPA

## Summary

Make the single-entry Harmonious SPA addressable from a plain static host without relying on server rewrite support. The shell must accept an explicit route parameter at boot, preserve one-page navigation, and make representative deep links openable in a new tab through the SPA entry rather than requiring direct `/p/...` or `/keyboard/...` server paths.

## Goals

- Add a boot-time route override for the SPA shell.
- Support representative deep links via `index.html?route=...`.
- Preserve existing in-page fake navigation and history behavior.
- Add Playwright coverage for direct shell boot into representative route families.
- Keep the shell as a single entry point.

## Scope

- Parse and honor a `route` query parameter in the SPA shell.
- Normalize internal route hrefs so opening in a new tab can still enter through the shell when desired.
- Extend Playwright validation to boot directly into representative `/p/...`, `/keyboard/...`, `/eadgbe-frets/...`, and key-slider-backed routes via the shell entry.
- Add `./verify.sh` guardrails for the new direct-entry behavior.

## Non-Goals

- No server rewrite rules.
- No multi-entry static export for every route family.
- No change to compat image generation.

## Verification-First Guardrails

- `./verify.sh` must assert the SPA runtime exposes query-route boot support.
- `./verify.sh` must assert the SPA Playwright validator exercises representative direct-entry shell boots.

## Exit Criteria

- `index.html?route=/p/fb/C-Major` boots directly into that route through the SPA shell.
- `index.html?route=/keyboard/C_3,E_3,G_3` boots directly into the interactive keyboard route.
- `index.html?route=/eadgbe-frets/-1,12,12,9,10,-1` boots directly into the interactive fret route.
- Representative key page direct-entry boots keep the slider synchronized.
- `./verify.sh` passes.

## Completion Status

- Completed and verified:
  - SPA shell boot now honors `index.html?route=...` for representative `/p/...`, `/keyboard/...`, `/eadgbe-frets/...`, and key-page routes
  - internal page-family links are rewritten through the shell entry and tagged with `data-lmt-shell-route`
  - keyboard and fretboard page-specific on-load code now receives the correct route semantics during direct shell boots
  - SPA Playwright validation now covers direct shell entry for page, keyboard, fretboard, and key-slider-backed routes
  - `./verify.sh` enforces the direct-entry guardrails

## Implementation History (Point-in-Time)

- Commit: `e56805f`
- Date: `2026-03-17`
- Shipped behavior:
  - added direct route boot support through `index.html?route=...` in the Harmonious SPA shell
  - rewrote internal page-family links back through the shell entry so new-tab and copied-link flows no longer depend on direct static `/p/...`, `/keyboard/...`, or `/eadgbe-frets/...` routes
  - patched direct keyboard and fretboard shell boots so original page-specific client code sees the intended route during initialization
  - expanded SPA Playwright coverage to enforce direct-entry boots for representative page, keyboard, fretboard, and key-slider routes
- Verification commands:
  - `node scripts/validate_harmonious_spa_playwright.mjs`
  - `./verify.sh`
