# 0110 — Counterpoint Repair Futures

> Dependencies: 0109, 0100, 0102
> Follow-up: none

Status: Draft

## Summary

Extend the live MIDI counterpoint scene with a `Repair Futures` panel that shows what each top `Repair Lab` fix opens up next. For each repair, surface the strongest immediate continuation, the reachable cadence tendency, and whether the repair meaningfully improves the future path rather than only the local duty score.

## Why

`Repair Lab` answers:

- what is the smallest per-voice change that would improve this focused move?

It still leaves a practical composing gap:

- if I accept this repair, does it merely patch the present moment, or does it lead somewhere better?

This slice keeps the repair workflow grounded in musical direction instead of local correctness alone.

## Scope

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must assert the presence of the `Repair Futures` host, runtime wiring, summary extraction, and Playwright coverage.
- gallery validation must verify that:
  - a populated live MIDI state renders futures for multiple repair rows
  - each future stays keyed to the currently focused repair/focused move signature
  - futures stay synchronized with hover, pin, clear-pin, context, profile, mini-mode, and snapshot changes
  - at least one future reports a concrete continuation and cadence trend improvement in the seeded MIDI test state

### Future Generation

Do not introduce a separate search engine.

For each chosen repair:

- reuse the repaired suggestion already produced by `Repair Lab`
- build the short continuation field through the existing continuation/next-step machinery
- summarize:
  - best immediate continuation label
  - strongest reachable cadence tendency
  - future warning pressure vs the unrepaired focused move
  - whether the repair increases continuation headroom

### Gallery View

Add a dedicated `Repair Futures` card that shows, per repair row:

- repaired source label
- strongest immediate continuation
- cadence trend chip
- short explanation of why the future is better, equal, or worse
- optional mini instrument preview for the best future when mini mode is on

## Exit Criteria

- live MIDI scene includes a populated `Repair Futures` view driven from `Repair Lab` entries and existing continuation ranking
- futures remain synchronized with the currently focused move and gallery interaction state
- gallery validation proves multiple repairs produce concrete future summaries
- `./verify.sh` passes
