# 0006 — Chromatic Cluster Detection and Evenness Metrics

> Dependencies: 0004 (Set Classification), 0005 (Interval Analysis)
> Blocks: 0009 (Chord Construction), 0011 (Voice Leading), 0014 (Clock Diagrams), 0018 (Misc SVGs)

## Objective

Implement cluster detection, cluster-free filtering, evenness distance computation, and consonance scoring.

## Research References

- [Evenness, Voice Leading and Geometry](../../research/evenness-voice-leading-and-geometry.md)
- [Chromatic Cluster Detection](../../research/algorithms/chromatic-cluster-detection.md)
- [Evenness and Consonance](../../research/algorithms/evenness-and-consonance.md)

## Implementation Steps

### 1. Cluster Detection (`src/cluster.zig`)

- `hasCluster(PitchClassSet) → bool` — test all 12 rotations of {0,1,2} as subsets
- `getClusters(PitchClassSet) → ClusterInfo` — greedy extraction of longest runs
- `clusterStats(PitchClassSet) → []u4` — lengths of all cluster runs

### 2. Cluster-Free Enumeration

- Filter 336 set classes → 124 cluster-free
- Precompute as compile-time table

### 3. Evenness Distance (`src/evenness.zig`)

- `evennessDistance(PitchClassSet) → f32` — Fourier-based (FC_C component)
- `isMaximallyEven(PitchClassSet) → bool`
- `isPerfectlyEven(PitchClassSet) → bool`

### 4. Consonance Score

- `consonanceScore(PitchClassSet) → f32` — composite of evenness + interval content

### 5. Precompute Tables

- `[336]ClusterInfo` — cluster analysis for all set classes
- `[336]EvennessInfo` — evenness data for all set classes

### 6. Tests

- Verify exactly 124 cluster-free set classes (card 3-9)
- Known cluster-free: diatonic, acoustic, pentatonic, major triad, minor triad
- Known cluster-containing: chromatic cluster {0,1,2} has cluster
- Perfectly even: tritone, augmented, dim7, whole-tone
- Maximally even: pentatonic (card 5), diatonic (card 7), octatonic (card 8)
- Evenness distance: perfectly even sets have distance 0

## Validation

- `tmp/harmoniousapp.net/p/4f/Evenness-Clusters.html`: 124/336 statistics, dart-board chart
- `tmp/harmoniousapp.net/p/8b/Cluster-free.html`: list of all 124 cluster-free set classes
- `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `hasCluster`, `getClusters`, `clusters`, `clusters93`

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
- [x] Exactly 124 cluster-free set classes
- [x] Perfectly even sets (tritone, aug, dim7, whole-tone) have distance 0
- [x] Maximally even sets identified correctly

## Verification Data Sources

- **harmoniousapp.net** (`tmp/harmoniousapp.net/p/4f/Evenness-Clusters.html`, `tmp/harmoniousapp.net/p/8b/Cluster-free.html`, `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`: `hasCluster`, `getClusters`)

## Implementation History (Point-in-Time)

- `28ddc53` (2026-02-15):
  - Shipped behavior: Added chromatic-cluster detection and extraction in `src/cluster.zig`, evenness distance/maximal-evenness/consonance scoring in `src/evenness.zig`, and precomputed cluster/evenness tables for all 336 set classes.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~200 lines of Zig code + ~200 lines of tests
