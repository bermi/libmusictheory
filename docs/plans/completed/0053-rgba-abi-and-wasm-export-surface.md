# 0053 — RGBA ABI And WASM Export Surface

> Dependencies: 0052

Status: Completed

## Objective

Expose direct RGBA rendering from Zig/WASM for proof-mode consumers using caller-owned memory and explicit capability reporting.

## Exit Criteria

- Native and wasm-facing exports expose proof scale, support status, target size, required RGBA bytes, candidate RGBA rendering, and reference SVG RGBA rendering.
- The proof wasm bundle has an explicit export contract enforced by verification.
- Focused tests cover deterministic RGBA output for the first supported family.

## Verification Commands

- `./verify.sh`
- `zig build test`
- `zig build wasm-bitmap-proof`
- `node scripts/check_wasm_exports.mjs --profile bitmap_proof --wasm zig-out/wasm-bitmap-proof/libmusictheory.wasm`

## Implementation History (Point-in-Time)

- `TBD` (`2026-03-14`)
- Shipped behavior:
- Added the proof RGBA ABI to `/Users/bermi/code/libmusictheory/include/libmusictheory.h` and `/Users/bermi/code/libmusictheory/src/c_api.zig`.
- Added the proof-focused wasm root in `/Users/bermi/code/libmusictheory/src/wasm_bitmap_proof_api.zig`.
- Added the first proof rendering module in `/Users/bermi/code/libmusictheory/src/bitmap_compat.zig`, including deterministic candidate RGBA output and reference SVG RGBA parsing for `opc`.
- Added bitmap-proof export validation in `/Users/bermi/code/libmusictheory/scripts/check_wasm_exports.mjs` and `/Users/bermi/code/libmusictheory/verify.sh`.
- Guardrail/completion verification:
- `./verify.sh`
- `zig build test`
- `zig build wasm-bitmap-proof`
- `node scripts/check_wasm_exports.mjs --profile bitmap_proof --wasm zig-out/wasm-bitmap-proof/libmusictheory.wasm`
