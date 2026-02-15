# 0021 — Compile-Time Static Tables

> Dependencies: 0004 (Set Classification), 0005 (Interval Analysis), 0006 (Cluster/Evenness)
> Blocks: None (optimization layer)

## Objective

Precompute all lookup tables at Zig compile time using `comptime`, eliminating runtime initialization and ensuring zero-cost data access.

## Research References

- [Pitch Class Set](../../research/data-structures/pitch-class-set.md) (comptime enumeration example)
- [Set Class and Classification](../../research/data-structures/set-class-and-classification.md) (table sizes)

## Implementation Steps

### 1. Set Class Tables (`src/tables/set_classes.zig`)

All precomputed at `comptime`:
- `SET_CLASSES: [336]SetClass` — all OPTC equivalence classes
- `FORTE_MAP: [336]ForteNumber` — Forte number for each class
- `COMPLEMENT_MAP: [336]u16` — index of complement class
- `INVOLUTION_MAP: [336]u16` — index of involution partner

### 2. Interval Tables (`src/tables/intervals.zig`)

- `INTERVAL_VECTORS: [336][6]u8` — IV for each set class
- `FC_COMPONENTS: [336][6]f32` — FC1-FC6 for each set class

### 3. Classification Tables (`src/tables/classification.zig`)

- `CLUSTER_INFO: [336]ClusterInfo` — cluster analysis
- `EVENNESS_INFO: [336]EvennessInfo` — evenness metrics
- `CLASSIFICATION_FLAGS: [336]ClassificationFlags` — packed bit flags
- `CLUSTER_FREE_INDICES: [124]u16` — indices of cluster-free classes

### 4. Scale/Mode Tables (`src/tables/scales.zig`)

- `SCALE_TYPE_PCS: [7]PitchClassSet` — prime forms
- `MODE_TYPES: [17]ModeType` — all core mode definitions
- `KEY_SPELLING_MAPS: [70]NoteSpellingMap` — note spellings per key/scale

### 5. Chord Tables (`src/tables/chords.zig`)

- `CHORD_TYPES: [~100]ChordType` — all named chord types
- `GAME_RESULTS: [~1000]GameResult` — exhaustive chord-mode matches

### 6. Color Tables (`src/tables/colors.zig`)

- `PC_COLORS: [12]Color` — pitch-class colors
- `IC_COLORS: [6]Color` — interval-class colors
- `COLOR_INDEX: [12]u4` — circle-of-fifths reordering

### 7. Verification

- Runtime assertions that comptime tables match runtime computation
- Cross-reference against site data (spot-check known values)

### Memory Budget

| Table | Entries | Size |
|-------|---------|------|
| Set classes | 336 | ~10 KB |
| Interval vectors | 336 | 2 KB |
| FC-components | 336 | 8 KB |
| Cluster info | 336 | 3 KB |
| Evenness info | 336 | 5 KB |
| Chord types | ~100 | 3 KB |
| Game results | ~1000 | 12 KB |
| Spelling maps | ~70 | 4 KB |
| **Total** | | **~47 KB** |

All fits in L1 cache. Zero runtime allocation needed.

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

- `./verify.sh` passes
- `zig build verify` passes
- Comptime tables produce identical results to runtime computation for all 336 set classes
- Total table memory <= 50KB
- Lookup time is O(1)

## Verification Data Sources

- **music21** (`/Users/bermi/tmp/music21/music21/chord/tables.py`) — cross-reference Forte numbers and interval vectors
- **tonal-ts** — chord and scale type tables

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~600 lines of Zig comptime code + ~200 lines of verification tests
