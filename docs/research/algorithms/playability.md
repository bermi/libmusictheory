# Playability Foundations

This note captures the research-backed foundation for the experimental `playability` API family.

## Scope

`0124` does not attempt global fingering search. It provides the shared state and topology primitives required by later slices:

- explicit hand-profile limits
- explicit temporal load memory
- fretboard location windows for arbitrary tunings
- keyboard key geometry and span state

## Why This Shape

The core papers converge on the same structural need: playability decisions depend on physical state, recent motion, and instrument topology, not just the next symbolic note.

- Hori and Sagayama, *Minimax Viterbi Algorithm for HMM-Based Guitar Fingering Decision*:
  bottleneck difficulty matters, so later ranking needs persistent shift/span state rather than stateless note scoring.
- Tuohy and Potter, *Topological Considerations for Tuning and Fingering Stringed Instruments*:
  fretted instruments need tuning-aware location lookup that works across arbitrary string counts and tunings.
- Balliauw, Herremans, and Sørensen, *A Variable Neighborhood Search Algorithm to Generate Piano Fingerings for Polyphonic Sheet Music*:
  keyboard playability depends on span and local hand geometry, not only pitch classes.
- Moulton et al., *Checklist Models for Improved Output Fluency in Piano Fingering Prediction*:
  recent motion history matters, so the library needs temporal load state instead of single-step heuristics.

## Public Semantics

The public umbrella term is `playability`, not `biomechanics`.

That keeps the API explainable without implying medical diagnosis. The library can say:

- "this note is reachable inside the current window"
- "this move requires a shift"
- "this chord exceeds the comfort span"

It should not claim injury prediction or medical certainty.

## Current Foundation Types

- `HandProfile`
  caller-provided comfort and limit spans/shifts
- `TemporalLoadState`
  event count, last anchor, last span, last shift, peak span/shift, cumulative span/shift
- `fret_topology.PlayState`
  current anchor fret, active strings, open/fretted counts, span, and updated load
- `keyboard_topology.PlayState`
  low/high note bounds, black/white key exposure, span, and updated load

## Explainability Contract

Every surfaced result from this slice should support a direct explanation, for example:

- "C4 is available on two strings in this tuning, but only one location lies inside the current comfort window anchored at fret 7."
- "This triad spans seven semitones, which fits inside the current keyboard comfort span."

Later slices may rank or filter candidates, but they should build on these explicit facts rather than invent hidden weights.

## 0127 - Opt-In Playability-Aware Reranking

`0127` adds an explicit policy layer on top of the existing theory-first candidate generators.

The important constraint is semantic separation:

- `lmt_rank_next_steps` and `lmt_rank_context_suggestions` stay theory-first
- playability-aware filtering and reranking are opt-in wrapper calls
- the wrapper returns both the original theory candidate and the playability transition facts used to accept, block, or reorder it

This keeps the API explainable for downstream tools and LLMs:

- "This continuation remains first under the balanced policy because it has the strongest harmonic score and no playability blocker."
- "This continuation drops under the minimax bottleneck policy because it creates the hardest single move in the local phrase."
- "This context suggestion is filtered out because it exceeds the configured keyboard shift limit from the current anchor."

### Named Policies

The public policy vocabulary is intentionally small and explicit:

- `balanced`
  preserve theory priority among playable candidates, then break ties with fewer playability warnings and lower strain
- `minimax bottleneck`
  minimize the hardest local move first, reflecting the guitar-fingering minimax literature
- `cumulative strain`
  minimize the running total of span and shift burden first

These policies are not hidden weights. They are fixed comparison orders over already-exposed facts:

- blocker presence
- theory score
- warning count
- bottleneck cost
- cumulative cost

### Research Connection

- Hori and Sagayama, *Minimax Viterbi Algorithm for HMM-Based Guitar Fingering Decision*:
  motivates exposing a minimax bottleneck policy instead of only cumulative difficulty.
- Balliauw, Herremans, and Sørensen, *A Variable Neighborhood Search Algorithm to Generate Piano Fingerings for Polyphonic Sheet Music*:
  supports using explicit local span/shift burdens and warning counts as ranking facts.
- Moulton et al., *Checklist Models for Improved Output Fluency in Piano Fingering Prediction*:
  supports carrying recent-motion load forward so reranking can account for fluency degradation from recent motion.

### Current Scope

`0127` applies the wrapper layer to keyboard playability first:

- counterpoint next-step suggestions can be reranked or filtered by keyboard playability
- keyboard context suggestions can be reranked with an explicit realized-note choice near the current anchor register

