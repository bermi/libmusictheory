# Key Slider and Tonnetz Grid

> References: [Guitar and Keyboard](../guitar-and-keyboard.md), [Keys, Harmony and Progressions](../keys-harmony-and-progressions.md)
> Source: `tmp/harmoniousapp.net/js-client/slider.js` functions: `urlPathToQuad`, `handleTap`, `blend`, `ease`
> Source: `tmp/harmoniousapp.net/js-client/slider.js` data: `pcColors`, `colorIndex`, `whitelistCoords`

## Overview

The interactive key slider is a touch/mouse-driven canvas element that presents chords in a Tonnetz-like triangular grid. It scrolls horizontally through the circle of fifths with snap-to-grid detente, momentum scrolling, and color blending.

## Static Data

### 12 Pitch-Class Colors

```
PC_COLORS = [
    "#00c",  // C  = 0
    "#a4f",  // C# = 1
    "#f0f",  // D  = 2
    "#a16",  // D# = 3
    "#e02",  // E  = 4
    "#f91",  // F  = 5
    "#c81",  // F# = 6
    "#094",  // G  = 7
    "#161",  // G# = 8
    "#077",  // A  = 9
    "#0bb",  // A# = 10
    "#28f",  // B  = 11
]
```

### Circle-of-Fifths Color Reordering

```
COLOR_INDEX = [2, 7, 0, 5, 10, 3, 8, 1, 6, 11, 4, 9]
// Maps key position (0-11 in CoF order) to pitch class for color lookup
// Position 0 → pc 2 (D), Position 1 → pc 7 (G), etc.
```

### Whitelist Coordinates (Valid Tap Targets)

```
// Each entry: [row, column, isDownTriangle, colorIndex]
// These define the legal triangular grid positions
WHITELIST_COORDS = [
    [0, 0, false, 0],  // Up triangle at row 0, col 0
    [0, 0, true, 1],   // Down triangle at row 0, col 0
    // ... (enumerated for the specific grid layout)
]
```

## Algorithms

### 1. URL Path to Grid Quad

**Input**: URL path string
**Output**: [keyIndex, isDownTriangle, row, column]

```
url_to_quad(path):
    // Parse URL to extract key, chord position
    // Maps the page URL to a specific triangle in the grid
    // Returns 4-tuple identifying the triangle
    segments = path.split("/")
    key_idx = parse_key_index(segments)
    down = is_down_triangle(segments)
    row = parse_row(segments)
    col = parse_column(segments)
    return [key_idx, down, row, col]
```

### 2. Triangular Grid Tap Detection

**Input**: Canvas pixel coordinates (x, y), canvas dimensions, current scroll offset
**Output**: Grid coordinates (row, column, isDownTriangle) or null

```
handle_tap(x, y, canvas_width, canvas_height, scroll_offset):
    stride = canvas_width / 9.0

    // Compute row (vertical position)
    row = floor(4 * 2 * y / canvas_height)

    // Compute column (horizontal position, offset by scroll)
    adjusted_x = x + scroll_offset
    col = floor(9 * (adjusted_x + 0.5 * stride) / canvas_width)

    // Determine up or down triangle within the cell
    // Each cell contains two triangles separated by diagonal lines
    cell_x = (adjusted_x + 0.5 * stride) % stride
    cell_y = y % (canvas_height / 8)

    // Linear inequality test for triangle boundary
    normalized_x = cell_x / stride
    normalized_y = cell_y / (canvas_height / 8)

    // Down triangle: point at bottom, flat top
    // Up triangle: point at top, flat bottom
    is_down = normalized_y < (1 - 2 * abs(normalized_x - 0.5))

    // Validate against whitelist
    candidate = [row, col, is_down]
    if candidate in WHITELIST_COORDS:
        return candidate
    return null
```

### 3. Sigmoid Easing Function

**Input**: Progress t (0.0 to 1.0)
**Output**: Eased value (0.0 to 1.0)

```
ease(t):
    return -cos(t * PI) * 0.5 + 0.5
```

Properties: ease(0) = 0, ease(1) = 1, smooth acceleration/deceleration.

