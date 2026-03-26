#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
ZIG_CMD="$ROOT_DIR/zigw"

step() {
    echo "[release-smoke] $1"
}

step "zig build"
"$ZIG_CMD" build

step "zig build c-smoke"
"$ZIG_CMD" build c-smoke

step "zig build wasm-docs"
"$ZIG_CMD" build wasm-docs

step "docs wasm export profile"
node scripts/check_wasm_exports.mjs --profile full_demo --wasm zig-out/wasm-docs/libmusictheory.wasm

step "docs playwright smoke"
node scripts/validate_wasm_docs_playwright.mjs

step "zig build wasm-gallery"
"$ZIG_CMD" build wasm-gallery

step "gallery wasm export profile"
node scripts/check_wasm_exports.mjs --profile gallery --wasm zig-out/wasm-gallery/libmusictheory.wasm

step "gallery playwright smoke"
node scripts/validate_wasm_gallery_playwright.mjs

step "gallery screenshot capture"
node scripts/capture_wasm_gallery_screenshots.mjs

echo "RELEASE_SMOKE=yes"
