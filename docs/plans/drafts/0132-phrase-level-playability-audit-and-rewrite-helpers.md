# 0132 — Phrase-Level Playability Audit, Committed Memory, And Repair Helpers

## Status

- Draft: 2026-04-11
- Updated: 2026-04-12

## Goal

Extend the experimental `playability` family from local realizations and next-step checks to phrase-level auditing so `libmusictheory` can tell a host or LLM:
- where a passage becomes physically implausible
- which event or transition is the phrase bottleneck
- whether the difficulty comes from span, shift, repetition, or unresolved load
- which accepted choices should bias later suggestions
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
- "this next move is better because you already committed the last two accepted states"

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
- explicit committed-memory semantics for accepted choices
- explicit repair classes with caller-selected permissions

Reject:
- black-box phrase difficulty scores with no reason breakdown
- automatic compositional rewrites that silently change musical meaning
- hidden style policies about what counts as an acceptable simplification
- hidden global mutable state in the library

## Critical Boundary: Library Memory Versus Host UI State

This roadmap needs a strict boundary.

### Library-owned working memory

If a choice is meant to change later music-theory or playability results, it belongs in caller-owned library memory.

That includes:
- committed voiced states
- committed keyboard phrase events
- committed fret phrase events
- phrase summaries derived from committed event streams
- next-step bias derived from committed accepted history

### Host-owned UI memory

If something only controls presentation or browser interaction, it stays outside the library.

That includes:
- hover state
- preview pins
- active Web MIDI devices
- local storage snapshots
- virtual keyboard toggles before commit
- "return to live" versus "previewing snapshot"

### Design consequence

The library should not grow a hidden singleton blackboard.

Instead, it should expose explicit caller-owned state, in the same style as `lmt_voiced_history`:
- reset
- push or append
- inspect
- summarize
- use that committed state to bias later ranking when the caller asks for it

## Scope

1. Add a phrase event model for playability audits.
2. Add phrase-level audit helpers for:
   - fixed fret realizations and transitions
   - fixed keyboard realizations and transitions
3. Add committed phrase memory for accepted choices.
4. Add structured phrase summaries:
   - max bottleneck severity
   - cumulative strain bucket
   - first blocked event
   - first blocked transition
   - issue counts by reason or warning family
5. Add controlled repair helpers that can propose minimal alternatives using explicit caller policy.
6. Add focused docs and host examples that show how committed memory, audit, and repair interact.

## Structural Decision: Commit Versus Preview

This is the key interaction model that keeps the API coherent.

### Preview
- host-owned
- does not change future ranking state
- examples: hover, inspect, pin for comparison

### Commit
- library-relevant
- appends an accepted event or state into caller-owned phrase memory
- later ranking and auditing can use that committed memory explicitly

A host must never treat preview focus as if it were a committed musical choice.

## Structural Decision: Repair Policy Boundary

The repair surface must distinguish three different things:

1. `realization_only`
- same sounding notes
- same onset structure
- same musical event sequence
- only the physical realization changes

2. `register_adjusted`
- same event count
- same harmonic target is preserved as closely as possible
- one or more notes may move by octave or swap voicing order
- still a musical change

3. `texture_reduced`
- the musical surface changes more materially
- some notes may be omitted or simplified
- constrained by explicit preservation rules

The API must never mix these categories into one undifferentiated ranked list.

## Non-Goals

Not in scope for the core library slices:
- hidden browser-session memory
- localStorage persistence semantics
- Web MIDI device management
- UI hover or pin logic
- silent note deletion or octave displacement unless a repair policy explicitly allows it

These belong in host slices built on the core API.

## Proposed API Direction

Everything starts experimental and caller-buffered.

### New structs

- `lmt_playability_phrase_issue`
- `lmt_playability_phrase_summary`
- `lmt_keyboard_phrase_memory`
- `lmt_fret_phrase_memory`
- `lmt_playability_repair_policy`
- `lmt_ranked_phrase_repair`

### Proposed committed-memory helpers

- `lmt_keyboard_phrase_memory_reset`
- `lmt_keyboard_phrase_memory_push_event`
- `lmt_keyboard_phrase_memory_len`
- `lmt_fret_phrase_memory_reset`
- `lmt_fret_phrase_memory_push_event`
- `lmt_fret_phrase_memory_len`
- helpers that bias later ranking or phrase summarization from the committed memory

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

## Design Constraints

