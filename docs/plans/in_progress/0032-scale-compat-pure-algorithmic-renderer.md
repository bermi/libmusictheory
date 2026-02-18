# 0032 — Scale Compatibility: Pure Algorithmic Renderer

> Dependencies: 0028 (integrity guardrails)
> Blocks: algorithmic parity claims for `scale`
> Does not block: 0029, 0030, 0031

## Objective

Replace `scale` compatibility output generation with a fully algorithmic Zig renderer that derives geometry and glyph placement from musical input rules, not precomputed per-image payloads/lookups.

Target scope:
- `tmp/harmoniousapp.net/scale/*.svg` (`494` files)

## Why This Plan Exists

Current `scale` compatibility is exact-match, but the implementation relies on generated assets/tuning tables that are too close to replay.

This plan enforces a stricter definition of done:
- exact byte parity must remain,
- generation must be algorithmic,
- verification must fail if replay-style scale data is reintroduced.

## Non-Goals

- Do not relax byte-exact SVG parity to visual similarity.
- Do not embed or load reference SVG contents into generation paths.
- Do not increase wasm artifact beyond the existing `<1MB` guardrail.

## Current Snapshot (2026-02-18)

- `scale` parity is currently `494/494` exact matches.
- Full compatibility run remains `8634/8634` exact matches.
- Runtime no longer uses:
- `harmonious_scale_nomod_profile_tuning`
- `harmonious_scale_nomod_names`
- `harmonious_scale_nomod_keysig_lines`
- Index-based replay (`harmonious_scale_x_by_index`).
- Scale key signature accidentals are now emitted algorithmically from reusable modifier glyph paths and anchor rules.
- Verification now enforces wasm footprint budgets via `scripts/wasm_size_audit.py`:
- total wasm `< 900000`
- wasm `DATA` section `< 760000`
- coordinate-like reachable generated data `< 170000`
- Chord compatibility path is now guarded against x/y coordinate replay table reintroduction.
- Remaining open item for strict completion:
- x-layout still applies a compact deterministic ULP shim table (`src/generated/harmonious_scale_layout_ulpshim.zig`) to mirror V8 floating-point edge behavior; next slice removes/reduces this shim with formula-only parity.

## Research Phase (Mandatory)

### 1. Source-of-Truth Rendering Model

- Reverse engineer `scale` staff rendering behavior from harmoniousapp source code and emitted SVG structure.
- Identify exact rendering stages:
- key signature accidental emission,
- notehead/stem/ledger placement,
- modifier collision/shift behavior,
- final SVG node order and numeric formatting.

### 2. API Contract and Missing Methods

- Verify compatibility API already provides complete name/argument enumeration for all scale images.
- Confirm missing internal interfaces for a pure algorithmic path (if any), for example:
- `scale layout model` builder,
- `modifier spacing solver`,
- strict SVG formatter.

### 3. Numeric/Formatting Contract

- Define deterministic float/decimal formatting rules and attribute ordering rules needed for byte identity.
- Document exact whitespace/newline grammar constraints.

### 4. Replay-Risk Audit

- Enumerate all `scale`-related generated dependencies currently used by runtime code.
- Classify each as:
- allowed (small static glyph shape constants),
- forbidden (per-image coordinates/tuning/lookup replay).

## Implementation Slices

### Slice 0 — Verification Guardrails First

Update `./verify.sh` before algorithm work to make cheating/regression impossible:
- fail if `src/svg/scale_nomod_compat.zig` (or replacement module) imports forbidden scale replay assets,
- fail on scale-specific generated coordinate/tuning lookup usage,
- keep full playwright strict parity and wasm size gates active.

### Slice 1 — Algorithmic Layout Core

- Implement a scale-specific algorithmic layout kernel:
- parse `key,note...` stem into note objects,
- compute stave lines and key signature geometry algorithmically,
- compute note x positions via deterministic spacing/collision logic.

### Slice 2 — Algorithmic Modifier Placement

- Implement accidental/modifier placement without per-image lookup tables.
- Reproduce collision handling and displacement behavior from rendering rules.

### Slice 3 — Strict Serializer

- Emit the exact header/body/footer grammar and deterministic node order.
- Implement strict numeric formatting/writer policy required for byte parity.

### Slice 4 — Remove Replay Dependencies

- Remove scale replay-style generated assets from runtime path.
- Keep only minimal reusable constants justified as glyph definitions or invariant geometry primitives.

### Slice 5 — Verification and Regression Lock

- Add focused tests for:
- parser correctness,
- layout determinism,
- modifier collision edge cases,
- byte-exact parity for all `494` scale files (when refs exist).
- Run sampled and full Playwright validation and keep mismatch preview behavior intact.

## Acceptance Criteria

All must be true:
1. `scale` is `494/494` exact matches.
2. `scale` renderer uses no forbidden replay-style generated lookup/payload assets.
3. `./verify.sh` passes with guardrails enabled.
4. `node scripts/validate_harmonious_playwright.mjs --kinds scale` passes with `0` mismatches.
5. `node scripts/validate_harmonious_playwright.mjs` full run remains `0` mismatches.
6. `zig-out/wasm-demo/libmusictheory.wasm < 1MB`.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5 --kinds scale`
- `node scripts/validate_harmonious_playwright.mjs --kinds scale`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
