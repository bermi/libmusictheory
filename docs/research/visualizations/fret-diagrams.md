# Fret Diagrams (Guitar And Parametric Fretboard Visualization)

> References: [Guitar and Keyboard](../guitar-and-keyboard.md)
> Source directory: `tmp/harmoniousapp.net/eadgbe/` (2,278 SVGs, 100×100 px)
> Source: `tmp/harmoniousapp.net/js-client/frets.js`, Inkscape-generated patterns

## Overview

Fret diagrams show chord voicings on a grid representing the fretboard. Each dot indicates where to press a string. Special markers show muted strings, open strings, barre chords, and pitch-class guide dots.

There are now two distinct surfaces in the library:

- a six-string compatibility wrapper for harmonious `eadgbe`
- a parametric fretboard API that accepts arbitrary string counts and explicit visible fret windows

## SVG Specifications

- **Canvas**: 100 × 100 px viewBox
- **Grid**: `N` vertical lines (strings) × typically 4-5 horizontal fret cells
- **Dot size**: ~4px radius circles at string/fret intersections
- **Markers**:
  - Filled circle = fretted note
  - "O" above nut = open string
  - "X" above nut = muted string
  - Thick bar across strings = barre
- **Nut**: Thicker line at top (fret 0) for open position chords
- **Position indicator**: Small number at left showing starting fret for non-open chords

## Grid Geometry

```
// N strings, equally spaced
string_x(i) = left_margin + i * string_spacing  // i = 0 .. string_count-1

// Frets, equally spaced
fret_y(j) = top_margin + j * fret_spacing  // j = 0 (nut) to num_frets

// Dot position (between frets)
dot_x(string) = string_x(string)
dot_y(fret) = fret_y(fret - 1) + fret_spacing / 2  // centered between fret lines
```

## Generation Algorithm

### Step 1: Determine Fret Window

```
fret_window(voicing, explicit_start = null, visible_frets = 4):
    if explicit_start is not null:
        return (explicit_start, explicit_start + visible_frets)
    fretted = [f for f in voicing.frets if f > 0]
    if len(fretted) == 0:
        return (0, visible_frets)  // open chord, show the requested window
    min_fret = min(fretted)
    max_fret = max(fretted)
    // Show enough frets to cover the voicing plus context
    start_fret = max(0, min_fret - 1)
    end_fret = max(start_fret + visible_frets, max_fret + 1)
    return (start_fret, end_fret)
```

### Step 2: Draw Grid

```xml
<!-- String lines (vertical) -->
<line x1="{string_x(i)}" y1="{top}" x2="{string_x(i)}" y2="{bottom}" stroke="black"/>

<!-- Fret lines (horizontal) -->
<line x1="{left}" y1="{fret_y(j)}" x2="{right}" y2="{fret_y(j)}" stroke="black"/>

<!-- Nut (thick line at top for open position) -->
<line x1="{left}" y1="{top}" x2="{right}" y2="{top}" stroke="black" stroke-width="3"/>
```

### Step 3: Draw Dots

```
for i in 0..string_count-1:
    fret = voicing.frets[i]
    if fret < 0:
        // Muted: draw X above nut
        draw_x(string_x(i), above_nut_y)
    elif fret == 0:
        // Open: draw O above nut
        draw_circle(string_x(i), above_nut_y, radius=3, fill="none", stroke="black")
    else:
        // Fretted: draw filled circle between frets
        draw_circle(string_x(i), dot_y(fret), radius=4, fill="black")
```

### Step 4: Draw Barre (if applicable)

```
detect_barre(voicing):
    // Find common fret across adjacent strings
    for fret in 1..max(voicing.frets):
        strings_at_fret = [i for i in 0..string_count-1 if voicing.frets[i] >= fret]
        if len(strings_at_fret) >= 2:
            // Check if these are consecutive strings
            if max(strings_at_fret) - min(strings_at_fret) == len(strings_at_fret) - 1:
                return (fret, min(strings_at_fret), max(strings_at_fret))
    return null

// Draw barre as thick rounded rectangle
if barre:
    draw_rect(string_x(barre.low_string), dot_y(barre.fret),
              string_x(barre.high_string) - string_x(barre.low_string),
              8, rx=4, fill="black")
```

### Step 5: Draw Position Indicator

```
if start_fret > 1:
    // Show fret number at left
    draw_text(left_margin - 10, dot_y(start_fret), str(start_fret), font_size=10)
```

### Step 6: Guide Dots (Interactive Mode)

For the interactive fretboard, additional semi-transparent dots show pitch-class equivalents:

```
for each selected_position:
    pc = fret_to_pc(selected_position)
    for all other positions with same pc:
        draw_circle(x, y, radius=3, fill="black", opacity=0.35)
```

## Compatibility File Naming Convention

`tmp/harmoniousapp.net/eadgbe/{root}-{chord_type}.svg`
Example: `tmp/harmoniousapp.net/eadgbe/C-Major.svg`, `tmp/harmoniousapp.net/eadgbe/A-Minor-7th.svg`

Multiple voicings per chord are stored with position suffixes.

## Counts
- tmp/harmoniousapp.net/eadgbe/: 2,278 SVGs (multiple voicings per chord × 12 roots)

## Algorithm Dependencies
- [Guitar Voicing](../algorithms/guitar-voicing.md): fret position computation, CAGED shapes
- [Pitch Class Set Operations](../algorithms/pitch-class-set-operations.md): pitch class from fret position

## Interactivity (Future)
- Tap dots to toggle fret positions
- Automatic pitch-class guide overlay
- CAGED position cycling
- Audio playback of voiced chord
- Synchronized with keyboard and clock diagram views
