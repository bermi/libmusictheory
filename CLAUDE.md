# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

libmusictheory is a Zig library (Zig 0.15.x) exposing a C ABI that implements the complete music theory framework extracted from harmoniousapp.net. It covers pitch class set theory, scale/mode/key analysis, chord construction and naming, voice leading, guitar/keyboard instrument interfaces, and SVG visualization generation.

## Build Commands

```bash
./verify.sh                  # Single verification entrypoint (required before commits)
zig build                    # Build static library to zig-out/lib/
zig build test               # Run unit tests
zig build fmt                # Check formatting for build.zig + src/
zig build verify             # test + fmt in one step — must pass before committing
```

## Architecture

**Pure computation library with no runtime dependencies:**

- **Core types** (`src/pitch.zig`, `src/note_name.zig`, `src/interval.zig`) — PitchClass (u4), MidiNote (u7), NoteName, SpelledNote, FormulaToken, IntervalClass (u3).
- **Pitch class sets** (`src/pitch_class_set.zig`) — u12 bitset representation with transposition, inversion, complement, subset, Hamming distance.
- **Set classification** (`src/set_class.zig`) — Prime form, Forte numbers, OPTIC equivalence, 336 set classes.
- **Interval analysis** (`src/interval_vector.zig`) — Interval vectors, FC-components, Z/M-relation detection.
- **Cluster/evenness** (`src/cluster.zig`, `src/evenness.zig`) — Chromatic cluster detection, evenness distance, consonance scoring.
- **Scales/modes** (`src/scale.zig`, `src/mode.zig`) — 4 scale types, 17 modes, mode identification, scale tessellation.
- **Keys** (`src/key.zig`) — Key signatures, note spelling, circle of fifths.
- **Chords** (`src/chord.zig`, `src/chord_type.zig`) — ~100 chord types, The Game algorithm, shell/slash chords.
- **Harmony** (`src/harmony.zig`) — Roman numerals, diatonic harmony, avoid notes, chord-scale compatibility.
- **Voice leading** (`src/voice_leading.zig`) — VL distance, optimal assignment, orbifold geometry.
- **Guitar** (`src/guitar.zig`) — Tunings, fret mapping, CAGED system, voicing generation.
- **Keyboard** (`src/keyboard.zig`) — Keyboard state, key toggling, URL persistence.
- **SVG** (`src/svg/`) — Clock diagrams, staff notation, fret diagrams, tessellation maps, mode icons, evenness chart, orbifold graph, circle of fifths, key slider.
- **C API** (`src/c_api.zig`, `include/libmusictheory.h`) — FFI surface for all public functions.
- **Static tables** (`src/tables.zig`) — Compile-time precomputed lookup tables for all 336 set classes.

## Design Principles

- u12 bitset as the universal pitch class set representation.
- Comptime precomputation where possible (Forte tables, mode tables, chord type tables).
- No allocations in core algorithms; all working memory on the stack or caller-provided.
- Add focused unit tests for each new behavior, verified against reference data.
- Update `docs/` when behavior changes.
- Break work into small tasks under `docs/plans/`.

## Verification Data Sources

- **harmoniousapp.net** (local): `tmp/harmoniousapp.net/p/` directory (3,578 articles), `tmp/harmoniousapp.net/js-client/` (JavaScript source)
- **music21** (Python): `/Users/bermi/tmp/music21/` — 224 Forte-classified sets, interval vectors, prime forms, chord tables
- **tonal-ts** (TypeScript): `/Users/bermi/tmp/tonal-ts/` — 102 scale types, 116 chord types in JSON databases

## Key Paths

- Architecture research: `docs/research/`
- Phased roadmap: `docs/plans/drafts/0001-coordinator.md`
- Active plans: `docs/plans/in_progress/`
- Completed plans: `docs/plans/completed/`
