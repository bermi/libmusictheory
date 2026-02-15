# 0003 — Pitch Class Set Operations

> Dependencies: 0002 (Core Types)
> Blocks: 0004 (Set Classification), 0007 (Scales/Modes)

## Objective

Implement the `PitchClassSet` type (u12) and all bitwise operations that form the foundation of every music theory algorithm.

## Research References

- [Pitch Class Sets and Set Theory](../../research/pitch-class-sets-and-set-theory.md)
- [Pitch Class Set Operations](../../research/algorithms/pitch-class-set-operations.md)
- [Pitch Class Set Data Structure](../../research/data-structures/pitch-class-set.md)

## Implementation Steps

### 1. Create `src/pitch_class_set.zig`

Core type and namespace:
```zig
pub const PitchClassSet = u12;
```

Operations (all O(1)):
- `fromList([]const PitchClass) → PitchClassSet`
- `toList(PitchClassSet, *[12]PitchClass) → []PitchClass`
- `cardinality(PitchClassSet) → u4` (uses `@popCount`)
- `transpose(PitchClassSet, u4) → PitchClassSet` (circular left shift)
- `transposeDown(PitchClassSet, u4) → PitchClassSet` (circular right shift)
- `invert(PitchClassSet) → PitchClassSet`
- `complement(PitchClassSet) → PitchClassSet`
- `isSubsetOf(PitchClassSet, PitchClassSet) → bool`
- `union_(PitchClassSet, PitchClassSet) → PitchClassSet`
- `intersection(PitchClassSet, PitchClassSet) → PitchClassSet`
- `hammingDistance(PitchClassSet, PitchClassSet) → u4`
- `format(PitchClassSet, *[12]u8) → []u8` (set theory notation: 0-9,t,e)

Constants:
- `EMPTY`, `CHROMATIC`
- Common sets: `C_MAJOR_TRIAD`, `DIATONIC`, `PENTATONIC`, etc.

### 2. Transposition-Aware Operations

- `hasSub(small, big) → bool` (any transposition of small is subset of big)
- `allRotations(PitchClassSet) → [12]PitchClassSet`
- `leastError([]PitchClassSet, target) → PitchClassSet` (min Hamming distance)

### 3. Write tests

- Round-trip: list → PCS → list
- Cardinality matches list length
- Transposition: C major up 7 = G major
- Complement: diatonic complement = pentatonic (5-35)
- Subset: major triad ⊂ diatonic scale
- Hamming distance: C major to C minor = 2
- Inversion: major triad inverted = minor triad (rotated)
- All 12 rotations of diatonic scale are distinct

## Validation Against Site Data

- `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `subbits`, `leftshift`, `rightshift`, `bitsset`, `tolist`, `fromlist`, `hasSub`, `leastError`
- Verify common PCS values match: diatonic = 0b101010110101, pentatonic = 0b000010010101

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

- [x] `./verify.sh` passes
- [x] `zig build verify` passes
- [x] All 12 transpositions of diatonic set are distinct
- [x] C major triad ⊂ diatonic scale
- [x] complement(diatonic) = pentatonic
- [x] Hamming distance(C major, C minor) = 2

## Verification Data Sources

- **harmoniousapp.net** (`tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `subbits`, `leftshift`, `rightshift`, `bitsset`, `tolist`, `fromlist`)

## Implementation History (Point-in-Time)

- `e7457d1` (2026-02-15):
  - Shipped behavior: Added `PitchClassSet` (`u12`) operations in `src/pitch_class_set.zig`, including transposition, inversion, complement, subset/union/intersection, rotations, transposition-aware subset checks, least-error selection, and format output.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~150 lines of Zig code
- ~200 lines of tests
- 1 source file + 1 test file
