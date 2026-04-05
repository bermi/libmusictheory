# Release Checklist

Target release candidate: `0.1.0-rc.1`

## Preconditions

- `./verify.sh` passes
- `scripts/release_smoke.sh` passes
- working tree is clean
- release branch is merged or ready to merge
- `docs/release/stability-matrix.md` has been reread so the reviewer path matches the real stable / experimental / internal split

## Versioning

- update `VERSION`
- review `docs/release/versioning.md`
- add a changelog entry in `CHANGELOG.md`
- confirm `VERSION` is the intended `-rc.N` target and not a `-dev` placeholder

## Native Surface

- run `./zigw build`
- run `./zigw build c-smoke`
- confirm `zig-out/include/libmusictheory.h` exists
- confirm `zig-out/lib` contains the native library artifacts

## Browser Surface

- run `./zigw build wasm-docs`
- run `./zigw build wasm-gallery`
- run `node scripts/check_wasm_exports.mjs --profile full_demo --wasm zig-out/wasm-docs/libmusictheory.wasm`
- run `node scripts/check_wasm_exports.mjs --profile gallery --wasm zig-out/wasm-gallery/libmusictheory.wasm`
- run `node scripts/validate_wasm_docs_playwright.mjs`
- run `node scripts/validate_wasm_gallery_playwright.mjs`

## Example Boundary

- confirm the stable browser contract demonstration is `wasm-docs`
- confirm the gallery is described as a supported standalone example surface, not the stable embedding contract
- confirm experimental helpers remain explicitly marked experimental in `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, `/Users/bermi/code/libmusictheory/README.md`, and `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`
- confirm quickstart commands in `README.md`, `RELEASE_CHECKLIST.md`, and `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md` all use the same `./zigw` command path

## Documentation

- review `README.md`
- review `docs/release/artifacts.md`
- review `docs/release/image-review-matrix.md`
- review `docs/release/reviewer-guide.md`
- review `docs/release/smoke-matrix.md`
- review `docs/release/stability-matrix.md`
- review `docs/release/versioning.md`

## Reviewer Evaluation

- hand the reviewer `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`
- confirm the reviewer path starts with `./verify.sh`, then `./scripts/release_smoke.sh`, then separate docs/gallery review
- confirm the reviewer path uses only `./zigw build`, `wasm-docs`, `wasm-gallery`, and release capture commands
- confirm no review step depends on local `tmp/harmoniousapp.net` data

## Internal Regression Status

- if `tmp/harmoniousapp.net` is present, confirm the extended regression lanes still pass
- confirm `NATIVE_RGBA_PROOF_COMPLETE=yes`

## Release Cut

- commit release metadata updates
- tag the release
- push branch and tag
