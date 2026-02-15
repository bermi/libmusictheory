# 0014 — SVG Clock Diagram Generation

> Dependencies: 0006 (Cluster/Evenness)
> Blocks: None (output layer)

## Objective

Generate OPC (colored, 100×100) and OPTC (monochrome, 70×70) clock diagram SVGs matching the site's output.

## Research References

- [Clock Diagrams](../../research/visualizations/clock-diagrams.md)
- [Pitch Class Sets](../../research/pitch-class-sets-and-set-theory.md)

## Implementation Steps

### 1. SVG Writer (`src/svg/clock.zig`)

- Circle position computation: `cx = center + r * sin(n * 30°)`, `cy = center - r * cos(n * 30°)`
- OPC variant: 100×100, colored fills from PC_COLORS
- OPTC variant: 70×70, black/gray/white fills based on cluster membership
- Center label for OPTC: prime form digits

### 2. Font Path Embedding

- Extract glyph paths for digits 0-9, t, e from font data
- Embed as `<path>` elements (not `<text>`) for font independence

### 3. Batch Generation

- Generate all 336 OPTC clock SVGs (one per set class)
- Generate OPC clocks as needed (7 specific ones matching site)

### 4. Tests

- Generated SVGs are valid XML
- Circle positions match expected coordinates (within float tolerance)
- Cluster coloring matches: black for non-cluster, gray for cluster members
- Center labels match prime form notation

## Validation

- Compare generated SVGs against `tmp/harmoniousapp.net/optc/` and `tmp/harmoniousapp.net/opc/` directories (2D coordinate matching)

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
- Generated SVGs are valid XML
- Circle positions match sin/cos at 30-degree intervals within float tolerance
- Cluster coloring matches (black=non-cluster, gray=cluster)
- Center labels match prime form notation
- Coordinate comparison against site `tmp/harmoniousapp.net/optc/` and `tmp/harmoniousapp.net/opc/` directories

## Verification Data Sources

- harmoniousapp.net (`tmp/harmoniousapp.net/optc/` directory — 336 OPTC clock SVGs, `tmp/harmoniousapp.net/opc/` directory — OPC clock SVGs)

## Implementation History (Point-in-Time)

- `fa78877` (2026-02-15):
  - Shipped behavior: Added `src/svg/clock.zig` with clock-circle geometry, OPC and OPTC SVG rendering, cluster-aware monochrome fills, center labels, and batch OPTC file generation for set classes.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~200 lines of Zig SVG generation code + ~100 lines of tests
