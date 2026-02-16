# WASM Interactive Documentation Demo

## Build

```bash
zig build wasm-demo
```

This emits runnable files to `zig-out/wasm-demo/`.

## Run locally

```bash
python3 -m http.server --directory zig-out/wasm-demo 8000
```

Open <http://localhost:8000>.

All music-theory and SVG outputs are produced by the WASM exports from `libmusictheory.wasm`.
