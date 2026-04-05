# 0112 — Public Docs, Quickstarts, And Example Boundary

> Dependencies: 0111, 0087, 0076
> Follow-up: 0113, 0114

Status: In progress

## Summary

Turn the standalone docs, README, reviewer guide, and gallery onboarding into a stable-release-quality path that a new reviewer can follow without repo archaeology or hidden tribal knowledge.

## Why

The library can now do much more than the original RC documentation suggests. The remaining work is not adding more features; it is making the intended entry paths obvious, bounded, and honest for stable users.

## Scope

### Quickstarts

- provide one clear native build / verify path
- provide one clear standalone docs path
- provide one clear standalone gallery path
- ensure the documented commands use `./zigw` where that is the supported path on current macOS hosts

### Example Boundary

- make stable examples prefer stable APIs
- move experimental examples or clearly label them as experimental when they are still valuable for review
- ensure README and reviewer docs explain which examples are contract demonstrations versus exploratory gallery features

### Reviewer Experience

- tighten `RELEASE_CHECKLIST.md`
- tighten `docs/release/reviewer-guide.md`
- make the review flow map directly to the shipped bundles and capture artifacts

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must check that quickstart commands, bundle names, and reviewer docs stay synchronized
- `./verify.sh` must fail if stable example sections silently depend on experimental helpers

## Exit Criteria

- a reviewer can get from clone to verify to docs to gallery with one obvious path
- stable and experimental examples are clearly separated
- release docs read like a stable handoff instead of RC scaffolding
- `./verify.sh` passes
