# 0026 — Harmonious SVG Compatibility: Staff and Fret Kinds

> Dependencies: 0025
> Blocks: 0027

## Objective

Reach exact harmoniousapp.net compatibility for these kinds:

- `scale`
- `chord`
- `chord-clipped`
- `wide-chord`
- `grand-chord`
- `eadgbe`

## Current Failure Baseline (2026-02-16)

- `scale`: 0/494 exact
- `chord`: 0/1698 exact
- `chord-clipped`: 0/2 exact
- `wide-chord`: 0/1 exact
- `grand-chord`: 0/2032 exact
- `eadgbe`: 0/2278 exact

Post-0025 verification snapshot:

- total remaining mismatches outside `majmin`: 6505
- all remaining staff/fret kinds fail at byte 1 or very early header bytes (renderer family mismatch, not isolated numeric drift)

## Point-in-Time Progress Update (2026-02-16)

Validation status after implementing `scale` Slice 1A (no-mod subset):

- `scale`: `141/494` exact (`no-mod 141/141`, `with-mod 0/353`)
- `chord`: `0/1698` exact
- `chord-clipped`: `0/2` exact
- `wide-chord`: `0/1` exact
- `grand-chord`: `0/2032` exact
- `eadgbe`: `0/2278` exact

Global compatibility snapshot:

- `images=8634`
- `generated=8634`
- `matches=1854`
- `mismatches=6780`
- `missing_ref=0`

First mismatch per remaining kind:

- `scale`: `A,A-4,B-4,C-5,D-5,Es-5,F-5,G-5,A-5.svg`
- `eadgbe`: `-1,-1,-1,0,0,2.svg`
- `wide-chord`: `C_3.svg`
- `chord-clipped`: `C_3,E_3,G_3,B_3.svg`
- `grand-chord`: `A_1,Db_2,E_2,G_2,Bb_2,C_3,Eb_3,Gb_3.svg`
- `chord`: `A_1,Db_2,E_2,G_2,Bb_2,C_3,Eb_3,Gb_3.svg`

Guardrails snapshot:

- Playwright sampled gate still fails (`--sample-per-kind 5`): first mismatch remains in `scale` with-mod subset.
- Playwright full gate still fails: first mismatch remains in `scale` with-mod subset.
- Wasm artifact size remains compliant (`972,489 bytes`, `< 1 MB`).

## Point-in-Time Progress Update (2026-02-17)

Validation status after scale algorithmic parity completion:

- `scale`: `494/494` exact
- `chord`: `0/1698` exact
- `chord-clipped`: `0/2` exact
- `wide-chord`: `0/1` exact
- `grand-chord`: `0/2032` exact
- `eadgbe`: `0/2278` exact

Additional compatibility status in this branch:

- `optc`: `885/885` exact
- exact kinds total: `2207/8634`
- remaining mismatches: `6427`

Playwright gates and wasm guardrails:

- sampled Playwright (`--sample-per-kind 5`) fails with `mismatches=28`, first mismatch in `eadgbe`.
- full Playwright run fails with `mismatches=6427`, first mismatch in `eadgbe`.
- wasm size remains compliant (`992,458 bytes`, `< 1 MB`).

First mismatch per remaining kind:

- `eadgbe`: `-1,-1,-1,0,0,2.svg`
- `wide-chord`: `C_3.svg`
- `chord-clipped`: `C_3,E_3,G_3,B_3.svg`
- `grand-chord`: `A_1,Db_2,E_2,G_2,Bb_2,C_3,Eb_3,Gb_3.svg`
- `chord`: `A_1,Db_2,E_2,G_2,Bb_2,C_3,Eb_3,Gb_3.svg`

## Point-in-Time Progress Update (2026-02-17, Slice: chord-family parity)

Validation status after completing the chord-family exact renderer slice:

