import {
  PARITY_REQUIRED_EXPORTS,
  NAME_CAPACITY,
  SVG_CAPACITY,
  createPageRefs,
  scratchArena,
  verifyExports,
  parsePositiveInt,
  parseKindFilter,
  parseQueryScales,
  sampleIndexes,
  cloneBytes,
  makeDiff,
  instantiateWasm,
  fetchReferenceSvg,
  readCString,
  writeUtf8,
  readCopyString,
  parseScaleSpecs,
  defaultScaleInputValue,
  setFailurePreview,
  renderSamples,
  clearFailurePreview,
} from "./render-compare-common.js";

const page = createPageRefs("run-parity");

let wasm = null;
let memory = null;
let runInFlight = false;

function parseSvgLength(raw) {
  if (!raw) return 0;
  const match = String(raw).trim().match(/^([0-9]+(?:\.[0-9]+)?)/);
  if (!match) return 0;
  return Number.parseFloat(match[1]);
}

function parseViewBox(raw) {
  if (!raw) return null;
  const parts = String(raw)
    .trim()
    .split(/[\s,]+/)
    .map((part) => Number.parseFloat(part));
  if (parts.length !== 4 || parts.some((value) => !Number.isFinite(value))) return null;
  return { minX: parts[0], minY: parts[1], width: parts[2], height: parts[3] };
}

function parseSvgBaseSize(svgText) {
  const doc = new DOMParser().parseFromString(svgText, "image/svg+xml");
  if (doc.querySelector("parsererror")) throw new Error("invalid svg");
  const root = doc.documentElement;
  if (!root || root.nodeName.toLowerCase() !== "svg") throw new Error("missing svg root");

  let width = parseSvgLength(root.getAttribute("width"));
  let height = parseSvgLength(root.getAttribute("height"));
  const viewBox = parseViewBox(root.getAttribute("viewBox"));
  if ((!width || !height) && viewBox) {
    width = width || viewBox.width;
    height = height || viewBox.height;
  }
  if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0) {
    throw new Error("svg size unavailable");
  }
  return { width, height };
}

function sameBaseSize(a, b, epsilon = 0.01) {
  return Math.abs(a.width - b.width) <= epsilon && Math.abs(a.height - b.height) <= epsilon;
}

function scaledPixelSize(baseSize, scale) {
  const width = Math.max(1, Math.round((baseSize.width * scale.numerator) / scale.denominator));
  const height = Math.max(1, Math.round((baseSize.height * scale.numerator) / scale.denominator));
  return { width, height };
}

