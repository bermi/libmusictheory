# 0078 — Release Packaging And Smoke Matrix

> Dependencies: 0074, 0075, 0076, 0077

Status: Draft

## Summary

Close the standalone-release branch with a clean package/release contract: install artifacts, build targets, versioning notes, smoke matrix, and a release checklist.

## Goals

- Define the release artifact set.
- Define the smoke matrix for native and browser surfaces.
- Add release notes/changelog scaffolding.
- Make the standalone release path reproducible.

## Scope

- release target audit
- install artifact audit
- smoke matrix
- versioning/changelog scaffolding
- release checklist

## Non-Goals

- No package registry publication automation
- No production hosting/deployment plan

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must enforce the presence of the release checklist and smoke-matrix documentation once this plan begins

## Recovered Planning Notes

This draft restores the planning detail that existed before the reverted implementation pass. The implementation itself remains intentionally undone, so this plan stays in `drafts/` until work resumes.

### Planned Release Artifacts

- `/Users/bermi/code/libmusictheory/VERSION`
- `/Users/bermi/code/libmusictheory/CHANGELOG.md`
- `/Users/bermi/code/libmusictheory/RELEASE_CHECKLIST.md`
- `/Users/bermi/code/libmusictheory/docs/release/artifacts.md`
- `/Users/bermi/code/libmusictheory/docs/release/smoke-matrix.md`
- `/Users/bermi/code/libmusictheory/docs/release/versioning.md`
- `/Users/bermi/code/libmusictheory/scripts/release_smoke.sh`

### Planned Smoke Matrix

The standalone release path should be verified independently from the full Harmonious regression infrastructure.

Required release smoke surfaces:

- native library build:
  - `zig build`
- installed C ABI smoke:
  - `zig build c-smoke`
- standalone docs browser bundle:
  - `zig build wasm-docs`
  - export check via `scripts/check_wasm_exports.mjs --profile full_demo`
  - Playwright smoke via `scripts/validate_wasm_docs_playwright.mjs`
- standalone gallery browser bundle:
  - `zig build wasm-gallery`
  - export check via `scripts/check_wasm_exports.mjs --profile gallery`
  - Playwright smoke via `scripts/validate_wasm_gallery_playwright.mjs`

### Planned Verify Integration

When this plan is implemented:

- `./verify.sh` should report `RELEASE_SURFACE_SMOKE=yes|no`
- the release smoke path should not depend on `/Users/bermi/code/libmusictheory/tmp/harmoniousapp.net`
- the extended Harmonious regression lanes should remain additive and separately reported

### Implementation Slices

#### Slice A — Release Scaffold

- add `VERSION`
- add `CHANGELOG.md`
- add `RELEASE_CHECKLIST.md`
- add `docs/release/artifacts.md`
- add `docs/release/smoke-matrix.md`
- add `docs/release/versioning.md`

#### Slice B — Explicit Smoke Script

- add `scripts/release_smoke.sh`
- make it validate the native install path plus `wasm-docs` and `wasm-gallery`
- make it print a compact release-smoke summary

#### Slice C — Verify Gate

- update `./verify.sh` to:
  - require the release artifacts
  - require the release docs structure
  - validate `VERSION` format
  - run `scripts/release_smoke.sh`
  - report `RELEASE_SURFACE_SMOKE=yes|no`

#### Slice D — README Wiring

- update `/Users/bermi/code/libmusictheory/README.md` to point to the release docs and checklist
- keep the standalone story separate from the internal Harmonious regression story

## Exit Criteria

- release artifact list is documented
- smoke matrix covers native static/shared plus browser docs/gallery
- release checklist exists
- versioning/changelog scaffolding exists
- `./verify.sh` passes
