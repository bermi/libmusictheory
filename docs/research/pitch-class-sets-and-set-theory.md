# Pitch Class Sets and Musical Set Theory

> Source: `tmp/harmoniousapp.net/p/71/Set-Classes.html`, `tmp/harmoniousapp.net/p/0b/Clocks-Pitch-Classes.html`, `tmp/harmoniousapp.net/p/df/Grouping-Clocks.html`,
> `tmp/harmoniousapp.net/p/ec/Equivalence-Groups.html`, `tmp/harmoniousapp.net/p/d0/glossary-atonal-theory.html`,
> Glossary: Pitch Class, Set Class, Prime Form, Forte Number, Interval Content,
> Interval Class, Z-Relation, M-Relation, Complement, Symmetry, Involution,
> Cardinality, Atonal Theory, Clock Diagram, all OPTIC equivalences

## Pitch Class Sets

### Representation
- An unordered collection of pitch classes (no duplicates, no octave information)
- 2^12 = 4,096 possible pitch class sets (including empty set)
- Compact 12-bit integer representation (0-4095): bit n = 1 iff pitch class n is present
- Example: C major triad {0,4,7} = `(1<<0)|(1<<4)|(1<<7)` = 0b000010010001 = 145

### Operations on 12-bit Integers
- **Cardinality** (popcount): count bits set to 1
- **Subset test**: `(small & big) == small`
- **Union**: `a | b`
- **Intersection**: `a & b`
- **Complement**: `~set & 0xFFF`
- **Transposition up by 1** (left shift): `((x << 1) | (x >> 11)) & 0xFFF`
- **Transposition down by 1** (right shift): `((x >> 1) | ((x & 1) << 11))`
- **Transposition by n**: apply left/right shift n times
- **Inversion/Involution**: for each pc x in set, replace with `(12-x) % 12`
- **Hamming distance**: `popcount(a ^ b)` = number of differing pitch classes

### Conversion
- Integer to list: iterate bits 0-11, collect positions of set bits
- List to integer: `OR` together `(1 << pc)` for each pc in list
- Pretty-print: digits 0-9, t=10, e=11 (e.g., `047` for major triad, `013568t` for diatonic)

## The OPTIC Equivalence Framework (Tymoczko / Callender et al. 2008)

Progressive levels of equivalence, reducing the musical object space:

| Level | Meaning | Count (card 3-9) |
|-------|---------|-----------------|
| O (Octave) | Same notes, different octave | hundreds of thousands |
| OC | Same pitch classes + same root | 23,628 |
| OPC | Same unordered pitch classes | 3,938 |
| OTC | Same intervals relative to root | 1,969 |
| OPTC | Same prime form | **336** |
| OPTIC | Same Forte number (+ involution) | 208 |
| OPTIC/K | Same + complementarity | **115** |

### Individual Equivalences
- **O (Octave)**: notes in different registers treated as same
- **P (Permutation)**: notes in different order treated as same (unordered set)
- **T (Transposition)**: same interval pattern at any starting pitch
- **I (Involution/Inversion)**: mirror-image interval patterns treated as same
- **C (Cardinality)**: duplicate pitch classes ignored
- **K (Complementarity)**: set and its complement grouped (non-standard, Harmonious-specific)