- `scale`: `494/494` exact
- `chord`: `1698/1698` exact
- `chord-clipped`: `2/2` exact
- `wide-chord`: `1/1` exact
- `grand-chord`: `2032/2032` exact
- `eadgbe`: `0/2278` exact

Compatibility totals snapshot:

- `images=8634`
- `generated=8634`
- `exact=5940`
- `mismatches=2694`
- `missing_ref=0`

Guardrails and validation slice gates:

- chord-family sampled Playwright validation (`--sample-per-kind 5 --kinds chord,grand-chord,chord-clipped,wide-chord`) passes with `mismatches=0`, `missing_ref=0`.
- wasm artifact remains under the integrity limit after compat changes:
  - `zig-out/wasm-demo/libmusictheory.wasm = 720,068 bytes` (`< 1 MB`).
- full all-kind Playwright validation still fails due remaining non-slice kinds (currently led by `eadgbe`, `majmin/*`).

## Structural Metrics Snapshot (2026-02-16)

### scale (494 files)

- Note-count distribution (stavenotes): `6 => 65`, `7 => 38`, `8 => 364`, `9 => 27`.
- Key-signature path-count distribution (excluding clef path): `0 => 85`, `1 => 90`, `2 => 72`, `3 => 72`, `4 => 69`, `5 => 51`, `6 => 34`, `7 => 21`.
- Per-file modifier path counts inside `vf-modifiers`: `0 => 141`, `1 => 72`, `2 => 145`, `3 => 72`, `4 => 25`, `5 => 11`, `6 => 7`, `8 => 21`.
- 141 files have zero per-note modifiers (`no-mod` subset); 353 files include modifiers (`with-mod` subset).
- Unique notehead y-levels in references: `15`.
- Modifier path families (shape signatures) observed in `scale`: `7`.

No-mod spacing finding:

- For all 141 no-mod files, notehead x positions are an exact arithmetic progression per file (`constant delta` across every adjacent pair in that file).
- The constant delta is bucketed by note count + key-signature profile; representative buckets include:
  - `n8|ks0 => 37.942418750`,
  - `n8|ks3 => 32.942418750` (sharp-family) vs `33.692418750` (flat-family),
  - `n6|ks0 => 50.589891667`,
  - `n6|ks5 => 40.589891667` (sharp-family) vs `42.256558333` (flat-family).

### chord (1698 files)

- One `vf-stavenote` block per file.
- Notehead count distribution per file: `3 => 329`, `4 => 479`, `5 => 518`, `6 => 300`, `7 => 60`, `8 => 12`.
- `vf-modifiers` path presence: `0 => 134`, `1 => 1564`.
- Fixed canvas/viewBox: `170 x 110.76923076923077`.

### grand-chord (2032 files)

- Two `vf-stavenote` blocks per file (treble + bass groups).
- Notehead count distribution per file: `2 => 12`, `3 => 18`, `4 => 396`, `5 => 705`, `6 => 529`, `7 => 300`, `8 => 60`, `9 => 12`.
- `vf-modifiers` path presence per file: `1 => 184`, `2 => 1848`.
- Fixed canvas/viewBox: `170 x 216`.

### chord-clipped (2 files) and wide-chord (1 file)

- `chord-clipped`: one `vf-stavenote`, noteheads `3` or `4`, no modifier paths, clipped viewBox `0 16 170 82.05128205128206`.
- `wide-chord`: two `vf-stavenote`, two noteheads, one modifier path, wide viewBox `0 0 220 216`.

### eadgbe (2278 files)

- Fixed transform wrapper: `<g transform=\"translate(14.5,5)\">` for all files.
- Dot (`sodipodi:type=\"arc\"`) distribution: `0 => 1`, `3 => 492`, `4 => 982`, `5 => 479`, `6 => 324`.
- Text-node count distribution: `0 => 600`, `1 => 1136`, `2 => 534`, `3 => 8`.
- Path count distribution: `8 => 1`, `14 => 198`, `15 => 438`, `16 => 840`, `17 => 622`, `18 => 179`.

