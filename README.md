# libmusictheory

`libmusictheory` is a Zig music-theory library with a C ABI and browser/WASM surfaces.

It covers:

- pitch-class-set operations and set classification
- scales, modes, keys, note spelling, and chord naming
- harmony, roman numerals, and voice-leading helpers
- fretboard and keyboard interaction models
- SVG generation for clocks, fret diagrams, staff notation, tessellations, and related theory imagery

## Public vs Internal Surfaces

The stable public surface is intentionally smaller than the full repository.

- Stable public surface:
  - `/Users/bermi/code/libmusictheory/include/libmusictheory.h`
  - `/Users/bermi/code/libmusictheory/src/root.zig` for core Zig consumers
  - `zig build`, `zig build test`, `zig build verify`
  - `zig build wasm-docs` as the standalone browser bundle
  - `zig build wasm-gallery` as the standalone creative example bundle
- Experimental surface:
  - `lmt_raster_is_enabled`
  - `lmt_raster_demo_rgba`
- Internal surface:
  - `/Users/bermi/code/libmusictheory/include/libmusictheory_compat.h`
  - Harmonious parity/proof/SPA bundles:
    - `wasm-demo`
    - `wasm-scaled-render-parity`
    - `wasm-native-rgba-proof`
    - `wasm-harmonious-spa`
  - Zig namespaces used only for verification against harmoniousapp.net, such as `harmonious_svg_compat`, `bitmap_compat`, and the `svg_*_compat` modules

If you are integrating the library into your own app, start with `libmusictheory.h` or the core Zig modules. Treat the compat/proof surface as regression infrastructure, not product API.

The internal regression infrastructure is documented separately in `/Users/bermi/code/libmusictheory/docs/internal/harmonious-regression.md`.

## Stable API Contract

This repository now has an explicit stable public surface.

- Stable:
  - the declarations in `/Users/bermi/code/libmusictheory/include/libmusictheory.h`, except the APIs called out as experimental below
  - scalar theory functions such as `lmt_pcs_*`, `lmt_scale`, `lmt_mode`, `lmt_chord`, `lmt_evenness_distance`
  - public string helpers such as `lmt_spell_note`, `lmt_chord_name`, `lmt_roman_numeral`
  - public fretboard helpers such as `lmt_fret_to_midi_n`, `lmt_midi_to_fret_positions_n`, `lmt_generate_voicings_n`, `lmt_pitch_class_guide_n`, `lmt_frets_to_url_n`, `lmt_url_to_frets_n`
  - public SVG helpers such as `lmt_svg_clock_optc`, `lmt_svg_fret`, `lmt_svg_fret_n`, `lmt_svg_chord_staff`
- Experimental:
  - `lmt_raster_is_enabled`
  - `lmt_raster_demo_rgba`
  - these are useful for demos and internal rendering work, but not yet the stable embedding contract
- Internal:
  - everything declared only in `/Users/bermi/code/libmusictheory/include/libmusictheory_compat.h`
  - all exact harmoniousapp.net parity/proof helpers
  - internal browser verification bundles and the Harmonious SPA shell

Return-value rules are explicit:

- scalar theory functions return computed values directly
- count-returning APIs such as `lmt_pcs_to_list`, `lmt_midi_to_fret_positions_n`, `lmt_pitch_class_guide_n`, and `lmt_url_to_frets_n` return the logical row/count result, even if you pass a smaller output buffer
- SVG writers such as `lmt_svg_clock_optc`, `lmt_svg_fret`, `lmt_svg_fret_n`, and `lmt_svg_chord_staff` return the total SVG byte length required; pass `buf = NULL` and `buf_size = 0` to size the buffer first
- `lmt_frets_to_url_n` returns the bytes actually written and requires a caller buffer up front
- experimental raster writers return `0` on disabled-backend, invalid-input, or insufficient-buffer cases

## Memory And Lifetime

- No heap ownership is transferred to callers for the stable C ABI.
- Caller-owned output buffers are required for:
  - list outputs
  - fret-position outputs
  - guide-dot outputs
  - URL serialization
  - SVG serialization
  - experimental RGBA output
- String-returning APIs such as `lmt_spell_note`, `lmt_chord_name`, and `lmt_roman_numeral` return pointers to shared internal rotating storage.
  - Copy the string if you need to keep it.
  - Do not free it.
  - Do not assume it survives another string-returning call.
  - Do not treat it as thread-safe shared state.
- Core theory algorithms are written to avoid allocation-heavy embedding patterns. For consumers, the safe assumption is that all durable output memory is owned by the caller.

## Quickstart (C ABI)

Build the native artifacts:

```bash
cd /Users/bermi/code/libmusictheory
zig build
```

The installed outputs land under:

- `/Users/bermi/code/libmusictheory/zig-out/include`
- `/Users/bermi/code/libmusictheory/zig-out/lib`

Minimal example:

