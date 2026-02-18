# 0033 — Graph Rendering Architecture Documentation

> Dependencies: 0024, 0028, 0032
> Blocks: none
> Track: documentation + architecture alignment

## Objective

Create a complete architecture document set under `docs/architecture/graphs/` that:

1. inventories current graph rendering methods in this repository,
2. explains current implementation strategy (algorithmic vs packed template/lookup),
3. documents backend-swappable rendering architecture (SVG + bitmap),
4. maps a concrete migration path to fully algorithmic rendering,
5. includes real sample outputs generated from our current renderer.

Deliverables:

- `docs/architecture/graphs.md`
- per-graph docs in `docs/architecture/graphs/*.md`
- sample assets in `docs/architecture/graphs/samples/*.svg`

## Research Phase (Mandatory)

### 1. Local Method Inventory

- Audit `src/svg/*.zig` and `src/harmonious_svg_compat.zig` entrypoints.
- Map each graph family to methods and output kinds.

### 2. Current Rendering Strategy Audit

- For each graph family, classify implementation:
- algorithmic geometry + serializer
- hybrid (algorithmic + compact patches/shims)
- packed template/compressed payload reconstruction

### 3. Alternative Programmatic Approaches

For each graph family, document alternative generation approaches used in existing ecosystems (notation engines, graph layout libraries, vector/raster toolchains), and identify pros/cons for parity, portability, and wasm footprint.

### 4. Backend Swap Architecture

- Define shared render IR constraints needed for backend swapping (SVG/bitmap) without changing musical logic.
- Define deterministic formatting constraints for compatibility paths.

## Implementation Slices

### Slice 0 — Guardrails in Verification

- Update `./verify.sh` to require graph architecture docs and sample artifacts.

### Slice 1 — Sample Export Pipeline

- Add/maintain a reproducible exporter to generate representative sample SVG outputs from current rendering methods.

### Slice 2 — Per-Graph Architecture Docs

- Add per-graph markdown files with:
- current method inventory
- data dependency map
- algorithmic rendering model
- backend-swappable strategy
- migration slices and risks
- sample references

### Slice 3 — Summary and Future Graphs

- Add `docs/architecture/graphs.md` summarizing:
- current state matrix
- algorithmic gap map
- future harmony graph opportunities inspired by visual research references.

### Slice 4 — Lifecycle Closure

- Move plan to `completed` with implementation history and verification gates.

## Acceptance Criteria

- All architecture docs and sample files exist and are referenced from summary doc.
- `./verify.sh` enforces presence of architecture docs/samples.
- Documentation clearly distinguishes current implementation from target fully algorithmic state.
- Backend swap strategy is explicit and graph-family specific.

## Verification Commands

- `./verify.sh`
- `zig build verify`
- `zig build test`

## Implementation History (Point-in-Time)

_To be filled at completion._
