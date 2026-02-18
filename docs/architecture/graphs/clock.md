# Clock Graphs (OPC / OPTC)

## Methods

- `src/svg/clock.zig:119` `renderOPC`
- `src/svg/clock.zig:142` `renderOPTC`
- `src/svg/clock.zig:177` `renderOPTCHarmoniousCompat`

## Current Approach

- Uses deterministic polar placement (`circlePosition`) for 12 pitch classes.
- Builds circles/spokes/center labels algorithmically for core OPC/OPTC rendering.
- Compatibility path uses pre-shaped template variants from `src/generated/harmonious_optc_templates.zig` for exact historical formatting behavior.

## Alternative Programmatic Approaches Studied

- D3 radial layouts with layer-specific styling and transition support.
- Graphviz `circo` for circular graph arrangements.
- Cytoscape radial and concentric layout plugins.

Decision:

- Keep custom deterministic radial layout in Zig for parity and low overhead.
- Avoid external layout engines in runtime path.

## Swappable Backend Plan

Layout IR for clock graphs:

- Node ring: `(pc, x, y, state)`
- Edge list: `(from, to, style)`
- Center annotation: `(label, style)`

Backends:

- SVG backend renders circles/paths/text.
- Bitmap backend paints same IR primitives to RGBA canvas.

## Path to Fully Algorithmic

1. Remove remaining OPTC compat variant template dependencies.
2. Encode variant semantics as rules (`cluster mask`, `dash mask`, `highlight mask`) over shared geometry.
3. Keep canonical serializer policy for exact SVG parity.

## Samples

- ![Core OPC](samples/core-opc.svg)
- ![Core OPTC](samples/core-optc.svg)
- ![Compat OPTC](samples/compat-optc.svg)
