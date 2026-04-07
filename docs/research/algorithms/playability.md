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
