# 0104 — Counterpoint Consensus Atlas

> Dependencies: 0103
> Follow-up: none

Status: Completed

## Summary

Extend the live MIDI counterpoint scene with a consensus-atlas view that clusters immediate next moves by cross-profile agreement, so composers can see which continuations are broadly supported and which are style-specific outliers before committing to one branch.

## Why

`0103` made it easy to compare how the same committed move evolves under each counterpoint profile. That answers a downstream question well, but it still assumes the composer has already chosen a root move to inspect.

The missing upstream question is: which immediate next moves are actually shared across profiles, and which ones only appear in one stylistic lens? A consensus atlas gives that answer directly by regrouping the top-ranked next moves from all profiles into shared families.

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the consensus-atlas host, styles, runtime wiring, and Playwright coverage.
- gallery validation must verify that:
  - the atlas renders populated clusters from the current voiced state
  - at least one cluster represents multi-profile agreement
  - the currently focused or pinned active-profile candidate highlights the matching consensus cluster
  - profile, context, hover, pin, clear-pin, preview-mode, and mini-mode changes keep the atlas synchronized
  - terminal clock and mini previews render for the visible consensus clusters

### Consensus Clustering

Reuse the existing library-owned counterpoint engine; do not introduce a separate JS-only ranking policy.

For each declared profile:

- rank immediate next moves from the current voiced history window
- collect a small top slice of candidates per profile
- cluster candidates by actual voiced-note signature
- summarize each cluster with:
  - support count across profiles
  - top-rank count
  - representative cadence tendency
  - representative reasons and warnings
  - terminal clock preview and mini instrument preview

### Gallery View

Add a dedicated gallery card that shows:

- one cluster card per visible consensus family
- consensus vs outlier framing
- focused-cluster highlighting tied to the active-profile focused or pinned candidate
- profile membership near the move label
- terminal clock and mini previews per cluster

## Exit Criteria

- live MIDI scene includes a consensus-atlas view driven by the current voiced state
- visible clusters come from regrouped library-owned profile rankings, not a separate JS-only theory policy
- at least one multi-profile cluster and one outlier cluster are visible when the scene is populated
- hover, pin, clear-pin, context changes, profile changes, and mini instrument changes keep the atlas synchronized
- gallery validation proves the behavior
- `./verify.sh` passes


## Verification Commands

- `./zigw build wasm-gallery`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `./verify.sh`

## Implementation History (Point-in-Time)

- `ef321bf` — 2026-04-04 — added the live MIDI consensus-atlas card, clustered immediate next moves by cross-profile agreement, and tightened gallery/runtime verification so hover, pin, profile, context, preview, and mini-mode changes keep the atlas synchronized.
- Completion gates: `./zigw build wasm-gallery`, `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`, `./verify.sh`
