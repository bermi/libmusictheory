# 0112 — Public Docs, Quickstarts, And Example Boundary

> Dependencies: 0111, 0087, 0076
> Follow-up: 0113, 0114

Status: Completed

## Summary

Turn the standalone docs, README, reviewer guide, and gallery onboarding into a stable-release-quality path that a new reviewer can follow without repo archaeology or hidden tribal knowledge.

## Why

The library can now do much more than the original RC documentation suggests. The remaining work is not adding more features; it is making the intended entry paths obvious, bounded, and honest for stable users.

## Scope

### Quickstarts

- provide one clear native build / verify path
- provide one clear standalone docs path
- provide one clear standalone gallery path
- ensure the documented commands use `./zigw` where that is the supported path on current macOS hosts

### Example Boundary

- make stable examples prefer stable APIs
- move experimental examples or clearly label them as experimental when they are still valuable for review
- ensure README and reviewer docs explain which examples are contract demonstrations versus exploratory gallery features

### Reviewer Experience

- tighten `RELEASE_CHECKLIST.md`
- tighten `docs/release/reviewer-guide.md`
- make the review flow map directly to the shipped bundles and capture artifacts

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must check that quickstart commands, bundle names, and reviewer docs stay synchronized
- `./verify.sh` must fail if stable example sections silently depend on experimental helpers

## Exit Criteria

- a reviewer can get from clone to verify to docs to gallery with one obvious path
- stable and experimental examples are clearly separated
- release docs read like a stable handoff instead of RC scaffolding
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./zigw build verify`

## Implementation History (Point-in-Time)

- `d08ff3b1e1a81f204ecd4be9c0a1b089267d1460` — 2026-04-05
  - tightened `/Users/bermi/code/libmusictheory/README.md`, `/Users/bermi/code/libmusictheory/RELEASE_CHECKLIST.md`, `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`, `/Users/bermi/code/libmusictheory/docs/release/artifacts.md`, and `/Users/bermi/code/libmusictheory/docs/release/smoke-matrix.md` around one clone-to-review path
  - made `wasm-docs` the explicit stable browser contract demonstration and `wasm-gallery` the explicit supported example surface across public release docs
  - added `0112` guardrails to `/Users/bermi/code/libmusictheory/verify.sh` so quickstart commands, reviewer flow, and docs/gallery boundary claims stay synchronized
  - verification gates:
    - `./verify.sh`
    - `./zigw build verify`
