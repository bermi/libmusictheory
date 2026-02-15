# 0005 — Interval Analysis

> Dependencies: 0004 (Set Classification)
> Blocks: 0006 (Cluster/Evenness)

## Objective

Implement interval vector computation, Lewin-Quinn FC-components, and relation detection algorithms (Z-relation, M-relation).

## Research References

- [Pitch Class Sets and Set Theory](../../research/pitch-class-sets-and-set-theory.md)
- [Interval Vector and FC Components](../../research/algorithms/interval-vector-and-fc-components.md)
- [Intervals and Vectors](../../research/data-structures/intervals-and-vectors.md)

## Implementation Steps

### 1. Interval Vector (`src/interval_vector.zig`)

```zig
pub const IntervalVector = [6]u8;
pub fn compute(set: PitchClassSet) IntervalVector
```

Verify against known vectors:
- Major triad [047]: <001110>
- Diatonic [013568t]: <254361>

### 2. FC-Components (`src/fc_components.zig`)

```zig
pub const FCComponents = [6]f32;
pub fn compute(set: PitchClassSet) FCComponents
```

Uses trigonometric computation:
- For each k (1-6), sum unit vectors at angles `p * k * 30°` for each pc p
- FC_k = magnitude of resulting vector

### 3. M5/M7 Transform

```zig
pub fn m5Transform(set: PitchClassSet) PitchClassSet
pub fn m7Transform(set: PitchClassSet) PitchClassSet
```

Permutation: multiply each pc by 5 (or 7) mod 12.

### 4. Z-Relation Detection

```zig
pub fn isZRelated(a: PitchClassSet, b: PitchClassSet) bool
```

Same interval vector, not related by transposition or involution.

### 5. M-Relation Detection

```zig
pub fn isMRelated(a: PitchClassSet, b: PitchClassSet) bool
```

One is the M5 transform of the other (up to transposition).

### 6. Precompute Tables

Compile-time computation of IV and FC for all 336 set classes.

### 7. Write tests

- Known interval vectors match published data
- FC-components: complement invariance (FC(x) = FC(complement(x)))
- FC-components: M-relation swaps FC1 ↔ FC5
- Z-related pairs: verify known pairs from Forte catalog
- M5 is self-inverse: m5(m5(x)) = x
- M5 × M7 = identity

## Validation Against Site Data

- `tmp/harmoniousapp.net/p/71/Set-Classes.html`: FC1-FC6 columns for all set classes
- Glossary entries: Interval Content, Lewin-Quinn FC-Components, Z-Relation, M-Relation

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

All of the following must pass before this plan is considered complete:

- [ ] `./verify.sh` passes
- [ ] `zig build verify` passes
- [ ] Interval vectors match music21 for all 336 set classes
- [ ] FC-components satisfy complement invariance
- [ ] M5 is self-inverse
- [ ] Known Z-related pairs verified

## Verification Data Sources

- **music21** (`/Users/bermi/tmp/music21/music21/chord/tables.py` — interval vectors)
- **harmoniousapp.net** (`tmp/harmoniousapp.net/p/71/Set-Classes.html` — FC1-FC6 columns)

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~200 lines of Zig code
- ~250 lines of tests
- 2-3 source files + 1 test file
