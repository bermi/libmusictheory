# Interval Vector and Fourier Component Computation

> References: [Pitch Class Sets](../pitch-class-sets-and-set-theory.md)
> Source: `tmp/harmoniousapp.net/p/71/Set-Classes.html` (FC column data), Glossary: Interval Content, Lewin-Quinn FC-Components

## Overview

Two complementary ways to measure the interval content of a pitch class set:
1. **Interval Vector** (Forte): counts pairs of each interval class
2. **FC-Components** (Lewin-Quinn): Fourier magnitudes measuring imbalance per interval class

## Algorithms

### 1. Interval Vector

**Input**: 12-bit PCS
**Output**: 6-element array [IC1, IC2, IC3, IC4, IC5, IC6]

```
interval_vector(x):
    pcs = tolist(x)
    iv = [0, 0, 0, 0, 0, 0]
    for i in 0..len(pcs)-2:
        for j in i+1..len(pcs)-1:
            diff = abs(pcs[j] - pcs[i])
            ic = min(diff, 12 - diff)  // interval class = 1..6
            iv[ic - 1] += 1
    return iv
```

**Complexity**: O(n²) where n = cardinality, max O(36) for 9-note sets = O(1)

### 2. Lewin-Quinn FC-Components

**Input**: 12-bit PCS
**Output**: 6 floating-point magnitudes [FC1, FC2, FC3, FC4, FC5, FC6]

```
fc_components(x):
    pcs = tolist(x)
    fc = [0.0; 6]
    for k in 1..6:
        sum_x = 0.0
        sum_y = 0.0
        for p in pcs:
            angle = p * k * (PI / 6)  // p * k * 30° in radians
            sum_x += cos(angle)
            sum_y += sin(angle)
        fc[k-1] = sqrt(sum_x * sum_x + sum_y * sum_y)
    return fc
```

Each FC_k measures how far the pitch class set deviates from perfect balance when projected onto the k-th harmonic of the chromatic circle.

**Complexity**: O(6n) where n = cardinality = O(1)

### 3. FC-Component Properties Verification

```
// Complement invariance: FC(x) == FC(complement(x))
verify_complement_invariance(x):
    assert fc_components(x) == fc_components(complement(x))

// M-relation: swaps FC1 ↔ FC5
verify_m_relation(x):
    fc_orig = fc_components(x)
    fc_m5 = fc_components(m5_transform(x))
    assert fc_orig[0] ≈ fc_m5[4]  // FC1 ↔ FC5
    assert fc_orig[4] ≈ fc_m5[0]
    assert fc_orig[1] ≈ fc_m5[1]  // FC2, FC3, FC4, FC6 unchanged
    assert fc_orig[2] ≈ fc_m5[2]
    assert fc_orig[3] ≈ fc_m5[3]
    assert fc_orig[5] ≈ fc_m5[5]
```

### 4. Z-Relation Detection

**Input**: Two 12-bit PCS
**Output**: Boolean — same interval vector but not related by T or TI?

```
is_z_related(a, b):
    if interval_vector(a) != interval_vector(b):
        return false
    // Check if related by transposition
    pf_a = prime_form(a)
    for k in 0..11:
        if prime_form(leftshift(b, k)) == pf_a:
            return false
    // Check if related by involution + transposition
    inv_b = invert(b)
    for k in 0..11:
        if prime_form(leftshift(inv_b, k)) == pf_a:
            return false
    return true
```

**Complexity**: O(24) = O(1)

### 5. M5/M7 Transform

**Input**: 12-bit PCS
**Output**: 12-bit PCS with each pc multiplied by 5 mod 12

```
m5_transform(x):
    result = 0
    for i in 0..11:
        if x & (1 << i):
            result |= (1 << ((i * 5) % 12))
    return result

m7_transform(x):
    result = 0
    for i in 0..11:
        if x & (1 << i):
            result |= (1 << ((i * 7) % 12))
    return result
```

M5 and M7 are inverses of each other. The permutation is:
- M5: 0→0, 1→5, 2→10, 3→3, 4→8, 5→1, 6→6, 7→11, 8→4, 9→9, 10→2, 11→7
- This swaps the chromatic circle and circle of fifths representations

**Complexity**: O(12) = O(1)

### 6. M-Relation Detection

**Input**: Two 12-bit PCS
**Output**: Boolean — is one the M5 transform of the other (up to transposition)?

```
is_m_related(a, b):
    m5_a = m5_transform(a)
    return prime_form(m5_a) == prime_form(b) or
           forte_prime(m5_a) == forte_prime(b)
```

**Complexity**: O(24) = O(1)

## Data Structures Used

- `IntervalVector`: [6]u8
- `FCComponents`: [6]f32
- Precomputed static tables for all 336 set classes

## Dependencies

- [Pitch Class Set Operations](pitch-class-set-operations.md)
- [Prime Form and Set Class](prime-form-and-set-class.md)
