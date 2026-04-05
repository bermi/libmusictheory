# 0085 — Stable 0.1.0 Cut Master

> Dependencies: 0078, 0082
> Follow-up: 0086, 0087, 0111, 0112, 0113, 0114, 0115

Status: In progress

## Objective

Promote `0.1.0-rc.1` to a stable `0.1.0` release only after the remaining RC review fixes and public API polish are explicitly triaged and gated.

## Why This Phase Exists

`0.1.0-rc.1` is now tagged and verified, but a stable `0.1.0` should not be a blind rename of the RC tag. The remaining work is narrower:

- decide whether RC review feedback requires another candidate or only documentation/API polish
- make small public-surface improvements without destabilizing the release
- cut `0.1.0` only when the standalone contract and gallery are comfortable to defend as a stable library

## Current Remaining Work

The remaining execution lane is now narrow and explicit:

1. complete `0115` and promote the current tree from `0.1.0-rc.1` to stable `0.1.0`
2. close `0086` after the promotion lane is complete
3. close the master plan after `0086` is completed

## Detailed Execution Order

### Stable Decision And Promotion

1. completed `0114` — stable reviewer sweep and release decision
2. `0115` — stable `0.1.0` promotion and tag handoff
3. close `0086`

### Master Closeout

1. close `0085` after `0086` and `0087` are both completed

## Workstreams

### 1. Stable Cut Readiness (`0086`)

Detailed child plans:

- `0114`
- `0115`

Review `0.1.0-rc.1`, collect any explicit deltas required for a stable cut, and tighten the release metadata/checklist for the final promotion from RC to stable.

### 2. Public API Polish (`0087`)

Detailed child plans:

Completed under `0087`:

- `0111`
- `0112`
- `0113`

Completed bounded improvements to the stable public surface:

- clearer naming and docs where the public contract is awkward
- better examples for public C/WASM entry points
- small ergonomic fixes that do not widen the unstable surface accidentally

## Risks To Resolve Before Stable

- stable, experimental, and internal surfaces can still drift apart in docs if not inventoried together
- current public image claims must not outrun what the parity/QA gates actually prove
- the reviewer path still reflects RC-era assumptions and needs a deliberate stable go / no-go pass

## Exit Criteria

- `0086` and `0087` are completed
- `0111` through `0115` are completed
- `./verify.sh` still passes
- `VERSION`, `CHANGELOG.md`, `RELEASE_CHECKLIST.md`, and reviewer docs are updated for a stable cut
- the resulting stable cut is honest about what is stable, experimental, and internal
