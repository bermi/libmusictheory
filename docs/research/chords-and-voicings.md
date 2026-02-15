# Chords, Voicings, and Chord Types

> Source: `tmp/harmoniousapp.net/p/fc/Chords.html`, `tmp/harmoniousapp.net/p/*/Chords-By-Name.html`, `tmp/harmoniousapp.net/p/*/Chords-for-Keyboard.html`,
> `tmp/harmoniousapp.net/p/*/Chords-for-Guitar.html`, `tmp/harmoniousapp.net/p/e7/Leave-Out-Notes.html`, `tmp/harmoniousapp.net/p/69/The-Game.html`,
> Glossary: Chord, Chord Type, Chord Formula, Root, Triad, Augmented, Diminished,
> Suspended, Consonance, Shell Chords, Slash Chords, Inversion

## Definitions

**Chord**: A collection of notes played simultaneously, emphasizing a root.
Named by root + chord type (e.g., "C Major Seventh").

**Chord Type** (OTC equivalence): same intervals from root, any root.
Defined by interval formula: R 3 5 7 etc. Up to 12 transpositions per type.

**Chord Formula**: transposition-equivalent interval listing. Harmonious uses "R" for root (not "1").

## Chord Categories

### Triads (3 notes)

| Name | Formula | Interval Stack | Set Class |
|------|---------|---------------|-----------|
| Major | R 3 5 | M3 + m3 | 3-11 [047] |
| Minor | R b3 5 | m3 + M3 | 3-11 [037] |
| Diminished | R b3 b5 | m3 + m3 | 3-10 [036] |
| Augmented | R 3 #5 | M3 + M3 | 3-12 [048] |
| Suspended 2 | R 2 5 | M2 + P4 | 3-9 [027] |
| Suspended 4 | R 4 5 | P4 + M2 | 3-9 [057] |

### Seventh Chords (4 notes)

| Name | Formula | Interval Stack | Set Class |
|------|---------|---------------|-----------|
| Major 7th | R 3 5 7 | M3+m3+M3 | 4-20 |
| Dominant 7th | R 3 5 b7 | M3+m3+m3 | 4-27 |
| Minor 7th | R b3 5 b7 | m3+M3+m3 | 4-26 |
| Minor Major 7th | R b3 5 7 | m3+M3+M3 | 4-19 |
| Half-Diminished 7th | R b3 b5 b7 | m3+m3+M3 | 4-27 |
| Diminished 7th | R b3 b5 bb7 | m3+m3+m3 | 4-28 |
| Augmented Major 7th | R 3 #5 7 | M3+M3+m3 | 4-19 |
| Augmented Dominant 7th | R 3 #5 b7 | M3+M3+m2 | 4-24 |
| Suspended 7th | R 4 5 b7 | -- | 4-23 |

### Extended Chords (5+ notes)
- **9th chords**: 7th + 9th (5 notes)
- **11th chords**: 9th + 11th (6 notes, often omit 3rd or 5th)
- **13th chords**: 11th + 13th (7 notes, many omissions typical)
- **Altered dominants**: b5, #5, b9, #9 and combinations
- **Lydian chords**: include #11 (from Lydian Dominant mode)
- **Add chords**: triad + one extension (no 7th): add9, add6, add6/9

### Special Categories
- **Shell chords**: 3-note voicings of 7th chords (root + 3rd + 7th, omit 5th)
  - 3rd and 7th reveal chord quality; 5th is a natural overtone
  - dim 7 no 5 and min 6 no 5 share voicings but differ in function
