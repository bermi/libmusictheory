# Prime Form and Set Class Computation

> References: [Pitch Class Sets](../pitch-class-sets-and-set-theory.md)
> Source: `tmp/harmoniousapp.net/js-client/pitch-class-sets.js` functions: `lowestRot`, `rotations`, `numTranspositions`

## Overview

Algorithms for reducing pitch class sets to canonical forms under various equivalence relations (OPTC, OPTIC).

## Algorithms

### 1. All Rotations (12 Transpositions)

**Input**: 12-bit PCS
**Output**: Array of 12 values (all transpositions)

```
rotations(x):
    result = [x]
    for i in 1..11:
        result.append(rightshift(x, i))
    return result
```

**Complexity**: O(12) = O(1)

### 2. Prime Form (OPTC Equivalence)

**Input**: 12-bit PCS
**Output**: Numerically smallest rotation (the canonical representative)

```
prime_form(x):
    return min(rotations(x))
```

This is the "lowestRot" function in pitch-class-sets.js. It selects the transposition yielding the smallest integer.

**Complexity**: O(12) = O(1)

### 3. Forte Prime Form (OPTIC Equivalence)

**Input**: 12-bit PCS
**Output**: Minimum of prime_form(x) and prime_form(invert(x))

```
forte_prime(x):
    return min(prime_form(x), prime_form(invert(x)))
```

Includes involution — groups major/minor triads into same Forte class.

**Complexity**: O(24) = O(1)

### 4. Number of Distinct Transpositions

**Input**: 12-bit PCS
**Output**: Integer 1-12 (how many unique transpositions exist)

```
num_transpositions(x):
    seen = set()
    for r in rotations(x):
        pf = prime_form(r)
        seen.add(pf)
    return |seen|
```

Equivalently: count unique values in `rotations(x)`.

Sets with fewer than 12 transpositions are "modes of limited transposition."

**Complexity**: O(12) = O(1)

### 5. Is Limited Transposition?

**Input**: 12-bit PCS
**Output**: Boolean

```
is_limited_transposition(x):
    pf = prime_form(x)
    for k in 1..11:
        if leftshift(pf, k) == pf:
            return true
    return false
```

**Complexity**: O(12) = O(1)

### 6. Symmetry Detection (Self-Involuting)

**Input**: 12-bit PCS
**Output**: Boolean — is the set unchanged by involution (up to transposition)?

```
is_symmetric(x):
    return prime_form(x) == prime_form(invert(x))
```

Symmetric sets appear identical when clock diagram is mirrored.

**Complexity**: O(24) = O(1)

### 7. Set Class Enumeration

**Input**: Cardinality range (typically 3-9)
**Output**: All OPTC-equivalence classes (336 total for card 3-9)

```
enumerate_set_classes(min_card, max_card):
    classes = set()
    for x in 0..4095:
        if min_card <= popcount(x) <= max_card:
            pf = prime_form(x)
            classes.add(pf)
    return sorted(classes)
```

Optimization: only iterate PCS with bit 0 set (OTC representatives), yielding 2048 candidates that reduce to 336.

**Complexity**: O(4096 * 12) — precomputable static table

### 8. Forte Number Assignment

**Input**: Set of all OPTC classes
**Output**: Mapping from Forte prime form → Forte number string

```
assign_forte_numbers(optc_classes):
    // Group by cardinality, then by forte_prime
    for card in 3..9:
        card_classes = [c for c in optc_classes if popcount(c) == card]
        // Sort by Forte's original ordering
        for i, c in enumerate(sorted(card_classes)):
            forte_map[c] = "{card}-{i+1}"
    return forte_map
```

Note: Forte's original ordering is a historical convention; the exact sort order must match published tables.

**Complexity**: Precomputed lookup table

### 9. OPTIC/K Grouping (Complement Pairs)

**Input**: Set of all Forte classes (208)
**Output**: 115 groups pairing complements

```
optic_k_groups(forte_classes):
    groups = []
    used = set()
    for c in forte_classes:
        if c in used: continue
        comp = complement(c)
        comp_forte = forte_prime(comp)
        if comp_forte != c and comp_forte not in used:
            groups.append((c, comp_forte))
            used.add(c)
            used.add(comp_forte)
        else:
            groups.append((c,))
            used.add(c)
    return groups
```

Self-complementary hexachords (cardinality 6) pair with themselves.

**Complexity**: O(208) = O(1) — precomputed table

## Data Structures Used

- `SetClass`: struct containing prime_form (u12), forte_number, cardinality, is_symmetric flag
- `ForteNumber`: struct with cardinality (u4) and ordinal (u8)
- Static lookup table: `[336]SetClass` indexed by prime form

## Dependencies

- [Pitch Class Set Operations](pitch-class-set-operations.md)
