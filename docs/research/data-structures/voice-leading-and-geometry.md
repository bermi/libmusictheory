# Voice Leading and Geometry Data Structures

> References: [Evenness, Voice Leading and Geometry](../evenness-voice-leading-and-geometry.md)
> Used by: voice-leading, evenness-and-consonance

## Types

### VoiceAssignment

Maps each voice in chord A to a voice in chord B.

```zig
pub const MAX_CARDINALITY = 9;

pub const VoiceAssignment = struct {
    from_pcs: [MAX_CARDINALITY]PitchClass,
    to_pcs: [MAX_CARDINALITY]PitchClass,
    cardinality: u4,

    pub fn distance(self: VoiceAssignment) u8 {
        var total: u8 = 0;
        for (0..self.cardinality) |i| {
            const diff = @as(u8, @intCast(
                @min(
                    @abs(@as(i8, self.from_pcs[i]) - @as(i8, self.to_pcs[i])),
                    12 - @abs(@as(i8, self.from_pcs[i]) - @as(i8, self.to_pcs[i]))
                )
            ));
            total += diff;
        }
        return total;
    }
};
```

### VoiceLeadingResult

Complete analysis of voice leading between two chords.

```zig
pub const VoiceLeadingResult = struct {
    from: PitchClassSet,
    to: PitchClassSet,
    optimal: VoiceAssignment,           // minimum distance assignment
    all_uncrossed: []VoiceAssignment,   // all C rotational assignments
    distance: u8,                        // total semitone movement

    pub fn commonTones(self: VoiceLeadingResult) u4 {
        return pcs.cardinality(self.from & self.to);
    }
};
```

### VLGraph

Graph of chords connected by single-semitone voice-leading edges.

```zig
pub const VLEdge = struct {
    from_idx: u16,
    to_idx: u16,
    distance: u8,
};

pub const VLGraph = struct {
    nodes: []const PitchClassSet,       // all chords of a given cardinality
    edges: []const VLEdge,              // single-semitone connections
    cardinality: u4,

    pub fn neighbors(self: VLGraph, node_idx: u16) []const VLEdge {
        // Return all edges incident to node_idx
    }
};
```

### OrbifoldPoint

Position in the orbifold geometric space.

```zig
pub const OrbifoldPoint = struct {
    chord: PitchClassSet,
    radius: f32,               // distance from center (= evenness distance)
    angular_position: f32,     // based on root pitch class
    elevation: f32,            // based on chord quality (for 3D visualization)

    pub fn isNearCenter(self: OrbifoldPoint) bool {
        return self.radius < 0.5;  // near-perfectly even
    }
};
```

### ScaleVoiceLeading

Voice-leading relationships between scales (for tessellation map).

```zig
pub const ScaleVLEdge = struct {
    from_scale: Scale,
    to_scale: Scale,
    changed_note_from: PitchClass,   // note that moves
    changed_note_to: PitchClass,     // where it moves to
    direction: i2,                    // +1 = up semitone, -1 = down semitone
};

pub const ScaleTessellation = struct {
    scales: []const Scale,
    edges: []const ScaleVLEdge,

    // Tile shapes based on scale type:
    // Diatonic → hexagon (6 neighbors)
    // Acoustic → square (4 neighbors)
    // Harmonic minor/major → triangle/diamond (3 neighbors)
};
```

### DiatonicCircuit

Ordered chord sequences within a key following voice-leading principles.

```zig
pub const CircuitType = enum {
    fifths,  // vii-iii-vi-ii-V-I-IV (shared 2 common tones)
    thirds,  // I-vi-IV-ii-vii-V-iii (Tymoczko: 1-2 semitone total VL)
};

pub const DiatonicCircuit = struct {
    key: Key,
    circuit_type: CircuitType,
    chords: [7]ChordInstance,
    degrees: [7]u4,                   // degree order for this circuit
    vl_distances: [7]u8,              // VL distance between adjacent pairs
};
```

## Relationships

```
VoiceAssignment (per-voice mapping)
  └── VoiceLeadingResult (optimal + all assignments)
        └── VLGraph (network of chord connections)
              └── OrbifoldPoint (geometric position)

ScaleVLEdge (single-semitone scale changes)
  └── ScaleTessellation (hexagonal/square/triangular map)

DiatonicCircuit (ordered chord sequences)
  └── CircuitType (fifths vs thirds ordering)
```

## Memory Considerations

- VLGraph for all 12 triads: 12 nodes × up to ~36 edges ≈ tiny
- VLGraph for all 48 chords (12 roots × 4 qualities): 48 nodes × ~200 edges ≈ small
- Full scale tessellation: ~66 scales (12×4 main + 12×2 harmonic + 2 WT + 3 dim) × ~4 edges each ≈ small
- All data fits in a few KB — no memory pressure