```c
#include "libmusictheory.h"

#include <stdio.h>

int main(void) {
    const lmt_pitch_class triad[3] = {0, 4, 7};
    lmt_pitch_class_set set = lmt_pcs_from_list(triad, 3);

    char svg[4096];
    unsigned svg_len = lmt_svg_clock_optc(set, svg, sizeof(svg));

    printf("pcs=0x%03x chord=%s svg_bytes=%u\n",
           set,
           lmt_chord_name(set),
           svg_len);
    return 0;
}
```

Compile against the installed header and library from `zig-out`.

## Quickstart (Zig)

Today the simplest Zig integration is source-based. Add the module from a checkout or vendored copy:

```zig
const libmusictheory = b.addModule("libmusictheory", .{
    .root_source_file = b.path("../libmusictheory/src/root.zig"),
    .target = target,
    .optimize = optimize,
});
```

Use it from Zig:

```zig
const std = @import("std");
const lmt = @import("libmusictheory");

pub fn main() !void {
    const set = lmt.pitch_class_set.fromList(&.{ 0, 4, 7 });
    const prime = lmt.set_class.primeForm(set);
    std.debug.print("set=0x{x} prime=0x{x}\n", .{ set, prime });
}
```

The stable Zig-facing namespaces are the core theory and rendering modules exported from `/Users/bermi/code/libmusictheory/src/root.zig`. Internal compat namespaces remain available in source, but they are not the standalone contract.

## Quickstart (Browser/WASM)

The public browser-facing entries today are the standalone docs bundle and the standalone gallery bundle.

```bash
cd /Users/bermi/code/libmusictheory
zig build wasm-docs
python3 -m http.server --directory /Users/bermi/code/libmusictheory/zig-out/wasm-docs 8001
```

Open [http://localhost:8001/index.html](http://localhost:8001/index.html).

For a gallery that uses only the stable public APIs:

```bash
cd /Users/bermi/code/libmusictheory
zig build wasm-gallery
python3 -m http.server --directory /Users/bermi/code/libmusictheory/zig-out/wasm-gallery 8002
```

Open [http://localhost:8002/index.html](http://localhost:8002/index.html).

## Gallery Scenes

The standalone gallery is intentionally curated around concrete musical-discovery workflows:

- `Set Observatory`: inspect a pitch-class set as a constellation with prime-form, complement, inversion, and evenness context
- `Key Bloom`: watch one tonic generate a full diatonic orbit and its triadic degree field
- `Chord Atelier`: read one sonority simultaneously as set, chord label, roman numeral, clock, and staff image
- `Progression Drift`: treat cadences as moving set-fields and track shared tones across a progression
- `Constellation Delta`: compare two pitch-class worlds by overlap, union, and transpositional relation
- `Fret Atlas`: explore the same pitch logic across arbitrary tunings and string counts

These scenes are driven by the authored preset manifest at `/Users/bermi/code/libmusictheory/examples/wasm-gallery/gallery-presets.json`.

## Release Readiness

The standalone release scaffold is documented here:

- `/Users/bermi/code/libmusictheory/RELEASE_CHECKLIST.md`
- `/Users/bermi/code/libmusictheory/docs/release/artifacts.md`
- `/Users/bermi/code/libmusictheory/docs/release/gallery-capture.md`
- `/Users/bermi/code/libmusictheory/docs/release/reviewer-guide.md`
- `/Users/bermi/code/libmusictheory/docs/release/smoke-matrix.md`
- `/Users/bermi/code/libmusictheory/docs/release/versioning.md`

To run the standalone release smoke path directly:

```bash
cd /Users/bermi/code/libmusictheory
./scripts/release_smoke.sh
```

This smoke path validates only the standalone surfaces: native build, C ABI smoke, `wasm-docs`, and `wasm-gallery`.

To regenerate the release-candidate gallery screenshots locally:

```bash
cd /Users/bermi/code/libmusictheory
node /Users/bermi/code/libmusictheory/scripts/capture_wasm_gallery_screenshots.mjs
```

This writes deterministic captures to `/Users/bermi/code/libmusictheory/zig-out/wasm-gallery-captures/`.

If you want to call exports directly from JavaScript, start with scalar APIs that do not require manual buffer setup:

```html
<script type="module">
  const { instance } = await WebAssembly.instantiateStreaming(fetch("/libmusictheory.wasm"), {});
  const { lmt_scale, lmt_mode } = instance.exports;

  console.log("C diatonic scale pcs =", lmt_scale(0, 0).toString(16));
  console.log("C dorian pcs =", lmt_mode(1, 0).toString(16));
</script>
```

Low-level browser buffer management is still evolving. The standalone contract today is the exported functions in `libmusictheory.h` plus the `wasm-docs` bundle, not the internal Harmonious scratch helpers.

## Further Reading

- `/Users/bermi/code/libmusictheory/docs/research/`
- `/Users/bermi/code/libmusictheory/docs/architecture/graphs.md`
