# Stable Review Decision

Status: Go for stable 0.1.0

Target under review: `0.1.0-rc.1`

## Review Inputs

- `./verify.sh`
- `./scripts/release_smoke.sh`
- `/Users/bermi/code/libmusictheory/docs/release/stability-matrix.md`
- `/Users/bermi/code/libmusictheory/docs/release/image-review-matrix.md`
- `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`

## Decision

Promote this tree to stable `0.1.0` under `0115`.

## Remaining Delta

No product or verification blockers remain from the stable review sweep. The remaining delta is mechanical release promotion work only:

- update `VERSION` and stable-facing release metadata
- rewrite the reviewer guide and checklist for the stable cut
- prepare the exact tag / merge handoff

## Issue Classification

### Must Fix Before Stable

None.

### Acceptable For Stable

- the stable contract remains the public SVG surface and the docs bundle, as classified in `/Users/bermi/code/libmusictheory/docs/release/stability-matrix.md`
- the direct bitmap APIs remain experimental and governed by the docs QA atlas threshold of `0.005`
- the gallery preview toggle remains an experimental proof tool governed by the critical-host drift threshold of `0.07`

### Defer To Post-0.1.0

- any future promise of stable exact SVG-vs-bitmap parity
- tighter gallery preview drift thresholds beyond the current experimental proof bar
- further stable-surface expansion beyond the current documented contract

## Notes

This file is the authoritative go / no-go record for the stable cut. `0115` may promote metadata only because this file now records an explicit go decision backed by `./verify.sh` and `./scripts/release_smoke.sh`.
