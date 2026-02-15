# Evenness and Consonance Metrics

> References: [Evenness, Voice Leading and Geometry](../evenness-voice-leading-and-geometry.md)
> Source: `tmp/harmoniousapp.net/p/4f/Evenness-Clusters.html`, `tmp/harmoniousapp.net/p/73/By-Evenness.html`, `tmp/harmoniousapp.net/p/78/Orbifold-Voice-Leading.html`

## Overview

Evenness measures how uniformly a pitch class set distributes notes around the chromatic circle. More even sets tend to be more consonant, more common in music, and have shorter voice-leading distances. This is the central geometric insight unifying the site's theory.

## Algorithms

### 1. Evenness Distance

**Input**: 12-bit PCS
**Output**: Float — Euclidean distance from the perfectly even C-note chord

The "perfectly even" chord of cardinality C places C notes equally around the unit circle at angles `k * (2π/C)` for k = 0..C-1.

```
evenness_distance(x):
    pcs = tolist(x)
    C = len(pcs)
    if C == 0 or C == 12: return 0.0

    // Compute centroid of actual pitch classes on unit circle
    // using the C-th harmonic (FC_C in Fourier terms)
    sum_x = 0.0
    sum_y = 0.0
    for p in pcs:
        angle = p * C * (2 * PI / 12)   // = p * C * PI/6
        sum_x += cos(angle)
        sum_y += sin(angle)

    // Distance from perfectly even = magnitude of C-th Fourier component
    // Perfectly even chord: this magnitude = C (all vectors align)
    // Actual: deviations reduce magnitude
    magnitude = sqrt(sum_x * sum_x + sum_y * sum_y)
    // Normalized so perfectly even = 0, maximally uneven = C
    return C - magnitude
```

Alternative simpler formulation using direct geometric distance:

```
evenness_distance_v2(x):
    pcs = tolist(x)
    C = len(pcs)
    if C <= 1: return 0.0

    // Place notes on unit circle at chromatic positions
    actual = [(cos(p * PI/6), sin(p * PI/6)) for p in pcs]

    // Place ideal even chord (C notes equally spaced)
    // Try all rotations and find minimum distance
    min_dist = infinity
    for offset in [i * (2*PI / (12*C)) for i in 0..12*C]:
        ideal = [(cos(offset + k*2*PI/C), sin(offset + k*2*PI/C)) for k in 0..C-1]
        // Optimal assignment (Hungarian algorithm for small C)
        dist = min_assignment_distance(actual, ideal)
        min_dist = min(min_dist, dist)
    return min_dist
```

The site uses the first (Fourier-based) approach which is equivalent to the FC_C component.

**Complexity**: O(n) where n = cardinality

### 2. Maximally Even Test

**Input**: 12-bit PCS
**Output**: Boolean — is this set maximally even for its cardinality?

```
is_maximally_even(x):
    C = popcount(x)
    all_classes = [c for c in set_classes if popcount(c) == C]
    my_evenness = evenness_distance(x)
    return all(my_evenness <= evenness_distance(c) for c in all_classes)
```

Known maximally even sets:
- Card 5: Pentatonic [02479] (5-35)
- Card 7: Diatonic [013568t] (7-35)
- Card 8: Octatonic [0134679t] (8-28)
- Card 9: Enneatonic [01245689t] (9-12)

**Complexity**: O(n) per set, precomputable

### 3. Perfectly Even Test (Limited Transposition)

**Input**: 12-bit PCS
**Output**: Boolean — does 12 divide evenly by cardinality AND is the set exactly at even spacing?

```
is_perfectly_even(x):
    C = popcount(x)
    if 12 % C != 0: return false
    step = 12 / C
    // Check if notes are exactly step apart
    pcs = tolist(x)
    for i in 1..C-1:
        if (pcs[i] - pcs[0]) % 12 != i * step:
            return false
    return true
```

Perfectly even sets: tritone (C=2), augmented (C=3), dim7 (C=4), whole-tone (C=6), chromatic (C=12).

**Complexity**: O(C) = O(1)

### 4. Dart-Board Evenness Chart Computation

**Input**: All 336 set classes
**Output**: Polar coordinates (angle = cardinality band, radius = evenness distance)

```
dartboard_positions(set_classes):
    positions = []
    for sc in set_classes:
        card = popcount(sc)
        evenness = evenness_distance(sc)
        // Cardinality determines the angular band (concentric ring)
        // Evenness determines radial position within band
        // Cluster-free status determines color
        cluster_free = not has_cluster(sc)
        positions.append({
            set_class: sc,
            cardinality: card,
            evenness: evenness,
            cluster_free: cluster_free,
            // Most even at center, least even at edge
            radius: evenness,
        })
    return positions
```

### 5. Consonance Score (Composite)

**Input**: 12-bit PCS
**Output**: Float — composite consonance score

```
consonance_score(x):
    // Combine evenness (primary) with interval content (secondary)
    ev = evenness_distance(x)
    iv = interval_vector(x)

    // Weight consonant intervals higher
    // IC5 (4ths/5ths) most consonant, IC1 (semitones) least
    ic_weights = [0.1, 0.3, 0.5, 0.7, 0.9, 0.4]  // IC1..IC6
    weighted_consonance = sum(iv[i] * ic_weights[i] for i in 0..5)

    // Lower evenness distance = more consonant
    // Higher weighted consonance = more consonant
    return weighted_consonance / (1 + ev)
```

Note: The exact weighting is an aesthetic choice. The site primarily uses evenness distance as the consonance proxy.

## Key Relationships

- More even → shorter average voice-leading distance to transpositions
- More even → more cluster-free
- More even → more common in tonal music
- Perfectly even = modes of limited transposition
- Near-even = most important scales and chords (diatonic, major/minor triads)

## Data Structures Used

- `EvennessInfo`: struct { distance: f32, is_maximally_even: bool, is_perfectly_even: bool }
- Static table: `[336]EvennessInfo`

## Dependencies

- [Pitch Class Set Operations](pitch-class-set-operations.md)
- [Prime Form and Set Class](prime-form-and-set-class.md)
- [Interval Vector](interval-vector-and-fc-components.md)
- [Chromatic Cluster Detection](chromatic-cluster-detection.md)
