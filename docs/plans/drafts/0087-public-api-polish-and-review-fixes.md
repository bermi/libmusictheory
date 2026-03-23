# 0087 — Public API Polish And Review Fixes

> Dependencies: 0085, 0074, 0076
> Follow-up: none

Status: Draft

## Summary

Address the remaining small public-surface rough edges discovered during RC review without widening the supported API beyond what the first stable cut can actually guarantee.

## Goals

- improve public API clarity where names, docs, or examples are misleading
- tighten the standalone docs/gallery examples around the stable contract
- keep all compatibility/proof infrastructure internal

## Candidate Scope

- public header documentation cleanup
- README and docs quickstart refinements
- example code improvements in docs/gallery where the stable surface is underspecified
- minor ergonomic improvements that preserve caller-owned buffer discipline and current ABI boundaries

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain checks for any newly clarified public contract language or example expectations
- no new public API should be added unless the stable/experimental/internal classification is updated at the same time

## Exit Criteria

- public docs and examples are clearer at the stable boundary
- any changed API language is enforced by verification
- `./verify.sh` passes