1. Stay deterministic.
2. Keep all outputs decomposable into reasons, warnings, blockers, and repair classes.
3. Phrase auditing must build on the existing local assessment engines rather than duplicating them.
4. Repair helpers must require explicit policy input from the caller.
5. Committed memory must be caller-owned explicit state, not hidden global library state.
6. The API must distinguish:
   - fixed realization auditing
   - committed memory that biases future steps
   - alternative realization repair
   - composition-changing repair
7. Phrase auditing should accept caller-authored event boundaries rather than infer meter or phrasing heuristically.

## Explainability Contract

Every phrase-level result should support a sentence like one of these:

- "The phrase becomes blocked at event 6 because the required right-hand span exceeds the configured practical range."
- "The hardest move is the jump into event 9; it is reachable, but it creates the largest bottleneck in the passage."
- "This next move is favored because your committed phrase memory already established an anchor that avoids another large shift."
- "This repair keeps the same pitch targets but moves the fret realization into a lower-shift window."

If the API cannot support a sentence like that, it is too opaque for this repo.

## Critical Review And Pushback

### What fits cleanly

- score verification for LLM output
- practice-app warnings
- explainable bottleneck detection
- committed-memory-informed ranking
- localized repair suggestions

### What needs caution

- phrase repair can slide into composition rewriting
- keyboard phrases become ambiguous once both hands and redistributed voices are involved
- a generic library "blackboard" can become a dump for UI state if we do not keep the boundary explicit

### What we should defer

- full two-hand piano assignment
- bass-technique-specific right-hand models
- decorative timeline or blackboard UI semantics inside the library

## Suggested Execution Order

1. Phrase event and summary structs.
2. Fixed-realization phrase auditing for fret and keyboard.
3. Committed phrase memory and choice-bias helpers.
4. Explicit repair-policy model.
5. Minimal repair suggestion helpers.
6. Host/gallery adoption for committed blackboard workflows and no-MIDI fallback.
7. Docs and examples for host and LLM usage.

## Planned Follow-On Slices

### 0133 - Phrase Event Model And Audit Summaries

Define the event-level phrase model, issue records, phrase summary structs, and the shared phrase-audit vocabulary for bottlenecks, cumulative load, and issue clustering.

### 0134 - Fixed-Realization Phrase Audit Engines

Add the actual phrase-audit passes for keyboard and fret sequences by composing the existing local realization and transition assessors over explicit event streams.

### 0135 - Committed Phrase Memory And Choice Bias

Add caller-owned committed phrase memory so accepted choices can bias future ranking and phrase analysis without introducing hidden global state.

### 0136 - Repair Policy And Ranked Phrase Repairs

Add the explicit repair-policy surface plus ranked repair candidates, keeping `realization_only`, `register_adjusted`, and `texture_reduced` outputs visibly distinct.

### 0137 - Gallery Phrase Blackboard And Virtual Keyboard Fallback

Adapt the gallery host so preview pins stay UI-local, committed choices are written into library-backed phrase memory, and the MIDI scene remains usable without hardware by letting users toggle notes from a virtual keyboard.

### 0138 - Phrase Audit Docs And Host Adoption

Document the intended usage in the unified API docs and host examples with explicit distinctions between audit-only, committed-memory bias, realization-only repair, and music-changing repair.

## Dependency Graph

```text
0132 phrase-level-playability-audit-and-rewrite-helpers
  -> 0133 phrase-event-model-and-audit-summaries
       -> 0134 fixed-realization-phrase-audit-engines
            -> 0135 committed-phrase-memory-and-choice-bias
                 -> 0136 repair-policy-and-ranked-phrase-repairs
                      -> 0137 gallery-phrase-blackboard-and-virtual-keyboard-fallback
                           -> 0138 phrase-audit-docs-and-host-adoption
```

## Verification

- `/Users/bermi/code/libmusictheory/./verify.sh`
- focused Zig tests for phrase audit, committed-memory, and repair helpers
- C ABI tests for every new exported struct and helper
- host validation that preview and commit are distinct behaviors

## Completion Gate

This roadmap is complete when a host can:
- pass a short phrase into the library
- receive a phrase summary and issue list with named reasons
- commit accepted choices into caller-owned library memory
- rerank later suggestions from that committed memory explicitly
- ask for allowed repair classes explicitly
- get ranked repair candidates whose tradeoffs are explainable in plain music-plus-playability language
