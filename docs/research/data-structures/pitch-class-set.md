# Pitch Class Set Data Structure

> References: [Pitch Class Sets](../pitch-class-sets-and-set-theory.md)
> Used by: Nearly all algorithms — the central data type

## Core Type

### PitchClassSet

A 12-bit integer representing an unordered collection of pitch classes. This is the most important data type in the entire library.

```zig
pub const PitchClassSet = u12; // 0-4095, each bit represents one pitch class

pub const pcs = struct {
    pub const EMPTY: PitchClassSet = 0;
    pub const CHROMATIC: PitchClassSet = 0xFFF; // all 12 pitch classes

    // Common sets
    pub const C_MAJOR_TRIAD: PitchClassSet = 0b000010010001; // {0,4,7} = 145
    pub const C_MINOR_TRIAD: PitchClassSet = 0b000010001001; // {0,3,7} = 137
    pub const DIATONIC: PitchClassSet = 0b101010110101;       // 7-35
    pub const ACOUSTIC: PitchClassSet = 0b101001110101;       // 7-34
    pub const WHOLE_TONE: PitchClassSet = 0b010101010101;     // 6-35
    pub const DIMINISHED: PitchClassSet = 0b011011011011;     // 8-28
    pub const PENTATONIC: PitchClassSet = 0b000010010101;     // 5-35

    /// Create from pitch class list
    pub fn fromList(pitch_classes: []const PitchClass) PitchClassSet {
        var result: PitchClassSet = 0;
        for (pitch_classes) |p| {
            result |= @as(PitchClassSet, 1) << @intCast(p);
        }
        return result;
    }

    /// Convert to sorted list of pitch classes
    pub fn toList(set: PitchClassSet, buf: *[12]PitchClass) []PitchClass {
        var count: usize = 0;
        for (0..12) |i| {
            if (set & (@as(PitchClassSet, 1) << @intCast(i)) != 0) {
                buf[count] = @intCast(i);
                count += 1;
            }
        }
        return buf[0..count];
    }

    /// Cardinality (number of pitch classes)
    pub fn cardinality(set: PitchClassSet) u4 {
        return @popCount(set);
    }

    /// Transpose up by n semitones (circular left shift)
    pub fn transpose(set: PitchClassSet, n: u4) PitchClassSet {
        const shift = @as(u4, n % 12);
        return ((set << shift) | (set >> @intCast(12 - shift))) & 0xFFF;
    }

    /// Transpose down by n semitones (circular right shift)
    pub fn transposeDown(set: PitchClassSet, n: u4) PitchClassSet {
        const shift = @as(u4, n % 12);
        return (set >> shift) | ((set & ((@as(PitchClassSet, 1) << shift) - 1)) << @intCast(12 - shift));
    }

    /// Inversion (replace each pc n with (12-n) % 12)
    pub fn invert(set: PitchClassSet) PitchClassSet {
        var result: PitchClassSet = 0;
        for (0..12) |i| {
            if (set & (@as(PitchClassSet, 1) << @intCast(i)) != 0) {
                result |= @as(PitchClassSet, 1) << @intCast((12 - i) % 12);
            }
        }
        return result;
    }

    /// Complement (all pitch classes NOT in set)
    pub fn complement(set: PitchClassSet) PitchClassSet {
        return ~set & 0xFFF;
    }

    /// Subset test
    pub fn isSubsetOf(small: PitchClassSet, big: PitchClassSet) bool {
        return (small & big) == small;
    }

    /// Hamming distance
    pub fn hammingDistance(a: PitchClassSet, b: PitchClassSet) u4 {
        return @popCount(a ^ b);
    }

    /// Prime form (smallest rotation = OPTC canonical)
    pub fn primeForm(set: PitchClassSet) PitchClassSet {
        var min_val = set;
        var rotated = set;
        for (1..12) |_| {
            rotated = transposeDown(rotated, 1);
            if (rotated < min_val) min_val = rotated;
        }
        return min_val;
    }

    /// Forte prime form (smallest of prime form and inverted prime form)
    pub fn fortePrime(set: PitchClassSet) PitchClassSet {
        return @min(primeForm(set), primeForm(invert(set)));
    }

    /// Check for chromatic cluster (3+ consecutive semitones)
    pub fn hasCluster(set: PitchClassSet) bool {
        const cluster3: PitchClassSet = 0b111; // {0,1,2}
        for (0..12) |k| {
            const mask = transpose(cluster3, @intCast(k));
            if (set & mask == mask) return true;
        }
        return false;
    }

    /// Pretty-print in set theory notation
    pub fn format(set: PitchClassSet, buf: *[12]u8) []u8 {
        const chars = "0123456789te";
        var count: usize = 0;
        for (0..12) |i| {
            if (set & (@as(PitchClassSet, 1) << @intCast(i)) != 0) {
                buf[count] = chars[i];
                count += 1;
            }
        }
        return buf[0..count];
    }
};
```

## Design Rationale

### Why u12?

- Exactly 12 pitch classes in Western music
- All set operations map to single CPU instructions (AND, OR, XOR, NOT, shift, popcount)
- Compact: 2 bytes per set, fits in a register
- All 4,096 possible sets can be stored in a small lookup table
- Transposition = circular bit rotation (not addition mod 12 on each element)

### Why Not a Bitset or Array?

- A `std.StaticBitSet(12)` would add overhead for operations we can do in one instruction
- An array `[12]bool` would use 12x more memory and require loops for set operations
- The integer representation makes precomputation trivial: iterate 0..4095

### Zig-Specific Considerations

- `u12` is a valid Zig integer type (arbitrary bit-width integers)
- `@popCount` gives hardware-accelerated cardinality
- Shift operators work naturally on u12
- Compile-time evaluation (`comptime`) can precompute all 336 set classes at build time

## Memory Layout for Lookup Tables

```zig
/// All 336 OPTC set classes (card 3-9), precomputed at comptime
pub const SET_CLASSES: [336]PitchClassSet = comptime blk: {
    var result: [336]PitchClassSet = undefined;
    var count: usize = 0;
    for (0..4096) |x| {
        const set: PitchClassSet = @intCast(x);
        const card = @popCount(set);
        if (card >= 3 and card <= 9) {
            const pf = pcs.primeForm(set);
            // Check if we've seen this prime form
            var found = false;
            for (result[0..count]) |existing| {
                if (existing == pf) { found = true; break; }
            }
            if (!found) {
                result[count] = pf;
                count += 1;
            }
        }
    }
    break :blk result;
};
```

## Relationships to Other Types

- Contains: `PitchClass` values (implicitly via bits)
- Used by: `SetClass`, `Scale`, `Chord`, `Mode`, `Key` (all built on PCS)
- Operations feed into: `IntervalVector`, `FCComponents`, `EvennessInfo`
