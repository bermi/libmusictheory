# WASM Browser Bundles

## Validation Bundle

```bash
zig build wasm-demo
```

This emits a validation-focused browser bundle to `zig-out/wasm-demo/`.

If `tmp/harmoniousapp.net/` exists locally, the reference SVG tree is mirrored into:

```text
zig-out/wasm-demo/tmp/harmoniousapp.net/
```

That makes the default validation reference root `/tmp/harmoniousapp.net` work when serving `zig-out/wasm-demo` directly.

## Run locally

```bash
python3 -m http.server --directory zig-out/wasm-demo 8000
```

Compatibility validation page: <http://localhost:8000/validation.html>.

## Bitmap Proof Bundle

```bash
zig build wasm-bitmap-proof
python3 -m http.server --directory zig-out/wasm-bitmap-proof 8002
```

Bitmap proof page: <http://localhost:8002/>.

The bitmap proof page accepts a scale list. The current verification baseline is:

```text
55/100,200/100
```

That means the proof lane validates native RGBA rendering at both `55%` and `200%` without browser-side rescaling.

This bundle is separate from the slim exact-SVG validation bundle. It is allowed to include proof-lane RGBA exports and raster verification code without changing the `wasm-demo` size budget.

## Full Interactive API Docs

```bash
zig build wasm-docs
python3 -m http.server --directory zig-out/wasm-docs 8001
```

Open <http://localhost:8001/index.html>.

This bundle ships the full interactive examples UI plus the validation page, backed by a wasm binary with the full demo export surface.
