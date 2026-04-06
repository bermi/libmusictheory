# 0116 — Ordered Scale And Mode Expansion Foundation

> Dependencies: contrapunk-theory-integration, 0007, 0020
> Follow-up: 0117, 0118

Status: Completed

## Summary

Add the first executable Contrapunk integration slice: a shared ordered-scale foundation, a corrected rooted mode inventory, and the 12 missing seven-note named modes that fit the library's explainability bar.

## Why

Everything else in the explainable-theory lane depends on one thing the repo does not yet model cleanly: ordered scale degrees. We need that layer before diatonic transposition, modal interchange, or principled nearest-scale-note helpers can be correct.

This slice also fixes a hidden correctness issue in the current mode inventory: the existing post-diatonic families are not all rooted from the right parent scale definitions, which makes the mode surface harder to explain and verify.

## Scope

### Ordered Scale Foundation

- add `/Users/bermi/code/libmusictheory/src/ordered_scale.zig`
- represent named ordered parent patterns with:
  - family
  - rooted offsets
  - degree count
  - derived `u12` pitch-class set
- provide deterministic helpers for:
  - base pattern lookup
  - mode rotation by degree
  - rooted mode pitch-class-set derivation

### Honest Mode Inventory Expansion

Extend the public mode inventory from 17 to 29 by adding the missing seven-note modes that survive the explainability gate:

- Harmonic Minor
- Locrian nat6
- Ionian Aug
- Dorian #4
- Phrygian Dominant
- Lydian #2
- Super Locrian Dim
- Double Harmonic
- Hungarian Minor
- Enigmatic
- Neapolitan Minor
- Neapolitan Major

### Public ABI Reflection

Keep the C ABI honest about the expanded inventory:

- extend `lmt_mode_type`
- add experimental reflection helpers:
  - `lmt_mode_type_count`
  - `lmt_mode_type_name`
- export them to the standalone WASM profiles

### Verification And Documentation

Before implementation behavior is accepted:

- update `/Users/bermi/code/libmusictheory/verify.sh` with `0116` guardrails
- add focused tests for ordered patterns, mode identity, and C ABI discovery
- update scale/mode research docs to reflect the new ordered-scale foundation and the expanded named inventory

## Explainability Check

An LLM should be able to say: `Phrygian Dominant is the fifth mode of harmonic minor, so its degrees are 1, b2, 3, 4, 5, b6, b7.`

## Exit Criteria

- the repo has a reusable ordered-scale layer with no heap allocation
- all 29 supported modes are identifiable and named correctly
- the public C ABI can report the mode inventory count and names
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `./zigw build test`


## Implementation History (Point-in-Time)

- `20e6034` (2026-04-06):
  - Shipped behavior: added `src/ordered_scale.zig`, corrected rooted parent-pattern facts, expanded the named public mode inventory from 17 to 29 entries, and exposed experimental C ABI mode discovery helpers via `lmt_mode_type_count` and `lmt_mode_type_name`.
  - Verification: `./verify.sh`, `./zigw build test`
