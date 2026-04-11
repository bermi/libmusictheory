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
