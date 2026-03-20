# Release Checklist

## Scope Freeze

- [ ] Public C ABI changes are reviewed against `/Users/bermi/code/libmusictheory/include/libmusictheory.h`.
- [ ] Experimental and internal surfaces are still documented honestly.
- [ ] The gallery and docs bundles still use only the intended public surface.

## Verification

- [ ] `bash scripts/release_smoke.sh`
- [ ] `./verify.sh`
- [ ] Any intentionally skipped optional regression lanes are called out in release notes.

## Artifacts

- [ ] `zig build` produced headers in `zig-out/include`.
- [ ] `zig build` produced static/shared libraries in `zig-out/lib`.
- [ ] `zig build wasm-docs` produced a working docs bundle.
- [ ] `zig build wasm-gallery` produced a working gallery bundle.

## Versioning And Notes

- [ ] `VERSION` is updated to the release version.
- [ ] `CHANGELOG.md` moves the relevant entries out of `Unreleased`.
- [ ] Release notes summarize public API and bundle changes only.

## Tagging

- [ ] The release commit is tagged as `vMAJOR.MINOR.PATCH`.
- [ ] The release branch or merge target is recorded.
- [ ] Post-release follow-up work returns to `Unreleased`.
