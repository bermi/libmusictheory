# 0001 — libmusictheory Project Coordinator

## Project Overview

Build `libmusictheory`, a Zig library exposing a C ABI that implements the complete music theory framework from harmoniousapp.net. The library will power:
- Static site generation (reproducing harmoniousapp.net)
- Music composition plugins (DAW integration)
- LLM agents for music theory reasoning

## Lifecycle Status

- Draft: 0001, 0029, 0030, 0031
- In progress: 0032
- Completed: 0002, 0003, 0004, 0005, 0006, 0007, 0008, 0009, 0010, 0011, 0012, 0013, 0014, 0015, 0016, 0017, 0018, 0019, 0020, 0021, 0022, 0023, 0024, 0025, 0026, 0027, 0028, 0033

## Plan Dependencies (Execute in Order)

```
0002-core-types          → Foundation: PitchClass, PitchClassSet, MidiNote, NoteName
0003-set-operations      → Bitwise PCS operations, transposition, complement
     ↓ depends on 0002
0004-set-classification  → Prime form, Forte numbers, OPTIC equivalences
     ↓ depends on 0003
0005-interval-analysis   → Interval vectors, FC-components, Z/M-relations
     ↓ depends on 0004
0006-cluster-evenness    → Chromatic cluster detection, evenness metrics
     ↓ depends on 0004, 0005
0007-scales-modes        → Scale types, 17 modes, mode identification
     ↓ depends on 0003
0008-keys-signatures     → Key signatures, note spelling, circle of fifths
     ↓ depends on 0007
0009-chord-construction  → Chord types, formulas, The Game algorithm
     ↓ depends on 0006, 0007
0010-harmony-analysis    → Roman numerals, diatonic harmony, avoid notes
     ↓ depends on 0008, 0009
0011-voice-leading       → VL distance, optimal assignment, orbifold geometry
     ↓ depends on 0006
0012-guitar-fretboard    → Tunings, fret mapping, CAGED, voicing generation
     ↓ depends on 0009
0013-keyboard-interaction → Keyboard state, toggle, URL persistence
     ↓ depends on 0008
0014-svg-clock-diagrams  → OPC/OPTC clock diagram SVG generation
     ↓ depends on 0006
0015-svg-staff-notation  → Chord/scale staff notation SVG generation
     ↓ depends on 0008, 0009
0016-svg-fret-diagrams   → Guitar fret diagram SVG generation
     ↓ depends on 0012
0017-svg-tessellation    → Scale tessellation map SVG generation
     ↓ depends on 0007, 0011
0018-svg-misc            → Mode icons, evenness chart, orbifold graph, CoF
     ↓ depends on 0010, 0011, 0006
0019-key-slider          → Tonnetz grid, scrolling, color blending
     ↓ depends on 0010
0020-c-abi               → C ABI wrapper, header generation, documentation
     ↓ depends on ALL above
0021-static-tables       → Compile-time precomputation of all lookup tables
     ↓ depends on 0004, 0005, 0006
0022-testing             → Comprehensive test suite validating against site data
     ↓ depends on ALL above
0023-wasm-interactive-docs → Browser-hosted WASM interactive documentation demo
     ↓ depends on 0020, 0022
0024-harmonious-svg-compat-foundation → compatibility API + exact-match harness + wasm validation page
     ↓ depends on 0020, 0022, 0023
0028-harmonious-svg-compat-integrity-guardrails → anti-cheating constraints + wasm size gate + verification hardening
     ↓ depends on 0024
0025-harmonious-svg-compat-text-clock-mode-even → exact parity for text/clock/mode/even kinds
     ↓ depends on 0028
0026-harmonious-svg-compat-staff-fret → exact parity for staff/chord/fret kinds
     ↓ depends on 0025
0027-harmonious-svg-compat-majmin → exact parity for majmin kinds and closure
     ↓ depends on 0026
0029-rendering-ir-dual-backend-foundation → shared deterministic rendering IR (SVG parity preserved)
     ↓ depends on 0024, 0028 (parallel/additive track)
0030-zig-raster-backend-native → optional native raster backend from shared IR
     ↓ depends on 0029
0031-compat-visual-diff-diagnostics → Playwright visual diff diagnostics (non-blocking)
     ↓ depends on 0024, 0028 (parallel/additive track)
0032-scale-compat-pure-algorithmic-renderer → remove replay-style `scale` data dependencies while preserving exact parity
     ↓ depends on 0028 (integrity baseline)
0033-graph-rendering-architecture-docs → architecture inventory + algorithmic/dual-backend migration docs per graph family
     ↓ depends on 0024, 0028, 0032 (parallel/additive track)
```

## Dependency Graph (Visual)

