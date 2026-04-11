# Gallery Capture

The standalone gallery is part of the public release surface. Its screenshots must be reproducible locally and must come from the public `wasm-gallery` bundle only.

The capture flow also primes the live MIDI scene through a fake Web MIDI implementation so the public interactive composer workflow is visible in deterministic screenshots.

## Build And Capture

```bash
cd /Users/bermi/code/libmusictheory
zig build wasm-gallery
node /Users/bermi/code/libmusictheory/scripts/capture_wasm_gallery_screenshots.mjs
```

Default output directory:

- `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures`

Artifacts produced:

- `gallery-overview.png`
- `gallery-hero.png`
- `scene-midi.png`
- `scene-midi-playability-guide.png`
- `scene-midi-playability-piano.png`
- `scene-midi-playability-fret.png`
- `scene-set.png`
- `scene-key.png`
- `scene-chord.png`
- `scene-progression.png`
- `scene-compare.png`
- `scene-fret.png`
- `captures.json`

Curated doc images:

- `/Users/bermi/code/libmusictheory/docs/release/images/scene-midi-playability-guide.png`
- `/Users/bermi/code/libmusictheory/docs/release/images/scene-midi-playability-piano.png`
- `/Users/bermi/code/libmusictheory/docs/release/images/scene-midi-playability-fret.png`

These checked-in doc images are copied from the deterministic capture output so the README and release docs can show the playability states directly.

## Capture Contract

- captures must come from `/index.html?capture=1`
- captures must use the public `wasm-gallery` bundle only
- the live MIDI scene must be visible as `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-midi.png`
- the dedicated playability states must be captured as:
  - `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-midi-playability-guide.png`
  - `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-midi-playability-piano.png`
  - `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-midi-playability-fret.png`
- captures must not depend on:
  - local Harmonious reference trees
  - parity/proof bundles
  - compat-only APIs
- the capture script must fail if required screenshots are missing or unexpectedly small
- the gallery validator must fail if the chord staff capture loses its notation features:
  - no clef
  - no shared chord stem
  - no simultaneous chord cluster

## Verification

`./verify.sh` runs the gallery capture script when the required local tools are present.

Manual spot check:

1. open `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/gallery-overview.png`
2. inspect `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-midi-playability-guide.png`
3. inspect `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-midi-playability-piano.png`
4. inspect `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/scene-midi-playability-fret.png`
5. confirm the screenshots remain legible at release-candidate scale and still reflect only public APIs
