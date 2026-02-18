# 0031 — Compatibility Visual Diff Diagnostics (Secondary Signal)

> Dependencies: 0024 (compat foundation), 0028 (integrity guardrails)
> Blocks: None
> Does not block: 0026, 0027

## Objective

Add a Playwright-based visual diff workflow to accelerate debugging when byte-exact SVG parity fails.

This is diagnostic only:
- exact byte match remains the pass/fail criterion for harmonious compatibility,
- visual metrics are supportive evidence for triage and prioritization.

## Non-Goals

- Do not replace strict byte comparison with SSIM/PSNR thresholds.
- Do not allow visual-pass + byte-fail results to be counted as compatible.
- Do not alter anti-cheating checks from `0028`.

## Research Phase

### 1. Stable Capture Strategy

- Define deterministic screenshot setup:
  - viewport, DPR, font loading, animation disabling,
  - consistent rendering host/browser settings.
- Confirm generated/reference previews remain visible when mismatches exist.

### 2. Diff Metrics and Artifacts

- Select metrics and artifact formats:
  - per-image absolute diff heatmap,
  - aggregate mismatch score per kind,
  - optional SSIM/PSNR for trend tracking.
- Store artifacts under deterministic local path (e.g., `tmp/compat-visual-diff/`).

### 3. Integration Policy

- Keep visual diff out of hard compatibility pass criteria.
- Provide opt-in verify integration (informational summary + artifact links).

## Implementation Steps

### 1. Add Visual Diff Runner

- Add a new script (e.g., `scripts/validate_harmonious_visual_diff.mjs`) that:
  - drives `validation.html`,
  - captures generated/reference previews,
  - computes pixel diffs and writes artifacts.

### 2. Add Sampling Controls

- Support modes:
  - sampled (`>=5` per kind),
  - full run for targeted kinds/files.
- Include deterministic sample selection and run metadata.

### 3. Add Reporting

- Emit machine-readable summary (JSON) + human-readable report:
  - worst mismatches per kind,
  - first mismatch coordinates/paths,
  - trend-ready metric outputs.

### 4. Optional Verify Hook

- Add non-blocking `./verify.sh` hook that runs only when refs exist and dependencies are available.
- Strict byte-match checks remain blocking; visual diff is supplementary.

## Exit Criteria

- `./verify.sh` passes.
- `zig build verify` passes.
- Visual diff artifacts are generated deterministically for sampled and full modes.
- Strict compatibility pass/fail behavior is unchanged.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs` (authoritative)
- `node scripts/validate_harmonious_visual_diff.mjs --sample-per-kind 5` (diagnostic)

## Implementation History (Point-in-Time)

_To be filled when implementation is complete._
