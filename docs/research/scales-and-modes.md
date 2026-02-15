# Scales, Modes, and the Four Scale Types

> Source: `tmp/harmoniousapp.net/p/34/Scales.html`, `tmp/harmoniousapp.net/p/39/Modes.html`, `tmp/harmoniousapp.net/p/0c/Beyond-Diatonic.html`,
> `tmp/harmoniousapp.net/p/b9/Diatonic-Modes-Chords.html`, `tmp/harmoniousapp.net/p/bc/Top-Down-View.html`,
> Glossary: Scale, Mode, Diatonic, Acoustic, Harmonic Minor, Harmonic Major,
> Pentatonic, Whole-Tone, Chromatic, Octatonic, Double Augmented Hexatonic, Other Scales

## Definitions

**Scale**: An unordered collection of 5-8 pitch classes from which chords and modes are built.
A 7-note scale has 7 modes (one rooted on each scale degree).

**Mode**: A scale with a designated root note. The interval pattern from the root defines the mode's character. Jazz theory generalizes modes: their notes can be played simultaneously, blurring chord/scale distinction (Levine 1995).

## The Fundamental Constraint: Cluster-Free Scales

**The puzzle** (Tymoczko 2011, ch. 4): Given pieces of 30° (semitone) and 60° (whole tone), with no two semitone pieces adjacent, form a complete 360° ring. Only 4 solutions exist (ignoring rotation):

### The Four Cluster-Free Scale Types

#### 1. Whole-Tone Scale (6-35, [0,2,4,6,8,10])
- 6 notes, perfectly even
- Mode of limited transposition: only **2** transpositions
- Single mode (all rotations equivalent)
- Formula: R 3 b5 #5 b7 9

#### 2. Diatonic Scale (7-35, [0,1,3,5,6,8,10])
- 7 notes, maximally even
- 12 transpositions (the 12 major keys)
- **7 modes**: Ionian, Dorian, Phrygian, Lydian, Mixolydian, Aeolian, Locrian
- Complement of pentatonic (black keys ↔ white keys)

#### 3. Acoustic/Melodic Minor Scale (7-34, [0,1,3,5,6,8,9])
- 7 notes, nearly as even as diatonic
- 12 transpositions
- **7 modes**: Melodic Minor, Dorian b2, Lydian Augmented, Lydian Dominant, Mixolydian b6, Locrian ♮2, Super Locrian (Altered)

#### 4. Diminished/Octatonic Scale (8-28, [0,1,3,4,6,7,9,10])
- 8 notes, alternating semitone/whole-tone
- Mode of limited transposition: only **3** transpositions
- **2 modes**: Half-Whole Diminished, Whole-Half Diminished
- Two interlocking diminished 7th chords

### The Three Neighboring Scale Types (contain a minor-third step)

#### 5. Harmonic Minor (7-32, [0,1,3,4,6,8,9])
- 7 notes with one minor-third gap (augmented second)
- Related to Harmonic Major by involution
- 7 modes including Phrygian Dominant, Lydian #2
- Voice-leading: 3 scales one semitone away (1 harmonic major, 1 acoustic, 1 diatonic)

#### 6. Harmonic Major (7-32, [0,1,3,5,6,8,9])
- Same set class as Harmonic Minor (involution pair)
- 7 modes including Lydian Minor, Mixolydian b2

#### 7. Double Augmented Hexatonic (6-20, [0,1,4,5,8,9])
- 6 notes, alternating semitone and minor third
- Mode of limited transposition: **4** transpositions
- 2 modes: Half-Third Augmented, Third-Half Augmented
- Two interlocking augmented triads
- Its own complement

### Other Scales Referenced

- **Pentatonic (5-35)**: complement of diatonic, very consonant, "black keys"
  - 5 modes: Major Pentatonic, Minor Pentatonic, Suspended, Blues Major, Blues Minor
- **Chromatic Scale**: all 12 pitch classes, 1 transposition
- **Blues/Bebop scales**: cluster-free scales + chromatic passing tones (rhythmic purpose)
- **Melodic Minor b2, Hungarian Minor**: heptatonic diminished subsets of octatonic
- **Non-Western**: Hindustani thaats, Carnatic ragas, Arabic maqam (many representable in 12-TET); Arab gadwal uses 24-TET

## The 17 Mode Types (Jazz Theory Foundation)

### Diatonic Modes

