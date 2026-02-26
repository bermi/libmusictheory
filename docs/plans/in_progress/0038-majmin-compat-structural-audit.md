# 0038 — MajMin Compatibility Structural Audit

> Dependencies: 0028 (compat integrity guardrails), 0033 (graph architecture inventory)
> Blocks: 0039 (future majmin algorithmic renderer migration)
> Does not block: strict compatibility validation (already enforced by 0024/0028)

Status: In Progress

## Objective

Add a deterministic structural audit for `tmp/harmoniousapp.net/majmin/*.svg` so algorithmic migration can be validated against stable reference invariants before replacing packed replay payloads.

## Non-Goals

- Do not relax strict byte-exact compatibility checks.
- Do not introduce a new renderer in this slice.
- Do not encode per-file coordinate replay tables in the audit script.

## Research Phase

### 1. Naming and Family Topology

- Validate complete filename grammar and cardinalities for:
  - `majmin/modes` (`366` files),
  - `majmin/scales` (`50` files).
- Validate allowed token domains:
  - transposition class (`-1..11`),
  - topology family (`dntri`, `hex`, `rhomb`, `uptri`, and the 2 legacy empty-shape special cases).

### 2. SVG Structural Invariants

- Validate stable element-model invariants by family:
  - viewBox buckets,
  - anchor/path distributions,
  - expected tag absence (`circle`, `text`) for this graph family.
- Validate exceptional legacy files (two large-canvas special cases per kind) remain exactly in expected slots.

### 3. Verification Integration

- Add a blocking `./verify.sh` gate (when `tmp/harmoniousapp.net/majmin` exists) that runs the structural audit script.
- Keep diagnostics machine-readable for future migration tooling.

## Implementation Steps

### 1. Add `scripts/audit_majmin_compat.py`

- Parse all `majmin` SVG references.
- Validate naming grammar and per-kind/family cardinalities.
- Validate per-family SVG structural distributions.
- Emit deterministic JSON summary for debugging and migration support.

### 2. Add Verify Gate

- Add `0038` gate in `./verify.sh`:
  - run audit script when local references are present,
  - fail on invariant drift.

### 3. Ensure Compatibility Baseline Unchanged

- Run full `./verify.sh` and confirm:
  - strict Playwright parity remains authoritative,
  - wasm size and anti-embed guardrails remain intact.

## Exit Criteria

- `./verify.sh` passes.
- `zig build verify` passes.
- `zig build test` passes.
- `python3 scripts/audit_majmin_compat.py --root tmp/harmoniousapp.net` passes.
- No strict compatibility behavior is changed.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `python3 scripts/audit_majmin_compat.py --root tmp/harmoniousapp.net`

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
