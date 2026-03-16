export const BASE_REQUIRED_EXPORTS = [
  "memory",
  "lmt_wasm_scratch_ptr",
  "lmt_wasm_scratch_size",
  "lmt_svg_compat_kind_count",
  "lmt_svg_compat_kind_name",
  "lmt_svg_compat_kind_directory",
  "lmt_svg_compat_image_count",
  "lmt_svg_compat_image_name",
  "lmt_bitmap_proof_scale_numerator",
  "lmt_bitmap_proof_scale_denominator",
  "lmt_bitmap_compat_kind_supported",
  "lmt_bitmap_compat_candidate_backend_name",
  "lmt_bitmap_compat_target_width_scaled",
  "lmt_bitmap_compat_target_height_scaled",
  "lmt_bitmap_compat_required_rgba_bytes_scaled",
  "lmt_bitmap_compat_render_candidate_rgba_scaled",
  "lmt_bitmap_compat_render_reference_svg_rgba_scaled",
];

export const PARITY_REQUIRED_EXPORTS = [
  ...BASE_REQUIRED_EXPORTS,
  "lmt_svg_compat_generate",
];

export const NAME_CAPACITY = 2048;
export const SVG_CAPACITY = 2 * 1024 * 1024;

const encoder = new TextEncoder();
const decoder = new TextDecoder();

export class Arena {
  constructor(base, size) {
    this.base = base;
    this.limit = base + size;
    this.ptr = base;
  }

  alloc(size, align = 1) {
    const out = Math.ceil(this.ptr / align) * align;
    const next = out + size;
    if (next > this.limit) {
      throw new Error(`wasm scratch exhausted (${next - this.base}/${this.limit - this.base})`);
    }
    this.ptr = next;
    return out;
  }
}

export function createPageRefs(runButtonId) {
  return {
    statusEl: document.getElementById("status"),
    progressEl: document.getElementById("progress"),
    summaryHost: document.getElementById("summary-host"),
    failureMeta: document.getElementById("failure-meta"),
    candidateHost: document.getElementById("candidate-host"),
    referenceHost: document.getElementById("reference-host"),
    diffHost: document.getElementById("diff-host"),
    samplesHost: document.getElementById("samples-host"),
    runButton: document.getElementById(runButtonId),
    refRootInput: document.getElementById("ref-root"),
    scaleListInput: document.getElementById("scale-list"),
    visualSampleSizeInput: document.getElementById("visual-sample-size"),
  };
}

export function bytes(memory) {
  return new Uint8Array(memory.buffer);
}

export function readCString(memory, ptr, maxBytes = null) {
  const raw = bytes(memory);
  const limit = maxBytes == null ? raw.length : Math.min(raw.length, ptr + maxBytes);
  let end = ptr;
  while (end < limit && raw[end] !== 0) end += 1;
  return decoder.decode(raw.subarray(ptr, end));
}

export function writeUtf8(memory, ptr, text) {
  const raw = bytes(memory);
  const encoded = encoder.encode(text);
  raw.set(encoded, ptr);
  return encoded.length;
}

export function scratchArena(wasm) {
  const ptr = wasm.lmt_wasm_scratch_ptr();
  const size = wasm.lmt_wasm_scratch_size();
  if (!ptr || !size) throw new Error("missing WASM scratch arena");
  return new Arena(ptr, size);
}

export function verifyExports(exportsObj, requiredExports) {
  const missing = requiredExports.filter((name) => !(name in exportsObj));
  if (missing.length > 0) throw new Error(`Missing WASM exports: ${missing.join(", ")}`);
}

export function parsePositiveInt(raw, fallback) {
  const value = Number.parseInt(String(raw ?? ""), 10);
  if (!Number.isFinite(value) || value <= 0) return fallback;
  return value;
}

export function parseKindFilter() {
  const params = new URLSearchParams(window.location.search);
  if (!params.get("kinds")) return null;
  return new Set(params.get("kinds").split(",").map((name) => name.trim()).filter(Boolean));
}