| Degree | Mode | Character | Formula |
|--------|------|-----------|---------|
| I | Ionian (Major) | Bright major | R 2 3 4 5 6 7 |
| ii | Dorian | Jazzy minor | R 2 b3 4 5 6 b7 |
| iii | Phrygian | Dark minor | R b2 b3 4 5 b6 b7 |
| IV | Lydian | Brightest major | R 2 3 #4 5 6 7 |
| V | Mixolydian | Bluesy major | R 2 3 4 5 6 b7 |
| vi | Aeolian (Natural Minor) | Sad minor | R 2 b3 4 5 b6 b7 |
| vii | Locrian | Diminished | R b2 b3 4 b5 b6 b7 |

### Acoustic/Melodic Minor Modes

| Degree | Mode | Formula |
|--------|------|---------|
| i | Melodic Minor | R 2 b3 4 5 6 7 |
| ii | Dorian b2 | R b2 b3 4 5 6 b7 |
| III | Lydian Augmented | R 2 3 #4 #5 6 7 |
| IV | Lydian Dominant | R 2 3 #4 5 6 b7 |
| V | Mixolydian b6 (Hindu) | R 2 3 4 5 b6 b7 |
| vi | Locrian ♮2 | R 2 b3 4 b5 b6 b7 |
| VII | Super Locrian (Altered) | R b2 b3 b4 b5 b6 b7 |

### Diminished Modes
- Half-Whole: R b2 #2 3 #4 5 6 b7
- Whole-Half: R 2 b3 4 b5 #5 6 7

### Whole-Tone Mode
- R 2 3 #4 #5 b7

## Key Signature Data

15 major key signatures (with enharmonic pairs):
```
C#: C# D# E# F# G# A# B#    (7 sharps)
F#: F# G# A# B  C# D# E#    (6 sharps)
B:  B  C# D# E  F# G# A#    (5 sharps)
E:  E  F# G# A  B  C# D#    (4 sharps)
A:  A  B  C# D  E  F# G#    (3 sharps)
D:  D  E  F# G  A  B  C#    (2 sharps)
G:  G  A  B  C  D  E  F#    (1 sharp)
C:  C  D  E  F  G  A  B     (0)
F:  F  G  A  Bb C  D  E     (1 flat)
Bb: Bb C  D  Eb F  G  A     (2 flats)
Eb: Eb F  G  Ab Bb C  D     (3 flats)
Ab: Ab Bb C  Db Eb F  G     (4 flats)
Db: Db Eb F  Gb Ab Bb C     (5 flats)
Gb: Gb Ab Bb Cb Db Eb F     (6 flats)
Cb: Cb Db Eb Fb Gb Ab Bb    (7 flats)
```

Additional scale spellings stored: melodic minor (15 keys), octatonic (4), whole-tone (2), harmonic minor (15), harmonic major (15), double augmented hexatonic (4).

## Scale-to-Mode Relationship

Given a scale (pitch class set) and a root pitch class:
1. The mode = ordered intervals from the root through the scale
2. Mode name depends on: parent scale type + degree number
3. Each scale of n notes produces n modes

## The Hexagonal Tessellation (Voice-Leading Map)

The site includes a large SVG tessellation (`tmp/harmoniousapp.net/majmin/scales,-1,,0,2.svg`) mapping all 12 transpositions of the 4 main scale types as geometric tiles:
- **Hexagons** = diatonic scales (6 neighbors: 2 diatonic, 2 acoustic, 1 harmonic major, 1 harmonic minor)
- **Squares** = acoustic scales (4 neighbors: 2 diatonic, 1 harmonic major, 1 harmonic minor)
- **Triangles/diamonds** = harmonic major/minor scales
- Adjacency = single-semitone voice-leading distance

## The Mode Tessellation (Top-Down View)

An inline SVG showing all 17 mode types in a hexagonal/triangular grid where:
- Adjacent shapes share common tones
- Each cell links to the mode page
- Includes harmonic major/minor modes in interstice regions

## Algorithms Required

1. Scale as pitch class set with all 12 transpositions
2. Mode derivation: given scale + root degree, compute interval formula
3. Mode naming lookup from (scale_type, degree_number)
4. Key signature generation and note spelling per key
5. Scale-chord compatibility: is chord a pitch-class subset of scale?
6. Cluster-free test on any pitch class set
7. Evenness metric computation
8. Scale complement computation
9. Voice-leading distance between two scales (for adjacency maps)
10. The "puzzle" enumeration (integer partitions of 12 with adjacency constraint)
