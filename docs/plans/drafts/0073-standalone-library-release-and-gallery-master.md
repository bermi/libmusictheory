# 0073 — Standalone Library Release And Gallery Master

> Dependencies: 0020, 0050, 0060, 0072
> Follow-up: 0074-0078

Status: Draft

## Objective

Turn `libmusictheory` from a correctness-driven Harmonious verification project into a clean standalone library release surface without discarding the verification infrastructure that proved the renderers and algorithms.

The release branch must present:

- a public API that is about music theory and rendering, not Harmonious compatibility internals
- a build/install surface that works without local Harmonious capture data
- a root documentation entry point for library users
- a local-only gallery of creative examples that use the public API directly
- retained internal compatibility/proof machinery for regression verification

## Why This Phase Exists

The current branch is strong on correctness:

- exact SVG parity is closed
- scaled render parity is closed
- native RGBA proof is closed
- the Harmonious SPA works locally

But the public release surface is still too coupled to the machinery we used to prove correctness:

- the installed header mixes standalone APIs with Harmonious compatibility and proof APIs
- the build graph exposes verification and reproduction bundles as first-class public targets
- there is no root library-facing `README.md`
- there is no standalone gallery bundle showing creative usage outside the Harmonious frame

This phase fixes that packaging and product-shaping problem.

## Principles

### 1. Verification stays, but it becomes internal infrastructure

Harmonious exact parity, scaled render parity, native RGBA proof, and the local SPA remain in-repo and continue to guard correctness. They are not the primary public identity of the standalone library.

### 2. The default public surface must stand on its own

A developer should be able to install and use `libmusictheory` without:

- local `tmp/harmoniousapp.net/`
- knowledge of compatibility kinds
- knowledge of proof/parity harnesses

### 3. Gallery examples must use only public APIs

The gallery is not allowed to reach into internal compat/proof APIs. It must demonstrate the standalone release surface honestly.

### 4. No production rollout work in this phase

This phase assumes local serving for docs and gallery examples. Deployment-hosting work is explicitly out of scope.

### 5. Verification standards do not relax

The branch remains mergeable only if:

- `./verify.sh` stays green
- exact SVG parity stays green
- native RGBA proof stays green

## Recovered Planning Notes

This draft restores the richer coordination detail from the original release-phase planning. The plan remains a draft because the phase is not fully closed while `0078` is still only planned.

### Public Release Story

The standalone branch should communicate a clean library story:

- `libmusictheory` is a reusable theory and rendering library
- Harmonious parity/proof work is the internal correctness harness
- the public user journey should start from:
  - `/Users/bermi/code/libmusictheory/README.md`
  - `zig build wasm-docs`
  - `zig build wasm-gallery`
- the public install story should center on:
  - `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
  - native static/shared install artifacts
  - public browser/WASM bundles

### Internal Infrastructure Story

The following remain in-repo and must stay green, but should not define the release identity:

- exact SVG parity
- scaled render parity
- native RGBA proof
- Harmonious SPA shell
- local corpus-dependent regression bundles and docs

### Target Public Surfaces

At release-close, the public-facing surfaces should be:

- standalone C ABI:
  - `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
- standalone docs bundle:
  - `zig build wasm-docs`
- standalone gallery bundle:
  - `zig build wasm-gallery`
- native install outputs:
  - `zig build`
  - `zig build c-smoke`

The following should remain clearly internal:

- `/Users/bermi/code/libmusictheory/include/libmusictheory_compat.h`
- `zig build wasm-demo`
- `zig build wasm-scaled-render-parity`
- `zig build wasm-native-rgba-proof`
- `zig build wasm-harmonious-spa`

### Release-Quality Constraints

The standalone release phase is only honest if all of the following are true:

- public headers do not force consumers to learn Harmonious compatibility concepts
- public docs do not rely on local `tmp/harmoniousapp.net` data
- gallery scenes use only public APIs
- internal regression tracks remain available and green
- release-oriented smoke verification is separate from the full local regression harness

### Phase Gates

#### Gate 1 — Surface Separation

Satisfied by `0074`:

- public vs compat header split
- standalone vs internal build-target labeling
- public install story independent of local Harmonious data

#### Gate 2 — Story Separation

Satisfied by `0075` and `0076`:

- root docs tell a library story first
- Harmonious tooling is documented as internal infrastructure
- stable/experimental/internal API boundaries are explicit

#### Gate 3 — Public Demonstration

Satisfied by `0077`:

- a creative gallery exists
- gallery uses only public APIs
- gallery is separately smoke-tested

#### Gate 4 — Release Closure

Still owned by `0078`:

- release artifact set
- versioning/changelog scaffold
- release checklist
- explicit standalone release smoke matrix

### Execution Order

The intended execution order for this phase is:

1. `0074` public API and build surface split
2. `0076` root README and stable API contract
3. `0077` standalone gallery and example bundle
4. `0075` Harmonious verification quarantine
5. `0078` release packaging and smoke matrix

That order keeps the library surface clean before polishing the outward-facing gallery and release workflow.

### Current Point-in-Time Status

As of this restored draft state:

- `0074` is completed
- `0075` is completed
- `0076` is completed
- `0077` is completed
- `0078` is restored as a draft after the reverted implementation pass

So the master plan is functionally in its final closure stage, but not yet complete.

## Workstreams

### 1. Public API And Build Surface Split

Plan: `0074`

Make the installed/public surface clearly separate from Harmonious-specific verification APIs and demo targets.

### 2. Harmonious Verification Quarantine

Plan: `0075`

Keep the parity/proof/SPA tracks available, but explicitly position them as internal verification tooling and optional local regression infrastructure.

### 3. Standalone README And Stable API Contract

Plan: `0076`

Add a root entry point that explains what the library is, which APIs are stable, what buffer/lifetime rules apply, and how developers are expected to consume it.

### 4. Standalone Gallery Bundle

Plan: `0077`

Ship a local-only browser gallery of creative examples that use the public API directly and show how the library can inspire novel musical discovery experiences.

### 5. Release Packaging And Smoke Matrix

Plan: `0078`

Close the release branch with packaging, versioning, smoke tests, and a release checklist that validates the standalone surface separately from the Harmonious verification harness.

## Completion Criteria For The Master Phase

`0073` should only be considered complete when:

- `0074`, `0075`, `0076`, `0077`, and `0078` are all completed
- the root standalone story is coherent without referencing Harmonious first
- `./verify.sh` reports a passing standalone release smoke path
- the full Harmonious regression infrastructure still passes when local data is available

## Target End State

At the end of this phase, the repo should have:

- a root `README.md` for standalone users
- a public header and build surface that do not force Harmonious concepts on library consumers
- a documented split between stable public APIs and internal verification APIs
- a `wasm-gallery` local demo bundle built on public APIs only
- a release smoke matrix that passes without depending on the Harmonious SPA or verification pages for the primary user story
- unchanged internal parity/proof infrastructure for regression verification

## Non-Goals

- No removal of the Harmonious verification harness
- No deletion of exact parity or native proof APIs
- No production deployment pipeline
- No redesign of core algorithms solely for release cosmetics

## Exit Criteria

- `0074`, `0075`, `0076`, `0077`, and `0078` are completed
- the public release surface is documented and buildable without local Harmonious data
- gallery examples are local, verified, and use only public APIs
- the internal verification tracks remain intact and green
- `./verify.sh` passes
