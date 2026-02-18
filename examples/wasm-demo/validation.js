const statusEl = document.getElementById("status");
const progressEl = document.getElementById("progress");
const summaryHost = document.getElementById("summary-host");
const mismatchMeta = document.getElementById("mismatch-meta");
const generatedHost = document.getElementById("generated-host");
const referenceHost = document.getElementById("reference-host");
const visualSampleEnabledEl = document.getElementById("visual-sample-enabled");
const visualSampleSizeEl = document.getElementById("visual-sample-size");
const visualSamplesHost = document.getElementById("visual-samples-host");

let wasm = null;
let memory = null;
let validationInFlight = false;
const textDecoder = new TextDecoder();

const REQUIRED_EXPORTS = [
  "memory",
  "lmt_wasm_scratch_ptr",
  "lmt_wasm_scratch_size",
  "lmt_svg_compat_kind_count",
  "lmt_svg_compat_kind_name",
  "lmt_svg_compat_kind_directory",
  "lmt_svg_compat_image_count",
  "lmt_svg_compat_image_name",
  "lmt_svg_compat_generate",
];

const C_STRING_CAPACITY = 4 * 1024 * 1024;
const NAME_STRING_CAPACITY = 2048;

class ScratchArena {
  constructor(base, size) {
    this.base = base;
    this.limit = base + size;
    this.ptr = base;
  }

  alloc(size, align = 1) {
    if (align < 1) {
      throw new Error(`invalid arena alignment ${align}`);
    }
    const out = Math.ceil(this.ptr / align) * align;
    const next = out + size;
    if (next > this.limit) {
      throw new Error(`wasm scratch exhausted (${next - this.base}/${this.limit - this.base})`);
    }
    this.ptr = next;
    return out;
  }
}

function u8() {
  return new Uint8Array(memory.buffer);
}

function readCString(ptr, maxBytes = null) {
  const bytes = u8();
  const limit = maxBytes === null ? bytes.length : Math.min(bytes.length, ptr + maxBytes);
  let end = ptr;
  while (end < limit && bytes[end] !== 0) end += 1;
  return textDecoder.decode(bytes.subarray(ptr, end));
}

function readCopyString(fn, outPtr, outCapacity, ...args) {
  const len = fn(...args, outPtr, outCapacity);
  if (!len) return "";
  return readCString(outPtr, outCapacity);
}

function compatScratchArena() {
  const ptr = wasm.lmt_wasm_scratch_ptr();
  const size = wasm.lmt_wasm_scratch_size();
  if (!ptr || size === 0) {
    throw new Error("WASM scratch region is unavailable");
  }
  return new ScratchArena(ptr, size);
}

function htmlEscape(text) {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function normalizeRoot(raw) {
  if (!raw) return "";
  return raw.endsWith("/") ? raw.slice(0, -1) : raw;
}

async function fetchReferenceSvg(referenceRoot, directory, imageName) {
  const encodedDir = directory
    .split("/")
    .map((part) => encodeURIComponent(part))
    .join("/");
  const encodedName = encodeURIComponent(imageName);
  const url = `${normalizeRoot(referenceRoot)}/${encodedDir}/${encodedName}`;
  const response = await fetch(url);
  if (!response.ok) {
    return { ok: false, url, svg: "" };
  }
  return { ok: true, url, svg: await response.text() };
}

function buildSummaryTable(rows, sampledRun) {
  const header = `
    <table>
      <thead>
        <tr>
          <th>Kind</th>
          <th>Directory</th>
          <th>Images</th>
          <th>Generated</th>
          <th>Exact Matches</th>
          <th>Mismatches</th>
          <th>Missing Ref</th>
        </tr>
      </thead>
      <tbody>
        ${rows
          .map((row) => `
            <tr>
              <td class="mono">${htmlEscape(row.kind)}</td>
              <td class="mono">${htmlEscape(row.directory)}</td>
              <td class="mono">${sampledRun ? `${row.sampleTotal}/${row.total}` : row.total}</td>
              <td>${row.generated}</td>
              <td class="${row.matches === row.sampleTotal ? "good" : ""}">${row.matches}</td>
              <td class="${row.mismatches > 0 ? "bad" : ""}">${row.mismatches}</td>
              <td>${row.missingReference}</td>
            </tr>
          `)
          .join("")}
      </tbody>
    </table>
  `;

  summaryHost.innerHTML = header;
}

function clearMismatchPreview() {
  mismatchMeta.textContent = "No mismatches captured.";
  generatedHost.innerHTML = "";
  referenceHost.innerHTML = "";
}

function clearVisualSamples(message) {
  visualSamplesHost.innerHTML = `<div class="sample-empty">${htmlEscape(message)}</div>`;
}

function parsePositiveInt(raw) {
  if (raw == null || raw.trim() === "") return null;
  const value = Number.parseInt(raw, 10);
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`Invalid positive integer: ${raw}`);
  }
  return value;
}

