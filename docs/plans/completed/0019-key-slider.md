# 0019 — Key Slider and Tonnetz Grid

> Dependencies: 0010 (Harmony)
> Blocks: None (output/interaction layer)

## Objective

Implement the interactive key slider: Tonnetz-like triangular grid, momentum scrolling, snap-to-grid detente, and color blending between adjacent keys.

## Research References

- [Key Slider and Tonnetz](../../research/algorithms/key-slider-and-tonnetz.md)
- [Guitar and Keyboard](../../research/data-structures/guitar-and-keyboard.md) (SliderState, GridCoord, Color types)
- [Keys, Harmony and Progressions](../../research/keys-harmony-and-progressions.md)

## Implementation Steps

### 1. Slider State (`src/slider.zig`)

- `SliderState` struct: position, velocity, current_key, canvas dimensions
- `updateScroll(position, velocity) → (position, velocity)` with friction 0.96
- Snap-to-grid detente when velocity < threshold

### 2. Triangular Grid

- `GridCoord` struct: row, col, is_down_triangle
- Whitelist of valid coordinates
- `handleTap(x, y, canvas_dims, scroll_offset) → ?GridCoord`
- Triangle boundary detection via linear inequalities

### 3. Color System

- 12 pitch-class colors as Color structs
- `colorIndex`: circle-of-fifths reordering [2,7,0,5,10,3,8,1,6,11,4,9]
- `blend(Color, Color, f32) → Color` — linear RGB interpolation
- `triangleColor(GridCoord, key_idx, scroll_fraction) → Color`

### 4. URL ↔ Grid Mapping

- `urlPathToQuad(path) → [4]u4` — URL to grid coordinates
- `quadToUrlPath(quad) → []const u8` — grid to URL

### 5. Easing Function

- `ease(t) → f32` — sigmoid: `-cos(t * π) * 0.5 + 0.5`

### 6. Canvas Rendering Data

- Provide triangle vertex positions for any grid state
- Color data for each triangle
- The Zig library computes positions and colors; actual rendering happens in client code (browser canvas, native GPU, etc.)

### 7. Tests

- Snap-to-grid: velocity decay reaches zero, position snaps to stride boundary
- Tap detection: known pixel → expected grid coordinate
- Color blending: (R=255, G=0, B=0) blend 50% with (R=0, G=0, B=255) → (R=127, G=0, B=127)
- Easing: ease(0)=0, ease(0.5)=0.5, ease(1)=1
- URL round-trip

## Validation

- `tmp/harmoniousapp.net/js-client/slider.js`: complete reference implementation (865 lines)
- `tmp/harmoniousapp.net/js-client/slider.js` data: `pcColors`, `colorIndex`, `whitelistCoords`

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

- `./verify.sh` passes
- `zig build verify` passes
- Snap-to-grid: velocity decay reaches zero and position snaps
- Tap detection matches known pixel-to-grid mappings from `slider.js`
- Color blending produces correct intermediate values
- Easing function: `ease(0)=0`, `ease(0.5)=0.5`, `ease(1)=1`
- URL round-trip correct

## Verification Data Sources

- **harmoniousapp.net**:
  - `tmp/harmoniousapp.net/js-client/slider.js` — complete 865-line reference implementation including `pcColors`, `colorIndex`, `whitelistCoords` data

## Implementation History (Point-in-Time)

- `7f03ae8ee2adb0ca3ee98f177006a56956fdccac` (2026-02-15):
  - Shipped behavior: added `src/slider.zig` with slider physics (`updateScroll`) using 0.96 friction, low-velocity detente snap, triangular grid hit-testing with whitelist coordinates from `slider.js`, color blending and circle-of-fifths color-index mapping, easing function, URL quad encode/decode, and triangle geometry helpers. Added `src/tests/slider_test.zig` for easing, blend, URL round-trip, detente convergence, tap detection, and color-index verification. Added `0019` gate in `./verify.sh`, exported `slider` in `src/root.zig`, and imported slider tests.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~250 lines of Zig code + ~150 lines of tests
