# Pitch Class Set Operations

> References: [Pitch and Intervals](../pitch-and-intervals.md), [Pitch Class Sets](../pitch-class-sets-and-set-theory.md)
> Source: `tmp/harmoniousapp.net/js-client/pitch-class-sets.js` functions: `subbits`, `leftshift`, `rightshift`, `bitsset`, `tolist`, `fromlist`

## Overview

Core bitwise operations on 12-bit integer pitch class sets (0-4095). These form the foundation for all higher-level algorithms.

## Algorithms

### 1. PCS from List

**Input**: Array of pitch classes (0-11)
**Output**: 12-bit integer

```
fromlist(pcs):
    result = 0
    for pc in pcs:
        result |= (1 << pc)
    return result
```

**Complexity**: O(n) where n = number of pitch classes

### 2. PCS to List

**Input**: 12-bit integer
**Output**: Sorted array of pitch classes

```
tolist(x):
    result = []
    for i in 0..11:
        if x & (1 << i):
            result.append(i)
    return result
```

**Complexity**: O(12) = O(1)

### 3. Cardinality (Popcount)

**Input**: 12-bit integer
**Output**: Number of set bits (0-12)

```
bitsset(x):
    count = 0
    while x > 0:
        count += x & 1
        x >>= 1
    return count
```

Zig optimization: use `@popCount(x)` builtin.

**Complexity**: O(1) with hardware popcount

### 4. Transposition Up (Leftshift)

**Input**: 12-bit PCS, number of semitones n
**Output**: 12-bit PCS rotated left by n

```
leftshift(x, n=1):
    return ((x << n) | (x >> (12 - n))) & 0xFFF
```

Equivalent to transposing all pitch classes up by n semitones (mod 12).

**Complexity**: O(1)

### 5. Transposition Down (Rightshift)

**Input**: 12-bit PCS, number of semitones n
**Output**: 12-bit PCS rotated right by n

```
rightshift(x, n=1):
    return (x >> n) | ((x & ((1 << n) - 1)) << (12 - n))
```

**Complexity**: O(1)

### 6. Involution (Inversion around axis)

**Input**: 12-bit PCS
**Output**: 12-bit PCS with each pc n replaced by (12-n) % 12

```
invert(x):
    result = 0
    for i in 0..11:
        if x & (1 << i):
            result |= (1 << ((12 - i) % 12))
    return result
```

Note: Bit 0 always maps to bit 0 (pitch class 0 is self-inverse). The operation effectively reverses the bit pattern (bit 1 ↔ bit 11, bit 2 ↔ bit 10, etc.).

**Complexity**: O(12) = O(1)

### 7. Complement

**Input**: 12-bit PCS
**Output**: 12-bit PCS with all bits flipped

```
complement(x):
    return ~x & 0xFFF
```

**Complexity**: O(1)

### 8. Subset Test

**Input**: Two 12-bit PCS (small, big)
**Output**: Boolean — is small a subset of big?

```
is_subset(small, big):
    return (small & big) == small
```

**Complexity**: O(1)

### 9. Transposition-Aware Subset Test (hasSub)

**Input**: Two 12-bit PCS (small, big)
**Output**: Boolean — is any transposition of small a subset of big?

```
has_sub(small, big):
    for k in 0..11:
        if is_subset(leftshift(small, k), big):
            return true
    return false
```

**Complexity**: O(12) = O(1)

### 10. Hamming Distance

**Input**: Two 12-bit PCS
**Output**: Number of differing pitch classes (0-12)

```
hamming(a, b):
    return popcount(a ^ b)
```

**Complexity**: O(1)

### 11. Least Error Match

**Input**: Target 12-bit PCS, array of candidate PCS
**Output**: Candidate with minimum Hamming distance to target

```
least_error(candidates, target):
    best = candidates[0]
    best_dist = hamming(best, target)
    for c in candidates[1..]:
        d = hamming(c, target)
        if d < best_dist:
            best = c
            best_dist = d
    return best
```

**Complexity**: O(n) where n = number of candidates

### 12. Pretty-Print (Set Theory Notation)

**Input**: 12-bit PCS
**Output**: String using digits 0-9, t=10, e=11

```
pretty(x):
    chars = "0123456789te"
    result = ""
    for i in 0..11:
        if x & (1 << i):
            result += chars[i]
    return result
```

**Complexity**: O(12) = O(1)

## Data Structures Used

- `PitchClassSet` (u12): the fundamental 12-bit type
- `PitchClass` (u4): single value 0-11

## Dependencies

None — these are leaf-level primitives.
