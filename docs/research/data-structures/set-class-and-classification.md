# Set Class and Classification Data Structures

> References: [Pitch Class Sets](../pitch-class-sets-and-set-theory.md), [Evenness](../evenness-voice-leading-and-geometry.md)
> Used by: prime-form-and-set-class, chromatic-cluster-detection, evenness-and-consonance

## Types

### ForteNumber

Allen Forte's canonical labeling for set classes.

```zig
pub const ForteNumber = struct {
    cardinality: u4,    // 3-9
    ordinal: u8,        // 1-50 (varies by cardinality)
    is_z: bool,         // Z-prefix for Z-related pairs

    pub fn format(self: ForteNumber, buf: *[8]u8) []u8 {
        // e.g., "3-11", "4-Z29", "7-35"
        var len: usize = 0;
        buf[len] = '0' + self.cardinality;
        len += 1;
        buf[len] = '-';
        len += 1;
        if (self.is_z) {
            buf[len] = 'Z';
            len += 1;
        }
        // write ordinal...
        return buf[0..len];
    }
};
```

### SetClass

Complete information about one OPTC-equivalence class.

```zig
pub const SetClass = struct {
    prime_form: PitchClassSet,        // canonical 12-bit representative
    forte_number: ForteNumber,
    cardinality: u4,
    interval_vector: IntervalVector,
    fc_components: FCComponents,
    evenness_distance: f32,

    // Classification flags
    is_cluster_free: bool,
    is_symmetric: bool,               // self-involuting
    is_limited_transposition: bool,
    num_transpositions: u4,           // 1-12

    // Related set classes
    complement_forte: ForteNumber,    // complement's Forte number
    involution_prime: PitchClassSet,  // involution partner (may equal self)
};
```

### SetClassTable

Static table of all 336 OPTC-equivalence classes, precomputed at comptime.

```zig
pub const SetClassTable = struct {
    classes: [336]SetClass,
    // Index structures for fast lookup
    by_forte: std.AutoHashMap(ForteNumber, *const SetClass),
    by_prime_form: std.AutoHashMap(PitchClassSet, *const SetClass),
    by_cardinality: [10][]const *SetClass,  // index 3-9

    pub fn lookup(self: *const SetClassTable, set: PitchClassSet) ?*const SetClass {
        const pf = pcs.primeForm(set);
        return self.by_prime_form.get(pf);
    }

    pub fn lookupForte(self: *const SetClassTable, forte: ForteNumber) ?*const SetClass {
        return self.by_forte.get(forte);
    }

    pub fn clusterFree(self: *const SetClassTable) []const *SetClass {
        // Return slice of the 124 cluster-free classes
        // Precomputed at init
    }
};
```

### OPTIC_K_Group

Complement-paired groups (115 total for card 3-9).

```zig
pub const OPTIC_K_Group = struct {
    primary: ForteNumber,
    complement: ?ForteNumber,     // null if self-complementary
    primary_classes: []const SetClass,
    complement_classes: ?[]const SetClass,
};
```

### ClassificationFlags

Bitfield for compact storage of classification properties.

```zig
pub const ClassificationFlags = packed struct(u16) {
    cluster_free: bool,           // no 3+ consecutive semitones
    symmetric: bool,              // self-involuting
    limited_transposition: bool,  // fewer than 12 transpositions
    tritonic: bool,               // contains tritone (IC6 > 0)
    hemitonic: bool,              // contains semitone (IC1 > 0)
    quartal: bool,                // built from stacked 4ths/5ths
    tertiary: bool,               // built from stacked 3rds
    _padding: u9 = 0,
};
```

### EvennessInfo

Evenness-related measurements for a set class.

```zig
pub const EvennessInfo = struct {
    distance: f32,              // distance from perfectly even
    is_maximally_even: bool,    // closest to even for its cardinality
    is_perfectly_even: bool,    // exactly even (limited transposition)
    avg_vl_distance: f32,       // average voice-leading distance to transpositions
};
```

### ClusterInfo

Chromatic cluster analysis for a set class.

```zig
pub const ClusterInfo = struct {
    is_cluster_free: bool,
    cluster_pcs: PitchClassSet,     // pitch classes that are part of clusters
    non_cluster_pcs: PitchClassSet, // pitch classes outside clusters
    max_cluster_length: u4,         // longest consecutive run (0 if cluster-free)
};
```

## Static Data Summary

| Table | Count | Size (approx) |
|-------|-------|---------------|
| All PCS (2^12) | 4,096 | 8 KB (u12 x 4096) |
| OPTC classes | 336 | ~10 KB |
| OPTIC classes | 208 | ~6 KB |
| OPTIC/K groups | 115 | ~3 KB |
| Cluster-free subset | 124 | ~4 KB |
| Interval vectors | 336 | 2 KB |
| FC-components | 336 | 8 KB |
| Evenness data | 336 | 5 KB |
| **Total static** | | **~46 KB** |

All tables fit comfortably in L1 cache and can be computed at Zig compile time.

## Relationships

```
PitchClassSet (u12)
  |-- SetClass (OPTC: 336 classes)
  |     |-- ForteNumber (OPTIC: 208 classes)
  |     |     \-- OPTIC_K_Group (115 groups)
  |     |-- IntervalVector [6]u8
  |     |-- FCComponents [6]f32
  |     |-- EvennessInfo
  |     |-- ClusterInfo
  |     \-- ClassificationFlags
  |-- Scale (named PCS + type)
  |-- Chord (PCS + root + type)
  \-- Mode (PCS + root + parent scale)
```
