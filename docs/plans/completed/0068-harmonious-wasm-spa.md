# 0068 — Harmonious WASM SPA Shell

## Summary

Build a single-entry SPA demo that reuses the original harmoniousapp.net content and client interactions while replacing compatibility SVG file loads with `libmusictheory` WASM generation. The shell must keep the original one-page navigation model, reconstruct the missing dynamic server endpoints locally, and prove via Playwright that compatibility images are sourced from WASM rather than fetched from disk.

## Goals

- Add a new browser bundle target, `zig build wasm-harmonious-spa`.
- Serve the original harmonious content through a single HTML entry point.
- Reuse the original client-side navigation and interaction model where it is still sound.
- Replace compatibility SVG `<img>` usage with on-demand WASM generation for all compatibility kinds.
- Reconstruct the missing `/random/`, `/search-keyboard/...`, and `/search-eadgbe/...` endpoints from a generated local corpus index.
- Verify the SPA through Playwright, including navigation, interactive keyboard/fret flows, and the absence of network requests for compatibility SVG files.

## Scope

- Add a SPA bundle under `zig-out/wasm-harmonious-spa/` with a single shell page `index.html`.
- Add a generated manifest/index derived from `tmp/harmoniousapp.net/`.
- Install the original static assets needed by the shell: CSS, JS client files, SVG/UI assets, fonts, and the HTML corpus under a non-entry data directory.
- Patch request handling in the SPA runtime so the original client code can keep calling `$.get(...)` for page loads and dynamic panes.
- Rewrite `auto:*` links and compatibility SVG image references in fetched HTML so they work in the SPA.
- Add conditional `./verify.sh` guardrails and a dedicated Playwright validator for the SPA.

## Non-Goals

- No deep-link server rewrite support for arbitrary static servers. The SPA owns navigation after the shell loads.
- No claim that the missing original server-side result panes were recovered byte-for-byte; they will be reconstructed from the local page corpus and existing library APIs.
- No changes to the exact compatibility generators themselves unless verification finds a real rendering bug.

## Design Constraints

- The SPA must not load compatibility SVG reference files as its primary image source.
- Compatibility image replacement must be deterministic and keyed by the compatibility API surface already exposed from WASM.
- The request bridge must normalize original harmonious absolute URLs, relative paths, and SPA history paths into the local bundle layout.
- The request bridge must return full HTML documents for page routes and fragment HTML for the reconstructed search/random endpoints.
- The SPA must preserve original inline page footer scripts so page-specific `onLoad` hooks continue to run.

## Verification-First Guardrails

- `./verify.sh` must conditionally check the new build target, output bundle, and Playwright script before the SPA is considered shipped.
- The Playwright validator must fail if any network request hits compatibility SVG directories such as `scale/`, `grand-chord/`, `oc/`, `optc/`, `eadgbe/`, `majmin/`, or the other compatibility output roots.
- The Playwright validator must cover:
  - shell boot into the home page,
  - normal content navigation into `/p/...`,
  - `auto:*` link resolution,
  - interactive keyboard page load with populated results,
  - interactive fretboard page load with populated results,
  - random-page navigation,
  - wasm-backed replacement of compatibility images.

## Exit Criteria

- `zig build wasm-harmonious-spa` succeeds when `tmp/harmoniousapp.net/` is present.
- Opening `zig-out/wasm-harmonious-spa/index.html` loads the harmonious home page content through the SPA shell.
- Original content navigation works without full page reloads for the major page families: home, `/p/...`, `/keyboard/...`, `/eadgbe-frets/...`.
- Keyboard and fret search panes are locally reconstructed and visibly populated.
- Compatibility images displayed in the SPA are generated through the WASM compatibility APIs rather than fetched as static SVG files.
- Playwright passes for the SPA validation flow.
- `./verify.sh` passes.

## Completion Status

- Completed and verified:
  - single-entry SPA shell bundle under `zig-out/wasm-harmonious-spa/`
  - local corpus/asset install and manifest generation
  - wasm-backed compat image replacement for page content and reconstructed search fragments
  - local `auto:*`, `/random/`, `/search-keyboard/...`, `/search-eadgbe/...`, and `/search-key-tri/...` request bridge reconstruction
  - local `/key-tri/...` background reconstruction for the interactive key slider
  - deterministic re-execution of page inline scripts after AJAX body swaps
  - explicit route-synchronized key-page slider header and initial fragment stabilization inside the SPA bridge
  - Playwright-verified navigation across home, `/p/...`, `/keyboard/...`, `/eadgbe-frets/...`, key-slider routes, and random routes

## Implementation History (Point-in-Time)

- Commit: `e497e98`
- Date: `2026-03-17`
- Shipped behavior:
  - completed the harmonious SPA request bridge so the missing key-slider fragment/background endpoints are reconstructed locally
  - stabilized AJAX page-route behavior by stripping inline page scripts from bridged HTML payloads and executing them exactly once in the SPA runtime
  - added route-based key-page slider synchronization so navigation into key pages no longer leaves stale `C Major` header/fragment state behind
  - verified the SPA via Playwright without network fetches for compatibility SVG roots or `/key-tri/` assets
- Verification commands:
  - `node scripts/validate_harmonious_spa_playwright.mjs`
  - `./verify.sh`
