# Graph Rendering Architecture

This document summarizes how `libmusictheory` currently renders graph-like music diagrams, where replay/compressed payloads still exist, and how we move to fully algorithmic rendering with swappable SVG/bitmap backends.

## Scope

Primary renderer and compatibility entrypoints:

- `src/harmonious_svg_compat.zig`
- `src/svg/clock.zig`
- `src/svg/mode_icon.zig`
- `src/svg/staff.zig`
- `src/svg/chord_compat.zig`
- `src/svg/scale_nomod_compat.zig`
- `src/svg/fret.zig`
- `src/svg/fret_compat.zig`
- `src/svg/evenness_chart.zig`
- `src/svg/tessellation.zig`
- `src/svg/majmin_compat.zig`
- `src/svg/orbifold.zig`
- `src/svg/circle_of_fifths.zig`
- `src/svg/text_misc.zig`

## Current State Matrix

| Graph family | Current implementation | Data dependency profile | Backend swap readiness |
|---|---|---|---|
| OPC / OPTC clock graphs | mostly algorithmic geometry | low (templates for compat variants) | high |
| OC mode icons | template-driven icon body replacement | medium | medium |
| Staff graphs (`scale/chord/grand`) | compatibility-first exact emitters | medium-high (patch/shim data) | medium |
| Fretboard graphs | compatibility template + algorithmic fret logic | medium | medium |
| Evenness charts | algorithmic dots + compressed compat payloads | medium | high |
| Tessellation graphs | algorithmic base tessellation | low | high |
| Majmin graphs | compressed packed reconstruction | high | low |
| Orbifold graphs | algorithmic node/edge generation | low | high |
| Circle of fifths / key sig | algorithmic | low | high |
| Text/glyph labels | template path lookup | medium | medium |

## Backend-Swappable Target Architecture

Render stack target for all graph families:

1. `MusicModel`: pure theory/state model (sets, keys, relations, metadata).
2. `LayoutModel`: deterministic geometry (nodes, edges, glyph anchors, label bounds).
3. `RenderIR`: backend-neutral primitives (`Path`, `Circle`, `Line`, `Text`, `Group`, `Transform`, `Style`).
4. `Backends`:
- `SvgBackend`: strict canonical serializer (for parity and web docs).
- `BitmapBackend`: raster painter over same IR (mobile/plugin/offscreen rendering).

Key rule: theory and layout layers must never depend on serializer quirks.

## Canonical Determinism Rules

Required for exact compat and stable cross-platform output:

- Stable primitive order and z-order.
- Deterministic float quantization policy by primitive class.
- Canonical style ordering and whitespace policy.
- Seeded/random-free layout for all graph families.

## Sample Outputs (Current Renderer)

Generated with `zig run export_graph_samples.zig`:

- ![Core OPC](graphs/samples/core-opc.svg)
- ![Core Tessellation](graphs/samples/core-tessellation.svg)
- ![Core Orbifold](graphs/samples/core-orbifold.svg)
- ![Compat Chord](graphs/samples/compat-chord.svg)
- ![Compat Scale](graphs/samples/compat-scale.svg)

## Per-Graph Docs

- [Clock Graphs](graphs/clock.md)
- [Mode Icon Graphs](graphs/mode-icons.md)
- [Staff Graphs](graphs/staff.md)
- [Fretboard Graphs](graphs/fretboard.md)
- [Evenness Graphs](graphs/evenness.md)
- [Tessellation and Majmin Graphs](graphs/tessellation-majmin.md)
- [Orbifold Graphs](graphs/orbifold.md)
- [Circle of Fifths Graphs](graphs/circle-of-fifths.md)
- [Text and Glyph Graphs](graphs/text-glyphs.md)
- [Future Harmony Graphs](graphs/future-harmony-graphs.md)

## Future Harmony Graph Opportunities

Based on harmony relation patterns and visual references, candidate additions include:

- Directed transformational chord networks (operation-colored edges).
- Radial extension webs for diatonic/borrowed/altered chord families.
- Hierarchical harmonic trees (cadential root + branch pathways).
- Multi-layer modulation manifolds with voice-leading cost overlays.
- Fractal progression expanders (motif substitution recursion with constraints).

Detailed concepts and implementation strategy are in [Future Harmony Graphs](graphs/future-harmony-graphs.md).
