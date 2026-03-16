# 0057 — Staff And Fret Native-RGBA Proof Lane

> Dependencies: 0055, 0056

Status: In Progress

## Objective

Close native-RGBA proof for the staff and fret compatibility families while preserving exact SVG parity and scaled-render-parity at both `55%` and `200%`.

## Target Families

- `scale`
- `eadgbe`
- `chord`
- `wide-chord`
- `chord-clipped`
- `grand-chord`

## Exit Criteria

- candidate source = `native-rgba`
- scaled-render-parity still green
- exact SVG parity still green
- anti-cheat rules still green

## Active Slice

- Tighten `./verify.sh` so `eadgbe` is required in the sampled native-RGBA proof lane.
- Add deterministic native candidate/reference bitmap support for `eadgbe` before moving on to staff families.