### 4. Momentum Scrolling with Friction

**Input**: Current velocity (dstride), current position
**Output**: Updated position and velocity per animation frame

```
FRICTION = 0.96

update_scroll(position, velocity):
    position += velocity
    velocity *= FRICTION

    // Snap-to-grid when velocity is small
    if abs(velocity) < 0.5:
        // Find nearest grid boundary
        stride = canvas_width / 9
        nearest_grid = round(position / stride) * stride
        // Ease toward grid position
        position = lerp(position, nearest_grid, 0.1)
        if abs(position - nearest_grid) < 0.5:
            position = nearest_grid
            velocity = 0

    return (position, velocity)
```

### 5. Color Blending Between Adjacent Keys

**Input**: Two hex colors, blend factor (0.0 to 1.0)
**Output**: Blended hex color

```
blend(color_a, color_b, t):
    // Parse hex colors to RGB
    r_a, g_a, b_a = parse_hex(color_a)
    r_b, g_b, b_b = parse_hex(color_b)

    // Linear interpolation in RGB space
    r = round(r_a + (r_b - r_a) * t)
    g = round(g_a + (g_b - g_a) * t)
    b = round(b_a + (b_b - b_a) * t)

    return to_hex(r, g, b)
```

During scrolling, triangle colors blend between the current key's color scheme and the next key's.

### 6. Triangle Color Assignment

**Input**: Triangle grid position, current key index, scroll offset
**Output**: Fill color for the triangle

```
triangle_color(row, col, is_down, key_idx, scroll_fraction):
    // Color index for this triangle in the current key
    ci = triangle_color_index(row, col, is_down)
    pc = COLOR_INDEX[(ci + key_idx) % 12]
    color_current = PC_COLORS[pc]

    // Blend with next key if scrolling
    if scroll_fraction > 0:
        next_key = (key_idx + 1) % 12
        pc_next = COLOR_INDEX[(ci + next_key) % 12]
        color_next = PC_COLORS[pc_next]
        return blend(color_current, color_next, scroll_fraction)

    return color_current
```

### 7. Canvas Rendering

**Input**: Grid state, scroll position, canvas context
**Output**: Rendered triangular grid on canvas

```
render_grid(ctx, grid, scroll_pos, canvas_width, canvas_height):
    stride = canvas_width / 9
    row_height = canvas_height / 8

    for (row, col, is_down, ci) in WHITELIST_COORDS:
        // Compute triangle vertices
        x_base = col * stride - scroll_pos
        y_base = row * row_height

        if is_down:
            // Down triangle: flat top, point at bottom
            vertices = [
                (x_base, y_base),
                (x_base + stride, y_base),
                (x_base + stride/2, y_base + row_height),
            ]
        else:
            // Up triangle: point at top, flat bottom
            vertices = [
                (x_base + stride/2, y_base),
                (x_base, y_base + row_height),
                (x_base + stride, y_base + row_height),
            ]

        color = triangle_color(row, col, is_down, current_key, scroll_fraction)
        ctx.fillStyle = color
        ctx.beginPath()
        ctx.moveTo(vertices[0])
        ctx.lineTo(vertices[1])
        ctx.lineTo(vertices[2])
        ctx.fill()
```

## Tonnetz Relationship

The triangular grid encodes Tonnetz relationships:
- **Up triangles** = major-type chords
- **Down triangles** = minor-type chords
- Adjacent triangles share two notes (common-tone relationships)
- Horizontal movement = circle of fifths
- Vertical movement = third relationships

## Data Structures Used

- `GridCoord`: struct { row: u4, col: u4, is_down: bool }
- `SliderState`: struct { position: f32, velocity: f32, current_key: u4 }
- `TriangleInfo`: struct { coord: GridCoord, color_index: u4, chord_type: ChordType }
- `Color`: struct { r: u8, g: u8, b: u8 }
- Static: `[12]Color` pitch class colors, `[12]u4` circle-of-fifths reordering

## Dependencies

- [Scale, Mode, and Key](scale-mode-key.md) (for key navigation)
- [Chord Construction](chord-construction-and-naming.md) (for chord identification from grid position)
