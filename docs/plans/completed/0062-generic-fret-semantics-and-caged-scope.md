# 0062 — Generic Fret Semantics And CAGED Scope

> Dependencies: 0012, 0061

Status: Completed

## Objective

Generalize the semantic fretboard helpers so the library can reason about arbitrary fretted instruments, not just render them.

This slice covers:

- generic voicing generation over caller-provided tunings
- generic pitch-class guide overlays
- generic fret URL encode/decode helpers

It does not pretend that CAGED is a generic fretted-instrument abstraction. CAGED remains explicitly scoped to six-string standard-guitar concepts unless a different formal model is introduced.

## Constraints

- no heap allocation in core algorithms
- keep existing six-string guitar APIs working as wrappers
- add generic APIs additively instead of mutating compatibility behavior
- docs must explicitly state that CAGED remains six-string guitar-specific

## Exit Criteria

- `src/guitar.zig` exposes:
  - `GenericVoicing`
  - `generateVoicingsGeneric`
  - `pitchClassGuideGeneric`
  - `fretsToUrlGeneric`
  - `urlToFretsGeneric`
- existing six-string helpers wrap the generic implementations where appropriate
- focused tests cover non-six-string voicing generation, guides, and URL round-trips
- docs stop implying that CAGED is generic
- `./verify.sh` passes

## Verification Commands

- `./verify.sh`
- `zig build test`

## Implementation History (Point-in-Time)

- `a6dca04` — 2026-03-15
- Shipped behavior:
  - added `GenericVoicing` plus `generateVoicingsGeneric`, `pitchClassGuideGeneric`, `fretsToUrlGeneric`, and `urlToFretsGeneric` in `/Users/bermi/code/libmusictheory/src/guitar.zig`
  - kept six-string wrappers intact, with URL helpers delegating to the new generic path
  - updated `/Users/bermi/code/libmusictheory/docs/research/algorithms/guitar-voicing.md`, `/Users/bermi/code/libmusictheory/docs/research/data-structures/guitar-and-keyboard.md`, and `/Users/bermi/code/libmusictheory/docs/architecture/graphs/fretboard.md` so CAGED is explicitly scoped to six-string standard guitar
- Completion gates used:
  - `./verify.sh`
  - `zig build verify`
