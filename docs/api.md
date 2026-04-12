# libmusictheory API Reference

`libmusictheory` is a deterministic, no-allocation-first music-theory library for symbolic reasoning, instrument-aware practice logic, and renderable theory outputs.

This document is the single consumer-facing reference for the library surface. It covers:

- the public Zig namespaces exported by `src/root.zig`
- the stable and experimental C ABI in `include/libmusictheory.h`
- the browser/WASM entry pattern
- the internal compatibility/proof helpers that exist in-repo but are not the product contract

## Goals

The library is designed for:

- LLM agents that need deterministic note, chord, scale, and voice-leading transforms
- practice and composition apps that need next-note guidance, spelling, voicings, and fingering logic
- headless DAWs and backend services that need stable, embeddable music-theory operations and image generation

## Surface Map

| Surface | Status | Primary use |
| --- | --- | --- |
| Zig modules exported by `src/root.zig` | Stable except where noted | Native Zig integrations |
| `include/libmusictheory.h` stable functions | Stable | C/C++, Rust FFI, Python, Swift, JS/WASM wrappers |
| Ordered-scale pedagogy, playability state, counterpoint state, ranking, direct RGBA helpers | Experimental | Exploratory apps and richer assistants |
| `harmonious_svg_compat`, `bitmap_compat`, `include/libmusictheory_compat.h` | Internal/proof | Regression and parity tooling |

## Shared Conventions

- Pitch classes are `0...11`.
  `0=C`, `1=C# / Db`, `11=B`.
- MIDI notes are `0...127`.
  `60` is `C4`.
- `pitch_class_set.PitchClassSet` is a `u12` bitset.
- Most Zig APIs write into caller-owned fixed buffers and return the written slice.
- Stable C string-returning functions use shared rotating storage.
  Copy returned strings if you need to keep them.
- Stable SVG C writers support a sizing pass.
  Call with `buf = NULL` and `buf_size = 0` to get the required byte count.
- Count-returning C APIs usually return the logical total even when your output buffer is smaller.
- Musical degree results in the C API are `1`-based, and `0` means "not found".
- Experimental `uint32_t` helpers usually return `1` on success and `0` on invalid input, disabled backends, or insufficient output capacity unless documented as returning a logical total count.

## Recommended Entry Points

If you are building an agent, theory service, practice app, or headless DAW, start here:

- set reasoning: `pitch_class_set`, `set_class`, `forte`, `interval_vector`, `cluster`, `evenness`
- tonal context: `ordered_scale`, `scale`, `mode`, `key`, `note_spelling`
- harmony: `chord_detection`, `chord_construction`, `harmony`, `voice_leading`
- instrument logic: `guitar`, `keyboard`, `playability`
- output: `svg_clock`, `svg_staff`, `svg_fret`, `svg_keyboard`

Minimal Zig example:

```zig
const std = @import("std");
const lmt = @import("libmusictheory");

pub fn main() !void {
    const set = lmt.pitch_class_set.fromList(&.{ 0, 4, 7 });
    const prime = lmt.set_class.primeForm(set);
    const name = lmt.chord_construction.pcsToChordName(set) orelse "Unknown";
    std.debug.print("set=0x{x} prime=0x{x} name={s}\n", .{ set, prime, name });
}
```

Minimal stable C SVG sizing pass:

```c
lmt_pitch_class_set set = lmt_chord(LMT_CHORD_MAJOR, 0);
uint32_t needed = lmt_svg_clock_optc(set, NULL, 0);
char *svg = malloc(needed + 1);
uint32_t total = lmt_svg_clock_optc(set, svg, needed + 1);
```

## Zig Reference

### Core Pitch And Naming

Important values:

- `pitch.PitchClass`, `pitch.MidiNote`, `pitch.Interval`, `pitch.IntervalClass`
- `pitch.pc.{C,Cs,D,Ds,E,F,Fs,G,Gs,A,As,B}`
- `note_name.{Letter,Accidental,NoteName,SpelledNote,AccidentalPreference}`
- `interval.FormulaToken`

