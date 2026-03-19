# 0076 — Root README And Stable API Contract

> Dependencies: 0073, 0074

Status: Draft

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

