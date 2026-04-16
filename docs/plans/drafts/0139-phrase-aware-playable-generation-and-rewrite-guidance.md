# 0139 — Phrase-Aware Playable Generation And Rewrite Guidance

## Status

- Draft: 2026-04-16

## Goal

Extend the completed phrase-audit and committed-memory work into a generation-facing lane so `libmusictheory` can help hosts and LLMs:
- bias multi-step candidate exploration toward phrases that stay playable over time
- explain why one branch remains viable while another becomes blocked
- distinguish hard physical blockers from soft strain accumulation
- request controlled phrase rewrites with explicit caller policy instead of silent musical changes
- keep generation guidance deterministic, explainable, and compatible with caller-owned musical memory

## Why This Is The Right Post-0138 Lane

The library can already do all of the local and phrase-level prerequisites:
- local realization and transition assessment
- committed phrase memory that biases later ranking
- phrase-level auditing over fixed realized passages
- controlled repair policy and ranked phrase repair helpers
- host-facing docs and gallery semantics that separate preview from commit

What it still cannot do cleanly is help a host or LLM say:
- "these next three options all work locally, but only one stays playable through the next four committed choices"
- "this branch fails at step 3 because the earlier choice consumed the available recovery window"
- "this rewrite preserves the phrase contour while removing the bottleneck transition"
- "this suggestion is not forbidden, but it should be deprioritized because it compounds the same strain family already present in memory"

That is the missing bridge from phrase-aware analysis to phrase-aware generation.

## Product Principle

This lane must produce explainable generation guidance, not opaque search magic.

Adopt:
- explicit branch windows
- explicit caller-supplied candidate buffers
- branch summaries with blocker and strain reasons
- hard-filter versus soft-bias distinction
- controlled rewrite exploration with stated preservation policy

Reject:
- hidden beam-search policy that cannot be explained
- random exploration or probabilistic defaults in core APIs
- silent music-changing rewrites
- hidden global state shared across branches or callers

## Scope

1. Add a branch/window model for phrase-aware candidate evaluation.
2. Add fixed-horizon generation helpers that score or classify candidate continuations against committed phrase memory.
3. Distinguish:
   - hard blockers
   - soft strain accumulation
   - recovery-improving branches
   - recovery-deficit branches
4. Add rewrite-guidance helpers that evaluate phrase-preserving versus music-changing rewrite families under explicit caller policy.
5. Expose generation-facing summaries and examples for hosts and LLM workflows.

## Critical Boundary

### Library-owned

Belongs in the library when it affects later musical results:
- committed phrase memory
- branch evaluation state derived from committed memory
- ranked branch summaries
- rewrite policy and ranked rewrite results
- reason codes for blockers, strain, and recovery

### Host-owned

Stays outside the library when it is presentation or session control:
- hovered candidate
- pinned preview card
- local persistence
- transport or playback state
- Web MIDI device permissions
- gallery-only browsing and comparison affordances

## Design Constraints

1. Deterministic only.
2. Caller-owned buffers only; no hidden allocations.
3. Phrase-aware generation must build on the completed phrase-audit surfaces instead of re-encoding duplicate logic.
4. The API must distinguish hard filtering from soft reranking.
5. Rewrite helpers must preserve the explicit policy boundary established in `0136`.
6. All branch-level outputs must be explainable in terms of concrete issue families, committed history, and recovery windows.

## Explainability Contract

Every result from this lane should support sentences like:
- "This continuation is locally valid, but it becomes blocked on the third event because the right-hand span exceeds the practical range after the previous stretch."
- "This branch is still playable, but it keeps accumulating the same shift strain without recovery, so it should be ranked below the alternatives."
- "This rewrite keeps the same number of events and the same harmonic target, but it moves the bottleneck transition into a lower-strain register."
- "This option is favored because your committed phrase memory already established an anchor that reduces the next shift."

## Proposed Slice Breakdown

1. `0140` — phrase branch state and fixed-horizon candidate windows
2. `0141` — phrase-biased branch ranking and hard-filter helpers
3. `0142` — rewrite exploration and preservation-aware branch repairs
4. `0143` — docs, examples, and host/gallery adoption for phrase-aware generation

## Dependencies

```text
0133 phrase event model and summaries
0134 fixed-realization phrase audit engines
0135 committed phrase memory and choice bias
0136 repair policy and ranked phrase repairs
0138 phrase audit docs and host adoption
     ↓
0140 phrase branch state and fixed-horizon candidate windows
     ↓
0141 phrase-biased branch ranking and hard-filter helpers
     ↓
0142 rewrite exploration and preservation-aware branch repairs
     ↓
0143 docs, examples, and host/gallery adoption for phrase-aware generation
```

## Verification Strategy

Every slice in this lane should extend `./verify.sh` only as needed and should prove:
- branch-level outputs are reproducible
- hard blockers and soft-bias reasons remain distinguishable
- committed memory actually affects branch evaluation when the caller opts in
- rewrite helpers never cross policy boundaries silently
- docs and host examples reflect the final API semantics exactly
