# Contrapunk Theory Integration

> Dependencies: 0007, 0009, 0010, 0011, 0020, 0115
> Follow-up: implementation slices to be created from this plan once Phase 0 decisions are accepted

Status: In progress

## Summary

Critically evaluate and then integrate the explainable Contrapunk theory primitives that fit `libmusictheory`'s actual goals: helping LLMs verify, annotate, and generate music with outputs that can always answer "why?" in music-theory terms. The additions in scope are degree-aware scale operations, principled mode expansion, structured chord detection, modal interchange containment, part-writing rule checks, and a narrow audit of existing suspension support.

This plan is intentionally not a blind port. It accepts only what fits the repo's current principles:
- zero allocation, stack-only core algorithms
- `u12` pitch-class-set canon for set operations
- deterministic, explicit APIs
- experimental-first C ABI additions
- no hidden preference orders, no unexplained numeric weights, no style heuristics disguised as theory

## Why

Contrapunk contains a useful subset of textbook theory primitives that `libmusictheory` still lacks in first-class, C-ABI-exported form. The right additions would materially improve:
- LLM explanation quality: "E is degree 3 in C major, so a diatonic third above it is G"
- composition verification: "this move creates parallel fifths between alto and tenor"
- annotation: "this sonority matches Cmaj7/E because the pitch classes form 0-4-7-11 above C while E is the bass"
- next-step generation: "F# is outside C Ionian but belongs to C Lydian as raised 4"

The wrong additions would weaken the library by importing opaque rankings, arbitrary tie-breaks, or stylistic assumptions with no principled explanation.

## Explainability Gate

Every feature in this plan must survive these checks before implementation:

1. A caller must be able to explain the output without referring to implementation detail, tuning, or search order.
2. If multiple theory-valid answers exist, the API must either:
   - return all of them, or
   - require the caller to provide the policy that chooses among them.
3. If a result depends on a convention rather than a universal fact, that convention must be named explicitly in the API or the docs.
4. If a feature overlaps an existing `libmusictheory` primitive, extend or refine the existing primitive rather than creating a parallel subsystem.

## Critical Review

| Candidate | Decision | Critical Review |
| --- | --- | --- |
| Harmonic-minor family modes | Adopt | These are objective interval structures and fit the existing mode system cleanly. They should be added only after cross-checking names and pitch-class content against `tonal-ts` and literature. |
| 5 exotic modes | Adopt | These are explainable as named scale definitions, but only if each is traceable to established literature and not just a project-local nickname. |
| "11 new modes" | Push back | The audit understates the count. Relative to the current `ModeType`, the repo is missing 12 seven-note modes if it adds the full harmonic-minor family plus the 5 named exotic modes. The implementation plan should treat the count honestly. |
| Barry Harris 8-note scales | Gate behind design review | The scales themselves are explainable. The danger is not cardinality; the repo already handles 6- and 8-note families (`whole_tone`, `diminished`) at the PCS level. The real question is whether Barry Harris belongs as a first-class mode family in the same API semantics as church/jazz modes, or as a separate ordered-scale pedagogy surface. |
| Diatonic transposition | Adopt first | This is one of the cleanest additions in the whole audit and should land before modal interchange or any explainable harmony helpers. |
| `snap_to_scale` with implicit lower-on-tie | Push back on default | "Lower on tie" is deterministic, but it is still a policy choice. The library should expose both candidates or require a caller-supplied tie policy rather than hardcoding an unexplained default. |
| 39-pattern chord detection | Adopt with API redesign | The chord vocabulary is explainable and useful, but a single string-returning API hides ambiguity. The library should return structured matches first and keep string formatting as a helper. |
| Chord ranking by pattern order | Push back on hidden precedence | Ranking by cardinality and root-equals-bass is explainable. Ranking by "earlier in a hand-written table" is not enough by itself when matches tie. The API should expose all matches or enough metadata for the caller to justify the choice. |
| Modal interchange mechanism | Adopt | Membership in parallel modes is an objective fact. The library should return all containing modes, plus degree information, and leave stylistic borrowing preference to the caller. |
| Modal interchange borrowing order | Reject | No internal Aeolian-first, Dorian-first, or similar search order belongs in core APIs. |
| Voice-leading rule checks | Adopt as complements | These fit the repo well if implemented as narrow violation detectors that complement the existing motion classifier and counterpoint engine. |
| Suspension mechanics | Audit first | The repo already exposes suspension-state machinery. The plan should first document what is already covered, then add only the missing textbook-specific detail. |
| SATB ranges | Adopt as optional profile helpers | Standard ranges are explainable, but they are not universal correctness rules for the library as a whole. They should be experimental, profile-scoped, and never treated as global validity gates. |
| Contrapunk scoring weights, style tuning, random dispatch | Reject | They violate the library's explainability principle and should not be imported. |