| Symbol(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `pitch.midiToPC`, `pitch.midiToOctave`, `pitch.pcToMidi`, `pitch.midiToFrequency`, `pitch.toIntervalClass`, `pitch.wrapPitchClass` | note or pitch-class primitives | pitch class, octave, MIDI, frequency, or normalized interval class | `pitch.pcToMidi(pitch.pc.C, 4)` | Normalize MIDI, build MIDI from symbolic notes, and convert to audio-engine frequencies. |
| `note_name.chooseName`, `note_name.NoteName.toPitchClass`, `note_name.NoteName.format`, `note_name.SpelledNote.toMidi` | pitch class plus accidental preference, or note-name values | note-name objects, pitch classes, formatted text, MIDI | `note_name.chooseName(10, .flats)` | Spell and format notes quickly when you only need enharmonic naming. |
| `note_spelling.spellWithPreference`, `note_spelling.spellNote`, `note_spelling.autoSpell` | pitch classes, preferences, key contexts, output buffers | spelled note names or batch-spell results | `note_spelling.spellNote(1, key.Key.init(0, .major))` | Spell notes with key-sensitive bias for prompts, notation, and analysis text. |
| `interval.semitones` | `token: FormulaToken` | `u8` semitone offset | `interval.semitones(.flat9)` | Parse interval and chord-formula tokens into semitone offsets. |

### Pitch-Class Sets And Classification

Important values:

- `pitch_class_set.{EMPTY,CHROMATIC,C_MAJOR_TRIAD,C_MINOR_TRIAD,DIATONIC,C_MAJOR_PENTATONIC,PENTATONIC}`
- `forte.ENTRIES`
- `set_class.SET_CLASSES`
- `interval_analysis.{INTERVAL_VECTOR_TABLE,FC_COMPONENT_TABLE}`
- `cluster.CLUSTER_INFO_TABLE`
- `evenness.EVENNESS_INFO_TABLE`
- `even_compat_model.DISPLAY_ENTRY_COUNT`

| Symbol(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `pitch_class_set.fromList`, `pitch_class_set.toList`, `pitch_class_set.cardinality`, `pitch_class_set.format` | pitch-class lists, sets, output buffers | sets, list slices, counts, formatted ASCII | `pitch_class_set.fromList(&.{0,4,7})` | Convert between symbolic note lists and compact `u12` set storage. |
| `pitch_class_set.transpose`, `pitch_class_set.transposeDown`, `pitch_class_set.invert`, `pitch_class_set.complement` | set plus interval or inversion | transformed `PitchClassSet` | `pitch_class_set.transpose(set, 2)` | Generate transpositions, inversions, complements, and root-normalized views. |
| `pitch_class_set.isSubsetOf`, `pitch_class_set.union_`, `pitch_class_set.intersection`, `pitch_class_set.hammingDistance`, `pitch_class_set.hasSub` | one or two sets | booleans, merged sets, intersections, distances | `pitch_class_set.isSubsetOf(triad, scale)` | Check containment, overlap, and similarity between harmonic or melodic collections. |
| `pitch_class_set.allRotations`, `pitch_class_set.leastError` | set or candidate-set array plus target | rotations or best-fit set | `pitch_class_set.allRotations(set)` | Enumerate related set states or choose the closest interpretation of noisy input. |
| `forte.lookup` | canonical prime form | `?ForteNumber` | `forte.lookup(set_class.fortePrime(set))` | Convert canonical forms into Forte labels. |
| `set_class.primeForm`, `set_class.fortePrime`, `set_class.numTranspositions`, `set_class.isLimitedTransposition`, `set_class.isSymmetric`, `set_class.countOpticClasses`, `set_class.countOpticKGroups` | set or none | canonical forms, symmetry flags, catalog counts | `set_class.isLimitedTransposition(set)` | Compute set-class identity and catalog sizing information. |
| `interval_vector.compute`, `fc_components.compute` | set | interval vector or Fourier components | `interval_vector.compute(set)` | Drive interval-content analysis, consonance work, and geometry views. |
| `interval_analysis.m5Transform`, `interval_analysis.m7Transform`, `interval_analysis.isZRelated`, `interval_analysis.isMRelated` | one or two sets | transformed set or boolean relation | `interval_analysis.isZRelated(a, b)` | Inspect multiplication-related and Z-related set behavior. |
| `cluster.hasCluster`, `cluster.getClusters`, `cluster.clusterStats` | set and optional output buffer | booleans, cluster info, cluster-run summary | `cluster.clusterStats(set, &runs)` | Detect dense chromatic adjacency for pedagogy or filtering. |
| `evenness.evennessDistance`, `evenness.isPerfectlyEven`, `evenness.isMaximallyEven`, `evenness.consonanceScore` | set | floating-point scores or booleans | `evenness.evennessDistance(set)` | Rank how evenly a collection spans the octave. |
| `even_compat_model.isOpticRepresentative`, `even_compat_model.isSelfComplementary`, `even_compat_model.isSelfComplementarySymmetricHexachord`, `even_compat_model.includeInDisplayDomain`, `even_compat_model.classifyIndexMarker`, `even_compat_model.enumerateDisplayDomain`, `even_compat_model.cardinalityHistogram`, `even_compat_model.countBorder` | set-class entry or display-domain buffers | booleans, markers, slices, counts | `even_compat_model.enumerateDisplayDomain(&out)` | Build evenness-atlas and OPTIC-style display catalogs. |

### Scales, Modes, Keys, And Spelling Context

Important values:

- `ordered_scale.ALL_PATTERNS`
- `scale.ScaleType`
- `mode.ALL_MODES`
- `key_signature.{KeyQuality,SignatureType,MAJOR_SIGNATURES}`

| Symbol(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `ordered_scale.OrderedScaleInfo.slice`, `ordered_scale.info`, `ordered_scale.count`, `ordered_scale.fromInt`, `ordered_scale.offsetsFor` | pattern IDs or ordered-scale info | pattern metadata, counts, offsets | `ordered_scale.offsetsFor(.harmonic_minor)` | Enumerate and inspect supported ordered-scale families. |
| `ordered_scale.rootedPitchClassSet`, `ordered_scale.modePitchClassSet`, `ordered_scale.modeOffsets` | pattern ID, tonic or degree, output buffer | rooted set or offsets slice | `ordered_scale.modePitchClassSet(.diatonic, 4)` | Build rooted scales and their modal rotations. |
| `ordered_scale.degreeIndexForOffsets`, `ordered_scale.degreeIndexForPitchClass`, `ordered_scale.transposeMidiByDegrees`, `ordered_scale.nearestScaleNeighbors`, `ordered_scale.snapToScale` | offsets, tonic, note or note pc, optional policy | degree index, transposed MIDI, neighbor info, snapped note | `ordered_scale.snapToScale(offsets, 0, 61, .higher)` | Implement degree-aware transposition and scale-quantization logic. |
| `ordered_scale.isBarryHarris`, `ordered_scale.barryHarrisParity` | pattern ID, tonic, note | boolean or parity classification | `ordered_scale.barryHarrisParity(.barry_harris_major_sixth_diminished, 0, 60)` | Distinguish chord tones from passing tones in Barry Harris patterns. |
| `scale.Scale.init`, `scale.Scale.mode`, `scale.pcsForType`, `scale.identifyScaleType`, `scale.isScaley` | scale types, roots, degrees, or sets | scale objects, modes, identified types, booleans | `scale.Scale.init(.diatonic, 0).mode(4)` | Move between named scale families and rooted scale objects. |
| `mode.identifyMode`, `mode.info`, `mode.name`, `mode.count`, `mode.fromInt`, `mode.offsets` | rooted sets, mode IDs, output buffers | mode type, mode info, names, counts, offsets | `mode.identifyMode(pitch_class_set.fromList(&.{0,2,3,5,7,9,10}))` | Turn rooted pitch-class sets into named modes. |
| `mode.degreeOfNote`, `mode.degreeOfPitchClass`, `mode.transposeDiatonic`, `mode.nearestScaleNeighbors`, `mode.snapToScale` | tonic, mode, note or note pc, policy | degree index, transposed MIDI, neighbor info, snapped note | `mode.transposeDiatonic(0, .dorian, 62, 2)` | Build degree-aware MIDI features without manual ordered-scale offsets. |
| `modal_interchange.findContainingModes` | note pc, tonic, candidate modes, output buffer | logical match count | `modal_interchange.findContainingModes(1, 0, mode.ALL_MODES[0..], out[0..])` | Ask which modal contexts contain a borrowed pitch. |
| `key_signature.fromTonic` | tonic, key quality | `KeySignature` | `key_signature.fromTonic(0, .major)` | Convert tonics into sharps/flats counts. |
| `key.Key.init`, `key.Key.relativeMajor`, `key.Key.relativeMinor`, `key.Key.parallelKey`, `key.Key.nextKeySharp`, `key.Key.nextKeyFlat` | tonic, quality, or existing `Key` values | `Key` | `key.Key.init(9, .minor).relativeMajor()` | Walk the circle of fifths and major/minor relationships. |

### Chords, Harmony, And Voice Leading

Important values:

- `chord_type.{MAJOR,MINOR,DIMINISHED,AUGMENTED,ALL}`
- `chord_detection.ALL_PATTERNS`
- `harmony.{CIRCLE_OF_FIFTHS_DEGREES,CIRCLE_OF_THIRDS_DEGREES}`

| Symbol(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `chord_construction.formulaToPCS`, `chord_construction.pcsToChordName`, `chord_construction.detectInversion`, `chord_construction.shellChord`, `chord_construction.leaveOneOut`, `chord_construction.computeGameStats` | formulas, sets, bass pitch class, root, output buffers | sets, names, inversion labels, shell chords, alternate sets, stats | `chord_construction.formulaToPCS("1 b3 5 b7")` | Parse chord formulas and derive chord labels or simplified voicings. |
| `chord_detection.count`, `chord_detection.pattern`, `chord_detection.fromInt`, `chord_detection.detectMatches` | pattern IDs, sets, bass flags, output buffers | counts, pattern metadata, match slices | `chord_detection.detectMatches(set, true, 0, out[0..])` | Return multiple ranked chord interpretations for a sonority. |
| `harmony.DiatonicHarmony.init`, `harmony.RomanNumeral.format`, `harmony.keyScaleSet`, `harmony.diatonicTriad`, `harmony.diatonicSeventh`, `harmony.romanNumeral`, `harmony.chordScaleCompatibility`, `harmony.tritoneSub` | key or chord context, degrees, output buffers | harmony objects, roman-numeral strings, compatibility reports | `harmony.romanNumeral(chord, key_ctx)` | Build diatonic harmony, roman-numeral analysis, and chord-scale compatibility. |
| `voice_leading.voiceDistance`, `voice_leading.vlDistance`, `voice_leading.uncrossedVoiceLeadings`, `voice_leading.avgVLDistance`, `voice_leading.vlGraph`, `voice_leading.graphIsConnected`, `voice_leading.diatonicFifthsCircuit`, `voice_leading.diatonicThirdsCircuit`, `voice_leading.orbifoldRadius` | notes, sets, node buffers, edge buffers, keys | distances, assignment slices, graphs, circuits, geometry scalars | `voice_leading.vlDistance(a, b)` | Measure voice-leading smoothness and build harmonic-motion graphs. |

### Counterpoint, Rule Checking, And SATB Helpers (Experimental)

Important values:

- `counterpoint.{MAX_VOICES,HISTORY_CAPACITY,MAX_NEXT_STEP_SUGGESTIONS,MAX_CADENCE_DESTINATIONS}`
- `counterpoint.{NEXT_STEP_REASON_NAMES,NEXT_STEP_WARNING_NAMES,CADENCE_DESTINATION_NAMES,SUSPENSION_STATE_NAMES}`
- `voice_leading_rules.{MAX_VOICE_PAIR_VIOLATIONS,VIOLATION_KIND_NAMES}`
- `choir.SATB_VOICE_NAMES`

| Symbol(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `counterpoint.MetricPosition.normalized`, `counterpoint.MotionSummary.init`, `counterpoint.SuspensionMachineSummary.init`, `counterpoint.VoicedState.initEmpty`, `counterpoint.VoicedState.slice` | metric fields or existing state | normalized metric or zeroed state/slices | `counterpoint.VoicedState.initEmpty(0, .ionian, metric)` | Seed stateful analysis and normalize metric position. |
| `counterpoint.VoicedHistoryWindow.init`, `counterpoint.VoicedHistoryWindow.reset`, `counterpoint.VoicedHistoryWindow.current`, `counterpoint.VoicedHistoryWindow.previous`, `counterpoint.VoicedHistoryWindow.push` | history state, note lists, context, cadence hints | rolling history state and newest snapshot | `history.push(notes, sustained, 0, .ionian, metric, null)` | Maintain rolling counterpoint state from live MIDI or score playback. |
| `counterpoint.buildVoicedState`, `counterpoint.inferCadenceState`, `counterpoint.classifyMotion`, `counterpoint.evaluateMotionProfile`, `counterpoint.rankNextSteps`, `counterpoint.rankCadenceDestinations`, `counterpoint.analyzeSuspensionMachine` | note lists, harmonic context, profiles, output buffers | voiced state, cadence labels, motion summaries, ranked suggestions | `counterpoint.rankNextSteps(&history, .species, out[0..])` | Build compositional assistants that reason about next moves, cadences, and suspensions. |
| `voice_leading_rules.MotionIndependenceSummary.init`, `voice_leading_rules.detectParallelPerfects`, `voice_leading_rules.detectVoiceCrossings`, `voice_leading_rules.detectSpacingViolations`, `voice_leading_rules.detectMotionIndependence` | voiced states and output buffers | summaries and logical violation counts | `voice_leading_rules.detectParallelPerfects(&a, &b, out[0..])` | Detect concrete rule violations between adjacent voiced states. |
| `choir.range`, `choir.rangeLow`, `choir.rangeHigh`, `choir.rangeContains`, `choir.checkRegisters` | SATB voice IDs, MIDI notes, voiced states | ranges, bounds, booleans, logical violation counts | `choir.rangeContains(.tenor, 60)` | Apply SATB register constraints to four-part writing. |

### Guitar, Keyboard, Playability, And UI State

Important values:

- `guitar.tunings.{STANDARD,DROP_D,DADGAD,OPEN_G,OPEN_D}`
- `guitar.{NUM_STRINGS,MAX_FRET,GUIDE_OPACITY,MAX_GENERIC_STRINGS}`
- `keyboard.{DEFAULT_RANGE_LOW,DEFAULT_RANGE_HIGH,NUM_KEYS,MAX_CONTEXT_SUGGESTIONS}`
- `playability.types.{REASON_NAMES,WARNING_NAMES}`
- `playability.phrase.{ISSUE_SCOPE_NAMES,ISSUE_SEVERITY_NAMES,FAMILY_DOMAIN_NAMES,STRAIN_BUCKET_NAMES}`
- `playability.fret_assessment.{PROFILE_NAMES,BLOCKER_NAMES}`
- `playability.keyboard_assessment.{HAND_ROLE_NAMES,BLOCKER_NAMES}`
- `playability.profile.{PRESET_NAMES}`
- `playability.ranking.{POLICY_NAMES}`

| Symbol(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `playability.types.HandProfile.init`, `playability.types.TemporalLoadState.init`, `playability.types.TemporalLoadState.observe` | ergonomic fields or observed spans | ergonomic state and load tracking | `playability.types.HandProfile.init(4, 4, 5, 4, 7, true)` | Create and update biomechanical profiles over time. |
| `playability.fret_topology.defaultHandProfile`, `currentWindowStart`, `currentWindowEnd`, `isFretInWindow`, `shiftStepsForFret`, `describeState`, `windowedLocationsForMidi` | anchor fret, profile, note, tuning, output buffers | hand profile, window bounds, booleans, state summaries, ranked locations | `playability.fret_topology.windowedLocationsForMidi(60, tuning, 7, profile, out[0..])` | Model the current fret-hand window and note reachability. |
| `playability.keyboard_topology.defaultHandProfile`, `isBlackKey`, `keyCoord`, `describeState` | MIDI notes, pitch classes, profile, previous load | keyboard geometry and ergonomic state | `playability.keyboard_topology.keyCoord(61)` | Map keyboard notes to geometry and span/load metrics. |
| `playability.fret_assessment.fromInt`, `defaultHandProfile`, `assessRealization`, `assessTransition`, `rankLocationsForMidi` | technique profile IDs, fret arrays, tuning, anchor fret, output buffers | technique profiles, assessment structs, ranked locations | `playability.fret_assessment.assessTransition(a, b, tuning, .generic_guitar, null)` | Score fretboard realizations and transitions for playability. |
| `playability.keyboard_assessment.fromInt`, `assessRealization`, `assessTransition`, `rankFingerings` | note lists, hand role, profile, previous load, output buffers | hand role, assessment structs, ranked fingering slices | `playability.keyboard_assessment.rankFingerings(notes, .right, profile, out[0..])` | Score keyboard realizations, transitions, and local fingerings with explainable blocker and warning flags. |
| `playability.phrase.{KeyboardPhraseEvent,FretPhraseEvent,PhraseIssue,PhraseSummary,SummaryAccumulator,summarizeIssues}` | realized events, issue rows, event count | fixed-size event rows, summarized phrase facts, reducer state | `playability.phrase.summarizeIssues(phrase_len, issues[0..issue_count])` | Share one explainable phrase vocabulary across future audit engines, repair helpers, and host bindings without smuggling UI state into the library. |
| `playability.profile.fromInt`, `playability.profile.applyPreset`, `playability.profile.summarizeFretRealization`, `playability.profile.summarizeFretTransition`, `playability.profile.summarizeKeyboardRealization`, `playability.profile.summarizeKeyboardTransition`, `playability.profile.suggestEasierFretRealization`, `playability.profile.suggestEasierKeyboardFingering`, `playability.profile.suggestSaferKeyboardNextStep` | preset IDs, hand profiles, assessments, history windows | adjusted profiles, difficulty summaries, easier realizations, safer next-step rows | `playability.profile.applyPreset(base, .compact_beginner)` | Apply explainable ergonomic presets and turn raw assessments into practice-facing summaries and safer suggestions. |
| `playability.ranking.fromInt`, `playability.ranking.rankKeyboardNextSteps`, `playability.ranking.filterNextStepsByPlayability`, `playability.ranking.rankKeyboardContextSuggestions` | voiced history, theory profile, hand role, hand profile, policy, output buffers | policy IDs, ranked playability rows, accepted next steps, ranked context rows | `playability.ranking.rankKeyboardNextSteps(&history, .tonal_chorale, .right, profile, .balanced, out[0..])` | Re-rank theory-valid continuations by explicit bottleneck and strain policies instead of hidden heuristics. |
| `guitar.FretPosition.toMidi`, `guitar.FretPosition.toPitchClass`, `guitar.GenericFretPosition.toMidi`, `guitar.GenericFretPosition.toPitchClass`, `guitar.GuitarVoicing.toPitchClassSet`, `guitar.GuitarVoicing.handSpan`, `guitar.GenericVoicing.toPitchClassSet`, `guitar.GenericVoicing.handSpan` | fret or voicing objects and tuning | MIDI notes, pitch classes, sets, spans | `voicing.toPitchClassSet()` | Turn fret positions and voicings into theory objects. |
| `guitar.fretToMidi`, `guitar.fretToMidiGeneric`, `guitar.midiToFretPositions`, `guitar.midiToFretPositionsGeneric`, `guitar.pcToFretPositions` | strings, frets, tuning, output buffers | MIDI notes or candidate-position slices | `guitar.midiToFretPositions(60, guitar.tunings.STANDARD, &out)` | Translate between fretboard coordinates and pitch content. |
| `guitar.generateVoicingsGeneric`, `guitar.bassMidiGeneric`, `guitar.scoreVoicingGeneric`, `guitar.preferredVoicingGeneric`, `guitar.generateVoicings`, `guitar.cagedPositions` | chord sets, tuning, search bounds, output buffers | voicing slices, bass MIDI, ranking scores, preferred voicing, CAGED anchors | `guitar.preferredVoicingGeneric(set, tuning, 12, 4, null, meta[0..], frets[0..])` | Search, score, and select playable chord voicings. |
| `guitar.pitchClassGuideGeneric`, `guitar.pitchClassGuide`, `guitar.fretsToUrlGeneric`, `guitar.fretsToUrl`, `guitar.urlToFretsGeneric`, `guitar.urlToFrets` | selected positions or voicings, fret range, tuning, buffers | guide-dot slices, URL fragments, parsed voicings | `guitar.fretsToUrl(voicing, &buf)` | Drive practice UIs and URL-addressable fretboard state. |
| `keyboard.KeyboardState.init`, `selected`, `toggle`, `pitchClassSet` | note toggles or current state | mutable UI state and active set | `state.toggle(60)` | Model click/tap driven keyboard selection. |
| `keyboard.notesPitchClassSet`, `keyboard.visualOpacityForMidi`, `keyboard.updateKeyVisuals`, `keyboard.notesToUrl`, `keyboard.urlToNotes`, `keyboard.playbackStyle`, `keyboard.modeSet`, `keyboard.modeSpellingQuality`, `keyboard.rankContextSuggestions` | note lists, set values, context, buffers | sets, opacities, visuals, URL text, parsed notes, playback modes, context suggestions | `keyboard.rankContextSuggestions(set, notes, 0, .ionian, out[0..])` | Build keyboard overlays, spelling hints, and next-note suggestions. |
| `slider.strideForHeight`, `slider.ease`, `slider.blend`, `slider.updateScroll`, `slider.handleTap`, `slider.triangleVertices`, `slider.triangleCenter`, `slider.getRelativeColorIndex`, `slider.triangleColor`, `slider.quadToUrlPath`, `slider.urlPathToQuad` | geometry, color, scroll, pointer, and path inputs | floats, colors, hit-test results, geometry, URL state | `slider.urlPathToQuad("/p/fb/C-Major")` | Support the library's slider/tonnetz-style interaction model. |

### Rendering, Diagrams, And Low-Level Graphics

Important values:

- `svg_quality.{SANS_STACK,SERIF_STACK,MONO_STACK}`
- `svg_tessellation.{CANVAS_WIDTH,CANVAS_HEIGHT,TILE_COUNT,MAX_EDGES}`
- `svg_orbifold.{NODE_COUNT,MAX_EDGES}`
- `svg_majmin_scene.{MODES_COUNT,SCALES_COUNT}`

| Symbol(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `svg_quality.writeSvgPrelude` | writer plus SVG framing values | `!void` | `try svg_quality.writeSvgPrelude(w, "100", "100", "0 0 100 100", "")` | Start custom SVG emitters with the library's shared visual conventions. |
| `svg_text_misc.verticalPathData`, `horizontalPathData`, `blockTextWidth`, `writeBlockText`, `centerSquarePathData`, `renderVerticalLabel`, `renderCenterSquareGlyph` | text, layout, and output buffers | path data, widths, SVG byte slices | `svg_text_misc.renderVerticalLabel("Dorian", false, buf[0..])` | Build text primitives and standalone label/glyph assets. |
| `svg_clock.circlePosition`, `renderOPC`, `renderOPTC`, `renderOpticKGroup`, `generateAllOPTCFiles` | sets, labels, geometry, buffers, directories | points, SVG slices, batch-export success | `svg_clock.renderOPTC(set, "037", &buf)` | Render pitch-class clocks and OPTIC/K cards. |
| `svg_staff.clefForGrandStaff`, `pianoStaffMode`, `midiToStaffPosition`, `needsAccidental`, `keySignatureSymbolCount`, `renderChordStaff`, `renderPianoStaff`, `renderGrandChordStaff`, `renderScaleStaff`, `renderKeyStaff`, `staffPositionForName` | notes, clefs, keys, buffers | clefs, modes, positions, counts, SVG slices | `svg_staff.renderPianoStaff(&.{43,52,60,64}, key_ctx, &buf)` | Render notation-ready chord, key, scale, and piano-staff views. |
| `svg_fret.renderFretDiagram`, `renderDiagram`, `detectBarre`, `detectBarreForFrets` | voicings or generic diagram specs, buffers | SVG slices and barre metadata | `svg_fret.renderDiagram(.{ .frets = frets[0..], .tuning = tuning }, &buf)` | Render standard or parametric fret diagrams. |
| `svg_keyboard.renderKeyboard` | notes, range, buffer | `[]u8` SVG | `svg_keyboard.renderKeyboard(&.{60,64,67}, 48, 72, &buf)` | Render colored keyboard snapshots. |
| `svg_evenness_chart.computeDots`, `renderEvennessChart`, `renderEvennessField`, `forteLabel`, `setClassCenter` | output buffers or highlighted sets | dot slices, SVG, labels, centers | `svg_evenness_chart.renderEvennessField(set, &buf)` | Render evenness atlases and highlighted set-class fields. |
| `svg_key_sig.renderKeySignature`, `svg_circle_of_fifths.fifthsOrder`, `svg_circle_of_fifths.renderCircleOfFifths` | signatures, buffers, none | SVG slices or circle order | `svg_circle_of_fifths.renderCircleOfFifths(&buf)` | Render key signatures and circle-of-fifths references. |
| `svg_tessellation.enumerateTiles`, `buildAdjacency`, `neighborCount`, `renderScaleTessellation` | output buffers, tile indices | tile slices, edge slices, counts, SVG | `svg_tessellation.buildAdjacency(tiles, &edges)` | Build and render scale-tessellation graphs. |
| `svg_mode_icon.renderModeIcon`, `modeRootPitchClass`, `degreeRoman`, `degreeCount`, `fileName` | mode-icon specs, families, output buffers | SVG, pitch classes, roman numerals, counts, file names | `svg_mode_icon.renderModeIcon(.{ .family = .diatonic, .transposition = 0, .degree = 1 }, &buf)` | Render compact modal badges. |
| `svg_orbifold.enumerateTriadNodes`, `buildTriadEdges`, `renderTriadOrbifold` | node and edge buffers | node slices, edge slices, SVG | `svg_orbifold.renderTriadOrbifold(&buf)` | Render orbifold harmony maps. |
| `svg_n_tet_chart.renderNTetChart`, `svg_majmin_scene.parseStem`, `parseImageName`, `isValidScene`, `formatStem`, `countForKind`, `imageName`, `sceneForIndex`, `enumerate`, `imageIndex` | scene IDs, names, buffers | SVG or scene metadata | `svg_majmin_scene.sceneForIndex(.scales, 12)` | Enumerate authored major/minor gallery scenes and deterministic scene IDs. |
| `render_ir.Builder.init`, `scene`, `raw`, `path`, `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`, `groupStart`, `groupEnd`, `linkStart`, `linkEnd`, `render_ir.isDeterministic`, `render_svg_serializer.write`, `render_raster.clear`, `render_raster.renderScene`, `render_raster.renderDemoScene`, `render_raster.hashSurface` | scene storage, SVG ops, raster surfaces, writers | scene builders, write success, raster output, deterministic hashes | `try render_svg_serializer.write(scene, writer, .strict)` | Build deterministic scene graphs, serialize them to SVG, or render them to RGBA. |

### Static Tables

Use `tables` when you need frozen lookup data instead of recomputing it:

- `tables.set_classes.SET_CLASSES`, `FORTE_MAP`, `COMPLEMENT_MAP`, `INVOLUTION_MAP`
- `tables.intervals.INTERVAL_VECTORS`, `FC_COMPONENTS`
- `tables.classification.CLUSTER_INFO`, `EVENNESS_INFO`, `CLASSIFICATION_FLAGS`, `CLUSTER_FREE_INDICES`
- `tables.scales.SCALE_TYPE_PCS`, `MODE_TYPES`, `KEY_SPELLING_MAPS`
- `tables.chords.CHORD_TYPES`, `GAME_RESULTS`
- `tables.colors.PC_COLORS`, `IC_COLORS`, `COLOR_INDEX`

These are especially useful for:

- LLM tool adapters that want immutable metadata
- headless services that want startup-time-free catalogs
- teaching or gallery tools that need stable, indexable references

### Verification-Only Zig Namespaces

These are public in source form but are not the embedding contract for applications.

| Namespace | Main symbols | Use |
| --- | --- | --- |
| `harmonious_svg_compat` | `kindCount`, `kindName`, `kindDirectory`, `kindId`, `imageCount`, `imageName`, `generateByIndex`, `generateByName` | Enumerate and generate Harmonious-compatible SVG fixtures. |
| `bitmap_compat` | `renderSvgMarkupRgba`, `renderPublicOpticKGroupRgba`, `renderPublicStandardFretDiagramRgba`, `kindSupported`, `candidateBackend`, `candidateBackendName`, `targetWidth`, `targetWidthScaled`, `targetHeight`, `targetHeightScaled`, `requiredRgbaBytes`, `requiredRgbaBytesScaled`, `renderCandidateRgba`, `renderCandidateRgbaScaled`, `renderReferenceSvgRgba`, `renderReferenceSvgRgbaScaled` | Scale-aware raster proof tooling for compatibility images. |
| `svg_clock_compat` | `circlePosition`, `renderOPC`, `renderOPTCHarmoniousCompat`, `optcCompatVariant`, `optcCompatCirclePosition`, `optcCompatSpokePath` | Harmonious clock parity helpers. |
| `svg_text_misc_compat` | `verticalPathData`, `centerSquarePathData`, `renderVerticalLabel`, `renderCenterSquareGlyph` | Legacy text-primitive compatibility helpers. |
| `svg_evenness_compat` | `renderEvennessByName` | Legacy evenness fixture generation. |

## C ABI Reference

The public C ABI is declared in `include/libmusictheory.h`.

Build and install:

```bash
./zigw build
```

Artifacts:

- `zig-out/include`
- `zig-out/lib`

### Stable C Types

Key stable output types:

- `lmt_key_context`
- `lmt_scale_snap_candidates`
- `lmt_containing_mode_match`
- `lmt_chord_match`
- `lmt_fret_pos`
- `lmt_guide_dot`

Key experimental but useful types:

- `lmt_context_suggestion`
- `lmt_hand_profile`, `lmt_temporal_load_state`
- `lmt_keyboard_phrase_event`, `lmt_fret_phrase_event`
- `lmt_playability_phrase_issue`, `lmt_playability_phrase_summary`
- `lmt_fret_candidate_location`, `lmt_fret_play_state`
- `lmt_fret_realization_assessment`, `lmt_fret_transition_assessment`, `lmt_ranked_fret_realization`
- `lmt_keybed_key_coord`, `lmt_keyboard_play_state`
- `lmt_keyboard_realization_assessment`, `lmt_keyboard_transition_assessment`, `lmt_ranked_keyboard_fingering`
- `lmt_playability_difficulty_summary`, `lmt_ranked_keyboard_context_suggestion`, `lmt_ranked_keyboard_next_step`
- `lmt_voiced_state`, `lmt_voiced_history`
- `lmt_motion_summary`, `lmt_motion_evaluation`
- `lmt_voice_pair_violation`, `lmt_motion_independence_summary`
- `lmt_satb_register_violation`
- `lmt_next_step_suggestion`, `lmt_cadence_destination_score`, `lmt_suspension_machine_summary`
- `lmt_orbifold_triad_node`, `lmt_orbifold_triad_edge`

### Stable C Functions

| Function(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `lmt_pcs_from_list`, `lmt_pcs_to_list`, `lmt_pcs_cardinality`, `lmt_pcs_transpose`, `lmt_pcs_invert`, `lmt_pcs_complement`, `lmt_pcs_is_subset` | pitch-class arrays or sets | sets, counts, transformed sets, booleans | `lmt_pcs_from_list((uint8_t[]){0,4,7}, 3)` | Stable set-building and set-transform primitives for any FFI host. |
| `lmt_prime_form`, `lmt_forte_prime`, `lmt_is_cluster_free`, `lmt_evenness_distance` | set | canonical set or analysis score | `lmt_forte_prime(set)` | Stable set-class canonicalization and coarse analysis. |
| `lmt_scale`, `lmt_mode`, `lmt_mode_type_count`, `lmt_mode_type_name`, `lmt_scale_degree`, `lmt_transpose_diatonic`, `lmt_nearest_scale_tones`, `lmt_snap_to_scale`, `lmt_find_containing_modes`, `lmt_spell_note`, `lmt_spell_note_parts` | scale or mode IDs, tonic, note, policy, key context, output buffers | rooted sets, counts, names, degrees, success flags, strings, logical match counts | `lmt_snap_to_scale(0, LMT_MODE_IONIAN, 61, LMT_SNAP_HIGHER, &out)` | Stable scalar navigation, note spelling, and modal containment from C-compatible hosts. |
| `lmt_chord`, `lmt_chord_pattern_count`, `lmt_chord_pattern_name`, `lmt_chord_pattern_formula`, `lmt_detect_chord_matches`, `lmt_chord_name`, `lmt_roman_numeral`, `lmt_roman_numeral_parts` | chord type, root, set, bass info, key context, output buffers | sets, counts, names, formulas, logical match totals, strings | `lmt_detect_chord_matches(set, 0, true, out, cap)` | Stable chord templates, chord detection, and roman-numeral labeling. |
| `lmt_fret_to_midi`, `lmt_midi_to_fret_positions`, `lmt_fret_to_midi_n`, `lmt_midi_to_fret_positions_n`, `lmt_generate_voicings_n`, `lmt_pitch_class_guide_n`, `lmt_frets_to_url_n`, `lmt_url_to_frets_n` | fretboard coordinates, tuning arrays, chord sets, buffers | MIDI notes, logical totals, serialized URL state | `lmt_generate_voicings_n(set, tuning, n, 12, 4, frets, cap)` | Stable fretboard lookup, voicing generation, and URL encoding. |
| `lmt_svg_clock_optc`, `lmt_svg_optic_k_group`, `lmt_svg_evenness_chart`, `lmt_svg_evenness_field`, `lmt_svg_fret`, `lmt_svg_fret_n`, `lmt_svg_fret_tuned_n`, `lmt_svg_chord_staff`, `lmt_svg_key_staff`, `lmt_svg_keyboard`, `lmt_svg_piano_staff` | sets, fret arrays, notes, key context, tuning arrays, output buffers | total SVG byte count | `lmt_svg_keyboard(notes, n, 48, 72, buf, cap)` | Stable image generation for clocks, staff, keyboard, fretboard, and evenness views. |

### Experimental C Functions

Most experimental `uint32_t` functions return `1` on success and `0` on invalid input, disabled backends, or insufficient output space unless noted otherwise.

#### Experimental Catalogs And Ranking

| Function(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `lmt_ordered_scale_pattern_count`, `lmt_ordered_scale_pattern_name`, `lmt_ordered_scale_degree_count`, `lmt_ordered_scale_pitch_class_set`, `lmt_barry_harris_parity` | ordered-scale index, tonic, note, output degree | counts, names, rooted sets, parity code | `lmt_barry_harris_parity(index, 0, 60, &degree)` | Enumerate ordered-scale catalogs and Barry Harris parity from non-Zig hosts. |
| `lmt_mode_spelling_quality`, `lmt_rank_context_suggestions`, `lmt_preferred_voicing_n` | mode context, active notes, chord sets, tuning, output buffers | key quality, logical suggestion totals, success flags | `lmt_preferred_voicing_n(set, tuning, n, 12, 4, 12, frets, cap)` | Rank next-note contexts and pick one best voicing in exploratory apps. |

#### Experimental Playability And Ergonomic State

| Function(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `lmt_playability_reason_count`, `lmt_playability_reason_name`, `lmt_playability_warning_count`, `lmt_playability_warning_name`, `lmt_playability_policy_count`, `lmt_playability_policy_name`, `lmt_playability_profile_preset_count`, `lmt_playability_profile_preset_name`, `lmt_playability_phrase_issue_scope_count`, `lmt_playability_phrase_issue_scope_name`, `lmt_playability_phrase_issue_severity_count`, `lmt_playability_phrase_issue_severity_name`, `lmt_playability_phrase_family_domain_count`, `lmt_playability_phrase_family_domain_name`, `lmt_playability_phrase_strain_bucket_count`, `lmt_playability_phrase_strain_bucket_name`, `lmt_fret_playability_blocker_count`, `lmt_fret_playability_blocker_name`, `lmt_keyboard_playability_blocker_count`, `lmt_keyboard_playability_blocker_name`, `lmt_fret_technique_profile_count`, `lmt_fret_technique_profile_name` | none or enum index | counts and names | `lmt_playability_phrase_family_domain_name(4)` | Reflect the full explainable playability and phrase-summary vocabulary into UI, docs, and bindings. |
| `lmt_sizeof_hand_profile`, `lmt_sizeof_temporal_load_state`, `lmt_sizeof_keyboard_phrase_event`, `lmt_sizeof_fret_phrase_event`, `lmt_sizeof_playability_phrase_issue`, `lmt_sizeof_playability_phrase_summary`, `lmt_sizeof_fret_candidate_location`, `lmt_sizeof_fret_play_state`, `lmt_sizeof_fret_realization_assessment`, `lmt_sizeof_fret_transition_assessment`, `lmt_sizeof_ranked_fret_realization`, `lmt_sizeof_keybed_key_coord`, `lmt_sizeof_keyboard_play_state`, `lmt_sizeof_keyboard_realization_assessment`, `lmt_sizeof_keyboard_transition_assessment`, `lmt_sizeof_ranked_keyboard_fingering`, `lmt_sizeof_ranked_keyboard_context_suggestion`, `lmt_sizeof_ranked_keyboard_next_step`, `lmt_sizeof_playability_difficulty_summary` | none | byte counts | `lmt_sizeof_playability_phrase_summary()` | Guard FFI layout compatibility for every playability and phrase-audit struct the gallery and host apps exchange. |
| `lmt_default_fret_hand_profile`, `lmt_default_fret_hand_profile_for_technique`, `lmt_default_keyboard_hand_profile`, `lmt_playability_profile_from_preset`, `lmt_describe_fret_play_state`, `lmt_windowed_fret_positions_n`, `lmt_assess_fret_realization_n`, `lmt_assess_fret_transition_n`, `lmt_rank_fret_realizations_n`, `lmt_keyboard_key_coord`, `lmt_describe_keyboard_play_state`, `lmt_assess_keyboard_realization_n`, `lmt_assess_keyboard_transition_n`, `lmt_rank_keyboard_fingerings_n` | profiles, preset IDs, fret arrays, tuning, note lists, previous load, output buffers | success flags or logical totals | `lmt_playability_profile_from_preset(LMT_PLAYABILITY_PRESET_COMPACT_BEGINNER, &base, &out)` | Build preset-aware hand profiles and obtain low-level keyboard/fret assessments from other languages. |
| `lmt_summarize_playability_phrase_issues` | event count, phrase issue rows, output summary | success flag | `lmt_summarize_playability_phrase_issues(events, issues, issue_count, &summary)` | Reduce explicit event/transition issue rows into first-blocked, bottleneck, dominant-family, and recovery-deficit facts for downstream phrase auditors. |
| `lmt_summarize_fret_realization_difficulty_n`, `lmt_summarize_fret_transition_difficulty_n`, `lmt_summarize_keyboard_realization_difficulty_n`, `lmt_summarize_keyboard_transition_difficulty_n` | assessed note/fret inputs, technique or hand info, output summary | success flag | `lmt_summarize_keyboard_transition_difficulty_n(a, an, b, bn, hand, &profile, NULL, &summary)` | Collapse blocker, warning, bottleneck, and recent-load data into practice-facing summaries without inventing opaque scores. |
| `lmt_suggest_easier_fret_realization_n`, `lmt_suggest_easier_keyboard_fingering_n`, `lmt_filter_next_steps_by_playability`, `lmt_rank_keyboard_next_steps_by_playability`, `lmt_suggest_safer_keyboard_next_step_by_playability`, `lmt_rank_keyboard_context_suggestions_by_playability` | current note/fret context, theory profile, hand role, hand profile, policy, output buffers | ranked rows, filtered next steps, or one safer fallback | `lmt_rank_keyboard_next_steps_by_playability(&history, LMT_COUNTERPOINT_TONAL_CHORALE, LMT_KEYBOARD_HAND_RIGHT, &profile, LMT_PLAYABILITY_POLICY_MINIMAX_BOTTLENECK, out, cap)` | Turn theory-valid output into explicitly playable alternatives and safer continuations for practice tools and LLM assistants. |

### Playability API Recipes

These recipes are the intended adoption path for the experimental playability surface.

Visual walkthroughs for the same surface live in:

- `/Users/bermi/code/libmusictheory/README.md` under `Playability Gallery States`
- `/Users/bermi/code/libmusictheory/docs/release/gallery-capture.md`

The important contract is:

- start from an explicit hand profile
- optionally apply a named preset
- summarize the current realization or transition
- only then filter or rerank theory-valid next steps
- explain the result with blockers, warnings, spans, shifts, and accepted/rejected candidates instead of hidden scores

#### Recipe 1: Apply A Preset Before Any Summary

```c
lmt_hand_profile base = {0};
lmt_hand_profile tuned = {0};

if (!lmt_default_keyboard_hand_profile(&base)) {
    /* invalid build/runtime state */
}
if (!lmt_playability_profile_from_preset(
        LMT_PLAYABILITY_PROFILE_COMPACT_BEGINNER,
        &base,
        &tuned)) {
    /* invalid preset */
}
```

Use this when your host wants to say:

`"I am evaluating this passage with a compact-beginner hand profile, so short spans and small shifts are treated as the comfort baseline."`

#### Recipe 2: Summarize The Current Keyboard Realization

```c
const lmt_midi_note notes[] = {60, 64, 67};
lmt_playability_difficulty_summary summary = {0};

if (lmt_summarize_keyboard_realization_difficulty_n(
        notes,
        3,
        LMT_KEYBOARD_HAND_RIGHT,
        &tuned,
        NULL,
        &summary)) {
    /* summary.accepted, summary.blocker_count, summary.warning_count,
       summary.bottleneck_cost, summary.cumulative_cost, summary.span_steps,
       and the comfort/limit margins are now populated */
}
```

Use this when your host wants to say:

`"This voicing is accepted because it stays inside the current comfort span,"`

or:

`"This voicing is blocked because it exceeds the profile's span or shift limits."`

#### Recipe 3: Offer An Easier Local Fingering

```c
lmt_ranked_keyboard_fingering easier = {0};

if (lmt_suggest_easier_keyboard_fingering_n(
        notes,
        3,
        LMT_KEYBOARD_HAND_RIGHT,
        &tuned,
        &easier)) {
    /* easier.fingers[0..easier.note_count] describes the recommended assignment */
}
```

Use this when your host wants to say:

`"I kept the same notes but changed the fingering to reduce the hardest local move."`

#### Recipe 4: Filter Or Rerank Theory-Valid Next Steps

```c
lmt_voiced_history history = {0};
lmt_voiced_state state = {0};
lmt_ranked_keyboard_next_step ranked[8] = {0};

lmt_voiced_history_reset(&history);
lmt_voiced_history_push(
    &history,
    notes, 3,
    NULL, 0,
    0, /* tonic C */
    LMT_MODE_IONIAN,
    1, 4, 0,
    LMT_CADENCE_NONE,
    &state);

uint32_t logical = lmt_rank_keyboard_next_steps_by_playability(
    &history,
    LMT_COUNTERPOINT_TONAL_CHORALE,
    LMT_KEYBOARD_HAND_RIGHT,
    &tuned,
    LMT_PLAYABILITY_POLICY_MINIMAX_BOTTLENECK,
    ranked,
    8);
```

Use this when your host wants to say:

`"These next moves are theory-valid first; this ranking then favors the move with the easiest hardest jump."`

If you want a single conservative fallback instead of a ranked list:

```c
lmt_ranked_keyboard_next_step safer = {0};

if (lmt_suggest_safer_keyboard_next_step_by_playability(
        &history,
        LMT_COUNTERPOINT_TONAL_CHORALE,
        LMT_KEYBOARD_HAND_RIGHT,
        &tuned,
        LMT_PLAYABILITY_POLICY_MINIMAX_BOTTLENECK,
        &safer)) {
    /* safer.candidate_index points back into the ranked-theory candidate space */
}
```

#### Recipe 5: LLM Explanation Pattern

Good downstream phrasing looks like this:

- `"I used the compact-beginner preset, so the comfort span is intentionally narrow."`
- `"This voicing is accepted, but it raises a warning because the shift is near the profile limit."`
- `"I rejected that next step because it creates the bottleneck move in the phrase."`
- `"I suggested this alternative because it preserves the harmonic role while reducing the hardest transition."`

Avoid phrasing like:

- `"The model preferred this."`
- `"This scored 47."`
- `"The heuristic weight was higher."`

#### Experimental Counterpoint, SATB, And Cadence Analysis

| Function(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `lmt_counterpoint_max_voices`, `lmt_counterpoint_history_capacity`, `lmt_counterpoint_rule_profile_count`, `lmt_counterpoint_rule_profile_name`, `lmt_voice_leading_violation_kind_count`, `lmt_voice_leading_violation_kind_name`, `lmt_satb_voice_count`, `lmt_satb_voice_name`, `lmt_cadence_destination_count`, `lmt_cadence_destination_name`, `lmt_suspension_state_count`, `lmt_suspension_state_name`, `lmt_next_step_reason_count`, `lmt_next_step_reason_name`, `lmt_next_step_warning_count`, `lmt_next_step_warning_name` | none or enum index | counts and names | `lmt_counterpoint_rule_profile_name(0)` | Reflect the counterpoint catalog into UI and bindings. |
| `lmt_sizeof_voiced_state`, `lmt_sizeof_voiced_history`, `lmt_sizeof_next_step_suggestion`, `lmt_sizeof_voice_pair_violation`, `lmt_sizeof_motion_independence_summary`, `lmt_sizeof_satb_register_violation`, `lmt_sizeof_cadence_destination_score`, `lmt_sizeof_suspension_machine_summary` | none | byte counts | `lmt_sizeof_voiced_history()` | Guard counterpoint struct layouts in FFI layers. |
| `lmt_voiced_history_reset`, `lmt_build_voiced_state`, `lmt_voiced_history_push`, `lmt_classify_motion`, `lmt_evaluate_motion_profile`, `lmt_check_parallel_perfects`, `lmt_check_voice_crossing`, `lmt_check_spacing`, `lmt_check_motion_independence`, `lmt_satb_range_low`, `lmt_satb_range_high`, `lmt_satb_range_contains`, `lmt_check_satb_registers`, `lmt_rank_next_steps`, `lmt_rank_cadence_destinations`, `lmt_analyze_suspension_machine` | voiced states, note lists, metric context, profiles, output buffers | success flags, logical totals, range bounds, booleans | `lmt_rank_next_steps(&history, LMT_COUNTERPOINT_TONAL_CHORALE, out, cap)` | Build stateful counterpoint assistants, SATB analyzers, and cadence rankers. |

#### Experimental Orbifold And Raster Helpers

| Function(s) | Parameters | Returns | Example | Typical use |
| --- | --- | --- | --- | --- |
| `lmt_orbifold_triad_node_count`, `lmt_sizeof_orbifold_triad_node`, `lmt_orbifold_triad_node_at`, `lmt_find_orbifold_triad_node`, `lmt_orbifold_triad_edge_count`, `lmt_sizeof_orbifold_triad_edge`, `lmt_orbifold_triad_edge_at` | indexes, sets, output buffers | counts, byte sizes, success flags, node index | `lmt_orbifold_triad_node_at(0, &node)` | Traverse the orbifold graph from non-Zig environments. |
| `lmt_raster_is_enabled`, `lmt_raster_demo_rgba`, `lmt_bitmap_clock_optc_rgba`, `lmt_bitmap_optic_k_group_rgba`, `lmt_bitmap_evenness_chart_rgba`, `lmt_bitmap_evenness_field_rgba`, `lmt_bitmap_fret_rgba`, `lmt_bitmap_fret_n_rgba`, `lmt_bitmap_fret_tuned_n_rgba`, `lmt_bitmap_chord_staff_rgba`, `lmt_bitmap_key_staff_rgba`, `lmt_bitmap_keyboard_rgba`, `lmt_bitmap_piano_staff_rgba` | sizes, sets, notes, fret arrays, tuning, output RGBA buffers | required byte counts or `0` | `lmt_bitmap_keyboard_rgba(notes, n, 48, 72, 1024, 240, rgba, bytes)` | Generate direct RGBA output when SVG is not the right integration format. |

## Browser And WASM

The browser-facing patterns are:

- `wasm-docs`
  stable public-contract demonstration bundle
- `wasm-gallery`
  supported example bundle that intentionally uses some experimental helpers
- `wasm-validation`, `wasm-scaled-render`, and related proof bundles
  internal verification surfaces

WASM memory helpers:

- `lmt_wasm_scratch_ptr()`
- `lmt_wasm_scratch_size()`

Use them when your JS host wants a reusable scratch region for temporary string or RGBA marshalling.

Aside from those helpers, exported browser symbols mirror the C ABI.

The `wasm-docs` bundle now includes a dedicated `Playability And Practice APIs` section that walks through:

- default keyboard profiles
- preset application
- realization and transition summaries
- easier fingering suggestions
- safer next-step selection and playability-aware reranking

## Internal Compatibility And Proof Surface

`include/libmusictheory_compat.h` exists for regression work, not application contracts. It includes:

- bitmap proof helpers such as `lmt_bitmap_proof_scale_numerator` and `lmt_bitmap_proof_scale_denominator`
- compatibility raster helpers such as `lmt_bitmap_compat_kind_supported`, `lmt_bitmap_compat_candidate_backend_name`, `lmt_bitmap_compat_target_width*`, `lmt_bitmap_compat_target_height*`, `lmt_bitmap_compat_required_rgba_bytes*`, `lmt_bitmap_compat_render_candidate_rgba*`, and `lmt_bitmap_compat_render_reference_svg_rgba*`
- compatibility SVG enumeration and generation helpers such as `lmt_svg_compat_kind_count`, `lmt_svg_compat_kind_name`, `lmt_svg_compat_kind_directory`, `lmt_svg_compat_image_count`, `lmt_svg_compat_image_name`, and `lmt_svg_compat_generate`

Use these only if you are:

- reproducing the repo's Harmonious parity workflow
- validating scaled-render drift
- building proof tooling around the exact gallery and atlas fixtures

For normal app development, prefer:

- the stable Zig modules exported by `src/root.zig`
- the stable functions in `include/libmusictheory.h`
- the `wasm-docs` bundle for browser integration
