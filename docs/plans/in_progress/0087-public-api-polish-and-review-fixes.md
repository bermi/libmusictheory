# 0087 — Public API Polish And Review Fixes

> Dependencies: 0085, 0074, 0076
> Follow-up: none

Status: In progress

## Summary

Address the remaining small public-surface rough edges discovered during RC review without widening the supported API beyond what the first stable cut can actually guarantee.

## Goals

- improve public API clarity where names, docs, or examples are misleading
- tighten the standalone docs/gallery examples around the stable contract
- keep all compatibility/proof infrastructure internal

## Candidate Scope

- public header documentation cleanup
- README and docs quickstart refinements
- example code improvements in docs/gallery where the stable surface is underspecified
- minor ergonomic improvements that preserve caller-owned buffer discipline and current ABI boundaries
- deterministic QA atlas page and screenshot capture for the public image-producing docs methods
- review-driven public image QA fixes:
  - measured clock-label layout for `lmt_svg_clock_optc`
  - public pitch-class clocks use the standalone palette instead of monochrome fallback
  - expose a public algorithmic `OPTIC/K` group diagram in docs, gallery, and bitmap QA atlas
  - expose a public focused evenness-field diagram in docs, gallery, live MIDI scene, and bitmap QA atlas
  - false-barre rejection for `lmt_svg_fret`
  - explicit barre-sample coverage in the bitmap QA atlas for `lmt_svg_fret`
  - aspect-correct bitmap QA capture for `lmt_svg_chord_staff`
  - public staff-position cleanup where line/ledger placement was visually misleading
  - lower-C ledger-line placement and stem-notehead alignment fixes for `lmt_svg_chord_staff`
  - add a real public multi-bar key-staff API and gallery/docs example instead of implying that a one-bar chord staff covers melodic/key notation
  - expose the public evenness chart in the docs, gallery, and bitmap QA atlas instead of showing only a scalar evenness number
  - expose a public keyboard diagram with highlighted notes and pitch-class colors on the standalone surface
  - replace the live MIDI scene's triad proxy with a real public piano-staff API that paints treble, bass, or grand staff from arbitrary MIDI note arrays
  - add live MIDI fret guidance in the gallery so the current held set and ranked next-step suggestions both expose compact `EADGBE` voicing previews
  - provide a stable Zig `0.15.x` wrapper for repo builds so `verify.sh`, release smoke, docs, and gallery commands do not depend on the broken host `zig build` path on macOS arm64
  - move the live MIDI compact-fret voicing selector out of gallery JS and into an explicitly experimental library helper so browser and embedded hosts use the same deterministic selection policy

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain checks for any newly clarified public contract language or example expectations
- no new public API should be added unless the stable/experimental/internal classification is updated at the same time

## Exit Criteria

- public docs and examples are clearer at the stable boundary
- any changed API language is enforced by verification
- the bitmap QA atlas remains visually inspectable and does not distort method output during capture
- known public image defects from RC review are either fixed or explicitly tracked; no silent “close enough” claims
- `./verify.sh` passes
