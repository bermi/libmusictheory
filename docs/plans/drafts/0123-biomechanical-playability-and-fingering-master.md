# 0123 - Biomechanical Playability And Fingering Master

Status: Draft

## Summary

Build a new experimental playability lane for `libmusictheory` that can evaluate whether an instrument realization is reachable, strained, fluent, or effectively unplayable, and can expose that assessment in explainable terms to LLMs, practice tools, and the gallery.

This lane is not a separate "fingering app" bolted onto the repo. It should extend the library's existing strengths:
- deterministic theory primitives
- explicit stateful counterpoint reasoning
- guitar and keyboard instrument models
- gallery surfaces that already show current state and next steps

The goal is not "predict the one true fingering." The goal is to make `libmusictheory` capable of saying:
- why a realization is easy, awkward, or impossible
- what physical constraint is being violated
- how a next step changes physical difficulty from the current state
- which suggestions should be filtered or deprioritized when an instrument context is active

## Why

The post-Contrapunk gap is no longer theory vocabulary. It is execution viability.

For LLM composition and verification, harmonic correctness is necessary but insufficient. A generated passage can be theoretically coherent and still fail at the instrument layer because:
- a piano hand cannot span the chord at the written time and register
- a fretted realization requires a bottleneck stretch or jump that breaks the phrase
- a next-step suggestion is harmonically attractive but physically implausible from the current hand state

If `libmusictheory` can expose explainable playability facts, tools built on top of it can:
- reject impossible continuations before presenting them
- annotate generated music with specific physical warnings
- rewrite or respell passages toward playable alternatives
- teach students why a fingering or voicing is awkward and what changed

## Core Product Principle

The library should model playability, not pretend to be a medical device.

Adopt:
- geometry
- reachability
- span and jump limits
- finger assignment constraints
- temporal memory of recent motion and load
- explainable bottleneck and fatigue proxies

Reject:
- opaque learned difficulty scores in core APIs
- injury prediction claims
- uncalibrated "energy" numbers presented as truth
- hidden stylistic defaults that callers cannot justify

## Research Interpretation Matrix

### Primary sources we should build from

| Source | What it contributes | What we should adopt | What we should not port blindly |
| --- | --- | --- | --- |
| Allen and Goudeseune, *Topological Considerations for Tuning and Fingering Stringed Instruments* (2011) | Formal tuning-aware mapping from pitch space to string/fret space; arbitrary string counts and tunings | A topology layer for stringed instruments with tuning vectors, redundant pitch locations, and tuning-aware reachability | The paper's topological language should not become the public API vocabulary by itself; callers need practical structs, not manifold jargon |
| Hart, Bosch, and Tsai, *Automatic Decision of Piano Fingering Based on Hidden Markov Models* (IJCAI 2007) | Sequential hand-state modeling and Viterbi decoding for piano fingering | The idea that fingering is stateful and transition-sensitive; local hand state matters more than isolated notes | A raw HMM should not be the stable public surface; it is an implementation strategy, not an explainable API contract |
| Herremans and others, *Generating Fingerings for Polyphonic Piano Music with a Tabu Search Algorithm* / VNS follow-up | Parameterized distance matrices, relaxed/comfortable/practical ranges, explicit penalty taxonomy, hand-size personalization | Structured span models and explicit penalty families; user-parameterized hand-size scaling | Their numeric weights are not universal truths and should not be imported as hidden constants |
| Hori and Sagayama, *Minimax Viterbi Algorithm for HMM-Based Guitar Fingering Decision* (ISMIR 2016) | Minimax objective that reduces the hardest local move instead of only optimizing total difficulty | A bottleneck-first playability metric for beginner-facing and guardrail use | We should not force minimax as the only global objective; callers may need both bottleneck and cumulative views |
| Nakamura, Ono, and Sagayama, *Merged-Output HMM for Piano Fingering of Both Hands* (ISMIR 2014) | Two-hand state, voice-part separation, vertical interval constraints for piano | The idea that hand assignment and fingering interact in polyphony and that vertical span is a hard physical constraint | Full merged-output HMM complexity should remain internal or deferred until the simpler one-hand and voiced-state path is solid |
| Srivatsan and Berg-Kirkpatrick, *Checklist Models for Improved Output Fluency in Piano Fingering Prediction* (ISMIR 2022) | Temporal memory beyond pointwise accuracy; fluency metrics for sequences that are locally plausible but globally awkward | Recent-history-aware fluency metrics and adjacency warnings | Reinforcement-learning training logic does not belong in the core library |
| Ramoneda and others, *Difficulty-Aware Score Generation for Piano Sight-Reading* (2025) | Difficulty conditioning is useful for generation and pedagogy | Downstream use case: libmusictheory should expose difficulty/playability facts that generative tools can condition on | The generative model itself is not a core library responsibility |

