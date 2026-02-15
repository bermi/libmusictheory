# Mode Icons (Roman Numeral Function Symbols)

> References: [Keys, Harmony and Progressions](../keys-harmony-and-progressions.md)
> Source directory: `tmp/harmoniousapp.net/oc/` (564 SVGs, 70×70 px)

## Overview

Mode icons are small square SVGs containing Roman numeral chord function symbols (I, ii, iii, IV, V, vi, vii°). Each shows a Roman numeral inside a bordered square, indicating the chord's function within a key.

## SVG Specifications

- **Canvas**: 70 × 70 px viewBox
- **Border**: Square border with fill color indicating chord function
- **Text**: Roman numeral centered in square
- **Coloring**: Based on the pitch class color of the chord root relative to the key

## File Naming Convention

```
tmp/harmoniousapp.net/oc/{scale_abbrev},{transposition},{roman_numeral}.svg
```

Components:
- `scale_abbrev`: parent scale type abbreviation
  - `d` = diatonic
  - `a` = acoustic/melodic minor
  - `o` = octatonic/diminished
  - `w` = whole-tone
- `transposition`: integer (0-11) indicating which key
- `roman_numeral`: the degree symbol (I, ii, iii, IV, V, vi, vii)

Example: `tmp/harmoniousapp.net/oc/d,0,I.svg` = Diatonic, key of C, degree I (C major)

## Generation Algorithm

### Step 1: Determine Content

```
mode_icon(scale_type, transposition, degree):
    // Get the chord quality for this degree
    quality = diatonic_chord_quality(scale_type, degree)
    // Format Roman numeral
    rn = format_roman_numeral(degree, quality)
    // Determine color from root pitch class
    root_pc = scale_degree_to_pc(scale_type, transposition, degree)
    color = PC_COLORS[root_pc]
```

### Step 2: Generate SVG

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 70 70">
  <rect x="2" y="2" width="66" height="66" rx="4"
        fill="{bg_color}" stroke="{border_color}" stroke-width="2"/>
  <text x="35" y="42" text-anchor="middle" dominant-baseline="middle"
        font-size="24" fill="white" font-family="serif">
    {roman_numeral}
  </text>
</svg>
```

Text is rendered as `<path>` elements (font outlines) for consistency.

### Step 3: Quality Symbols

```
quality_suffix(quality):
    switch quality:
        MAJOR: ""
        MINOR: ""         // lowercase numeral indicates minor
        DIMINISHED: "°"
        AUGMENTED: "+"
        HALF_DIM: "ø"
```

## Counts
- 564 SVGs total
- ≈ 7 degrees × 12 keys × several scale types + variants

## Algorithm Dependencies
- [Chord Construction](../algorithms/chord-construction-and-naming.md): Roman numeral assignment
- [Scale, Mode, Key](../algorithms/scale-mode-key.md): degree-to-pitch-class mapping

## Interactivity (Future)
- Click to navigate to the chord's page
- Hover to preview chord tones
- Color matches the key slider's color scheme
