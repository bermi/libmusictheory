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
