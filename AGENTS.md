# AGENTS

Project instructions for working effectively in this repo.

## Toolchain
- Use Zig 0.15.x.
- Preferred commands:
  - `./verify.sh`
  - `zig build verify`
  - `zig build test`

## Build Conventions
- `./verify.sh` is the single source of truth and must pass before committing.
- `zig build verify` is invoked by `./verify.sh`.
- `verify` includes tests and formatting checks.

## Work Style
- Keep APIs minimal and explicit; no allocations in core algorithms.
- Use u12 bitset for all pitch class set operations.
- Use comptime for lookup table generation where possible.
- Add focused unit tests for each new behavior.
- Validate outputs against reference data from harmoniousapp.net, music21, and tonal-ts.
- Update docs in `docs/research/` when algorithms change.
- Read `CONSTRAINTS.md` before executing plan slices that touch public APIs or core algorithms.
- Before implementing a plan slice, update `./verify.sh` so the new behavior/constraints are programmatically checked.

## Verification Data
- **music21** (`/Users/bermi/tmp/music21/`): Forte number tables in `music21/chord/tables.py`, interval vectors, prime forms. Use as ground truth for set classification.
- **tonal-ts** (`/Users/bermi/tmp/tonal-ts/`): Scale/chord databases in `packages/dictionary/data/`. Use for chord type and scale type validation.
- **harmoniousapp.net** (local `tmp/harmoniousapp.net/p/` and `tmp/harmoniousapp.net/js-client/`): Original source material. Use for algorithm behavior verification.

## Git Workflow
- Every change set must be committed and pushed.
- Use clear, single-purpose commit messages.

## Plans
- Break work into small tasks under `docs/plans/`.
- Plan lifecycle is mandatory: `docs/plans/drafts/` -> `docs/plans/in_progress/` -> `docs/plans/completed/`.
- When implementation starts, move the plan file to `docs/plans/in_progress/` in the same commit as the first code change.
- When all slices are done and `./verify.sh` passes, move the plan file to `docs/plans/completed/` in the same commit as completion.
- Every completed plan must include an `Implementation History (Point-in-Time)` section with:
  - commit hash and date,
  - concrete shipped behavior for that commit,
  - verification command(s) used as completion gates (`./verify.sh`, `zig build verify`).
- Keep `docs/plans/drafts/0001-coordinator.md` aligned with plan execution progress.
