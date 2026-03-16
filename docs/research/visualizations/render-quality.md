# Render Quality

`libmusictheory` now treats render quality as a first-class concern for non-compat generated SVGs.

## Contract Split

- Exact harmonious compatibility output is a reproduction contract and must stay visually frozen.
- Non-compat generated SVGs use a shared quality prelude:
  - canonical SVG open tag with geometric precision flags
  - shared font stacks
  - shared outline/stroke conventions for text
  - consistent non-scaling stroke behavior

## Why This Split Exists

The repo now has two different obligations:

1. reproduce harmoniousapp.net exactly
2. expose a good-looking general-purpose rendering library

Those obligations conflict if they share one visual contract. The fix is additive: preserve exact compat output, improve the library-native generators.

## Immediate Benefits

- better cross-platform text consistency
- clearer label contrast on colored nodes
- more stable stroke treatment when scaled in browsers and host UIs
- one place to evolve shared SVG presentation rules
