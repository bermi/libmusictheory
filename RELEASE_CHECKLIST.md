# Release Checklist

Target release candidate: `0.1.0-rc.1`

## Preconditions

- `./verify.sh` passes
- `scripts/release_smoke.sh` passes
- working tree is clean
- release branch is merged or ready to merge

## Versioning

- update `VERSION`
- review `docs/release/versioning.md`
- add a changelog entry in `CHANGELOG.md`
- confirm `VERSION` is the intended `-rc.N` target and not a `-dev` placeholder

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
- review `docs/release/reviewer-guide.md`
- review `docs/release/smoke-matrix.md`
- review `docs/release/versioning.md`

## Reviewer Evaluation

- hand the reviewer `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`
- confirm the reviewer path uses only `zig build`, `wasm-docs`, `wasm-gallery`, and release capture commands
- confirm no review step depends on local `tmp/harmoniousapp.net` data

## Internal Regression Status

- if `tmp/harmoniousapp.net` is present, confirm the extended regression lanes still pass
- confirm `NATIVE_RGBA_PROOF_COMPLETE=yes`

## Release Cut

- commit release metadata updates
- tag the release
- push branch and tag
