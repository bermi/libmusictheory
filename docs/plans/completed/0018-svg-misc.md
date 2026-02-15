# 0018 — Miscellaneous SVG Visualizations

> Dependencies: 0010 (Harmony), 0011 (Voice Leading), 0006 (Cluster/Evenness)
> Blocks: None (output layer)

## Objective

Generate the remaining SVG visualization types: mode icons (tmp/harmoniousapp.net/oc/), evenness dart-board chart (tmp/harmoniousapp.net/even/), orbifold graph, circle of fifths, key signatures, and various labels/icons.

## Research References

- [Mode Icons](../../research/visualizations/mode-icons.md)
- [Evenness Chart](../../research/visualizations/evenness-chart.md)
- [Orbifold Graph](../../research/visualizations/orbifold-graph.md)
- [Circle of Fifths and Key Signatures](../../research/visualizations/circle-of-fifths-and-key-signatures.md)

## Implementation Steps

### 1. Mode Icons (`src/svg/mode_icon.zig`)

- 70×70 px squares with Roman numeral labels
- Color from pitch-class color scheme
- Generate for all scale types × transpositions × degrees
- File naming: `tmp/harmoniousapp.net/oc/{scale_abbrev},{transposition},{roman_numeral}.svg`
- ~564 SVGs

### 2. Evenness Dart-Board Chart (`src/svg/evenness_chart.zig`)

- Polar layout: concentric rings by cardinality, radial by evenness distance
- Dots colored by cluster-free status (teal vs gray)
- Labels with Forte numbers
- Single large SVG (tmp/harmoniousapp.net/even/index.svg)

### 3. Orbifold Graph (`src/svg/orbifold.zig`)

- Force-directed or geometric layout of triad network
- Nodes = chord circles, edges = single-semitone VL connections
- Augmented triads at center, major/minor surrounding, diminished at edges
- Single SVG (tmp/harmoniousapp.net/svg/triads-graphviz-maj-min-orbifold.svg)

### 4. Circle of Fifths (`src/svg/circle_of_fifths.zig`)

- 12 positions, major keys outer ring, minor keys inner ring
- Colored by pitch-class colors
- Enharmonic labels at 5/6/7 o'clock positions
- Single SVG (tmp/harmoniousapp.net/svg/cofclock.svg)

### 5. Key Signature SVGs (`src/svg/key_sig.zig`)

- Small staff segments with clef + accidentals
- Sharps in order F C G D A E B at correct staff positions
- Flats in order B E A D G C F at correct staff positions

### 6. Vertical Text Labels

- Forte number labels for table row headers
- `tmp/harmoniousapp.net/vert-text-black/`: 115 top-to-bottom labels
- `tmp/harmoniousapp.net/vert-text-b2t-black/`: 115 bottom-to-top labels
- `tmp/harmoniousapp.net/center-square-text/`: 24 single-letter glyphs (36×36px)

### 7. N-TET Chart

- Comparison chart of equal temperament systems
- Shows interval accuracy vs just intonation

### 8. Tests

- All generated SVGs are valid XML
- Mode icon colors match expected pitch-class colors
- Circle of fifths positions are correctly ordered
- Evenness chart has correct number of dots per cardinality ring

## Validation

- Compare against `tmp/harmoniousapp.net/oc/`, `tmp/harmoniousapp.net/even/`, `tmp/harmoniousapp.net/svg/`, `tmp/harmoniousapp.net/vert-text-black/`, `tmp/harmoniousapp.net/vert-text-b2t-black/`, `tmp/harmoniousapp.net/center-square-text/` directories

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
- All generated SVGs are valid XML
- Mode icon colors match pitch-class color scheme
- Circle of fifths positions correctly ordered (C G D A E B F# at sharps, F Bb Eb Ab Db Gb at flats)
- Evenness chart has correct number of dots per cardinality ring

## Verification Data Sources

- **harmoniousapp.net**:
  - `tmp/harmoniousapp.net/oc/` directory — 564 mode icon SVGs
  - `tmp/harmoniousapp.net/even/` directory
  - `tmp/harmoniousapp.net/svg/cofclock.svg`
  - `tmp/harmoniousapp.net/svg/triads-graphviz-maj-min-orbifold.svg`
  - `tmp/harmoniousapp.net/vert-text-black/`
  - `tmp/harmoniousapp.net/center-square-text/`

## Implementation History (Point-in-Time)

- `64e779a98bc73a608914ed3875448ff9caa072f4` (2026-02-15):
  - Shipped behavior: added misc SVG modules `src/svg/mode_icon.zig`, `src/svg/evenness_chart.zig`, `src/svg/orbifold.zig`, `src/svg/circle_of_fifths.zig`, `src/svg/key_sig.zig`, plus `src/svg/text_misc.zig` and `src/svg/n_tet_chart.zig`. Added `src/tests/svg_misc_test.zig` covering mode-icon color mapping, evenness dot-count cardinality distribution, circle-of-fifths order, orbifold validity, key-signature accidental count, vertical/center text validity, and N-TET chart validity. Added `0018` gate in `./verify.sh` and exported new modules from `src/root.zig`.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~400 lines of Zig SVG code across 6 sub-generators + ~200 lines of tests
