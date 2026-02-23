# 0036 - Text Compat Primitive Audit and Guardrails

Status: Completed

## Objective

Establish deterministic, script-verified structural invariants for `vert-text-black` and `vert-text-b2t-black` path construction as a prerequisite for replacing per-stem path tables with algorithmic glyph composition.

## Why

- Current text compat parity is table-driven through per-stem `path_d` payloads.
- We need hard facts about shared path primitives and decomposition rules before implementing a true character-level renderer.
- Guardrails prevent accidental regression while algorithmic migration is in progress.

## Scope

- Add audit script for:
  - `tmp/harmoniousapp.net/vert-text-black/*.svg`
  - `tmp/harmoniousapp.net/vert-text-b2t-black/*.svg`
- Add `verify.sh` gate that executes the audit when local references exist.
- Update architecture notes for text glyph decomposition findings.

## Non-Goals

- Replacing the runtime text renderer in this slice.
- Relaxing exact compatibility checks.

## Implementation Slices

### Slice A: Verification Gate First

- Update `./verify.sh` to run text primitive audit conditionally.

### Slice B: Primitive Audit Script

- Add `scripts/audit_text_compat_primitives.py`:
  - parse path subpaths,
  - verify primitive cardinality per symbol,
  - verify deterministic per-stem segmentation under inferred glyph primitive order.

### Slice C: Documentation

- Record audited invariants and migration implications in graph architecture docs.

## Completion Criteria

- Audit script passes on local references.
- `./verify.sh` includes and executes the new gate when refs exist.
- Full `./verify.sh` remains green (including Playwright sampled/full parity).

## Implementation History (Point-in-Time)

- `b1789e0a00e36c44d59a29d4985e26741a810955` (`2026-02-23T14:38:15+01:00`)
- Shipped behavior:
- Added `scripts/audit_text_compat_primitives.py` to enforce deterministic primitive decomposition invariants for `vert-text-black` and `vert-text-b2t-black`.
- Added `0036` verify gate in `./verify.sh` to run the audit when local text reference directories exist.
- Updated `docs/architecture/graphs/text-glyphs.md` with audited primitive grammar facts and algorithmic migration implications.
- Guardrail/completion verification:
- `./verify.sh`
