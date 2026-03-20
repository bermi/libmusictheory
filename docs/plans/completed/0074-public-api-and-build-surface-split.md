# 0074 — Public API And Build Surface Split

> Dependencies: 0073, 0020, 0050, 0063

Status: Completed

## Summary

Separate the standalone library release surface from the Harmonious verification and compatibility surface.

Today, `/Users/bermi/code/libmusictheory/include/libmusictheory.h` and `/Users/bermi/code/libmusictheory/build.zig` still present a mixed identity: public theory/rendering APIs are interleaved with exact-compatibility, scaled-render-parity/native-proof verification APIs, and Harmonious SPA support. This plan makes the standalone surface explicit.

## Goals

- Keep `/Users/bermi/code/libmusictheory/include/libmusictheory.h` focused on stable standalone APIs.
- Move Harmonious-specific compatibility and proof APIs behind a separate header or internal install surface.
- Reclassify build targets into:
  - public/standalone
  - internal verification/demo
- Ensure public install flows do not require `tmp/harmoniousapp.net/`.

## Scope

- header split or equivalent public/private surface split
- install artifact review
- build target naming review
- standalone-vs-internal documentation in build/help text

## Non-Goals

- No deletion of internal verification APIs
- No algorithm changes purely for release packaging
- No production-hosting work

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must gain checks that the installed public header does not accidentally expose Harmonious-only APIs
- `./verify.sh` must gain checks that public bundle/documentation references do not require local Harmonious data

## Exit Criteria

- public header/install surface is standalone-focused
- Harmonious compat/proof APIs are clearly separated from the default installed surface
- public build targets are clearly distinguished from internal verification targets
- public install/docs flows work without `tmp/harmoniousapp.net/`
- `./verify.sh` passes

## Completion Status

- Completed and verified:
  - `/Users/bermi/code/libmusictheory/include/libmusictheory.h` now exposes the standalone-facing theory/rendering C ABI without Harmonious compat/proof declarations
  - Harmonious compatibility, proof, and wasm scratch entry points now live in `/Users/bermi/code/libmusictheory/include/libmusictheory_compat.h`
  - `/Users/bermi/code/libmusictheory/build.zig` now installs the separate compat header and labels `wasm-demo`, `wasm-scaled-render-parity`, `wasm-native-rgba-proof`, and `wasm-harmonious-spa` as internal verification bundles, while `wasm-docs` is labeled as the standalone interactive docs bundle
  - native C smoke coverage now exercises the separated compat header through `/Users/bermi/code/libmusictheory/examples/c/compat_smoke.c`
  - `/Users/bermi/code/libmusictheory/examples/wasm-demo/README.md` now explicitly distinguishes the public docs bundle from the internal verification bundles

## Implementation History (Point-in-Time)

- Commit: `f7dd375f0ca7fe046e553491a6c060378805a001`
- Date: `2026-03-20`
- Shipped behavior:
  - split the installed C header surface into standalone vs compatibility/proof concerns
  - added dedicated compat-header compile coverage in the C smoke path and Zig `@cImport` path
  - clarified build-target intent so the standalone docs surface is distinct from internal verification bundles
- Verification commands:
  - `./verify.sh`
  - `zig build verify`
