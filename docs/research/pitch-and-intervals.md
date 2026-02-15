# Pitch and Intervals

> Source: `tmp/harmoniousapp.net/p/ca/Pitch-Intervals.html`, `tmp/harmoniousapp.net/p/23/Musical-Objects.html`, `tmp/harmoniousapp.net/p/dd/Staff-Notation.html`,
> Glossary: Pitch, Note, Interval, Semitone, Whole Tone, Cent, Octave, Unison, Acoustics

## Acoustics Foundations

- Sound = mechanical vibrations; pitch = perceived frequency
- Higher frequency = higher pitch; string halved in length = octave higher
- Fundamental tone + overtones (integer multiples of fundamental) = timbre
- Overtone series: f, 2f, 3f, 4f, 5f... produces octave, fifth, fourth, major third, minor third

### String Division to Intervals

| Division | Approx. Semitones | Interval |
|----------|-------------------|----------|
| 1/2 | 12 | Perfect Octave |
| 1/3 | 5 | Perfect Fourth |
| 1/4 | 4 | Just Major Third |
| 1/5 | 3 | Just Minor Third |
| 1/8 | 2 | Just Whole Tone |
| 1/16 | 1 | Just Semitone |
| 2/5 | 6 | Just Tritone |

## The 12-Tone Chromatic System

- Western music divides the octave into 12 equal semitones (12-TET)
- Each semitone ratio: `2^(1/12) ≈ 1.05946`
- Cent = 1/1200 of octave; 1 semitone = 100 cents
- Audible tuning threshold: ~15-25 cents
- Pitch perception is logarithmic: A3=220Hz, A4=440Hz, A5=880Hz sound evenly spaced

### Frequency Formulas

- MIDI to frequency: `freq = 440 * 2^((midi - 69) / 12)`
- Frequency to MIDI: `midi = 69 + 12 * log2(freq / 440)`
- Cents between frequencies: `cents = 1200 * log2(f2 / f1)`

## Pitch Classes

- Pitch class = note identity ignoring octave (mod 12 arithmetic)
- 12 pitch classes: C=0, C#/Db=1, D=2, D#/Eb=3, E=4, F=5, F#/Gb=6, G=7, G#/Ab=8, A=9, A#/Bb=10, B=11
- Set theory notation: 0-9 plus t=10, e=11

## Note Names and Enharmonic Equivalence

35 total note name spellings map to 12 pitch classes:

```
C=0, B#=0, Dbb=0
C#=1, Db=1
D=2, C##=2, Ebb=2
D#=3, Eb=3
E=4, D##=4, Fb=4
F=5, E#=5, Gbb=5
F#=6, Gb=6, E##=6
G=7, F##=7, Abb=7
G#=8, Ab=8
A=9, G##=9, Bbb=9
A#=10, Bb=10
B=11, A##=11, Cb=11
```

In 12-TET, enharmonic equivalents are the exact same frequency.
In historical tuning systems, they may differ (this matters for tuning history, not for set theory).

## MIDI Note Numbers

- Formula: `midi = 12 + (12 * octave) + pitch_class` (where C4 = MIDI 60)
- Piano range: MIDI 21 (A0) to MIDI 108 (C8)
- Pitch class from MIDI: `pc = midi % 12`
- Octave from MIDI: `octave = floor(midi / 12) - 1`

## Intervals

Two notes form an interval, measured in semitones. All chords/scales are built from intervals.

### Complete Interval Table

