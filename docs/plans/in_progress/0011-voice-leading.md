# 0011 — Voice Leading

> Dependencies: 0006 (Cluster/Evenness)
> Blocks: 0017 (Tessellation), 0018 (Misc SVGs)

## Objective

Implement voice-leading distance computation, optimal (uncrossed) voice-leading assignment, and voice-leading graph construction for the orbifold visualization.

## Research References

- [Evenness, Voice Leading and Geometry](../../research/evenness-voice-leading-and-geometry.md)
- [Voice Leading](../../research/algorithms/voice-leading.md)
- [Voice Leading and Geometry](../../research/data-structures/voice-leading-and-geometry.md)

## Implementation Steps

### 1. Single Voice Distance (`src/voice_leading.zig`)

- `voiceDistance(PitchClass, PitchClass) → u4` — shortest path around chromatic circle: `min(|a-b|, 12-|a-b|)`

### 2. Voice-Leading Distance (Same Cardinality)

- `vlDistance(PitchClassSet, PitchClassSet) → u8` — minimum total movement
- For C ≤ 5: brute-force all permutations
- For C > 5: Hungarian algorithm

### 3. Uncrossed Voice Leadings (Tymoczko 2006)

- `uncrossedVoiceLeadings(PitchClassSet, PitchClassSet) → []VoiceAssignment`
- Only C rotational assignments need checking (not C! permutations)
- Return sorted by distance

### 4. Average VL Distance to Transpositions

- `avgVLDistance(PitchClassSet) → f32` — average across all 11 non-trivial transpositions
- Strongly correlates with evenness distance

### 5. Voice-Leading Graph

- `vlGraph([]PitchClassSet) → VLGraph` — nodes = chords, edges = single-semitone VL
- Used for orbifold visualization

### 6. Diatonic Voice-Leading Circuits

- `diatonicFifthsCircuit(Key) → [7]ChordInstance` — vii-iii-vi-ii-V-I-IV
- `diatonicThirdsCircuit(Key) → [7]ChordInstance` — I-vi-IV-ii-vii-V-iii

### 7. Orbifold Coordinates

- `orbifoldRadius(PitchClassSet) → f32` — equals evenness distance

### 8. Tests

- VL distance: G7→C = small (2-3 semitones total)
- Uncrossed VLs: verify C rotational assignments
- Average VL distance correlates with evenness
- VL graph for triads: verify edge count and connectivity
- Diatonic circuits: verify correct degree ordering

## Validation

- `tmp/harmoniousapp.net/p/78/Orbifold-Voice-Leading.html`: orbifold structure, VL correlation
- `tmp/harmoniousapp.net/svg/triads-graphviz-maj-min-orbifold.svg`: expected graph structure

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

- `./verify.sh` passes, `zig build verify` passes.
- VL distance for common cadences matches published values.
- Uncrossed voice leadings use C rotational assignments.
- Average VL distance correlates with evenness.
- Diatonic circuits produce correct degree ordering.

## Verification Data Sources

- harmoniousapp.net (`tmp/harmoniousapp.net/p/78/Orbifold-Voice-Leading.html`, `tmp/harmoniousapp.net/svg/triads-graphviz-maj-min-orbifold.svg`)

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~300 lines of Zig code + ~250 lines of tests
