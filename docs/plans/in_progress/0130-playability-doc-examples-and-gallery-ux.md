# 0130 — Playability API Examples And Gallery UX

## Status

- Draft: 2026-04-11
- In progress: 2026-04-11

## Goal

Make the new playability surface easier to adopt by:
- adding practical, copyable examples to the unified API reference and browser docs surface
- clarifying the gallery controls for playability presets, policies, overlays, and practice feedback
- verifying both the documentation and gallery UX so the new surface remains discoverable

## Scope

1. Expand `/Users/bermi/code/libmusictheory/docs/api.md` with concrete task-oriented examples for:
- preset application
- keyboard realization/transition summaries
- safer next-step selection
- playability-aware next-step reranking
- LLM/practice-app framing

2. Ensure the standalone docs bundle points users to the unified API reference with explicit playability examples.

3. Tighten the gallery UX in `/Users/bermi/code/libmusictheory/examples/wasm-gallery/` by:
- making the playability controls easier to discover and understand
- adding concise helper text around what the preset, policy, and overlay controls do
- making practice feedback status easier to parse at a glance

4. Update `/Users/bermi/code/libmusictheory/verify.sh` guardrails so these docs/UX additions are enforced.

## Files

- `/Users/bermi/code/libmusictheory/docs/api.md`
- `/Users/bermi/code/libmusictheory/README.md`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/index.html`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery.js`
- `/Users/bermi/code/libmusictheory/examples/wasm-gallery/styles.css`
- `/Users/bermi/code/libmusictheory/scripts/lib/wasm_gallery_playwright_common.mjs`
- `/Users/bermi/code/libmusictheory/scripts/validate_wasm_gallery_playwright.mjs`
- `/Users/bermi/code/libmusictheory/verify.sh`
- `/Users/bermi/code/libmusictheory/docs/plans/drafts/0001-coordinator.md`

## Verification

- `/Users/bermi/code/libmusictheory/./verify.sh`

## Completion Notes

Add an `Implementation History (Point-in-Time)` section before moving this plan to `completed`.
