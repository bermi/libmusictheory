# Release Candidate Reviewer Guide

Target: `0.1.0-rc.1`

This guide is for local review of the standalone `libmusictheory` release candidate.

## What To Review

Review only the standalone surfaces:

- native build outputs from `./zigw build`
- the public C ABI in `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- the standalone docs bundle from `./zigw build wasm-docs`
- the standalone gallery bundle from `./zigw build wasm-gallery`

Do not use internal Harmonious validation/proof bundles for release-candidate signoff.

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

## Gallery Review

Run:

```bash
cd /Users/bermi/code/libmusictheory
./zigw build wasm-gallery
python3 -m http.server --directory /Users/bermi/code/libmusictheory/zig-out/wasm-gallery 8002
```

Open [http://localhost:8002/index.html](http://localhost:8002/index.html).

Review points:

- hero and scene cards load without layout breakage
- the live MIDI scene appears above the fold and shows a ready/connected state
- after connecting a MIDI controller, sustain (`CC64`) keeps sounding notes visible, changing tonic/mode visibly changes the interpretation and suggestions, middle pedal (`CC66`) stores a clickable snapshot that restores both notes and context, cross-register voicings paint a grand staff instead of collapsing into a triad proxy, and the live scene keeps both `OPTIC/K` and evenness field diagrams visible and populated
- clock scenes are large, centered, and crisp
- the set scene includes all three public set visuals together: colored clock, `OPTIC/K` group diagram, and focused evenness field
- chord/staff scenes show proper clef opening, simultaneous cluster layout, readable accidentals, and the key scene includes a visible multi-bar staff walk
- fret scenes are centered and remain legible across arbitrary tuning/string-count examples

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

The atlas is a single labeled image that lays out only the public image-producing docs methods, one row per method, as direct PNGs encoded from RGBA buffers returned by the library. It is not an SVG preview sheet. The current public set includes the `OPTIC/K` group diagram, the static evenness chart, the focused evenness field, and the multi-bar `lmt_svg_key_staff` row.

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
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/` uses only public APIs
- release docs do not require local Harmonious reference data
