# Tessellation Maps (Scale Voice-Leading Visualization)

> References: [Scales and Modes](../scales-and-modes.md), [Evenness, Voice Leading and Geometry](../evenness-voice-leading-and-geometry.md)
> Source directory: `tmp/harmoniousapp.net/majmin/` (416 SVGs, 300×360 px)
> Source: `tmp/harmoniousapp.net/p/0c/Beyond-Diatonic.html` (hexagonal tessellation), `tmp/harmoniousapp.net/p/bc/Top-Down-View.html` (mode tessellation)

## Overview

Tessellation maps are the most complex SVGs on the site. They show relationships between scales/modes as geometric tilings where adjacent tiles are connected by single-semitone voice leading. Two types:

1. **Scale tessellation** (`tmp/harmoniousapp.net/majmin/`): Shows all transpositions of the 4 main scale types as geometric tiles where adjacency = one note changes by one semitone
2. **Mode tessellation** (inline SVG): Shows all 17 mode types in a hexagonal/triangular grid with common-tone relationships

## SVG Specifications

### Scale Tessellation (`tmp/harmoniousapp.net/majmin/`)
- **Canvas**: 300 × 360 px viewBox
- **Tile shapes** determined by scale type:
  - **Hexagons** = diatonic scales (7-35): 6 neighbors (2 diatonic, 2 acoustic, 1 harmonic major, 1 harmonic minor)
  - **Squares** = acoustic scales (7-34): 4 neighbors (2 diatonic, 1 harmonic major, 1 harmonic minor)
  - **Triangles/Diamonds** = harmonic minor/major scales (7-32): 3 neighbors
- **Colors**: Each tile colored by its tonic's pitch-class color
- **Labels**: Scale name inside each tile (rendered as path glyphs)
- **Edges**: Shared edges between adjacent tiles represent single-semitone voice leading

### Mode Tessellation (inline SVG)
- Hexagonal/triangular grid showing all 17 mode types
- Each cell links to the mode's article page
- Adjacent shapes share common tones
- Harmonic major/minor modes fill interstice regions

## Voice-Leading Adjacency Rules

Each scale type has specific neighbors determined by single-semitone voice leading:

```
Diatonic scale neighbors (6):
  - 2 other diatonic scales (±1 in circle of fifths)
  - 2 acoustic scales (raise/lower specific degrees)
  - 1 harmonic major (lower specific degree)
  - 1 harmonic minor (raise specific degree)

Acoustic scale neighbors (4):
  - 2 diatonic scales
  - 1 harmonic major
  - 1 harmonic minor

Harmonic minor/major neighbors (3):
  - 1 diatonic
  - 1 acoustic
  - 1 harmonic of opposite type
```

## Generation Algorithm

### Step 1: Compute All Scales and Their Voice-Leading Distances

```
all_scales = []
for scale_type in [DIATONIC, ACOUSTIC, HARMONIC_MINOR, HARMONIC_MAJOR]:
    for transposition in 0..scale_type.num_transpositions:
        pcs = transpose(scale_type.prime_form, transposition)
        all_scales.append((scale_type, transposition, pcs))

// Build adjacency graph
edges = []
for i in 0..len(all_scales):
    for j in i+1..len(all_scales):
        dist = hamming_distance(all_scales[i].pcs, all_scales[j].pcs)
        if dist == 2:  // one note leaves, one enters = Hamming 2
            edges.append((i, j))
```

### Step 2: Assign Tile Shapes

```
tile_shape(scale_type):
    switch scale_type:
        DIATONIC: return HEXAGON       // 6 edges = 6 neighbors
        ACOUSTIC: return SQUARE        // 4 edges = 4 neighbors
        HARMONIC_MINOR: return TRIANGLE
        HARMONIC_MAJOR: return DIAMOND
```

### Step 3: Layout Computation (Tessellation)

The layout follows a regular tiling pattern:
```
// Hexagons tile in a honeycomb pattern
// Squares fill gaps between hexagons
// Triangles/diamonds fill remaining interstices

hex_positions = honeycomb_layout(diatonic_scales)
square_positions = fill_gaps(hex_positions, acoustic_scales)
triangle_positions = fill_interstices(hex_positions, square_positions, harmonic_scales)
```

### Step 4: SVG Generation

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 360">
  <!-- Hexagonal tile for C Diatonic -->
  <polygon points="{hex_points}" fill="{color}" stroke="black" stroke-width="1"/>
  <text x="{cx}" y="{cy}" text-anchor="middle" font-size="8">C Major</text>

  <!-- Square tile for C Acoustic -->
  <rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{color}" stroke="black"/>

  <!-- Triangle tile for C Harmonic Minor -->
  <polygon points="{tri_points}" fill="{color}" stroke="black"/>
</svg>
```

### Step 5: Highlighting and Selection

The 416 SVG variants represent different selections/highlights:
```
tmp/harmoniousapp.net/majmin/{scale_type},{transposition},{highlight_mode},{zoom}.svg
```

Where highlight_mode selects which tiles are emphasized (e.g., showing only neighbors of a selected scale).

## File Naming Convention

```
tmp/harmoniousapp.net/majmin/scales,{offset},{highlight},{zoom}.svg
```

Components vary by view mode — some show all scales, others focus on a single scale's neighborhood.

## Counts
- 416 SVGs in `tmp/harmoniousapp.net/majmin/` directory
- These are the largest SVGs on the site (300×360 px with many path elements)

## Algorithm Dependencies
- [Pitch Class Set Operations](../algorithms/pitch-class-set-operations.md): Hamming distance for adjacency
- [Scale, Mode, Key](../algorithms/scale-mode-key.md): scale enumeration and identification
- [Voice Leading](../algorithms/voice-leading.md): single-semitone VL computation

## Interactivity (Future)
- Click a tile to select that scale/mode
- Highlight neighbors (voice-leading connections)
- Animate voice-leading transitions (show which note moves)
- Synchronized with key slider and other views
- Zoom in/out to show detail or overview
