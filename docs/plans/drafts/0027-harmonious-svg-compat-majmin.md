# 0027 — Harmonious SVG Compatibility: MajMin Tessellation Kinds

> Dependencies: 0026
> Blocks: None

## Objective

Reach exact harmoniousapp.net compatibility for:

- `majmin/modes,*.svg`
- `majmin/scales,*.svg`

## Current Failure Baseline (2026-02-16)

- `majmin/modes`: 0/366 exact
- `majmin/scales`: 0/50 exact

Post-0025 verification snapshot:

- all `majmin` files are still mismatching at the root SVG structure level (header/canvas/DOM shape mismatch), not just style differences.

## Structural Metrics Snapshot (2026-02-16)

- Total files: `416` (`modes => 366`, `scales => 50`).
- Dominant canvas: `viewBox=\"0 0 300 360\"` for `412` files.
- Outlier canvases: `0 0 436 510` (2 files) and `0 0 708 510` (2 files).
- Path-count clusters per file:
  - major clusters: `362`, `364`, `370`, `372`, `374`,
  - secondary cluster: `324`,
  - outliers: `510`, `578`, `748`, `846`.
- Link-count (`<a href=...>`) clusters per file:
  - major clusters: `115`, `121`, `139`, `145`, `151`, `153`,
  - outliers: `204`, `240`, `294`, `352`.
- Empty-group (`<g/>`) clusters per file:
  - major clusters: `190`, `308`, `310`, `312`, `318`, `320`,
  - outliers: `141`, `169`, `286`, `302`.

These metrics confirm that `majmin` references are not one-template outputs; they are topology families with deterministic but non-trivial group/link cardinalities.

## Research Phase

### 1. MajMin Argument and Topology Mapping

- Reverse-map `majmin` filename fields (mode/scales prefixes, transposition, shape markers, indices).
- Confirm relation to tessellation graph/shape logic and any hidden special-case files.

Research findings:

- Filenames encode at least four fields: `{family},{transpose},{shape_or_variant},{index}`.
- `modes,*` and `scales,*` are distinct visual datasets and must not share one static renderer output.
- Current compatibility path ignores filename arguments and always emits one generic tessellation SVG.

Per-kind argument grammar:

- `modes,{transpose},{shape},{index}.svg`
- `scales,{transpose},{shape},{index}.svg`

These argument slots are semantically active in references and must drive tile/link highlighting.

### 2. Renderer Delta Analysis

- Compare current tessellation output and naming vs reference set.
- Document required deterministic ordering rules (tile ordering, edge ordering, numeric precision, transform formatting).

Research findings:

- Current `src/svg/tessellation.zig` output differs fundamentally:
  - wrong canvas (`300x360` vs many references at `436x510`),
  - wrong primitive set (colored labeled polygons vs multi-layer gray beveled tiles with link wrappers),
  - missing per-file highlighted/linked subsets and exact `<a href="/p/...">` structure.
- Byte parity requires reproducing exact grouping/order of `<g>`, `<path>`, and link nodes, including empty groups.

Per-kind root cause summary:

- `majmin/modes`: currently uses generic tessellation renderer with wrong canvas and no argument-driven highlighting.
- `majmin/scales`: same renderer mismatch plus family-specific link/selection rules not implemented.

Implementation-directed delta notes:

- Renderer must branch by topology family before style selection:
  - base `300x360` family (majority),
  - `436x510` and `708x510` outlier families.
- Link and empty-group counts are stable family signals and can be used as deterministic regression sentinels.
- Completion should enforce family coverage first, then per-file highlighting parity.

### 3. API Contract Completion

- Define final compatibility API methods for MajMin name enumeration and rendering.

Research findings:

- Enumeration already exists via compatibility manifest.
- Missing internal method contract is a deterministic `renderMajminCompat(stem)` that uses parsed filename args to drive exact output selection/composition.

## Implementation Steps

### 1. Implement MajMin Argument Parser

- Parse and validate `modes` and `scales` filename fields into an internal `MajminSpec`.
- Add strict unit tests for parser coverage, including edge cases (`-1`, empty fields, variant aliases).

Detailed fix scope:

- Parse CSV fields exactly as encoded in filenames (including empty middle fields).
- Normalize family discriminator (`modes` vs `scales`) into separate render branches.

### 2. Implement Shared Geometry/Ordering Kernel

- Build deterministic geometry and emission ordering that matches reference coordinate precision and group ordering.
- Reproduce empty `<g/>` placement and `<a href>` wrapping rules exactly.
- Keep rendering algorithmic; no runtime loading of reference SVG payloads.

Detailed fix scope:

- Reproduce fixed canvas and static frame groups first.
- Emit deterministic tile/link groups using sorted stable ordering keyed by parsed args.
- Match exact whitespace/newline placement once geometry is stable.
- Implement topology-family dispatch (`300x360`, `436x510`, `708x510`) before per-argument highlighting.

### 3. Implement `modes,*` Exact Rendering

- Use `MajminSpec` to select highlighted/linked cells and style state for all 366 `modes` files.
- Gate: `modes` reaches 366/366 exact before implementing `scales`.

### 4. Implement `scales,*` Exact Rendering

- Apply corresponding `scales` selection/mapping rules for all 50 files.
- Gate: `scales` reaches 50/50 exact.

### 5. Final Validation Closure

- Add full MajMin exact-match tests.
- Ensure `validation.html` generates and verifies every `majmin` file.

### 6. Coordinator/History Updates

- Move all completed compatibility plans through lifecycle states.
- Record commit history entries and verification commands.

## Exit Criteria

- `./verify.sh` passes
- `zig build verify` passes
- Exact byte match for all `majmin` files
- `validation.html` complete for all requested harmoniousapp.net kinds

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