### Biomechanics and fatigue sources

| Source | What it contributes | How to use it responsibly |
| --- | --- | --- |
| Reviews and fatigue studies on piano biomechanics and hand control degradation | Extreme wrist deviation, force degradation, and fatigue matter in sustained playing | Use them to justify stateful strain proxies and warnings; do not expose medical certainty or raw physiological predictions |
| Instrument energy-expenditure studies | Posture and energy are real but coarse-grained | Do not build note-level MET scoring into the API; the evidence is too coarse for score-event decisions |

### Sources to treat as secondary or profile-level only

| Topic | Decision | Why |
| --- | --- | --- |
| Simandl vs one-finger-per-fret bass technique | Experimental profile only | Real pedagogy value, but the evidence in the provided list is mostly pedagogical or anecdotal rather than a settled core invariant |
| Slap/pop right-hand mechanics | Experimental profile only | Useful for future bass-specific overlays and warnings, but not strong enough for first-wave core semantics |
| 7-string thumb placement advice | Experimental profile only | Good practical guidance, but too instrument- and player-specific to hard-code as a universal correctness rule |

## Critical Product Review

### What fits `libmusictheory`

1. Explainable physical facts
- reachable or unreachable
- comfortable or at limit
- repeated weak-finger use
- excessive span
- jump distance
- thumb-on-black-key or black-key crossing exposure
- awkward string change or neck shift
- bottleneck move severity

2. Stateful assessment
- current hand state
- recent load and recovery
- recent jumps or stretches
- current position window on fretboard or keybed

3. Optional instrument-aware filtering of next steps
- do not change theory results by default
- only filter or rerank when an explicit instrument context is present

4. Optional overlays in docs/gallery
- finger labels
- span box
- pivot and shift arrows
- strain heat
- hand silhouette or wireframe only after the state model exists

### What does not fit as a core promise

1. One globally correct fingering per phrase
2. Hidden weighted sums that callers cannot explain
3. ML-only difficulty outputs without decomposed reasons
4. Medical or injury-prevention claims
5. Quietly changing harmonic rankings just because an instrument happens to be active

## Proposed Architecture

### 1. New experimental playability family

Add a new experimental module family under `/Users/bermi/code/libmusictheory/src/playability/`.

Recommended internal split:
- `types.zig`
- `fret_topology.zig`
- `keyboard_topology.zig`
- `fret_assessment.zig`
- `keyboard_assessment.zig`
- `ranking.zig`
- `overlay.zig`

This keeps the new work close to existing `guitar`, `keyboard`, and `counterpoint` modules without overloading any one file.

### 2. Separate facts from policy

The API should be layered.

Layer A: realization facts
- all reachable locations for a note or set
- span required
- hand position window
- crossings, jumps, repetitions, weak-finger sequences

Layer B: assessment
- hard blockers
- warnings
- bottleneck severity
- cumulative strain estimate
- explanation-friendly reason codes

Layer C: ranking and filtering
- given multiple realizations or next-step candidates, rank or filter them using explicit caller-selected policy

This preserves DX and explainability. A host can inspect raw facts, not just trust a single score.

### 3. Keep theory and playability composable, not fused

`libmusictheory` already has theory-first ranking surfaces. We should not silently rewrite them.

Instead:
- keep current harmonic and counterpoint APIs valid
- add optional playability evaluation for realized candidates
- add opt-in combined helpers later

This matters because some hosts want pure theory analysis with no instrument chosen, while others want instrument-constrained generation.

### 4. Use "playability" as the public concept, not "biomechanics"

Internally and in docs we can discuss biomechanics. In the C ABI and gallery, `playability` is the better umbrella:
- less medical overclaim
- closer to what callers actually need
- easier to combine across instruments

## Proposed Experimental API Direction

Exact names can be finalized per slice, but the family should look like this:

- reflection and enums
  - `lmt_playability_reason_*`
  - `lmt_playability_warning_*`
  - `lmt_playability_profile_*`
  - `lmt_playability_policy_*`

- state and profile structs
  - `lmt_hand_profile`
  - `lmt_fret_play_state`
  - `lmt_keyboard_play_state`
  - `lmt_playability_assessment`

- instrument-specific assessment
  - `lmt_assess_fret_realization_*`
  - `lmt_assess_keyboard_realization_*`
  - `lmt_assess_fret_transition_*`
  - `lmt_assess_keyboard_transition_*`

- ranking/filtering
  - `lmt_rank_fret_realizations_*`
  - `lmt_rank_keyboard_fingerings_*`
  - `lmt_filter_next_steps_by_playability_*`

