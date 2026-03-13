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

## Full Interactive API Docs

```bash
zig build wasm-docs
python3 -m http.server --directory zig-out/wasm-docs 8001
```

Open <http://localhost:8001/index.html>.

This bundle ships the full interactive examples UI plus the validation page, backed by a wasm binary with the full demo export surface.