async function loadSvgImage(svgText) {
  const blob = new Blob([svgText], { type: "image/svg+xml;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  try {
    const img = new Image();
    img.decoding = "sync";
    const loaded = new Promise((resolve, reject) => {
      img.onload = resolve;
      img.onerror = () => reject(new Error("failed to decode svg image"));
    });
    img.src = url;
    await loaded;
    return img;
  } finally {
    URL.revokeObjectURL(url);
  }
}

async function rasterizeSvgAtSize(svgText, width, height) {
  const img = await loadSvgImage(svgText);
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d", { alpha: true, willReadFrequently: true });
  ctx.clearRect(0, 0, width, height);
  ctx.drawImage(img, 0, 0, width, height);
  return new Uint8ClampedArray(ctx.getImageData(0, 0, width, height).data);
}

async function rasterizeSvgScaled(svgText, scale, expectedBaseSize = null) {
  const baseSize = parseSvgBaseSize(svgText);
  if (expectedBaseSize && !sameBaseSize(baseSize, expectedBaseSize)) {
    throw new Error(`svg size mismatch candidate=${expectedBaseSize.width}x${expectedBaseSize.height} reference=${baseSize.width}x${baseSize.height}`);
  }
  const { width, height } = scaledPixelSize(baseSize, scale);
  const pixels = await rasterizeSvgAtSize(svgText, width, height);
  return { baseSize, width, height, pixels };
}

async function runScaledRenderParity() {
  if (runInFlight) return;
  runInFlight = true;
  page.runButton.disabled = true;

  try {
    const refRoot = page.refRootInput.value.trim();
    const samplePerKind = Math.max(5, parsePositiveInt(page.visualSampleSizeInput.value, 5));
    const kindFilter = parseKindFilter();
    const scales = parseScaleSpecs(parseQueryScales() || page.scaleListInput.value);

    const arena = scratchArena(wasm);
    const namePtr = arena.alloc(NAME_CAPACITY, 1);
    const svgPtr = arena.alloc(SVG_CAPACITY, 1);

    const rows = [];
    const sampleGroups = [];
    let firstFailure = null;
    let supportedRows = 0;
    let compared = 0;
    let passing = 0;
    let nativeRgbaRows = 0;
    let generatedSvgRows = 0;

    const threshold = 0.0001;
    const kindCount = wasm.lmt_svg_compat_kind_count();
    for (const scale of scales) {
      for (let kindIndex = 0; kindIndex < kindCount; kindIndex += 1) {
        const kindName = readCString(memory, wasm.lmt_svg_compat_kind_name(kindIndex));
        if (kindFilter && !kindFilter.has(kindName)) continue;
        const directory = readCString(memory, wasm.lmt_svg_compat_kind_directory(kindIndex));
        const total = wasm.lmt_svg_compat_image_count(kindIndex);
        const nativeSupported = wasm.lmt_bitmap_compat_kind_supported(kindIndex) === 1;
        const candidateSource = nativeSupported ? "native-rgba" : "generated-svg";
        supportedRows += 1;
        if (nativeSupported) nativeRgbaRows += 1;
        else generatedSvgRows += 1;

        const indexes = sampleIndexes(total, samplePerKind);
        let width = 0;
        let height = 0;
        let rgbaBytes = 0;
        let candidatePtr = 0;
        let referencePtr = 0;
        if (nativeSupported) {
          width = wasm.lmt_bitmap_compat_target_width_scaled(kindIndex, indexes[0] ?? 0, scale.numerator, scale.denominator);
          height = wasm.lmt_bitmap_compat_target_height_scaled(kindIndex, indexes[0] ?? 0, scale.numerator, scale.denominator);
          rgbaBytes = wasm.lmt_bitmap_compat_required_rgba_bytes_scaled(kindIndex, indexes[0] ?? 0, scale.numerator, scale.denominator);
          if (!width || !height || !rgbaBytes) throw new Error(`scaled render target unavailable for native-rgba kind ${kindName} at ${scale.label}`);
          candidatePtr = arena.alloc(rgbaBytes, 4);
          referencePtr = arena.alloc(rgbaBytes, 4);
        }

        const samples = [];
        let kindCompared = 0;
        let kindPassing = 0;
        let kindFailures = 0;
        let kindMaxDrift = 0;
        let kindChangedPixels = 0;

        page.progressEl.textContent = `Generating scaled render parity for ${kindName} @ ${scale.percentLabel} (${indexes.length}/${total}) [${candidateSource}]`;
        for (const imageIndex of indexes) {
          const imageName = readCopyString(memory, wasm.lmt_svg_compat_image_name, namePtr, NAME_CAPACITY, kindIndex, imageIndex);
          let candidateBytes = null;
          let referenceBytes = null;
          let referenceUrl = "";

          if (nativeSupported) {
            const candidateWritten = wasm.lmt_bitmap_compat_render_candidate_rgba_scaled(kindIndex, imageIndex, scale.numerator, scale.denominator, candidatePtr, rgbaBytes);
            if (candidateWritten !== rgbaBytes) {
              kindFailures += 1;
              if (!firstFailure) {
                firstFailure = { meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | error=candidate render failed`, width, height, candidate: new Uint8ClampedArray(rgbaBytes), reference: new Uint8ClampedArray(rgbaBytes), diff: new Uint8ClampedArray(rgbaBytes) };
              }
              continue;
            }

            const referenceSvg = await fetchReferenceSvg(refRoot, directory, imageName);
            referenceUrl = referenceSvg.url;
            if (!referenceSvg.ok) {
              kindFailures += 1;
              if (!firstFailure) {
                firstFailure = { meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | error=missing reference | url=${referenceSvg.url}`, width, height, candidate: cloneBytes(memory, candidatePtr, rgbaBytes), reference: new Uint8ClampedArray(rgbaBytes), diff: new Uint8ClampedArray(rgbaBytes) };
              }
              continue;
            }

            const svgLen = writeUtf8(memory, svgPtr, referenceSvg.svg);
            const referenceWritten = wasm.lmt_bitmap_compat_render_reference_svg_rgba_scaled(kindIndex, scale.numerator, scale.denominator, svgPtr, svgLen, referencePtr, rgbaBytes);
            if (referenceWritten !== rgbaBytes) {
              kindFailures += 1;
              if (!firstFailure) {
                firstFailure = { meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | error=reference raster failed | url=${referenceSvg.url}`, width, height, candidate: cloneBytes(memory, candidatePtr, rgbaBytes), reference: new Uint8ClampedArray(rgbaBytes), diff: new Uint8ClampedArray(rgbaBytes) };
              }
              continue;
            }

            candidateBytes = cloneBytes(memory, candidatePtr, rgbaBytes);
            referenceBytes = cloneBytes(memory, referencePtr, rgbaBytes);
          } else {
            const candidateSvg = readCopyString(memory, wasm.lmt_svg_compat_generate, svgPtr, SVG_CAPACITY, kindIndex, imageIndex);
            if (!candidateSvg) {
              kindFailures += 1;
              if (!firstFailure) {
                firstFailure = { meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | error=candidate svg generation failed`, width: 1, height: 1, candidate: new Uint8ClampedArray(4), reference: new Uint8ClampedArray(4), diff: new Uint8ClampedArray(4) };
              }
              continue;
            }

            const referenceSvg = await fetchReferenceSvg(refRoot, directory, imageName);
            referenceUrl = referenceSvg.url;
            if (!referenceSvg.ok) {
              kindFailures += 1;
              if (!firstFailure) {
                firstFailure = { meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | error=missing reference | url=${referenceSvg.url}`, width: 1, height: 1, candidate: new Uint8ClampedArray(4), reference: new Uint8ClampedArray(4), diff: new Uint8ClampedArray(4) };
              }
              continue;
            }

            try {
              const candidateRaster = await rasterizeSvgScaled(candidateSvg, scale);
              const referenceRaster = await rasterizeSvgScaled(referenceSvg.svg, scale, candidateRaster.baseSize);
              width = candidateRaster.width;
              height = candidateRaster.height;
              candidateBytes = candidateRaster.pixels;
              referenceBytes = referenceRaster.pixels;
            } catch (err) {
              kindFailures += 1;
              if (!firstFailure) {
                firstFailure = { meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | error=${err.message} | url=${referenceSvg.url}`, width: Math.max(1, width), height: Math.max(1, height), candidate: new Uint8ClampedArray(Math.max(4, (width * height * 4) || 4)), reference: new Uint8ClampedArray(Math.max(4, (width * height * 4) || 4)), diff: new Uint8ClampedArray(Math.max(4, (width * height * 4) || 4)) };
              }
              continue;
            }
          }

          const diff = makeDiff(candidateBytes, referenceBytes, width, height);
          kindCompared += 1;
          compared += 1;
          kindMaxDrift = Math.max(kindMaxDrift, diff.drift);
          kindChangedPixels += diff.changedPixels;
          if (diff.drift <= threshold) {
            passing += 1;
            kindPassing += 1;
          } else {
            kindFailures += 1;
            if (!firstFailure) {
              firstFailure = {
                meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | drift=${diff.drift} | changed=${diff.changedPixels} | url=${referenceUrl}`,
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
            scaleKey: scale.key,
            scalePercent: scale.percentLabel,
            candidateSource,
            drift: diff.drift,
            changedPixels: diff.changedPixels,
            candidate: candidateBytes,
            reference: referenceBytes,
            diff: diff.pixels,
          });
        }

        rows.push({ kind: kindName, directory, total, scaleKey: scale.key, scaleLabel: scale.label, scalePercent: scale.percentLabel, candidateSource, supported: true, compared: kindCompared, passing: kindPassing, failures: kindFailures, drift: kindMaxDrift, changedPixels: kindChangedPixels });
        sampleGroups.push({ key: `${kindName}@${scale.key}`, kind: kindName, scaleKey: scale.key, scalePercent: scale.percentLabel, candidateSource, samples });
      }
    }

    page.summaryHost.innerHTML = `
      <table>
        <thead>
          <tr><th>Kind</th><th>Scale</th><th>Candidate Source</th><th>Directory</th><th>Images</th><th>Compared</th><th>Passing</th><th>Failures</th></tr>
        </thead>
        <tbody>
          ${rows.map((row) => `
            <tr>
              <td class="mono">${row.kind}</td>
              <td class="mono">${row.scalePercent}</td>
              <td class="mono">${row.candidateSource}</td>
              <td class="mono">${row.directory}</td>
              <td>${row.total}</td>
              <td>${row.compared}</td>
              <td class="${row.failures === 0 ? "good" : ""}">${row.passing}</td>
              <td class="${row.failures > 0 ? "bad" : ""}">${row.failures}</td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    `;

    if (firstFailure) setFailurePreview(page, firstFailure);
    else clearFailurePreview(page);
    renderSamples(page, sampleGroups, "No scaled render samples were collected.");

    const requestedKinds = Array.from(new Set(rows.map((row) => row.kind)));
    const requestedScales = scales.map((scale) => scale.key);
    page.progressEl.textContent = [
      `Kinds: ${rows.length}`,
      `Scales: ${scales.map((scale) => `${scale.label} (${scale.percentLabel})`).join(", ")}`,
      `Supported rows: ${supportedRows}`,
      `Native RGBA rows: ${nativeRgbaRows}`,
      `Generated SVG rows: ${generatedSvgRows}`,
      `Compared samples: ${compared}`,
      `Passing samples: ${passing}`,
      `Failures: ${compared - passing}`,
      `Drift threshold: 0.0001`,
    ].join("\n");
    window.__lmtLastScaledRenderParity = {
      rows,
      requestedKinds,
      requestedScales,
      supportedRows,
      failures: compared - passing,
      compared,
      passing,
      nativeRgbaRows,
      generatedSvgRows,
      threshold,
    };
    page.statusEl.textContent = "Scaled render parity run completed.";
    page.statusEl.style.color = "#1f6c72";
  } finally {
    runInFlight = false;
    page.runButton.disabled = false;
  }
}

async function main() {
  try {
    const instance = await instantiateWasm();
    wasm = instance.exports;
    verifyExports(wasm, PARITY_REQUIRED_EXPORTS);
    memory = wasm.memory;
    page.scaleListInput.value = defaultScaleInputValue(wasm);
    page.statusEl.textContent = "WASM loaded. Scaled render parity validation is ready.";
    page.statusEl.style.color = "#1f6c72";
    page.runButton.addEventListener("click", () => {
      runScaledRenderParity().catch((err) => {
        page.statusEl.textContent = `Scaled render parity failed: ${err.message}`;
        page.statusEl.style.color = "#b03620";
      });
    });
  } catch (err) {
    page.statusEl.textContent = `Failed to initialize: ${err.message}`;
    page.statusEl.style.color = "#b03620";
  }
}

main();
