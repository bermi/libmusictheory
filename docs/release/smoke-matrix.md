# Release Smoke Matrix

The standalone release smoke path verifies the public library surface without depending on local Harmonious reference data.

| Surface | Command | Expected Result |
| --- | --- | --- |
| Native build | `zig build` | native headers and libraries install to `zig-out/` |
| Public C ABI smoke | `zig build c-smoke` | C smoke binaries pass |
| Standalone docs bundle | `zig build wasm-docs` | docs bundle installs to `zig-out/wasm-docs` |
| Docs export profile | `node scripts/check_wasm_exports.mjs --profile full_demo --wasm zig-out/wasm-docs/libmusictheory.wasm` | required docs wasm exports present |
| Docs browser smoke | `node scripts/validate_wasm_docs_playwright.mjs` | interactive docs render successfully |
| Standalone gallery bundle | `zig build wasm-gallery` | gallery bundle installs to `zig-out/wasm-gallery` |
| Gallery export profile | `node scripts/check_wasm_exports.mjs --profile gallery --wasm zig-out/wasm-gallery/libmusictheory.wasm` | required gallery wasm exports present |
| Gallery browser smoke | `node scripts/validate_wasm_gallery_playwright.mjs` | gallery scenes render successfully |
| Gallery screenshot capture | `node scripts/capture_wasm_gallery_screenshots.mjs` | release-candidate screenshots and `captures.json` regenerate successfully |

## Summary Signal

`scripts/release_smoke.sh` is the executable form of this matrix.

`./verify.sh` must report:

- `RELEASE_SURFACE_SMOKE=yes` when the matrix passes
- `HARMONIOUS_EXTENDED_REGRESSION=enabled|skipped` separately
- `NATIVE_RGBA_PROOF_COMPLETE=yes|no` separately