export function parseQueryScales() {
  return new URLSearchParams(window.location.search).get("scales");
}

export function sampleIndexes(total, samplePerKind) {
  const indexes = Array.from({ length: total }, (_, index) => index);
  if (samplePerKind >= total) return indexes;
  const copy = [...indexes];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    const tmp = copy[i];
    copy[i] = copy[j];
    copy[j] = tmp;
  }
  return copy.slice(0, samplePerKind).sort((a, b) => a - b);
}

export function rgbaView(memory, ptr, size) {
  return new Uint8ClampedArray(memory.buffer, ptr, size);
}

export function cloneBytes(memory, ptr, size) {
  return new Uint8ClampedArray(rgbaView(memory, ptr, size));
}

export function makeCanvas(width, height, rgbaBytes) {
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d", { alpha: true });
  const image = new ImageData(rgbaBytes, width, height);
  ctx.putImageData(image, 0, 0);
  return canvas;
}

export function makeDiff(candidate, reference, width, height) {
  const diff = new Uint8ClampedArray(candidate.length);
  let sumAbs = 0;
  let changedPixels = 0;
  let maxDelta = 0;

  for (let i = 0; i < candidate.length; i += 4) {
    const dr = Math.abs(candidate[i] - reference[i]);
    const dg = Math.abs(candidate[i + 1] - reference[i + 1]);
    const db = Math.abs(candidate[i + 2] - reference[i + 2]);
    const da = Math.abs(candidate[i + 3] - reference[i + 3]);
    const pixelDelta = dr + dg + db + da;
    sumAbs += pixelDelta;
    maxDelta = Math.max(maxDelta, pixelDelta);
    if (pixelDelta > 0) {
      changedPixels += 1;
      diff[i] = 255;
      diff[i + 1] = 48;
      diff[i + 2] = 48;
      diff[i + 3] = 255;
    } else {
      const luma = Math.round((reference[i] + reference[i + 1] + reference[i + 2]) / 3);
      diff[i] = luma;
      diff[i + 1] = luma;
      diff[i + 2] = luma;
      diff[i + 3] = 72;
    }
  }

  const drift = width * height > 0 ? sumAbs / (255 * 4 * width * height) : 0;
  return { drift, changedPixels, maxDelta, pixels: diff };
}

export async function instantiateWasm() {
  const wasmUrl = "./libmusictheory.wasm";
  if (WebAssembly.instantiateStreaming) {
    try {
      const streaming = await WebAssembly.instantiateStreaming(fetch(wasmUrl), {});
      return streaming.instance;
    } catch (_err) {
      // fall back below
    }
  }

  const response = await fetch(wasmUrl);
  if (!response.ok) throw new Error(`Failed to fetch ${wasmUrl}: ${response.status}`);
  const wasmBytes = await response.arrayBuffer();
  const module = await WebAssembly.instantiate(wasmBytes, {});
  return module.instance;
}

export async function fetchReferenceSvg(referenceRoot, directory, imageName) {
  const encodedDir = directory.split("/").map((part) => encodeURIComponent(part)).join("/");
  const encodedName = encodeURIComponent(imageName);
  const url = `${referenceRoot.replace(/\/$/, "")}/${encodedDir}/${encodedName}`;
  const response = await fetch(url);
  if (!response.ok) return { ok: false, url, svg: "" };
  return { ok: true, url, svg: await response.text() };
}

export function readCopyString(memory, fn, outPtr, outCap, ...args) {
  const len = fn(...args, outPtr, outCap);
  if (!len) return "";
  if (len >= outCap) throw new Error(`WASM string truncated (len=${len}, cap=${outCap})`);
  return readCString(memory, outPtr, outCap);
}

