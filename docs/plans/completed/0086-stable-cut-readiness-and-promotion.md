# 0086 — Stable Cut Readiness And Promotion

> Dependencies: 0085, 0082
> Follow-up: 0114, 0115

Status: Completed

## Summary

Evaluate the `0.1.0-rc.1` state against the stable release bar, decide whether another RC is needed, and if not, promote the versioning/docs/checklist from RC to stable `0.1.0`.

## Remaining Work

- none

## Detailed Execution Order

1. completed `0114` — stable review sweep and release decision
2. completed `0115` — stable `0.1.0` promotion and tag handoff
3. close `0086`

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must make `0086` fail if `VERSION` is stable while `CHANGELOG.md` and release docs still describe an RC cut
- `./verify.sh` must make `0086` fail if reviewer docs still present the release as `0.1.0-rc.1` after promotion
- `./verify.sh` must make `0086` fail if a new RC is chosen while the release docs still present the cut as already stable

## Exit Criteria

- either the branch explicitly decides to keep another RC, or the metadata is promoted to stable `0.1.0`
- release docs and checklists use stable terminology consistently
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./scripts/release_smoke.sh`

## Implementation History (Point-in-Time)

- `8c4ce3d2ff0cf54e7f6999ffe1da0639c9991123` — `2026-04-05 17:20:19 +0200`
  - added `/Users/bermi/code/libmusictheory/docs/release/stable-review-decision.md`
  - recorded `Status: Go for stable 0.1.0` as the explicit decision for the promotion lane
  - tightened `/Users/bermi/code/libmusictheory/verify.sh` so the stable decision record must exist and cannot stay pending once the review slice is completed
  - verification gates: `./verify.sh`, `./scripts/release_smoke.sh`
- `0bb9721809d6411b5177067f90d7569084daefe0` — `2026-04-05 17:47:19 +0200`
  - promoted `/Users/bermi/code/libmusictheory/VERSION` from `0.1.0-rc.1` to `0.1.0`
  - rewrote `/Users/bermi/code/libmusictheory/CHANGELOG.md`, `/Users/bermi/code/libmusictheory/RELEASE_CHECKLIST.md`, `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`, and `/Users/bermi/code/libmusictheory/docs/release/versioning.md` for the stable cut
  - added `/Users/bermi/code/libmusictheory/docs/release/tag-handoff.md` and the matching stable handoff guardrails in `/Users/bermi/code/libmusictheory/verify.sh`
  - verification gates: `./verify.sh`, `./scripts/release_smoke.sh`
