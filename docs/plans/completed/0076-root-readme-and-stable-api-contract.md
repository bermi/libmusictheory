# 0076 — Root README And Stable API Contract

> Dependencies: 0073, 0074

Status: Completed

## Summary

Add the first real library-facing entry point for `libmusictheory` and document the stable API contract that external developers are expected to depend on.

There is currently no root `/Users/bermi/code/libmusictheory/README.md`. The repo has deep technical documentation and browser-bundle notes, but not a release-quality explanation of what the library is and how to use it safely.

## Goals

- Add a root `README.md`.
- Define the stable public API surface.
- Document ownership, scratch-buffer, and return-value/error semantics.
- Provide minimal quickstarts for:
  - C ABI
  - Zig
  - WASM/browser

## Scope

- root README
- stable/experimental/internal API classification
- memory/lifetime contract documentation
- minimal code examples
- link map into deeper docs and research

## Non-Goals

- No tutorial sprawl
- No gallery implementation
- No compatibility-plan history dump in the root README

## Verification-First Guardrails

Before implementation:

- `./verify.sh` must check for the presence of a root `README.md`
- `./verify.sh` must check for a stable API contract section and standalone quickstart references

## Exit Criteria

- root `README.md` exists and is library-facing
- stable/experimental/internal API boundaries are documented
- memory and lifetime rules are documented
- quickstart examples exist for native and browser usage
- `./verify.sh` passes

## Completion Status

- Completed and verified:
  - `/Users/bermi/code/libmusictheory/README.md` now exists as the library-facing entry point with explicit public/internal surface classification
  - the root README now documents the stable API contract, return-value conventions, and memory/lifetime ownership rules
  - the root README now includes quickstarts for C ABI, Zig source-based module usage, and the standalone browser/WASM docs bundle
  - `/Users/bermi/code/libmusictheory/include/libmusictheory.h` now documents the stable public C ABI, caller-owned buffer expectations, string lifetime rules, and the experimental/internal surface split

## Implementation History (Point-in-Time)

- Commit: `<pending>`
- Date: `2026-03-20`
- Shipped behavior:
  - added the first root README for standalone consumers instead of forcing them through Harmonious verification docs
  - documented stable, experimental, and internal surfaces in both the root README and the public C header
  - documented caller-owned buffer rules, string lifetime constraints, and the current browser/WASM entry point
- Verification commands:
  - `./verify.sh`
  - `zig build verify`