Fret-specific candidate reranking and multi-instrument consensus can layer on the same policy vocabulary later without changing the theory-first base APIs.

## 0129 - Personalized Profiles And Practice Feedback

`0129` adds a thin personalization layer without changing the underlying assessment facts.

The key API decision is that presets are not universal hand models. They are explicit adjustments applied to a caller-selected base profile:

- `compact-beginner`
  narrows span and shift comfort windows and forces low-tension preference
- `balanced-standard`
  preserves the base profile exactly
- `span-tolerant`
  widens span windows while keeping shift semantics unchanged
- `shift-tolerant`
  widens shift windows while keeping span semantics unchanged

This keeps the surface explainable:

- "Under the compact-beginner preset, the same keyboard hand keeps five fingers, but the comfort span and shift windows are narrower."
- "Under the span-tolerant preset, this voicing is still the same harmonic target; the profile simply allows a wider comfort span before warning."

### Why Presets Are Delta-Based

The same raw `HandProfile` type is shared by keyboard and fret playability. A universal preset that overwrote `finger_count` would be misleading across instruments.

So the preset API applies deltas to a caller-supplied base profile instead:

- keyboard hosts can start from the default keyboard hand profile
- fret hosts can start from the default profile for the selected technique
- advanced callers can still bypass presets and provide raw parameters directly

### Difficulty Summaries

`0129` also adds explicit difficulty summaries for practice and generation tools.

These summaries do not replace the detailed assessments. They compress the same facts into a compact report:

- accepted or blocked
- blocker, warning, and reason counts
- bottleneck and cumulative cost
- current span and shift burden
- recent peak load
- remaining comfort and hard-limit headroom

That lets downstream tools say:

- "This realization is blocked because the shift margin is negative."
- "This option is playable, but it has only one semitone of comfort-span headroom left."
- "This alternative keeps the musical target but lowers the bottleneck cost."

## 0133 - Phrase Event Model And Audit Summaries

`0133` adds the shared phrase vocabulary that the later audit and repair slices build on.

The important boundary is still intact:

- no phrase audit engine yet
- no committed phrase memory yet
- no gallery pin or preview semantics in the library

This slice only standardizes the facts later slices need to agree on:

- `KeyboardPhraseEvent`
  a fixed-size single-hand event carrying a realized note list
- `FretPhraseEvent`
  a fixed-size realized fret event carrying caller-provided string choices
- `PhraseIssue`
  an explainable issue row with:
  - event or transition scope
  - advisory, warning, or blocked severity
  - a family-domain namespace
  - explicit event indices
  - a caller-visible magnitude
- `PhraseSummary`
  a compact phrase-level report with:
  - first blocked event
  - first blocked transition
  - bottleneck issue metadata
  - dominant reason and warning families
  - severity/family counts
  - recovery-deficit run metadata
  - a named strain bucket

### Why The Issue Row Needs Domains

Later phrase audits need to explain more than "something is hard."

The same phrase can contain:

- a general playability reason
- a general playability warning
- a fret-specific blocker
- a keyboard-specific blocker

So the shared issue row uses a `FamilyDomain` instead of pretending one flat enum can explain every instrument-specific blocker.

That keeps downstream explanations honest:

- "The bottleneck is a keyboard shift hard limit."
- "The dominant warning family is shift required."
- "The phrase keeps reaching relief facts like open-string relief, so the strain never accumulates into a recovery deficit."

### Strain Buckets Stay Rule-Based

The strain bucket is intentionally small and explicit:

- `neutral`
  no warning or blocked issue survives into the phrase summary
- `elevated`
  warnings exist, but they do not yet form a sustained recovery deficit
- `high`
  warnings persist across multiple consecutive events without recovery
- `blocked`
  at least one blocked issue exists

This avoids a fake "difficulty score" while still giving hosts and LLMs a phrase-level answer they can explain.

## 0134 - Fixed-Realization Phrase Audit Engines

`0134` turns the shared phrase vocabulary into real audit passes for already chosen keyboard and fret realizations.

The public boundary stays explicit:

- this is a fixed-realization phrase audit
- it does not rewrite the music
- it does not introduce committed phrase memory
- it does not treat gallery hover or pin state as library memory

### What The Audit Adds

For both keyboard and fret phrases, the audit now composes:

- event-local realization issues
- transition-local issues between adjacent realized events
- repeated warning clusters
- recovery-deficit runs

That lets a host or LLM say things like:

- "This phrase is locally playable event by event, but it contains a warning cluster of repeated maximal stretches."
- "The hand continuity reset breaks the recovery-deficit run when the phrase switches hands."
- "The phrase stays unchanged musically; the audit only reports why the current realization is becoming strained."

### Hand Continuity Reset

Keyboard phrase events carry an explicit hand role, so the audit must not pretend a same-hand shift exists across a hand change.

When adjacent events switch from one hand to the other, the audit emits a `hand continuity reset` advisory reason and restarts the local continuity segment for:

- transition interpretation

## 0135 - Committed Phrase Memory And Choice Bias

`0135` adds committed phrase memory as explicit library state without collapsing UI state into the core API.

The public rule is strict:

- committed phrase memory is library-owned musical state
- caller-owned committed memory is passed in explicitly
- accepted choices bias later ranking
- preview-only host interactions stay out of library memory

That keeps the semantics aligned with the rest of `libmusictheory`:

- no hidden global blackboard
- no browser/device state in the C layer
- no confusion between preview focus and accepted musical history

### What Counts As Committed Memory

The new committed memory structs hold accepted realized phrase events only:

- `KeyboardCommittedPhraseMemory`
- `FretCommittedPhraseMemory`

They support explicit:

- reset
- push
- length inspection
- phrase auditing over the committed window
- keyboard next-step and context reranking from the committed window

This makes the downstream explanation honest:

- "accepted choices bias later ranking because the committed phrase already established a higher register anchor"
- "preview-only host interactions stay out of library memory, so hovering or pinning does not mutate the committed phrase"

### Why This Boundary Matters

Hosts still need their own UI state for:

- hover
- preview pin
- device connection state
- virtual keyboard toggles
- local persistence

But that state is not theory state. The library should only store committed choices that change later musical or playability results.
- warning cluster detection
- recovery-deficit accounting

This keeps the phrase report explainable:

- "The right hand accumulated strain through event 1, then the left hand starts a new continuity segment at event 2."

### Why Warning Clusters And Recovery-Deficit Runs Matter

A phrase can fail gracefully or fail cumulatively.

## 0136 - Repair Policy And Ranked Phrase Repairs

`0136` adds an explicit repair policy layer and ranked phrase repairs on top of the fixed-realization phrase audit engines.

The boundary is deliberate:

- the library may suggest repairs
- the library must say whether a candidate stayed inside `realization_only`
- the library must say when a candidate crossed into `register_adjusted`
- the library must say when a candidate crossed into `texture_reduced`

That keeps the explanation honest:

- "This repair stayed realization_only, so the music did not change."
- "This repair crossed musical-change boundary because it octave-displaced one note."
- "This repair crossed musical-change boundary because it removed one note from the texture."

### Repair Policy

The repair policy is explicit caller input, not a hidden preference table.

It controls:

- the maximum allowed repair class
- whether the bass must remain fixed
- whether the top voice must remain fixed
- whether inner-note changes are preferred
- whether keyboard hand reassignment is allowed

This lets hosts say exactly why a repair appeared:

- "We allowed realization_only repairs first, so the library only looked for hand or fret-location changes."
- "We widened the repair policy to register_adjusted because realization_only could not reduce the phrase bottleneck."

### Ranked Phrase Repairs

The ranked phrase repairs return:

- the target event index
- before and after phrase summaries
- a replacement event
- whether the candidate crossed musical-change boundary
- `what changed`
- `what was preserved`

`what changed` is represented explicitly so hosts can explain:

- hand reassigned
- fret location changed
- octave displaced
- note removed

`what was preserved` is represented explicitly so hosts can explain:

- bass preserved
- top voice preserved
- pitch classes preserved
- note count preserved
- exact pitches preserved
- exact frets preserved

The ranking order stays explainable:

- repairs that do not cross musical-change boundary come first
- lower after-strain buckets outrank higher ones
- lower after bottleneck severity outranks higher severity
- bigger blocked-issue reduction outranks smaller reduction

That lets an LLM or practice app say:

- "This is the first repair because it fixes the bottleneck without changing the written pitches."
- "This register_adjusted repair ranks below the realization_only repair because it crossed musical-change boundary even though both improved the phrase."

`0134` keeps both cases visible:

- a repeated warning cluster says the same warning family keeps recurring across a continuity segment
- a recovery-deficit run says strain persists across consecutive events without enough relief to reset the phrase burden

These are rule-based summaries, not hidden scores. They give downstream tools a phrase-level explanation without inventing a black-box difficulty number.
