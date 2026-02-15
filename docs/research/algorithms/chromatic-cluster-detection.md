# Chromatic Cluster Detection and Extraction

> References: [Pitch Class Sets](../pitch-class-sets-and-set-theory.md), [Evenness](../evenness-voice-leading-and-geometry.md)
> Source: `tmp/harmoniousapp.net/js-client/pitch-class-sets.js` functions: `hasCluster`, `getClusters`
> Source: `tmp/harmoniousapp.net/p/4f/Evenness-Clusters.html`, `tmp/harmoniousapp.net/p/8b/Cluster-free.html`

## Overview

Chromatic clusters are runs of 3+ consecutive semitones in a pitch class set. Cluster-free sets (124 of 336 set classes) form the harmonic foundation of tonal and jazz music. Detection and extraction algorithms are critical for classification and filtering.

## Algorithms

### 1. Cluster Detection (hasCluster)

**Input**: 12-bit PCS
**Output**: Boolean — does the set contain 3+ consecutive semitones?

```
has_cluster(x):
    // All 12 rotations of {0,1,2} (three consecutive semitones)
    cluster_masks = [
        0b000000000111,  // {0,1,2}
        0b000000001110,  // {1,2,3}
        0b000000011100,  // {2,3,4}
        0b000000111000,  // {3,4,5}
        0b000001110000,  // {4,5,6}
        0b000011100000,  // {5,6,7}
        0b000111000000,  // {6,7,8}
        0b001110000000,  // {7,8,9}
        0b011100000000,  // {8,9,10}
        0b111000000000,  // {9,10,11}
        0b100000000011,  // {10,11,0} wrapping
        0b000000000101 | (1 << 11),  // {11,0,1} wrapping = 0b100000000011
    ]
    // Simplified: generate masks with leftshift
    base = 0b111  // {0,1,2}
    for k in 0..11:
        mask = leftshift(base, k)
        if (x & mask) == mask:
            return true
    return false
```

**Complexity**: O(12) = O(1)

### 2. Greedy Cluster Extraction (getClusters)

**Input**: 12-bit PCS
**Output**: (cluster_pcs: u12, non_cluster_pcs: u12)

Greedily extract the longest consecutive runs first:

```
get_clusters(x):
    remaining = x
    for run_len in [9, 8, 7, 6, 5, 4, 3]:
        // Build mask of run_len consecutive semitones
        base_mask = (1 << run_len) - 1  // run_len consecutive bits
        for k in 0..11:
            mask = leftshift(base_mask, k)
            if (remaining & mask) == mask:
                remaining ^= mask  // remove cluster
    cluster_pcs = x ^ remaining
    return (cluster_pcs, remaining)
```

The greedy approach (longest first) is needed because a run of 4 consecutive notes contains two overlapping 3-note clusters.

**Complexity**: O(7 * 12) = O(1)

### 3. Cluster-Free Set Enumeration

**Input**: Cardinality range (3-9)
**Output**: All cluster-free set classes

```
enumerate_cluster_free(min_card, max_card):
    all_classes = enumerate_set_classes(min_card, max_card)
    return [c for c in all_classes if not has_cluster(c)]
```

Results: 124 cluster-free set classes out of 336 total (card 3-9).

**Complexity**: O(336 * 12) — precomputable

### 4. Cluster Statistics Per Set Class

**Input**: 12-bit PCS (prime form)
**Output**: Cluster count and cluster length distribution

```
cluster_stats(x):
    pcs = tolist(x)
    // Walk around the circle, finding consecutive runs
    runs = []
    current_run = 1
    for i in 1..len(pcs):
        if pcs[i % len(pcs)] == (pcs[(i-1) % len(pcs)] + 1) % 12:
            current_run += 1
        else:
            if current_run >= 3:
                runs.append(current_run)
            current_run = 1
    // Handle wrap-around
    if current_run >= 3:
        runs.append(current_run)
    return runs
```

### 5. Clock Diagram Coloring (Cluster vs Non-Cluster)

Used by OPTC clock diagrams to color notes:
- Black filled: non-cluster pitch classes
- Gray filled: cluster pitch classes
- White: absent pitch classes

```
clock_colors(x):
    (cluster_pcs, non_cluster_pcs) = get_clusters(x)
    colors = [WHITE; 12]
    for i in 0..11:
        if non_cluster_pcs & (1 << i):
            colors[i] = BLACK
        elif cluster_pcs & (1 << i):
            colors[i] = GRAY
    return colors
```

## Significance

- Cluster-free sets sound more consonant and are used in tonal music
- The 124 cluster-free set classes are the "harmonic vocabulary" of jazz
- Sets with clusters are "degenerate" — always one voice-leading step from ±1 cardinality
- The evenness dart-board chart correlates cluster-freeness with proximity to center

## Data Structures Used

- `PitchClassSet` (u12)
- `ClusterInfo`: struct { cluster_pcs: u12, non_cluster_pcs: u12, is_cluster_free: bool }
- Static table: `[336]ClusterInfo` precomputed for all set classes

## Dependencies

- [Pitch Class Set Operations](pitch-class-set-operations.md)
- [Prime Form and Set Class](prime-form-and-set-class.md)
