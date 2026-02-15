# Guitar, Keyboard, and Instrument-Specific Theory

> Source: `tmp/harmoniousapp.net/p/*/Fret-Diagrams.html`, `tmp/harmoniousapp.net/p/*/CAGED-Fretboard-System.html`,
> `tmp/harmoniousapp.net/p/62/Chords-for-Guitar.html`, `tmp/harmoniousapp.net/p/f2/Chords-for-Keyboard.html`,
> `tmp/harmoniousapp.net/js-client/frets.js`, `tmp/harmoniousapp.net/js-client/kb.js`, `tmp/harmoniousapp.net/js-client/slider.js`

## Guitar

### Standard Tuning
- 6 strings, low to high: E2 A2 D3 G3 B3 E4
- MIDI note numbers: [40, 45, 50, 55, 59, 64]
- String intervals: P4, P4, P4, **M3**, P4 (the M3 between G-B is the irregularity)

### Fret-to-MIDI Conversion
```
midi_note = string_open_midi[string_index] + fret_number
```
- String 0 (low E): fret 0 = MIDI 40 (E2), fret 12 = MIDI 52 (E3)
- Typical playable range: frets 0-24, MIDI 40-88

### Fret Array Representation
- 6-element array, one per string (low E to high E)
- Each element: array of fret numbers (multi-dot mode) or single value
- Special values: empty/x/X = muted string, -1 = not played
- URL format: comma-separated integers, e.g., `0,3,2,0,1,0` (C major open)

### CAGED System
5 open chord shapes moved up the neck as barre chords:
- **C form**: root on 5th string
- **A form**: root on 5th string (higher position)
- **G form**: root on 6th string
- **E form**: root on 6th string
- **D form**: root on 4th string

Each root note has 5 CAGED positions spanning the entire fretboard.

### Guitar Voicing Constraints
- Maximum 6 simultaneous notes
- Typical hand span: 4-5 frets
- Open strings only at fret 0
- Barre: one finger across multiple strings at same fret
- Muted strings: strings between played strings left unplayed

### Pitch Class Guide (Octave Equivalence)
When a note is fretted, show same pitch class positions on other strings:
- Guide dot opacity: 0.35 (subtle visual hint)
- Muted string opacity: 0.4
- Full opacity for selected notes, half opacity for octave equivalents

### Inverse Mapping: MIDI → All Fret Positions
For any target MIDI note, find all (string, fret) pairs:
```
for each string i:
    fret = target_midi - string_open_midi[i]
    if fret >= 0 and fret <= max_fret: yield (i, fret)
```

### Alternative Tunings (extension potential)
- Drop D: [38, 45, 50, 55, 59, 64]
- DADGAD: [38, 45, 50, 55, 57, 62]
- Open G: [38, 43, 50, 55, 59, 62]
- System: just change string_open_midi values

## Piano/Keyboard

### Layout
- 88 keys: MIDI 21 (A0) to MIDI 108 (C8)
- White keys: A B C D E F G pattern repeating
- Black keys: in groups of 2 and 3
- The interactive keyboard covers MIDI 36-83 (C2 to B5, 4 octaves)

### Key Pattern (one octave)
Using the site's template system:
```
p0 = '_:_:__:_:_:_'   // blank template (: = black key, _ = white key)
p1 = 'x*x*xx*x*x*x'   // filled template
```
Maps to: C C# D D# E F F# G G# A A# B

### Accidental Preference
- Sharps mode: C C# D D# E F F# G G# A A# B
- Flats mode: C Db D Eb E F Gb G Ab A Bb B
- Auto mode: choose based on key context from note-spelling database

### Note Spelling Algorithm
Given MIDI notes, find the best key signature spelling:
1. Compute pitch classes of all notes
2. Search through all key signatures (15 major + melodic minor + harmonic + etc.)
3. Find the key whose note names cover all needed pitch classes
4. Apply preferred accidental direction (sharp/flat/auto)
5. Fall back to auto if preferred direction cannot cover all notes

### Grand Staff Distribution
Notes split between treble and bass clef based on pitch range.
Middle C (MIDI 60) is the dividing line.

## The Interactive Key Slider

### Geometry
- Canvas-based rendering with touch/mouse interaction
- Triangular grid (Tonnetz-like) with rows and columns
- Up triangles = major chords, down triangles = minor chords
- Each triangle has a color index (0-11) representing interval relationship to current key

### Navigation
- Horizontal scrolling through circle of fifths
- Snap-to-grid detente (snaps to key boundaries)
- Velocity-based scrolling with friction (dstride *= 0.96)
- Sigmoid easing: `ease(t) = -cos(t * π) * 0.5 + 0.5`

### Color System
12 pitch-class colors:
```
#00c, #a4f, #f0f, #a16, #e02, #f91, #c81, #094, #161, #077, #0bb, #28f
```
Circle-of-fifths reordering: [2, 7, 0, 5, 10, 3, 8, 1, 6, 11, 4, 9]
Colors blend between adjacent keys during scroll transitions.

### Tap Detection
Convert pixel (x, y) to triangular grid coordinates:
```
row = floor(4 * 2 * y / canvas_height)
col = floor(9 * (x + 0.5 * stride) / canvas_width)
// Determine up/down triangle from linear inequalities of triangle edges
```
Validate against whitelist of legal coordinates.

## Algorithms Required

1. Fret position → MIDI note conversion
2. MIDI note → all possible fret positions (inverse mapping)
3. Guitar voicing generation: given pitch class set, find playable fret combinations
4. CAGED position computation for any chord root
5. Hand span constraint checking
6. Note spelling from MIDI notes (key-context-aware)
7. Grand staff split (treble vs bass)
8. Scale URL → keyboard URL conversion (key signature aware)
9. Tonnetz grid coordinate computation
10. Triangular tap-target detection
11. Color blending for key transitions
12. Pitch class guide overlay for fretboard
