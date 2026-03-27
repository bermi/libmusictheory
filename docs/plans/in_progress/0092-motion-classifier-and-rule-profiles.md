# 0092 — Motion Classifier And Rule Profiles

> Dependencies: 0091
> Follow-up: 0093, 0094

Status: In Progress

## Summary

Build the adjacent-state motion semantics and style-profile system needed to distinguish good counterpoint from merely short voice-leading distance.

## Scope

### MotionClassifier

Per adjacent state pair, classify:

- contrary motion
- similar motion
- parallel motion
- oblique motion
- voice crossing
- voice overlap
- step vs leap magnitude
- common-tone retention
- outer-voice interval trajectory

### CounterpointRuleProfile

Provide multiple reusable profiles instead of one hidden rule set:

- species
- tonal chorale
- modal polyphony
- jazz close-leading
- free contemporary

Each profile should specify at least:

- which motion classes are preferred, penalized, or disallowed
- spacing expectations
- leap handling expectations
- cadence weighting hooks
- dissonance/tendency-tone expectations where already available

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain explicit coverage that all declared profiles are exported/documented consistently
- tests must cover each motion class with small deterministic fixtures
- tests must prove that profile weights actually alter scoring outcomes

## Exit Criteria

- adjacent-state motion classes are available as deterministic library results
- multiple rule profiles exist and change evaluation behavior in tests
- the library can explain motion semantics without relying on gallery JS heuristics
- `./verify.sh` passes
