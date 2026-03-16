# 0064 — WASM Docs Run-All Visibility And Resilience

## Summary

Fix the full interactive docs workflow so the `Run all sections` action is trustworthy for manual review. The current page auto-runs on load, which allows the docs smoke test to pass even if the click path regresses. The rendered SVG previews also remain too small and visually easy to miss.

## Goals

- Make the `Run all sections` click path explicitly verifiable.
- Ensure per-section failures do not silently suppress later sections such as SVG rendering.
- Make fret and staff previews visibly large enough for manual spot checks.

## Scope

- Tighten `./verify.sh` coverage through the existing docs Playwright script.
- Strengthen `scripts/validate_wasm_docs_playwright.mjs` so it clears outputs before clicking `Run all sections`.
- Improve `examples/wasm-demo/app.js` run-all error handling and success/error status reporting.
- Improve `examples/wasm-demo/styles.css` and SVG preview normalization so the rendered diagrams are visibly inspectable.

## Non-Goals

- No public C ABI changes.
- No music-theory algorithm changes.
- No compatibility/parity renderer changes.

## Exit Criteria

- `Run all sections` is validated by Playwright after clearing the page outputs.
- The docs page reports explicit success or section-scoped failure after `Run all sections`.
- Fret and staff previews render at visibly inspectable size in the docs layout.
- `./verify.sh` passes.

## Implementation History (Point-in-Time)

- `d1e040a` — 2026-03-16
  - Strengthened the docs verification path so the Playwright script clears the rendered outputs before clicking `Run all sections`, waits for the explicit success status, and checks that the clock/fret/staff previews land at visibly inspectable sizes.
  - Hardened the docs UI so `Run all sections` continues through section-local failures, writes per-section error text instead of silently aborting later sections, and reports explicit overall success or failure in the page status.
  - Rebalanced preview sizing so fret and staff SVGs are large enough for manual inspection without blowing up the docs card layout.
  - Completion gates:
    - `node scripts/validate_wasm_docs_playwright.mjs`
    - `./verify.sh`
