# 0025 — Harmonious SVG Compatibility: Text, Clock, Mode, Evenness

> Dependencies: 0024
> Blocks: 0026, 0027

## Objective

Reach exact harmoniousapp.net compatibility for these kinds:

- `vert-text-black`
- `vert-text-b2t-black`
- `center-square-text`
- `even` (`index.svg`, `grad.svg`, `line.svg`)
- `opc`
- `optc`
- `oc`

## Research Phase

### 1. Kind-by-Kind Reverse Engineering

- Extract expected output grammar and argument mapping from source references.
- Confirm where each kind is referenced in `js-client` and pages.
- Identify any missing API contracts (for text orientation, mode families/degrees, OPTC metadata filenames, etc.).

### 2. Existing Renderer Delta

- Compare current renderers (`src/svg/clock.zig`, `src/svg/mode_icon.zig`, `src/svg/evenness_chart.zig`, `src/svg/text_misc.zig`) against reference SVG bytes.
- Catalog exact mismatches (headers, attribute ordering, numeric precision, glyph path strategy, transforms).

## Implementation Steps

### 1. Text SVG Compatibility

- Implement exact output for `vert-text-black`, `vert-text-b2t-black`, and `center-square-text`.
- Ensure output includes expected SVG metadata and path-form text where required.

### 2. Clock SVG Compatibility

- Implement exact `opc` and `optc` rendering and naming (`*.svg`, `*,0,0,0.svg` variants).
- Ensure cluster fill behavior and center labeling exactly match reference.

### 3. Mode Icon Compatibility

- Implement exact `oc` rendering for all families (`wt`, `pent`, `hex`, `hmaj`, `hmin`, `aco`, `dia`, and others present).
- Ensure filename arguments are API-driven and complete.

### 4. Evenness Compatibility

- Implement exact outputs for `even/index.svg`, `even/grad.svg`, `even/line.svg`.

### 5. Validation/Test Integration

- Register all kinds in compatibility API enumeration.
- Add exact-match coverage in compatibility tests.
- Add all kinds to `validation.html` generation list.

## Current Progress (Point-in-Time)

- Completed exact parity:
  - `vert-text-black` (115/115)
  - `vert-text-b2t-black` (115/115)
  - `center-square-text` (24/24)
  - `even` (3/3)
  - `opc` (7/7)
  - `oc` (564/564)
  - `optc` (885/885)

Plan 0025 implementation scope is complete; remaining global mismatches are in 0026/0027 kinds.

## OPTC Research Findings (2026-02-16)

- Current `optc` output is semantically similar but byte-incompatible:
  - no XML prolog/doctype block,
  - different circle emission order,
  - center label rendered as `<text>` while reference uses path glyph variants,
  - missing exact whitespace/comment structure and numeric formatting.
- `src/generated/harmonious_optc_templates.zig` already contains extracted deterministic label variants (transform, fill, path data), but is not wired into `src/svg/clock.zig` or compatibility generation.

## OPTC Delivered

1. Wired `harmonious_optc_templates` into OPTC compatibility rendering.
2. Emitted exact header/body/footer structure (prolog/doctype/comment, circle order, spacing).
3. Added metadata-driven spoke rendering from filename args (`cluster_mask`, `dash_mask`, `black_mask`).
4. Preserved algorithmic dot fill behavior and special-label center glyph variants.
5. Added focused tests for OPTC compat rendering and metadata parsing.

## Exit Criteria

- `./verify.sh` passes
- `zig build verify` passes
- 100% exact byte match for all kinds listed in this plan
- `validation.html` generates and verifies all files for all listed kinds

## Kind Progress Rule

No work proceeds to 0026 until every kind in this plan meets the 3-point completion rule from 0024.

## Implementation History (Point-in-Time)

- Commit: `0fff14eee024ea3dbce6ae8bf90243b49ed0eca3`
- Date: `2026-02-18 03:42:47 +0100`
- Shipped behavior:
- Implemented exact compatibility for text/clock/mode/even kinds: `vert-text-black` (115/115), `vert-text-b2t-black` (115/115), `center-square-text` (24/24), `even` (3/3), `opc` (7/7), `optc` (885/885), `oc` (564/564).
- Integrated these kinds into compatibility API enumeration and WASM validation output.
- Completion gates:
- `./verify.sh`
- `zig build verify`
