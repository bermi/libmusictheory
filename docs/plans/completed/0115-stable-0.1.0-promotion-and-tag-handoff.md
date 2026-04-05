# 0115 — Stable 0.1.0 Promotion And Tag Handoff

> Dependencies: 0114, 0086, 0085
> Follow-up: none

Status: Completed

## Summary

Promote the repo from `0.1.0-rc.1` to a stable `0.1.0` only if `0114` says the bar is met; otherwise cut `0.1.0-rc.2` honestly and prepare the same handoff artifacts for another reviewer pass.

## Why

The last step should be mechanical and honest: reflect the decision in metadata, verify it, and hand off the exact merge / tag sequence without editorial ambiguity.

## Scope

### Promotion Or RC Fallback

- update `VERSION`
- update `CHANGELOG.md`
- update `RELEASE_CHECKLIST.md`
- update `docs/release/reviewer-guide.md`
- update any remaining release docs that still speak in RC-only or stable-only language incorrectly

### Release Handoff

- prepare the exact tag and push sequence
- ensure the final handoff says what is stable, what remains experimental, and what internal regression lanes still exist

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must fail if `VERSION` is stable while release docs still describe an RC cut
- `./verify.sh` must fail if `VERSION` is an RC while the reviewer docs or checklist describe a stable cut

## Exit Criteria

- the repo metadata matches the chosen release target exactly
- the release/tag handoff is explicit and executable
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./scripts/release_smoke.sh`

## Implementation History (Point-in-Time)

- `0bb9721809d6411b5177067f90d7569084daefe0` — `2026-04-05 17:47:19 +0200`
  - promoted `/Users/bermi/code/libmusictheory/VERSION` from `0.1.0-rc.1` to `0.1.0`
  - rewrote `/Users/bermi/code/libmusictheory/CHANGELOG.md`, `/Users/bermi/code/libmusictheory/RELEASE_CHECKLIST.md`, `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`, and `/Users/bermi/code/libmusictheory/docs/release/versioning.md` for a stable release
  - added `/Users/bermi/code/libmusictheory/docs/release/tag-handoff.md` with the exact merge and tag sequence for `0.1.0`
  - tightened `/Users/bermi/code/libmusictheory/verify.sh` so stable metadata and handoff docs must stay internally consistent
  - verification gates: `./verify.sh`, `./scripts/release_smoke.sh`
