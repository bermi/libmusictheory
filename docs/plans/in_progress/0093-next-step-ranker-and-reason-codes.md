# 0093 — Next Step Ranker And Reason Codes

> Dependencies: 0091, 0092
> Follow-up: 0094

Status: In Progress

## Summary

Rank plausible next moves from a `VoicedState`, using recent history and a selected rule profile, while returning explicit reason codes and score components that the gallery can expose honestly.

## Scope

- define `NextStepRanker` over `VoicedState + TemporalMemory + CounterpointRuleProfile`
- rank candidate next moves using:
  - minimal total motion
  - avoidance of parallels and crossings
  - tendency-tone resolution
  - spacing preservation
  - tension increase/decrease
  - cadence effect
  - common-tone retention
- return explicit reasons, not just a scalar score
- support both strict and permissive policies depending on profile
- expose an experimental ABI suitable for WASM/gallery use

## Reason Model

Each ranked suggestion should support at least:

- total score
- dominant contributing reasons
- warnings / penalties
- cadence direction label
- tension delta label

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain checks for exported reason-code tables or manifest consistency
- tests must prove that the same input state under different profiles yields different rankings for coherent reasons
- tests must cover temporal-memory effects so the scorer is not reducible to the current chord alone

## Exit Criteria

- ranked next moves are produced by the library rather than gallery policy code
- each suggestion carries explicit reasons and warnings
- temporal memory affects ranking in tests
- the gallery can consume the ABI without re-implementing ranking policy
- `./verify.sh` passes
