# 0087 — Public API Polish And Review Fixes

> Dependencies: 0085, 0074, 0076
> Follow-up: 0111, 0112, 0113

Status: In progress

## Summary

Address the remaining small public-surface rough edges discovered during RC review without widening the supported API beyond what the first stable cut can actually guarantee.

## Already Shipped Under This Umbrella

- deterministic bitmap QA atlas and capture path for public image methods
- standalone docs/gallery exposure for public clocks, `OPTIC/K`, evenness, staffs, keyboard, piano staff, and fret surfaces
- gallery SVG / bitmap preview toggle and validation wiring
- live MIDI counterpoint scene plus instrument miniviews and repair / continuation surfaces
- stable Zig wrapper path for supported repo builds on current macOS hosts
- experimental helper extraction from gallery JS into Zig for fret voicing and counterpoint suggestion policy

## Remaining Work

- inventory the real stable contract and enforce it consistently
- clean up quickstarts, examples, and reviewer-facing docs around that contract
- resolve the remaining public image parity / review claims so the stable cut is honest about what is fully guaranteed and what remains experimental

## Detailed Execution Order

1. `0111` — public stable contract audit and enforcement
2. `0112` — public docs, quickstarts, and example boundary
3. `0113` — public image review and parity closure
4. close `0087`

## Remaining Candidate Scope

- public header documentation cleanup
- README and docs quickstart refinements
- example code improvements in docs/gallery where the stable surface is underspecified
- minor ergonomic improvements that preserve caller-owned buffer discipline and current ABI boundaries
- honest stable / experimental / internal classification across header, README, reviewer guide, and gallery wording
- stable quickstart and reviewer paths that do not require repo archaeology
- remaining public image review / parity closure:
  - tighten or explicitly scope SVG-vs-bitmap parity claims
  - keep the QA atlas and gallery toggle aligned with the actual public image methods
  - avoid silent `close enough` wording where a surface is still experimental

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain checks for any newly clarified public contract language or example expectations
- no new public API should be added unless the stable/experimental/internal classification is updated at the same time

## Exit Criteria

- public docs and examples are clearer at the stable boundary
- any changed API language is enforced by verification
- the bitmap QA atlas remains visually inspectable and does not distort method output during capture
- known public image defects from RC review are either fixed or explicitly tracked; no silent `close enough` claims
- `./verify.sh` passes
