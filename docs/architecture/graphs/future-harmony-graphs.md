# Future Harmony Graphs

This document captures future graph families motivated by harmony-relationship visuals (including the reference screenshots shared in this thread).

## Candidate Graph Families

## 1. Transformational Chord Networks

Model:

- Nodes: chord classes or concrete voiced chords.
- Edges: labeled transformations (`Tn`, inversion, modal exchange, neo-Riemannian moves, altered extensions).
- Edge style: operation family color + direction arrows.

Use cases:

- explain transformational paths between tonal centers,
- interactive reharmonization suggestions.

## 2. Radial Extension Webs

Model:

- Inner ring: base diatonic chords.
- Outer rings: add9/add11/add13/altered variants.
- Connectors: inheritance and alteration edges.

Use cases:

- visualize extension ladders and functional substitution options.

## 3. Harmonic Trees and Fractals

Model:

- Root: tonic/cadential anchor.
- Branches: progression expansions under substitution rules.
- Depth semantics: complexity/tension growth.

Use cases:

- educational branching examples,
- generative progression exploration.

## 4. Modulation Manifolds

Model:

- Multi-layer graph of keys/chords with voice-leading cost surfaces.
- Directed paths weighted by modulation smoothness.

Use cases:

- route planning for key changes,
- comparative analysis of modulation strategies.

## 5. Multi-scale Harmonic Ecosystems

Model:

- Nested rings/clusters of diatonic, borrowed, dominant, and chromatic structures.
- Optional curved trajectory overlays for common cadence families.

Use cases:

- macro harmony maps for arrangement/composition.

## Common Data Primitives Needed

- Chord/node identity (`pcs`, spelling, function).
- Relation type catalog (transform, function, voice-leading delta).
- Edge direction + cost + style channels.
- Layout policy (`radial`, `tree`, `force`, `lattice`, `hybrid`).

## Backend Strategy

All future graphs should be authored through shared `LayoutModel -> RenderIR -> Backend` flow:

- SVG backend: deterministic static outputs and parity-friendly tests.
- Bitmap backend: high-performance interactive rendering for mobile/plugins.

## Phased Delivery Recommendation

1. Start with deterministic radial transformational network (closest to current clock graph strengths).
2. Add extension web layer atop same node model.
3. Introduce tree/fractal expansion renderer using shared edge semantics.
4. Add manifold overlays and cost heatmaps once core IR stabilizes.