```
         0002 (Core Types)
            │
         0003 (Set Operations)
          ┌─┴──────┐
       0004       0007 (Scales)
      (Set Class)   │
       ┌─┴─┐      0008 (Keys)
     0005 0006      │
     (IV)  (Clust)  │
       │    │    ┌──┴──┐
       │    │  0009   0013
       │    │ (Chords) (KB)
       │    │    │
       │    │  0010 (Harmony)
       │    │    │      │
       │   0011  │    0019
       │  (VL)   │  (Slider)
       │    │    │
     0014 0017 0015  0012
    (Clock)(Tess)(Staff)(Guitar)
       │    │    │      │
     0018  0017 0015  0016
    (Misc)              (Fret)
       │
     0020 (C ABI) ← ALL
       │
     0021 (Tables)
       │
     0022 (Tests)
       │
     0023 (WASM Docs)
       │
     0024 (SVG Compat Foundation)
       │
     0028 (Compat Integrity Guardrails)
       │
     0025 (Compat Text/Clock/Mode/Even)
       │
     0026 (Compat Staff/Fret)
       │
     0027 (Compat MajMin)
```

Supplementary additive track (does not replace strict SVG parity):

```
0024 + 0028
   │
 0029 (Rendering IR)
   │
 0030 (Native Raster Backend, optional)

0024 + 0028
   │
 0031 (Visual Diff Diagnostics, non-blocking)
```

## Phase Summary

### Phase 1: Core Data Layer (Plans 0002-0006)
Implement the foundational types and algorithms. All music theory primitives: pitch classes, pitch class sets, set classification, interval analysis, cluster detection, and evenness metrics. No dependencies outside this phase.

**Deliverable**: A self-contained module that can classify any pitch class set.

### Phase 2: Musical Structures (Plans 0007-0011)
Build the named musical concepts: scales, modes, keys, chords, harmony analysis, and voice leading. Depends on Phase 1.

**Deliverable**: A module that can name any chord in any key, compute voice-leading distances, and analyze tonal function.

### Phase 3: Instrument Interfaces (Plans 0012-0013)
Guitar fretboard and keyboard-specific algorithms. Depends on Phases 1-2.

**Deliverable**: Guitar voicing generation, CAGED system, keyboard interaction state.

### Phase 4: SVG Generation (Plans 0014-0019)
All visualization outputs: clock diagrams, staff notation, fret diagrams, tessellation maps, mode icons, evenness charts, orbifold graphs, circle of fifths, and the key slider.

**Deliverable**: Pure Zig SVG generation for all visualization types.

### Phase 5: Integration (Plans 0020-0023)
C ABI wrapper, compile-time table generation, and comprehensive testing.

**Deliverable**: `libmusictheory.h` + `libmusictheory.a` usable from any language.

### Phase 6: Harmonious SVG Exact Compatibility (Plans 0024-0027)
Compatibility-driven exact byte match against local harmoniousapp.net SVG references, with API-driven filename/argument generation and WASM validation coverage per kind.

**Deliverable**: exact compatibility verification for all required `tmp/harmoniousapp.net/<kind>/` SVG families.

### Phase 6.5: Harmonious SVG Integrity Guardrails (Plan 0028)
Lock verification so exact-match progress cannot be faked with embedded reference payloads or oversized wasm artifacts.

**Deliverable**: anti-cheating constraints enforced by verification (`wasm < 1MB`, no reference-svg embedding in generation path, strict Playwright validation).

### Phase 7 (Additive): Shared Rendering IR + Native Raster + Visual Diagnostics (Plans 0029-0031)
Add optional rendering infrastructure and diagnostics for native/mobile/plugin consumers while keeping SVG byte-parity as the sole compatibility completion target.

**Deliverable**: backend-agnostic rendering pipeline and optional raster/visual-debug tooling that does not relax exact SVG verification.

## Research Documents Index

### Theme Research
- [Pitch and Intervals](../../research/pitch-and-intervals.md)
- [Pitch Class Sets and Set Theory](../../research/pitch-class-sets-and-set-theory.md)
- [Scales and Modes](../../research/scales-and-modes.md)
- [Chords and Voicings](../../research/chords-and-voicings.md)
- [Keys, Harmony and Progressions](../../research/keys-harmony-and-progressions.md)
- [Evenness, Voice Leading and Geometry](../../research/evenness-voice-leading-and-geometry.md)
- [Guitar and Keyboard](../../research/guitar-and-keyboard.md)
- [WASM Footprint Audit](../../research/wasm-footprint.md)

