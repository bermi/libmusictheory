# 0143 — Phrase-Aware Generation Docs And Host/Gallery Adoption

## Status

- Draft: 2026-04-16

## Goal

Make the new phrase-aware generation surface usable by hosts and visible in the gallery/docs without inventing new musical semantics.

## Scope

1. Document the new generation-facing API surface.
2. Add examples that distinguish:
   - branch window construction
   - hard-filter versus rerank
   - committed-memory bias
   - realization-preserving versus music-changing branch repairs
3. Update the gallery only where it helps demonstrate the branch semantics already defined in the library.
4. Preserve the host/library split:
   - host owns preview and persistence
   - library owns committed memory, branch evaluation, and rewrite reasoning

## Files

- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/README.md`
- `/Users/bermi/code/libmusictheory/examples/wasm-demo/index.html`
- `/Users/bermi/code/libmusictheory/examples/wasm-demo/app.js`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css`
- `/Users/bermi/code/libmusictheory/scripts/validate_wasm_docs_playwright.mjs`
- `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `/Users/bermi/code/libmusictheory/verify.sh`

## Explainability Check

An LLM or host should be able to show:
- "Here are the branches that were hard-filtered."
- "Here are the branches that stayed visible but were reranked down."
- "Here is the committed phrase memory fact that changed the outcome."
- "Here is a realization-only branch repair, and here is a register-adjusted one."

## Verification

- docs bundle covers branch-window examples
- gallery validation covers branch summary visibility if adopted there
- `/Users/bermi/code/libmusictheory/./zigw build wasm-docs`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_docs_playwright.mjs`
- `node /Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `/Users/bermi/code/libmusictheory/./verify.sh`
