# 0078 — Release Packaging And Smoke Matrix

> Dependencies: 0074, 0075, 0076, 0077

Status: Completed

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

## Implementation Notes

- `0078` starts by turning release closure into explicit repo artifacts:
  - `VERSION`
  - `CHANGELOG.md`
  - `RELEASE_CHECKLIST.md`
  - `docs/release/artifacts.md`
  - `docs/release/smoke-matrix.md`
  - `docs/release/versioning.md`
  - `scripts/release_smoke.sh`
- `./verify.sh` now treats the standalone release smoke path as a first-class gate instead of inferring release readiness from unrelated bundle presence.

## Exit Criteria

- release artifact list is documented
- smoke matrix covers native static/shared plus browser docs/gallery
- release checklist exists
- versioning/changelog scaffolding exists
- `./verify.sh` passes

## Completion Status

- Completed and verified:
  - added release scaffolding files in `/Users/bermi/code/libmusictheory/VERSION`, `/Users/bermi/code/libmusictheory/CHANGELOG.md`, and `/Users/bermi/code/libmusictheory/RELEASE_CHECKLIST.md`
  - added release documentation in `/Users/bermi/code/libmusictheory/docs/release/artifacts.md`, `/Users/bermi/code/libmusictheory/docs/release/smoke-matrix.md`, and `/Users/bermi/code/libmusictheory/docs/release/versioning.md`
  - added `/Users/bermi/code/libmusictheory/scripts/release_smoke.sh` as the explicit standalone release smoke path for native and browser surfaces
  - extended `/Users/bermi/code/libmusictheory/verify.sh` to enforce the release scaffolds and run the release smoke script as a first-class gate
  - updated `/Users/bermi/code/libmusictheory/README.md` to point standalone consumers at the release docs and checklist

## Implementation History (Point-in-Time)

- Commit: `4525058`
- Date: `2026-03-20`
- Shipped behavior:
  - added an explicit standalone release scaffold instead of leaving artifact selection, versioning, and smoke expectations implicit
  - added a reproducible smoke path that verifies installed native outputs plus the standalone `wasm-docs` and `wasm-gallery` browser bundles
  - made `./verify.sh` report `RELEASE_SURFACE_SMOKE=yes|no` based on that explicit release smoke path
- Verification commands:
  - `bash scripts/release_smoke.sh`
  - `./verify.sh`
