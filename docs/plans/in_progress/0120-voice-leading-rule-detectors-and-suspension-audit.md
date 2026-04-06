# 0120 — Voice-Leading Rule Detectors And Suspension Audit

> Dependencies: contrapunk-theory-integration, 0011, 0091, 0117, 0020
> Follow-up: 0121

Status: In progress

## Summary

Add textbook part-writing detectors that complement the existing counterpoint engine, then audit the current suspension surface to extend only the missing explainable detail.

## Scope

- create `/Users/bermi/code/libmusictheory/src/voice_leading_rules.zig`
- add detectors for:
  - parallel fifths
  - parallel octaves/unisons
  - voice crossing
  - spacing violations
  - motion-independence collapse
- expose offending voice pairs through experimental C ABI structs
- audit `/Users/bermi/code/libmusictheory/src/counterpoint.zig` suspension summaries before adding any new suspension fields
- update `/Users/bermi/code/libmusictheory/verify.sh` before implementation lands

## Explainability Check

An LLM should be able to say: `The alto and tenor move from one perfect fifth to another in similar motion, so this creates parallel fifths.`

## Exit Criteria

- rule detectors agree with focused textbook-fact tests
- suspension additions, if any, are strictly additive and non-duplicative
- voice-pair outputs use the same voice identity assumptions as existing counterpoint surfaces
- `./verify.sh` passes
