# Circle of Fifths and Key Signature Visualizations

> References: [Keys, Harmony and Progressions](../keys-harmony-and-progressions.md)
> Source: `tmp/harmoniousapp.net/svg/cofclock.svg`, `tmp/harmoniousapp.net/svg/key-sig-*.svg`
> Source: `tmp/harmoniousapp.net/p/d9/Circle-of-Fifths-Keys.html`, `tmp/harmoniousapp.net/p/a7/Keys.html`

## Overview

Two related visualization types:
1. **Circle of fifths clock**: 12 keys arranged by ascending perfect fifths
2. **Key signature display**: Traditional notation showing sharps/flats on a staff

## Circle of Fifths Clock

### SVG Specifications
- **Canvas**: Similar to clock diagram but larger (for text labels)
- **Layout**: 12 positions around a circle, like a clock
- **Position 0** (12 o'clock): C major / A minor
- **Clockwise**: sharp keys (G, D, A, E, B, F#)
- **Counter-clockwise**: flat keys (F, Bb, Eb, Ab, Db, Gb)
- **Inner ring**: relative minor keys
- **Outer ring**: major keys

### Generation Algorithm

```
circle_of_fifths_positions():
    // 12 positions, each separated by 30°
    // Starting at top (12 o'clock = C)
    cof_order = [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5]
    // Maps to: C, G, D, A, E, B, F#/Gb, Db, Ab, Eb, Bb, F

    for i in 0..11:
        angle = i * 30 * PI / 180
        major_pc = cof_order[i]
        minor_pc = (major_pc + 9) % 12  // relative minor

        outer_x = cx + outer_r * sin(angle)
        outer_y = cy - outer_r * cos(angle)
        inner_x = cx + inner_r * sin(angle)
        inner_y = cy - inner_r * cos(angle)

        // Draw major key label at outer position
        draw_text(outer_x, outer_y, major_key_name(major_pc))
        // Draw minor key label at inner position
        draw_text(inner_x, inner_y, minor_key_name(minor_pc))
```

### Color Coding

Each position colored by its pitch-class color:
```
fill = PC_COLORS[cof_order[position_index]]
```

### Enharmonic Pairs

At 6 o'clock position, show both spellings:
- F# / Gb (6 sharps / 6 flats)
- C# / Db (7 sharps / 5 flats) — at 7 o'clock
- B / Cb (5 sharps / 7 flats) — at 5 o'clock

## Key Signature Display

### SVG Specifications
- **Canvas**: Small (like chord/ SVGs)
- **Content**: Treble or bass clef + sharps/flats on correct staff lines
- **Sharp positions on treble staff**: F5, C5, G5, D5, A4, E5, B4
- **Flat positions on treble staff**: B4, E5, A4, D5, G4, C5, F4

### Generation Algorithm

```
key_signature_svg(key):
    sig = key.signature
    positions = []

    if sig.type == SHARPS:
        // Sharps appear in order: F C G D A E B
        SHARP_STAFF_POS_TREBLE = [5, 2, 6, 3, 0, 4, 1]  // staff positions
        for i in 0..sig.count:
            x = clef_width + i * accidental_spacing
            y = staff_y(SHARP_STAFF_POS_TREBLE[i])
            draw_sharp_glyph(x, y)

    elif sig.type == FLATS:
        // Flats appear in order: B E A D G C F
        FLAT_STAFF_POS_TREBLE = [3, 0, 4, 1, 5, 2, 6]
        for i in 0..sig.count:
            x = clef_width + i * accidental_spacing
            y = staff_y(FLAT_STAFF_POS_TREBLE[i])
            draw_flat_glyph(x, y)
```

## N-TET Chart

The site also includes `tmp/harmoniousapp.net/svg/n-tet-chart.svg` showing how different equal temperament systems compare:
- 12-TET (standard Western)
- 19-TET, 24-TET (quarter-tones), 31-TET, 53-TET
- Comparison of interval accuracy to just intonation ratios

## Other SVGs in `tmp/harmoniousapp.net/svg/` Directory

The `tmp/harmoniousapp.net/svg/` directory contains ~140 miscellaneous SVGs:
- `tmp/harmoniousapp.net/svg/cofclock.svg`: Circle of fifths
- `tmp/harmoniousapp.net/svg/n-tet-chart.svg`: Equal temperament comparison
- `tmp/harmoniousapp.net/svg/triads-graphviz-maj-min-orbifold.svg`: Triad orbifold graph
- Individual icons, labels, and decorative elements
- `tmp/harmoniousapp.net/center-square-text/`: 24 SVGs with single letter glyphs (36×36 px)
- `tmp/harmoniousapp.net/vert-text-black/`: 115 SVGs with vertical Forte number labels
- `tmp/harmoniousapp.net/vert-text-b2t-black/`: 115 SVGs with bottom-to-top vertical labels

## Algorithm Dependencies
- [Scale, Mode, Key](../algorithms/scale-mode-key.md): key signature computation, circle of fifths navigation
- [Note Spelling](../algorithms/note-spelling.md): correct accidental display

## Interactivity (Future)
- Click a key on the circle to navigate to that key's page
- Highlight related keys (relative, parallel, dominant, subdominant)
- Animate key changes showing which note changes
- Integration with key slider for synchronized navigation
