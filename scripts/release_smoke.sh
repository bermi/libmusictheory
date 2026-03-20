#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "missing required command: $1" >&2
        exit 1
    fi
}

assert_file() {
    if [ ! -f "$1" ]; then
        echo "missing required file: $1" >&2
        exit 1
    fi
}

find_static_lib() {
    local candidate
    for candidate in \
        "zig-out/lib/libmusictheory.a" \
        "zig-out/lib/musictheory.lib"
    do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

find_shared_lib() {
    local candidate
    for candidate in \
        "zig-out/lib/libmusictheory.dylib" \
        "zig-out/lib/libmusictheory.so" \
        "zig-out/lib/musictheory.dll"
    do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

require_cmd zig
require_cmd node
require_cmd npm
require_cmd python3

zig build >/dev/null

assert_file "zig-out/include/libmusictheory.h"
assert_file "zig-out/include/libmusictheory_compat.h"
STATIC_LIB_PATH="$(find_static_lib)" || {
    echo "missing static library in zig-out/lib" >&2
    exit 1
}
SHARED_LIB_PATH="$(find_shared_lib)" || {
    echo "missing shared library in zig-out/lib" >&2
    exit 1
}

zig build c-smoke >/dev/null

zig build wasm-docs >/dev/null
assert_file "zig-out/wasm-docs/index.html"
assert_file "zig-out/wasm-docs/libmusictheory.wasm"
assert_file "zig-out/wasm-docs/app.js"
assert_file "zig-out/wasm-docs/styles.css"
node scripts/check_wasm_exports.mjs --profile full_demo --wasm zig-out/wasm-docs/libmusictheory.wasm >/dev/null
node scripts/validate_wasm_docs_playwright.mjs >/dev/null

zig build wasm-gallery >/dev/null
assert_file "zig-out/wasm-gallery/index.html"
assert_file "zig-out/wasm-gallery/libmusictheory.wasm"
assert_file "zig-out/wasm-gallery/gallery.js"
assert_file "zig-out/wasm-gallery/styles.css"
node scripts/check_wasm_exports.mjs --profile gallery --wasm zig-out/wasm-gallery/libmusictheory.wasm >/dev/null
node scripts/validate_wasm_gallery_playwright.mjs >/dev/null

printf 'release smoke passed: version=%s static=%s shared=%s browser=wasm-docs,wasm-gallery\n' \
    "$(cat VERSION)" \
    "$STATIC_LIB_PATH" \
    "$SHARED_LIB_PATH"
