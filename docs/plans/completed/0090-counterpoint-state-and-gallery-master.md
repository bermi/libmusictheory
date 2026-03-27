# 0090 — Counterpoint State And Gallery Master

> Dependencies: 0010, 0011, 0077, 0087
> Follow-up: 0091, 0092, 0093, 0094

Status: Completed

## Objective

Turn `libmusictheory` from a harmony-and-static-graph library into a time-aware counterpoint and voice-leading system that can explain the current musical state, rank plausible next moves, and surface those decisions inside the interactive gallery.

## Why This Phase Exists

The library already knew pitch-class structure, harmony, evenness, keyboard/fret/staff rendering, and static voice-leading distance. This phase added the missing continuity layer: voiced identity through time, motion semantics, profile-aware ranking, and gallery exposure grounded in the same library state.

## Exit Criteria

- the library can represent a time-aware voiced musical state with history
- adjacent-state motion is explicitly classified and testable
- multiple counterpoint/voice-leading profiles are available rather than one hidden policy
- ranked next moves carry machine-readable and human-readable reasons
- the standalone gallery can surface the current state and plausible continuations with optional piano/fret mini views
- `./verify.sh` remains the source-of-truth gate for all shipped slices

## Verification Commands

- `./verify.sh`
- `./zigw build test`

## Implementation History (Point-in-Time)

- `fc8998b` — 2026-03-27
- Shipped behavior:
  - added `VoicedState`, `VoicedHistoryWindow`, cadence-state inference, deterministic voice assignment, and experimental ABI exports in `/Users/bermi/code/libmusictheory/src/counterpoint.zig`, `/Users/bermi/code/libmusictheory/src/c_api.zig`, and `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
  - added verification and documentation for time-aware counterpoint state in `/Users/bermi/code/libmusictheory/src/tests/counterpoint_test.zig`, `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`, `/Users/bermi/code/libmusictheory/verify.sh`, and `/Users/bermi/code/libmusictheory/docs/research/algorithms/voice-leading.md`
- Completion gates used:
  - `./verify.sh`
  - `./zigw build test`

- `5b0a7ef` — 2026-03-27
- Shipped behavior:
  - added adjacent-state motion classification, counterpoint rule profiles, reason-coded next-step ranking, and exported manifest helpers in `/Users/bermi/code/libmusictheory/src/counterpoint.zig`, `/Users/bermi/code/libmusictheory/src/c_api.zig`, `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, and `/Users/bermi/code/libmusictheory/build.zig`
  - exposed the counterpoint engine inside the standalone gallery with live MIDI profile selection, temporal history, ranked suggestions, and optional piano/fret mini views in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`, `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html`, and `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css`
  - tightened verification for public bitmap fret parity and live gallery counterpoint/miniview coherence in `/Users/bermi/code/libmusictheory/src/svg/fret.zig`, `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`, `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, and `/Users/bermi/code/libmusictheory/verify.sh`
- Completion gates used:
  - `./verify.sh`
  - `./zigw build test`