- **Rootless voicings**: omit root (bass player covers it)
- **Slash chords**: "Chord/Bass" notation (e.g., C/A = A min 7)
- **Power chord**: root + 5th only
- **Augmented 6th**: French (R 3 #4 #6), German (R 3 5 #6), Italian (R 3 #6)

## Chord Inversions

- Root position: root is lowest note
- First inversion: 3rd is lowest
- Second inversion: 5th is lowest
- Third inversion: 7th is lowest (for 7th chords)
- Inversions are OC-equivalent (same root, same notes, different order)
- NOT to be confused with involution (set-theoretic inversion)

## Slash Chord Reference Pattern

The site generates comprehensive slash chord tables for each root:
- "Over C" table: all chords with C as bass note → resulting full chord name + inversion type
- "Upper C" table: all C-rooted upper structures over various bass notes

Examples:
- Db/C = Db Maj 7 (Third Inversion)
- Eb/C = C min 7 (Root Position)
- F/C = F Maj (Second Inversion)
- G/C = C Maj 9 no 3 (Root Position no 3)

## The "Game" Algorithm (Exhaustive Chord Reference)

### Goal
Match all cluster-free OTC-equivalent objects against the 17 modes to produce a complete chord reference.

### Algorithm
1. Enumerate all 2^12 = 4,096 pitch class sets
2. Restrict to those including pitch class 0 (as moveable root): 2^11 = 2,048
3. Restrict to cardinality 3-9: 1,969 OTC-equivalent objects
4. Filter to cluster-free: **560** objects
5. Filter to subsets of the 17 modes: **479** objects
6. For each of these 479 objects × 17 modes, check subset relationship
7. Extract chord formulas from mode formulas (each interval maps to a degree name)
8. Result: ~1,000 chord-mode combinations to catalog

### The Ambiguity Problem
A given pitch class interval (e.g., 6 semitones) can be named multiple ways (#4 or b5).
Solution: start from known mode formulas and match, rather than guess names from intervals.

### The 17 Mode Formulas

| Scale | Mode | Full Formula |
|-------|------|-------------|
| Diatonic | Lydian | R 3 5 7 9 #11 13 |
| Diatonic | Ionian | R 3 5 7 9 11 13 |
| Diatonic | Mixolydian | R 3 5 b7 9 11 13 |
| Diatonic | Dorian | R b3 5 b7 9 11 13 |
| Diatonic | Aeolian | R b3 5 b7 9 11 b13 |
| Diatonic | Phrygian | R b3 5 b7 b9 11 b13 |
| Diatonic | Locrian | R b3 b5 b7 b9 11 b13 |
| Acoustic | Lydian Aug | R 3 #5 7 9 #11 13 |
| Acoustic | Melodic Minor | R b3 5 7 9 11 13 |
| Acoustic | Lydian Dom | R 3 5 b7 9 #11 13 |
| Acoustic | Dorian b2 | R b3 5 b7 b9 11 13 |
| Acoustic | Mixolydian b6 | R 3 5 b7 9 11 b13 |
| Acoustic | Locrian ♮2 | R b3 b5 b7 9 11 b13 |
| Acoustic | Super Locrian | R b3 3 b5 #5 b7 b9 |
| Whole-tone | Whole-Tone | R 3 b5 #5 b7 9 |
| Diminished | Half/Whole | R 3 b5 5 b7 b9 #9 13 |
| Diminished | Whole/Half | R b3 b5 #5 7 9 11 13 |

## Chord-Scale Compatibility

A chord is compatible with a mode if:
1. All chord tones are pitch-class subsets of the mode
2. No chord tone + an adjacent scale tone creates an avoid-note situation
3. Available tensions = scale tones not flagged as avoid notes

### Avoid Notes
A scale tone that is exactly one semitone above a chord tone.
Creates a chromatic cluster when sustained. Used as passing tones only.

**Lydian is the only diatonic mode with NO avoid notes** — all 7 scale degrees are available.

## Note Omission and Voicing

### Omission Rationale
- 5th: most commonly omitted (present as natural harmonic of root)
- Root: omitted in rootless voicings (bass instrument covers it)
- 3rd: sometimes omitted in sus or quartal voicings
- Removing notes changes evenness/cardinality of the chord

### Voicing Types
- Close voicing: all notes within one octave
- Open voicing: spread across octaves
- Drop voicings: move specific voices down an octave
- Shell voicing: root + 3rd + 7th only

## Guitar-Specific Chord Concepts

### Standard Tuning: E2 A2 D3 G3 B3 E4
MIDI: [40, 45, 50, 55, 59, 64]
String intervals: P4, P4, P4, M3, P4

### CAGED System
5 open chord shapes (C, A, G, E, D) as moveable barre chords.
Each root has 5 positions covering the entire fretboard.

### Fret Position to MIDI: `midi = string_open[i] + fret`
### Constraints: max 6 notes, ~4-fret hand span, muting for unneeded strings

## Algorithms Required

1. Chord formula to pitch class set: parse formula string → set of pitch classes
2. Pitch class set + root → chord name lookup (reverse of formula)
3. Chord-scale compatibility test (subset + avoid note check)
4. Inversion computation (rotate lowest note up an octave)
5. Shell chord extraction (keep root + 3rd + 7th)
6. Available tensions enumeration for any chord in any mode
7. Slash chord decomposition (upper structure + bass note)
8. Guitar voicing generation (fret positions for 6 strings within hand span)
9. Exhaustive OTC enumeration (The Game algorithm)
10. Chord type naming from mode context
