# 0119 — Structured Chord Detection

> Dependencies: contrapunk-theory-integration, 0008, 0009, 0116, 0020
> Follow-up: 0120

Status: In progress

## Summary

Add structured extended chord detection built from explicit interval patterns, exhaustive root testing, and ambiguity-preserving match output.

## Scope

- create `/Users/bermi/code/libmusictheory/src/chord_detection.zig`
- add the documented Contrapunk-style extended vocabulary as explicit pattern data, but keep the count honest against the actual table we ship
- detect matches by testing every observed pitch class as a root candidate
- expose structured matches first; formatting helpers second
- cross-check interval definitions against tonal-ts chord data
- update `/Users/bermi/code/libmusictheory/verify.sh` before implementation lands

## Explainability Check

An LLM should be able to say: `These notes form Cmaj7 because, measured from C, they contain the intervals 1, 3, 5, and 7.`

## Exit Criteria

- `detect(construct(type, root))` succeeds for the supported overlapping vocabulary
- tied interpretations stay visible in the API output
- slash/bass information is preserved explicitly
- `./verify.sh` passes
