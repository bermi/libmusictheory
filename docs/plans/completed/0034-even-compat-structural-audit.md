# 0034 - Even Compat Structural Audit and Model Grounding

Status: Completed

## Why

`even/index.svg`, `even/grad.svg`, and `even/line.svg` currently pass exact parity, but the compat path still relies on replay payloads. Before replacing that path with generated output, we need deterministic, script-verified facts about the true structure of the reference SVGs to avoid false confidence and incorrect assumptions.

## Research Scope

1. Parse `tmp/harmoniousapp.net/even/*.svg` and extract:
   - visible point counts and ray grouping,
   - marker-type counts (triangle vs circle),
   - hidden-marker mirror set counts,
   - per-variant shared vs variant-specific block boundaries.
2. Validate key invariants directly from references when local references exist.
3. Record findings in `docs/research/visualizations/evenness-chart.md`.

## Implementation Slices

### Slice A: Programmatic Audit

- Add `scripts/audit_even_compat.py`.
- Script emits a concise structured summary and exits non-zero on invariant violations.

### Slice B: Verification Gate

- Update `./verify.sh` so that when `tmp/harmoniousapp.net/even/` exists and `python3` is available, the audit script is executed and must pass.

### Slice C: Research Doc Alignment

- Update reverse-engineering notes in `docs/research/visualizations/evenness-chart.md` to match script-verified counts.

## Completion Criteria

- `scripts/audit_even_compat.py` exists and passes against local references.
- `./verify.sh` runs the audit (conditional on local refs).
- `docs/research/visualizations/evenness-chart.md` reflects audited structural facts.
- `./verify.sh` passes.
- Playwright sampled and full compatibility checks pass with 0 mismatches.

## Implementation History (Point-in-Time)

- `COMMIT_HASH_PLACEHOLDER` (`COMMIT_DATE_PLACEHOLDER`)
- Shipped behavior:
- Added `scripts/audit_even_compat.py` to programmatically validate `even/index|grad|line` structural invariants (ray counts, marker composition, hidden-point parity, and pairwise variant boundaries).
- Added `0034` verify gate in `./verify.sh` that runs the audit when `tmp/harmoniousapp.net/even/` exists.
- Updated `docs/research/visualizations/evenness-chart.md` reverse-engineering notes to match script-verified counts and boundary facts.
- Guardrail/completion verification:
- `./verify.sh`
- `python3 scripts/audit_even_compat.py --root tmp/harmoniousapp.net`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`
