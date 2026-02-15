# 0004 — Set Class Classification

> Dependencies: 0003 (Set Operations)
> Blocks: 0005 (Interval Analysis), 0006 (Cluster/Evenness), 0021 (Static Tables)

## Objective

Implement OPTC/OPTIC equivalence classification: prime form computation, Forte number assignment, symmetry detection, and limited transposition detection. Generate the complete catalog of 336 set classes at compile time.

## Research References

- [Pitch Class Sets and Set Theory](../../research/pitch-class-sets-and-set-theory.md)
- [Prime Form and Set Class](../../research/algorithms/prime-form-and-set-class.md)
- [Set Class and Classification](../../research/data-structures/set-class-and-classification.md)

## Implementation Steps

### 1. Create `src/set_class.zig`

Algorithms:
- `primeForm(PitchClassSet) → PitchClassSet` (minimum of 12 rotations)
- `fortePrime(PitchClassSet) → PitchClassSet` (min of prime form and inverted prime form)
- `isSymmetric(PitchClassSet) → bool`
- `numTranspositions(PitchClassSet) → u4`
- `isLimitedTransposition(PitchClassSet) → bool`

### 2. Create `src/forte.zig`

Forte number assignment and lookup:
```zig
pub const ForteNumber = struct { cardinality: u4, ordinal: u8, is_z: bool };
```

Static table matching Allen Forte's catalog ordering.

### 3. Compile-Time Enumeration

```zig
pub const SET_CLASSES: [336]SetClass = comptime enumerate();
```

The `enumerate` function:
1. Iterate all 4096 PCS values
2. Filter to cardinality 3-9
3. Compute prime form for each
4. Deduplicate → 336 unique classes
5. Assign Forte numbers by matching Forte's ordering

### 4. OPTIC/K Grouping

Pair complement set classes:
- 208 Forte classes (OPTIC) from 336 OPTC classes
- 115 complement-paired groups (OPTIC/K)

### 5. Classification Flags

```zig
pub const ClassificationFlags = packed struct(u16) {
    cluster_free: bool,
    symmetric: bool,
    limited_transposition: bool,
    // ...
};
```

### 6. Write tests

- Verify exactly 336 OPTC classes for card 3-9
- Verify exactly 208 OPTIC classes
- Verify exactly 115 OPTIC/K groups
- Known prime forms: major triad = 0b000010010001, diatonic = specific value
- Known Forte numbers: 3-11, 7-35, 4-28, etc.
- Symmetry: diatonic (7-35) is symmetric
- Limited transposition: whole-tone has 2, dim7 has 3, aug has 4

## Validation Against Site Data

- `tmp/harmoniousapp.net/p/71/Set-Classes.html`: sortable table of all 115 OPTIC/K groups
- `tmp/harmoniousapp.net/p/8b/Cluster-free.html`: 124 cluster-free set classes
- `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `lowestRot`, `rotations`, `numTranspositions`

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
- [ ] Exactly 336 OPTC classes
- [ ] Exactly 208 OPTIC classes
- [ ] Exactly 115 OPTIC/K groups
- [ ] Forte numbers match music21 `chord/tables.py` for all 224 entries
- [ ] Prime forms match Rahn algorithm

## Verification Data Sources

- **music21** (`/Users/bermi/tmp/music21/music21/chord/tables.py` — 224 Forte-classified sets)
- **harmoniousapp.net** (`tmp/harmoniousapp.net/p/71/Set-Classes.html`)

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~250 lines of Zig code
- ~300 lines of tests (including verification against Forte catalog)
- 2 source files + 1 test file
