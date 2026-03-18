# 0071 — Static-Host Ready Harmonious SPA

## Summary

Make the Harmonious SPA bundle self-sufficient on plain static hosts by shipping explicit `404.html` fallback behavior, a built-in favicon, and verified direct raw-route fallback into the shell entry. The shell must remain canonical on `index.html?route=...`, but a static host serving `404.html` for unknown `/p/...`, `/keyboard/...`, or `/eadgbe-frets/...` requests must still recover into the SPA without manual rewrites.

## Goals

- Ship a bundle-local `404.html` fallback for static hosts.
- Recover raw route requests into `index.html?route=...` automatically.
- Add a built-in favicon so the SPA bundle does not emit avoidable `favicon.ico` noise.
- Document the static-host deployment model clearly.
- Verify fallback behavior in Playwright.

## Scope

- Add a dedicated SPA fallback page or redirect behavior for unknown static routes.
- Install the fallback artifact into `zig-out/wasm-harmonious-spa/`.
- Add favicon wiring to the shell and fallback page.
- Replace the SPA validator's basic file server with a custom static-host-like server that serves `404.html` for unknown routes.
- Extend Playwright validation to boot representative raw `/p/...`, `/keyboard/...`, and `/eadgbe-frets/...` requests through the fallback path.
- Add `./verify.sh` guardrails for the new hosting behavior.

## Non-Goals

- No server-side rewrites.
- No change to the shell's canonical URL model; the shell remains `index.html?route=...`.
- No multi-page export for every route.

## Verification-First Guardrails

- `./verify.sh` must assert that the SPA bundle installs `404.html` and favicon handling.
- `./verify.sh` must assert that the SPA Playwright validator exercises raw-route fallback through the bundle's static-host behavior.

## Exit Criteria

- `zig-out/wasm-harmonious-spa/404.html` exists.
- Raw requests for representative `/p/...`, `/keyboard/...`, and `/eadgbe-frets/...` routes recover into `index.html?route=...` through the fallback path.
- The shell no longer emits a `favicon.ico` 404 during validation.
- `node scripts/validate_harmonious_spa_playwright.mjs` passes.
- `./verify.sh` passes.

## Completion Status

- Completed and verified:
  - the SPA bundle now installs `404.html` alongside `index.html`, `harmonious-spa.js`, and `libmusictheory.wasm`
  - raw `/p/...`, `/keyboard/...`, and `/eadgbe-frets/...` requests are recovered through the fallback page into canonical shell-form `index.html?route=...` URLs
  - the SPA validator now runs against a static-host-like Node server that serves `404.html` on unknown routes instead of relying on `python3 -m http.server`
  - the shell keeps its canonical link synchronized to the visible shell-form URL during route loads and history mutations
  - both the shell and fallback page now ship a built-in favicon so the SPA bundle does not need a separate `favicon.ico`
  - `./verify.sh` now enforces installation of `404.html` plus end-to-end fallback and canonical metadata coverage

## Implementation History (Point-in-Time)

- Commit: `PENDING`
- Date: `2026-03-18`
- Shipped behavior:
  - installed `404.html` into the harmonious SPA bundle and added a route-family fallback page that redirects raw static-host deep links back into `index.html?route=...`
  - synchronized shell canonical metadata to the current visible shell-form URL
  - replaced the SPA Playwright validator's simple file server with a static-host-like Node server so raw deep-link fallback is actually exercised
  - extended SPA validation to assert fallback traversal, shell canonical correctness, and absence of `favicon.ico` network requests
- Verification commands:
  - `node scripts/validate_harmonious_spa_playwright.mjs`
  - `./verify.sh`
