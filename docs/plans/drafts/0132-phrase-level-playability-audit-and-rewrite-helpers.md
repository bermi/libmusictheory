# 0132 — Phrase-Level Playability Audit And Rewrite Helpers

## Status

- Draft: 2026-04-11

## Goal

Extend the experimental `playability` family from local realizations and next-step checks to phrase-level auditing so `libmusictheory` can tell a host or LLM:
- where a passage becomes physically implausible
- which event or transition is the phrase bottleneck
- whether the difficulty comes from span, shift, repetition, or unresolved load
- what minimal, explainable repair options exist when a passage should stay musically similar but become more playable

## Why This Is The Right Post-0131 Slice

The current library can already assess:
- one realization
- one transition
- one ranked local next step
- one practice-oriented easier or safer alternative

What it still cannot do cleanly is audit a whole phrase and explain:
- "measure 3 is the bottleneck"
- "the same hand never recovers after the previous stretch"
- "this chord is locally reachable, but the phrase becomes unplayable because the next jump compounds the strain"

That is the missing bridge between:
- theory-valid generation
- local playability hints
- real score verification for practice tools and LLM composition systems

## Product Principle

This slice should produce explainable phrase facts, not opaque difficulty magic.

Adopt:
- bottleneck location
- accumulated load windows
- phrase-local issue clusters
- explicit repair classes with caller-selected permissions

Reject:
- black-box phrase difficulty scores with no reason breakdown
- automatic compositional rewrites that silently change musical meaning
- hidden style policies about what counts as an acceptable simplification
- premature hand-animation or gallery-heavy work before the core audit semantics exist

## Scope

1. Add a phrase event model for playability audits.
2. Add phrase-level audit helpers for:
   - fixed fret realizations and transitions
   - fixed keyboard realizations and transitions
3. Add structured phrase summaries:
   - max bottleneck severity
   - cumulative strain bucket
   - first blocked event
   - first blocked transition
   - issue counts by reason/warning family
4. Add controlled repair helpers that can propose minimal alternatives using explicit caller policy.
5. Add focused docs and tests that show how hosts and LLMs should consume the new audit layer.

## Structural Decision: Repair Policy Boundary

This is the most important design decision in the slice.

The repair surface must distinguish three different things:

1. `realization-only repair`
- same sounding notes
- same onset structure
- same musical event sequence
- only the physical realization changes

Examples:
- different fret/string location for the same note
- different keyboard fingering for the same chord
- different anchor window or hand shift plan with identical sounding output

2. `register-preserving musical repair`
- same event count
- same harmonic target is preserved as closely as possible
- one or more notes may move by octave or swap voicing order
- this is a musical change, but still a conservative one

Examples:
- move one inner note up an octave
- respread a keyboard voicing between adjacent registers
- move a guitar note to a different octave while preserving chord quality and anchors

3. `texture-reducing musical repair`
- the musical surface changes more materially
- some notes may be omitted or simplified
- still constrained by explicit preservation rules

Examples:
- drop a doubled pitch
- reduce a five-note sonority to a shell voicing
- remove a non-structural inner note to restore playability

The API must never mix these categories into one undifferentiated ranked list.

## Repair Policy Rules

The caller should always choose an explicit repair policy struct rather than rely on defaults.

Minimum policy axes:
- whether realization-only repairs are allowed
- whether octave displacement is allowed
- whether note omission is allowed
- whether note reordering within the event is allowed
- whether top voice must be preserved
- whether bass voice must be preserved
- whether chord root must be preserved when identifiable
- maximum events that may be altered
- maximum notes per event that may be altered

That makes the downstream explanation and UX clean:
- "show me another fingering"
- "allow octave moves but do not delete notes"
- "allow note thinning, but keep the bass and top voice fixed"

## Repair Result Taxonomy

Every ranked repair should carry:
- `repair_class`
  - `realization_only`
  - `register_adjusted`
  - `texture_reduced`
- `events_touched`
- `notes_changed`
- `preserves_bass`
- `preserves_top_voice`
- `preserves_root`
- `playability_lift`
- `musical_deviation_flags`

That prevents a host from presenting a note-thinned fallback as if it were just an alternate fingering.

## Non-Goals

This slice should not try to solve everything at once.

Not in scope:
- two-hand piano voice-to-hand assignment
- right-hand bass slap/pop mechanics
- generic score engraving or notation timeline rendering
- automatic reharmonization
- silent note deletion or octave displacement unless a repair policy explicitly allows it
- a new gallery scene

If we need a gallery surface later, it should be a follow-up slice built on stable audit outputs.

## Proposed API Direction

Everything starts experimental and caller-buffered.

### New structs

- `lmt_playability_phrase_event`
- `lmt_playability_phrase_issue`
- `lmt_playability_phrase_summary`
- `lmt_playability_repair_policy`
- `lmt_ranked_phrase_repair`

### Proposed repair-policy fields

- `allow_realization_only_repairs`
- `allow_octave_displacement`
- `allow_note_omission`
- `allow_note_reordering`
- `preserve_bass_voice`
- `preserve_top_voice`
- `preserve_identified_root`
- `max_events_touched`
- `max_notes_changed_per_event`

### Proposed phrase-summary fields

- `first_blocked_event_index`
- `first_blocked_transition_index`
- `max_bottleneck_cost`
- `cumulative_cost`
- `issue_count`
- `blocked_issue_count`
- `warning_issue_count`
- `peak_span`
- `peak_shift`
- `recovery_deficit_count`
- `dominant_reason`
- `dominant_warning`

