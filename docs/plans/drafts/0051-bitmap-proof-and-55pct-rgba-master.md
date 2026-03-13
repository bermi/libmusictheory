# 0051 — Bitmap Proof And 55% RGBA Validation Master

> Dependencies: 0030, 0031, 0050
> Follow-up: 0052-0059 staged slice plans

Status: Draft

## Objective

Add a second, stricter proof track for harmonious compatibility:

- render harmonious reference SVGs at a canonical `55%` target size into bitmaps,
- render our candidate diagrams algorithmically at that same `55%` size directly to RGBA without first generating a full-size SVG and scaling it down,
- compare bitmap-to-bitmap with deterministic diff metrics,
- expose the candidate RGBA buffers from Zig/WASM so the browser paints them to `<canvas>` directly.

This track exists to prove that the diagram rules are encoded algorithmically and are not just replayed as memorized SVG geometry at a different scale.

## Why This Is Different

Exact SVG parity remains the authoritative compatibility target for the existing site-reproduction lane.

This new bitmap lane is not a replacement for exact SVG parity. It is a separate proof obligation:

- exact SVG parity proves site reproduction,
- direct `55%` RGBA generation proves scalable algorithmic rendering rules.

Both must stay true for the project to claim full-quality rendering.

## Non-Goals

- Do not replace byte-exact SVG compatibility with visual similarity.
- Do not allow browser/CSS/canvas rescaling of our generated SVG to count as algorithmic bitmap output.
- Do not allow replay-style geometry payloads to survive behind a bitmap diff pass and still be called “algorithmic”.
- Do not bloat the existing validation-focused `zig-out/wasm-demo` bundle past its strict footprint guardrails.

## Do Not Fool Ourselves

Bitmap similarity alone is not sufficient evidence of algorithmic rendering. This master plan treats a family as proven only when all of the following are true:

1. The candidate bitmap is produced from Zig layout/raster code, not from rasterizing our own SVG output.
2. The candidate bitmap is generated at native `55%` target dimensions, not by drawing a `100%` scene and scaling it down afterward.
3. The family has anti-replay guardrails that ban embedded harmonious SVG/PNG payloads and block new replay tables in the candidate path.
4. The family passes the deterministic bitmap diff threshold against the scaled harmonious reference.
5. The existing exact-SVG compatibility lane remains green unless and until a family-specific completion policy explicitly supersedes it.

If any one of those fails, the family is not considered algorithmically proven.

## Canonical Bitmap Contract

This plan introduces a precise bitmap contract that every proof run must obey.

### Target Size

- Reference target size = canonical `55%` downscaled size derived from the harmonious source SVG.
- Candidate target size = the exact same pixel width/height, computed before rendering begins.
- No CSS scaling.
- No browser zoom assumptions.
- Backing canvas size must equal displayed canvas size in proof mode.

### Reference Rendering Rules

- The harmonious reference may start from SVG, but it must be rasterized directly at the target `55%` dimensions.
- The reference path must use a deterministic rasterization setup:
  - fixed browser,
  - fixed DPR,
  - fixed font loading state,
  - fixed image smoothing policy,
  - fixed canvas color space assumptions.

### Candidate Rendering Rules

- The candidate path must start from Zig algorithmic layout code and output RGBA directly.
- JS may only copy the returned RGBA bytes into `ImageData` / `<canvas>`.
- JS must not:
  - load candidate SVG into `<img>`,
  - call `drawImage` on candidate SVG,
  - apply `scale()` transforms to candidate canvas content,
  - use CSS transforms to resize the candidate image.

## Bitmap Drift Metric

The proof lane needs a precise and audit-friendly drift metric.

### Primary Pass Metric

Define normalized RGBA drift as:

`sum(abs(candidate[i] - reference[i])) / (255 * 4 * pixel_count)`

Pass threshold for proof mode:

- `normalized_rgba_drift <= 0.0001` (`0.01%`)

### Required Hard Gates

- identical width
- identical height
- identical stride contract
- identical pixel count
- no NaN/overflow in dimension math

### Secondary Diagnostics

These do not replace the primary threshold, but they must be reported for triage:

- changed-pixel ratio
- worst-pixel delta
- alpha-only mismatch ratio
- bounding box of differing pixels
- diff heatmap artifact

## Build Partitioning Strategy

The current validation wasm is intentionally slim and should stay that way.

This master plan therefore introduces a separate bitmap-proof bundle rather than loading raster proof code into the current small validation bundle by default.

Proposed bundle split:

- `zig-out/wasm-demo`
  - keep current exact-SVG validation lane and strict size budget.
- `zig-out/wasm-docs`
  - keep current full interactive docs lane.
- `zig-out/wasm-bitmap-proof` or equivalent
  - new bundle for `55%` bitmap proof mode,
  - may include raster backend + RGBA exports,
  - must have its own explicit wasm export check and Playwright verification.

