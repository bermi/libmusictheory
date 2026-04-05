# 0111 — Public Stable Contract Audit And Enforcement

> Dependencies: 0087, 0076, 0077
> Follow-up: 0112, 0113

Status: Draft

## Summary

Inventory the standalone surface that will be defended as stable at `0.1.0`, separate it cleanly from experimental and internal helpers, and make that classification impossible to misstate in the header, README, reviewer guide, and gallery copy.

## Why

The repo now ships a much richer standalone surface than the original RC cut, but the language around what is stable versus experimental is still too easy to drift. Before the stable cut, we need one authoritative contract sweep rather than more piecemeal wording edits.

## Scope

### Contract Inventory

- enumerate the stable public C ABI that `0.1.0` promises
- enumerate experimental helpers that remain visible in docs/gallery but are not part of the stable contract
- enumerate internal-only verification and Harmonious regression surfaces that must stay outside the public promise

### Enforcement

- align `include/libmusictheory.h`, `README.md`, `docs/release/reviewer-guide.md`, and release docs around the same stable / experimental / internal language
- make gallery/docs wording stop implying that every exposed helper is stable if some are intentionally experimental
- ensure any new examples that rely on experimental helpers say so explicitly at the call site

### Verification-First Guardrails

Before implementation:

- `./verify.sh` must fail if stable / experimental wording disagrees across header, README, and reviewer docs
- `./verify.sh` must fail if gallery-facing docs claim a stable-only surface while experimental helpers are still required for some scenes

## Exit Criteria

- the stable contract is inventoried once and repeated consistently
- experimental helpers are still usable, but clearly marked as experimental everywhere they appear publicly
- internal verification surfaces remain documented as internal infrastructure only
- `./verify.sh` passes
