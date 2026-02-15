# Evenness, Voice Leading, and Orbifold Geometry

> Source: `tmp/harmoniousapp.net/p/4f/Evenness-Clusters.html`, `tmp/harmoniousapp.net/p/78/Orbifold-Voice-Leading.html`,
> `tmp/harmoniousapp.net/p/73/By-Evenness.html`, `tmp/harmoniousapp.net/p/46/Limited-Transposition.html`,
> Glossary: Evenness, Cluster-free, Chromatic Cluster, Voice Leading,
> Limited Transposition, Consonance, Quartal, Tertiary

## Evenness

### Definition
Measures how uniformly a pitch class set distributes notes around the chromatic circle.
Computed as the minimum Euclidean distance to the "perfectly even" C-note chord
(where C = cardinality, dividing the octave into C equal parts).

### Perfectly Even Sets (Limited Transposition)

| Card | Set | Name | Transpositions |
|------|-----|------|---------------|
| 2 | {0,6} | Tritone | 6 |
| 3 | {0,4,8} | Augmented triad | 4 |
| 4 | {0,3,6,9} | Diminished 7th | 3 |
| 6 | {0,2,4,6,8,10} | Whole-tone | 2 |
| 12 | {all} | Chromatic | 1 |

For cardinality 5, 7, 8, 9: the perfectly even chord does NOT exist in 12-TET
(would require C-TET). Maximally even = closest approximation.

### Maximally Even Sets (Most Important Scales)

| Card | Set Class | Name |
|------|-----------|------|
| 5 | 5-35 [02479] | Pentatonic |
| 7 | 7-35 [013568t] | Diatonic |
| 8 | 8-28 [0134679t] | Diminished Octatonic |
| 9 | 9-12 [01245689t] | Enneatonic |

### Nearly Even Sets (Most Common Chords)
- Major/minor triads: nearest to augmented for 3 notes
- Dominant/major 7th: nearest to dim7 for 4 notes
- Acoustic scale: nearly as even as diatonic for 7 notes

### Evenness Trends (from the dart-board chart)

| Even (center) | Uneven (edge) |
|---------------|---------------|
| More cluster-free | More cluster-containing |
| More tonal | More chromatic/atonal |
| More voice-leading possibilities | Fewer VL possibilities |
| More common in music | Harmonic dead-ends |

## Chromatic Clusters

### Definition
A run of 3 or more consecutive semitones (e.g., {C, C#, D}).

### Cluster Statistics
- 124 of 336 set classes (card 3-9) are cluster-free
- 212 contain chromatic clusters
- Cluster-containing sets are "degenerate" — always one VL step from ±1 cardinality

### On Clock Diagrams
- Black filled circles = regular pitch classes
- Gray filled circles = part of a chromatic cluster
- White circles = absent

## Voice Leading

### Definition
Movement of individual voices from one chord to the next.
Good voice leading = small movements (semitone or whole tone).

### Voice-Leading Distance
The sum of individual pitch-class movements (using shortest path around the circle).
For each voice: `min(|a-b|, 12-|a-b|)`.

### Uncrossed Voice Leadings (Tymoczko 2006)
An algorithm computing ALL possible voice leadings between two pitch class sets,
including the shortest. Key constraint: voices should not cross (swap register positions).

### Correlation with Evenness
Strong correlation: more even set classes (excluding limited-transposition outliers)
have shorter average voice-leading distance to their own transpositions.
Shown in scatter plot (`tmp/harmoniousapp.net/svg/plot-evenness-v-vld.svg`) with regression lines per cardinality.

### Examples
- G Dom 7 → C Maj: short voice leadings (B→C semitone, F→E semitone, D→C whole tone, G shared)
- C minor → F# major: long voice leadings (less related harmonically)

## Orbifold Geometry (Tymoczko 2011)

### The Space
A C-dimensional geometric space for pitch class sets of cardinality C.
- Points = pitch class sets (chords/scales)
- Distance = voice-leading distance in semitones
- Moving one step = one semitone of voice leading
- 12-TET forms a lattice within the continuous space

### Structure for Triads (C=3)
- Four cubes touching at corners, aligned along diagonals
- Central pole of perfect evenness (augmented triads = 4 transpositions)
- Major/minor triads surround the center at equal radius
- Edge of space = mirror wall (degenerate chords where notes coincide)
- 120° twist between first and last repeat

### Higher Dimensions
- 9-D hyperprism contains all cardinalities (card 2-9)
- 8-D walls contain the 8-D orbifold
- Down to 3-D walls of the 4-D orbifold (which contains tesseracts)
- 2-D walls = Möbius strip
- 1-D walls = pitch class circle

### Network/Graph View
- Nodes = chords (same type at equal radius from center)
- Gray edges = single-semitone voice-leading steps
- Most even chords near center; degenerate chords at edges

### Key Result
The orbifold unifies three concepts:
1. **Evenness** = distance from central pole
2. **Voice-leading distance** = graph distance
3. **Consonance** = correlates with proximity to center

Composers choosing consonant chords were simultaneously playing the
"short voice-leading game" and the "near-evenness game."

## Limited Transposition

### Definition
A set class where some transposition T_k (k < 12) produces the same set.
The orbit size divides 12.

### Catalog (from `tmp/harmoniousapp.net/p/46/Limited-Transposition.html`)

| Card | Forte | Prime Form | Name | # Transpositions |
|------|-------|-----------|------|-----------------|
| 3 | 3-12 | 048 | Augmented | 4 |
| 4 | 4-28 | 0369 | Diminished 7th | 3 |
| 4 | 4-25 | 0268 | French 6th | 6 |
| 4 | 4-9 | 0167 | Maj 11 b5 | 6 |
| 6 | 6-35 | 02468t | Whole-Tone | 2 |
| 6 | 6-30 | 013679 | -- | 6 |
| 6 | 6-20 | 014589 | Aug Hexatonic | 4 |
| 6 | 6-7 | 012678 | -- | 6 |
| 8 | 8-28 | 0134679t | Dim Octatonic | 3 |
| 8 | 8-25 | 0124678t | -- | 6 |
| 8 | 8-9 | 01236789 | -- | 6 |
| 9 | 9-12 | 01245689t | Enneatonic | 4 |

## Quartal vs Tertiary Harmony

**Tertiary**: chords built from stacked major/minor 3rds.
Even basic triads need a P4 to complete the octave, so "stacked thirds" is
already imprecise. Near-evenness is a more useful framework.

**Quartal**: chords built from stacked P4ths/P5ths.
Quartal harmony is non-tertiary, used in jazz and modern classical.
Quartal index catalogs quartal set classes by cardinality 3-9.

## Algorithms Required

1. Evenness distance computation (Euclidean distance to perfectly-even C-point chord on unit circle)
2. Chromatic cluster detection and greedy extraction
3. Voice-leading distance between two pitch class sets (Tymoczko algorithm)
4. Optimal voice-leading assignment (minimize total movement, uncrossed)
5. Limited transposition detection (orbit size computation)
6. Average voice-leading distance to all transpositions
7. Orbifold coordinate computation (distance from center)
8. Consonance scoring from interval content + evenness
9. Voice-leading graph construction (nodes = chords, edges = single-semitone moves)
10. Regression analysis: evenness vs. average VL distance