- overlay data, not pre-rendered art
  - `lmt_fret_overlay_points_*`
  - `lmt_keyboard_overlay_points_*`
  - `lmt_hand_outline_anchors_*`

The important DX rule is that rendering helpers should return geometry and labels, not force SVG decisions. That keeps gallery/docs flexible and makes the ABI usable from non-browser hosts.

## UX/DX Fit With Existing Surfaces

### Gallery

The gallery should expose playability as an optional layer on top of the current scenes.

Recommended controls:
- `Playability Overlay: Off | Basic | Detailed`
- `Instrument Profile: Piano | Guitar | Bass | Custom`
- `Difficulty Lens: Bottleneck | Fatigue | Balanced`

Recommended visuals:
- frets: finger numbers, hand-position box, shift arrows, stretch heat, optional abstract hand wireframe
- piano: left/right hand ranges, finger labels, crossing arrows, black-key risk markers, optional hand silhouettes
- next-step cards: `playable`, `strained`, `blocked` badges with reasons

Pushback on hand outlines:
- do not start with decorative hand art
- start with anchors, boxes, vectors, and labeled digits
- add hand silhouettes only once the underlying state geometry is stable and testable

### LLM / app embedding

The library should let an LLM say things like:
- "This voicing is theoretically fine, but in standard tuning it needs a five-fret span at fret 2, which exceeds the requested comfort window."
- "This next chord is reachable, but it creates the hardest jump in the phrase so far."
- "This piano realization fits the harmony, but the right hand must exceed the configured octave span."

That means every ranked result should come with decomposed reasons, not just a scalar.

## Dependency Graph

```text
0123 biomechanical-playability-and-fingering-master
  -> 0124 instrument-topology-and-biomechanical-state
       -> 0125 fretted-instrument-playability-and-technique-profiles
       -> 0126 keyboard-fingering-and-hand-span-models
            -> 0127 playability-reason-codes-and-next-step-filtering
                 -> 0128 gallery-overlays-and-hand-outline-visualizations
                 -> 0129 personalized-profiles-and-practice-feedback
```

## Execution Slices

### 0124 - Instrument Topology And Biomechanical State

Build the foundation layer:
- hand profiles
- current play state
- temporal load memory
- topology helpers for stringed instruments and keyboard

### 0125 - Fretted Instrument Playability And Technique Profiles

Implement explainable fretboard-specific assessment:
- redundant location search
- position windows
- spans, shifts, crossings
- bottleneck move severity
- optional technique profiles kept experimental

### 0126 - Keyboard Fingering And Hand-Span Models

Implement explainable piano-specific assessment:
- hand assignment helpers
- span limits
- crossing and thumb/black-key exposure
- simple chord and transition assessment

### 0127 - Playability Reason Codes And Next-Step Filtering

Connect playability to ranking:
- structured reasons and warnings
- opt-in filtering or reranking of existing next-step candidates
- bottleneck versus cumulative policy modes

### 0128 - Gallery Overlays And Hand Outline Visualizations

Expose optional overlays in the docs/gallery using computed geometry:
- finger labels
- spans
- shift vectors
- optional stylized hand outlines

### 0129 - Personalized Profiles And Practice Feedback

Add parameterized hand-size and comfort windows, plus practice-facing feedback that can suggest easier realizations without claiming universal correctness.

## Open Decisions

1. Should a single cross-instrument `lmt_playability_assessment` exist, or should fret and keyboard stay fully separate at the ABI layer?
- Recommendation: shared high-level assessment struct, instrument-specific input/state structs.

2. Should the first ranking helper combine harmonic and playability scoring?
- Recommendation: no. First expose playability evaluation separately and add combined helpers later as experimental convenience wrappers.

3. Should named technique profiles ship in the first wave?
- Recommendation: only if clearly marked experimental and documented as pedagogy presets, not universal truth.

4. Should hand outlines be first-class deliverables?
- Recommendation: no. They are slice-0128 visualization outputs that depend on the earlier geometry/state model.

## Success Criteria

1. The repo has an explicit experimental playability family with caller-owned structs and no hidden allocation.
2. A host can evaluate whether a realization or transition is blocked, strained, or comfortable and get named reasons.
3. Existing next-step suggestions can be optionally filtered or reranked by instrument playability without changing theory-first behavior by default.
4. The gallery can optionally show playability overlays on fretboards and keyboard views.
5. Every surfaced playability claim can be explained in concrete physical terms.
6. `./verify.sh` remains the gate for each implementation slice.

## Implementation History (Point-in-Time)

_To be filled when the roadmap is executed._
- `<commit-hash>` (<date>):
  - Shipped behavior: ...
  - Verification: `./verify.sh`, `./zigw build verify`.
