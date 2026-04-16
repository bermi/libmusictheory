# 0001 — libmusictheory Project Coordinator

## Project Overview

Build `libmusictheory`, a Zig library exposing a C ABI that implements the complete music theory framework from harmoniousapp.net. The library will power:
- Static site generation (reproducing harmoniousapp.net)
- Music composition plugins (DAW integration)
- LLM agents for music theory reasoning

## Lifecycle Status

- Draft: 0001
- In progress: None
## Current Remaining Work

The stable-release execution lane, the post-`0.1.0` explainable-theory Contrapunk lane, the experimental playability roadmap, the `0130`/`0131` adoption follow-ups, and the phrase-audit master lane through `0138` are complete.

There is no active execution slice right now. The phrase-audit lane is now closed through:
- `0132` phrase-level playability audit, committed memory, and repair helpers
- `0133` phrase-event foundation
- `0134` fixed-realization phrase auditing
- `0135` committed phrase memory and choice bias
- `0136` repair-policy and ranked phrase repairs
- `0137` gallery phrase blackboard and virtual keyboard fallback
- `0138` docs and host adoption

The key design boundary remains explicit for future work:
- committed musical choices that affect later ranking belong in caller-owned library memory
- hover, pin, device state, persistence, and transient virtual-keyboard UI state remain host-owned

The next meaningful work should start from a new roadmap slice on clean `main`.

- Completed: 0002, 0003, 0004, 0005, 0006, 0007, 0008, 0009, 0010, 0011, 0012, 0013, 0014, 0015, 0016, 0017, 0018, 0019, 0020, 0021, 0022, 0023, 0024, 0025, 0026, 0027, 0028, 0029, 0030, 0031, 0032, 0033, 0034, 0035, 0036, 0037, 0038, 0039, 0040, 0041, 0042, 0043, 0044, 0045, 0046, 0047, 0048, 0049, 0050, 0051, 0052, 0053, 0054, 0055, 0056, 0057, 0058, 0059, 0060, 0061, 0062, 0063, 0064, 0065, 0066, 0067, 0068, 0069, 0070, 0071, 0072, 0073, 0074, 0075, 0076, 0077, 0078, 0079, 0080, 0081, 0082, 0083, 0084, 0085, 0086, 0087, 0088, 0089, 0090, 0091, 0092, 0093, 0094, 0095, 0096, 0097, 0098, 0099, 0100, 0101, 0102, 0103, 0104, 0105, 0106, 0107, 0108, 0109, 0110, 0111, 0112, 0113, 0114, 0115, 0116, 0117, 0118, 0119, 0120, 0121, 0122, 0123, 0124, 0125, 0126, 0127, 0128, 0129, 0130, 0131, 0132, 0133, 0134, 0135, 0136, 0137, 0138, contrapunk-theory-integration

## Plan Dependencies (Execute in Order)

```text
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
     ↓ depends on 0073, 0020, 0050
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
0101-counterpoint-path-weaver → extend the focused continuation into several short recursively ranked multi-step paths in the live counterpoint scene
     ↓ depends on 0100
0102-counterpoint-cadence-garden → group the short recursively ranked paths by reachable cadence outcome in the live counterpoint scene
     ↓ depends on 0101
0103-counterpoint-profile-orchard → contrast the same focused move across all counterpoint rule profiles in the live counterpoint scene
     ↓ depends on 0102
0104-counterpoint-consensus-atlas → cluster immediate next moves by cross-profile agreement so the live scene exposes consensus and stylistic outliers before committing to one continuation
     ↓ depends on 0103
0105-counterpoint-obligation-ledger → summarize the current counterpoint state's pending duties and show whether the focused next move resolves, delays, or aggravates them
     ↓ depends on 0104, 0097, 0099
0106-counterpoint-resolution-threader → project the current obligations through the strongest short continuation paths so composers can see which duties resolve, stay open, or worsen over the next few ranked moves
     ↓ depends on 0105, 0101, 0099
0107-counterpoint-obligation-timeline → replay the current duties across recent actual moves and compare them with the focused move so obligation memory becomes readable backward as well as forward
     ↓ depends on 0105, 0106, 0091
0108-counterpoint-voice-duties → show which persistent voices are carrying the present duties and how the focused move treats each one directly
     ↓ depends on 0105, 0107, 0091