export function parseScaleSpecs(raw) {
  const specs = String(raw ?? "")
    .split(",")
    .map((token) => token.trim())
    .filter(Boolean)
    .map((token) => {
      const normalized = token.replace(/%/g, "");
      let numerator = 0;
      let denominator = 0;
      if (normalized.includes("/")) {
        const [numRaw, denRaw] = normalized.split("/");
        numerator = Number.parseInt(numRaw, 10);
        denominator = Number.parseInt(denRaw, 10);
      } else if (normalized.includes(":")) {
        const [numRaw, denRaw] = normalized.split(":");
        numerator = Number.parseInt(numRaw, 10);
        denominator = Number.parseInt(denRaw, 10);
      } else {
        numerator = Number.parseInt(normalized, 10);
        denominator = 100;
      }
      if (!Number.isFinite(numerator) || !Number.isFinite(denominator) || numerator <= 0 || denominator <= 0) {
        throw new Error(`invalid scale token '${token}'`);
      }
      return {
        numerator,
        denominator,
        key: `${numerator}:${denominator}`,
        label: `${numerator}/${denominator}`,
        percentLabel: `${((numerator / denominator) * 100).toFixed(0)}%`,
      };
    });

  if (specs.length === 0) throw new Error("at least one scale is required");
  const seen = new Set();
  for (const spec of specs) {
    if (seen.has(spec.key)) throw new Error(`duplicate scale '${spec.label}'`);
    seen.add(spec.key);
  }
  return specs;
}

export function defaultScaleInputValue(wasm) {
  return `${wasm.lmt_bitmap_proof_scale_numerator()}/${wasm.lmt_bitmap_proof_scale_denominator()},200/100`;
}

export function setFailurePreview(page, sample) {
  page.failureMeta.textContent = sample.meta;
  page.candidateHost.innerHTML = "";
  page.referenceHost.innerHTML = "";
  page.diffHost.innerHTML = "";
  page.candidateHost.appendChild(makeCanvas(sample.width, sample.height, sample.candidate));
  page.referenceHost.appendChild(makeCanvas(sample.width, sample.height, sample.reference));
  page.diffHost.appendChild(makeCanvas(sample.width, sample.height, sample.diff));
}

export function renderSamples(page, groups, emptyText) {
  if (groups.length === 0) {
    page.samplesHost.textContent = emptyText;
    return;
  }
  page.samplesHost.innerHTML = groups.map((entry) => `
    <section class="sample-kind">
      <h3 class="mono">${entry.kind} @ ${entry.scalePercent} [${entry.candidateSource} | ${entry.candidateBackend}]</h3>
      <div class="sample-items">
        ${entry.samples.map((sample) => `
          <article class="sample-item">
            <p class="sample-meta mono">image=${sample.imageName} | scale=${sample.scalePercent} | source=${sample.candidateSource} | backend=${sample.candidateBackend} | drift=${sample.drift.toFixed(8)} | changed=${sample.changedPixels}</p>
            <div class="sample-compare">
              <div><h4>Candidate</h4><div class="canvas-host" data-sample-candidate="${entry.key}:${sample.imageName}"></div></div>
              <div><h4>Reference</h4><div class="canvas-host" data-sample-reference="${entry.key}:${sample.imageName}"></div></div>
              <div><h4>Diff</h4><div class="canvas-host" data-sample-diff="${entry.key}:${sample.imageName}"></div></div>
            </div>
          </article>
        `).join("")}
      </div>
    </section>
  `).join("");

  for (const entry of groups) {
    for (const sample of entry.samples) {
      const key = `${entry.key}:${sample.imageName}`;
      page.samplesHost.querySelector(`[data-sample-candidate="${CSS.escape(key)}"]`)?.appendChild(makeCanvas(sample.width, sample.height, sample.candidate));
      page.samplesHost.querySelector(`[data-sample-reference="${CSS.escape(key)}"]`)?.appendChild(makeCanvas(sample.width, sample.height, sample.reference));
      page.samplesHost.querySelector(`[data-sample-diff="${CSS.escape(key)}"]`)?.appendChild(makeCanvas(sample.width, sample.height, sample.diff));
    }
  }
}

export function clearFailurePreview(page) {
  page.failureMeta.textContent = "No failures captured.";
  page.candidateHost.innerHTML = "";
  page.referenceHost.innerHTML = "";
  page.diffHost.innerHTML = "";
}
