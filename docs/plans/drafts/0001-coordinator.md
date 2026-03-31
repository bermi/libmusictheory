# 0001 — libmusictheory Project Coordinator

## Project Overview

Build `libmusictheory`, a Zig library exposing a C ABI that implements the complete music theory framework from harmoniousapp.net. The library will power:
- Static site generation (reproducing harmoniousapp.net)
- Music composition plugins (DAW integration)
- LLM agents for music theory reasoning

## Lifecycle Status

- Draft: 0001, 0085
- In progress: 0086, 0087
- Completed: 0002, 0003, 0004, 0005, 0006, 0007, 0008, 0009, 0010, 0011, 0012, 0013, 0014, 0015, 0016, 0017, 0018, 0019, 0020, 0021, 0022, 0023, 0024, 0025, 0026, 0027, 0028, 0029, 0030, 0031, 0032, 0033, 0034, 0035, 0036, 0037, 0038, 0039, 0040, 0041, 0042, 0043, 0044, 0045, 0046, 0047, 0048, 0049, 0050, 0051, 0052, 0053, 0054, 0055, 0056, 0057, 0058, 0059, 0060, 0061, 0062, 0063, 0064, 0065, 0066, 0067, 0068, 0069, 0070, 0071, 0072, 0073, 0074, 0075, 0076, 0077, 0078, 0079, 0080, 0081, 0082, 0083, 0084, 0088, 0089, 0090, 0091, 0092, 0093, 0094, 0095, 0096, 0097, 0098, 0099, 0100

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
0034-even-compat-structural-audit → script-verified structural invariants for even/index|grad|line prior to renderer migration
     ↓ depends on 0028, 0032 (verification hardening)
0035-even-compat-segmented-gzip-renderer → replace monolithic even payload with audited shared/variant segmented gzip assembly
     ↓ depends on 0034 (structural grounding)
0036-text-compat-primitive-audit → script-verified primitive decomposition invariants for vertical text labels before glyph-level renderer migration
     ↓ depends on 0028, 0033 (verification + architecture grounding)
0037-text-compat-symbolic-renderer → replace vertical per-stem path lookup with symbolic primitive composition while preserving exact byte parity
     ↓ depends on 0036 (audited primitive model)
0038-majmin-compat-structural-audit → script-verified structural invariants for majmin/modes|scales prior to algorithmic renderer migration
     ↓ depends on 0028, 0033 (verification + architecture grounding)
0039-majmin-compat-algorithmic-renderer → replace packed majmin compatibility payload with deterministic algorithmic scene generation
     ↓ depends on 0038, 0028, 0029 (audited structure + guardrails + IR foundation)
0040-majmin-scales-geometry-cutover → procedural cutover for invariant scales geometry layer while preserving exact parity
     ↓ depends on 0039, 0038, 0028 (scene model + audits + guardrails)
0041-majmin-numeric-renderer-master → coordinate milestone track for removing replay-style geometry/path payloads from majmin while preserving strict parity
     ↓ depends on 0040, 0039, 0028
0042-majmin-scales-geometry-template-renderer → replace per-path replay strings with slot/shape renderer backed by compact coordinate topology tables
     ↓ depends on 0041, 0040
0043-majmin-scales-geometry-analytic-coordinates → replace coordinate token tables with computed decimal coordinate emitters and stricter anti-replay guardrails
     ↓ depends on 0042
0044-majmin-scales-scene-pack-geometry-prune → remove scales geometry payload from scene-pack generation + parser path
     ↓ depends on 0043
0045-majmin-modes-geometry-numeric-cutover → apply numeric geometry renderer strategy to modes groups and prune corresponding replay payload
     ↓ depends on 0044
0046-wasm-compat-name-pack-cutover → remove runtime manifest string tables from wasm compat path via compact name-pack + strict size guardrail tightening
     ↓ depends on 0045
0047-wasm-explicit-export-roots → replace wasm `rdynamic` reachability with explicit exported C ABI roots to reduce binary size while preserving demo/compat behavior
     ↓ depends on 0046
0048-wasm-validation-bundle-budget → enforce validation bundle `(wasm + installed js) <= 512KiB` with validation-focused export/asset surface and strict parity retention
     ↓ depends on 0047
0049-wasm-validation-root-slimming → build validation wasm from a dedicated minimal root and push installed bundle below strict decimal 500000 bytes
     ↓ depends on 0048
0050-wasm-docs-bundle-and-installed-validation → make installed validation/docs browser workflows actually work and verify both via Playwright
     ↓ depends on 0049
0051-scaled-render-parity-and-native-rgba-proof-master → coordinate the split between all-kind scaled render parity and strict native-RGBA proof, with anti-cheat guardrails and completion discipline
     ↓ depends on 0030, 0031, 0050
