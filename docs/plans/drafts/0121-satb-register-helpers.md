# 0121 — SATB Register Helpers

> Dependencies: contrapunk-theory-integration, 0120, 0020
> Follow-up: 0122

Status: Draft

## Summary

Add choir-specific SATB range helpers as optional experimental tools, without turning them into global correctness gates for the rest of the library.

## Scope

- create `/Users/bermi/code/libmusictheory/src/choir.zig`
- model standard SATB range membership facts
- add optional register-check helpers over voiced states
- keep the feature explicitly choir-scoped in the docs and header comments
- update `/Users/bermi/code/libmusictheory/verify.sh` before implementation lands

## Explainability Check

An LLM should be able to say: `That note is outside the conventional alto range used in four-part chorale writing.`

## Exit Criteria

- range membership reflects standard SATB textbook bounds
- helpers are marked experimental and choir-specific
- no unrelated validator depends on them implicitly
- `./verify.sh` passes
