# Release Artifacts

## Public Native Artifacts

These are the native outputs a standalone consumer should rely on after running `zig build`.

| Path | Surface | Notes |
| --- | --- | --- |
| `zig-out/include/libmusictheory.h` | Stable C ABI header | Public embedding contract. |
| `zig-out/lib/libmusictheory.a` | Static library | Native linking for CLI/apps/plugins. |
| `zig-out/lib/libmusictheory.dylib` / `zig-out/lib/libmusictheory.so` / `zig-out/lib/musictheory.dll` | Shared library | Platform-dependent filename. |

## Public Browser Artifacts

These are the browser-facing standalone bundles.

| Path | Surface | Notes |
| --- | --- | --- |
| `zig-out/wasm-docs/index.html` | Interactive docs shell | Public docs/examples bundle. |
| `zig-out/wasm-docs/libmusictheory.wasm` | Docs wasm module | Exported surface checked by `scripts/check_wasm_exports.mjs --profile full_demo`. |
| `zig-out/wasm-gallery/index.html` | Creative gallery shell | Public gallery/demo bundle. |
| `zig-out/wasm-gallery/libmusictheory.wasm` | Gallery wasm module | Exported surface checked by `scripts/check_wasm_exports.mjs --profile gallery`. |

## Internal Artifacts Still Present In Repo

These remain useful for regression work, but they are not the standalone release story.

| Path or target | Role |
| --- | --- |
| `zig-out/include/libmusictheory_compat.h` | Internal compat/proof header split from the stable public header. |
| `zig build wasm-demo` | Exact Harmonious SVG parity validation bundle. |
| `zig build wasm-scaled-render-parity` | Internal scaled bitmap parity bundle. |
| `zig build wasm-native-rgba-proof` | Internal strict native RGBA proof bundle. |
| `zig build wasm-harmonious-spa` | Internal local SPA/regression shell. |

## Build Targets

- `zig build`
- `zig build c-smoke`
- `zig build test`
- `zig build verify`
- `zig build wasm-docs`
- `zig build wasm-gallery`
- `bash scripts/release_smoke.sh`
- `./verify.sh`
