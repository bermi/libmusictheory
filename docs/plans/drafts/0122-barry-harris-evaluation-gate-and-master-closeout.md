# 0122 — Barry Harris Evaluation Gate And Master Closeout

> Dependencies: contrapunk-theory-integration, 0117, 0121

Status: Draft

## Summary

Make an explicit yes/no decision on Barry Harris support, document the reasoning, and close the Contrapunk integration master plan only after the accepted slices are fully verified.

## Scope

- evaluate Barry Harris against the ordered-scale semantics added in `0116` and `0117`
- decide whether Barry Harris belongs in:
  - `ScaleType`
  - `ModeType`
  - an experimental ordered-scale-only API
  - or a documented deferral
- if rejected or deferred, document the exact reason in research/docs
- if accepted, add a narrowly explainable parity API rather than overloading generic mode identification
- close `/Users/bermi/code/libmusictheory/docs/plans/in_progress/contrapunk-theory-integration.md` only after all accepted slices are complete and verified

## Explainability Check

An LLM should be able to say either `This belongs in the library because the parity rule is an explicit pedagogical claim` or `This is deferred because it would blur the semantics of the current mode API.`

## Exit Criteria

- Barry Harris has a documented resolution
- the master Contrapunk plan is moved to `completed` with implementation history
- `/Users/bermi/code/libmusictheory/./verify.sh` passes on the final tree