## Research Phase

### 1. Staff/Chord Naming and Argument Extraction

- Reverse-map filename grammars to API argument contracts (note spellings, octaves, ordering, key context).
- Confirm generation contexts from `client-side.js`, `kb.js`, and page references.

Research findings:

- `scale` filenames are `key,note,note,...` where each note is spelling+octave (e.g. `A-4`, `Es-5`).
- `chord` / `grand-chord` / `chord-clipped` / `wide-chord` filenames are note lists like `Db_2,Ab_2,Cb_3,G_3.svg`.
- `chord-clipped` is not a different note algorithm; it is a clipped viewport variant of chord staff output.
- `wide-chord` is not the same as `grand-chord`; it uses a wider grand staff canvas and right barline placement rules.
- `eadgbe` filenames are six comma-separated fret integers (`-1` mute, `0` open, `>0` fretted).

Per-kind argument grammar:

- `scale`: `{key_token},{note_1},{note_2},...` with spelled note+octave tokens (`A-4`, `Db_5`, etc.).
- `chord`: comma-separated spelled note+octave list.
- `chord-clipped`: same note grammar as `chord`; only output viewport differs.
- `wide-chord`: same note grammar as `grand-chord`; output canvas/line extents differ.
- `grand-chord`: comma-separated spelled note+octave list over grand staff.
- `eadgbe`: exactly six integers.

### 2. Renderer Delta Analysis

- Compare current `src/svg/staff.zig` and `src/svg/fret.zig` output vs reference bytes.
- Determine if exact compatibility requires VexFlow-like glyph/path output strategy and document the minimal deterministic approach.

Research findings:

- Current renderers are simplified and structurally incompatible:
  - reference uses VexFlow-style path-heavy noteheads/clefs/accidentals and barline rectangles;
  - current output uses simple `<line>`, `<circle>`, and text accidentals.
- Reference files include XML prolog/doctype and exact attribute ordering/precision.
- `chord` and `grand-chord` include deterministic brace/connector and duplicated path fragments not present in current output.
- `eadgbe` reference output is Inkscape-style SVG with specific metadata blocks, path IDs, and marker geometry; current output is a minimal custom fret grid.

Per-kind root cause summary:

- `scale`: wrong renderer family (`simple staff primitives`) and missing prolog/doctype + VexFlow path glyph grammar.
- `chord`: same as `scale` plus incorrect clipped-height layout model.
- `chord-clipped`: currently aliased to `chord`; missing dedicated clipped canvas + exact baseline offsets.
- `wide-chord`: currently aliased to `grand-chord`; missing wide variant dimensions and right barline placement.
- `grand-chord`: wrong renderer family and missing brace/connector path structure.
- `eadgbe`: fully different SVG grammar (Inkscape metadata/ids/paths) and different marker geometry.

Implementation-directed delta notes:

- `scale` should be split into two execution slices:
  - Slice A: no-mod subset (141 files) where x-layout is arithmetic progression with deterministic bucket constants.
  - Slice B: with-mod subset (353 files) where VexFlow-like modifier context spacing is required.
- `chord` / `grand-chord` likely share one layout kernel with different staff topology:
  - single block vs two-block stavenote emission,
  - identical notehead/stem glyph grammar,
  - different header scaffolding.
- `eadgbe` is structurally template-driven with bounded combinatorics (path/text/dot count clusters), making deterministic skeleton + variable-node emission feasible.

### 3. Missing API Methods

- Define and add any missing C/WASM entry points required for:
  - arbitrary note-list staff rendering,
  - clipped/wide variants,
  - grand-staff generation,
  - direct fret URL argument generation.

Research findings:

