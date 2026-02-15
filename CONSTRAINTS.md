# CONSTRAINTS

Execution constraints for autonomous implementation work in this repository.

## Verification Protocol
Before implementing any plan slice:
1. Read this file in full.
2. Update `./verify.sh` so the target behavior/constraint is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write/adjust tests first when feasible (red -> green flow).
5. Implement the change.
6. Run `./verify.sh` again and do not declare success unless it passes.

Do not treat ad-hoc commands as sufficient verification if `./verify.sh` does not pass.

## Hard Invariants
- No allocations in core pitch class set algorithms; all working memory on the stack.
- u12 is the canonical pitch class set representation; no alternative representations in core.
- Comptime tables must produce identical results to runtime computation.
- All 336 set classes must match Forte number assignments from music21 reference data.
- All 17 mode types must produce correct pitch class sets for any root.
- C ABI changes must preserve layout/calling compatibility unless explicitly documented.
- `./verify.sh` must pass before every commit.

## Correctness Contract
- **Forte numbers**: Must match music21's `chord/tables.py` (224 entries) and the full 336 OPTC classification.
- **Interval vectors**: Must match music21's interval vector computation for all 336 set classes.
- **Prime forms**: Must match Rahn algorithm output (compare against music21's `forteClass` property).
- **Scale types**: Must match tonal-ts's `scales.json` (102 types) for interval sequences.
- **Chord types**: Must match tonal-ts's `chords.json` (116 types) for interval arrays.
- **The Game algorithm**: Must produce exactly 560 cluster-free OTC objects and ~479 mode-compatible subsets.
- **Note spelling**: Must match harmoniousapp.net output for all 70+ key/scale contexts.
- **SVG output**: Clock diagrams, staff notation, fret diagrams must be pixel-comparable to site originals.

## Verify vs Test
- `zig build test`:
  - Unit tests for all Zig modules.
  - Should remain fast and deterministic.
- `zig build verify` (invoked by `./verify.sh`):
  - Library build
  - `test`
  - formatting check
- `./verify.sh`:
  - Orchestrates build/test/verify and structural contract checks not purely covered by Zig tests.
  - Validates file structure, exported symbols, and cross-reference consistency.

## Plan Execution Guardrail
Before implementing a draft plan slice:
1. Read this file.
2. Identify which correctness contracts apply to the change.
3. Add/adjust tests before implementing, using reference data from music21 or tonal-ts where available.
4. Verify against harmoniousapp.net source data for algorithm-specific behavior.