## Architectural Decisions

### 1. Ordered Scale Operations Need A Dedicated Internal Layer

`src/scale.zig` currently identifies scale families and rotates their pitch-class sets; it does not provide a durable ordered-degree API for note-level operations. The clean addition is an internal ordered-scale layer that can provide:
- degree-ordered offsets
- cardinality
- degree lookup
- transposition by scale degree
- nearest-scale-tone search

Planned internal file:
- `/Users/bermi/code/libmusictheory/src/ordered_scale.zig`

This layer should be internal-first and reusable by mode expansion, diatonic transposition, Barry Harris evaluation, and modal interchange.

### 2. Chord Detection Must Be Structured, Not String-First

A string like `Cmaj7/E` is useful for display, but it is not the right primary ABI if the library's job is explanation and verification.

The primary detection result should include at least:
- detected root pitch class
- bass pitch class
- pattern identifier
- inversion/slash information
- whether the bass equals the root
- matched cardinality

String formatting should be a secondary helper layered over that struct.

### 3. Modal Interchange Results Need Degree Information

Returning only `ModeType[]` is insufficient for explanation. The result should include the degree within each containing mode so an LLM can say:
- `F# belongs to C Lydian as raised 4`
- `Eb belongs to C Aeolian as minor 3`

### 4. Barry Harris Is Not Blocked By Cardinality Alone

The repo already models non-heptatonic scale families at the PCS level. The real design choice is semantic:
- are Barry Harris scales first-class `ScaleType` families?
- are they an experimental `ordered_scale` family only?
- do they participate in `ModeType` identification, or remain explicit pedagogical named scales?

This plan treats Barry Harris as a gated track that can proceed only after ordered-scale semantics are explicit.

### 5. Voice-Leading Rules Should Reuse Existing Counterpoint State

New violation detectors must consume the same voice ordering and state assumptions already used by:
- `/Users/bermi/code/libmusictheory/src/voice_leading.zig`
- `/Users/bermi/code/libmusictheory/src/counterpoint.zig`

They should not create a second incompatible notion of voice identity or motion.

## Dependency Graph

```text
Phase 0: verify/docs/references guardrail
    ↓
Phase 1: ordered-scale foundation + honest mode inventory
    ↓
Phase 2: degree-aware note primitives
    - scale_degree
    - transpose_diatonic
    - nearest scale tone candidates / explicit tie policy
    ↓
Phase 3: modal interchange containment
    - depends on Phases 1-2

Phase 4: structured chord detection
    - depends on existing chord construction + note spelling
    - can proceed in parallel with Phase 3 after Phase 0

Phase 5: voice-leading rule detectors + suspension overlap audit
    - depends on existing voice_leading/counterpoint
    - SATB helpers depend on this phase's voice model decisions

Phase 6: Barry Harris evaluation gate
    - depends on Phase 1 ordered-scale layer
    - implementation only if semantics are clean and verification remains honest
```

## Phase Plan

### Phase 0 — Guardrails, References, And Scope Lock

Before implementation:
- update `/Users/bermi/code/libmusictheory/verify.sh` so each new phase has a concrete gate
- document the accepted references for each feature in the relevant research docs
- add the feature-policy note that Contrapunk heuristics are intentionally excluded

Files to modify:
- `/Users/bermi/code/libmusictheory/verify.sh`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/scale-mode-key.md`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/chord-construction-and-naming.md`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/voice-leading.md`

Exit criteria:
- the new lanes are named in `verify.sh`
- the plan's accepted vs rejected scope is reflected in research/docs

### Phase 1 — Ordered Scale Foundation And Mode Expansion

Deliver:
- internal ordered-scale representation for all supported named families
- 12 additional seven-note modes if reference validation holds:
  - Harmonic Minor
  - Locrian nat6
  - Ionian Aug
  - Dorian #4
  - Phrygian Dominant
  - Lydian #2
  - Super Locrian Dim
  - Double Harmonic
  - Hungarian Minor
  - Enigmatic
  - Neapolitan Minor
  - Neapolitan Major
- honest mode-count updates across Zig tests and C ABI documentation

Files to create/modify:
- create `/Users/bermi/code/libmusictheory/src/ordered_scale.zig`
- modify `/Users/bermi/code/libmusictheory/src/scale.zig`
- modify `/Users/bermi/code/libmusictheory/src/mode.zig`
- modify `/Users/bermi/code/libmusictheory/src/root.zig`
- modify `/Users/bermi/code/libmusictheory/src/c_api.zig`
- modify `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- create `/Users/bermi/code/libmusictheory/src/tests/ordered_scale_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/scales_modes_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/reference_data_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/property_test.zig`

