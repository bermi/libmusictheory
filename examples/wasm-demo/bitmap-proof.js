const statusEl = document.getElementById("status");
const progressEl = document.getElementById("progress");
const summaryHost = document.getElementById("summary-host");
const failureMeta = document.getElementById("failure-meta");
const candidateHost = document.getElementById("candidate-host");
const referenceHost = document.getElementById("reference-host");
const diffHost = document.getElementById("diff-host");
const samplesHost = document.getElementById("samples-host");

const REQUIRED_EXPORTS = [
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
  "lmt_bitmap_compat_target_width",
  "lmt_bitmap_compat_target_height",
  "lmt_bitmap_compat_required_rgba_bytes",
  "lmt_bitmap_compat_render_candidate_rgba",
  "lmt_bitmap_compat_render_reference_svg_rgba",
];

const NAME_CAPACITY = 2048;
const encoder = new TextEncoder();
const decoder = new TextDecoder();

let wasm = null;
let memory = null;
let proofInFlight = false;

class Arena {
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

function bytes() {
  return new Uint8Array(memory.buffer);
}

function readCString(ptr, maxBytes = null) {
  const raw = bytes();
  const limit = maxBytes == null ? raw.length : Math.min(raw.length, ptr + maxBytes);
  let end = ptr;
  while (end < limit && raw[end] !== 0) end += 1;
  return decoder.decode(raw.subarray(ptr, end));
}

function writeUtf8(ptr, text) {
  const raw = bytes();
  const encoded = encoder.encode(text);
  raw.set(encoded, ptr);
  return encoded.length;
}

function scratchArena() {
  const ptr = wasm.lmt_wasm_scratch_ptr();
  const size = wasm.lmt_wasm_scratch_size();
  if (!ptr || !size) throw new Error("missing WASM scratch arena");
  return new Arena(ptr, size);
}

function verifyExports(exportsObj) {
  const missing = REQUIRED_EXPORTS.filter((name) => !(name in exportsObj));
  if (missing.length > 0) throw new Error(`Missing WASM exports: ${missing.join(", ")}`);
}

function parsePositiveInt(raw, fallback) {
  const value = Number.parseInt(String(raw ?? ""), 10);
  if (!Number.isFinite(value) || value <= 0) return fallback;
  return value;
}

function sampleIndexes(total, samplePerKind) {
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

function rgbaView(ptr, size) {
  return new Uint8ClampedArray(memory.buffer, ptr, size);
}

function cloneBytes(ptr, size) {
  return new Uint8ClampedArray(rgbaView(ptr, size));
}

function makeCanvas(width, height, rgbaBytes) {
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d", { alpha: true });
  const image = new ImageData(rgbaBytes, width, height);
  ctx.putImageData(image, 0, 0);
  return canvas;
}

function makeDiff(candidate, reference, width, height) {
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

async function instantiateWasm() {
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
  const bytes = await response.arrayBuffer();
  const module = await WebAssembly.instantiate(bytes, {});
  return module.instance;
}

async function fetchReferenceSvg(referenceRoot, directory, imageName) {
  const encodedDir = directory.split("/").map((part) => encodeURIComponent(part)).join("/");
  const encodedName = encodeURIComponent(imageName);
  const url = `${referenceRoot.replace(/\/$/, "")}/${encodedDir}/${encodedName}`;
  const response = await fetch(url);
  if (!response.ok) return { ok: false, url, svg: "" };
  return { ok: true, url, svg: await response.text() };
}

function readCopyString(fn, outPtr, outCap, ...args) {
  const len = fn(...args, outPtr, outCap);
  if (!len) return "";
  return readCString(outPtr, outCap);
}

function setFailurePreview(sample) {
  failureMeta.textContent = sample.meta;
  candidateHost.innerHTML = "";
  referenceHost.innerHTML = "";
  diffHost.innerHTML = "";
  candidateHost.appendChild(makeCanvas(sample.width, sample.height, sample.candidate));
  referenceHost.appendChild(makeCanvas(sample.width, sample.height, sample.reference));
  diffHost.appendChild(makeCanvas(sample.width, sample.height, sample.diff));
}

function renderSamples(kinds) {
  if (kinds.length === 0) {
    samplesHost.textContent = "No supported bitmap proof samples were collected.";
    return;
  }
  samplesHost.innerHTML = kinds.map((entry) => `
    <section class="sample-kind">
      <h3 class="mono">${entry.kind}</h3>
      <div class="sample-items">
        ${entry.samples.map((sample) => `
          <article class="sample-item">
            <p class="sample-meta mono">image=${sample.imageName} | drift=${sample.drift.toFixed(8)} | changed=${sample.changedPixels}</p>
            <div class="sample-compare">
              <div><h4>Candidate</h4><div class="canvas-host" data-sample-candidate="${sample.imageName}"></div></div>
              <div><h4>Reference</h4><div class="canvas-host" data-sample-reference="${sample.imageName}"></div></div>
              <div><h4>Diff</h4><div class="canvas-host" data-sample-diff="${sample.imageName}"></div></div>
            </div>
          </article>
        `).join("")}
      </div>
    </section>
  `).join("");

  for (const entry of kinds) {
    for (const sample of entry.samples) {
      const section = [...samplesHost.querySelectorAll(".sample-kind")].find((node) => node.querySelector("h3")?.textContent === entry.kind);
      if (!section) continue;
      section.querySelector(`[data-sample-candidate="${CSS.escape(sample.imageName)}"]`)?.appendChild(makeCanvas(sample.width, sample.height, sample.candidate));
      section.querySelector(`[data-sample-reference="${CSS.escape(sample.imageName)}"]`)?.appendChild(makeCanvas(sample.width, sample.height, sample.reference));
      section.querySelector(`[data-sample-diff="${CSS.escape(sample.imageName)}"]`)?.appendChild(makeCanvas(sample.width, sample.height, sample.diff));
    }
  }
}

async function runProof() {
  if (proofInFlight) return;
  proofInFlight = true;
  const runButton = document.getElementById("run-proof");
  runButton.disabled = true;

  try {
    const refRoot = document.getElementById("ref-root").value.trim();
    const samplePerKind = Math.max(5, parsePositiveInt(document.getElementById("visual-sample-size").value, 5));
    const params = new URLSearchParams(window.location.search);
    const kindFilter = params.get("kinds")
      ? new Set(params.get("kinds").split(",").map((name) => name.trim()).filter(Boolean))
      : null;

    const arena = scratchArena();
    const namePtr = arena.alloc(NAME_CAPACITY, 1);
    const svgPtr = arena.alloc(2 * 1024 * 1024, 1);

    const rows = [];
    const sampleGroups = [];
    let firstFailure = null;
    let supportedKinds = 0;
    let unsupportedKinds = 0;
    let compared = 0;
    let passing = 0;

    const threshold = 0.0001;
    const kindCount = wasm.lmt_svg_compat_kind_count();
    for (let kindIndex = 0; kindIndex < kindCount; kindIndex += 1) {
      const kindName = readCString(wasm.lmt_svg_compat_kind_name(kindIndex));
      if (kindFilter && !kindFilter.has(kindName)) continue;
      const directory = readCString(wasm.lmt_svg_compat_kind_directory(kindIndex));
      const total = wasm.lmt_svg_compat_image_count(kindIndex);
      const supported = wasm.lmt_bitmap_compat_kind_supported(kindIndex) === 1;
      if (!supported) {
        unsupportedKinds += 1;
        rows.push({ kind: kindName, directory, total, supported: false, compared: 0, passing: 0, failures: 0, unsupported: total });
        continue;
      }
      supportedKinds += 1;

      const indexes = sampleIndexes(total, samplePerKind);
      const width = wasm.lmt_bitmap_compat_target_width(kindIndex, indexes[0] ?? 0);
      const height = wasm.lmt_bitmap_compat_target_height(kindIndex, indexes[0] ?? 0);
      const rgbaBytes = wasm.lmt_bitmap_compat_required_rgba_bytes(kindIndex, indexes[0] ?? 0);
      if (!width || !height || !rgbaBytes) throw new Error(`bitmap proof target unavailable for supported kind ${kindName}`);

      const candidatePtr = arena.alloc(rgbaBytes, 4);
      const referencePtr = arena.alloc(rgbaBytes, 4);
      const samples = [];
      let kindPassing = 0;
      let kindFailures = 0;

      progressEl.textContent = `Generating bitmap proof for ${kindName} (${indexes.length}/${total})`;
      for (const imageIndex of indexes) {
        const imageName = readCopyString(wasm.lmt_svg_compat_image_name, namePtr, NAME_CAPACITY, kindIndex, imageIndex);
        const candidateWritten = wasm.lmt_bitmap_compat_render_candidate_rgba(kindIndex, imageIndex, candidatePtr, rgbaBytes);
        if (candidateWritten !== rgbaBytes) {
          kindFailures += 1;
          if (!firstFailure) {
            firstFailure = { meta: `kind=${kindName} | image=${imageName} | error=candidate render failed`, width, height, candidate: new Uint8ClampedArray(rgbaBytes), reference: new Uint8ClampedArray(rgbaBytes), diff: new Uint8ClampedArray(rgbaBytes) };
          }
          continue;
        }

        const referenceSvg = await fetchReferenceSvg(refRoot, directory, imageName);
        if (!referenceSvg.ok) {
          kindFailures += 1;
          if (!firstFailure) {
            firstFailure = { meta: `kind=${kindName} | image=${imageName} | error=missing reference | url=${referenceSvg.url}`, width, height, candidate: cloneBytes(candidatePtr, rgbaBytes), reference: new Uint8ClampedArray(rgbaBytes), diff: new Uint8ClampedArray(rgbaBytes) };
          }
          continue;
        }

        const svgLen = writeUtf8(svgPtr, referenceSvg.svg);
        const referenceWritten = wasm.lmt_bitmap_compat_render_reference_svg_rgba(kindIndex, svgPtr, svgLen, referencePtr, rgbaBytes);
        if (referenceWritten !== rgbaBytes) {
          kindFailures += 1;
          if (!firstFailure) {
            firstFailure = { meta: `kind=${kindName} | image=${imageName} | error=reference raster failed | url=${referenceSvg.url}`, width, height, candidate: cloneBytes(candidatePtr, rgbaBytes), reference: new Uint8ClampedArray(rgbaBytes), diff: new Uint8ClampedArray(rgbaBytes) };
          }
          continue;
        }

        const candidateBytes = cloneBytes(candidatePtr, rgbaBytes);
        const referenceBytes = cloneBytes(referencePtr, rgbaBytes);
        const diff = makeDiff(candidateBytes, referenceBytes, width, height);
        compared += 1;
        if (diff.drift <= threshold) {
          passing += 1;
          kindPassing += 1;
        } else {
          kindFailures += 1;
          if (!firstFailure) {
            firstFailure = {
              meta: `kind=${kindName} | image=${imageName} | drift=${diff.drift} | changed=${diff.changedPixels} | url=${referenceSvg.url}`,
              width,
              height,
              candidate: candidateBytes,
              reference: referenceBytes,
              diff: diff.pixels,
            };
          }
        }

        samples.push({
          imageName,
          width,
          height,
          drift: diff.drift,
          changedPixels: diff.changedPixels,
          candidate: candidateBytes,
          reference: referenceBytes,
          diff: diff.pixels,
        });
      }

      rows.push({ kind: kindName, directory, total, supported: true, compared: indexes.length, passing: kindPassing, failures: kindFailures, unsupported: 0 });
      sampleGroups.push({ kind: kindName, samples });
    }

    summaryHost.innerHTML = `
      <table>
        <thead>
          <tr><th>Kind</th><th>Directory</th><th>Images</th><th>Support</th><th>Compared</th><th>Passing</th><th>Failures</th><th>Unsupported</th></tr>
        </thead>
        <tbody>
          ${rows.map((row) => `
            <tr>
              <td class="mono">${row.kind}</td>
              <td class="mono">${row.directory}</td>
              <td>${row.total}</td>
              <td class="${row.supported ? "good" : "bad"}">${row.supported ? "supported" : "unsupported"}</td>
              <td>${row.compared}</td>
              <td class="${row.failures === 0 && row.supported ? "good" : ""}">${row.passing}</td>
              <td class="${row.failures > 0 ? "bad" : ""}">${row.failures}</td>
              <td>${row.unsupported}</td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    `;

    if (firstFailure) {
      setFailurePreview(firstFailure);
    } else {
      failureMeta.textContent = "No failures captured.";
      candidateHost.innerHTML = "";
      referenceHost.innerHTML = "";
      diffHost.innerHTML = "";
    }
    renderSamples(sampleGroups);

    const summaryLines = [
      `Kinds: ${rows.length}`,
      `Supported kinds: ${supportedKinds}`,
      `Unsupported kinds: ${unsupportedKinds}`,
      `Compared samples: ${compared}`,
      `Passing samples: ${passing}`,
      `Failures: ${compared - passing}`,
      `Drift threshold: 0.0001`,
    ];
    progressEl.textContent = summaryLines.join("\n");
    window.__lmtLastBitmapProof = { rows, supportedKinds, unsupportedKinds, compared, passing, failures: compared - passing, threshold };
    statusEl.textContent = "Bitmap proof run completed.";
    statusEl.style.color = "#1f6c72";
  } finally {
    proofInFlight = false;
    runButton.disabled = false;
  }
}

async function main() {
  try {
    const instance = await instantiateWasm();
    wasm = instance.exports;
    verifyExports(wasm);
    memory = wasm.memory;
    statusEl.textContent = "WASM loaded. Bitmap proof validation is ready.";
    statusEl.style.color = "#1f6c72";
    document.getElementById("run-proof").addEventListener("click", () => {
      runProof().catch((err) => {
        statusEl.textContent = `Bitmap proof failed: ${err.message}`;
        statusEl.style.color = "#b03620";
      });
    });
  } catch (err) {
    statusEl.textContent = `Failed to initialize: ${err.message}`;
    statusEl.style.color = "#b03620";
  }
}

main();
