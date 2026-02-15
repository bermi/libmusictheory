# 0013 — Keyboard Interaction

> Dependencies: 0008 (Keys/Signatures)
> Blocks: None directly (UI layer)

## Objective

Implement keyboard state management: note selection, visual state computation, URL persistence, and playback style detection.

## Research References

- [Guitar and Keyboard](../../research/guitar-and-keyboard.md)
- [Keyboard Interaction](../../research/algorithms/keyboard-interaction.md)
- [Guitar and Keyboard](../../research/data-structures/guitar-and-keyboard.md)

## Implementation Steps

### 1. Keyboard State (`src/keyboard.zig`)

- `KeyboardState` struct: selected notes, accidental preference, range
- `toggle(MidiNote)` — add/remove note
- `pitchClassSet() → PitchClassSet` — collapse to pitch classes

### 2. Visual State

- `updateKeyVisuals(KeyboardState) → [48]KeyVisual`
- Selected = full opacity, octave equivalents = half opacity, others = normal

### 3. URL Persistence

- `notesToUrl(selected) → []const u8` — format as "C4-E4-G4"
- `urlToNotes(url) → []MidiNote` — parse back

### 4. Playback Style

- `playbackStyle(PitchClassSet) → PlaybackMode`
- Uses isScaley heuristic: scales → sequential, chords → simultaneous

### 5. Tests

- Toggle: add C4, add E4, add G4 → PCS = major triad
- Visual: C4 selected → C2, C3, C5 at half opacity
- URL round-trip: notes → URL → notes matches
- Playback: {C,E,G} → simultaneous, {C,D,E,F,G,A,B} → sequential

## Validation

- `tmp/harmoniousapp.net/js-client/kb.js`: full keyboard interaction
- `tmp/harmoniousapp.net/keyboard/` directory: 100+ pre-generated keyboard HTML pages

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

- `./verify.sh` passes
- `zig build verify` passes
- Toggle adds/removes notes correctly
- PCS extraction collapses octaves
- URL round-trip (notes → URL → notes) produces identical results
- Playback style heuristic matches isScaley

## Verification Data Sources

- harmoniousapp.net (`tmp/harmoniousapp.net/js-client/kb.js` — full keyboard interaction, `tmp/harmoniousapp.net/keyboard/` directory: 100+ pre-generated pages)

## Implementation History (Point-in-Time)

- `4aa8627` (2026-02-15):
  - Shipped behavior: Added `src/keyboard.zig` with bounded keyboard state toggling, octave-collapsed PCS extraction, key visual opacity computation (full/half/normal), URL note serialization/deserialization, and playback style classification via `isScaley`.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~150 lines of Zig code + ~100 lines of tests