0052-bitmap-contract-and-anti-cheat-guardrails → enforce proof-lane anti-cheat rules, explicit support reporting, and bundle verification gates
     ↓ depends on 0051
0053-rgba-abi-and-wasm-export-surface → expose caller-owned RGBA native-proof ABI and explicit wasm export roots
     ↓ depends on 0052
0054-deterministic-reference-raster-pipeline → rasterize harmonious references at 55% size inside the proof lane with measurable drift outputs
     ↓ depends on 0052, 0053
0055-raster-backend-capability-upgrade → broaden the proof renderer primitive coverage family by family
     ↓ depends on 0053, 0054
0056-simple-families-55pct-proof-lane → close native-RGBA proof for simple compatibility families
     ↓ depends on 0055
0057-staff-and-fret-55pct-proof-lane → close native-RGBA proof for staff/fret families
     ↓ depends on 0055, 0056
0058-majmin-55pct-proof-lane → close native-RGBA proof for majmin families
     ↓ depends on 0055, 0056, 0057
0059-project-level-scaled-render-parity-closure → unify reporting and closure rules across the full compat corpus for scaled render parity, with explicit native-RGBA vs generated-SVG candidate reporting
     ↓ depends on 0056, 0057, 0058
0060-project-level-native-rgba-proof-closure → define the only acceptable visual completion gate: all 15 kinds proven through native-RGBA at both canonical scales
     ↓ depends on 0056, 0057, 0058, 0059
0061-parametric-fret-renderer-and-api → add arbitrary-string fret rendering and `*_n` ABI while preserving 6-string compatibility wrappers
     ↓ depends on 0012, 0016, 0020, 0050
0062-generic-fret-semantics-and-caged-scope → generalize voicing/guide/url semantics for arbitrary tunings while keeping CAGED explicitly six-string scoped
     ↓ depends on 0012, 0061
0063-generic-fret-semantic-c-abi-and-wasm-docs → expose the generic voicing/guide/url fret model through the public C ABI and the wasm docs surface
     ↓ depends on 0020, 0023, 0062
0064-wasm-docs-run-all-visibility-and-resilience → make the docs `Run all sections` path explicitly verified and visually inspectable
     ↓ depends on 0023, 0050, 0063
0065-core-svg-render-quality-uplift → raise the visual and notation quality of the core fret/staff SVG APIs used by the docs surface
     ↓ depends on 0015, 0016, 0023, 0064
0066-project-wide-generated-svg-quality-foundation → apply a shared quality prelude and typography/stroke discipline across all non-compat generated SVG families without touching exact compat output
     ↓ depends on 0014, 0015, 0016, 0017, 0018, 0023, 0065
0067-native-raster-antialias-quality → replace hard-threshold native bitmap edges with coverage-based raster antialiasing across proof/parity raster backends
     ↓ depends on 0030, 0059, 0060, 0066
0068-harmonious-wasm-spa → single-entry harmonious SPA shell backed by wasm-generated compatibility images and a locally reconstructed request bridge
0069-route-addressable-harmonious-spa → single-entry shell bootable through explicit `?route=...` deep links on plain static hosts
     ↓ depends on 0023, 0024, 0050, 0060, 0067
0070-shell-form-live-history-for-interactive-routes → keep interactive keyboard/fret edits and back/forward history on shell-form `index.html?route=...` URLs
     ↓ depends on 0068, 0069
0071-static-host-ready-harmonious-spa → ship static-host `404.html` fallback recovery, synchronized shell canonical metadata, and favicon-clean bundle behavior
     ↓ depends on 0068, 0069, 0070
0072-shell-form-fragment-links → rewrite locally reconstructed search and key-slider fragment links back through the SPA shell for copy/new-tab correctness
     ↓ depends on 0068, 0069, 0070, 0071
0073-standalone-library-release-and-gallery-master → coordinate the standalone release surface, keeping Harmonious verification as internal regression infrastructure while promoting a clean public API, docs, and gallery
0074-public-api-and-build-surface-split → separate standalone install/build surfaces from Harmonious compat/proof/demo surfaces
     ↓ depends on 0073, 0020, 0050, 0063
0075-harmonious-verification-quarantine → retain parity/proof/SPA tooling as internal verification lanes and document a reduced release path that does not depend on local Harmonious data
     ↓ depends on 0073, 0074, 0024, 0060, 0072
0076-root-readme-and-stable-api-contract → add the first real library-facing README, stable API boundaries, and documented memory/lifetime rules
     ↓ depends on 0073, 0074
0077-standalone-gallery-and-example-bundle → build a local-only creative gallery using public stable APIs only
     ↓ depends on 0073, 0074, 0076, 0066
0078-release-packaging-and-smoke-matrix → close the standalone release branch with release artifacts, smoke tests, versioning/changelog scaffolding, and a checklist
     ↓ depends on 0074, 0075, 0076, 0077