### Algorithm Research
- [Pitch Class Set Operations](../../research/algorithms/pitch-class-set-operations.md)
- [Prime Form and Set Class](../../research/algorithms/prime-form-and-set-class.md)
- [Interval Vector and FC Components](../../research/algorithms/interval-vector-and-fc-components.md)
- [Chromatic Cluster Detection](../../research/algorithms/chromatic-cluster-detection.md)
- [Evenness and Consonance](../../research/algorithms/evenness-and-consonance.md)
- [Voice Leading](../../research/algorithms/voice-leading.md)
- [Scale, Mode, Key](../../research/algorithms/scale-mode-key.md)
- [Chord Construction and Naming](../../research/algorithms/chord-construction-and-naming.md)
- [Guitar Voicing](../../research/algorithms/guitar-voicing.md)
- [Note Spelling](../../research/algorithms/note-spelling.md)
- [Keyboard Interaction](../../research/algorithms/keyboard-interaction.md)
- [Key Slider and Tonnetz](../../research/algorithms/key-slider-and-tonnetz.md)

### Data Structure Research
- [Pitch and Pitch Class](../../research/data-structures/pitch-and-pitch-class.md)
- [Pitch Class Set](../../research/data-structures/pitch-class-set.md)
- [Intervals and Vectors](../../research/data-structures/intervals-and-vectors.md)
- [Set Class and Classification](../../research/data-structures/set-class-and-classification.md)
- [Scales, Modes, Keys](../../research/data-structures/scales-modes-keys.md)
- [Chords and Harmony](../../research/data-structures/chords-and-harmony.md)
- [Guitar and Keyboard](../../research/data-structures/guitar-and-keyboard.md)
- [Voice Leading and Geometry](../../research/data-structures/voice-leading-and-geometry.md)

### Visualization Research
- [Clock Diagrams](../../research/visualizations/clock-diagrams.md)
- [Staff Notation](../../research/visualizations/staff-notation.md)
- [Fret Diagrams](../../research/visualizations/fret-diagrams.md)
- [Mode Icons](../../research/visualizations/mode-icons.md)
- [Tessellation Maps](../../research/visualizations/tessellation-maps.md)
- [Evenness Chart](../../research/visualizations/evenness-chart.md)
- [Orbifold Graph](../../research/visualizations/orbifold-graph.md)
- [Circle of Fifths and Key Signatures](../../research/visualizations/circle-of-fifths-and-key-signatures.md)

## Source Material Reference

All algorithms and data are extracted from the static capture of harmoniousapp.net located at:
```
/Users/bermi/code/music-composition/harmoniousapp.net/
```

Key source files:
- `tmp/harmoniousapp.net/js-client/pitch-class-sets.js` (892 lines) — Core music theory engine
- `tmp/harmoniousapp.net/js-client/kb.js` (343 lines) — Keyboard interaction
- `tmp/harmoniousapp.net/js-client/frets.js` (434 lines) — Fretboard interaction
- `tmp/harmoniousapp.net/js-client/slider.js` (865 lines) — Key slider
- `tmp/harmoniousapp.net/js-client/client-side.js` (964 lines) — Main app
- `tmp/harmoniousapp.net/p/31/Glossary.html` — Master glossary with 90+ entries
- `tmp/harmoniousapp.net/p/` directory — 3,578 theory articles

## Success Criteria

1. All 336 set classes correctly classified with matching Forte numbers
2. All 17 mode types correctly identified and named
3. All ~100 chord types correctly constructed and named
4. The Game algorithm produces ~479 cluster-free OTC objects matching 17 modes
5. Note spelling matches harmoniousapp.net for all 70+ key/scale contexts
6. Guitar voicing generation produces playable CAGED positions
7. All SVG visualization types generate valid SVGs matching site output
8. C ABI compiles and links from C, Python, and other languages
9. Compile-time tables match runtime computation results
10. All static data can be verified against site content
11. All required harmoniousapp.net SVG kinds can be generated through library APIs and match reference SVG bytes exactly
12. Any raster/visual diagnostic additions remain additive and must not weaken strict SVG parity gates

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

All of the following must pass before this plan is considered complete:

- [ ] `./verify.sh` passes
- [ ] All required sub-plans (0002–0028) completed and verified
- [ ] If additive rendering track is adopted, sub-plans 0029–0031 completed and verified
- [ ] All 336 set classes verified against music21
- [ ] All 17 modes verified
- [ ] All ~100 chord types verified against tonal-ts
- [ ] The Game produces 479 objects

## Verification Data Sources

- **music21** (`/Users/bermi/tmp/music21/`) — Forte numbers, interval vectors, prime forms, chord tables
- **tonal-ts** (`/Users/bermi/tmp/tonal-ts/`) — Scale types, chord types
- **harmoniousapp.net** (local `tmp/harmoniousapp.net/p/`, `tmp/harmoniousapp.net/js-client/`) — Algorithm behavior

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh` passes, `zig build verify` passes.
