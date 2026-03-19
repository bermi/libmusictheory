# 0075 — Harmonious Verification Quarantine

> Dependencies: 0073, 0074, 0024, 0060, 0072

Status: Draft

## Summary

Preserve the Harmonious exact-parity, scaled-parity, native-proof, and SPA tracks as internal regression infrastructure while preventing them from defining the standalone library’s public identity.

The correctness work remains valuable. The mistake would be presenting that verification machinery as the product surface.

## Goals

- Keep exact SVG parity, scaled render parity, native RGBA proof, and the local SPA available in-repo.
- Reframe them as internal verification tooling and regression harnesses.
- Make the standalone release path understandable without those tools.
- Ensure release smoke tests can run in a reduced mode that does not require local Harmonious capture data.

## Scope

- verification/doc wording cleanup
- optional local-data gating review
- internal tooling section in docs
- separation between release smoke checks and full regression checks

## Non-Goals

- No weakening of parity/proof checks
- No removal of local Harmonious validation flows
- No public API redesign by itself

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must distinguish release-surface checks from extended Harmonious regression checks
- documentation checks must fail if public-facing docs present Harmonious verification as the primary product story

## Exit Criteria

- internal verification tracks remain runnable and documented
- standalone release docs do not depend on Harmonious framing
- release-oriented smoke checks succeed without local Harmonious data
- full regression verification remains available when local data is present
- `./verify.sh` passes

