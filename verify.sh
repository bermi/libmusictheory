#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

FAIL=0

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
    if bash -lc "$cmd"; then
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

if [ -f "$ROOT_DIR/src/tests/svg_harmonious_compat_test.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build test 2>&1" "0024 harmoniousapp.net compatibility test suite"
else
    unverified "0024 harmoniousapp.net compatibility test suite (src/tests/svg_harmonious_compat_test.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/validation.html" ]; then
    check_cmd "cd '$ROOT_DIR' && zig build wasm-demo 2>&1" "0024 wasm validation page build"
else
    unverified "0024 wasm validation page build (examples/wasm-demo/validation.html not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/harmonious_svg_compat.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"@embedFile\\(|tmp/harmoniousapp\\.net|harmonious_embed_refs\" src/harmonious_svg_compat.zig" "0028 compatibility generator anti-embed guardrail"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"\\.majmin_modes, \\.majmin_scales => svg_tessellation\\.renderScaleTessellation\\(buf\\)\" src/harmonious_svg_compat.zig" "0028 majmin compat guardrail (no placeholder tessellation fallback)"
else
    unverified "0028 compatibility generator anti-embed guardrail (src/harmonious_svg_compat.zig not yet implemented)"
fi

if [ -f "$ROOT_DIR/src/svg/scale_nomod_compat.zig" ] && [ -f "$ROOT_DIR/src/harmonious_svg_compat.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"renderScaleStaffByIndex|SCALE_X_BY_INDEX|harmonious_scale_x_by_index\" src/harmonious_svg_compat.zig src/svg/scale_nomod_compat.zig" "0028 scale algorithmic layout guardrail (no index-based x replay)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"std\\.mem\\.eql\\(u8, stem,\" src/svg/scale_nomod_compat.zig" "0028 scale algorithmic layout guardrail (no stem-specific hardcoded exceptions)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_scale_nomod_profile_tuning|harmonious_scale_nomod_names|harmonious_scale_nomod_keysig_lines|SCALE_PROFILE_TUNINGS|layoutTuning\\(|stepUlpNudge\\(|isNoModStem\\(\" src/svg/scale_nomod_compat.zig" "0032 scale pure algorithmic guardrail (no replay tuning/name/keysig tables)"
else
    unverified "0028 scale algorithmic layout guardrail (scale compat sources missing)"
fi

if [ -f "$ROOT_DIR/src/svg/chord_compat.zig" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"std\\.mem\\.eql\\(u8, stem,\" src/svg/chord_compat.zig" "0028 chord algorithmic layout guardrail (no stem-specific hardcoded exceptions)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"@embedFile\\(|tmp/harmoniousapp\\.net\" src/svg/chord_compat.zig" "0028 chord algorithmic layout guardrail (no embedded/svg reference payloads)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_chord_mod_x_lookup|harmonious_chord_mod_y_lookup|harmonious_whole_note_x_lookup|harmonious_whole_note_y_lookup\" src/svg/chord_compat.zig" "0032 chord algorithmic layout guardrail (no x/y lookup coordinate replay tables)"
else
    unverified "0028 chord algorithmic layout guardrail (src/svg/chord_compat.zig missing)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/index.html" ]; then
    check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-demo/libmusictheory.wasm && [ \"$(wc -c < zig-out/wasm-demo/libmusictheory.wasm | tr -d '[:space:]')\" -lt 1048576 ]" "0028 wasm demo size guardrail (<1MB)"
    if [ -f "$ROOT_DIR/scripts/wasm_size_audit.py" ] && command -v python3 >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && python3 scripts/wasm_size_audit.py --wasm zig-out/wasm-demo/libmusictheory.wasm --max-wasm-bytes 900000 --max-data-bytes 760000 --max-reachable-generated-bytes 1800000 --max-coordinate-generated-bytes 170000" "0032 wasm size audit guardrail (section + generated footprint budgets)"
    else
        unverified "0032 wasm size audit guardrail (scripts/wasm_size_audit.py or python3 missing)"
    fi
else
    unverified "0028 wasm demo size guardrail (<1MB) (examples/wasm-demo/index.html not yet implemented)"
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

# ───────────────────────────────────────────
# Summary
# ───────────────────────────────────────────
section "Summary"

if [ "$FAIL" -eq 0 ]; then
    echo "  All checks passed."
else
    echo "  Some checks FAILED. Review output above."
fi

exit "$FAIL"
