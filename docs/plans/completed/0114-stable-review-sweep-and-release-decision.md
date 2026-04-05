# 0114 — Stable Review Sweep And Release Decision

> Dependencies: 0113, 0086
> Follow-up: 0115

Status: Completed

## Summary

Run the final stable-review pass against the post-`0087` tree, capture the remaining deltas explicitly, and decide whether the repo should promote to `0.1.0` or cut another release candidate.

## Why

`0086` should not be a silent version bump. It is the explicit decision point where we say whether the current standalone surface is good enough for a stable contract.

## Scope

### Review Pass

- execute the documented reviewer path on the current tree
- inspect release artifacts, gallery captures, and public docs with the stable contract in mind
- classify any remaining issues as:
  - must-fix before stable
  - acceptable for stable
  - defer to post-`0.1.0`

### Decision Record

- record whether the branch is ready for `0.1.0`
- if not, record the minimum delta for `0.1.0-rc.2`
- ensure the decision is reflected consistently in `VERSION`, changelog expectations, and release docs

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must fail if the repo presents itself as stable without a stable decision having been reflected in the release metadata
- `./verify.sh` must fail if reviewer docs and version metadata disagree on whether the cut is stable or RC

## Exit Criteria

- a documented go / no-go decision exists for `0.1.0`
- the remaining delta to the chosen release target is explicit
- `./verify.sh` passes


## Verification Commands

- `./verify.sh`
- `./scripts/release_smoke.sh`

## Implementation History (Point-in-Time)

- `8c4ce3d` (2026-04-05) — added `/Users/bermi/code/libmusictheory/docs/release/stable-review-decision.md`, recorded an explicit go decision for stable `0.1.0`, updated the release checklist to include the decision record, and added `0114` guardrails so a completed review cannot leave the decision pending or disagree with the current RC-vs-stable metadata lane. Completion gates: `./verify.sh`, `./scripts/release_smoke.sh`.
