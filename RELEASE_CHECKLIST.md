# Release Checklist

## Preconditions

- `./verify.sh` passes
- `scripts/release_smoke.sh` passes
- working tree is clean
- release branch is merged or ready to merge

## Versioning

- update `VERSION`
- review `docs/release/versioning.md`
- add a changelog entry in `CHANGELOG.md`

## Native Surface

- run `zig build`
- run `zig build c-smoke`
- confirm `zig-out/include/libmusictheory.h` exists
- confirm `zig-out/lib` contains the native library artifacts

## Browser Surface

- run `zig build wasm-docs`
- run `zig build wasm-gallery`
- run `node scripts/check_wasm_exports.mjs --profile full_demo --wasm zig-out/wasm-docs/libmusictheory.wasm`
- run `node scripts/check_wasm_exports.mjs --profile gallery --wasm zig-out/wasm-gallery/libmusictheory.wasm`
- run `node scripts/validate_wasm_docs_playwright.mjs`
- run `node scripts/validate_wasm_gallery_playwright.mjs`

## Documentation

- review `README.md`
- review `docs/release/artifacts.md`
- review `docs/release/smoke-matrix.md`
- review `docs/release/versioning.md`

## Internal Regression Status

- if `tmp/harmoniousapp.net` is present, confirm the extended regression lanes still pass
- confirm `NATIVE_RGBA_PROOF_COMPLETE=yes`

## Release Cut

- commit release metadata updates
- tag the release
- push branch and tag
