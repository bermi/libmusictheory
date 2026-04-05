# Versioning

`libmusictheory` uses Semantic Versioning for the standalone public surface.

## Stable Contract Boundary

Version compatibility is defined by:

- `include/libmusictheory.h`
- the documented memory/lifetime rules in `README.md`
- `docs/release/stability-matrix.md`
- the public standalone bundles:
  - `wasm-docs`

The gallery bundle is a supported standalone example and review artifact, but it is not by itself the stable embedding contract when it exercises experimental helpers.

It is not defined by:

- `include/libmusictheory_compat.h`
- Harmonious parity/proof bundles
- internal Zig namespaces used only for verification

## Version File

`VERSION` stores the current release target for the standalone library.

Allowed forms:

- stable release: `MAJOR.MINOR.PATCH`
- pre-release build: `MAJOR.MINOR.PATCH-label.N`

Current policy:

- breaking changes to the stable C ABI require a major-version bump
- additive stable API changes require a minor-version bump
- bug fixes and internal-only changes require a patch-version bump
- purely internal Harmonious regression work does not require a public version bump unless it changes the standalone contract or release artifacts

Current release-candidate target:

- `0.1.0-rc.1`
