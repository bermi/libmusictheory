# Render Quality

`libmusictheory` now treats render quality as a first-class concern for non-compat generated SVGs.

## Contract Split

- Exact harmonious compatibility output is a reproduction contract and must stay visually frozen.
- Non-compat generated SVGs use a shared quality prelude:
  - canonical SVG open tag with geometric precision flags
  - shared font stacks
  - shared outline/stroke conventions for text
  - consistent non-scaling stroke behavior
- Native RGBA proof/parity raster output uses coverage-based edge antialiasing in Zig:
  - circles and stroked lines blend edge coverage instead of using hard thresholds
  - polygon/path fills sample multiple sub-rows per pixel row and accumulate fractional coverage
  - the browser pages display the actual Zig-generated bitmap; no CSS or canvas scaling trick is used to hide raster defects

## Why This Split Exists

The repo now has two different obligations:

1. reproduce harmoniousapp.net exactly
2. expose a good-looking general-purpose rendering library

Those obligations conflict if they share one visual contract. The fix is additive: preserve exact compat output, improve the library-native generators.

## Immediate Benefits

- better cross-platform text consistency
- clearer label contrast on colored nodes
- more stable stroke treatment when scaled in browsers and host UIs
- one place to evolve shared SVG presentation rules
- proof/parity bitmap previews no longer rely on staircase edges for circles, diagonals, and polygon fills
