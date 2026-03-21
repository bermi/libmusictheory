# 0081 — Gallery Presentation And Capture Pipeline

> Dependencies: 0077, 0079

Status: Draft

## Summary

Make the standalone gallery suitable for release-candidate review by improving presentation quality and adding a reproducible local capture workflow for representative screenshots.

## Goals

- strengthen gallery information hierarchy and copy
- define a stable set of showcase presets
- add a local script or documented flow that captures representative gallery screenshots
- verify that the capture flow still works as the gallery evolves

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must require the presence of gallery capture docs and capture scripts once this plan begins
- `./verify.sh` must enforce that capture targets only use public gallery routes and not internal Harmonious bundles

## Exit Criteria

- release-candidate screenshots can be regenerated locally
- representative scenes are documented and stable
- gallery presentation is improved without weakening the public-API-only rule
- `./verify.sh` passes