0079-release-candidate-gallery-polish-master → coordinate post-release-candidate gallery expansion, presentation polish, and first release-candidate materials
0080-gallery-scene-expansion-and-curation → expand and curate the public standalone gallery using only stable APIs
     ↓ depends on 0077, 0078, 0079
0081-gallery-presentation-and-capture-pipeline → make the gallery presentable and reproducibly capturable for release-candidate review
     ↓ depends on 0077, 0079
0083-core-staff-renderer-quality-and-gallery-guardrails → correct the public staff renderer so gallery/release captures require real notation features rather than only framing
     ↓ depends on 0065, 0077, 0081, 0079
0084-core-clef-glyph-fidelity → replace placeholder public clefs with compat-derived glyph outlines and guard against regressions
     ↓ depends on 0083, 0079
0082-first-release-candidate-cut → turn the release scaffold into a real first release-candidate cut with reviewer guidance
     ↓ depends on 0078, 0079, 0083, 0084
0090-counterpoint-state-and-gallery-master → coordinate time-aware counterpoint state, motion semantics, next-step ranking, and interactive gallery exposure
0091-voiced-state-and-temporal-memory → add persistent voice identity, recent history, key/mode context, metric position, and cadence state to the core library
     ↓ depends on 0010, 0011, 0090
0092-motion-classifier-and-rule-profiles → classify adjacent voice motion and evaluate it under multiple style profiles
     ↓ depends on 0091
0093-next-step-ranker-and-reason-codes → rank plausible next voiced moves with explicit reasons and temporal-memory-aware scoring
     ↓ depends on 0091, 0092
0094-interactive-counterpoint-gallery-and-instrument-miniviews → expose the counterpoint engine in the standalone gallery and add optional piano/fret miniviews across scenes
     ↓ depends on 0077, 0087, 0093
0095-voice-leading-horizon-and-braid-gallery → add local-slice horizon and braid visualizations over the live counterpoint scene
     ↓ depends on 0094
0096-counterpoint-weather-map-and-risk-radar → add local next-move pressure fields and compact contrapuntal risk diagnostics to the live counterpoint scene
     ↓ depends on 0095
0097-cadence-funnel-and-suspension-machine → add phrase-direction and suspension-state visuals to the live counterpoint scene
     ↓ depends on 0096
0098-orbifold-ribbon-and-common-tone-constellation → add local harmonic-geometry and retained-vs-moving diagnostics to the live counterpoint scene
     ↓ depends on 0097
0099-counterpoint-inspector-and-candidate-pinning → add a pinned candidate inspector and instrument-synced current/next compare previews to the live counterpoint scene
     ↓ depends on 0098
0100-counterpoint-continuation-ladder → rank and visualize follow-up continuations from the currently focused next move in the live counterpoint scene
     ↓ depends on 0099
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

Parity hardening continuation:

```
0028 + 0032
   │
 0034 (Even Structural Audit)
   │
0035 (Even Segmented Gzip Renderer)
   │
0036 (Text Primitive Audit)
   │
 0037 (Text Symbolic Renderer)
   │
0038 (MajMin Structural Audit)
   │
0039 (MajMin Algorithmic Scene Renderer)
   │
0040 (MajMin Scales Geometry Cutover)
   │
0041 (MajMin Numeric Renderer Master)
   │
0042 (Scales Geometry Template Renderer)
   │
0043 (Scales Geometry Analytic Coordinates)
   │
0044 (Scales Scene-Pack Geometry Prune)
   │
0045 (Modes Geometry Numeric Cutover)
   │
0046 (WASM Compat Name-Pack Cutover)
   │
0047 (WASM Explicit Export Roots)
   │
0048 (WASM Validation Bundle Budget)
   │
0049 (WASM Validation Root Slimming)
   │
0050 (Installed Validation + Full Docs Bundle)
   │
0051 (55% Bitmap Proof Master)
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

### Phase 7.5 (Planned Additive): Scaled Render Parity + Native-RGBA Proof Master (Plan 0051)
Split the additive bitmap lane into two honest claims: all-kind scaled render parity and strict native-RGBA proof, without allowing generated-SVG parity coverage to count as proof.

**Deliverable**: a staged master plan with explicit anti-cheat rules, RGBA ABI requirements, deterministic diff metrics, parity/proof naming discipline, and per-family closure gates.

### Phase 7.6 (Completed Additive): Native-RGBA Proof Execution Track (Plans 0052-0060)
Execute the native-proof lane in dependency order: anti-cheat guardrails first, then RGBA exports, then reference rasterization, then per-family closure. Scaled render parity remains a separate all-kind lane; families that are not natively supported must remain explicitly unsupported and may not count as proven.

**Deliverable**: separate scaled-render-parity and native-proof bundles, with `0059` retained as parity-only closure and `0060` closed as the only visual completion marker after all 15 kinds passed strict native-RGBA proof at `55%` and `200%`.

### Phase 7.7 (Completed Additive): Harmonious WASM SPA (Plan 0068)
Ship a single-entry SPA that reuses the original harmonious content/client stack while serving compatibility imagery from `libmusictheory` WASM and reconstructing the missing dynamic server endpoints locally.

**Deliverable**: a verified `zig build wasm-harmonious-spa` bundle with local request-bridge reconstruction for keyboard/fret/key-slider/random flows and Playwright-enforced absence of network compatibility SVG loads.

### Phase 7.8 (Completed Additive): Route-Addressable Harmonious SPA (Plan 0069)
Make the single-entry shell directly bootable through `index.html?route=...` and rewrite internal page-family links through the shell entry so static hosting does not depend on direct `/p/...`, `/keyboard/...`, or `/eadgbe-frets/...` server routes for new-tab and copied-link flows.

**Deliverable**: a Playwright-verified shell that directly boots representative page, keyboard, fretboard, and key-slider routes through the single SPA entry.

### Phase 7.9 (Completed Additive): Shell-Form Live History For Interactive Routes (Plan 0070)
Keep keyboard and fretboard live edits on shell-form URLs so the SPA remains single-entry after interactive mutations, while preserving correct back/forward behavior.

**Deliverable**: Playwright-verified live keyboard and fret edits that keep the browser on `index.html?route=...` and round-trip correctly through history navigation.

### Phase 7.10 (Completed Additive): Static-Host Ready Harmonious SPA (Plan 0071)
Make the single-entry shell recover correctly on plain static hosts that serve `404.html` for unknown deep routes, while keeping the visible URL canonical on `index.html?route=...`.

**Deliverable**: a static-host-ready SPA bundle with installed `404.html`, verified raw-route recovery into `index.html?route=...`, synchronized shell canonical metadata, and built-in favicon handling that avoids `favicon.ico` network noise.

### Phase 7.11 (Completed Additive): Shell-Form Fragment Links (Plan 0072)
Keep SPA-generated fragment links consistent with the shell URL model so search results and key-slider cards do not leak raw route URLs when opened in a new tab or copied from the DOM.

**Deliverable**: Playwright-verified search and key-slider fragments whose generated page-route anchors use `index.html?route=...` plus `data-lmt-shell-route`, while non-page links remain unchanged.

### Phase 8 (Planned): Standalone Release Surface And Gallery (Plans 0073-0078)
Convert the current correctness-heavy branch into a clean standalone library release surface. Keep Harmonious parity/proof/SPA work in-repo as internal regression infrastructure, but stop letting it define the public product identity. Focus this phase on public API/build separation, root docs, a standalone gallery, and release packaging. Local serving is sufficient; no production rollout work belongs here.

**Deliverable**: a standalone-facing library surface with a root README, stable API contract, public-vs-internal build/install separation, a verified local `wasm-gallery` bundle using only public APIs, and a release smoke/checklist layer that remains decoupled from Harmonious-specific tooling.

## Phase 0079-0082 — Release Candidate Gallery Polish

The standalone surface is now structurally clean. The next phase is to make it presentable as a release candidate by expanding the gallery, improving its presentation, adding a reproducible capture pipeline, and converting the release scaffold into a real first candidate cut.

**Deliverable**: a polished standalone gallery with stronger curated scenes, reproducible local screenshots/captures, and a first release-candidate package/story that still stays strictly independent from Harmonious-specific regression infrastructure.

## Phase 0088 (Completed): Live MIDI Composer Scene

Add a first-class interactive gallery scene that listens to all browser MIDI inputs, respects sustain behavior, stores snapshots on middle-pedal presses, and gives composers an immediate visual/theory reading of what they are sounding plus compatible next-step suggestions.

**Deliverable**: a Playwright-verified above-the-fold gallery scene driven by real Web MIDI at runtime and fake MIDI in verification, with snapshot recall, stable-public-API visual output, and screenshot coverage in the release capture pipeline.

## Phase 0089 (Completed): Live MIDI Context And Snapshot UX

Stabilize the composer-facing behavior of `Live MIDI Compass` by replacing auto-fit key guessing with explicit tonic/mode context controls. The selected context must drive spelling, suggestion ranking, and saved snapshot recall so the scene behaves predictably during composition.

**Deliverable**: a Playwright-verified live MIDI scene whose selected tonic/mode changes the rendered interpretation and whose snapshots recall both notes and context.

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
13. The standalone release surface can be installed, documented, and smoke-tested without requiring local Harmonious capture data
14. The repo ships a standalone gallery demonstrating creative public-API usage without depending on Harmonious-specific browser flows

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
- [ ] If standalone release track is adopted, sub-plans 0073–0078 completed and verified
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