C API additions:
- extend `lmt_mode_type`
- if absent, add reflection helpers for discovery:
  - `uint32_t lmt_mode_type_count(void);`
  - `const char *lmt_mode_type_name(uint32_t index);`

Scope: M

Explainability check:
- "Phrygian Dominant is the fifth mode of harmonic minor, so its scale degrees are 1, b2, 3, 4, 5, b6, b7."

### Phase 2 — Degree-Aware Note Primitives

Deliver:
- degree lookup
- degree-aware transposition with octave wrapping
- nearest scale tone candidates without hidden tie bias

Files to create/modify:
- modify `/Users/bermi/code/libmusictheory/src/ordered_scale.zig`
- modify `/Users/bermi/code/libmusictheory/src/c_api.zig`
- modify `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- create `/Users/bermi/code/libmusictheory/src/tests/diatonic_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/property_test.zig`
- modify `/Users/bermi/code/libmusictheory/docs/research/algorithms/scale-mode-key.md`

Recommended C API surface:
- `uint8_t lmt_scale_degree(lmt_pitch_class tonic, lmt_mode_type mode, lmt_midi_note note);`
- `lmt_midi_note lmt_transpose_diatonic(lmt_pitch_class tonic, lmt_mode_type mode, lmt_midi_note note, int8_t degrees);`
- primary structured API:
  - `typedef struct lmt_scale_snap_candidates { ... } lmt_scale_snap_candidates;`
  - `uint8_t lmt_nearest_scale_tones(lmt_pitch_class tonic, lmt_mode_type mode, lmt_midi_note note, lmt_scale_snap_candidates *out);`
- optional convenience API only if tie policy is explicit:
  - `lmt_midi_note lmt_snap_to_scale(lmt_pitch_class tonic, lmt_mode_type mode, lmt_midi_note note, lmt_snap_tie_policy policy);`

Scope: M

Explainability check:
- "E4 is degree 3 in C Ionian, so moving up two degrees lands on G4, a diatonic third above it."

### Phase 3 — Modal Interchange Containment

Deliver:
- parallel-mode containment search with no internal priority ordering
- per-match degree information so callers can explain each borrowed possibility

Files to create/modify:
- create `/Users/bermi/code/libmusictheory/src/modal_interchange.zig`
- modify `/Users/bermi/code/libmusictheory/src/root.zig`
- modify `/Users/bermi/code/libmusictheory/src/c_api.zig`
- modify `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- create `/Users/bermi/code/libmusictheory/src/tests/modal_interchange_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/property_test.zig`
- modify `/Users/bermi/code/libmusictheory/docs/research/algorithms/scale-mode-key.md`

Recommended C API surface:
- `typedef struct lmt_containing_mode_match { lmt_mode_type mode; uint8_t degree; } lmt_containing_mode_match;`
- `uint8_t lmt_find_containing_modes(lmt_pitch_class note_pc, lmt_pitch_class tonic, const lmt_mode_type *modes, uint8_t mode_count, lmt_containing_mode_match *out, uint8_t out_len);`

Scope: S

Explainability check:
- "F# is not in C Ionian, but it is in C Lydian as the raised fourth degree."

### Phase 4 — Structured Extended Chord Detection

Deliver:
- comptime-backed 39-pattern vocabulary cross-checked against `tonal-ts`
- exhaustive root testing over the observed PCS
- structured candidate output with explicit ambiguity handling
- formatting helpers for plain names and key-aware names

