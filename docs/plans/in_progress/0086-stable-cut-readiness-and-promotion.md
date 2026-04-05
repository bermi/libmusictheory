# 0086 — Stable Cut Readiness And Promotion

> Dependencies: 0085, 0082
> Follow-up: 0114, 0115

Status: In progress

## Summary

Evaluate the `0.1.0-rc.1` state against the stable release bar, decide whether another RC is needed, and if not, promote the versioning/docs/checklist from RC to stable `0.1.0`.

## Remaining Work

- execute the post-`0087` reviewer sweep on the actual shipped tree
- record a real go / no-go decision for `0.1.0`
- if the bar is met, promote release metadata from RC to stable
- if the bar is not met, cut `0.1.0-rc.2` honestly instead of pretending the stable decision was already made

## Detailed Execution Order

1. `0114` — stable review sweep and release decision
2. `0115` — stable `0.1.0` promotion and tag handoff
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
