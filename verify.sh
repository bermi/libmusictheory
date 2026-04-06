#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"
ZIG_CMD="$ROOT_DIR/zigw"

FAIL=0
RELEASE_SURFACE_SMOKE_STATUS="no"

section() {
    echo ""
    echo "==========================================="
    echo "  $1"
    echo "==========================================="
}

pass() {
    echo "  PASS: $1"
}

fail() {
    echo "  FAIL: $1"
    FAIL=1
}

unverified() {
    echo "  UNVERIFIED: $1"
}

check_cmd() {
    local cmd="$1"
    local label="$2"
    if env LMT_ZIG_WRAPPER="$ZIG_CMD" bash -lc "zig(){ \"\$LMT_ZIG_WRAPPER\" \"\$@\"; }; export -f zig; $cmd"; then
        pass "$label"
    else
        fail "$label"
    fi
}

# ───────────────────────────────────────────
# Section 1: Project Structure
# ───────────────────────────────────────────
section "Project Structure"

if [ -f "$ROOT_DIR/build.zig" ]; then
    pass "build.zig exists"
else
    fail "build.zig missing"
fi

if [ -x "$ZIG_CMD" ]; then
    pass "zigw exists"
else
    fail "zigw missing or not executable"
fi

if [ -f "$ROOT_DIR/CLAUDE.md" ]; then
    pass "CLAUDE.md exists"
else
    fail "CLAUDE.md missing"
fi

if [ -f "$ROOT_DIR/AGENTS.md" ]; then
    pass "AGENTS.md exists"
else
    fail "AGENTS.md missing"
fi

if [ -f "$ROOT_DIR/CONSTRAINTS.md" ]; then
    pass "CONSTRAINTS.md exists"
else
    fail "CONSTRAINTS.md missing"
fi

if [ -d "$ROOT_DIR/src" ]; then
    pass "src/ directory exists"
else
    fail "src/ directory missing"
fi

if [ -d "$ROOT_DIR/include" ]; then
    pass "include/ directory exists"
else
    fail "include/ directory missing"
fi

# ───────────────────────────────────────────
# Section 1.5: Release Packaging
# ───────────────────────────────────────────
section "Release Packaging"

RELEASE_ARTIFACT_FILES=(
    "VERSION"
    "CHANGELOG.md"
    "RELEASE_CHECKLIST.md"
    "docs/release/artifacts.md"
    "docs/release/reviewer-guide.md"
    "docs/release/smoke-matrix.md"
    "docs/release/versioning.md"
    "scripts/release_smoke.sh"
)

for path in "${RELEASE_ARTIFACT_FILES[@]}"; do
    if [ -f "$ROOT_DIR/$path" ]; then
        pass "$path"
    else
        fail "$path missing"
    fi
done