Files to create/modify:
- create `/Users/bermi/code/libmusictheory/src/chord_detection.zig`
- modify `/Users/bermi/code/libmusictheory/src/chord_construction.zig`
- modify `/Users/bermi/code/libmusictheory/src/root.zig`
- modify `/Users/bermi/code/libmusictheory/src/c_api.zig`
- modify `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- create `/Users/bermi/code/libmusictheory/src/tests/chord_detection_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/chord_construction_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/reference_data_test.zig`
- modify `/Users/bermi/code/libmusictheory/docs/research/algorithms/chord-construction-and-naming.md`

Recommended C API surface:
- `typedef struct lmt_chord_match { ... } lmt_chord_match;`
- `uint8_t lmt_detect_chord_matches(const lmt_midi_note *notes, uint8_t count, lmt_chord_match *out, uint8_t out_len);`
- `const char *lmt_format_chord_match(lmt_chord_match match);`
- `const char *lmt_format_chord_match_in_key(lmt_chord_match match, lmt_pitch_class key_tonic, lmt_key_quality quality);`

Critical rule:
- `lmt_detect_chord_matches` should surface tied matches rather than burying them behind table order.

Scope: L

Explainability check:
- "These notes form Cmaj7 because, measured from C, they contain 1, 3, 5, and 7."

### Phase 5 — Voice-Leading Rule Detectors And Suspension Audit

Deliver:
- explicit pairwise violation detectors for:
  - parallel fifths
  - parallel octaves/unisons
  - voice crossing
  - spacing violations
  - motion-independence collapse
- overlap audit between the current counterpoint suspension machine and textbook preparation-suspension-resolution behavior
- only the missing suspension detail gets added

Files to create/modify:
- create `/Users/bermi/code/libmusictheory/src/voice_leading_rules.zig`
- modify `/Users/bermi/code/libmusictheory/src/counterpoint.zig`
- modify `/Users/bermi/code/libmusictheory/src/voice_leading.zig`
- modify `/Users/bermi/code/libmusictheory/src/root.zig`
- modify `/Users/bermi/code/libmusictheory/src/c_api.zig`
- modify `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- create `/Users/bermi/code/libmusictheory/src/tests/voice_leading_rules_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/counterpoint_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- modify `/Users/bermi/code/libmusictheory/docs/research/algorithms/voice-leading.md`

Recommended C API surface:
- `typedef struct lmt_voice_pair_violation { uint8_t upper_voice; uint8_t lower_voice; uint8_t interval_class; } lmt_voice_pair_violation;`
- `uint8_t lmt_check_parallel_perfects(const lmt_voiced_state *prev, const lmt_voiced_state *curr, lmt_voice_pair_violation *out, uint8_t out_len);`
- `uint8_t lmt_check_voice_crossing(const lmt_voiced_state *state, lmt_voice_pair_violation *out, uint8_t out_len);`
- `uint8_t lmt_check_spacing(const lmt_voiced_state *state, lmt_voice_pair_violation *out, uint8_t out_len);`
- `uint8_t lmt_check_motion_independence(const lmt_voiced_state *prev, const lmt_voiced_state *curr);`
- extend `lmt_analyze_suspension_machine(...)` only if the current summary lacks enough textbook detail to explain preparation, dissonant hold, and resolution.

Scope: M

Explainability check:
- "This voicing is poor common-practice writing because alto and tenor move from one perfect fifth to another in similar motion."

### Phase 6 — SATB Register Helpers

Deliver:
- optional SATB range facts as experimental helpers
- no global correctness claims outside the choir-specific surface

Files to create/modify:
- create `/Users/bermi/code/libmusictheory/src/choir.zig`
- modify `/Users/bermi/code/libmusictheory/src/root.zig`
- modify `/Users/bermi/code/libmusictheory/src/c_api.zig`
- modify `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- create `/Users/bermi/code/libmusictheory/src/tests/choir_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- modify `/Users/bermi/code/libmusictheory/docs/research/algorithms/voice-leading.md`

Recommended C API surface:
- `typedef enum lmt_satb_voice { ... } lmt_satb_voice;`
- `uint8_t lmt_satb_range_contains(lmt_satb_voice voice, lmt_midi_note note);`
- `uint8_t lmt_check_satb_registers(const lmt_voiced_state *state, const lmt_satb_voice *voices, uint8_t voice_count, lmt_voice_pair_violation *out, uint8_t out_len);`

Scope: S

Explainability check:
- "This note is outside the conventional alto range used in four-part chorale writing."

### Phase 7 — Barry Harris Evaluation Gate

Deliver:
- a documented yes/no decision on whether Barry Harris belongs in the core ordered-scale surface
- implementation only if the API can stay explicit and explainable

Questions the gate must answer:
- Are Barry Harris families modeled as `ScaleType`, `ModeType`, or experimental ordered-scale names only?
- Can `identifyMode` remain honest if Barry Harris joins the public mode table?
- Do parity/chord-tone semantics require a dedicated API rather than overloading plain mode identification?

If accepted, files to create/modify:
- modify `/Users/bermi/code/libmusictheory/src/ordered_scale.zig`
- modify `/Users/bermi/code/libmusictheory/src/scale.zig`
- modify `/Users/bermi/code/libmusictheory/src/mode.zig` only if mode semantics remain clean
- modify `/Users/bermi/code/libmusictheory/src/root.zig`
- modify `/Users/bermi/code/libmusictheory/src/c_api.zig`
- modify `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- create `/Users/bermi/code/libmusictheory/src/tests/barry_harris_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- modify `/Users/bermi/code/libmusictheory/src/tests/property_test.zig`
- modify `/Users/bermi/code/libmusictheory/docs/research/algorithms/scale-mode-key.md`

Recommended C API surface if accepted:
- `uint8_t lmt_ordered_scale_degree_count(...);`
- `uint8_t lmt_barry_harris_parity(...);` only if the parity rule is surfaced explicitly and not smuggled into generic scale APIs

Scope: M (evaluation) / L (if implemented)

Explainability check:
- "In the major sixth diminished scale, moving by two degrees preserves chord-tone parity because the scale alternates chord tones and passing tones."

## Feature Ledger

| Feature | Internal Files | C API Additions | Tests | Scope | Explainability Sentence |
| --- | --- | --- | --- | --- | --- |
| Ordered scale foundation | `src/ordered_scale.zig`, `src/scale.zig`, `src/mode.zig`, `src/root.zig` | internal-first; mode discovery helpers if needed | `src/tests/ordered_scale_test.zig`, `src/tests/scales_modes_test.zig`, `src/tests/property_test.zig` | M | "This mode is defined by these ordered degrees, so degree arithmetic is a fact about the scale, not a heuristic." |
| 12 missing seven-note modes | `src/mode.zig`, `src/scale.zig`, `src/c_api.zig`, `include/libmusictheory.h` | extend `lmt_mode_type`; optional count/name helpers | `src/tests/scales_modes_test.zig`, `src/tests/c_api_test.zig`, `src/tests/reference_data_test.zig` | M | "This mode belongs to a named family and is identified by its degree pattern and interval content." |
| Diatonic transposition | `src/ordered_scale.zig`, `src/c_api.zig`, `include/libmusictheory.h` | `lmt_scale_degree`, `lmt_transpose_diatonic`, nearest-scale structured helper | `src/tests/diatonic_test.zig`, `src/tests/c_api_test.zig`, `src/tests/property_test.zig` | M | "A diatonic third above E in C major is G because degree 3 moves to degree 5 within that scale." |
| Modal interchange containment | `src/modal_interchange.zig`, `src/ordered_scale.zig`, `src/c_api.zig`, `include/libmusictheory.h` | `lmt_find_containing_modes`, `lmt_containing_mode_match` | `src/tests/modal_interchange_test.zig`, `src/tests/c_api_test.zig`, `src/tests/property_test.zig` | S | "This outside note becomes explainable once you show which parallel modes actually contain it." |
| Structured chord detection | `src/chord_detection.zig`, `src/chord_construction.zig`, `src/c_api.zig`, `include/libmusictheory.h` | `lmt_detect_chord_matches`, `lmt_format_chord_match`, `lmt_chord_match` | `src/tests/chord_detection_test.zig`, `src/tests/chord_construction_test.zig`, `src/tests/c_api_test.zig`, `src/tests/reference_data_test.zig` | L | "The detected chord is justified by its interval set from the proposed root, not by a tuned score." |
| Voice-leading rule checks | `src/voice_leading_rules.zig`, `src/voice_leading.zig`, `src/counterpoint.zig`, `src/c_api.zig`, `include/libmusictheory.h` | pairwise violation structs + check functions | `src/tests/voice_leading_rules_test.zig`, `src/tests/counterpoint_test.zig`, `src/tests/c_api_test.zig` | M | "The violation is explainable because these two named voices move into or maintain a prohibited relationship." |
| Suspension overlap audit | `src/counterpoint.zig`, `src/c_api.zig`, `include/libmusictheory.h` | extend existing suspension summary only if needed | `src/tests/counterpoint_test.zig`, `src/tests/c_api_test.zig` | S | "This is a suspension because a prepared tone is held into dissonance and then resolves by step." |
| SATB range helpers | `src/choir.zig`, `src/c_api.zig`, `include/libmusictheory.h` | SATB range membership helpers | `src/tests/choir_test.zig`, `src/tests/c_api_test.zig` | S | "This range check is specific to four-part choral writing, not a universal rule of music." |
| Barry Harris evaluation | `src/ordered_scale.zig`, `src/scale.zig`, optional `src/mode.zig`, `src/c_api.zig`, `include/libmusictheory.h` | only if semantics stay explicit | `src/tests/barry_harris_test.zig`, `src/tests/c_api_test.zig`, `src/tests/property_test.zig` | M/L | "The usefulness here comes from the documented parity rule, not from importing Barry Harris stylistic defaults wholesale." |

## Structural Decisions Needing Resolution

1. **Mode count honesty**
   - The request says "11 new modes," but the missing seven-note set is 12 if the full harmonic-minor family and the 5 named exotic modes are all added.
   - Resolution required before coding: treat the count as 12 or narrow the requested scope intentionally.

2. **Ordered-scale boundary**
   - Decide whether degree-aware note operations live in a new internal module (`ordered_scale.zig`) or are spread across `scale.zig` and `mode.zig`.
   - Recommended: one internal ordered-scale layer to avoid mixing PCS identity logic with note-level degree logic.

3. **Chord detection boundary**
   - Keep `src/chord_construction.zig` as formula/PCS construction.
   - Put pattern matching, ambiguity handling, and formatting in `src/chord_detection.zig`.

4. **String helpers vs structured results**
   - All new explainability-critical surfaces should return structs first and strings second.
   - This especially matters for chord detection and modal interchange.

5. **Nearest-scale-tone policy**
   - No silent lower-on-tie behavior.
   - Resolution required: either expose two nearest candidates or require an explicit tie policy enum.

6. **Suspension overlap**
   - First document whether the current `counterpoint` suspension summary already covers preparation, held dissonance, and resolution well enough for an LLM explanation.
   - Only then add or extend fields.

7. **SATB scope**
   - Keep SATB helpers experimental and choir-specific.
   - They must not become generic validity gates for all composition contexts.

8. **Barry Harris placement**
   - Decide whether Barry Harris is:
     - a public `ScaleType`
     - a public `ModeType`
     - an experimental ordered-scale family only
     - or deferred entirely
   - Recommended default: evaluate after Phase 2, do not commit it up front.

## Verification Checklist Per Phase

### Phase 0
- `./verify.sh`
- verify that new lane names appear in `verify.sh`
- confirm docs explicitly reject Contrapunk heuristic weights and preference orderings

### Phase 1
- `./verify.sh`
- `./zigw build test`
- reference cross-check against `/Users/bermi/tmp/tonal-ts/packages/dictionary/data/scales.json`
- property check that every added mode is identifiable and has the expected cardinality

### Phase 2
- `./verify.sh`
- `./zigw build test`
- property tests:
  - transpose up `N`, then down `N`, returns original note for in-scale notes
  - degree lookup matches ordered offsets for all supported modes and tonics
  - nearest-scale helper always returns in-scale notes

### Phase 3
- `./verify.sh`
- `./zigw build test`
- property test that every returned containing mode actually contains the queried pitch class
- objective cross-checks against Contrapunk tests only for containment facts, not for mode preference ordering

### Phase 4
- `./verify.sh`
- `./zigw build test`
- reference cross-check against `/Users/bermi/tmp/tonal-ts/packages/dictionary/data/chords.json`
- round-trip property: `detect(construct(type, root))` returns a matching candidate for every supported pattern
- ambiguity tests where more than one chord interpretation is valid

### Phase 5
- `./verify.sh`
- `./zigw build test`
- unit tests with textbook facts for parallel fifths, octaves, crossing, spacing, and motion collapse
- confirm no duplicate or contradictory suspension state machinery was introduced

### Phase 6
- `./verify.sh`
- `./zigw build test`
- unit tests for standard SATB range facts
- confirm these helpers stay experimental and are not wired into unrelated validation paths

### Phase 7
- `./verify.sh`
- `./zigw build test`
- explicit written decision in docs whether Barry Harris is accepted, experimental, or deferred
- if implemented, property tests for parity behavior and degree-count correctness

## Acceptance Criteria

This plan is ready to split into implementation slices only when:
- the mode-count discrepancy is resolved honestly
- the ordered-scale boundary is accepted
- chord detection is approved as a structured API rather than string-only
- nearest-scale behavior has an explicit tie policy decision
- Barry Harris is explicitly marked as gated rather than assumed

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh`, `zig build verify`
