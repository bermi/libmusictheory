# 0090 — Counterpoint State And Gallery Master

> Dependencies: 0010, 0011, 0077, 0087
> Follow-up: 0091, 0092, 0093, 0094

Status: Draft

## Objective

Turn `libmusictheory` from a harmony-and-static-graph library into a time-aware counterpoint and voice-leading system that can explain the current musical state, rank plausible next moves, and surface those decisions inside the interactive gallery.

## Why This Phase Exists

The library already knows a great deal about pitch-class structure, harmony, evenness, keyboard/fret/staff rendering, and static voice-leading distance. What it does not yet model is the musical fact that counterpoint depends on continuity:

- voices persist through time
- recent history changes the meaning of the current sonority
- motion types matter as much as vertical content
- good next steps are profile-dependent, not universal

Without that layer, the gallery can show attractive harmonic snapshots, but it cannot yet behave like a serious counterpoint or voice-leading assistant.

## Research Framing

### Existing Strengths To Reuse

- pitch-class and harmonic analysis from the core library
- voice-leading distance and geometric/orbifold groundwork
- public SVG + bitmap surfaces for staff, keyboard, fret, clock, `OPTIC/K`, and evenness
- interactive gallery with live MIDI input and ranked next-step infrastructure

### Gaps This Phase Must Close

- persistent voice identity
- adjacent-state motion classification
- time-aware memory of the last 1-3 states
- explicit cadence and dissonance-resolution state
- multiple rule profiles instead of a single hidden policy
- reusable next-step ranking with human-readable reasons

### Anti-Slop Visualization Principles

These should constrain both the algorithms and the gallery:

- never collapse everything into one dense static infographic
- always expose the current state before showing the future
- every ranking must provide reasons, not just scores
- every abstract graph must have a local instrumental or notational reading
- keep multiple linked lenses visible: harmonic, contrapuntal, instrumental
- avoid diagrams that are only pretty summaries of a rulebook; prefer diagrams that guide an actual next decision
- use progressive disclosure: reveal the relevant local slice first, then allow expansion to the wider graph
- never ask the user to decode a full theory map before they can act on the current musical moment

### External Source Note

The requested Reddit thread at [old.reddit.com/r/musictheory/comments/1ot0mqt/what_are_your_thoughts_on_this_diagram/](https://old.reddit.com/r/musictheory/comments/1ot0mqt/what_are_your_thoughts_on_this_diagram/) could not be fetched over the network from this environment because Reddit blocked anonymous requests, but the user supplied a local PDF capture at `/Users/bermi/Downloads/What are your thoughts on this diagram_ _ musictheory.pdf`.

Useful takeaways from that thread:

- dense totalizing diagrams are widely perceived as “too much going on” when shown out of context
- the same visuals become more useful when introduced progressively and only the relevant slice is active
- some musicians genuinely benefit from visual pattern systems, but only when the graph helps them explore rather than pretending to replace explanation
- standalone diagrams need explicit contextual framing, otherwise viewers cannot tell whether they are pedagogy, analysis, or inspiration prompts

This phase should treat those points as product constraints, not as casual opinions.

## Workstreams

### 1. Time-Aware Counterpoint State

Plan: `0091`

Define `VoicedState` and temporal memory as reusable core objects:

- voices with stable identity
- current notes and registral assignment
- recent history window
- tonic/mode/key context
- metric position
- cadence state
- caller-owned ABI exposure without heap allocation in core algorithms

### 2. Motion Semantics And Style Profiles

Plan: `0092`

Add adjacent-state motion classification and configurable rule profiles:

- contrary, similar, parallel, oblique
- crossing and overlap
- leap/step size buckets
- common-tone retention
- profile-specific weighting/legality rules for:
  - species
  - tonal chorale
  - modal polyphony
  - jazz close-leading
  - free contemporary

### 3. Ranked Next Moves With Reasons

Plan: `0093`

Build a reusable next-step ranker over the time-aware state:

- minimal total motion
- avoidance of parallels and crossings
- tendency-tone resolution pressure
- spacing preservation
- tension increase/decrease
- cadence effect
- explicit reason codes and score breakdowns

### 4. Interactive Counterpoint Gallery Surface

Plan: `0094`

Expose the new system in the standalone gallery:

- a live counterpoint/voice-leading scene driven by MIDI or gallery presets
- current-state view + ranked next-step view
- optional linked mini instrument visualization on every scene
- global instrument selector:
  - `piano`
  - `fret`
- mini views must use the same pitch-class color coding as the graphs
- current and suggested next states must both render through the selected instrument mini-view

## Exit Criteria

- the library can represent a time-aware voiced musical state with history
- adjacent-state motion is explicitly classified and testable
- multiple counterpoint/voice-leading profiles are available rather than one hidden policy
- ranked next moves carry machine-readable and human-readable reasons
- the standalone gallery can surface the current state and plausible continuations with optional piano/fret mini views
- `./verify.sh` remains the source-of-truth gate for all shipped slices