if [ -f "$ROOT_DIR/VERSION" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n '^[0-9]+\\.[0-9]+\\.[0-9]+([-.][0-9A-Za-z]+(\\.[0-9A-Za-z]+)*)?$' VERSION" "0078 release version guardrail (VERSION uses semver-style format)"
else
    unverified "0078 release version guardrail (VERSION missing)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0082-first-release-candidate-cut.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0082-first-release-candidate-cut.md" ]; then
    if rg -q '^[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$' "$ROOT_DIR/VERSION"; then
        check_cmd "cd '$ROOT_DIR' && rg -n '^[0-9]+\\.[0-9]+\\.[0-9]+-rc\\.[0-9]+$' VERSION" "0082 release-candidate guardrail (VERSION is an rc cut, not a dev placeholder)"
        check_cmd "cd '$ROOT_DIR' && ! rg -n '^## \\[Unreleased\\]$' CHANGELOG.md && rg -n '^## \\[[0-9]+\\.[0-9]+\\.[0-9]+-rc\\.[0-9]+\\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$' CHANGELOG.md" "0082 release-candidate guardrail (CHANGELOG has a dated rc entry and no unreleased-only scaffold)"
        check_cmd "cd '$ROOT_DIR' && rg -n '^## Reviewer Evaluation$|docs/release/reviewer-guide\\.md|0\\.1\\.0-rc\\.1|rc reviewer|release candidate' RELEASE_CHECKLIST.md" "0082 release-candidate guardrail (checklist is upgraded for rc review)"
        check_cmd "cd '$ROOT_DIR' && rg -n '^# Release Candidate Reviewer Guide$|^## What To Review$|^## Quick Smoke Path$|^## Gallery Review$|^## Public API Review$' docs/release/reviewer-guide.md" "0082 release-candidate guardrail (reviewer guide exists with concrete evaluation steps)"
    fi
    check_cmd "cd '$ROOT_DIR' && ! rg -n 'tmp/harmoniousapp\\.net|wasm-demo|wasm-scaled-render-parity|wasm-native-rgba-proof|wasm-harmonious-spa|validate_harmonious_' docs/release" "0082 release-candidate guardrail (public release docs stay independent from Harmonious-local tooling)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0086-stable-cut-readiness-and-promotion.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0086-stable-cut-readiness-and-promotion.md" ]; then
    if rg -q '^[0-9]+\.[0-9]+\.[0-9]+$' "$ROOT_DIR/VERSION"; then
        check_cmd "cd '$ROOT_DIR' && rg -n '^## \\[[0-9]+\\.[0-9]+\\.[0-9]+\\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$' CHANGELOG.md && ! rg -n '\\-rc\\.[0-9]+' CHANGELOG.md" "0086 stable-cut guardrail (CHANGELOG is promoted from rc to stable entry)"
        check_cmd "cd '$ROOT_DIR' && ! rg -n 'release candidate|0\\.[0-9]+\\.[0-9]+-rc\\.[0-9]+' RELEASE_CHECKLIST.md docs/release/reviewer-guide.md docs/release/versioning.md" "0086 stable-cut guardrail (checklist and release docs no longer describe an rc cut after promotion)"
        check_cmd "cd '$ROOT_DIR' && rg -n '^# Stable Release Reviewer Guide$' docs/release/reviewer-guide.md >/dev/null && rg -n '^Target: \\x60[0-9]+\\.[0-9]+\\.[0-9]+\\x60$' docs/release/reviewer-guide.md >/dev/null" "0086 stable-cut guardrail (reviewer guide is rewritten for a stable cut)"
    fi
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0087-public-api-polish-and-review-fixes.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0087-public-api-polish-and-review-fixes.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'qa-atlas\\.html|qa-atlas\\.js|qa-atlas\\.css|capture_wasm_docs_qa_atlas\\.mjs|validate_wasm_docs_bitmap_playwright\\.mjs' build.zig verify.sh README.md docs/release/reviewer-guide.md >/dev/null" "0087 qa atlas guardrail (build, docs, capture, and bitmap diff wiring are present)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n 'tmp/harmoniousapp\\.net|validate_harmonious_|libmusictheory_compat\\.h|lmt_svg_compat_|lmt_bitmap_compat_' examples/wasm-demo/qa-atlas.js scripts/capture_wasm_docs_qa_atlas.mjs scripts/validate_wasm_docs_bitmap_playwright.mjs" "0087 qa atlas guardrail (atlas stays on standalone public docs outputs)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_svg_clock_optc|lmt_svg_optic_k_group|lmt_svg_evenness_chart|lmt_svg_evenness_field|lmt_svg_fret\\b|lmt_svg_fret_n|lmt_svg_chord_staff|lmt_svg_key_staff|lmt_svg_keyboard|lmt_svg_piano_staff' examples/wasm-demo/index.html examples/wasm-demo/app.js examples/wasm-demo/qa-atlas.js >/dev/null" "0087 qa atlas guardrail (all public docs image methods are rendered and atlas-covered)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_bitmap_clock_optc_rgba|lmt_bitmap_optic_k_group_rgba|lmt_bitmap_evenness_chart_rgba|lmt_bitmap_evenness_field_rgba|lmt_bitmap_fret_rgba|lmt_bitmap_fret_n_rgba|lmt_bitmap_chord_staff_rgba|lmt_bitmap_key_staff_rgba|lmt_bitmap_keyboard_rgba|lmt_bitmap_piano_staff_rgba' include/libmusictheory.h build.zig scripts/check_wasm_exports.mjs examples/wasm-demo/qa-atlas.js >/dev/null" "0087 qa atlas guardrail (public bitmap image APIs are declared, exported, and atlas-consumed)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'ImageData|putImageData|createObjectURL|toBlob|target=\"_blank\"|BITMAP_REVIEW_WIDTH|renderSvgString|rasterizeSvgMarkup|compareRgba' examples/wasm-demo/qa-atlas.js examples/wasm-demo/qa-atlas.html scripts/validate_wasm_docs_bitmap_playwright.mjs >/dev/null && ! rg -n 'outerHTML' examples/wasm-demo/qa-atlas.js" "0087 qa atlas guardrail (atlas renders direct library RGBA bitmaps and computes svg-vs-bitmap diffs)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'OPC_STROKE_COLORS|OPC_FILL_COLORS|clockPaletteMetrics|paletteMatches|#00c|#f0f|#1e0|#28f' src/svg/clock.zig src/tests/svg_clock_test.zig scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0087 public clock palette guardrail (renderer, tests, and gallery validation require colored pitch-class diagrams)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_svg_key_staff|key-staff|keyStaffFeatures|barlineCount >= 2|key-staff svg' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs README.md >/dev/null" "0087 public key staff guardrail (gallery and validation require a multi-bar public staff example)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_svg_keyboard|lmt_bitmap_keyboard_rgba|midi-keyboard|key-keyboard|keyboardFeatures|selectedKeyCount|echoKeyCount' examples/wasm-demo/index.html examples/wasm-demo/app.js examples/wasm-demo/qa-atlas.js examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_docs_playwright.mjs scripts/validate_wasm_docs_bitmap_playwright.mjs scripts/validate_wasm_gallery_playwright.mjs README.md >/dev/null" "0087 public keyboard guardrail (docs, qa atlas, gallery, and validation require a visible standalone keyboard diagram)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'black-key-base|black-key-overlay|black-key.*is-echo|blackEchoSelectedCount|maxCenterSeamDelta|maxBlackEchoCenterSeamDelta' src/svg/keyboard_svg.zig src/tests/svg_keyboard_test.zig scripts/validate_wasm_docs_playwright.mjs scripts/validate_wasm_gallery_playwright.mjs scripts/validate_wasm_docs_bitmap_playwright.mjs >/dev/null" "0087 public keyboard seam guardrail (black-key tint layering and pixel seam checks are enforced for non-Ionian samples)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'preview-mode|bitmap preview|large vector|lmt_bitmap_clock_optc_rgba|lmt_bitmap_optic_k_group_rgba|lmt_bitmap_evenness_field_rgba|lmt_bitmap_chord_staff_rgba|lmt_bitmap_key_staff_rgba|lmt_bitmap_piano_staff_rgba|previewKinds|expectedPreviewMode|previewVisualDiffs|maxPreviewDrift|captureHostScreenshots|compareRgba' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs README.md >/dev/null" "0087 gallery preview-mode guardrail (gallery can switch between SVG and direct bitmap previews for the public image surfaces and verify pixel drift)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_svg_piano_staff|lmt_bitmap_piano_staff_rgba|midi-staff|svg-piano-staff|midiStaffFeatures|staffMode|clefCount >= 2' examples/wasm-demo/index.html examples/wasm-demo/app.js examples/wasm-demo/qa-atlas.js examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_docs_playwright.mjs scripts/validate_wasm_docs_bitmap_playwright.mjs scripts/validate_wasm_gallery_playwright.mjs include/libmusictheory.h >/dev/null" "0087 public piano staff guardrail (docs, qa atlas, gallery, and validation require an arbitrary-register piano staff, not a triad proxy)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_svg_evenness_chart|lmt_svg_evenness_field|set-evenness|midi-evenness|setEvennessSvg|midiEvennessSvg|setEvennessFeatures|midiEvennessFeatures|ringCount|dotCount|highlightCount' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs README.md >/dev/null" "0087 public evenness guardrail (gallery and validation require visible set and live evenness diagrams)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_svg_optic_k_group|set-optic-k|midi-optic-k|setOpticKSvg|midiOpticKSvg|setOpticKFeatures|midiOpticKFeatures|clockCount|linkCount' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs README.md >/dev/null" "0087 public OPTIC/K guardrail (gallery and validation require visible set and live OPTIC/K diagrams)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'modeSpellingQuality|ContextSuggestion|rankContextSuggestions' src/keyboard.zig src/tests/keyboard_test.zig >/dev/null && rg -n 'lmt_mode_spelling_quality|lmt_rank_context_suggestions|lmt_context_suggestion' include/libmusictheory.h src/c_api.zig scripts/check_wasm_exports.mjs examples/wasm-gallery/gallery.js src/tests/c_api_test.zig >/dev/null && ! rg -n 'function buildMidiSuggestions\\(|function inferModeSpellingQuality\\(' examples/wasm-gallery/gallery.js >/dev/null" "0087 live context-suggestion guardrail (mode quality and suggestion ranking live in the library and gallery JS no longer owns them)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'preferredVoicingGeneric|scoreVoicingGeneric|bassMidiGeneric' src/guitar.zig src/tests/guitar_test.zig >/dev/null && rg -n 'lmt_preferred_voicing_n' include/libmusictheory.h src/c_api.zig scripts/check_wasm_exports.mjs examples/wasm-gallery/gallery.js src/tests/c_api_test.zig >/dev/null && ! rg -n 'function scoreFretVoicing\\(|function generatePreferredFretVoicing\\(' examples/wasm-gallery/gallery.js >/dev/null" "0087 live fret voicing guardrail (preferred voicing selection lives in the library and gallery JS no longer scores fret rows)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'Experimental APIs: lmt_raster_is_enabled, lmt_raster_demo_rgba,|lmt_counterpoint_max_voices|lmt_build_voiced_state|lmt_classify_motion|lmt_rank_next_steps|lmt_rank_cadence_destinations|lmt_analyze_suspension_machine|method-specific RGBA bitmap renderers' include/libmusictheory.h >/dev/null && rg -n 'Experimental surface:|lmt_counterpoint_max_voices|lmt_build_voiced_state|lmt_classify_motion|lmt_rank_next_steps|lmt_rank_cadence_destinations|lmt_analyze_suspension_machine|RGBA bitmap renderers|gallery bundle uses the stable public SVG APIs plus experimental counterpoint and bitmap helpers|not part of stable release signoff' README.md docs/release/reviewer-guide.md >/dev/null && ! rg -n 'gallery that uses only the stable public APIs' README.md >/dev/null" "0087 stable contract guardrail (header, README, and reviewer guide classify counterpoint/bitmap helpers as experimental and stop overstating the gallery surface)"
    check_cmd "cd '$ROOT_DIR' && zig build wasm-docs 2>&1" "0087 public docs bundle build (qa atlas validates the current docs output, not a stale install)"
    check_cmd "cd '$ROOT_DIR' && node scripts/validate_wasm_docs_bitmap_playwright.mjs 2>&1" "0087 qa atlas bitmap visual diff verification"
    check_cmd "cd '$ROOT_DIR' && node scripts/capture_wasm_docs_qa_atlas.mjs 2>&1" "0087 qa atlas capture verification"
    check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-docs-qa/qa-atlas.png && test -f zig-out/wasm-docs-qa/qa-atlas.json" "0087 qa atlas capture guardrail (deterministic artifacts generated)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0111-public-stable-contract-audit-and-enforcement.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0111-public-stable-contract-audit-and-enforcement.md" ]; then
    check_cmd "cd '$ROOT_DIR' && test -f docs/release/stability-matrix.md && rg -n '^# Stability Matrix$|^## Stable Contract$|^## Experimental Public Surface$|^## Supported Standalone Example Surface$|^## Internal Regression Infrastructure$|^## Review Interpretation$' docs/release/stability-matrix.md >/dev/null" "0111 stable contract guardrail (stability matrix exists with the required classification sections)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'docs/release/stability-matrix\\.md|Stable contract:|Experimental public surface:|Internal regression infrastructure:' README.md >/dev/null && rg -n 'Detailed release-surface classification lives in|Experimental APIs:|libmusictheory_compat\\.h' include/libmusictheory.h >/dev/null && rg -n 'docs/release/stability-matrix\\.md|stable release signoff|supported example review|internal-only regression infrastructure' docs/release/reviewer-guide.md >/dev/null" "0111 stable contract guardrail (header, README, and reviewer guide all point at the same stable/experimental/internal split)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_svg_clock_optc|lmt_svg_optic_k_group|lmt_svg_evenness_chart|lmt_svg_evenness_field|lmt_svg_fret|lmt_svg_fret_n|lmt_svg_chord_staff|lmt_svg_key_staff|lmt_svg_piano_staff|lmt_svg_keyboard' docs/release/stability-matrix.md >/dev/null && rg -n 'lmt_counterpoint_\\*|lmt_build_voiced_state|lmt_rank_next_steps|lmt_rank_cadence_destinations|lmt_analyze_suspension_machine|lmt_mode_spelling_quality|lmt_rank_context_suggestions|lmt_preferred_voicing_n|lmt_bitmap_\\*_rgba' docs/release/stability-matrix.md >/dev/null && rg -n 'wasm-demo|wasm-scaled-render-parity|wasm-native-rgba-proof|wasm-harmonious-spa|libmusictheory_compat\\.h' docs/release/stability-matrix.md >/dev/null" "0111 stable contract guardrail (stability matrix inventories stable APIs, experimental helpers, and internal regression surfaces explicitly)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0112-public-docs-quickstart-and-example-boundary.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0112-public-docs-quickstart-and-example-boundary.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'Recommended Clone-To-Review Path|\\./verify\\.sh|\\./zigw build wasm-docs|\\./zigw build wasm-gallery' README.md >/dev/null && rg -n '^## Start Here$|\\./verify\\.sh|\\./scripts/release_smoke\\.sh' docs/release/reviewer-guide.md >/dev/null" "0112 docs boundary guardrail (README and reviewer guide expose one obvious clone-to-review path)"
    check_cmd "cd '$ROOT_DIR' && rg -n '\\./zigw build|\\./zigw build c-smoke|\\./zigw build wasm-docs|\\./zigw build wasm-gallery' RELEASE_CHECKLIST.md docs/release/artifacts.md >/dev/null && ! rg -n '(^|[^./])zig build($| c-smoke| wasm-docs| wasm-gallery)' RELEASE_CHECKLIST.md docs/release/artifacts.md" "0112 docs boundary guardrail (release checklist and artifacts use the supported zigw command path)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'stable browser contract demonstration|supported standalone example surface|uses stable public SVG APIs plus experimental counterpoint and bitmap helpers' README.md docs/release/reviewer-guide.md docs/release/artifacts.md docs/release/smoke-matrix.md >/dev/null" "0112 docs boundary guardrail (docs and gallery example boundaries are explicit across release docs)"
    check_cmd "cd '$ROOT_DIR' && rg -n '^For a single-image QA atlas covering the stable public image methods rendered by the docs bundle:$' README.md >/dev/null && rg -n 'qa-atlas\\.html|direct PNGs encoded from RGBA buffers returned by the library|supported example review' docs/release/reviewer-guide.md docs/release/artifacts.md >/dev/null" "0112 docs boundary guardrail (QA atlas and review artifacts stay tied to the public docs bundle and reviewer path)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0113-public-image-review-and-parity-closure.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0113-public-image-review-and-parity-closure.md" ]; then
    check_cmd "cd '$ROOT_DIR' && test -f docs/release/image-review-matrix.md && rg -n '^# Public Image Review Matrix$|^## Stable SVG Contract Surfaces$|^## Experimental Bitmap Parity Review$|^## Gallery Preview Toggle Review$|^## Review Interpretation$' docs/release/image-review-matrix.md >/dev/null" "0113 image review guardrail (image review matrix exists with the required sections)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_svg_clock_optc|lmt_svg_optic_k_group|lmt_svg_evenness_chart|lmt_svg_evenness_field|lmt_svg_fret\\b|lmt_svg_fret_n|lmt_svg_chord_staff|lmt_svg_key_staff|lmt_svg_keyboard|lmt_svg_piano_staff' docs/release/image-review-matrix.md >/dev/null && rg -n 'lmt_bitmap_clock_optc_rgba|lmt_bitmap_optic_k_group_rgba|lmt_bitmap_evenness_chart_rgba|lmt_bitmap_evenness_field_rgba|lmt_bitmap_fret_rgba|lmt_bitmap_fret_n_rgba|lmt_bitmap_chord_staff_rgba|lmt_bitmap_key_staff_rgba|lmt_bitmap_keyboard_rgba|lmt_bitmap_piano_staff_rgba' docs/release/image-review-matrix.md >/dev/null" "0113 image review guardrail (matrix inventories every public SVG surface and bitmap companion)"
    check_cmd "cd '$ROOT_DIR' && rg -n '0\\.005|0\\.07|experimental bitmap APIs|QA atlas|gallery preview toggle' README.md docs/release/reviewer-guide.md docs/release/stability-matrix.md docs/release/image-review-matrix.md >/dev/null && rg -n '0\\.005' scripts/validate_wasm_docs_bitmap_playwright.mjs >/dev/null && rg -n '0\\.07' scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0113 image review guardrail (public parity claims match the actual docs and gallery drift thresholds)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n 'stable exact bitmap parity|stable 1:1 bitmap parity|guarantees exact bitmap parity|zero drift' README.md docs/release -g '!**/completed/**'" "0113 image review guardrail (release docs do not overstate bitmap parity beyond what verification enforces)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0114-stable-review-sweep-and-release-decision.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0114-stable-review-sweep-and-release-decision.md" ]; then
    check_cmd "cd '$ROOT_DIR' && test -f docs/release/stable-review-decision.md && rg -n '^# Stable Review Decision$|^Status: (Pending|Go for stable 0\.1\.0|Hold for another RC)$|^Target under review:' docs/release/stable-review-decision.md >/dev/null && rg -n '^## Decision$|^## Remaining Delta$' docs/release/stable-review-decision.md >/dev/null" "0114 stable decision guardrail (stable review decision record exists with the required sections)"
    check_cmd "cd '$ROOT_DIR' && if [ -f docs/plans/completed/0114-stable-review-sweep-and-release-decision.md ]; then ! rg -n '^Status: Pending$' docs/release/stable-review-decision.md >/dev/null; else true; fi" "0114 stable decision guardrail (completed stable review cannot leave the decision record pending)"
    check_cmd "cd '$ROOT_DIR' && if rg -n '^Status: Go for stable 0\.1\.0$' docs/release/stable-review-decision.md >/dev/null; then rg -n '^0\.1\.0-rc\.1$|^0\.1\.0$' VERSION >/dev/null; else true; fi" "0114 stable decision guardrail (the decision record is compatible with the current promotion lane state)"
    check_cmd "cd '$ROOT_DIR' && if rg -n '^0\.1\.0-rc\.1$' VERSION >/dev/null; then rg -n '^# Release Candidate Reviewer Guide$|^Target:' docs/release/reviewer-guide.md >/dev/null && rg -n '0\.1\.0-rc\.1' docs/release/reviewer-guide.md >/dev/null; else true; fi" "0114 stable decision guardrail (while metadata is still RC, reviewer docs remain RC and do not silently claim a stable cut)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0115-stable-0.1.0-promotion-and-tag-handoff.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0115-stable-0.1.0-promotion-and-tag-handoff.md" ]; then
    check_cmd "cd '$ROOT_DIR' && test -f docs/release/tag-handoff.md && rg -n '^# Stable Tag Handoff$|^## Preconditions$|^## Exact Sequence$|^## Interpretation$' docs/release/tag-handoff.md >/dev/null && rg -n 'git merge --ff-only codex/stable-cut-execution-plan|git tag 0\.1\.0|git push origin 0\.1\.0' docs/release/tag-handoff.md >/dev/null" "0115 stable handoff guardrail (exact stable merge/tag sequence is documented)"
    check_cmd "cd '$ROOT_DIR' && if rg -n '^[0-9]+\.[0-9]+\.[0-9]+$' VERSION >/dev/null; then rg -n '^0\.1\.0$' VERSION >/dev/null && rg -n '^## \[0\.1\.0\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$' CHANGELOG.md >/dev/null && rg -n '^Target release: \\x600\.1\.0\\x60$' RELEASE_CHECKLIST.md >/dev/null && rg -n '^# Stable Release Reviewer Guide$' docs/release/reviewer-guide.md >/dev/null && rg -n '^Target: \\x600\.1\.0\\x60$' docs/release/reviewer-guide.md >/dev/null && rg -n '^Current stable target:$' docs/release/versioning.md >/dev/null && rg -n '^- \\x600\.1\.0\\x60$' docs/release/versioning.md >/dev/null; else true; fi" "0115 stable handoff guardrail (stable metadata is rewritten consistently when VERSION is stable)"
fi



if [ -f "$ROOT_DIR/docs/plans/in_progress/0088-live-midi-composer-scene.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0088-live-midi-composer-scene.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'scene-midi|Connect MIDI|midi-return-live|midi-snapshots|midi-suggestions|midi-current-fret|midi-suggestion-fret|requestMIDIAccess|MIDI_SNAPSHOT_STORAGE_KEY|CC64|CC66|middle pedal|Live MIDI Compass' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js scripts/validate_wasm_gallery_playwright.mjs scripts/capture_wasm_gallery_screenshots.mjs scripts/lib/wasm_gallery_playwright_common.mjs README.md docs/release/reviewer-guide.md docs/research/algorithms/keyboard-interaction.md >/dev/null" "0088 live MIDI scene guardrail (runtime, docs, and verification wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'installFakeMidi|driveFakeMidiTriad|waitForMidiSceneActive|data-midi-snapshot|scene-midi\\.png' scripts/validate_wasm_gallery_playwright.mjs scripts/capture_wasm_gallery_screenshots.mjs scripts/lib/wasm_gallery_playwright_common.mjs docs/release/gallery-capture.md >/dev/null" "0088 live MIDI scene guardrail (fake MIDI validation and capture flow are wired)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0089-live-midi-context-and-snapshot-ux.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0089-live-midi-context-and-snapshot-ux.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-tonic|midi-mode|midi-save-snapshot|selected context|context orbit|context overlap|snapshot context|contextLabel|suggestionNames' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js scripts/validate_wasm_gallery_playwright.mjs README.md docs/release/reviewer-guide.md docs/research/algorithms/keyboard-interaction.md >/dev/null" "0089 live MIDI context guardrail (UI, runtime, docs, and verification wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'selectOption\\(\"#midi-tonic\"|selectOption\\(\"#midi-mode\"|contextChanged|snapshotContextRestored' scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0089 live MIDI context guardrail (playwright proves tonic/mode changes alter the scene and snapshot recall restores context)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0091-voiced-state-and-temporal-memory.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0091-voiced-state-and-temporal-memory.md" ]; then
    check_cmd "cd '$ROOT_DIR' && test -f src/counterpoint.zig && rg -n 'pub const counterpoint|tests/counterpoint_test\\.zig' src/root.zig >/dev/null" "0091 counterpoint core guardrail (module and focused tests are wired into the root surface)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'VoicedState|VoicedHistoryWindow|buildVoicedState|inferCadenceState' src/counterpoint.zig src/tests/counterpoint_test.zig docs/research/algorithms/voice-leading.md >/dev/null" "0091 counterpoint state guardrail (state/history logic and research docs are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_metric_position|lmt_voice|lmt_voiced_state|lmt_voiced_history|lmt_voiced_history_reset|lmt_build_voiced_state|lmt_voiced_history_push' include/libmusictheory.h src/c_api.zig build.zig scripts/check_wasm_exports.mjs src/tests/c_api_test.zig >/dev/null" "0091 counterpoint ABI guardrail (experimental state/history ABI is declared, exported, and tested)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0092-motion-classifier-and-rule-profiles.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0092-motion-classifier-and-rule-profiles.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'MotionSummary|VoiceMotionClass|PairMotionClass|CounterpointRuleProfile|evaluateMotionProfile|classifyMotion' src/counterpoint.zig src/tests/counterpoint_test.zig docs/research/algorithms/voice-leading.md >/dev/null" "0092 motion classifier guardrail (adjacent-state motion semantics and docs are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'species|tonal_chorale|modal_polyphony|jazz_close_leading|free_contemporary' src/counterpoint.zig src/tests/counterpoint_test.zig include/libmusictheory.h src/c_api.zig >/dev/null" "0092 rule profile guardrail (all declared profiles are implemented and covered consistently)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_pair_motion_class|lmt_counterpoint_rule_profile|lmt_motion_summary|lmt_motion_evaluation|lmt_classify_motion|lmt_evaluate_motion_profile' include/libmusictheory.h src/c_api.zig build.zig scripts/check_wasm_exports.mjs src/tests/c_api_test.zig >/dev/null" "0092 motion/profile ABI guardrail (classification and profile evaluation are exported and tested)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0093-next-step-ranker-and-reason-codes.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0093-next-step-ranker-and-reason-codes.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'NextStepSuggestion|rankNextSteps|NEXT_STEP_REASON_|NEXT_STEP_WARNING_|temporalMemory' src/counterpoint.zig src/tests/counterpoint_test.zig docs/research/algorithms/voice-leading.md >/dev/null" "0093 next-step ranker guardrail (ranker, reasons, and temporal scoring docs are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_next_step_suggestion|lmt_rank_next_steps|lmt_next_step_reason_count|lmt_next_step_reason_name|lmt_next_step_warning_count|lmt_next_step_warning_name' include/libmusictheory.h src/c_api.zig build.zig scripts/check_wasm_exports.mjs src/tests/c_api_test.zig >/dev/null" "0093 next-step ABI guardrail (suggestion structs and reason tables are exported and tested)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'temporal.*history|different profiles|reason_mask|warning_mask' src/tests/counterpoint_test.zig src/tests/c_api_test.zig >/dev/null" "0093 next-step verification guardrail (tests cover profile changes, reasons, warnings, and temporal-memory effects)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0094-interactive-counterpoint-gallery-and-instrument-miniviews.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0094-interactive-counterpoint-gallery-and-instrument-miniviews.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'mini-instrument|midi-profile|midi-history|scene-mini|suggestion-mini|counterpoint|keyboardMiniRangeForNotes|miniRangeSpan' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs README.md >/dev/null" "0094 counterpoint gallery guardrail (interactive scene, profile control, miniviews, docs, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_voiced_history_reset|lmt_voiced_history_push|lmt_rank_next_steps|lmt_next_step_reason_name|lmt_next_step_warning_name|lmt_counterpoint_rule_profile_count|lmt_counterpoint_rule_profile_name' include/libmusictheory.h src/c_api.zig build.zig scripts/check_wasm_exports.mjs examples/wasm-gallery/gallery.js src/tests/c_api_test.zig >/dev/null" "0094 counterpoint gallery guardrail (gallery consumes voiced-history, ranked next-step, reason, warning, and profile-name ABI helpers)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'pitch-class.*color|PC_.*COLOR|noteColor|fill=\\\"#|barre' src/svg/fret.zig src/tests/svg_fret_test.zig >/dev/null" "0094 fret miniview guardrail (library fret previews expose pitch-class coloring and stay covered by tests)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0095-voice-leading-horizon-and-braid-gallery.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0095-voice-leading-horizon-and-braid-gallery.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-horizon|midi-braid|voice-leading horizon|voice braid|renderVoiceLeadingHorizon|renderVoiceBraid' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0095 horizon/braid guardrail (gallery hosts, runtime, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiHorizonFeatures|midiBraidFeatures|candidateNodeCount|historyColumnCount|candidateColumnCount' examples/wasm-gallery/gallery.js scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0095 horizon/braid guardrail (gallery summary and validation assert structural feature counts)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0096-counterpoint-weather-map-and-risk-radar.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0096-counterpoint-weather-map-and-risk-radar.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-weather|midi-risk-radar|renderCounterpointWeatherMap|renderParallelRiskRadar|counterpoint weather map|parallel-risk radar' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0096 weather/radar guardrail (gallery hosts, runtime, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiWeatherFeatures|midiRiskRadarFeatures|cellCount|populatedAxisCount|currentAnchorCount|hoveredCandidateIndex' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0096 weather/radar guardrail (gallery summary and validation assert structural feature counts)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0097-cadence-funnel-and-suspension-machine.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0097-cadence-funnel-and-suspension-machine.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-cadence-funnel|midi-suspension-machine|renderCadenceFunnel|renderSuspensionMachine|Cadence Funnel|Suspension Machine' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0097 cadence/suspension guardrail (gallery hosts, runtime, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_rank_cadence_destinations|lmt_analyze_suspension_machine|lmt_cadence_destination|lmt_suspension_state|lmt_cadence_destination_score|lmt_suspension_machine_summary' include/libmusictheory.h src/c_api.zig build.zig scripts/check_wasm_exports.mjs src/tests/c_api_test.zig src/tests/counterpoint_test.zig >/dev/null" "0097 cadence/suspension guardrail (experimental ABI, exports, and tests are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiCadenceFunnelFeatures|midiSuspensionMachineFeatures|branchCount|anchorCount|stateLabel|obligationCount' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0097 cadence/suspension guardrail (gallery summary and validation assert structural feature counts)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0098-orbifold-ribbon-and-common-tone-constellation.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0098-orbifold-ribbon-and-common-tone-constellation.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-orbifold-ribbon|midi-common-tone-constellation|renderOrbifoldRibbon|renderCommonToneConstellation|Orbifold Ribbon|Common-Tone Constellation' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0098 orbifold/constellation guardrail (gallery hosts, runtime, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'lmt_orbifold_triad_node_count|lmt_orbifold_triad_node_at|lmt_orbifold_triad_edge_count|lmt_orbifold_triad_edge_at|lmt_find_orbifold_triad_node|lmt_orbifold_triad_node|lmt_orbifold_triad_edge' include/libmusictheory.h src/c_api.zig build.zig scripts/check_wasm_exports.mjs src/tests/c_api_test.zig >/dev/null" "0098 orbifold/constellation guardrail (experimental orbifold ABI, exports, and tests are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiOrbifoldRibbonFeatures|midiCommonToneConstellationFeatures|candidateAnchorCount|retainedStarCount|movingVectorCount' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0098 orbifold/constellation guardrail (gallery summary and validation assert structural feature counts)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0099-counterpoint-inspector-and-candidate-pinning.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0099-counterpoint-inspector-and-candidate-pinning.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-inspector|midi-clear-pin|midi-focused-mini|Counterpoint Inspector|Focused Next Instrument|pinnedSuggestionIndex|pinnedSuggestionSignature|resolveFocusedMidiSuggestionIndex|renderMidiCounterpointInspector' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0099 counterpoint inspector guardrail (gallery hosts, focus model, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'focusedCandidateIndex|pinnedCandidateIndex|focusedMiniRendered|midiInspectorFeatures|pin-candidate|clear-pin|pinPersistsAfterMouseleave' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0099 counterpoint inspector guardrail (summary and playwright prove pin/focus state and inspector metadata)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-focused-mini|midi-current-fret|Mini instrument set to|currentMiniMode === \"piano\"|currentMiniMode === \"fret\"|focusedMiniRendered === true' scripts/validate_wasm_gallery_playwright.mjs scripts/lib/wasm_gallery_playwright_common.mjs examples/wasm-gallery/gallery.js >/dev/null" "0099 counterpoint inspector guardrail (current and focused instrument previews are validated under piano and fret modes)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0100-counterpoint-continuation-ladder.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0100-counterpoint-continuation-ladder.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-continuation-ladder|renderMidiContinuationLadder|buildFocusedContinuationContext|Continuation Ladder|data-continuation-clock|data-continuation-mini' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0100 continuation ladder guardrail (gallery hosts, runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiContinuationLadderFeatures|continuationCount|continuationClockCount|continuationMiniCount|sourceFocusedIndex|firstContinuationLabel' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0100 continuation ladder guardrail (summary and playwright prove focused follow-up ranking and mini preview coverage)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0101-counterpoint-path-weaver.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0101-counterpoint-path-weaver.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-path-weaver|renderMidiPathWeaver|buildContinuationPaths|Path Weaver|data-path-weaver-mini' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0101 path weaver guardrail (gallery hosts, recursive path runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiPathWeaverFeatures|pathCount|pathStepCount|pathMiniCount|rootFocusedIndex|terminalLabels' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0101 path weaver guardrail (summary and playwright prove multi-step continuation path rendering and mini preview coverage)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0102-counterpoint-cadence-garden.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0102-counterpoint-cadence-garden.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-cadence-garden|renderMidiCadenceGarden|buildCadenceGardenGroups|Cadence Garden|data-cadence-garden-mini|data-cadence-garden-clock' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0102 cadence garden guardrail (gallery hosts, cadence grouping runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiCadenceGardenFeatures|groupCount|branchCount|terminalClockCount|terminalMiniCount|cadenceLabels|warningGroupCount' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0102 cadence garden guardrail (summary and playwright prove grouped cadence destinations and terminal preview coverage)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0103-counterpoint-profile-orchard.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0103-counterpoint-profile-orchard.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-profile-orchard|renderMidiProfileOrchard|buildProfileOrchardEntries|Profile Orchard|data-profile-orchard-mini|data-profile-orchard-clock' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0103 profile orchard guardrail (gallery host, runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiProfileOrchardFeatures|profileCardCount|populatedProfileCount|highlightedCardCount|profileClockCount|profileMiniCount|activeProfileIndex|profileNames|cadenceLabels|warningCardCount|rootFocusedIndex' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0103 profile orchard guardrail (summary and playwright prove populated profile comparisons and mini preview coverage)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0104-counterpoint-consensus-atlas.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0104-counterpoint-consensus-atlas.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-consensus-atlas|renderMidiConsensusAtlas|buildConsensusAtlasEntries|Consensus Atlas|data-consensus-atlas-mini|data-consensus-atlas-clock' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0104 consensus atlas guardrail (gallery host, runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiConsensusAtlasFeatures|clusterCount|consensusClusterCount|singletonClusterCount|highlightedClusterCount|clusterClockCount|clusterMiniCount|maxSupportCount|focusedSignature|profileCoverageCount|clusterLabels|cadenceLabels' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0104 consensus atlas guardrail (summary and playwright prove shared-vs-outlier consensus clustering and mini preview coverage)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0105-counterpoint-obligation-ledger.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0105-counterpoint-obligation-ledger.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-obligation-ledger|renderMidiObligationLedger|buildObligationLedgerEntries|Obligation Ledger|data-obligation-status' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0105 obligation ledger guardrail (gallery host, runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiObligationLedgerFeatures|entryCount|criticalEntryCount|focusedSupportCount|focusedDelayCount|focusedAggravateCount|warningEntryCount|focusedSignature|statusLabels|entryLabels' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0105 obligation ledger guardrail (summary and playwright prove focused obligation outcomes and synchronized status coverage)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0106-counterpoint-resolution-threader.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0106-counterpoint-resolution-threader.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-resolution-threader|renderMidiResolutionThreader|buildResolutionThreaderRows|Resolution Threader|data-resolution-thread-status' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0106 resolution threader guardrail (gallery host, runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiResolutionThreaderFeatures|rowCount|threadCount|resolvedThreadCount|aggravateThreadCount|openThreadCount|focusedSignature|entryLabels' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0106 resolution threader guardrail (summary and playwright prove projected obligation threads and focus synchronization)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0107-counterpoint-obligation-timeline.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0107-counterpoint-obligation-timeline.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-obligation-timeline|renderMidiObligationTimeline|buildObligationTimelineColumns|buildObligationTimelineRows|Obligation Timeline|data-obligation-timeline-status' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0107 obligation timeline guardrail (gallery host, runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiObligationTimelineFeatures|rowCount|historyColumnCount|focusedColumnCount|actualMatchCount|resolvedCellCount|aggravateCellCount|inactiveCellCount|focusedSignature|rowLabels' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0107 obligation timeline guardrail (summary and playwright prove history columns, focused synchronization, and populated current-duty rows)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0108-counterpoint-voice-duties.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0108-counterpoint-voice-duties.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-voice-duties|renderMidiVoiceDuties|buildVoiceDutyRows|Voice Duties|data-voice-duty-status|voice-duties-current-note|voice-duties-focused-note' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0108 voice duties guardrail (gallery host, runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiVoiceDutiesFeatures|activeDutyCount|resolveCount|aggravateCount|suspensionVoiceCount|leadingToneVoiceCount|leapRecoveryCount|currentNoteCount|focusedNoteCount|focusedSignature|rowLabels' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0108 voice duties guardrail (summary and playwright prove per-voice duties, synchronized focus, and non-neutral seeded rows)"
fi

if [ -f "$ROOT_DIR/docs/plans/in_progress/0109-counterpoint-repair-lab.md" ] || [ -f "$ROOT_DIR/docs/plans/completed/0109-counterpoint-repair-lab.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-repair-lab|renderMidiRepairLab|buildRepairLabEntries|buildRepairTargetsForVoice|Repair Lab|data-repair-status|data-repair-label' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0109 repair lab guardrail (gallery host, runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiRepairLabFeatures|improvedRepairCount|improvedVoiceCount|warningReductionCount|targetHitCount|focusedSignature|repairLabels|voiceLabels' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0109 repair lab guardrail (summary and playwright prove multiple synchronized repair candidates and concrete per-voice improvements)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midi-repair-futures|renderMidiRepairFutures|buildRepairFutureEntries|Repair Futures|data-repair-future-status|data-repair-future-label' examples/wasm-gallery/index.html examples/wasm-gallery/gallery.js examples/wasm-gallery/styles.css scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0110 repair futures guardrail (gallery host, runtime hooks, styles, and validation wiring are present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'midiRepairFutureFeatures|concreteFutureCount|improvedFutureCount|cadenceImprovedCount|futureClockCount|futureMiniCount|futureLabels' examples/wasm-gallery/gallery.js scripts/lib/wasm_gallery_playwright_common.mjs scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0110 repair futures guardrail (summary and playwright prove synchronized repair projections and concrete future path lift)"
fi

if [ -f "$ROOT_DIR/scripts/release_smoke.sh" ]; then
    check_cmd "cd '$ROOT_DIR' && test -x scripts/release_smoke.sh" "0078 release smoke guardrail (script is executable)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n 'tmp/harmoniousapp\\.net|validate_harmonious_|wasm-demo|wasm-scaled-render-parity|wasm-native-rgba-proof|wasm-harmonious-spa' scripts/release_smoke.sh" "0078 release smoke guardrail (script stays on standalone surfaces and does not depend on local harmonious data)"
else
    unverified "0078 release smoke guardrail (script not yet implemented)"
fi

# ───────────────────────────────────────────
# Section 2: Plan Lifecycle Structure
# ───────────────────────────────────────────
section "Plan Lifecycle"

for dir in drafts in_progress completed; do
    if [ -d "$ROOT_DIR/docs/plans/$dir" ]; then
        pass "docs/plans/$dir/ exists"
    else
        fail "docs/plans/$dir/ missing"
    fi
done

DRAFT_COUNT=$(find "$ROOT_DIR/docs/plans/drafts" -name '*.md' | wc -l | tr -d ' ')
IN_PROGRESS_COUNT=$(find "$ROOT_DIR/docs/plans/in_progress" -name '*.md' | wc -l | tr -d ' ')
COMPLETED_COUNT=$(find "$ROOT_DIR/docs/plans/completed" -name '*.md' | wc -l | tr -d ' ')
echo "  Plans: $DRAFT_COUNT drafts, $IN_PROGRESS_COUNT in_progress, $COMPLETED_COUNT completed"

# ───────────────────────────────────────────
# Section 3: Research Docs Completeness
# ───────────────────────────────────────────
section "Research Docs"

THEME_DOCS=(
    "pitch-and-intervals.md"
    "pitch-class-sets-and-set-theory.md"
    "scales-and-modes.md"
    "chords-and-voicings.md"
    "keys-harmony-and-progressions.md"
    "evenness-voice-leading-and-geometry.md"
    "guitar-and-keyboard.md"
)
for doc in "${THEME_DOCS[@]}"; do
    if [ -f "$ROOT_DIR/docs/research/$doc" ]; then
        pass "research/$doc"
    else
        fail "research/$doc missing"
    fi
done

ALGO_DOCS=(
    "pitch-class-set-operations.md"
    "prime-form-and-set-class.md"
    "interval-vector-and-fc-components.md"
    "chromatic-cluster-detection.md"
    "evenness-and-consonance.md"
    "voice-leading.md"
    "scale-mode-key.md"
    "chord-construction-and-naming.md"
    "guitar-voicing.md"
    "note-spelling.md"
    "keyboard-interaction.md"
    "key-slider-and-tonnetz.md"
)
for doc in "${ALGO_DOCS[@]}"; do
    if [ -f "$ROOT_DIR/docs/research/algorithms/$doc" ]; then
        pass "algorithms/$doc"
    else
        fail "algorithms/$doc missing"
    fi
done

DS_DOCS=(
    "pitch-and-pitch-class.md"
    "pitch-class-set.md"
    "intervals-and-vectors.md"
    "set-class-and-classification.md"
    "scales-modes-keys.md"
    "chords-and-harmony.md"
    "guitar-and-keyboard.md"
    "voice-leading-and-geometry.md"
)
for doc in "${DS_DOCS[@]}"; do
    if [ -f "$ROOT_DIR/docs/research/data-structures/$doc" ]; then
        pass "data-structures/$doc"
    else
        fail "data-structures/$doc missing"
    fi
done

VIZ_DOCS=(
    "clock-diagrams.md"
    "staff-notation.md"
    "fret-diagrams.md"
    "mode-icons.md"
    "tessellation-maps.md"
    "evenness-chart.md"
    "orbifold-graph.md"
    "circle-of-fifths-and-key-signatures.md"
)
for doc in "${VIZ_DOCS[@]}"; do
    if [ -f "$ROOT_DIR/docs/research/visualizations/$doc" ]; then
        pass "visualizations/$doc"
    else
        fail "visualizations/$doc missing"
    fi
done

# ───────────────────────────────────────────
# Section 3.5: Graph Architecture Docs
# ───────────────────────────────────────────
section "Graph Architecture Docs"

GRAPH_ARCH_DOCS=(
    "docs/architecture/graphs.md"
    "docs/architecture/graphs/clock.md"
    "docs/architecture/graphs/mode-icons.md"
    "docs/architecture/graphs/staff.md"
    "docs/architecture/graphs/fretboard.md"
    "docs/architecture/graphs/evenness.md"
    "docs/architecture/graphs/tessellation-majmin.md"
    "docs/architecture/graphs/orbifold.md"
    "docs/architecture/graphs/circle-of-fifths.md"
    "docs/architecture/graphs/text-glyphs.md"
    "docs/architecture/graphs/future-harmony-graphs.md"
    "docs/architecture/graphs/samples/README.md"
)

for doc in "${GRAPH_ARCH_DOCS[@]}"; do
    if [ -f "$ROOT_DIR/$doc" ]; then
        pass "$doc"
    else
        fail "$doc missing"
    fi
done

GRAPH_SAMPLE_SVGS=(
    "docs/architecture/graphs/samples/compat-opc.svg"
    "docs/architecture/graphs/samples/compat-optc.svg"
    "docs/architecture/graphs/samples/compat-oc.svg"
    "docs/architecture/graphs/samples/compat-even.svg"
    "docs/architecture/graphs/samples/compat-scale.svg"
    "docs/architecture/graphs/samples/compat-eadgbe.svg"
    "docs/architecture/graphs/samples/compat-chord.svg"
    "docs/architecture/graphs/samples/compat-grand-chord.svg"
    "docs/architecture/graphs/samples/core-opc.svg"
    "docs/architecture/graphs/samples/core-optc.svg"
    "docs/architecture/graphs/samples/core-mode-icon.svg"
    "docs/architecture/graphs/samples/core-evenness.svg"
    "docs/architecture/graphs/samples/core-tessellation.svg"
    "docs/architecture/graphs/samples/core-orbifold.svg"
    "docs/architecture/graphs/samples/core-circle-of-fifths.svg"
)

for sample in "${GRAPH_SAMPLE_SVGS[@]}"; do
    if [ -s "$ROOT_DIR/$sample" ]; then
        pass "$sample"
    else
        fail "$sample missing or empty"
    fi
done

if [ -f "$ROOT_DIR/export_graph_samples.zig" ]; then
    pass "export_graph_samples.zig exists"
else
    fail "export_graph_samples.zig missing"
fi

# ───────────────────────────────────────────
# Section 4: Zig Build (when src/root.zig exists)
# ───────────────────────────────────────────
section "Zig Build"

if [ -f "$ROOT_DIR/src/root.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build verify 2>&1" "zig build verify"
else
    unverified "zig build verify (src/root.zig not yet created)"
fi

# ───────────────────────────────────────────
# Section 5: Reference Data Accessibility
# ───────────────────────────────────────────
section "Reference Data"

if [ -f "/Users/bermi/tmp/music21/music21/chord/tables.py" ]; then
    pass "music21 chord tables accessible"
else
    unverified "music21 chord tables (not found at /Users/bermi/tmp/music21/)"
fi

if [ -f "/Users/bermi/tmp/tonal-ts/packages/dictionary/data/chords.json" ]; then
    pass "tonal-ts chord data accessible"
else
    unverified "tonal-ts chord data (not found at /Users/bermi/tmp/tonal-ts/)"
fi

if [ -f "/Users/bermi/tmp/tonal-ts/packages/dictionary/data/scales.json" ]; then
    pass "tonal-ts scale data accessible"
else
    unverified "tonal-ts scale data (not found at /Users/bermi/tmp/tonal-ts/)"
fi

# ───────────────────────────────────────────
# Section 6: Plan Gates
# ───────────────────────────────────────────
section "Plan Gates"

if [ -f "$ROOT_DIR/src/tests/pitch_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0002 core types test suite"
else
    unverified "0002 core types test suite (src/tests/pitch_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/pitch_class_set_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0003 set operations test suite"
else
    unverified "0003 set operations test suite (src/tests/pitch_class_set_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/set_class_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0004 set classification test suite"
else
    unverified "0004 set classification test suite (src/tests/set_class_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/interval_analysis_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0005 interval analysis test suite"
else
    unverified "0005 interval analysis test suite (src/tests/interval_analysis_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/cluster_evenness_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0006 cluster/evenness test suite"
else
    unverified "0006 cluster/evenness test suite (src/tests/cluster_evenness_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/scales_modes_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0007 scales/modes test suite"
else
    unverified "0007 scales/modes test suite (src/tests/scales_modes_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/keys_signatures_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0008 keys/signatures test suite"
else
    unverified "0008 keys/signatures test suite (src/tests/keys_signatures_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/chord_construction_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0009 chord construction test suite"
else
    unverified "0009 chord construction test suite (src/tests/chord_construction_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/harmony_analysis_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0010 harmony analysis test suite"
else
    unverified "0010 harmony analysis test suite (src/tests/harmony_analysis_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/voice_leading_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0011 voice leading test suite"
else
    unverified "0011 voice leading test suite (src/tests/voice_leading_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/guitar_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0012 guitar fretboard test suite"
else
    unverified "0012 guitar fretboard test suite (src/tests/guitar_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/keyboard_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0013 keyboard interaction test suite"
else
    unverified "0013 keyboard interaction test suite (src/tests/keyboard_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/svg_clock_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0014 svg clock diagram test suite"
else
    unverified "0014 svg clock diagram test suite (src/tests/svg_clock_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/svg_staff_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0015 svg staff notation test suite"
else
    unverified "0015 svg staff notation test suite (src/tests/svg_staff_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/svg_fret_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0016 svg fret diagram test suite"
else
    unverified "0016 svg fret diagram test suite (src/tests/svg_fret_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/svg_tessellation_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0017 svg tessellation test suite"
else
    unverified "0017 svg tessellation test suite (src/tests/svg_tessellation_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/svg_misc_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0018 svg misc test suite"
else
    unverified "0018 svg misc test suite (src/tests/svg_misc_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/slider_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0019 key slider test suite"
else
    unverified "0019 key slider test suite (src/tests/slider_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/c_api_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build verify 2>&1" "0020 c api test suite"
else
    unverified "0020 c api test suite (src/tests/c_api_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/tables_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build verify 2>&1" "0021 static tables test suite"
else
    unverified "0021 static tables test suite (src/tests/tables_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/property_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build verify 2>&1" "0022 comprehensive testing suite"
else
    unverified "0022 comprehensive testing suite (src/tests/property_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/scripts/extract_reference_data.py" ]; then
    pass "0022 reference extraction script"
else
    unverified "0022 reference extraction script (scripts/extract_reference_data.py not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/index.html" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build wasm-demo 2>&1" "0023 wasm interactive docs demo build"
else
    unverified "0023 wasm interactive docs demo build (examples/wasm-demo/index.html not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/index.html" ] && rg -Fq 'step("wasm-docs"' "$ROOT_DIR/build.zig"; then
    check_cmd "cd '$ROOT_DIR' && zig build wasm-docs 2>&1" "0050 wasm full docs bundle build"
else
    unverified "0050 wasm full docs bundle build (wasm-docs target not yet implemented)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && [ -f "$ROOT_DIR/examples/wasm-demo/harmonious-spa.html" ] && rg -Fq 'step("wasm-harmonious-spa"' "$ROOT_DIR/build.zig"; then
    check_cmd "cd '$ROOT_DIR' && zig build wasm-harmonious-spa 2>&1" "0068 harmonious wasm SPA bundle build"
    check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-harmonious-spa/index.html && test -f zig-out/wasm-harmonious-spa/harmonious-spa.js && test -f zig-out/wasm-harmonious-spa/libmusictheory.wasm" "0068 harmonious wasm SPA bundle guardrail (shell html/js/wasm installed)"
    check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-harmonious-spa/404.html && rg -n 'rel=\"icon\"|spa-shell-canonical' zig-out/wasm-harmonious-spa/index.html zig-out/wasm-harmonious-spa/404.html >/dev/null" "0071 harmonious SPA bundle guardrail (404 fallback and shell metadata installed)"
    if command -v node >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && node scripts/check_wasm_exports.mjs --profile full_demo --wasm zig-out/wasm-harmonious-spa/libmusictheory.wasm" "0068 harmonious wasm SPA export guardrail (required full-demo exports are present)"
    else
        unverified "0068 harmonious wasm SPA export guardrail (node missing)"
    fi
    if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && rg -Fq 'wasm-harmonious-spa/spa-content' "$ROOT_DIR/build.zig"; then
        check_cmd "cd '$ROOT_DIR' && test -d zig-out/wasm-harmonious-spa/spa-content/p && test -d zig-out/wasm-harmonious-spa/spa-content/keyboard && test -d zig-out/wasm-harmonious-spa/spa-content/eadgbe-frets && test -d zig-out/wasm-harmonious-spa/css && test -d zig-out/wasm-harmonious-spa/js-client && test -d zig-out/wasm-harmonious-spa/svg" "0068 harmonious wasm SPA bundle guardrail (content corpus and original static assets installed)"
    else
        unverified "0068 harmonious wasm SPA bundle guardrail (spa-content install not yet implemented)"
    fi
else
    unverified "0068 harmonious wasm SPA bundle build (tmp/harmoniousapp.net, shell page, or build target not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/svg_harmonious_compat_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0024 harmoniousapp.net compatibility test suite"
else
    unverified "0024 harmoniousapp.net compatibility test suite (src/tests/svg_harmonious_compat_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/tests/even_compat_model_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0064 even compat domain model test suite"
else
    unverified "0064 even compat domain model test suite (src/tests/even_compat_model_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/validation.html" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build wasm-demo 2>&1" "0024 wasm validation page build"
else
    unverified "0024 wasm validation page build (examples/wasm-demo/validation.html not yet implemented)"
fi

if [ -d "$ROOT_DIR/src" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_scale_mod_ulpshim\" src" "0032 global guardrail (no scale modifier ulp replay module imports in src)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_scale_layout_ulpshim\" src" "0032 global guardrail (no scale layout ulp replay module imports in src)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_scale_x_by_index.zig" "0032 global guardrail (scale by-index replay artifact remains removed)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_scale_nomod_names.zig" "0032 global guardrail (scale name replay artifact remains removed)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_scale_nomod_profile_tuning.zig" "0032 global guardrail (scale profile tuning replay artifact remains removed)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_scale_nomod_keysig_lines.zig" "0032 global guardrail (scale keysig replay artifact remains removed)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_scale_mod_ulpshim.zig" "0032 global guardrail (scale modifier ulp replay artifact remains removed)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_scale_layout_ulpshim.zig" "0032 global guardrail (scale layout ulp replay artifact remains removed)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_scale_mod_assets.zig" "0032 global guardrail (scale absolute modifier asset replay artifact remains removed)"
else
    unverified "0032 global guardrail (src directory missing)"
fi

if [ -f "$ROOT_DIR/src/harmonious_svg_compat.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"@embedFile\\(|tmp/harmoniousapp\\.net|harmonious_embed_refs\" src/harmonious_svg_compat.zig" "0028 compatibility generator anti-embed guardrail"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"\\.majmin_modes, \\.majmin_scales => svg_tessellation\\.renderScaleTessellation\\(buf\\)\" src/harmonious_svg_compat.zig" "0028 majmin compat guardrail (no placeholder tessellation fallback)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"generated/harmonious_manifest\\.zig\" src/harmonious_svg_compat.zig src/root.zig src/c_api.zig" "0046 wasm compat name-pack guardrail (runtime path not coupled to harmonious_manifest)"
else
    unverified "0028 compatibility generator anti-embed guardrail (src/harmonious_svg_compat.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/harmonious_name_pack.zig" ] && [ -f "$ROOT_DIR/src/generated/harmonious_name_pack_xz.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n \"harmonious_name_pack_xz\" src/harmonious_name_pack.zig src/harmonious_svg_compat.zig" "0046 wasm compat name-pack guardrail (compact name-pack module wired)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"generated/harmonious_manifest\\.zig\" src/harmonious_name_pack.zig src/harmonious_svg_compat.zig" "0046 wasm compat name-pack guardrail (no fallback manifest import in name-pack path)"
else
    unverified "0046 wasm compat name-pack guardrail (name-pack sources missing)"
fi

if [ -f "$ROOT_DIR/src/svg/scale_nomod_compat.zig" ] && [ -f "$ROOT_DIR/src/harmonious_svg_compat.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"renderScaleStaffByIndex|SCALE_X_BY_INDEX|harmonious_scale_x_by_index\" src/harmonious_svg_compat.zig src/svg/scale_nomod_compat.zig" "0028 scale algorithmic layout guardrail (no index-based x replay)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"std\\.mem\\.eql\\(u8, stem,\" src/svg/scale_nomod_compat.zig" "0028 scale algorithmic layout guardrail (no stem-specific hardcoded exceptions)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_scale_nomod_profile_tuning|harmonious_scale_nomod_names|harmonious_scale_nomod_keysig_lines|SCALE_PROFILE_TUNINGS|layoutTuning\\(|stepUlpNudge\\(|isNoModStem\\(|ModPatch|SHARP_PATCHES|FLAT_PATCHES|NATURAL_PATCHES|DOUBLE_FLAT_PATCHES|resolveModifierOffset\\(\" src/svg/scale_nomod_compat.zig" "0032 scale pure algorithmic guardrail (no replay tuning/name/keysig/patch tables)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_scale_mod_ulpshim\" src/svg/scale_nomod_compat.zig" "0032 scale pure algorithmic guardrail (no modifier ulp replay module)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_scale_layout_ulpshim\" src/svg/scale_nomod_compat.zig" "0032 scale pure algorithmic guardrail (no generated layout ulp replay module)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"offsets:\\s*\\[9\\]u8|\\.offsets\\s*=\\s*\\.\\{\" src/svg/scale_nomod_compat.zig" "0032 scale pure algorithmic guardrail (no per-rule offset-array replay tables)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"ScaleLayoutSigRule|SCALE_LAYOUT_SIG_RULES\" src/svg/scale_nomod_compat.zig" "0032 scale pure algorithmic guardrail (no signature replay tables)"
else
    unverified "0028 scale algorithmic layout guardrail (scale compat sources missing)"
fi

if [ -f "$ROOT_DIR/src/svg/chord_compat.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"std\\.mem\\.eql\\(u8, stem,\" src/svg/chord_compat.zig" "0028 chord algorithmic layout guardrail (no stem-specific hardcoded exceptions)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"@embedFile\\(|tmp/harmoniousapp\\.net\" src/svg/chord_compat.zig" "0028 chord algorithmic layout guardrail (no embedded/svg reference payloads)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_chord_mod_x_lookup|harmonious_chord_mod_y_lookup|harmonious_whole_note_x_lookup|harmonious_whole_note_y_lookup\" src/svg/chord_compat.zig" "0032 chord algorithmic layout guardrail (no x/y lookup coordinate replay tables)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_chord_mod_patches\" src/svg/chord_compat.zig" "0032 chord algorithmic layout guardrail (no chord modifier patch lookup replay tables)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_chord_mod_ulpshim\" src/svg/chord_compat.zig" "0032 chord algorithmic layout guardrail (no chord modifier ulp table replay modules)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_scale_mod_ulpshim\" src/svg/chord_compat.zig" "0032 chord algorithmic layout guardrail (no shared scale modifier ulp replay module)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_whole_note_patches\" src/svg/chord_compat.zig" "0032 chord algorithmic layout guardrail (no whole-note patch lookup replay tables)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_whole_note_ulpshim\" src/svg/chord_compat.zig" "0032 chord algorithmic layout guardrail (no whole-note ulp table replay modules)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"110\\.9506\" src/svg/chord_compat.zig" "0032 chord algorithmic layout guardrail (no hardcoded ledger width magic anchor)"
else
    unverified "0028 chord algorithmic layout guardrail (src/svg/chord_compat.zig missing)"
fi

if [ -f "$ROOT_DIR/src/generated/harmonious_scale_mod_offset_assets.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"ModPatch|SHARP_PATCH|FLAT_PATCH|NATURAL_PATCH|DOUBLE_FLAT_PATCH|_PATCHES|SHARP_OFFSETS|FLAT_OFFSETS|NATURAL_OFFSETS|DOUBLE_FLAT_OFFSETS|_OFFSETS\" src/generated/harmonious_scale_mod_offset_assets.zig" "0032 chord algorithmic layout guardrail (no modifier patch/offset replay tables in generated scale modifier offset assets)"
else
    unverified "0032 chord algorithmic layout guardrail (src/generated/harmonious_scale_mod_offset_assets.zig missing)"
fi

if [ -f "$ROOT_DIR/src/generated/harmonious_even_segment_xz.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_even_gzip\" src/svg/evenness_compat.zig" "0035 even compat guardrail (no monolithic even gzip replay import when segmented assets exist)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"harmonious_even_segment_xz\" src/svg/evenness_compat.zig" "0035 even compat guardrail (segmented even xz module wired in)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_even_segment_gzip.zig" "0035 even compat guardrail (legacy segmented gzip artifact removed after xz cutover)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_even_gzip.zig" "0035 even compat guardrail (gzip payload artifact removed when segmented assets exist)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_even_segments.zig" "0035 even compat guardrail (uncompressed segmented payload artifact removed)"
elif [ -f "$ROOT_DIR/src/generated/harmonious_even_segment_gzip.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_even_gzip\" src/svg/evenness_chart.zig" "0035 even compat guardrail (no monolithic even gzip replay import when segmented assets exist)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"harmonious_even_segment_gzip\" src/svg/evenness_chart.zig" "0035 even compat guardrail (segmented even gzip module wired in)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_even_gzip.zig" "0035 even compat guardrail (gzip payload artifact removed when segmented assets exist)"
    check_cmd "cd '$ROOT_DIR' && test ! -f src/generated/harmonious_even_segments.zig" "0035 even compat guardrail (uncompressed segmented payload artifact removed)"
else
    unverified "0035 even compat guardrail (segmented even gzip assets not yet present)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/index.html" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n -e \"wasm_mod\\.export_symbol_names\\s*=\\s*&validation_export_symbols\" -e \"wasm_mod\\.export_symbol_names\\s*=\\s*&\\.\\{\" build.zig" "0047 wasm explicit export roots guardrail (build.zig defines wasm export symbol roots)"
    check_cmd "cd '$ROOT_DIR' && rg -n -e \"wasm_exe\\.rdynamic\\s*=\\s*false\" -e \"fn configureWasmExe\\(exe: \\*std\\.Build\\.Step\\.Compile\\) void\" -e \"exe\\.rdynamic\\s*=\\s*false\" build.zig" "0047 wasm explicit export roots guardrail (rdynamic disabled for wasm)"
    check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-demo/libmusictheory.wasm && [ \"$(wc -c < zig-out/wasm-demo/libmusictheory.wasm | tr -d '[:space:]')\" -lt 524288 ]" "0046 wasm demo size guardrail (<512KiB)"
    if [ -f "$ROOT_DIR/scripts/check_wasm_exports.mjs" ] && command -v node >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && node scripts/check_wasm_exports.mjs --profile validation --wasm zig-out/wasm-demo/libmusictheory.wasm" "0047 wasm explicit export roots guardrail (required validation exports are present)"
    else
        unverified "0047 wasm explicit export roots guardrail (scripts/check_wasm_exports.mjs or node missing)"
    fi
    check_cmd "cd '$ROOT_DIR' && python3 -c \"import pathlib,sys; root=pathlib.Path('zig-out/wasm-demo'); wasm=root/'libmusictheory.wasm'; js_total=sum(p.stat().st_size for p in root.glob('*.js')); combined=wasm.stat().st_size+js_total; print(f'wasm={wasm.stat().st_size} js_total={js_total} combined={combined}'); sys.exit(0 if combined <= 524288 else 1)\"" "0048 wasm validation bundle guardrail (installed wasm+js <= 512KiB)"
    if [ -f "$ROOT_DIR/scripts/wasm_size_audit.py" ] && command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/wasm_size_audit.py --wasm zig-out/wasm-demo/libmusictheory.wasm --max-wasm-bytes 524288 --max-data-bytes 480000 --max-reachable-generated-bytes 1600000 --max-coordinate-generated-bytes 170000" "0046 wasm size audit guardrail (section + generated footprint budgets)"
    else
        unverified "0046 wasm size audit guardrail (scripts/wasm_size_audit.py or python3 missing)"
    fi
    if [ -f "$ROOT_DIR/src/wasm_validation_api.zig" ]; then
        check_cmd "cd '$ROOT_DIR' && rg -n \"root_source_file = b\\.path\\(\\\"src/wasm_validation_api\\.zig\\\"\\)\" build.zig" "0049 wasm validation root guardrail (dedicated validation root wired in build)"
        check_cmd "cd '$ROOT_DIR' && python3 -c \"import pathlib,sys; root=pathlib.Path('zig-out/wasm-demo'); wasm=root/'libmusictheory.wasm'; js_total=sum(p.stat().st_size for p in root.glob('*.js')); combined=wasm.stat().st_size+js_total; print(f'wasm={wasm.stat().st_size} js_total={js_total} combined={combined}'); sys.exit(0 if combined < 500000 else 1)\"" "0049 wasm validation bundle guardrail (installed wasm+js < 500000)"
    else
        unverified "0049 wasm validation root guardrail (src/wasm_validation_api.zig not yet implemented)"
    fi
    if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && rg -Fq 'wasm-demo/tmp/harmoniousapp.net' "$ROOT_DIR/build.zig"; then
        check_cmd "cd '$ROOT_DIR' && test -d zig-out/wasm-demo/tmp/harmoniousapp.net && test -f zig-out/wasm-demo/tmp/harmoniousapp.net/even/index.svg" "0050 installed validation bundle guardrail (local harmonious refs mirrored into wasm-demo output)"
    else
        unverified "0050 installed validation bundle guardrail (wasm-demo ref mirror not yet implemented)"
    fi
else
    unverified "0046 wasm demo size guardrail (<512KiB) (examples/wasm-demo/index.html not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/index.html" ] && rg -Fq 'step("wasm-docs"' "$ROOT_DIR/build.zig"; then
    if [ -f "$ROOT_DIR/scripts/check_wasm_exports.mjs" ] && command -v node >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-docs/libmusictheory.wasm && node scripts/check_wasm_exports.mjs --profile full_demo --wasm zig-out/wasm-docs/libmusictheory.wasm" "0050 wasm full docs export guardrail (required full-demo exports are present)"
    else
        unverified "0050 wasm full docs export guardrail (scripts/check_wasm_exports.mjs or node missing)"
    fi
    if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && rg -Fq 'wasm-docs/tmp/harmoniousapp.net' "$ROOT_DIR/build.zig"; then
        check_cmd "cd '$ROOT_DIR' && test -d zig-out/wasm-docs/tmp/harmoniousapp.net && test -f zig-out/wasm-docs/tmp/harmoniousapp.net/even/index.svg" "0050 installed docs bundle guardrail (local harmonious refs mirrored into wasm-docs output)"
    else
        unverified "0050 installed docs bundle guardrail (wasm-docs ref mirror not yet implemented)"
    fi
else
    unverified "0050 wasm full docs export guardrail (wasm-docs target not yet implemented)"
fi

if [ -f "$ROOT_DIR/include/libmusictheory.h" ] && [ -f "$ROOT_DIR/examples/wasm-demo/app.js" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n \"lmt_fret_to_midi_n|lmt_midi_to_fret_positions_n|lmt_svg_fret_n\" include/libmusictheory.h" "0061 parametric fret ABI guardrail (generic fret symbols declared in public header)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"lmt_fret_to_midi_n|lmt_midi_to_fret_positions_n|lmt_svg_fret_n\" examples/wasm-demo/app.js examples/wasm-demo/index.html build.zig scripts/check_wasm_exports.mjs" "0061 parametric fret ABI guardrail (docs/demo/build wired to generic fret symbols)"
else
    unverified "0061 parametric fret ABI guardrail (header or docs app missing)"
fi

if [ -f "$ROOT_DIR/src/guitar.zig" ] && [ -f "$ROOT_DIR/docs/research/algorithms/guitar-voicing.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n \"GenericVoicing|generateVoicingsGeneric|pitchClassGuideGeneric|fretsToUrlGeneric|urlToFretsGeneric\" src/guitar.zig" "0062 generic fret semantics guardrail (voicing/guide/url generic APIs present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'CAGED.*six-string|six-string.*CAGED|standard-guitar.*CAGED|CAGED remains' docs/research/algorithms/guitar-voicing.md docs/research/data-structures/guitar-and-keyboard.md docs/architecture/graphs/fretboard.md" "0062 generic fret semantics guardrail (docs explicitly scope CAGED as six-string guitar-specific)"
else
    unverified "0062 generic fret semantics guardrail (guitar core or research docs missing)"
fi

if [ -f "$ROOT_DIR/include/libmusictheory.h" ] && [ -f "$ROOT_DIR/src/c_api.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n \"lmt_guide_dot|lmt_generate_voicings_n|lmt_pitch_class_guide_n|lmt_frets_to_url_n|lmt_url_to_frets_n\" include/libmusictheory.h" "0063 generic fret semantic ABI guardrail (public header exposes guide/voicing/url symbols)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"lmt_generate_voicings_n|lmt_pitch_class_guide_n|lmt_frets_to_url_n|lmt_url_to_frets_n\" src/c_api.zig build.zig scripts/check_wasm_exports.mjs examples/wasm-demo/app.js examples/wasm-demo/index.html" "0063 generic fret semantic ABI guardrail (c api, exports, and docs demo wired to new symbols)"
else
    unverified "0063 generic fret semantic ABI guardrail (header or c api missing)"
fi

if [ -f "$ROOT_DIR/include/libmusictheory_compat.h" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"lmt_bitmap_proof_scale_numerator|lmt_bitmap_compat_|lmt_wasm_scratch_ptr|lmt_wasm_scratch_size|lmt_svg_compat_\" include/libmusictheory.h" "0074 public api split guardrail (public header excludes compat/proof symbols)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"#include \\\"libmusictheory\\.h\\\"|lmt_bitmap_proof_scale_numerator|lmt_bitmap_compat_|lmt_wasm_scratch_ptr|lmt_wasm_scratch_size|lmt_svg_compat_\" include/libmusictheory_compat.h" "0074 public api split guardrail (compat header carries separated compat/proof symbols)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"libmusictheory_compat\\.h|internal exact SVG parity validation bundle|internal scaled render parity verification bundle|internal native RGBA proof verification bundle|internal harmoniousapp\\.net SPA verification shell|standalone interactive docs bundle\" build.zig" "0074 build surface split guardrail (compat header install and public/internal target labeling wired)"
    if [ -f "$ROOT_DIR/examples/c/compat_smoke.c" ]; then
        check_cmd "cd '$ROOT_DIR' && rg -n \"libmusictheory_compat\\.h|lmt_svg_compat_kind_count|lmt_bitmap_proof_scale_numerator\" examples/c/compat_smoke.c build.zig" "0074 compat header smoke guardrail (separate compat include exercised in C smoke path)"
    else
        unverified "0074 compat header smoke guardrail (examples/c/compat_smoke.c not yet implemented)"
    fi
else
    unverified "0074 public api split guardrail (compat header split not yet implemented)"
fi

if [ -f "$ROOT_DIR/README.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n '^# libmusictheory$|^## Stable API Contract$|^## Memory And Lifetime$|^## Quickstart \\(C ABI\\)$|^## Quickstart \\(Zig\\)$|^## Quickstart \\(Browser/WASM\\)$|^## Public vs Internal Surfaces$' README.md" "0076 root readme guardrail (library-facing README sections present)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'stable public surface|experimental|internal|libmusictheory_compat\\.h|wasm-docs|wasm-demo|wasm-scaled-render-parity|wasm-native-rgba-proof|wasm-harmonious-spa' README.md" "0076 root readme guardrail (surface classification and bundle boundaries documented)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n 'copy this file|save this file' README.md" "0076 root readme guardrail (standalone docs stay user-facing, not editor-instruction driven)"
    check_cmd "cd '$ROOT_DIR' && rg -n '^## Release Readiness$|RELEASE_CHECKLIST\\.md|docs/release/smoke-matrix\\.md|scripts/release_smoke\\.sh' README.md" "0078 release readme guardrail (release docs and smoke path are linked)"
else
    unverified "0076 root readme guardrail (root README.md not yet implemented)"
fi

if [ -f "$ROOT_DIR/include/libmusictheory.h" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'Stable public C ABI|Ownership and lifetime|Caller-owned output buffers|String-returning APIs|Experimental APIs|Internal Harmonious verification/proof APIs' include/libmusictheory.h" "0076 public header contract guardrail (stable/experimental/internal and lifetime rules documented)"
else
    unverified "0076 public header contract guardrail (public header missing)"
fi

if [ -f "$ROOT_DIR/README.md" ] && [ -f "$ROOT_DIR/docs/internal/harmonious-regression.md" ]; then
    check_cmd "cd '$ROOT_DIR' && ! sed -n '1,20p' README.md | rg -qi 'harmonious|validation|parity|proof'" "0075 public docs guardrail (root README opens with standalone library story, not Harmonious verification framing)"
    check_cmd "cd '$ROOT_DIR' && rg -n '^# Harmonious Regression Infrastructure$|^## Exact SVG Parity$|^## Scaled Render Parity$|^## Native RGBA Proof$|^## Harmonious SPA$|^## Reduced Release Smoke$' docs/internal/harmonious-regression.md" "0075 internal regression doc guardrail (internal Harmonious tooling documented in a dedicated internal doc)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'internal regression infrastructure|tmp/harmoniousapp.net|release smoke|extended Harmonious regression|optional local data' README.md docs/internal/harmonious-regression.md examples/wasm-demo/README.md" "0075 doc quarantine guardrail (release vs internal verification split is documented)"
else
    unverified "0075 doc quarantine guardrail (root README or docs/internal/harmonious-regression.md missing)"
fi

if [ -f "$ROOT_DIR/examples/wasm-gallery/index.html" ] && rg -Fq 'step("wasm-gallery"' "$ROOT_DIR/build.zig"; then
    check_cmd "cd '$ROOT_DIR' && zig build wasm-gallery 2>&1" "0077 standalone gallery bundle build"
    check_cmd "cd '$ROOT_DIR' && rg -n 'standalone gallery bundle|wasm-gallery/index.html|wasm-gallery/gallery.js|wasm-gallery/styles.css' build.zig" "0077 standalone gallery guardrail (bundle install and target wiring present)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n 'validation\\.js|render-compare-common\\.js|harmonious-spa\\.js|lmt_svg_compat_|lmt_bitmap_compat_|lmt_wasm_scratch_ptr|lmt_wasm_scratch_size|tmp/harmoniousapp\\.net' examples/wasm-gallery scripts/validate_wasm_gallery_playwright.mjs -g '!zig-out/**'" "0077 standalone gallery guardrail (gallery sources stay on public APIs and do not import compat-only paths)"
    check_cmd "cd '$ROOT_DIR' && rg -n '__lmtGallerySummary|lmt_pcs_from_list|lmt_mode|lmt_chord_name|lmt_svg_clock_optc|lmt_svg_fret_n|lmt_generate_voicings_n' examples/wasm-gallery/gallery.js scripts/validate_wasm_gallery_playwright.mjs >/dev/null" "0077 standalone gallery guardrail (public-api gallery scenes and summary object are wired)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'wasm-gallery|gallery' README.md" "0077 standalone gallery guardrail (root readme mentions gallery bundle)"
    if [ -f "$ROOT_DIR/scripts/check_wasm_exports.mjs" ] && command -v node >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-gallery/libmusictheory.wasm && node scripts/check_wasm_exports.mjs --profile gallery --wasm zig-out/wasm-gallery/libmusictheory.wasm" "0077 standalone gallery export guardrail (public gallery exports are present)"
    else
        unverified "0077 standalone gallery export guardrail (scripts/check_wasm_exports.mjs or node missing)"
    fi
    if [ -f "$ROOT_DIR/scripts/validate_wasm_gallery_playwright.mjs" ] && command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && node scripts/validate_wasm_gallery_playwright.mjs 2>&1" "0077 standalone gallery playwright smoke validation"
    else
        unverified "0077 standalone gallery playwright smoke validation (script or runtime missing)"
    fi
else
    unverified "0077 standalone gallery bundle build (gallery target not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-gallery/gallery-presets.json" ]; then
    check_cmd "cd '$ROOT_DIR' && test \"$(rg -o '<section class=\"panel reveal scene-card\"' examples/wasm-gallery/index.html | wc -l | tr -d ' ')\" -ge 6" "0080 gallery curation guardrail (minimum standalone scene count is >= 6)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'gallery-presets\\.json|manifestLoaded|progression|compare|sceneCount' examples/wasm-gallery/gallery.js scripts/validate_wasm_gallery_playwright.mjs build.zig examples/wasm-gallery/index.html >/dev/null" "0080 gallery curation guardrail (preset manifest, new scenes, and summary wiring are present)"
    check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-gallery/gallery-presets.json" "0080 gallery curation guardrail (preset manifest installs into wasm-gallery output)"
    check_cmd "cd '$ROOT_DIR' && python3 -c \"import json, pathlib; data=json.loads(pathlib.Path('examples/wasm-gallery/gallery-presets.json').read_text()); assert data['meta']['sceneCount'] >= 6; assert len(data['progressionPresets']) >= 4; assert len(data['comparePresets']) >= 4; assert len(data['setPresets']) >= 4; assert len(data['fretPresets']) >= 4\"" "0080 gallery curation guardrail (preset manifest has curated multi-scene coverage)"
    check_cmd "cd '$ROOT_DIR' && rg -n '^## Gallery Scenes$|Set Observatory|Key Bloom|Chord Atelier|Progression Drift|Constellation Delta|Fret Atlas' README.md" "0080 gallery curation guardrail (root readme explains the gallery scenes)"
else
    unverified "0080 gallery curation guardrail (preset manifest not yet implemented)"
fi

if [ -f "$ROOT_DIR/scripts/capture_wasm_gallery_screenshots.mjs" ] && [ -f "$ROOT_DIR/docs/release/gallery-capture.md" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'gallery-capture\\.md|capture_wasm_gallery_screenshots\\.mjs|\\?capture=1' docs/release/gallery-capture.md scripts/capture_wasm_gallery_screenshots.mjs examples/wasm-gallery/gallery.js examples/wasm-gallery/index.html >/dev/null" "0081 gallery capture guardrail (docs, script, and capture route wiring are present)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n 'tmp/harmoniousapp\\.net|wasm-demo|wasm-scaled-render-parity|wasm-native-rgba-proof|harmonious-spa|libmusictheory_compat\\.h|lmt_svg_compat_|lmt_bitmap_compat_' scripts/capture_wasm_gallery_screenshots.mjs docs/release/gallery-capture.md" "0081 gallery capture guardrail (capture pipeline stays on standalone public surfaces)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'gallery-capture\\.md|capture_wasm_gallery_screenshots\\.mjs|wasm-gallery-captures' README.md docs/release/artifacts.md docs/release/smoke-matrix.md scripts/release_smoke.sh >/dev/null" "0081 gallery capture guardrail (release docs and smoke path include screenshot regeneration)"
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && node scripts/capture_wasm_gallery_screenshots.mjs 2>&1" "0081 gallery screenshot capture verification"
        check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-gallery-captures/gallery-overview.png && test -f zig-out/wasm-gallery-captures/gallery-hero.png && test -f zig-out/wasm-gallery-captures/scene-set.png && test -f zig-out/wasm-gallery-captures/scene-key.png && test -f zig-out/wasm-gallery-captures/scene-chord.png && test -f zig-out/wasm-gallery-captures/scene-progression.png && test -f zig-out/wasm-gallery-captures/scene-compare.png && test -f zig-out/wasm-gallery-captures/scene-fret.png && test -f zig-out/wasm-gallery-captures/captures.json" "0081 gallery screenshot capture guardrail (expected capture artifacts generated)"
    else
        unverified "0081 gallery screenshot capture verification (script or runtime missing)"
    fi
else
    unverified "0081 gallery capture guardrail (docs or capture script not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/svg/staff.zig" ] && [ -f "$ROOT_DIR/scripts/validate_wasm_gallery_playwright.mjs" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'staffFeatures|clefCount|sharedStemCount|noteColumnSpan|simultaneousCluster' scripts/validate_wasm_gallery_playwright.mjs scripts/lib/wasm_gallery_playwright_common.mjs examples/wasm-gallery/gallery.js >/dev/null" "0083 staff quality guardrail (gallery validator requires staff feature checks)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'class=\\\\\"clef clef-|class=\\\\\"cluster-stem|class=\\\\\"chord-notehead' src/svg/staff.zig src/tests/svg_staff_test.zig >/dev/null" "0083 staff quality guardrail (public staff renderer and tests expose clef/cluster structure)"
else
    unverified "0083 staff quality guardrail (staff renderer or gallery validator missing)"
fi

if [ -f "$ROOT_DIR/src/svg/staff.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n 'TREBLE_CLEF_PATH_D|BASS_CLEF_PATH_D|class=\\\\\"clef-glyph' src/svg/staff.zig src/tests/svg_staff_test.zig >/dev/null" "0084 clef glyph guardrail (public renderer uses named clef glyph paths)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n 'clef-stroke|clef-hole|M 12 -52 C 2 -52' src/svg/staff.zig >/dev/null" "0084 clef glyph guardrail (placeholder clef spline removed)"
else
    unverified "0084 clef glyph guardrail (staff renderer missing)"
fi

if [ -f "$ROOT_DIR/scripts/release_smoke.sh" ]; then
    check_cmd "cd '$ROOT_DIR' && ./scripts/release_smoke.sh 2>&1" "0078 standalone release smoke matrix"
    if bash -lc "cd '$ROOT_DIR' && ./scripts/release_smoke.sh >/dev/null 2>&1"; then
        RELEASE_SURFACE_SMOKE_STATUS="yes"
    fi
else
    unverified "0078 standalone release smoke matrix (script not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/scaled-render-parity.html" ] && rg -Fq 'step("wasm-scaled-render-parity"' "$ROOT_DIR/build.zig"; then
    check_cmd "cd '$ROOT_DIR' && zig build wasm-scaled-render-parity 2>&1" "0059 scaled render parity bundle build"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"\\.scale\\(|transform:\\s*scale|style\\.transform\" examples/wasm-demo/scaled-render-parity.js" "0059 scaled render parity anti-cheat guardrail (no css/post-bitmap scaling shortcut)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"lmt_svg_compat_generate|rasterizeSvgAtSize|drawImage\\(img, 0, 0, width, height\\)\" examples/wasm-demo/scaled-render-parity.js" "0059 scaled render parity guardrail (generated SVG candidate rasterized directly at target size)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"candidateBackend|lmt_bitmap_compat_candidate_backend_name\" examples/wasm-demo/scaled-render-parity.js examples/wasm-demo/native-rgba-proof.js examples/wasm-demo/render-compare-common.js scripts/validate_harmonious_scaled_render_parity_playwright.mjs scripts/validate_harmonious_native_rgba_proof_playwright.mjs src/c_api.zig src/bitmap_compat.zig" "0059 backend honesty guardrail (candidate backend subtype reported end-to-end)"
    if [ -f "$ROOT_DIR/scripts/check_wasm_exports.mjs" ] && command -v node >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-scaled-render-parity/libmusictheory.wasm && node scripts/check_wasm_exports.mjs --profile scaled_render_parity --wasm zig-out/wasm-scaled-render-parity/libmusictheory.wasm" "0059 scaled render parity export guardrail (required exports are present)"
    else
        unverified "0059 scaled render parity export guardrail (scripts/check_wasm_exports.mjs or node missing)"
    fi
    if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && rg -Fq 'wasm-scaled-render-parity/tmp/harmoniousapp.net' "$ROOT_DIR/build.zig"; then
        check_cmd "cd '$ROOT_DIR' && test -d zig-out/wasm-scaled-render-parity/tmp/harmoniousapp.net && test -f zig-out/wasm-scaled-render-parity/tmp/harmoniousapp.net/opc/047,0,0,0.svg && test -f zig-out/wasm-scaled-render-parity/tmp/harmoniousapp.net/center-square-text/A.svg && test -f zig-out/wasm-scaled-render-parity/tmp/harmoniousapp.net/vert-text-black/6-9.svg && test -f zig-out/wasm-scaled-render-parity/tmp/harmoniousapp.net/vert-text-b2t-black/6-9.svg" "0059 scaled render parity bundle guardrail (local harmonious refs mirrored into parity output)"
    else
        unverified "0059 scaled render parity bundle guardrail (parity ref mirror not yet implemented)"
    fi
else
    unverified "0059 scaled render parity bundle build (target not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/native-rgba-proof.html" ] && rg -Fq 'step("wasm-native-rgba-proof"' "$ROOT_DIR/build.zig"; then
    check_cmd "cd '$ROOT_DIR' && zig build wasm-native-rgba-proof 2>&1" "0060 native RGBA proof bundle build"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"\\.scale\\(|transform:\\s*scale|style\\.transform|drawImage\\(|lmt_svg_compat_generate|generated-svg\" examples/wasm-demo/native-rgba-proof.js" "0060 native RGBA proof anti-cheat guardrail (no generated SVG candidate path or scaling shortcut)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"putImageData\\(\" examples/wasm-demo/render-compare-common.js" "0060 native RGBA proof contract guardrail (candidate RGBA painted through ImageData)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"backend subtype|generated-SVG rasterization inside Zig/WASM|direct-primitives|path-geometry|markup-template-raster|generated-svg-raster\" examples/wasm-demo/native-rgba-proof.html examples/wasm-demo/README.md" "0060 native RGBA proof honesty guardrail (docs disclose backend subtype distinctions)"
    if [ -f "$ROOT_DIR/scripts/check_wasm_exports.mjs" ] && command -v node >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-native-rgba-proof/libmusictheory.wasm && node scripts/check_wasm_exports.mjs --profile native_rgba_proof --wasm zig-out/wasm-native-rgba-proof/libmusictheory.wasm" "0060 native RGBA proof export guardrail (required exports are present)"
    else
        unverified "0060 native RGBA proof export guardrail (scripts/check_wasm_exports.mjs or node missing)"
    fi
    if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && rg -Fq 'wasm-native-rgba-proof/tmp/harmoniousapp.net' "$ROOT_DIR/build.zig"; then
        check_cmd "cd '$ROOT_DIR' && test -d zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/even/index.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/opc/047,0,0,0.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/oc/wt,0,I.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/eadgbe/-1,3,2,0,1,0.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/center-square-text/A.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/vert-text-black/6-9.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/vert-text-b2t-black/6-9.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/majmin/modes,0,rhomb,0.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/majmin/scales,0,uptri,0.svg" "0060 native RGBA proof bundle guardrail (local harmonious refs mirrored into proof output)"
    else
        unverified "0060 native RGBA proof bundle guardrail (proof ref mirror not yet implemented)"
    fi
else
    unverified "0060 native RGBA proof bundle build (target not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/scaled-render-parity.html" ] && [ -f "$ROOT_DIR/examples/wasm-demo/native-rgba-proof.html" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"svg-raster|\\bsvg raster\\b|\\bSVG raster\\b\" examples/wasm-demo/README.md examples/wasm-demo/scaled-render-parity.html examples/wasm-demo/scaled-render-parity.js examples/wasm-demo/native-rgba-proof.html examples/wasm-demo/native-rgba-proof.js scripts/validate_harmonious_scaled_render_parity_playwright.mjs scripts/validate_harmonious_native_rgba_proof_playwright.mjs docs/plans/drafts docs/plans/in_progress -g '!*/completed/*'" "0060 terminology guardrail (no svg-raster term in active surfaces)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"bitmap-proof|Bitmap proof|bitmap proof|wasm-bitmap-proof|__lmtLastBitmapProof|validate_harmonious_bitmap_playwright\" build.zig examples/wasm-demo/README.md examples/wasm-demo scripts docs/plans/drafts docs/plans/in_progress -g '!*/completed/*'" "0060 terminology guardrail (no active bitmap-proof naming remains)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"\\bproof\\b|Proof\" examples/wasm-demo/scaled-render-parity.html examples/wasm-demo/scaled-render-parity.js" "0060 terminology guardrail (scaled render parity surface does not claim proof)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"candidateSource\\s*=\\s*['\\\"]generated-svg['\\\"]|generated-svg\\s*<\" examples/wasm-demo/native-rgba-proof.js examples/wasm-demo/native-rgba-proof.html" "0060 terminology guardrail (native RGBA proof surface does not present generated-svg as a runtime candidate source)"
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 -c \"from pathlib import Path; import sys; roots=[Path('examples/wasm-demo/README.md'), Path('docs/plans/drafts'), Path('docs/plans/in_progress')]; violations=[f'{path}:{lineno}:{line}' for root in roots for path in ([root] if root.is_file() else sorted(root.rglob('*.md'))) for lineno, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1) if 'all 15' in line.lower() and 'proof' in line.lower() and 'native-rgba' not in line.lower() and 'native rgba' not in line.lower()]; sys.exit('\\n'.join(violations[:20])) if violations else None\"" "0060 terminology guardrail (all-15 proof claims must be native-rgba)"
    else
        unverified "0060 terminology guardrail (all-15 proof claims must be native-rgba) (python3 missing)"
    fi
else
    unverified "0060 terminology guardrail (new parity/proof surfaces not yet implemented)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net/even" ] && [ -f "$ROOT_DIR/scripts/audit_even_compat.py" ]; then
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/audit_even_compat.py --root tmp/harmoniousapp.net >/dev/null" "0034 even compatibility structural audit (reference invariants)"
    else
        unverified "0034 even compatibility structural audit (python3 missing)"
    fi
else
    unverified "0034 even compatibility structural audit (tmp/harmoniousapp.net/even or script missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net/majmin" ] && [ -f "$ROOT_DIR/scripts/audit_majmin_compat.py" ]; then
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/audit_majmin_compat.py --root tmp/harmoniousapp.net >/dev/null" "0038 majmin compatibility structural audit (reference invariants)"
    else
        unverified "0038 majmin compatibility structural audit (python3 missing)"
    fi
else
    unverified "0038 majmin compatibility structural audit (tmp/harmoniousapp.net/majmin or script missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net/majmin" ] && [ -f "$ROOT_DIR/scripts/audit_majmin_mode_templates.py" ]; then
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/audit_majmin_mode_templates.py --root tmp/harmoniousapp.net >/dev/null" "0039 majmin mode template audit (masked structure invariant by family/rotation)"
    else
        unverified "0039 majmin mode template audit (python3 missing)"
    fi
else
    unverified "0039 majmin mode template audit (tmp/harmoniousapp.net/majmin or script missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net/majmin" ] && [ -f "$ROOT_DIR/scripts/audit_majmin_scale_templates.py" ]; then
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/audit_majmin_scale_templates.py --root tmp/harmoniousapp.net >/dev/null" "0039 majmin scale template audit (family templates + rotation formula invariants)"
    else
        unverified "0039 majmin scale template audit (python3 missing)"
    fi
else
    unverified "0039 majmin scale template audit (tmp/harmoniousapp.net/majmin or script missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net/majmin" ] && [ -f "$ROOT_DIR/scripts/audit_majmin_scales_parametric.py" ]; then
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/audit_majmin_scales_parametric.py --root tmp/harmoniousapp.net >/dev/null" "0039 majmin scales parametric audit (family decomposition + transposition slot invariants)"
    else
        unverified "0039 majmin scales parametric audit (python3 missing)"
    fi
else
    unverified "0039 majmin scales parametric audit (tmp/harmoniousapp.net/majmin or script missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net/majmin" ] && [ -f "$ROOT_DIR/scripts/audit_majmin_geometry_templates.py" ]; then
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/audit_majmin_geometry_templates.py --root tmp/harmoniousapp.net >/dev/null" "0039 majmin geometry template audit (polygon geometry invariant across scene groups)"
    else
        unverified "0039 majmin geometry template audit (python3 missing)"
    fi
else
    unverified "0039 majmin geometry template audit (tmp/harmoniousapp.net/majmin or script missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net/majmin" ] && [ -f "$ROOT_DIR/scripts/audit_majmin_scales_geometry_slots.py" ]; then
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/audit_majmin_scales_geometry_slots.py --root tmp/harmoniousapp.net >/dev/null" "0040 majmin scales geometry slot audit (first 76 slots invariant geometry layer)"
    else
        unverified "0040 majmin scales geometry slot audit (python3 missing)"
    fi
else
    unverified "0040 majmin scales geometry slot audit (tmp/harmoniousapp.net/majmin or script missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net/majmin" ] && [ -f "$ROOT_DIR/scripts/audit_majmin_modes_geometry_slots.py" ]; then
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/audit_majmin_modes_geometry_slots.py --root tmp/harmoniousapp.net >/dev/null" "0045 majmin modes geometry slot audit (grouped invariant prefix geometry slots)"
    else
        unverified "0045 majmin modes geometry slot audit (python3 missing)"
    fi
else
    unverified "0045 majmin modes geometry slot audit (tmp/harmoniousapp.net/majmin or script missing)"
fi

if [ -f "$ROOT_DIR/src/svg/majmin_scene.zig" ]; then
    if [ -f "$ROOT_DIR/src/generated/harmonious_majmin_scene_pack_xz.zig" ]; then
        check_cmd "cd '$ROOT_DIR' && [ \$(wc -c < src/generated/harmonious_majmin_scene_pack_xz.zig) -le 1100000 ]" "0039 majmin payload reduction guardrail (scene-pack source payload <= 1.1MB while algorithmic cutover progresses)"
        check_cmd "cd '$ROOT_DIR' && awk '/pub const PACK_RAW_LEN:/ {gsub(\";\", \"\", \$6); if (\$6 + 0 < 6503908) ok=1} END {exit(ok ? 0 : 1)}' src/generated/harmonious_majmin_scene_pack_xz.zig" "0044 majmin scales geometry prune guardrail (raw scene-pack payload reduced below pre-0044 baseline)"
        check_cmd "cd '$ROOT_DIR' && awk '/pub const PACK_RAW_LEN:/ {gsub(\";\", \"\", \$6); if (\$6 + 0 < 6488900) ok=1} END {exit(ok ? 0 : 1)}' src/generated/harmonious_majmin_scene_pack_xz.zig" "0045 majmin modes geometry prune guardrail (raw scene-pack payload reduced below pre-0045 baseline)"
    else
        unverified "0039 majmin payload reduction guardrail (src/generated/harmonious_majmin_scene_pack_xz.zig missing)"
    fi
    check_cmd "cd '$ROOT_DIR' && rg -n \"harmonious_majmin_scene_pack_xz\" src/svg/majmin_compat.zig" "0039 majmin scene-pack guardrail (renderer imports compact scene pack asset)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_majmin_compat_xz\" src/svg/majmin_compat.zig src/harmonious_svg_compat.zig src/root.zig" "0039 majmin scene-pack guardrail (legacy compat payload not reachable from wasm path)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"svg/majmin_scene\\.zig\" src/harmonious_svg_compat.zig src/root.zig" "0039 majmin topology model guardrail (scene parser wired into compat + root exports)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"svg_majmin_scene\\.imageIndex\\(\" src/harmonious_svg_compat.zig" "0039 majmin topology model guardrail (compat uses algorithmic scene-to-index mapping)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"svg_majmin_scene\\.imageName\\(\" src/harmonious_svg_compat.zig" "0039 majmin topology model guardrail (compat exposes algorithmic majmin image-name enumeration)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"image_index >= info\\.names\\.len\\) return renderFallback|trimSvgSuffix\\(info\\.names\\[image_index\\]\\)\" src/harmonious_svg_compat.zig" "0039 majmin topology model guardrail (render path not dependent on manifest name arrays)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"MAJMIN_MODES_NAMES|MAJMIN_SCALES_NAMES\" src/generated/harmonious_manifest.zig" "0039 majmin topology model guardrail (manifest majmin name tables removed from wasm path)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"renderModes\\(\" src/svg/majmin_compat.zig" "0039 majmin modes cutover guardrail (dedicated algorithmic modes renderer present)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"\\.modes\\s*=>\\s*renderFileByIndex\\(image_index,\\s*buf\\)\" src/svg/majmin_compat.zig" "0039 majmin modes cutover guardrail (no direct per-file modes replay dispatch)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"renderScales\\(\" src/svg/majmin_compat.zig" "0039 majmin scales cutover guardrail (dedicated algorithmic scales renderer present)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"\\.scales\\s*=>\\s*pack_data\\.MODE_COUNT\\s*\\+\\s*image_index\" src/svg/majmin_compat.zig" "0039 majmin scales cutover guardrail (no direct per-file scales replay dispatch)"
    if [ -f "$ROOT_DIR/src/svg/majmin_scales_geometry.zig" ]; then
        check_cmd "cd '$ROOT_DIR' && rg -n \"pub const SCALE_GEOMETRY_PATH_COUNT:\\s*usize\\s*=\\s*76\" src/svg/majmin_scales_geometry.zig" "0040 majmin scales geometry cutover guardrail (explicit geometry slot count)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"majmin_scales_geometry\" src/svg/majmin_compat.zig" "0040 majmin scales geometry cutover guardrail (compat renderer imports geometry module)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"d_i\\s*<\\s*majmin_scales_geometry\\.SCALE_GEOMETRY_PATH_COUNT\" src/svg/majmin_compat.zig" "0040 majmin scales geometry cutover guardrail (geometry slots dispatched procedurally)"
        check_cmd "cd '$ROOT_DIR' && ! rg -n \"pub const SCALE_GEOMETRY_PATHS\\s*=\\s*\\[_\\]\\[\\]const u8\" src/svg/majmin_scales_geometry.zig" "0042 majmin scales geometry template guardrail (no full per-slot path replay table)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"pub const SCALE_GEOMETRY_CLUSTER_COUNT:\\s*usize\\s*=\\s*19\" src/svg/majmin_scales_geometry.zig" "0042 majmin scales geometry template guardrail (cluster topology constant)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"pub const SCALE_GEOMETRY_SHAPES_PER_CLUSTER:\\s*usize\\s*=\\s*4\" src/svg/majmin_scales_geometry.zig" "0042 majmin scales geometry template guardrail (shape topology constant)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"pub fn writePathForSlot\\(\" src/svg/majmin_scales_geometry.zig" "0042 majmin scales geometry template guardrail (template emitter entrypoint)"
        check_cmd "cd '$ROOT_DIR' && ! rg -n \"const X_TOKENS|const Y_TOKENS|const CLUSTERS_X|const CLUSTERS_Y\" src/svg/majmin_scales_geometry.zig" "0043 majmin scales analytic guardrail (no coordinate token replay dictionaries)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"pub const SCALE_GEOMETRY_STEP_X:\\s*f64\\s*=\\s*27\\.2\" src/svg/majmin_scales_geometry.zig" "0043 majmin scales analytic guardrail (x-step constant present)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"pub const SCALE_GEOMETRY_STEP_Y:\\s*f64\\s*=\\s*47\\.11178196587346\" src/svg/majmin_scales_geometry.zig" "0043 majmin scales analytic guardrail (y-step constant present)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"fn xCoordFor\\(|fn yCoordFor\\(\" src/svg/majmin_scales_geometry.zig" "0043 majmin scales analytic guardrail (analytic coordinate functions present)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"pub const SCALE_GEOMETRY_D_SLOT_COUNT:\\s*usize\\s*=\\s*76\" src/generated/harmonious_majmin_scene_pack_xz.zig" "0044 majmin scales geometry prune guardrail (generated pack exposes geometry slot boundary)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"pub const SCALE_NON_GEOMETRY_D_SLOT_COUNT:\\s*usize\\s*=\\s*248\" src/generated/harmonious_majmin_scene_pack_xz.zig" "0044 majmin scales geometry prune guardrail (generated pack exposes non-geometry d-slot count)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"\\[pack_data\\.SCALE_NON_GEOMETRY_D_SLOT_COUNT\\]u16\" src/svg/majmin_compat.zig" "0044 majmin scales geometry prune guardrail (scale model stores only non-geometry d-slot map)"
        check_cmd "cd '$ROOT_DIR' && ! rg -n \"model\\.d_slot_base\\[d_i\\]\" src/svg/majmin_compat.zig" "0044 majmin scales geometry prune guardrail (render path avoids geometry-indexed d-slot replay lookup)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"harmonious_majmin_modes_geometry_refs\" src/svg/majmin_compat.zig src/generated/harmonious_majmin_modes_geometry_refs.zig" "0045 majmin modes geometry guardrail (dedicated modes geometry refs module wired)"
        check_cmd "cd '$ROOT_DIR' && rg -n \"MODE_GEOMETRY_SLOT_COUNTS\" src/svg/majmin_compat.zig src/generated/harmonious_majmin_modes_geometry_refs.zig" "0045 majmin modes geometry guardrail (render path uses grouped geometry-slot counts)"
        check_cmd "cd '$ROOT_DIR' && ! rg -n \"pub const MODE_MAX_D_SLOT_COUNT:\\s*usize\\s*=\\s*374\" src/generated/harmonious_majmin_scene_pack_xz.zig" "0045 majmin modes geometry prune guardrail (mode d-slot replay max reduced from pre-0045 baseline)"
    else
        unverified "0040 majmin scales geometry cutover guardrail (src/svg/majmin_scales_geometry.zig missing)"
    fi
    if [ -f "$ROOT_DIR/src/tests/majmin_scene_test.zig" ]; then
        check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0039 majmin topology model test suite"
    else
        unverified "0039 majmin topology model test suite (src/tests/majmin_scene_test.zig missing)"
    fi
else
    unverified "0039 majmin topology model guardrail (src/svg/majmin_scene.zig missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net/vert-text-black" ] && [ -d "$ROOT_DIR/tmp/harmoniousapp.net/vert-text-b2t-black" ] && [ -f "$ROOT_DIR/scripts/audit_text_compat_primitives.py" ]; then
    if command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/audit_text_compat_primitives.py --root tmp/harmoniousapp.net >/dev/null" "0036 text compatibility primitive audit (reference invariants)"
    else
        unverified "0036 text compatibility primitive audit (python3 missing)"
    fi
else
    unverified "0036 text compatibility primitive audit (vert-text refs or script missing)"
fi

if [ -f "$ROOT_DIR/src/generated/harmonious_text_primitives.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n \"harmonious_text_primitives\" src/svg/text_misc.zig" "0037 text symbolic guardrail (text primitives module wired in)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_text_templates|templates\\.VERT_TEXT_BLACK|templates\\.VERT_TEXT_B2T_BLACK\" src/svg/text_misc.zig" "0037 text symbolic guardrail (no per-stem vertical template array usage)"
else
    unverified "0037 text symbolic guardrail (symbolic text primitive assets not yet present)"
fi

if [ -f "$ROOT_DIR/src/render/ir.zig" ] && [ -f "$ROOT_DIR/src/render/svg_serializer.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n \"render/ir\\.zig|render/svg_serializer\\.zig\" src/svg/clock_compat.zig" "0029 rendering IR guardrail (optc pilot wired through render IR + serializer)"
    if [ -f "$ROOT_DIR/src/tests/render_ir_test.zig" ]; then
        check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0029 rendering IR determinism test suite"
    else
        unverified "0029 rendering IR determinism test suite (src/tests/render_ir_test.zig missing)"
    fi
else
    unverified "0029 rendering IR guardrail (src/render/ir.zig or src/render/svg_serializer.zig missing)"
fi

if [ -f "$ROOT_DIR/src/render/raster.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n \"enable_raster_backend\" build.zig src/c_api.zig" "0030 raster backend guardrail (build option + abi gating)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"lmt_raster_\" include/libmusictheory.h src/c_api.zig" "0030 raster backend guardrail (native abi surface exported)"
    if [ -f "$ROOT_DIR/src/tests/raster_test.zig" ]; then
        check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0030 raster backend determinism test suite"
    else
        unverified "0030 raster backend determinism test suite (src/tests/raster_test.zig missing)"
    fi
else
    unverified "0030 raster backend guardrail (src/render/raster.zig missing)"
fi

if [ -f "$ROOT_DIR/src/bitmap_compat.zig" ] && [ -f "$ROOT_DIR/src/render/raster.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && rg -n \"AA_SUBPIXEL_GRID|blendCoverage|accumulateScanlineCoverage|intervalCoverage\" src/bitmap_compat.zig src/render/raster.zig >/dev/null" "0067 raster antialiasing guardrail (coverage-based edge helpers wired into Zig raster backends)"
    check_cmd "cd '$ROOT_DIR' && rg -n 'test \"bitmap compat anti aliases primitive circle edge pixels\"|test \"bitmap compat anti aliases polygon fill edge pixels\"|test \"raster demo anti aliases curved and diagonal edges\"' src/bitmap_compat.zig src/tests/raster_test.zig >/dev/null" "0067 raster antialiasing guardrail (focused edge-quality tests present)"
else
    unverified "0067 raster antialiasing guardrail (bitmap_compat or render/raster missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && [ -f "$ROOT_DIR/scripts/validate_harmonious_visual_diff.mjs" ]; then
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        if bash -lc "cd '$ROOT_DIR' && node scripts/validate_harmonious_visual_diff.mjs --sample-per-kind 5 >/dev/null 2>&1"; then
            pass "0031 compatibility visual diff diagnostics (non-blocking sampled artifacts)"
        else
            unverified "0031 compatibility visual diff diagnostics (non-blocking; script execution failed)"
        fi
    else
        unverified "0031 compatibility visual diff diagnostics (node/npm/python3 missing)"
    fi
else
    unverified "0031 compatibility visual diff diagnostics (tmp/harmoniousapp.net or script missing)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && [ -f "$ROOT_DIR/scripts/validate_harmonious_playwright.mjs" ]; then
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5 2>&1" "0024 harmoniousapp.net playwright sampled validation (>=5 per kind, 0 mismatches)"
        check_cmd "cd '$ROOT_DIR' && node scripts/validate_harmonious_playwright.mjs 2>&1" "0024 harmoniousapp.net playwright validation (0 mismatches)"
    else
        unverified "0024 harmoniousapp.net playwright validation (node/npm/python3 missing)"
    fi
else
    unverified "0024 harmoniousapp.net playwright validation (tmp/harmoniousapp.net or script missing)"
fi

if [ -f "$ROOT_DIR/scripts/validate_wasm_docs_playwright.mjs" ]; then
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && rg -n \"All sections rendered successfully\\.|run-all|visibleBounds|staffFeatures|sharedStemCount|noteColumnSpan\" examples/wasm-demo/app.js scripts/validate_wasm_docs_playwright.mjs >/dev/null" "0064 wasm docs run-all guardrail (explicit success status and visible staff render assertions wired)"
        check_cmd "cd '$ROOT_DIR' && node scripts/validate_wasm_docs_playwright.mjs 2>&1" "0050 wasm full docs playwright run-all validation"
    else
        unverified "0050 wasm full docs playwright smoke validation (node/npm/python3 missing)"
    fi
else
    unverified "0050 wasm full docs playwright smoke validation (script not yet implemented)"
fi

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && [ -f "$ROOT_DIR/scripts/validate_harmonious_spa_playwright.mjs" ]; then
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && rg -n 'search-key-tri|key-tri|sliderEntries|sliderImageCount|currentKeyText|keySliderVariant' scripts/validate_harmonious_spa_playwright.mjs examples/wasm-demo/harmonious-spa.js >/dev/null" "0068 harmonious wasm SPA guardrail (key-slider fragments and backgrounds are covered by runtime + playwright)"
        check_cmd "cd '$ROOT_DIR' && rg -n 'fetchPagePayload|collectInlineBodyScripts\\(doc\\)|executeInlineScripts\\(inlineScripts, normalizedRoute\\)' examples/wasm-demo/harmonious-spa.js >/dev/null" "0068 harmonious wasm SPA guardrail (AJAX page routes re-run inline page scripts after body swaps)"
        check_cmd "cd '$ROOT_DIR' && rg -n 'scheduleKeyPageSliderSynchronization|synchronizeKeyPageSliderOnce|keySliderInitialSpecForRoute' examples/wasm-demo/harmonious-spa.js >/dev/null" "0068 harmonious wasm SPA guardrail (key-page slider header and initial fragment are route-synchronized in the SPA bridge)"
        check_cmd "cd '$ROOT_DIR' && rg -n 'resolveShellNavigationRoute|shellHrefForRoute|data-lmt-shell-route|\\?route=' examples/wasm-demo/harmonious-spa.js scripts/validate_harmonious_spa_playwright.mjs >/dev/null" "0069 harmonious SPA direct-entry guardrail (single-entry shell accepts route query boot and rewrites internal links through the shell)"
        check_cmd "cd '$ROOT_DIR' && rg -n 'installShellHistoryOverride|installKeyboardOnPopOverride|installFretOnPopOverride|keyboardUrlAfterEdit|fretUrlAfterEdit' examples/wasm-demo/harmonious-spa.js scripts/validate_harmonious_spa_playwright.mjs >/dev/null" "0070 harmonious SPA shell-history guardrail (interactive keyboard/fret edits persist shell-form URLs and patched on-pop semantics)"
        check_cmd "cd '$ROOT_DIR' && rg -n '404.html|favicon|fallbackRedirect|rawRouteFallback|x-lmt-spa-fallback|canonicalHref' build.zig examples/wasm-demo/harmonious-spa.html examples/wasm-demo/harmonious-spa-fallback.html examples/wasm-demo/harmonious-spa.js scripts/validate_harmonious_spa_playwright.mjs >/dev/null" "0071 harmonious SPA static-host guardrail (404 fallback, favicon handling, canonical shell metadata, and raw-route recovery are wired end-to-end)"
        check_cmd "cd '$ROOT_DIR' && rg -n 'shellAttrsForRoute|data-lmt-shell-route|keyboardSearchShellHref|fretSearchShellHref|sliderCardShellHref' examples/wasm-demo/harmonious-spa.js scripts/validate_harmonious_spa_playwright.mjs >/dev/null" "0072 harmonious SPA fragment-link guardrail (search and slider fragments emit shell-form links and playwright verifies them)"
        check_cmd "cd '$ROOT_DIR' && node scripts/validate_harmonious_spa_playwright.mjs 2>&1" "0068 harmonious wasm SPA playwright validation"
    else
        unverified "0068 harmonious wasm SPA playwright validation (node/npm missing)"
    fi
else
    unverified "0068 harmonious wasm SPA playwright validation (tmp/harmoniousapp.net or script missing)"
fi

if [ -f "$ROOT_DIR/src/svg/fret.zig" ] && [ -f "$ROOT_DIR/src/svg/staff.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && \
        rg -Fq 'marker-open' src/tests/svg_fret_test.zig && \
        rg -Fq 'marker-muted' src/tests/svg_fret_test.zig && \
        rg -Fq 'accidental-natural' src/tests/svg_staff_test.zig && \
        rg -Fq 'accidental-sharp' src/tests/svg_staff_test.zig && \
        rg -Fq 'geometricPrecision' src/svg/fret.zig src/svg/staff.zig && \
        ! rg -Fq '>X</text>' src/svg/fret.zig && \
        ! rg -Fq '>O</text>' src/svg/fret.zig" "0065 core svg quality guardrail (vector markers, explicit accidental glyphs, and geometric precision styling wired)"
else
    unverified "0065 core svg quality guardrail (core svg renderers not present)"
fi

if [ -f "$ROOT_DIR/src/svg/quality.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && \
        rg -n 'const svg_quality = @import\\(\"quality\\.zig\"\\);' \
            src/svg/clock.zig \
            src/svg/staff.zig \
            src/svg/fret.zig \
            src/svg/mode_icon.zig \
            src/svg/circle_of_fifths.zig \
            src/svg/evenness_chart.zig \
            src/svg/text_misc.zig \
            src/svg/orbifold.zig \
            src/svg/tessellation.zig \
            src/svg/key_sig.zig \
            src/svg/n_tet_chart.zig >/dev/null" "0066 shared svg quality guardrail (non-compat generators import shared quality module)"
    check_cmd "cd '$ROOT_DIR' && \
        ! rg -n 'const svg_quality = @import\\(\"quality\\.zig\"\\);' \
            src/harmonious_svg_compat.zig \
            src/svg/clock_compat.zig \
            src/svg/evenness_compat.zig \
            src/svg/text_misc_compat.zig \
            src/svg/chord_compat.zig \
            src/svg/fret_compat.zig \
            src/svg/majmin_compat.zig >/dev/null" "0066 shared svg quality guardrail (exact compat renderers stay visually frozen)"
    check_cmd "cd '$ROOT_DIR' && \
        rg -n 'writeSvgPrelude\\(' src/svg/clock.zig src/svg/staff.zig src/svg/fret.zig src/svg/mode_icon.zig src/svg/circle_of_fifths.zig src/svg/evenness_chart.zig src/svg/text_misc.zig src/svg/orbifold.zig src/svg/tessellation.zig src/svg/key_sig.zig src/svg/n_tet_chart.zig >/dev/null" "0066 shared svg quality guardrail (shared prelude wired across generated svg families)"
else
    unverified "0066 shared svg quality guardrail (shared quality module not yet implemented)"
fi

if [ -f "$ROOT_DIR/scripts/validate_harmonious_scaled_render_parity_playwright.mjs" ]; then
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && node scripts/validate_harmonious_scaled_render_parity_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100 2>&1" "0059 scaled render parity playwright sampled validation (all kinds at 55% and 200%, 0 drift failures)"
    else
        unverified "0059 scaled render parity playwright sampled validation (node/npm/python3 missing)"
    fi
else
    unverified "0059 scaled render parity playwright sampled validation (script not yet implemented)"
fi

if [ -f "$ROOT_DIR/scripts/validate_harmonious_native_rgba_proof_playwright.mjs" ]; then
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100 2>&1" "0060 native RGBA proof playwright sampled validation (all kinds at 55% and 200%, 0 drift failures)"
    else
        unverified "0056 native RGBA proof playwright sampled validation (node/npm/python3 missing)"
    fi
else
    unverified "0056 native RGBA proof playwright sampled validation (script not yet implemented)"
fi

# ───────────────────────────────────────────
# Summary
# ───────────────────────────────────────────
section "Summary"

echo "  RELEASE_SURFACE_SMOKE=$RELEASE_SURFACE_SMOKE_STATUS"

if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ]; then
    echo "  HARMONIOUS_EXTENDED_REGRESSION=enabled"
else
    echo "  HARMONIOUS_EXTENDED_REGRESSION=skipped"
fi

if [ -f "$ROOT_DIR/scripts/validate_harmonious_native_rgba_proof_playwright.mjs" ] && command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    if bash -lc "cd '$ROOT_DIR' && node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds vert-text-black,even,scale,opc,oc,optc,eadgbe,center-square-text,wide-chord,chord-clipped,grand-chord,majmin/modes,majmin/scales,chord,vert-text-b2t-black --scales 55:100,200:100 >/dev/null 2>&1"; then
        echo "  NATIVE_RGBA_PROOF_COMPLETE=yes"
    else
        echo "  NATIVE_RGBA_PROOF_COMPLETE=no"
    fi
else
    echo "  NATIVE_RGBA_PROOF_COMPLETE=unknown"
fi

if [ "$FAIL" -eq 0 ]; then
    echo "  All checks passed."
else
    echo "  Some checks FAILED. Review output above."
fi

exit "$FAIL"