- Existing public C API only offers `lmt_svg_chord_staff(chord_kind, root, ...)`, which cannot express arbitrary note-list filenames used by compatibility kinds.
- Compatibility API can enumerate/generate by kind/index, but internal rendering still lacks dedicated staff/fret compatibility methods.
- Required internal API additions:
  - `renderScaleStaffCompat(name_stem)`
  - `renderChordStaffCompat(name_stem, variant)`
  - `renderGrandStaffCompat(name_stem, variant)`
  - `renderFretCompat(name_stem)`

## Implementation Steps

### 1. Implement `scale` Exact Renderer

- Rebuild staff output to match reference byte grammar (prolog, rect bars, VexFlow-like note path ordering, key signature glyph path usage).
- Implement note spelling and accidental placement exactly from filename spelling tokens.
- Add deterministic float/number formatting helpers matching reference precision.
- Gate: `scale` reaches 494/494 exact before moving to chord families.

Detailed fix scope:

- Parse spelled note tokens into deterministic staff positions without rewriting enharmonics.
- Emit exact reference header block and stave scaffolding ordering.
- Replace text/shape shorthand with deterministic path glyph emission for clef/key-signature/accidentals/noteheads/stems.
- Deliver in two sub-slices:
  - 1A: no-mod subset (141/494) exact using deterministic key-signature buckets + arithmetic-progression spacing. (`DONE`, 2026-02-16)
  - 1B: with-mod subset (353/494) exact by implementing modifier-aware spacing compatible with VexFlow layout behavior. (`DONE`, 2026-02-17)

### 2. Implement `chord` and `grand-chord` Exact Renderers

- Build exact shared staff engine for chord-like outputs with variant-specific canvas/barline/brace rules.
- Implement both treble-only and grand-staff note placement parity.
- Gate: `chord` 1698/1698 and `grand-chord` 2032/2032 exact.

Detailed fix scope:

- Build shared deterministic staff-glyph kernel from `scale` renderer with variant layout presets.
- Add grand-staff brace/connector path emission and exact staff spacing constants.
- Keep note ordering from filename input (no resorting side effects) to preserve byte identity.

### 3. Implement Variant Wrappers: `chord-clipped` and `wide-chord`

- `chord-clipped`: generate exact clipped `viewBox` and dimensions from chord baseline output.
- `wide-chord`: generate exact wide grand-staff canvas and right-edge rules.
- Gate: `chord-clipped` 2/2 and `wide-chord` 1/1 exact.

Detailed fix scope:

- `chord-clipped`: crop/height and viewBox rules only; no re-render divergence from `chord` glyph layer.
- `wide-chord`: wide grand-staff dimensions and barline endpoint constants only.

### 4. Implement `eadgbe` Exact Renderer

- Replace simplified fret diagram with reference-compatible Inkscape-style output grammar.
- Implement exact placement for:
  - fret window text,
  - open/mute markers,
  - dot and barre geometry,
  - metadata/defs blocks and attribute ordering.
- Gate: `eadgbe` 2278/2278 exact.

Detailed fix scope:

- Implement exact Inkscape-like template skeleton (metadata/defs/groups/id ordering).
- Generate only algorithmic variable nodes (fret numbers, open/mute circles, finger dots/barres) within that fixed skeleton.
- Preserve deterministic attribute ordering/precision and trailing whitespace/newline behavior.

### 5. Verification Lock

- Add sampled and full strict tests per kind under `src/tests/svg_harmonious_compat_test.zig`.
- Keep Playwright sampled (`>=5/kind`) and full gates in `verify.sh`.
- Add regression fixtures: first previously failing sample for each kind.

## Exit Criteria

- `./verify.sh` passes
- `zig build verify` passes
- Exact byte match for all files in listed kinds
- `validation.html` covers all files in listed kinds

## Kind Progress Rule

No work proceeds to 0027 until every kind in this plan meets the 3-point completion rule from 0024.

Within this plan:

1. complete `scale`;
2. complete `chord` + `grand-chord`;
3. complete `chord-clipped` + `wide-chord`;
4. complete `eadgbe`.

Do not start the next step until the current step has full exact parity.

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
