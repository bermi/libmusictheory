# Keys, Harmony, and Progressions

> Source: `tmp/harmoniousapp.net/p/a7/Keys.html`, `tmp/harmoniousapp.net/p/d9/Circle-of-Fifths-Keys.html`, `tmp/harmoniousapp.net/p/b9/Diatonic-Modes-Chords.html`,
> `tmp/harmoniousapp.net/p/bc/Top-Down-View.html`, `tmp/harmoniousapp.net/p/05/Extensions-Avoid-Notes.html`,
> Glossary: Key, Tonic, Dominant, Tonality, Harmony, Roman Numeral Function,
> Common Practice, Reharmonization, Compatibility, Relative Key, Parallel Key

## Keys

- A key = a diatonic scale + a tonic (home note/chord)
- 12 major keys + 12 minor keys
- 15 named key signatures (3 enharmonic pairs: Db/C#, Gb/F#, Cb/B)
- Key signature = the sharps/flats needed to spell the diatonic notes

## Circle of Fifths

12 major keys arranged by ascending perfect fifths (7 semitones):
```
C → G → D → A → E → B → F# (sharps direction)
C → F → Bb → Eb → Ab → Db → Gb (flats direction)
```

- Adjacent keys differ by exactly one note (one sharp/flat added or removed)
- This is fundamentally about single-semitone voice leading between 7-note scales
- Circle of fourths = same sequence reversed (interval class 5 is self-inverse)
- The M-relation converts circle of fifths → chromatic circle and back

### Key Signature Ordering
- Sharps added: F C G D A E B ("Forgo Chocolate Glazed Donuts And Eat Breakfast")
- Flats added: B E A D G C F ("Before Eating A Donut Get Coffee First")

## Roman Numeral Function

Transposition-invariant chord analysis:
- **Uppercase** = major/augmented: I, IV, V
- **Lowercase** = minor: ii, iii, vi
- **°** = diminished: vii°
- **+** = augmented: III+

### Diatonic Triads (Major Key)

| Degree | Roman | Quality | C Major |
|--------|-------|---------|---------|
| I | I | Major | C E G |
| II | ii | Minor | D F A |
| III | iii | Minor | E G B |
| IV | IV | Major | F A C |
| V | V | Major | G B D |
| VI | vi | Minor | A C E |
| VII | vii° | Diminished | B D F |

### Diatonic Seventh Chords (Major Key)

| Degree | Roman | Quality | C Major |
|--------|-------|---------|---------|
| I | Imaj7 | Major 7th | C E G B |
| II | ii7 | Minor 7th | D F A C |
| III | iii7 | Minor 7th | E G B D |
| IV | IVmaj7 | Major 7th | F A C E |
| V | V7 | Dominant 7th | G B D F |
| VI | vi7 | Minor 7th | A C E G |
| VII | viiø7 | Half-dim 7th | B D F A |

## Tonal Function

- **Tonic** (I, iii, vi): stable, at rest
- **Subdominant** (ii, IV): moderate tension
- **Dominant** (V, vii°): maximum tension, resolves to tonic
- **V7 → I**: the fundamental cadence of tonal music

## Diatonic Voice-Leading Circuits

### Circle of Fifths Order: vii-iii-vi-ii-V-I-IV
Each adjacent pair shares two common tones and differs by one.

### Circle of Thirds Order (Tymoczko 2011 §6.3.2): I-vi-IV-ii-vii-V-iii-I
Each adjacent pair differs by only 1-2 semitones total voice-leading distance.

## Extensions and Avoid Notes (Jazz)

For each diatonic mode, chord tones (R, 3, 5, 7) + available extensions:

| Mode | Chord | Avoid | Available |
|------|-------|-------|-----------|
| Ionian (I) | Cmaj7 | **11 (F)** | 9, 13 |
| Dorian (ii) | Dm7 | (b13 context) | 9, 11 |
| Phrygian (iii) | Em7 | **b9 (F), b13 (C)** | 11 |
| Lydian (IV) | Fmaj7 | (none!) | 9, #11, 13 |
| Mixolydian (V) | G7 | **11 (C)** | 9, 13 |
| Aeolian (vi) | Am7 | **b13 (F)** | 9, 11 |
| Locrian (vii) | Bm7b5 | **b9 (C)** | 11, b13 |

Lydian is the only diatonic mode with NO avoid notes.

## Minor Key Harmony

- Natural minor (Aeolian): i ii° III iv v VI VII
- Harmonic minor: raised 7th creates V7 → i resolution
- Melodic minor: raised 6th and 7th ascending

### Relative and Parallel Keys
- **Relative key**: shares the same key signature (C major ↔ A minor)
- **Parallel key**: shares the same tonic (C major ↔ C minor)

## Reharmonization

- Substitute chords with same function (tonic for tonic, dominant for dominant)
- **Tritone substitution**: replace V7 with bII7 (shared tritone: 3rd and 7th swap)
- **Modal interchange**: borrow chords from parallel modes
- Non-trivial: replace mode entirely (Super Locrian for Mixolydian)
- Trivial: upgrade within same mode (Dom 7 → Dom 9)
- Voice-leading-based: minimize total movement

## Playing Outside

Jazz atonal/polytonal technique:
- Purposely play notes outside expected scale for tension
- Brief departures that resolve back "inside"
- Side-slipping: shift patterns by a semitone

## The Interactive Key Slider

Triangular grid visualizing chord relationships within a key:
- Up triangles = major-type chords, down = minor-type
- Tonnetz-like hexagonal tiling
- Scrolls through all 12 keys with color interpolation
- 12 pitch-class colors blended during transitions
- Tap target detection via triangular tiling geometry

## Algorithms Required

1. Key signature generation from tonic + mode type
2. Diatonic chord construction (stack thirds from scale degrees)
3. Roman numeral assignment for any chord in a key
4. Available tensions computation (scale tones minus avoid notes)
5. Avoid note detection (scale tone one semitone above chord tone)
6. Voice-leading distance between two chords
7. Tritone substitution computation
8. Relative/parallel key computation
9. Circle of fifths ordering and navigation
10. Transposition of entire key (shift all chords)