### Key Equivalence Levels Used
- **OC**: a specific voicing with root (e.g., C Maj root position vs C Maj first inversion)
- **OPC**: a named chord = unordered pitch class set (e.g., "C Major" regardless of inversion)
- **OTC**: a chord type = intervals from root (e.g., "Major Triad" = R 3 5 in any key)
- **OPTC**: prime form / set class (e.g., [0,4,7] = all major AND minor triads if symmetric, or just major)
- **OPTIC**: Forte number (e.g., 3-11 = major AND minor triads together, since they're related by involution)

## Prime Form and Set Classes

### Prime Form Computation
The numerically smallest value among all 12 transpositions of the 12-bit integer:
```
prime_form(x) = min(x, rightshift(x), rightshift^2(x), ..., rightshift^11(x))
```
This yields 336 distinct set classes for cardinality 3-9.

### Forte Prime Form (includes involution)
```
forte_prime(x) = min(prime_form(x), prime_form(invert(x)))
```
This yields 208 distinct Forte numbers.

### Forte Number
- Notation: `cardinality-ordinal` (e.g., 3-11, 4-28, 7-35)
- Z prefix for Z-related pairs (same interval content, not related by involution)
- Allen Forte's original catalog ordering

### Number of Distinct Transpositions
- Most sets: 12 distinct transpositions
- Perfectly even sets have fewer: whole-tone=2, dim7=3, aug=4, octatonic=3
- Limited transposition count = 12 / (orbit size under rotation)
- A set has limited transposition iff `leftshift^k(x) == x` for some k < 12

## Interval Content and Related Measures

### Interval Vector (Forte)
6-number vector [IC1, IC2, IC3, IC4, IC5, IC6] counting pairs of each interval class.
- Major triad: <001110> (one minor 3rd, one major 3rd, one perfect 4th/5th)
- Diatonic scale: <254361> (two semitones, five whole tones, four minor 3rds, three major 3rds, six 4ths/5ths, one tritone)

### Lewin-Quinn FC-Components (Fourier Analysis)
Six numbers (FC1-FC6) measuring pitch-class-set imbalance relative to each interval class.

**Algorithm**: For each interval class k (1-6):
1. For each pitch class p in the set, compute a 2D vector at angle `p * k * 30°`
2. Sum all vectors
3. FC_k = length of resulting vector

**Properties**:
- Complementary set classes share identical FC1-FC6 values
- M-related set classes swap FC1 and FC5 (keeping FC2, FC3, FC4, FC6)
- Can be extended to any N-TET system
- The 6D complex Fourier space provides a metric for comparing any two pitch class sets

### Z-Relation
Two set classes with identical interval vectors but NOT related by transposition or involution.
- "Zygotic" pairs (Forte's term)
- For hexachords (6 notes): Z-related pairs are always complements

### M-Relation (M5/M7 Multiplication)
- Transform: replace each pitch class n with `(n * 5) % 12` (or `(n * 7) % 12`)
- Effect: swaps semitones ↔ fourths in interval content
- Mathematical basis: 1,5,7,11 are generators of Z_12 (coprime to 12)
- M-relation is its own inverse (applying twice returns to original)
- Visual: converts circle of fifths to chromatic circle and back

### Complement
- The complement of set S is {0..11} \ S (all pitch classes NOT in S)
- Bitwise: `~set & 0xFFF`
- Complements share identical FC-components
- Examples: pentatonic (5-35) ↔ diatonic (7-35), black keys ↔ white keys
- Whole-tone (6-35) and double augmented hexatonic (6-20) are their own complements
- Lower-cardinality set is always a subset of some transposition of its complement

### Involution (Inverse)
- Inversion: replace each pc n with `(12-n) % 12`
- On clock diagram: mirror image
- Major triads ↔ minor triads are related by involution
- NOT the same as registral inversion (reordering notes)
- Preserves interval content (same vector, different interval order)
- Self-involuting sets are called **symmetric** (e.g., diatonic scale)

### Symmetry
A set class is symmetric if involution equals itself (up to transposition).
Clock diagrams make symmetry visually obvious (palindromic patterns).

## Classification Properties

| Property | Definition | Count (of 336) |
|----------|-----------|---------------|
| Cluster-free | No 3+ consecutive semitones | 124 |
| Chromatic | Has 3+ consecutive semitones | 212 |
| Tritonic | Contains tritone (IC6) | varies |
| Atritonic | No tritone | varies |
| Hemitonic | Contains semitone (IC1) | varies |
| Anhemitonic | No semitone | varies |
| Cohemitonic | Has chromatic cluster | = Chromatic |
| Ancohemitonic | No chromatic cluster | = Cluster-free |
| Quartal | Built from stacked 4ths/5ths | varies |
| Tertiary | Built from stacked 3rds | varies |
| Limited transposition | Fewer than 12 distinct transpositions | ~20 |
| Symmetric | Self-involuting | varies |

## Clock Diagrams

### Colored Clock (OPC)
- 12 circles at clock positions (C at 12 o'clock, clockwise chromatic)
- Filled/colored = pitch class present; white = absent
- Each color unique per pitch class (12-color scheme)
- Position formula: cx = 50 + 42*sin(n*30°), cy = 50 - 42*cos(n*30°)

### Black-and-White Clock (OPTC)
- Same layout but monochrome
- Filled black = in prime form; gray = cluster content; white = absent
- Represents the entire set class (all transpositions collapsed)
- Center label shows prime form digits

## The Set Classes Table

Generated data for 115 rows (OPTIC/K equivalence), showing:
- Forte number (both sides: cardinality C and 12-C complement)
- 1-2 clock diagrams per side (1 if symmetric, 2 if distinct involution pair)
- Evenness distance (√ notation with color coding)
- FC1 through FC6 values (color coded)
- Sortable by any column

## Chromatic Cluster Detection

### Algorithm (from pitch-class-sets.js)
Test all 12 rotations of {0,1,2} (3 consecutive semitones) as subsets:
```
clusters = [{0,1,2}, {1,2,3}, {2,3,4}, ..., {10,11,0}, {11,0,1}]
has_cluster(set) = any(is_subset(cluster, set) for cluster in clusters)
```

### Greedy Cluster Extraction
For measuring cluster content, greedily extract the longest consecutive runs:
```
for run_length in [9, 8, 7, 6, 5, 4, 3]:
    for each rotation of run_length consecutive semitones:
        if is_subset(run, remaining):
            extract it (XOR out)
cluster_content = original XOR remaining
```

## Subset Relationships

### Leave-One-Out (Parent Set Classes)
Given a set class, generate all possible cardinality-(n-1) subsets:
```
for each pitch class in set:
    remove it, compute prime form of result
deduplicate results
```

### Has-Sub (Transposition-Aware Subset Test)
Test if any transposition of `small` is a subset of `big`:
```
for k in 0..11:
    if is_subset(transpose(small, k), big): return true
return false
```

### Hamming Distance (Set Similarity)
```
distance(a, b) = popcount(a XOR b)
least_error(choices, target) = argmin(popcount(choice XOR target) for choice in choices)
```
