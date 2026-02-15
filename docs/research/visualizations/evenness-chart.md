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