## Proposed Staged Slice Plans

This master plan coordinates the following staged implementation sequence.

### 0052 — Bitmap Contract And Anti-Cheat Guardrails

- Formalize canonical `55%` target-size rules.
- Add `verify.sh` guardrails that forbid candidate SVG-to-canvas raster shortcuts in proof-mode JS/WASM plumbing.
- Add source guardrails that ban embedded harmonious raster/SVG payloads in the new bitmap candidate path.
- Define the exact normalized RGBA drift formula and artifact outputs.

Exit gate:

- proof metric and anti-cheat policy are programmatically enforced before any renderer work begins.

### 0053 — RGBA ABI And WASM Export Surface

- Add explicit Zig/C ABI surface for algorithmic RGBA generation:
  - query target bitmap dimensions,
  - query required RGBA buffer bytes,
  - render direct RGBA into caller-provided memory.
- Add wasm exports for proof-mode canvas painting.
- Keep caller-owned buffers where feasible.

Exit gate:

- wasm can expose deterministic RGBA for a trivial scene and native tests cover ABI shape.

### 0054 — Deterministic Reference Raster Pipeline

- Implement canonical rasterization of harmonious SVG references at `55%`.
- Lock DPR, smoothing, browser, and asset-loading behavior.
- Add bitmap diff helper and lossless artifact emission.

Exit gate:

- repeated runs on the same reference images are byte-stable,
- diff tooling reports zero drift for reference-vs-reference control tests.

### 0055 — Raster Backend Capability Upgrade

- Audit missing raster features against actual diagram families:
  - path fill/stroke,
  - joins/caps/dashes,
  - clipping,
  - transforms,
  - text/glyph strategy,
  - deterministic anti-aliasing.
- Extend the existing IR/raster path only where necessary.

Exit gate:

- raster backend can faithfully paint the primitive set required by the first proof families.

### 0056 — Simple Families 55% Proof Lane

Target families:

- `vert-text-black`
- `vert-text-b2t-black`
- `center-square-text`
- `opc`
- `optc`
- `oc`
- `even`

Goals:

- direct algorithmic `55%` RGBA output,
- no post-render scaling,
- proof UI shows candidate/reference/diff canvases,
- per-family drift under threshold.

Exit gate:

- sampled + full proof runs pass for all simple families.

### 0057 — Staff And Fret Family 55% Proof Lane

Target families:

- `scale`
- `eadgbe`
- `chord`
- `wide-chord`
- `chord-clipped`
- `grand-chord`

Goals:

- move notation-specific scaling rules into direct target-size layout,
- ensure ledger lines, stems, modifiers, barlines, clip regions, and spacing are computed at target size,
- keep exact-SVG lane green while bitmap proof is added.

Exit gate:

- staff/fret families pass bitmap proof at `55%` with thresholded drift and anti-replay guardrails.

### 0058 — Majmin 55% Proof Lane

Target families:

- `majmin/modes`
- `majmin/scales`

Goals:

- direct target-size tessellation/scaffold rendering,
- deterministic color, path, and highlight behavior,
- no scene-pack replay fallback in proof mode.

Exit gate:

- majmin families pass full bitmap proof lane.

### 0059 — Project-Level Bitmap Proof Closure

- unify reports across all families,
- add Playwright project-wide proof runs,
- tighten per-family signoff rules,
- document the completion policy that combines:
  - exact SVG parity,
  - bitmap proof,
  - anti-replay structure,
  - wasm/export/build partitioning.

Exit gate:

- all required families pass both existing exact-SVG validation and the new bitmap proof lane.

## Quality Gates

Every slice under this master plan must satisfy all applicable gates below.

### Correctness Gates

- exact target dimensions match between reference and candidate
- deterministic RGBA output across repeated runs
- normalized drift at or below threshold
- diff artifacts stored for failures

### Provenance Gates

- no candidate SVG raster shortcut
- no candidate CSS/canvas scaling shortcut
- no harmonious embedded raster/SVG payloads in candidate path
- no new replay tables introduced without explicit exception review

### Verification Gates

- `./verify.sh`
- `zig build verify`
- `zig build test`
- authoritative Playwright proof run for the installed bitmap bundle
- family-targeted sample runs before full all-family runs

### Bundle Gates

- existing validation/docs bundles keep their current purpose and budgets
- new bitmap-proof bundle gets its own measured budget and explicit export contract

## Completion Standard

This master plan is complete only when the project can say all of the following without caveat:

- we still reproduce harmoniousapp.net exactly in SVG where required,
- we can also render the same diagrams directly to deterministic RGBA at `55%` size,
- the candidate bitmap path is algorithmic and not a scaled replay of full-size SVG,
- the reference/candidate bitmap drift is within the defined threshold across all required families,
- the entire process is enforced by reproducible automated verification.
