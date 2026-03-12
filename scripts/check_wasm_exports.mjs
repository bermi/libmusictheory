#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const REQUIRED_EXPORTS = [
  'memory',
  'lmt_pcs_from_list',
  'lmt_pcs_to_list',
  'lmt_pcs_cardinality',
  'lmt_pcs_transpose',
  'lmt_pcs_invert',
  'lmt_pcs_complement',
  'lmt_pcs_is_subset',
  'lmt_prime_form',
  'lmt_forte_prime',
  'lmt_is_cluster_free',
  'lmt_evenness_distance',
  'lmt_scale',
  'lmt_mode',
  'lmt_spell_note',
  'lmt_spell_note_parts',
  'lmt_chord',
  'lmt_chord_name',
  'lmt_roman_numeral',
  'lmt_roman_numeral_parts',
  'lmt_fret_to_midi',
  'lmt_midi_to_fret_positions',
  'lmt_svg_clock_optc',
  'lmt_svg_fret',
  'lmt_svg_chord_staff',
  'lmt_wasm_scratch_ptr',
  'lmt_wasm_scratch_size',
  'lmt_svg_compat_kind_count',
  'lmt_svg_compat_kind_name',
  'lmt_svg_compat_kind_directory',
  'lmt_svg_compat_image_count',
  'lmt_svg_compat_image_name',
  'lmt_svg_compat_generate',
];

function parseArg(flag, fallback = null) {
  const idx = process.argv.indexOf(flag);
  if (idx === -1) return fallback;
  if (idx + 1 >= process.argv.length) {
    throw new Error(`missing value for ${flag}`);
  }
  return process.argv[idx + 1];
}

async function main() {
  const wasmPathArg = parseArg('--wasm', 'zig-out/wasm-demo/libmusictheory.wasm');
  const wasmPath = path.resolve(process.cwd(), wasmPathArg);

  if (!fs.existsSync(wasmPath)) {
    throw new Error(`wasm not found: ${wasmPath}`);
  }

  const bytes = fs.readFileSync(wasmPath);
  const mod = await WebAssembly.compile(bytes);
  const exports = WebAssembly.Module.exports(mod).map((entry) => entry.name);
  const exportSet = new Set(exports);

  const missing = REQUIRED_EXPORTS.filter((name) => !exportSet.has(name));
  if (missing.length > 0) {
    console.error(`missing required exports (${missing.length}): ${missing.join(', ')}`);
    process.exit(1);
  }

  console.log(`wasm exports ok: required=${REQUIRED_EXPORTS.length}, actual=${exports.length}`);
}

main().catch((err) => {
  console.error(err.message || String(err));
  process.exit(1);
});