function sampleIndexes(total, samplePerKind) {
  const indexes = Array.from({ length: total }, (_, index) => index);
  if (samplePerKind == null || samplePerKind >= total) return indexes;
  if (samplePerKind === 1) return [0];

  const picked = new Set();
  const last = total - 1;
  for (let i = 0; i < samplePerKind; i += 1) {
    const idx = Math.round((i * last) / (samplePerKind - 1));
    picked.add(idx);
  }
  for (let idx = 0; picked.size < samplePerKind && idx < total; idx += 1) {
    picked.add(idx);
  }
  return [...picked].sort((a, b) => a - b);
}

function randomSubset(indexes, count) {
  if (count >= indexes.length) return [...indexes];
  const copy = [...indexes];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    const tmp = copy[i];
    copy[i] = copy[j];
    copy[j] = tmp;
  }
  return copy.slice(0, count);
}

function readVisualSampleCount() {
  const parsed = parsePositiveInt(visualSampleSizeEl.value);
  return Math.max(5, parsed ?? 5);
}

function setMismatchPreview(mismatch) {
  mismatchMeta.innerHTML = [
    `kind=${htmlEscape(mismatch.kind)}`,
    `directory=${htmlEscape(mismatch.directory)}`,
    `image=${htmlEscape(mismatch.imageName)}`,
    mismatch.url ? `url=${htmlEscape(mismatch.url)}` : "",
  ]
    .filter(Boolean)
    .join(" | ");

  generatedHost.innerHTML = mismatch.generatedSvg;
  referenceHost.innerHTML = mismatch.referenceSvg;
}

function renderVisualSamples(samplesByKind, options) {
  if (!options.enabled) {
    clearVisualSamples("Random visual compare is disabled for this run.");
    return;
  }
  if (!options.compareEnabled) {
    clearVisualSamples("Enable reference comparison to display side-by-side generated and harmonious SVGs.");
    return;
  }
  if (samplesByKind.length === 0) {
    clearVisualSamples("No visual samples were collected in this run.");
    return;
  }

  const body = samplesByKind
    .map((kind) => {
      const sampleCards = kind.samples
        .map((sample) => {
          const status = sample.missingReference
            ? "missing reference"
            : sample.exactMatch
              ? "exact"
              : "mismatch";
          const referenceHostContent = sample.missingReference
            ? '<div class="sample-empty">Reference file missing</div>'
            : sample.referenceSvg;

          return `
            <article class="sample-item">
              <p class="sample-meta mono">image=${htmlEscape(sample.imageName)} | status=${htmlEscape(status)}</p>
              <div class="sample-compare">
                <div>
                  <h4>Generated</h4>
                  <div class="svg-host">${sample.generatedSvg}</div>
                </div>
                <div>
                  <h4>Reference</h4>
                  <div class="svg-host">${referenceHostContent}</div>
                </div>
              </div>
            </article>
          `;
        })
        .join("");

      const emptyNote = kind.samples.length === 0
        ? '<div class="sample-empty">No samples captured for this kind.</div>'
        : "";

      return `
        <section class="sample-kind">
          <h3 class="mono">${htmlEscape(kind.kind)} <span class="small">(${kind.samples.length}/${kind.requested} random samples)</span></h3>
          ${emptyNote}
          <div class="sample-items">${sampleCards}</div>
        </section>
      `;
    })
    .join("");

  visualSamplesHost.innerHTML = `
    <p class="small">Random samples per kind: ${options.samplesPerKind} (or fewer when kind image count is lower).</p>
    ${body}
  `;
}

