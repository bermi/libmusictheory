# Evenness Dart-Board Chart

> References: [Evenness, Voice Leading and Geometry](../evenness-voice-leading-and-geometry.md)
> Source: `tmp/harmoniousapp.net/even/index.svg` (main chart), `tmp/harmoniousapp.net/even/grad.svg` (gradient), `tmp/harmoniousapp.net/even/line.svg` (divider)
> Source: `tmp/harmoniousapp.net/p/4f/Evenness-Clusters.html`, `tmp/harmoniousapp.net/p/73/By-Evenness.html`

## Overview

The evenness dart-board chart is a polar visualization showing all 336 set classes arranged by cardinality (concentric rings) and evenness distance (radial position). Cluster-free sets are distinguished from cluster-containing sets by color.

## SVG Specifications

- **Canvas**: Large viewBox (exact size varies)
- **Layout**: Concentric rings, one per cardinality (3-9)
- **Radial axis**: Evenness distance (center = perfectly even, edge = maximally uneven)
- **Dots**: One per set class, sized by some metric
- **Colors**:
  - Cluster-free sets: one color (teal/green)
  - Cluster-containing sets: another color (gray/muted)
- **Labels**: Forte numbers or prime form notation near dots

## Generation Algorithm

### Step 1: Compute Positions for All 336 Set Classes

```
for sc in all_set_classes:
    card = cardinality(sc)
    ev = evenness_distance(sc)
    cluster_free = not has_cluster(sc)

    // Concentric ring based on cardinality
    ring_radius = ring_base + (card - 3) * ring_spacing

    // Radial position within ring based on evenness
    // More even → closer to center
    radial_offset = ev * scale_factor

    // Angular position: distribute set classes of same cardinality evenly
    angle = index_within_cardinality * (2 * PI / count_in_cardinality)

    position = {
        x: center_x + (ring_radius + radial_offset) * cos(angle),
        y: center_y + (ring_radius + radial_offset) * sin(angle),
        color: cluster_free ? TEAL : GRAY,
        label: forte_number(sc),
    }
```

### Step 2: Draw Concentric Ring Guides

```xml
<!-- Ring for each cardinality -->
<circle cx="{center}" cy="{center}" r="{ring_radius}"
        fill="none" stroke="#eee" stroke-width="0.5"/>
<text x="{label_x}" y="{label_y}" font-size="10">Card {c}</text>
```

### Step 3: Draw Set Class Dots

```xml
<circle cx="{x}" cy="{y}" r="3"
        fill="{color}" stroke="none"
        data-forte="{forte_number}"/>
<!-- Optional: tooltip with set class info -->
```

### Step 4: Draw Evenness Axis Labels

```xml
<!-- Center label: "Most Even" -->
<text x="{center}" y="{center}" text-anchor="middle">Perfectly Even</text>
<!-- Edge label: "Least Even" -->
<text x="{edge}" y="{center}" text-anchor="end">Maximally Uneven</text>
```

## Key Visual Patterns

The chart reveals:
1. Cluster-free sets cluster near the center (more even)
2. Cluster-containing sets spread toward the edges
3. Perfectly even sets (tritone, aug, dim7, whole-tone) sit at exact center of their ring
4. Most common musical scales/chords are near-center
5. "Harmonic dead-ends" are at the edges

## Supporting SVGs

- `tmp/harmoniousapp.net/even/grad.svg`: Gradient bar showing the evenness scale
- `tmp/harmoniousapp.net/even/line.svg`: Divider line between sections

## Algorithm Dependencies
- [Evenness and Consonance](../algorithms/evenness-and-consonance.md): evenness distance computation
- [Chromatic Cluster Detection](../algorithms/chromatic-cluster-detection.md): cluster-free classification
- [Prime Form and Set Class](../algorithms/prime-form-and-set-class.md): enumeration and Forte numbers

## Interactivity (Future)
- Hover over dot to see set class details (prime form, interval vector, name if known)
- Click to navigate to set class page
- Filter by cardinality, cluster-free status, etc.
- Animated transitions when filtering

## Compatibility Reverse-Engineering Notes (2026-02-21)

These notes describe the exact structure of the harmonious compatibility targets:
`tmp/harmoniousapp.net/even/index.svg`, `tmp/harmoniousapp.net/even/grad.svg`,
`tmp/harmoniousapp.net/even/line.svg`.

### Confirmed Structural Facts

- `grad.svg` and `line.svg` share the same core chart body.
  - longest common prefix: `116,436` bytes,
  - longest common suffix: `8` bytes.
- Core chart primitives in `grad.svg`:
  - `588` circles total.
  - `7` radial guide lines.
  - `194` visible black point circles (`style="stroke: black; stroke-width: 3"`).
  - `194` marker symbols in sequence:
    - cluster-free markers are red triangles (`path d="M0,80 L100,80 L50,-6z"`),
    - cluster-containing markers are gray circles.
- Marker style split:
  - triangles: `78` total (`49` pair style + `29` single style),
  - circles: `116` total (`79` pair style + `37` single style).

### Domain/Count Inference

- Visible point counts per cardinality ray are:
  - `[12, 29, 38, 36, 38, 29, 12]` for cardinalities `3..9`.
- The origin point appears once per ray; assigning origin points by next non-origin point
  (instead of naive `atan2(0,0)`) is required to avoid a false count skew.
- This matches unique Forte classes for all cardinalities except `6`:
  - unique Forte card-6 count is `50`,
  - compatibility chart uses `36`.
- Marker kind counts by cardinality exactly match cluster-free vs cluster-containing
  class counts for these selected domains.

### Card-6 Selection Gap

- A complement-collapse model for cardinality-6 yields `35` classes (`16` cluster-free, `19` clustered).
- Compatibility requires `36` classes (`16` cluster-free, `20` clustered), so one additional clustered card-6 class is retained beyond pure collapse.
- This exact card-6 inclusion rule is still unresolved and must be derived before final
  fully algorithmic parity conversion.

### Open Implementation Constraint

- Do not re-introduce embedded reference payloads for `even/*`.
- Target implementation should derive:
  - class domain selection (including exact card-6 rule),
  - ray ordering,
  - marker sequencing and placement,
  - variant-specific decoration blocks (`index` / `grad` / `line`),
  while preserving byte-exact output parity.

### Audit Automation

- Programmatic guardrail: `scripts/audit_even_compat.py`
  validates the invariants above against local references and is wired into `./verify.sh`
  when `tmp/harmoniousapp.net/even/` exists.
