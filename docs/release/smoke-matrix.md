# Release Smoke Matrix

## Canonical Smoke Command

```bash
cd /Users/bermi/code/libmusictheory
bash scripts/release_smoke.sh
```

This command is the standalone-release smoke path. It uses only the public native/docs/gallery surfaces.

## Required Smoke Lanes

| Lane | Command | Expected evidence |
| --- | --- | --- |
| Native install artifacts | `zig build` | `zig-out/include/libmusictheory.h`, `zig-out/lib/libmusictheory.a`, and one shared library are installed. |
| C ABI smoke | `zig build c-smoke` | Static and shared smoke executables link and run. |
| Docs export surface | `node scripts/check_wasm_exports.mjs --profile full_demo --wasm zig-out/wasm-docs/libmusictheory.wasm` | Docs wasm exports match the documented browser surface. |
| Docs browser smoke | `node scripts/validate_wasm_docs_playwright.mjs` | The interactive docs bundle renders and `Run all sections` succeeds. |
| Gallery export surface | `node scripts/check_wasm_exports.mjs --profile gallery --wasm zig-out/wasm-gallery/libmusictheory.wasm` | Gallery wasm exports stay on the public API only. |
| Gallery browser smoke | `node scripts/validate_wasm_gallery_playwright.mjs` | All gallery scenes render and interactive refresh actions succeed. |

## Optional Extended Regression

`./verify.sh` still runs the Harmonious parity/proof/regression surfaces when `/Users/bermi/code/libmusictheory/tmp/harmoniousapp.net` exists locally.

Those checks remain valuable, but they are intentionally outside the canonical standalone release smoke path.
