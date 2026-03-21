# 0082 — First Release Candidate Cut

> Dependencies: 0078, 0079, 0083

Status: Draft

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
