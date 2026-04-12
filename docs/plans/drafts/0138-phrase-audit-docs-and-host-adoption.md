# 0138 — Phrase Audit Docs And Host Adoption

## Status

- Draft: 2026-04-12

## Goal

Make the phrase-audit surface usable by host applications and LLM workflows with clear examples that show:
- fixed-realization auditing
- committed-memory bias
- bottleneck reporting
- conservative repair requests
- explicitly music-changing repair requests

## Scope

1. Add unified API documentation for phrase auditing, committed phrase memory, and repair policies.
2. Add host-facing examples that distinguish:
   - audit only
   - preview versus commit
   - realization-only repair
   - music-changing repair
3. Add gallery/docs references only if they help adoption without inventing new semantics.

## Files

- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/README.md`
- `/Users/bermi/code/libmusictheory/examples/wasm-demo/index.html`
- `/Users/bermi/code/libmusictheory/examples/wasm-demo/app.js`
- `/Users/bermi/code/libmusictheory/scripts/validate_wasm_docs_playwright.mjs`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM should be able to show a user:
- "Here is the first blocked transition."
- "Here is an alternate realization that keeps the same sounding notes."
- "Here is a committed phrase memory example, and here is how it changes the next-step ranking."
- "Here is a second repair that changes the voicing, and here is exactly how it changed."

## Verification

- docs run-all/examples coverage
- phrase-audit examples visible in unified docs
- committed-memory examples visible in unified docs
- `/Users/bermi/code/libmusictheory/./verify.sh`
