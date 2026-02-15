# Voice Leading Distance and Optimal Assignment

> References: [Evenness, Voice Leading and Geometry](../evenness-voice-leading-and-geometry.md)
> Source: `tmp/harmoniousapp.net/p/78/Orbifold-Voice-Leading.html`, Glossary: Voice Leading

## Overview

Voice leading measures the total pitch-class movement between two chords. Good voice leading minimizes movement — semitone or whole-tone steps. The Tymoczko (2006) algorithm computes all uncrossed voice leadings between equal-cardinality sets.

## Algorithms

### 1. Single Voice Distance (Shortest Path on Circle)

**Input**: Two pitch classes a, b (0-11)
**Output**: Minimum distance around the chromatic circle (0-6)

```
voice_distance(a, b):
    diff = abs(a - b)
    return min(diff, 12 - diff)
```

**Complexity**: O(1)

### 2. Voice-Leading Distance (Same Cardinality)

**Input**: Two 12-bit PCS of equal cardinality
**Output**: Minimum total voice-leading distance

For sets of equal cardinality C, the voice-leading distance is the minimum sum of individual voice movements across all possible C! assignments.

```
vl_distance(x, y):
    pcs_x = tolist(x)
    pcs_y = tolist(y)
    C = len(pcs_x)
    assert C == len(pcs_y)

    if C <= 5:
        // Brute-force all permutations for small C
        min_dist = infinity
        for perm in permutations(pcs_y):
            dist = sum(voice_distance(pcs_x[i], perm[i]) for i in 0..C-1)
            min_dist = min(min_dist, dist)
        return min_dist
    else:
        // Hungarian algorithm for larger C
        return hungarian_vl(pcs_x, pcs_y)
```

**Complexity**: O(C!) brute-force, O(C³) Hungarian

### 3. Uncrossed Voice Leadings (Tymoczko 2006)

**Input**: Two 12-bit PCS of equal cardinality
**Output**: All uncrossed voice-leading assignments

An uncrossed voice leading preserves the relative order of voices — no voice "crosses" another in register.

```
uncrossed_voice_leadings(x, y):
    pcs_x = sorted(tolist(x))
    pcs_y = sorted(tolist(y))
    C = len(pcs_x)

    results = []
    // Try all C rotations of the target set
    for r in 0..C-1:
        rotated_y = pcs_y[r:] + pcs_y[:r]
        // Compute voice-leading for this rotation
        vl = [(pcs_x[i], rotated_y[i]) for i in 0..C-1]
        dist = sum(voice_distance(vl[i][0], vl[i][1]) for i in 0..C-1)
        results.append({
            assignment: vl,
            distance: dist,
            is_uncrossed: true
        })
    return sorted(results, by=distance)
```

Key insight: for uncrossed voice leadings, only C rotational assignments need to be checked (not C! permutations). The optimal uncrossed VL is always among these C candidates.

**Complexity**: O(C²) for all uncrossed VLs

### 4. Average Voice-Leading Distance to Transpositions

**Input**: 12-bit PCS
**Output**: Average VL distance across all 12 transpositions

```
avg_vl_distance(x):
    total = 0.0
    for k in 1..11:
        transposed = leftshift(x, k)
        total += vl_distance(x, transposed)
    return total / 11.0
```

This metric strongly correlates with evenness distance (Tymoczko's key finding). The scatter plot in `tmp/harmoniousapp.net/even/index.svg` shows this correlation with regression lines per cardinality.

**Complexity**: O(11 * C!) or O(11 * C³) with Hungarian

### 5. Voice-Leading Graph Construction

**Input**: Set of chords (e.g., all triads)
**Output**: Graph where edges = single-semitone voice-leading steps

```
vl_graph(chords):
    nodes = chords
    edges = []
    for i in 0..len(chords)-2:
        for j in i+1..len(chords)-1:
            // Check if chords differ by exactly one semitone in one voice
            dist = vl_distance(chords[i], chords[j])
            if dist == 1:
                edges.append((i, j))
    return (nodes, edges)
```

Used for the orbifold visualization where triads form a network in 3D space.

**Complexity**: O(n² * C) where n = number of chords

### 6. Diatonic Voice-Leading Circuits

**Input**: Key (tonic + mode)
**Output**: Ordered chord sequences with minimum voice-leading

```
// Circle of fifths order: vii-iii-vi-ii-V-I-IV
// Each adjacent pair shares 2 common tones
diatonic_fifths_circuit(key):
    degrees = [7, 3, 6, 2, 5, 1, 4]
    chords = [diatonic_triad(key, d) for d in degrees]
    return chords

// Circle of thirds order (Tymoczko): I-vi-IV-ii-vii-V-iii-I
// Each pair differs by 1-2 semitones total VL distance
diatonic_thirds_circuit(key):
    degrees = [1, 6, 4, 2, 7, 5, 3]
    chords = [diatonic_triad(key, d) for d in degrees]
    return chords
```

## Orbifold Geometry

### 7. Orbifold Coordinate (Distance from Center)

**Input**: 12-bit PCS (a chord)
**Output**: Float — distance from perfectly even center in orbifold space

```
orbifold_radius(x):
    // In the orbifold, distance from center = evenness distance
    return evenness_distance(x)
```

The orbifold is a C-dimensional space where:
- Center = perfectly even chord (augmented for C=3, dim7 for C=4)
- Radius = evenness distance
- Edges = degenerate chords (doubled notes)
- 12-TET chords form a lattice within the continuous space

### 8. Orbifold Network Layout

**Input**: All chords of cardinality C
**Output**: 3D positions for visualization

```
orbifold_layout(chords, C):
    // For C=3 (triads): 4 cubes meeting at diagonal corners
    // Center = augmented triads (4 positions)
    // Surrounding = major/minor triads at equal radius
    positions = {}
    for chord in chords:
        radius = orbifold_radius(chord)
        // Angular position based on root and type
        root = chord_root(chord)
        angle = root * (2 * PI / 12)
        // Type determines height
        quality = chord_quality(chord)
        z = 0 if quality == MAJOR else 1 if quality == MINOR else -1
        positions[chord] = (radius * cos(angle), radius * sin(angle), z)
    return positions
```

## Data Structures Used

- `VoiceLeading`: struct { from: PitchClassSet, to: PitchClassSet, assignment: [MAX_CARD]struct{from: u4, to: u4}, distance: u8 }
- `VLGraph`: struct { nodes: []PitchClassSet, edges: []struct{a: u16, b: u16, distance: u8} }

## Dependencies

- [Pitch Class Set Operations](pitch-class-set-operations.md)
- [Evenness and Consonance](evenness-and-consonance.md)
