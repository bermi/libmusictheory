# 0082 — First Release Candidate Cut

> Dependencies: 0078, 0079, 0083

Status: Completed

## Summary

Prepare the first standalone release candidate using the new release scaffold and the polished gallery surface.

## Goals

- choose the first release-candidate version
- turn the changelog scaffold into real release notes
- tighten the release checklist for the first candidate cut
- document how reviewers should evaluate the standalone release locally

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must require an updated `VERSION` and non-placeholder changelog/release-checklist content once this plan begins
- release-candidate docs must stay independent from local Harmonious data

## Exit Criteria

- version target is chosen and reflected in `VERSION`
- release notes describe the standalone surface honestly
- evaluation steps for local reviewers are documented
- `./verify.sh` passes

## Implementation History (Point-in-Time)

- Commit hash: `PENDING`
- Date: 2026-03-22
- Shipped behavior:
  - cut the first standalone release-candidate target as `0.1.0-rc.1` in `/Users/bermi/code/libmusictheory/VERSION`
  - replaced the changelog scaffold in `/Users/bermi/code/libmusictheory/CHANGELOG.md` with a real `0.1.0-rc.1` entry describing the standalone public surface, gallery, and verification state
  - tightened `/Users/bermi/code/libmusictheory/RELEASE_CHECKLIST.md` for reviewer-facing RC evaluation and added `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`
  - kept release documentation on standalone surfaces only by removing internal regression artifact references from `/Users/bermi/code/libmusictheory/docs/release/`
  - updated `/Users/bermi/code/libmusictheory/verify.sh` so an active or completed `0082` plan requires an `-rc.N` version, a dated changelog entry, reviewer documentation, and release docs that do not depend on local Harmonious tooling
- Verification commands:
  - `./verify.sh`
