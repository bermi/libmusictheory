# 0129 - Personalized Profiles And Practice Feedback

Status: Draft

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