### New helpers

- `lmt_assess_fret_phrase_n`
- `lmt_assess_keyboard_phrase_n`
- `lmt_summarize_fret_phrase_playability`
- `lmt_summarize_keyboard_phrase_playability`
- `lmt_suggest_fret_phrase_repairs_n`
- `lmt_suggest_keyboard_phrase_repairs_n`

### Likely internal modules

- `/Users/bermi/code/libmusictheory/src/playability/phrase.zig`
- `/Users/bermi/code/libmusictheory/src/playability/repair.zig`

### Supporting files

- `/Users/bermi/code/libmusictheory/src/c_api.zig`
- `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- `/Users/bermi/code/libmusictheory/src/tests/playability_phrase_test.zig`
- `/Users/bermi/code/libmusictheory/src/tests/c_api_test.zig`
- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/docs/research/algorithms/playability.md`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Design Constraints

1. Stay deterministic.
2. Keep all outputs decomposable into reasons, warnings, blockers, and repair classes.
3. Phrase auditing must build on the existing local assessment engines rather than duplicating them.
4. Repair helpers must require explicit policy input from the caller.
5. The API must distinguish:
   - fixed realization auditing
   - alternative realization repair
   - composition-changing repair

That last distinction matters for DX. A host must be able to say:
- "only show alternate fingerings"
- "allow octave displacement"
- "allow note thinning"

without guessing what the library changed.

6. Phrase auditing should accept caller-authored event boundaries rather than infer meter or phrasing heuristically.
7. Repair helpers may rank candidates, but they must never silently cross a policy boundary.

## Phrase Model Boundary

The first version of phrase auditing should work on explicit event sequences, not full notation semantics.

That means callers provide:
- event-ordered note groups
- already-realized fret or keyboard state per event, or enough information to derive it
- optional timing weights if they want denser events to count more heavily

That avoids overpromising:
- no meter inference
- no beat-strength inference
- no automatic phrase segmentation from notation

If a host wants bar-aware or beat-aware language, it can map event indexes back to score locations itself.

## Explainability Contract

Every phrase-level result should support a sentence like one of these:

- "The phrase becomes blocked at event 6 because the required right-hand span exceeds the configured practical range."
- "The hardest move is the jump into event 9; it is reachable, but it creates the largest bottleneck in the passage."
- "This repair keeps the same pitch targets but moves the fret realization into a lower-shift window."
- "This alternate keyboard fingering preserves the chord but reduces repeated weak-finger use across the sequence."

If the API cannot support a sentence like that, it is too opaque for this repo.

## Critical Review And Pushback

### What fits cleanly

- score verification for LLM output
- practice-app warnings
- explainable bottleneck detection
- localized repair suggestions

### What needs caution

- phrase repair can easily slide into composition rewriting
- keyboard phrases become ambiguous once both hands and redistributed voices are involved
- note-thinning or octave-drop suggestions are useful, but they must be opt-in and visibly labeled as musical compromises
- phrase difficulty summaries can become misleading if they imply a single universal score rather than explicit bottleneck and cumulative facts

### What we should defer

- full two-hand piano assignment
- bass-technique-specific right-hand models
- decorative timeline/gallery UI

Those are worthwhile, but they should sit on top of a solid phrase-audit core.

## Suggested Execution Order

1. Phrase event and summary structs.
2. Fixed-realization phrase auditing for fret and keyboard.
3. Phrase issue extraction and summary helpers.
4. Explicit repair-policy model.
5. Minimal repair suggestion helpers.
6. Docs and C ABI examples for host/LLM usage.

## Planned Follow-On Slices

### 0133 - Phrase Event Model And Audit Summaries

Define the event-level phrase model, issue records, phrase summary structs, and the shared phrase-audit vocabulary for bottlenecks, cumulative load, and issue clustering.

### 0134 - Fixed-Realization Phrase Audit Engines

Add the actual phrase-audit passes for keyboard and fret sequences by composing the existing local realization and transition assessors over explicit event streams.

### 0135 - Repair Policy And Ranked Phrase Repairs

Add the explicit repair-policy surface plus ranked repair candidates, keeping `realization_only`, `register_adjusted`, and `texture_reduced` outputs visibly distinct.

### 0136 - Phrase Audit Docs And Host Adoption

Document the intended usage in the unified API docs with examples aimed at:
- LLM verification of generated passages
- practice-app bottleneck reporting
- conservative versus music-changing repair requests

## Dependency Graph

```text
0132 phrase-level-playability-audit-and-rewrite-helpers
  -> 0133 phrase-event-model-and-audit-summaries
       -> 0134 fixed-realization-phrase-audit-engines
            -> 0135 repair-policy-and-ranked-phrase-repairs
                 -> 0136 phrase-audit-docs-and-host-adoption
```

## Verification

- `/Users/bermi/code/libmusictheory/./verify.sh`
- focused Zig tests for phrase audit and repair helpers
- C ABI tests for every new exported struct and helper
- docs examples proving the repair-policy distinction is explicit

## Completion Gate

This slice is complete when a host can:
- pass a short phrase into the library
- receive a phrase summary and issue list with named reasons
- ask for allowed repair classes explicitly
- get ranked repair candidates whose tradeoffs are explainable in plain music-plus-playability language
