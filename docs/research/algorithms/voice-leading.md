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

## Time-Aware Counterpoint State

The standalone library now also needs a register-aware, time-aware layer on top of pitch-class voice-leading. The current `VoicedState` work adds fixed-capacity primitives for:

- persistent voice identity across adjacent MIDI snapshots
- current MIDI notes and sustained-note flags
- recent temporal memory through a `VoicedHistoryWindow`
- tonic/mode context and derived key quality
- metric position (`beat_in_bar`, `beats_per_bar`, `subdivision`)
- lightweight cadence-state inference

This is intentionally a separate layer from pure PCS voice-leading distance:

- PCS voice-leading treats voices as anonymous and equal-cardinality
- counterpoint state keeps concrete MIDI register, voice ids, and recent history

The implementation uses a deterministic assignment step with insertion/deletion costs so the same note sequence always yields the same voice ids. That state then becomes the input for later motion classification and next-step ranking.

## Motion Classification And Rule Profiles

With persistent voice ids in place, adjacent-state counterpoint can be classified deterministically instead of guessed in the gallery layer. The standalone library now derives a `MotionSummary` from two `VoicedState` values.

Per retained voice it records:

- `stationary` motion (`common tone`)
- `step`
- `leap`

Across retained voice pairs it classifies:

- `contrary`
- `similar`
- `parallel`
- `oblique`
- `crossing`
- `overlap`

It also exposes:

- total motion magnitude
- outer-voice interval trajectory
- previous/current cadence states

Those summaries are then evaluated under explicit `CounterpointRuleProfile` values instead of a hidden single rule set:

- `species`
- `tonal_chorale`
- `modal_polyphony`
- `jazz_close_leading`
- `free_contemporary`

The current profile layer is intentionally lightweight:

- it prefers or penalizes motion classes differently
- it penalizes excessive spacing and leaps differently
- it can mark parallels/crossings as disallowed for stricter styles
- it applies cadence-transition bonuses where cadence state is already available

This gives the next-step ranker a deterministic, inspectable base that can be reused across CLI, C ABI, WASM, and gallery surfaces.

## Ranked Next Steps And Reason Codes

On top of `VoicedHistoryWindow`, `MotionSummary`, and `CounterpointRuleProfile`, the library now exposes a `NextStepSuggestion` ranker for short-range counterpoint exploration.

The current ranker is intentionally bounded rather than combinatorial:

- single-voice step candidates
- outer-voice contrary-motion candidates
- outer-voice parallel-motion candidates
- simple cadential-resolution candidates when the current state reads as dominant

Each `NextStepSuggestion` carries:

- a total score
- the resulting MIDI notes and pitch-class set
- embedded motion/profile evaluation data
- `reason_mask`
- `warning_mask`
- cadence effect and tension delta

Current reason codes:

- `NEXT_STEP_REASON_MINIMAL_MOTION`
- `NEXT_STEP_REASON_CONTRARY_MOTION`
- `NEXT_STEP_REASON_COMMON_TONE_RETENTION`
- `NEXT_STEP_REASON_CADENCE_PULL`
- `NEXT_STEP_REASON_PRESERVES_SPACING`
- `NEXT_STEP_REASON_RELEASES_TENSION`
- `NEXT_STEP_REASON_BUILDS_TENSION`
- `NEXT_STEP_REASON_LEAP_COMPENSATION`

Current warning codes:

- `NEXT_STEP_WARNING_PARALLELS`
- `NEXT_STEP_WARNING_CROSSING`
- `NEXT_STEP_WARNING_OVERLAP`
- `NEXT_STEP_WARNING_WIDE_SPACING`
- `NEXT_STEP_WARNING_CONSECUTIVE_LEAP`
- `NEXT_STEP_WARNING_OUTSIDE_CONTEXT`
- `NEXT_STEP_WARNING_CLUSTER_PRESSURE`

Temporal memory matters here: `temporalMemoryScore` looks back one state so consecutive leaps and leap compensation are scored differently from the same current chord viewed in isolation.

## Cadence Funnel And Suspension Machine

The live counterpoint layer now also exposes two phrase-aware summaries on top of the ranked next-step data.

### Cadence Funnel

`rankCadenceDestinations` collapses the current state plus short-range next-step candidates into a small set of destination classes:

- `stable-continuation`
- `pre-dominant-arrival`
- `dominant-arrival`
- `authentic-arrival`
- `half-arrival`
- `deceptive-pull`

This is intentionally not a full formal cadence parser. It is a near-term destination-pressure summary for interactive composing:

- current cadence state contributes an immediate anchor bias
- ranked next-step candidates reinforce or weaken destination classes
- warning-heavy candidates reduce destination confidence
- accumulated tension deltas show whether that destination tends to build or release pressure

### Suspension Machine

`analyzeSuspensionMachine` uses the recent `VoicedHistoryWindow` rather than a single chord snapshot. It reports:

- `none`
- `preparation`
- `suspension`
- `resolution`
- `unresolved`

The current implementation is deliberately lightweight and deterministic:

- it looks for retained voices between adjacent states
- it checks whether tension rose into the current slice
- it scans the next-step ranker for stepwise resolution candidates of the held voice
- it marks unresolved states when a held dissonant-looking tone has no immediate stepwise release path

This keeps the cadence and suspension views reusable across the C ABI, WASM gallery, and future host applications without embedding gallery-only heuristics.

## Orbifold Ribbon And Common-Tone Constellation

The live counterpoint gallery now also exposes two linked explanatory views built on top of the existing voice-leading and counterpoint summaries.

### Orbifold Ribbon

The orbifold ribbon is intentionally local rather than global. It does not try to solve a general continuous orbifold embedding for every live texture. Instead it uses the existing triad orbifold metadata as a stable explanatory anchor layer.

Current behavior:

- enumerate the library-owned triad orbifold nodes and edges once through the C ABI
- map the current state and ranked next-step candidates onto those anchors
- prefer exact triad matches first
- otherwise reduce richer sets to the most explanatory nearby triadic anchor by:
  - overlap with the live set
  - subset preservation
  - minimized outside tones
  - root proximity
  - stable quality preference

This makes the view useful for real live MIDI textures where the ranked candidates often contain added tones or incomplete sonorities. The ribbon is therefore an explanatory projection of counterpoint state onto harmonic geometry, not a claim that every live sonority is itself a pure orbifold node.

### Common-Tone Constellation

The common-tone constellation is driven by recent voiced history plus the currently focused ranked candidate.

Its current presentation separates:

- retained tones as fixed stars
- moving tones as directed vectors
- recent states as quieter history anchors

The important implementation choice is that the visible retained-vs-moving split is derived from the actual current voiced notes and the candidate voiced notes, not only from already-compressed motion-summary flags. That keeps the explanatory picture aligned with the concrete notes the user is hearing and seeing.

Together, the ribbon and constellation answer two different questions:

- `Where is this move heading in harmonic geometry?`
- `How much of the texture is actually staying put versus moving?`

## Dependencies

- [Pitch Class Set Operations](pitch-class-set-operations.md)
- [Evenness and Consonance](evenness-and-consonance.md)
