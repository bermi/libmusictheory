# 0078 — Release Packaging And Smoke Matrix

> Dependencies: 0074, 0075, 0076, 0077

Status: In progress

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
