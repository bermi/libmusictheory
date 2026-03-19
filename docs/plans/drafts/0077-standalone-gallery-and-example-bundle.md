# 0077 — Standalone Gallery And Example Bundle

> Dependencies: 0073, 0074, 0076, 0066

Status: Draft

## Summary

Build a local-only gallery bundle that demonstrates creative uses of `libmusictheory` using only the stable public APIs.

This gallery is the outward-facing replacement for relying on Harmonious reproduction as the only visual proof that the library is useful.

## Goals

- Add a `wasm-gallery` bundle.
- Keep it single-entry and locally servable.
- Use only public standalone APIs.
- Show multiple distinct musical-discovery experiences, not just API widgets.

## Candidate Gallery Scenes

- pitch-class set explorer
- chord/color clock playground
- parametric fretboard/tuning explorer
- progression or key-neighborhood explorer
- geometry-driven harmony scene using the public rendering APIs

## Scope

- gallery HTML/JS/CSS bundle
- curated example scenes
- local serving instructions
- Playwright smoke coverage for the gallery shell and representative scenes

## Non-Goals

- No Harmonious content mirroring
- No dependency on exact-compat APIs
- No production deployment work

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must require that gallery code does not import Harmonious SPA or compat-only browser scripts
- `./verify.sh` must require a Playwright smoke path for the gallery bundle

## Exit Criteria

- `zig build wasm-gallery` exists
- gallery scenes render using public APIs only
- gallery has Playwright smoke coverage
- gallery is documented from the root README
- `./verify.sh` passes

