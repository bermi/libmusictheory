# 0022 — Comprehensive Testing

> Dependencies: ALL previous plans
> Blocks: None (final validation)

## Objective

Build a comprehensive test suite validating all library functionality against the harmoniousapp.net source data and published music theory references.

## Testing Strategy

### 1. Unit Tests (per module)

Each `src/*.zig` file has corresponding `src/tests/*_test.zig`:
- Pitch class operations
- Set operations (all bitwise functions)
- Set classification (336 classes, 208 Forte, 115 OPTIC/K)
- Interval vectors and FC-components
- Cluster detection (124 cluster-free)
- Evenness metrics
- Scale/mode identification (17 modes)
- Key signatures (15 keys)
- Note spelling (35 name mappings)
- Chord construction (~100 types)
- The Game (479 objects, ~1000 matches)
- Voice leading distances
- Guitar fret mapping
- Keyboard state

### 2. Integration Tests

- Chord-in-key analysis: every chord in every key correctly named
- Scale-chord compatibility: correct avoid notes for all 7 modes
- CAGED positions: all 5 shapes × 12 roots produce valid voicings
- SVG generation: output is valid XML, dimensions match expected

### 3. Reference Data Tests

Extract verification data from harmoniousapp.net:

```
// From tmp/harmoniousapp.net/p/71/Set-Classes.html
test "set class table matches site" {
    // 3-11 (major/minor triad): IV = <001110>, FC values match
    const sc = SetClassTable.lookupForte(.{.cardinality = 3, .ordinal = 11});
    try std.testing.expectEqual(sc.interval_vector, .{0, 0, 1, 1, 1, 0});
}

// From tmp/harmoniousapp.net/p/8b/Cluster-free.html
test "cluster-free count" {
    var count: usize = 0;
    for (SET_CLASSES) |sc| {
        if (sc.is_cluster_free) count += 1;
    }
    try std.testing.expectEqual(count, 124);
}

// From tmp/harmoniousapp.net/p/69/The-Game.html
test "the game produces correct counts" {
    const results = TheGame.run();
    try std.testing.expectEqual(results.cluster_free_otc, 560);
    try std.testing.expectEqual(results.mode_subsets, 479);
}
```

### 4. Property-Based Tests

- Complement invariance: FC(x) = FC(complement(x)) for all x
- M5 self-inverse: m5(m5(x)) = x for all x
- Transposition cycle: transpose(x, 12) = x for all x
- Inversion involution: invert(invert(x)) = x for all x
- Cardinality: card(complement(x)) = 12 - card(x)
- Prime form stability: primeForm(primeForm(x)) = primeForm(x)

### 5. Fuzz Tests

- Random PCS inputs to all functions — no panics, no undefined behavior
- Random MIDI notes through spelling pipeline
- Random guitar fret positions

### 6. Benchmark Tests

- PCS operations: verify O(1) performance
- Set class lookup: verify constant time
- SVG generation: measure throughput (target: 10,000+ SVGs/second)
- Full enumeration: 4096 PCS classification < 1ms

### 7. Site Data Extraction Script

Create a script that:
1. Parses HTML from `tmp/harmoniousapp.net/p/71/Set-Classes.html` to extract Forte numbers, IV, FC values
2. Parses `tmp/harmoniousapp.net/p/69/The-Game.html` to extract expected chord-mode counts
3. Generates Zig test data files for automated verification

## Test File Organization

```
src/tests/
  pitch_test.zig
  pcs_test.zig
  set_class_test.zig
  interval_test.zig
  cluster_test.zig
  evenness_test.zig
  scale_test.zig
  mode_test.zig
  key_test.zig
  spelling_test.zig
  chord_test.zig
  game_test.zig
  harmony_test.zig
  voice_leading_test.zig
  guitar_test.zig
  keyboard_test.zig
  svg_test.zig
  integration_test.zig
  reference_data_test.zig
  property_test.zig
```

## Success Criteria

- 100% of unit tests pass
- All 336 set classes match published Forte catalog
- All 124 cluster-free set classes verified
- All 17 mode types correctly identified
- The Game algorithm produces exactly 479 mode-subset matches
- Note spelling matches site for all 70+ key contexts
- All SVG outputs are valid XML
- Zero memory leaks in C ABI usage
- No panics under fuzz testing

## Verification Protocol

Before implementing any step in this plan:
1. Read `CONSTRAINTS.md` in full.
2. Update `./verify.sh` so the target behavior is checked programmatically.
3. Run `./verify.sh` as baseline (must pass before changes).
4. Write tests first when feasible (red → green flow).
5. Implement the change.
6. Run `./verify.sh` again — do not declare success unless it passes.

## Exit Criteria

- `./verify.sh` passes
- `zig build verify` passes
- 100% of unit tests pass
- All 336 set classes match music21 Forte catalog
- All 124 cluster-free set classes verified
- All 17 mode types correctly identified
- The Game produces exactly 479 mode-subset matches
- Note spelling matches harmoniousapp.net for all 70+ key contexts
- All SVG outputs are valid XML
- Zero panics under fuzz testing

## Verification Data Sources

- **music21** (`/Users/bermi/tmp/music21/music21/chord/tables.py`) — 224 Forte entries, interval vectors, prime forms
- **tonal-ts** (`/Users/bermi/tmp/tonal-ts/packages/dictionary/data/`) — 102 scales, 116 chords
- **harmoniousapp.net**:
  - `tmp/harmoniousapp.net/p/71/Set-Classes.html`
  - `tmp/harmoniousapp.net/p/69/The-Game.html`
  - `tmp/harmoniousapp.net/p/8b/Cluster-free.html`
  - All SVG directories

## Implementation History (Point-in-Time)

- `d764ee5` (2026-02-16):
  - Shipped behavior: added cross-module integration tests (`src/tests/integration_test.zig`), reference spot-check tests (`src/tests/reference_data_test.zig`), property/fuzz tests over all 4096 pitch-class sets (`src/tests/property_test.zig`), and a local data extraction utility (`scripts/extract_reference_data.py`) integrated via new `verify.sh` gates.
  - Verification: `./verify.sh` passes, `zig build verify` passes.

## Estimated Scope

- ~2,000 lines of test code across 20 test files
- ~200 lines of reference data extraction script
