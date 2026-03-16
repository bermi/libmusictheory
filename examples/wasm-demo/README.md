# WASM Browser Bundles

## Exact SVG Parity

```bash
zig build wasm-demo
python3 -m http.server --directory zig-out/wasm-demo 8000
```

Validation page: <http://localhost:8000/validation.html>.

If `tmp/harmoniousapp.net/` exists locally, the reference SVG tree is mirrored into:

```text
zig-out/wasm-demo/tmp/harmoniousapp.net/
```

That makes the default validation reference root `/tmp/harmoniousapp.net` work when serving `zig-out/wasm-demo` directly.

## Scaled Render Parity

```bash
zig build wasm-scaled-render-parity
python3 -m http.server --directory zig-out/wasm-scaled-render-parity 8002
```

Page: <http://localhost:8002/>.

This lane validates all 15 compatibility kinds at both `55%` and `200%` with target-size bitmap diffs. Each kind/scale row reports whether the candidate source was:

- `native-rgba`
- `generated-svg`

Native-RGBA rows also report their backend subtype so current direct primitive/path rendering is distinguishable from Zig-side markup or generated-SVG rasterization.

This lane is useful and required, but it is not sufficient to call the project visually complete.

## Native RGBA Proof

```bash
zig build wasm-native-rgba-proof
python3 -m http.server --directory zig-out/wasm-native-rgba-proof 8003
```

Page: <http://localhost:8003/>.

This lane only accepts `native-rgba` candidate pixels generated inside Zig/WASM. Each supported row also reports its backend subtype:

- `direct-primitives`
- `path-geometry`
- `markup-template-raster`
- `generated-svg-bitmap`

That keeps the repo honest about which kinds are already direct drawing and which still depend on internal markup/SVG rasterization. Unsupported kinds remain visible as unsupported rows and fail automated validation.

## Full Interactive API Docs

```bash
zig build wasm-docs
python3 -m http.server --directory zig-out/wasm-docs 8001
```

Open <http://localhost:8001/index.html>.

The docs bundle now exposes both:

- six-string compatibility wrappers such as `lmt_svg_fret`
- parametric fretboard APIs such as `lmt_fret_to_midi_n`, `lmt_midi_to_fret_positions_n`, and `lmt_svg_fret_n`

Core non-compat SVG generators in the docs bundle now share a common quality prelude. Exact harmonious compatibility generators remain frozen and are not visually restyled.

## Project Completion Criteria

The project is not visually complete until all 15 compatibility kinds pass Native RGBA Proof at `55%` and `200%`.
