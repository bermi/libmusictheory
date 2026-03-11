# 0044 — MajMin Scales Scene-Pack Geometry Prune

> Dependencies: 0043
> Blocks: 0045

Status: Draft

## Objective

Remove scales-geometry replay payload from `harmonious_majmin_scene_pack_xz` generation and parser reachability after analytic scales geometry renderer is stable.

## Non-Goals

- Do not touch modes geometry payload in this milestone.
- Do not change legacy overview payload behavior.

## Pre-Implementation Verification Changes

- Add `verify.sh` budget + shape guardrails:
- reduced scene-pack payload size envelope,
- parser/model fields for removed scales geometry data are not required anymore.

## Implementation Slices

1. Update `scripts/generate_harmonious_majmin_scene_pack.py` to omit scales geometry replay payload.
2. Regenerate `src/generated/harmonious_majmin_scene_pack_xz.zig`.
3. Simplify `src/svg/majmin_compat.zig` scales D-slot logic to use analytic renderer for geometry slots only, with reduced pack fields.

## Exit Criteria

- Scales geometry replay payload removed from generated scene-pack.
- Scene-pack size decreases versus pre-0044 baseline.
- Strict parity unchanged and all verify gates pass.

## Verification Commands (Completion Gates)

- `./verify.sh`
- `zig build verify`
- `zig build test`
- `node scripts/validate_harmonious_playwright.mjs --sample-per-kind 5`
- `node scripts/validate_harmonious_playwright.mjs`

## Implementation History (Point-in-Time)

_To be filled when completed._
