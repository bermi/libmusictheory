# 0086 — Stable Cut Readiness And Promotion

> Dependencies: 0085, 0082
> Follow-up: none

Status: In progress

## Summary

Evaluate the `0.1.0-rc.1` state against the stable release bar, decide whether another RC is needed, and if not, promote the versioning/docs/checklist from RC to stable `0.1.0`.

## Goals

- define the exact delta between `0.1.0-rc.1` and stable `0.1.0`
- make the stable release notes explicit and non-placeholder
- update the reviewer and release checklist language from RC to stable once the bar is met

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must make `0086` fail if `VERSION` is stable while `CHANGELOG.md` and release docs still describe an RC cut
- `./verify.sh` must make `0086` fail if reviewer docs still present the release as `0.1.0-rc.1` after promotion

## Exit Criteria

- either the branch explicitly decides to keep another RC, or the metadata is promoted to stable `0.1.0`
- release docs and checklists use stable terminology consistently
- `./verify.sh` passes
