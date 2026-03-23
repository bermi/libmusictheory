# 0085 — Stable 0.1.0 Cut Master

> Dependencies: 0078, 0082
> Follow-up: 0086, 0087

Status: Draft

## Objective

Promote `0.1.0-rc.1` to a stable `0.1.0` release only after the remaining RC review fixes and public API polish are explicitly triaged and gated.

## Why This Phase Exists

`0.1.0-rc.1` is now tagged and verified, but a stable `0.1.0` should not be a blind rename of the RC tag. The remaining work is narrower:

- decide whether RC review feedback requires another candidate or only documentation/API polish
- make small public-surface improvements without destabilizing the release
- cut `0.1.0` only when the standalone contract and gallery are comfortable to defend as a stable library

## Workstreams

### 1. Stable Cut Readiness

Plan: `0086`

Review `0.1.0-rc.1`, collect any explicit deltas required for a stable cut, and tighten the release metadata/checklist for the final promotion from RC to stable.

### 2. Public API Polish

Plan: `0087`

Make bounded, explicit improvements to the stable public surface:

- clearer naming and docs where the public contract is awkward
- better examples for public C/WASM entry points
- small ergonomic fixes that do not widen the unstable surface accidentally

## Exit Criteria

- `0086` and `0087` are completed
- `./verify.sh` still passes
- `VERSION`, `CHANGELOG.md`, `RELEASE_CHECKLIST.md`, and reviewer docs are updated for a stable cut
- the resulting stable cut is honest about what is stable, experimental, and internal
