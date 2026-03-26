# WASM Browser Bundles

This directory documents internal regression infrastructure and the standalone docs bundle.

For the standalone library entry point, start with:

- `/Users/bermi/code/libmusictheory/README.md`

For the dedicated internal regression overview, use:

- `/Users/bermi/code/libmusictheory/docs/internal/harmonious-regression.md`

This directory now contains two kinds of browser surfaces:

- standalone/public:
  - `wasm-docs`
- internal verification/regression:
  - `wasm-demo`
  - `wasm-scaled-render-parity`
  - `wasm-native-rgba-proof`
  - `wasm-harmonious-spa`

## Exact SVG Parity

```bash
./zigw build wasm-demo
python3 -m http.server --directory zig-out/wasm-demo 8000
```

Validation page: <http://localhost:8000/validation.html>.

This is an internal verification bundle, not the primary standalone release surface.

If `tmp/harmoniousapp.net/` exists locally, the reference SVG tree is mirrored into:

```text
zig-out/wasm-demo/tmp/harmoniousapp.net/
```

That makes the default validation reference root `/tmp/harmoniousapp.net` work when serving `zig-out/wasm-demo` directly.

## Scaled Render Parity

```bash
./zigw build wasm-scaled-render-parity
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
./zigw build wasm-native-rgba-proof
python3 -m http.server --directory zig-out/wasm-native-rgba-proof 8003
```

Page: <http://localhost:8003/>.

This lane only accepts `native-rgba` candidate pixels generated inside Zig/WASM. Each supported row also reports its backend subtype:

- `direct-primitives`
- `path-geometry`
- `markup-template-raster`
- `generated-svg-bitmap`

That keeps the repo honest about which kinds are already direct drawing and which still depend on internal markup/SVG rasterization. Unsupported kinds remain visible as unsupported rows and fail automated validation.

The displayed proof/parity bitmaps are not browser-smoothed placeholders. They are the actual Zig raster outputs, and the native raster backends now use coverage-based edge antialiasing so manual inspection is meaningful for circles, diagonals, and filled path edges.

## Full Interactive API Docs

```bash
./zigw build wasm-docs
python3 -m http.server --directory zig-out/wasm-docs 8001
```

Open <http://localhost:8001/index.html>.

This is the primary standalone/public browser bundle today.

The docs bundle now exposes both:

- six-string compatibility wrappers such as `lmt_svg_fret`
- parametric fretboard APIs such as `lmt_fret_to_midi_n`, `lmt_midi_to_fret_positions_n`, and `lmt_svg_fret_n`

Core non-compat SVG generators in the docs bundle now share a common quality prelude. Exact harmonious compatibility generators remain frozen and are not visually restyled.

## Harmonious SPA

```bash
./zigw build wasm-harmonious-spa
python3 -m http.server --directory zig-out/wasm-harmonious-spa 8004
```

Open <http://localhost:8004/index.html>.

This is an internal local regression shell that replays the Harmonious site structure against `libmusictheory`.

The shell is now directly bootable through explicit route parameters on a plain static host:

- <http://localhost:8004/index.html?route=/p/fb/C-Major>
- <http://localhost:8004/index.html?route=/keyboard/C_3,E_3,G_3>
- <http://localhost:8004/index.html?route=/eadgbe-frets/-1,12,12,9,10,-1>

Internal page-family links are rewritten back through `index.html?route=...` so opening them in a new tab stays inside the single-entry shell instead of depending on direct `/p/...`, `/keyboard/...`, or `/eadgbe-frets/...` server routes.

Interactive keyboard and fretboard edits now also keep the browser on shell-form history entries, so back/forward navigation stays inside the single-entry shell even after live selection changes.

Locally reconstructed search results and key-slider cards now follow the same rule: generated page-route anchors also use shell-form `index.html?route=...` URLs and carry `data-lmt-shell-route`, so copy/new-tab behavior stays consistent even inside fragment content.

The SPA bundle is also static-host ready:

- `zig-out/wasm-harmonious-spa/404.html` is installed for hosts that serve fallback HTML on unknown routes
- raw `/p/...`, `/keyboard/...`, and `/eadgbe-frets/...` requests recover into `index.html?route=...`
- the shell and fallback pages ship a built-in favicon, so the bundle does not need a separate `favicon.ico`
- the shell keeps a canonical link synchronized to the visible shell-form URL

## Project Completion Criteria

The project is not visually complete until all 15 compatibility kinds pass Native RGBA Proof at `55%` and `200%`.