async function runValidation() {
  if (validationInFlight) return;
  validationInFlight = true;

  const runButton = document.getElementById("run-validation");
  runButton.disabled = true;

  const compareEnabled = document.getElementById("compare-enabled").value === "1";
  const refRoot = document.getElementById("ref-root").value.trim();
  const samplePerKind = parsePositiveInt(new URLSearchParams(window.location.search).get("sample_per_kind"));
  const kindsParam = new URLSearchParams(window.location.search).get("kinds");
  const kindFilter = kindsParam
    ? new Set(
        kindsParam
          .split(",")
          .map((name) => name.trim())
          .filter((name) => name.length > 0),
      )
    : null;
  const sampledRun = samplePerKind != null;
  const visualSamplesEnabled = visualSampleEnabledEl.value === "1";
  const visualSamplesPerKind = readVisualSampleCount();

  try {
    progressEl.textContent = "Starting compatibility generation...";
    summaryHost.innerHTML = "";
    clearMismatchPreview();
    clearVisualSamples("Collecting random visual samples...");

    const arena = compatScratchArena();
    const nameOutPtr = arena.alloc(NAME_STRING_CAPACITY, 1);
    const svgOutPtr = arena.alloc(C_STRING_CAPACITY, 1);

    const kindCount = wasm.lmt_svg_compat_kind_count();
    const rows = [];
    const visualSamplesByKind = [];
    let firstMismatch = null;

    for (let kindIndex = 0; kindIndex < kindCount; kindIndex += 1) {
      const kindName = readCString(wasm.lmt_svg_compat_kind_name(kindIndex));
      if (kindFilter && !kindFilter.has(kindName)) {
        continue;
      }
      const directory = readCString(wasm.lmt_svg_compat_kind_directory(kindIndex));
      const imageCount = wasm.lmt_svg_compat_image_count(kindIndex);
      const imageIndexes = sampleIndexes(imageCount, samplePerKind);
      const visualIndexes = (compareEnabled && visualSamplesEnabled)
        ? new Set(randomSubset(imageIndexes, Math.min(visualSamplesPerKind, imageIndexes.length)))
        : null;
      const visualSamples = [];

      let generated = 0;
      let matches = 0;
      let mismatches = 0;
      let missingReference = 0;

      progressEl.textContent = `Generating kind ${kindIndex + 1}/${kindCount}: ${kindName} (${imageIndexes.length}/${imageCount} images)`;

      for (const imageIndex of imageIndexes) {
        const imageName = readCopyString(
          wasm.lmt_svg_compat_image_name,
          nameOutPtr,
          NAME_STRING_CAPACITY,
          kindIndex,
          imageIndex,
        );
        const svgLen = wasm.lmt_svg_compat_generate(kindIndex, imageIndex, svgOutPtr, C_STRING_CAPACITY);
        const generatedSvg = svgLen > 0 ? readCString(svgOutPtr, C_STRING_CAPACITY) : "";

        if (svgLen > 0) generated += 1;

        if (!compareEnabled) continue;

        const reference = await fetchReferenceSvg(refRoot, directory, imageName);
        let exactMatch = false;
        let missingRef = false;
        if (!reference.ok) {
          missingReference += 1;
          missingRef = true;
        } else if (reference.svg === generatedSvg) {
          matches += 1;
          exactMatch = true;
        } else {
          mismatches += 1;
          if (!firstMismatch) {
            firstMismatch = {
              kind: kindName,
              directory,
              imageName,
              url: reference.url,
              generatedSvg,
              referenceSvg: reference.svg,
            };
          }
        }

        if (visualIndexes && visualIndexes.has(imageIndex)) {
          visualSamples.push({
            imageName,
            generatedSvg,
            referenceSvg: reference.ok ? reference.svg : "",
            exactMatch,
            missingReference: missingRef,
          });
        }
      }

      rows.push({
        kind: kindName,
        directory,
        total: imageCount,
        sampleTotal: imageIndexes.length,
        generated,
        matches,
        mismatches,
        missingReference,
      });

      if (visualSamplesEnabled && compareEnabled) {
        visualSamplesByKind.push({
          kind: kindName,
          requested: Math.min(visualSamplesPerKind, imageIndexes.length),
          samples: visualSamples,
        });
      }

      buildSummaryTable(rows, sampledRun);
      await new Promise((resolve) => setTimeout(resolve, 0));
    }

    if (firstMismatch) {
      setMismatchPreview(firstMismatch);
    }
    renderVisualSamples(visualSamplesByKind, {
      enabled: visualSamplesEnabled,
      compareEnabled,
      samplesPerKind: visualSamplesPerKind,
    });

    const totals = rows.reduce(
      (acc, row) => {
        acc.images += row.sampleTotal;
        acc.fullImages += row.total;
        acc.generated += row.generated;
        acc.matches += row.matches;
        acc.mismatches += row.mismatches;
        acc.missingReference += row.missingReference;
        return acc;
      },
      { images: 0, fullImages: 0, generated: 0, matches: 0, mismatches: 0, missingReference: 0 },
    );

    const progressLines = [
      `Kinds: ${rows.length}`,
      `Images: ${totals.images}`,
      `Generated: ${totals.generated}`,
    ];

    if (sampledRun) {
      progressLines.push(`Sample per kind: ${samplePerKind}`);
      progressLines.push(`Full image count: ${totals.fullImages}`);
    }
    progressLines.push(
      compareEnabled
        ? `Exact matches: ${totals.matches}, mismatches: ${totals.mismatches}, missing ref: ${totals.missingReference}`
        : "Comparison disabled",
    );

    progressEl.textContent = progressLines.join("\n");
    window.__lmtLastValidation = {
      sampledRun,
      samplePerKind,
      visualSamplesEnabled,
      visualSamplesPerKind,
      rows,
      totals,
    };
  } finally {
    validationInFlight = false;
    runButton.disabled = false;
  }
}

