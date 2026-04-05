# 0113 — Public Image Review And Parity Closure

> Dependencies: 0111, 0112, 0087
> Follow-up: 0114

Status: Completed

## Summary

Resolve the remaining open questions around public image quality, SVG-vs-bitmap parity, and the truthfulness of the gallery/QA review story before the stable cut.

## Why

The standalone surface now exposes a serious image stack: SVG previews, direct RGBA bitmap APIs, docs QA atlas, and gallery preview toggles. The stable release cannot leave ambiguity about which parity guarantees are real, which are still experimental, and what the review gates actually prove.

## Scope

### Public Image Audit

- review the public image-producing methods one by one:
  - clocks
  - `OPTIC/K`
  - evenness chart and evenness field
  - fret diagrams
  - key staff, chord staff, and piano staff
  - keyboard diagrams
- record any remaining visual defects or parity drift that still matter for a stable review bar

### Parity Decision

- tighten SVG-vs-bitmap verification where parity is intended to be canonical
- if exact or near-exact parity is not yet defensible for a surface, keep that surface experimental and document the limitation explicitly
- ensure the gallery preview toggle and QA atlas are described as proof tools, not decorative extras

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must fail if stable docs/gallery make stronger parity claims than the actual thresholds enforce
- `./verify.sh` must fail if public image review artifacts fall out of sync with the shipped image methods

## Exit Criteria

- every public image surface has an honest quality/parity classification
- stable surfaces have the corresponding verification bar
- experimental surfaces remain available but explicitly non-stable
- `./verify.sh` passes


## Verification Commands

- `./verify.sh`
- `./zigw build verify`

## Implementation History (Point-in-Time)

- `848104c` (2026-04-05) — added `/Users/bermi/code/libmusictheory/docs/release/image-review-matrix.md`, aligned the README / reviewer guide / checklist / stability matrix with the actual `0.005` docs QA and `0.07` gallery preview thresholds, and added `0113` guardrails so release docs cannot overstate bitmap parity beyond what verification proves. Completion gates: `./verify.sh`, `./zigw build verify`.
