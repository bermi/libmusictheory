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
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"harmonious_even_gzip\" src/svg/evenness_chart.zig" "0035 even compat guardrail (no monolithic even gzip replay import when segmented assets exist)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"harmonious_even_segment_xz\" src/svg/evenness_chart.zig" "0035 even compat guardrail (segmented even xz module wired in)"
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

if [ -f "$ROOT_DIR/examples/wasm-demo/scaled-render-parity.html" ] && rg -Fq 'step("wasm-scaled-render-parity"' "$ROOT_DIR/build.zig"; then
    check_cmd "cd '$ROOT_DIR' && zig build wasm-scaled-render-parity 2>&1" "0059 scaled render parity bundle build"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"\\.scale\\(|transform:\\s*scale|style\\.transform\" examples/wasm-demo/scaled-render-parity.js" "0059 scaled render parity anti-cheat guardrail (no css/post-bitmap scaling shortcut)"
    check_cmd "cd '$ROOT_DIR' && rg -n \"lmt_svg_compat_generate|rasterizeSvgAtSize|drawImage\\(img, 0, 0, width, height\\)\" examples/wasm-demo/scaled-render-parity.js" "0059 scaled render parity guardrail (generated SVG candidate rasterized directly at target size)"
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
    if [ -f "$ROOT_DIR/scripts/check_wasm_exports.mjs" ] && command -v node >/dev/null 2>&1; then
        check_cmd "cd '$ROOT_DIR' && test -f zig-out/wasm-native-rgba-proof/libmusictheory.wasm && node scripts/check_wasm_exports.mjs --profile native_rgba_proof --wasm zig-out/wasm-native-rgba-proof/libmusictheory.wasm" "0060 native RGBA proof export guardrail (required exports are present)"
    else
        unverified "0060 native RGBA proof export guardrail (scripts/check_wasm_exports.mjs or node missing)"
    fi
    if [ -d "$ROOT_DIR/tmp/harmoniousapp.net" ] && rg -Fq 'wasm-native-rgba-proof/tmp/harmoniousapp.net' "$ROOT_DIR/build.zig"; then
        check_cmd "cd '$ROOT_DIR' && test -d zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/opc/047,0,0,0.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/center-square-text/A.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/vert-text-black/6-9.svg && test -f zig-out/wasm-native-rgba-proof/tmp/harmoniousapp.net/vert-text-b2t-black/6-9.svg" "0060 native RGBA proof bundle guardrail (local harmonious refs mirrored into proof output)"
    else
        unverified "0060 native RGBA proof bundle guardrail (proof ref mirror not yet implemented)"
    fi
else
    unverified "0060 native RGBA proof bundle build (target not yet implemented)"
fi

if [ -f "$ROOT_DIR/examples/wasm-demo/scaled-render-parity.html" ] && [ -f "$ROOT_DIR/examples/wasm-demo/native-rgba-proof.html" ]; then
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"svg-raster|SVG raster\" examples/wasm-demo/README.md examples/wasm-demo/scaled-render-parity.html examples/wasm-demo/scaled-render-parity.js examples/wasm-demo/native-rgba-proof.html examples/wasm-demo/native-rgba-proof.js scripts/validate_harmonious_scaled_render_parity_playwright.mjs scripts/validate_harmonious_native_rgba_proof_playwright.mjs docs/plans/drafts docs/plans/in_progress -g '!*/completed/*'" "0060 terminology guardrail (no svg-raster term in active surfaces)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"bitmap-proof|Bitmap proof|bitmap proof|wasm-bitmap-proof|__lmtLastBitmapProof|validate_harmonious_bitmap_playwright\" build.zig examples/wasm-demo/README.md examples/wasm-demo scripts docs/plans/drafts docs/plans/in_progress -g '!*/completed/*'" "0060 terminology guardrail (no active bitmap-proof naming remains)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"\\bproof\\b|Proof\" examples/wasm-demo/scaled-render-parity.html examples/wasm-demo/scaled-render-parity.js" "0060 terminology guardrail (scaled render parity surface does not claim proof)"
    check_cmd "cd '$ROOT_DIR' && ! rg -n \"generated-svg\" examples/wasm-demo/native-rgba-proof.html examples/wasm-demo/native-rgba-proof.js" "0060 terminology guardrail (native RGBA proof surface does not advertise generated SVG)"
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
    check_cmd "cd '$ROOT_DIR' && rg -n \"render/ir\\.zig|render/svg_serializer\\.zig\" src/svg/clock.zig" "0029 rendering IR guardrail (optc pilot wired through render IR + serializer)"
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
        check_cmd "cd '$ROOT_DIR' && node scripts/validate_wasm_docs_playwright.mjs 2>&1" "0050 wasm full docs playwright smoke validation"
    else
        unverified "0050 wasm full docs playwright smoke validation (node/npm/python3 missing)"
    fi
else
    unverified "0050 wasm full docs playwright smoke validation (script not yet implemented)"
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
        check_cmd "cd '$ROOT_DIR' && node scripts/validate_harmonious_native_rgba_proof_playwright.mjs --sample-per-kind 5 --kinds opc,optc,center-square-text,vert-text-black,vert-text-b2t-black --scales 55:100,200:100 2>&1" "0056 native RGBA proof playwright sampled validation (supported simple families + text at 55% and 200%, 0 drift failures)"
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
