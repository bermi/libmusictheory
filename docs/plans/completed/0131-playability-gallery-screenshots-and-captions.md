# 0131 — Playability Gallery Screenshots And Captions

## Status

- Draft: 2026-04-11
- In progress: 2026-04-11
- Completed: 2026-04-11

## Goal

Add reproducible, captioned screenshots for the new playability-focused gallery states so the docs can show:
- the default playability guide state
- a keyboard mini-preview overlay state
- a fret mini-preview overlay state

## Scope

1. Extend the gallery screenshot capture flow with dedicated MIDI playability states.
2. Commit a small curated set of doc images derived from that deterministic capture flow.
3. Add captioned documentation for those screenshots in the README and release-facing docs.
4. Update `./verify.sh` so the screenshot filenames, docs references, and capture pipeline stay in sync.

## Files

- `/Users/bermi/code/libmusictheory/README.md`
- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/docs/release/artifacts.md`
- `/Users/bermi/code/libmusictheory/docs/release/gallery-capture.md`
- `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`
- `/Users/bermi/code/libmusictheory/docs/release/images/`
- `/Users/bermi/code/libmusictheory/docs/plans/drafts/0001-coordinator.md`
- `/Users/bermi/code/libmusictheory/scripts/capture_wasm_gallery_screenshots.mjs`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Verification

- `/Users/bermi/code/libmusictheory/./verify.sh`

## Implementation History (Point-in-Time)

- Commit: `2770f572890313803c63404231f4e8222d7795ed`
- Date: `2026-04-11`
- Shipped behavior:
  - added three deterministic gallery captures for the playability guide, piano mini overlay, and fret mini overlay states
  - checked in curated release-doc images derived from the capture pipeline under `/Users/bermi/code/libmusictheory/docs/release/images/`
  - documented the new playability gallery states in `/Users/bermi/code/libmusictheory/README.md` and linked them from release-facing docs
  - hardened `/Users/bermi/code/libmusictheory/verify.sh` so filenames, asset presence, and capture/docs agreement are enforced together
- Verification commands:
  - `/Users/bermi/code/libmusictheory/./verify.sh`
