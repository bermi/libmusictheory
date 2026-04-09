# 0129 - Personalized Profiles And Practice Feedback

Status: Completed

## Summary

Add explicit personalization and practice-oriented feedback on top of the playability engine.

This slice should make it possible for tools to adapt the same passage for different players without claiming that one difficulty level is universally correct.

## Why

The strongest pedagogical value in the cited work is not merely automatic fingering. It is adaptation:
- smaller or larger hands
- comfort versus stretch tolerance
- beginner-focused bottleneck protection
- practice feedback that suggests easier realizations while preserving musical intent

## Deliverables

1. Explicit hand-size and comfort-window profiles
2. Named but experimental presets plus raw parameter entry
3. Practice-facing feedback helpers that can suggest:
- easier realization
- lower-bottleneck alternative
- reduced-span alternative
- safer next-step alternative
4. Difficulty summaries for hosts that need to condition generation or filter outputs

## Recommended file work

Create:
- `/Users/bermi/code/libmusictheory/src/playability/profile.zig`
- `/Users/bermi/code/libmusictheory/src/tests/playability_profile_test.zig`

Modify:
- `/Users/bermi/code/libmusictheory/src/playability/ranking.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/docs/release/stability-matrix.md`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`

## Experimental ABI direction

- `lmt_playability_profile_preset_count`
- `lmt_playability_profile_preset_name`
- `lmt_playability_profile_from_preset`
- `lmt_suggest_easier_realization_*`
- `lmt_summarize_playability_difficulty_*`

## Critical review guardrail

Do not claim that these profiles diagnose injury risk or reflect all players. They are user-selected comfort models and pedagogy presets.

## Explainability check

An LLM should be able to say:
- "Under the selected beginner profile, this voicing is not rejected for theory reasons but because it exceeds the configured comfort span. Here is a lower-bottleneck alternative."

## Scope

M

## Verification gates

- preset reflection tests
- profile parameter round-trip tests
- easier-alternative suggestions must preserve the requested musical target where possible
- `./verify.sh`

## Verification Commands

- `./zigw build test`
- `./verify.sh`

## Implementation History (Point-in-Time)

- `c012bda4090557998b29bb59775dfbe7fd0ca9f2` - `2026-04-09T04:52:57+02:00`
  - added `/Users/bermi/code/libmusictheory/src/playability/profile.zig` with experimental profile presets, difficulty summaries for fret and keyboard realizations/transitions, and practice-facing helpers that suggest easier realizations and safer keyboard next steps without changing theory-first behavior by default
  - exposed the new playability profile and difficulty-summary surface through `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, `/Users/bermi/code/libmusictheory/src/c_api.zig`, `/Users/bermi/code/libmusictheory/build.zig`, and `/Users/bermi/code/libmusictheory/scripts/check_wasm_exports.mjs`
  - added focused Zig and C ABI coverage in `/Users/bermi/code/libmusictheory/src/tests/playability_profile_test.zig` and `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`, then hardened `/Users/bermi/code/libmusictheory/verify.sh` and the playability docs so the new personalization lane is programmatically and narratively enforced
  - verification gates: `./zigw build test`, `./verify.sh`
