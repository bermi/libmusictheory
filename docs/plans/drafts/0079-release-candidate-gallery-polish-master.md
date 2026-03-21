# 0079 — Release Candidate Gallery Polish Master

> Dependencies: 0073, 0078
> Follow-up: 0080-0082

Status: Draft

## Objective

Turn the newly clean standalone release surface into a release candidate that is easy to evaluate visually and technically.

This phase is not about proving parity with harmoniousapp.net again. That proof is already closed. It is about making the standalone library legible, attractive, and credible as a product developers would actually adopt.

## Why This Phase Exists

The repo now has:

- a stable public header
- a standalone docs bundle
- a standalone gallery bundle
- a release smoke path
- explicit separation between public APIs and internal Harmonious regression infrastructure

That is enough for a technically honest release. It is not yet enough for a strong release candidate.

The current gallery is real and verified, but it is still closer to a smoke-tested technical demo than a polished outward-facing showcase. This phase raises the bar on:

- visual curation
- example quality
- onboarding clarity
- release-candidate presentation

## Principles

### 1. Public examples must feel intentional

The gallery should demonstrate why `libmusictheory` is useful for novel music-discovery interfaces, not just prove that the wasm exports work.

### 2. Public examples must stay on public APIs

No gallery scene may depend on:

- `libmusictheory_compat.h`
- Harmonious parity/proof wasm targets
- internal compat/proof namespaces
- local `tmp/harmoniousapp.net` data

### 3. Release-candidate materials must be reproducible

Any screenshots, scene presets, and release notes scaffolding added in this phase must be generated or verified locally.

### 4. Verification remains mandatory

The release candidate must not relax the existing verification discipline. `./verify.sh` remains the gate, and new gallery/release-candidate behavior must be enforced programmatically.

## Workstreams

### 1. Gallery Scene Expansion

Plan: `0080`

Add stronger standalone gallery scenes and preset curation so the gallery communicates creative use cases instead of only low-level capabilities.

Candidate additions:

- harmonic neighborhood explorer
- progression tension/relaxation view
- voice-leading constellation view
- alternate-tuning voicing explorer with better preset storytelling
- set-class comparison scene with more musical framing

### 2. Gallery Presentation And Capture Pipeline

Plan: `0081`

Make the gallery presentable as release-candidate material.

Scope:

- stronger copy and layout hierarchy
- stable preset ordering
- exportable screenshot/capture workflow
- verified representative screenshots or scene manifests
- docs for how to regenerate the gallery artifacts locally

### 3. Release Candidate Cut And Notes

Plan: `0082`

Prepare the first standalone release candidate cut.

Scope:

- choose the first non-dev version target
- promote `CHANGELOG.md` from scaffold to real release notes
- tighten `RELEASE_CHECKLIST.md` for the first candidate cut
- add a short release-candidate evaluation guide for local reviewers

## Exit Criteria

`0079` should only be considered complete when:

- `0080`, `0081`, and `0082` are completed
- the gallery reads as a curated product surface, not just a smoke-tested wasm demo
- release-candidate notes and evaluation steps are documented
- `./verify.sh` still passes

## Non-Goals

- No return to Harmonious parity work as the main story
- No production hosting/deployment pipeline
- No package-registry automation
- No unstable API expansion just to make the gallery more impressive
