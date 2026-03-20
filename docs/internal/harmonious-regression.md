# Harmonious Regression Infrastructure

This document describes the internal regression infrastructure that keeps `libmusictheory` honest against the original harmoniousapp.net corpus.

This is not the standalone product surface. The standalone entry points are the root `/Users/bermi/code/libmusictheory/README.md`, `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, and `zig build wasm-docs`.

## Exact SVG Parity

Purpose:

- authoritative byte-for-byte regression against the captured harmoniousapp.net SVG corpus

Primary bundle:

- `zig build wasm-demo`

Primary surface:

- `zig-out/wasm-demo/validation.html`

This lane depends on local capture data under:

- `/Users/bermi/code/libmusictheory/tmp/harmoniousapp.net`

## Scaled Render Parity

Purpose:

- compare our candidate rendering and the harmonious reference at the same target bitmap size
- validate scalable rendering behavior at `55%` and `200%`

Primary bundle:

- `zig build wasm-scaled-render-parity`

Primary surface:

- `zig-out/wasm-scaled-render-parity/index.html`

This remains internal regression infrastructure even though it exercises all 15 compatibility kinds.

## Native RGBA Proof

Purpose:

- prove that the candidate bitmap was produced inside Zig/WASM as `native-rgba`
- keep strict bitmap proof separate from weaker parity claims

Primary bundle:

- `zig build wasm-native-rgba-proof`

Primary surface:

- `zig-out/wasm-native-rgba-proof/index.html`

This lane also depends on local capture data under `/Users/bermi/code/libmusictheory/tmp/harmoniousapp.net`.

## Harmonious SPA

Purpose:

- local regression shell that reconstructs harmoniousapp.net interactions while replacing image generation with `libmusictheory`

Primary bundle:

- `zig build wasm-harmonious-spa`

Primary surface:

- `zig-out/wasm-harmonious-spa/index.html`

This is internal regression infrastructure. It is useful for verifying behavior parity, but it is not the standalone library story.

## Reduced Release Smoke

Release smoke is the standalone path that does not require local Harmonious capture data.

The required release smoke surfaces are:

- root `/Users/bermi/code/libmusictheory/README.md`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `zig build verify`
- `zig build wasm-docs`

When `/Users/bermi/code/libmusictheory/tmp/harmoniousapp.net` is absent, `./verify.sh` should still report release smoke and mark the extended Harmonious regression lanes as skipped or unverified rather than pretending they ran.

## Extended Harmonious Regression

When `/Users/bermi/code/libmusictheory/tmp/harmoniousapp.net` is present locally, `./verify.sh` also runs the extended Harmonious regression lanes:

- exact SVG parity
- scaled render parity
- native RGBA proof
- Harmonious SPA Playwright coverage

That is the full internal regression infrastructure. It remains available in-repo, but it should not define the library’s public identity.
