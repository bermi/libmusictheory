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