async function instantiateWasm() {
  const wasmUrl = "./libmusictheory.wasm";

  if (WebAssembly.instantiateStreaming) {
    try {
      const streaming = await WebAssembly.instantiateStreaming(fetch(wasmUrl), {});
      return streaming.instance;
    } catch (_error) {
      // Fallback below for dev servers without wasm MIME type.
    }
  }

  const response = await fetch(wasmUrl);
  if (!response.ok) {
    throw new Error(`Failed to fetch ${wasmUrl}: ${response.status}`);
  }

  const bytes = await response.arrayBuffer();
  const module = await WebAssembly.instantiate(bytes, {});
  return module.instance;
}

function verifyExports(exportsObj) {
  const missing = REQUIRED_EXPORTS.filter((name) => !(name in exportsObj));
  if (missing.length > 0) {
    throw new Error(`Missing WASM exports: ${missing.join(", ")}`);
  }
}

async function main() {
  try {
    const instance = await instantiateWasm();
    wasm = instance.exports;
    verifyExports(wasm);
    memory = wasm.memory;

    statusEl.textContent = "WASM loaded. Compatibility validation is ready.";
    statusEl.style.color = "#1f6c72";

    document.getElementById("run-validation").addEventListener("click", () => {
      runValidation().catch((err) => {
        statusEl.textContent = `Validation failed: ${err.message}`;
        statusEl.style.color = "#b03620";
      });
    });
  } catch (err) {
    statusEl.textContent = `Failed to initialize: ${err.message}`;
    statusEl.style.color = "#b03620";
  }
}

main();