| Semi | Name | Formula | Mnemonic |
|------|------|---------|----------|
| 0 | Unison | R | -- |
| 1 | Semitone / Minor 2nd | b2 | Jaws |
| 2 | Whole Tone / Major 2nd | 2 | Happy Birthday |
| 3 | Minor 3rd / Aug 2nd | b3 / #2 | Brahms' Lullaby |
| 4 | Major 3rd / Dim 4th | 3 / b4 | Davy Crockett |
| 5 | Perfect 4th / Aug 3rd | 4 / #3 | Eine Kleine Nachtmusik |
| 6 | Tritone / Aug 4th / Dim 5th | #4 / b5 | The Simpsons Theme |
| 7 | Perfect 5th | 5 | Star Wars |
| 8 | Minor 6th / Aug 5th | b6 / #5 | In My Life |
| 9 | Major 6th / Dim 7th | 6 / bb7 | My Bonnie Lies |
| 10 | Minor 7th / Aug 6th | b7 / #6 | Star Trek |
| 11 | Major 7th | 7 | Take on Me |
| 12 | Octave | 8va | Somewhere Over the Rainbow |
| 13 | Minor 9th | b9 | |
| 14 | Major 9th | 9 | |
| 15 | Augmented 9th | #9 | |
| 16 | Diminished 11th | b11 | |
| 17 | Perfect 11th | 11 | |
| 18 | Augmented 11th | #11 | |
| 19 | Perfect 12th | 8va+5 | |
| 20 | Minor 13th | b13 | |
| 21 | Major 13th | 13 | |
| 22 | Augmented 13th | #13 | |

### Interval Classes (Set Theory)

Intervals grouped by inversion into 6 classes (each pair sums to 12):

| IC | Intervals | Semitones | Color (site) |
|----|-----------|-----------|-------------|
| IC1 | Minor 2nd / Major 7th | 1 + 11 | Blue (#0073F2) |
| IC2 | Major 2nd / Minor 7th | 2 + 10 | Cyan (#2CD6F9) |
| IC3 | Minor 3rd / Major 6th | 3 + 9 | Teal (#2CBE86) |
| IC4 | Major 3rd / Minor 6th | 4 + 8 | Green (#74C937) |
| IC5 | Perfect 4th / Perfect 5th | 5 + 7 | Yellow (#E8C745) |
| IC6 | Tritone (self-inverse) | 6 + 6 | Orange (#FB7A3D) |

Key insight: equal-tempered intervals sharing an IC have related tuning ratios: a × b = 2.

### Interval Formula Notation (Chord Degrees)

```
1=0, b2=1, 2=2, #2=3, b3=3, 3=4, #3=5, 4=5,
#4=6, b5=6, 5=7, #5=8, b6=8, 6=9, #6=10, b7=10,
7=11, bb7=9, b9=1, 9=2, #9=3, b11=4, 11=5,
#11=6, b13=8, 13=9, #13=10
```

### Compound Intervals (base semitones for extended voicings)

```
degree: [_, 0, 2, 4, 5, 7, 9, 11, _, 14, _, 17, _, 21]
         1  2  3  4  5  6  7      9     11     13
```

9th = 14 semitones, 11th = 17, 13th = 21 (above root, spanning more than an octave).

## Staff Notation

- 5-line staff with treble clef (G clef) and bass clef (F clef)
- Grand staff: treble + bass connected by brace
- Ledger lines extend beyond staff
- Treble lines: E G B D F ("Every Good Boy Does Fine")
- Treble spaces: F A C E ("FACE")
- Bass lines: G B D F A ("Grizzly Bears Don't Fly Airplanes")
- Bass spaces: A C E G ("All Cows Eat Grass")
- Key signatures: sharps added in order F C G D A E B; flats in order B E A D G C F
- The notation system is inherently biased toward the diatonic scale

## Tuning Systems

- **Just Intonation**: pure ratios (3:2 for fifth, 5:4 for major third), only works in one key
- **Pythagorean**: based on pure 5ths, has a "wolf" 5th
- **Meantone**: compromised 5ths to improve 3rds
- **Well temperaments** (Werckmeister, Kirnberger): unequal but all keys usable
- **12-TET**: all semitones equal, all keys equally (slightly) out of tune
- **N-TET systems**: 19-TET, 24-TET (quarter-tones), 31-TET, 53-TET offer different tradeoffs
- Arab tone system (gadwal) uses 24-TET

### 12-TET vs Just Intonation

| Interval | Just Ratio | Just Cents | 12-TET Cents | Error |
|----------|-----------|------------|--------------|-------|
| Perfect 5th | 3:2 | 702 | 700 | -2 |
| Major 3rd | 5:4 | 386 | 400 | +14 |
| Minor 3rd | 6:5 | 316 | 300 | -16 |
| Perfect 4th | 4:3 | 498 | 500 | +2 |
