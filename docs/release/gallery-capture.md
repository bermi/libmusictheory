# Gallery Capture

The standalone gallery is part of the public release surface. Its screenshots must be reproducible locally and must come from the public `wasm-gallery` bundle only.

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
- `scene-set.png`
- `scene-key.png`
- `scene-chord.png`
- `scene-progression.png`
- `scene-compare.png`
- `scene-fret.png`
- `captures.json`

## Capture Contract

- captures must come from `/index.html?capture=1`
- captures must use the public `wasm-gallery` bundle only
- captures must not depend on:
  - local Harmonious reference trees
  - parity/proof bundles
  - compat-only APIs
- the capture script must fail if required screenshots are missing or unexpectedly small

## Verification

`./verify.sh` runs the gallery capture script when the required local tools are present.

Manual spot check:

1. open `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/gallery-overview.png`
2. inspect each `scene-*.png`
3. confirm the screenshots remain legible at release-candidate scale and still reflect only public APIs
