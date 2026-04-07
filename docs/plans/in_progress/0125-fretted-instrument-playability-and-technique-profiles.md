# 0125 - Fretted Instrument Playability And Technique Profiles

Status: In Progress

## Summary

Implement the first explainable playability engine for fretted instruments using the topology foundation from `0124`.

The first wave should cover what the research actually supports strongly:
- redundant pitch-location choice
- hand-position windows
- fret span and longitudinal jump size
- open-string relief
- bottleneck move severity
- configurable comfort versus limit windows

Technique profiles such as bass Simandl, OFPF, slap/pop, or 7-string thumb constraints should remain explicitly experimental and profile-scoped.

## Why

The strongest paper-backed foundation here is not a specific guitar pedagogy. It is:
- topology-aware note placement across strings and frets
- path optimization across state transitions
- minimax bottleneck protection for human playability

That is enough to build useful, explainable fret hints without overclaiming.

## Deliverables

1. Fret realization assessment for single notes, sets, and transitions
2. Structured blockers and warnings such as:
- span exceeds comfort window
- span exceeds hard limit
- excessive longitudinal shift
- unnecessary string change
- repeated maximal-stretch move
- weak-finger stress or unsupported extension where profile encodes it
3. Minimax-style bottleneck scoring for phrase fragments
4. Optional experimental technique profiles:
- `generic_guitar`
- `bass_simandl`
- `bass_ofpf`
- `extended_range_classical_thumb`

## Recommended file work

Create:
- `/Users/bermi/code/libmusictheory/src/playability/fret_assessment.zig`
- `/Users/bermi/code/libmusictheory/src/tests/fret_playability_test.zig`

Modify:
- `/Users/bermi/code/libmusictheory/src/guitar.zig`
- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/guitar_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/guitar-voicing.md`

## Experimental ABI direction

Assessment helpers:
- `lmt_assess_fret_realization_n`
- `lmt_assess_fret_transition_n`
- `lmt_rank_fret_realizations_n`

Output structs should include:
- chosen or assessed position window
- bottleneck cost
- cumulative cost
- hard blockers bitset
- warnings bitset
- recommended finger labels when the result is sufficiently constrained

## Critical review guardrail

Do not hard-code bass or 7-string pedagogy as universal truth in this slice. If we ship presets, they must be named as presets and treated as opt-in profiles.

## Explainability check

An LLM should be able to say:
- "This standard-tuning realization is playable, but it forces a five-fret stretch from the current position."
- "This alternate realization uses an open string and removes the hardest shift in the phrase."

## Scope

L

## Verification gates

- arbitrary tuning coverage
- bottleneck-versus-cumulative test cases
- profile-scoped warnings only when the profile is active
- `./verify.sh`
