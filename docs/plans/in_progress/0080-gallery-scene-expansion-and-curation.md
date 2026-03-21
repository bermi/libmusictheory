# 0080 — Gallery Scene Expansion And Curation

> Dependencies: 0077, 0078, 0079

Status: Draft

## Summary

Expand the standalone gallery into a stronger creative showcase with curated scenes and presets that demonstrate concrete musical-discovery workflows.

## Goals

- Add at least two new gallery scenes beyond the current four
- Improve the existing scenes so each has a clear musical use case
- Curate presets so the gallery feels authored rather than random
- Keep the gallery strictly on public stable APIs

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must require a minimum gallery scene count and preset manifest presence once this plan begins
- `./verify.sh` must fail if gallery code imports compat/proof APIs or local Harmonious data

## Exit Criteria

- gallery scene count increases
- presets are explicit and documented
- Playwright covers the new representative scenes
- root README or gallery docs explain what each scene is for
- `./verify.sh` passes
