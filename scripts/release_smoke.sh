#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

step() {
    echo "[release-smoke] $1"
}

step "zig build"
zig build

step "zig build c-smoke"
zig build c-smoke

step "zig build wasm-docs"
zig build wasm-docs

step "docs wasm export profile"
node scripts/check_wasm_exports.mjs --profile full_demo --wasm zig-out/wasm-docs/libmusictheory.wasm

step "docs playwright smoke"
node scripts/validate_wasm_docs_playwright.mjs

step "zig build wasm-gallery"
zig build wasm-gallery

step "gallery wasm export profile"
node scripts/check_wasm_exports.mjs --profile gallery --wasm zig-out/wasm-gallery/libmusictheory.wasm

step "gallery playwright smoke"
node scripts/validate_wasm_gallery_playwright.mjs

echo "RELEASE_SMOKE=yes"
