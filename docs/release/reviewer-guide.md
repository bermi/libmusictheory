# Release Candidate Reviewer Guide

Target: `0.1.0-rc.1`

This guide is for local review of the standalone `libmusictheory` release candidate.

Read `/Users/bermi/code/libmusictheory/docs/release/stability-matrix.md` first. It is the authoritative stable / experimental / internal classification for release review.
Then read `/Users/bermi/code/libmusictheory/docs/release/image-review-matrix.md` for the image-quality and parity interpretation.

## Start Here

1. Run `./verify.sh`.
2. Run `./scripts/release_smoke.sh`.
3. Review `wasm-docs` as the stable browser contract demonstration.
4. Review `wasm-gallery` as the supported standalone example surface.

This order keeps the stable signoff path clear before you spend time on the exploratory gallery surfaces.

## What To Review

Review only the standalone surfaces:

- native build outputs from `./zigw build`
- the public C ABI in `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- the standalone docs bundle from `./zigw build wasm-docs`
- the standalone gallery bundle from `./zigw build wasm-gallery`

Do not use internal Harmonious validation/proof bundles for release-candidate signoff.
The gallery bundle exercises experimental counterpoint and direct bitmap-preview helpers; review those for bundle quality, but they are not part of stable release signoff.

## Surface Classes

- stable release signoff:
  - `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, except APIs explicitly marked experimental
  - native library artifacts from `./zigw build`
  - standalone docs bundle from `./zigw build wasm-docs`
- supported example review:
  - standalone gallery bundle from `./zigw build wasm-gallery`
- internal-only regression infrastructure:
  - `/Users/bermi/code/libmusictheory/include/libmusictheory_compat.h`
  - Harmonious parity/proof/SPA bundles

The gallery should be reviewed carefully, but it must not be used to silently widen the stable contract beyond the stability matrix.

## Quick Smoke Path

Run:

```bash
cd /Users/bermi/code/libmusictheory
./scripts/release_smoke.sh
```

Expected summary:

- native build succeeds
- C smoke succeeds
- docs bundle export and browser smoke succeed
- gallery bundle export and browser smoke succeed
- gallery screenshot capture succeeds

## Stable Docs Review

Run:

```bash
cd /Users/bermi/code/libmusictheory
./zigw build wasm-docs
python3 -m http.server --directory /Users/bermi/code/libmusictheory/zig-out/wasm-docs 8001
```

Open [http://localhost:8001/index.html](http://localhost:8001/index.html).

Review points:

- the docs bundle loads without console/runtime errors
- the docs page demonstrates the stable browser contract, not gallery-only experimental helpers
- interactive public SVG examples render and remain legible
- the QA atlas is reachable at [http://localhost:8001/qa-atlas.html](http://localhost:8001/qa-atlas.html) and shows direct PNGs encoded from RGBA buffers returned by the library
- the QA atlas is a review tool for experimental bitmap APIs, not a stable promise of exact parity; the enforced docs-side drift threshold is `0.005`
- docs wording continues to point stable users to `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, `/Users/bermi/code/libmusictheory/src/root.zig`, and `wasm-docs` before the gallery

## Gallery Review

Run:

```bash
cd /Users/bermi/code/libmusictheory
./zigw build wasm-gallery
python3 -m http.server --directory /Users/bermi/code/libmusictheory/zig-out/wasm-gallery 8002
```

Open [http://localhost:8002/index.html](http://localhost:8002/index.html).

Treat this as supported example review, not stable ABI signoff.

Review points:

- hero and scene cards load without layout breakage
- the live MIDI scene appears above the fold and shows a ready/connected state
- after connecting a MIDI controller, sustain (`CC64`) keeps sounding notes visible, changing tonic/mode visibly changes the interpretation and suggestions, middle pedal (`CC66`) stores a clickable snapshot that restores both notes and context, cross-register voicings paint a grand staff instead of collapsing into a triad proxy, and the live scene keeps `OPTIC/K`, evenness, cadence funnel, and suspension-state visuals visible and populated
- clock scenes are large, centered, and crisp
- the set scene includes all three public set visuals together: colored clock, `OPTIC/K` group diagram, and focused evenness field
- chord/staff scenes show proper clef opening, simultaneous cluster layout, readable accidentals, and the key scene includes a visible multi-bar staff walk
- fret scenes are centered and remain legible across arbitrary tuning/string-count examples
- the preview toggle remains an experimental proof tool; the enforced critical-host drift threshold is `0.07`, so use it to catch incoherent regressions rather than to sign off exact bitmap parity

Optional deterministic screenshot regeneration:

```bash
cd /Users/bermi/code/libmusictheory
node /Users/bermi/code/libmusictheory/scripts/capture_wasm_gallery_screenshots.mjs
```

Inspect:

- `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/gallery-overview.png`
- `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/gallery-hero.png`
- `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-midi.png`
- `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-chord.png`
- `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-fret.png`

## QA Atlas Review

Run:

```bash
cd /Users/bermi/code/libmusictheory
node /Users/bermi/code/libmusictheory/scripts/capture_wasm_docs_qa_atlas.mjs
```

Inspect:

- `/Users/bermi/code/libmusictheory/zig-out/wasm-docs-qa/qa-atlas.png`
- `/Users/bermi/code/libmusictheory/zig-out/wasm-docs-qa/qa-atlas.json`

The atlas is a single labeled image that lays out only the stable public image-producing docs methods, one row per method, as direct PNGs encoded from RGBA buffers returned by the library. It is not an SVG preview sheet. The current public set includes the `OPTIC/K` group diagram, the static evenness chart, the focused evenness field, and the multi-bar `lmt_svg_key_staff` row.

## Public API Review

Run:

```bash
cd /Users/bermi/code/libmusictheory
./zigw build
./zigw build c-smoke
./zigw build wasm-docs
```

Check:

- `/Users/bermi/code/libmusictheory/zig-out/include/libmusictheory.h` is installed
- `/Users/bermi/code/libmusictheory/zig-out/lib/` contains native library artifacts
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/` uses only public APIs, but not only stable ones
- experimental APIs remain clearly documented as experimental in `/Users/bermi/code/libmusictheory/include/libmusictheory.h` and `/Users/bermi/code/libmusictheory/README.md`
- release docs do not require local Harmonious reference data
