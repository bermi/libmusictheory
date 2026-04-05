# Stable Tag Handoff

This is the exact handoff sequence for the stable `0.1.0` cut.

## Preconditions

- `./verify.sh` passes
- `./scripts/release_smoke.sh` passes
- `/Users/bermi/code/libmusictheory/docs/release/stable-review-decision.md` records `Status: Go for stable 0.1.0`
- the working tree is clean

## Exact Sequence

```bash
cd /Users/bermi/code/libmusictheory

git checkout main
git pull --ff-only origin main
git merge --ff-only codex/stable-cut-execution-plan
git push origin main

git tag 0.1.0
git push origin 0.1.0
```

## Interpretation

Stable signoff for `0.1.0` means:

- the stable contract is the public surface in `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, except APIs explicitly marked experimental
- `wasm-docs` is the stable browser contract demonstration
- `wasm-gallery` remains a supported example surface and may exercise experimental helpers
- direct bitmap parity helpers and the gallery preview toggle remain experimental review tools, not a stable exact-parity promise
- Harmonious parity/proof/SPA bundles remain internal regression infrastructure
