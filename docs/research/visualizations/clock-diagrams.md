# Clock Diagrams (OPC and OPTC)

> References: [Pitch Class Sets](../pitch-class-sets-and-set-theory.md)
> Source directories: `tmp/harmoniousapp.net/optc/` (885 SVGs, monochrome), `tmp/harmoniousapp.net/opc/` (7 SVGs, colored)
> Source: `tmp/harmoniousapp.net/p/0b/Clocks-Pitch-Classes.html`, `tmp/harmoniousapp.net/p/71/Set-Classes.html`

## Overview

Clock diagrams place 12 circles at clock positions (like a clock face) representing the 12 pitch classes. Filled circles indicate presence in the set. Two variants exist: colored (OPC, pitch-class specific) and monochrome (OPTC, transposition-independent).

## SVG Specifications

### OPC (Colored) Clock Diagrams
- **Canvas**: 100×100 px viewBox
- **Circle layout**: 12 circles at radius 42 from center (50, 50)
- **Circle radius**: ~5px
- **Position formula**: `cx = 50 + 42 * sin(n * 30°)`, `cy = 50 - 42 * cos(n * 30°)` where n = pitch class (0=C at 12 o'clock, clockwise)
- **Colors**: Each pitch class has its own color from the 12-color scheme
- **Fill**: Colored = present in set, white with thin stroke = absent

### OPTC (Monochrome) Clock Diagrams
- **Canvas**: 70×70 px viewBox
- **Circle layout**: 12 circles at radius ~30 from center (35, 35)
- **Fill colors**:
  - Black filled = pitch class present (not part of cluster)
  - Gray filled = pitch class present AND part of a chromatic cluster
  - White with stroke = pitch class absent
- **Center text**: Prime form digits (e.g., "047", "013568t") using SVG text or path glyphs
- **Purpose**: Represents the entire set class (all 12 transpositions collapsed)

## Generation Algorithm

### Step 1: Compute Circle Positions

```
for n in 0..11:
    angle_deg = n * 30  // 360° / 12
    angle_rad = angle_deg * PI / 180
    cx = center_x + radius * sin(angle_rad)
    cy = center_y - radius * cos(angle_rad)
    positions[n] = (cx, cy)
```

### Step 2: Determine Fill Colors

For OPC (colored):
```
for n in 0..11:
    if pitch_class_set & (1 << n):
        fill = PC_COLORS[n]
    else:
        fill = "white"
        stroke = "#ccc"
```

For OPTC (monochrome):
```
cluster_info = get_clusters(pitch_class_set)
for n in 0..11:
    if cluster_info.cluster_pcs & (1 << n):
        fill = "#999"      // gray for cluster member
    elif pitch_class_set & (1 << n):
        fill = "black"     // black for non-cluster member
    else:
        fill = "white"
        stroke = "#ccc"
```

### Step 3: Generate Center Label (OPTC only)

```
label = pretty_print(prime_form)  // e.g., "047", "013568t"
// Position centered in the clock
// Font size scales with label length
font_size = max(8, 14 - len(label))
```

### Step 4: Assemble SVG

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 70 70">
  <!-- 12 circles -->
  <circle cx="{cx}" cy="{cy}" r="4" fill="{fill}" stroke="{stroke}"/>
  <!-- ... repeat for all 12 -->
  <!-- Center label -->
  <text x="35" y="38" text-anchor="middle" font-size="{fs}">{label}</text>
</svg>
```

## File Naming Convention

### OPTC
`tmp/harmoniousapp.net/optc/{prime_form_hex}.svg` — e.g., `tmp/harmoniousapp.net/optc/047.svg` for set class [047] (major/minor triad)

### OPC
`tmp/harmoniousapp.net/opc/{pitch_class_list}.svg` — e.g., `tmp/harmoniousapp.net/opc/0,4,7.svg` for C major triad specifically

## Counts
- OPTC: 885 SVGs (336 set classes × some with involution variants + other cardinalities)
- OPC: 7 SVGs (used sparingly for specific illustrations)

## Algorithm Dependencies
- [Pitch Class Set Operations](../algorithms/pitch-class-set-operations.md): bit manipulation
- [Prime Form](../algorithms/prime-form-and-set-class.md): canonical form computation
- [Chromatic Cluster Detection](../algorithms/chromatic-cluster-detection.md): cluster coloring
- Trigonometric functions: `sin`, `cos` for circle positioning

## Interactivity (Future)
- Click a circle to toggle pitch class membership
- Drag to rotate (transpose)
- Hover to show interval relationships
- Real-time update of related views (staff notation, keyboard, fretboard)
