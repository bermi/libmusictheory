import {
  BASE_REQUIRED_EXPORTS,
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

const page = createPageRefs("run-proof");

let wasm = null;
let memory = null;
let runInFlight = false;

function yieldToBrowser() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

async function runNativeRgbaProof() {
  if (runInFlight) return;
  runInFlight = true;
  page.runButton.disabled = true;

  try {
    const refRoot = page.refRootInput.value.trim();
    const samplePerKind = Math.max(5, parsePositiveInt(page.visualSampleSizeInput.value, 5));
    const kindFilter = parseKindFilter();
    const scales = parseScaleSpecs(parseQueryScales() || page.scaleListInput.value);

    const rows = [];
    const sampleGroups = [];
    let firstFailure = null;
    let supportedRows = 0;
    let unsupportedRows = 0;
    let compared = 0;
    let passing = 0;
    const backendCounts = Object.create(null);

    const threshold = 0.0001;
    const kindCount = wasm.lmt_svg_compat_kind_count();
    for (const scale of scales) {
      for (let kindIndex = 0; kindIndex < kindCount; kindIndex += 1) {
        const kindName = readCString(memory, wasm.lmt_svg_compat_kind_name(kindIndex));
        if (kindFilter && !kindFilter.has(kindName)) continue;
        const directory = readCString(memory, wasm.lmt_svg_compat_kind_directory(kindIndex));
        const total = wasm.lmt_svg_compat_image_count(kindIndex);
        const candidateSource = "native-rgba";
        const nativeSupported = wasm.lmt_bitmap_compat_kind_supported(kindIndex) === 1;
        const candidateBackend = nativeSupported
          ? readCString(memory, wasm.lmt_bitmap_compat_candidate_backend_name(kindIndex))
          : "unsupported";

        if (!nativeSupported) {
          unsupportedRows += 1;
          rows.push({
            kind: kindName,
            directory,
            total,
            scaleKey: scale.key,
            scaleLabel: scale.label,
            scalePercent: scale.percentLabel,
            candidateSource,
            candidateBackend,
            supported: false,
            compared: 0,
            passing: 0,
            failures: 0,
            drift: 0,
            unsupported: 1,
          });
          if (!firstFailure) {
            firstFailure = {
              meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | error=unsupported`,
              width: 1,
              height: 1,
              candidate: new Uint8ClampedArray(4),
              reference: new Uint8ClampedArray(4),
              diff: new Uint8ClampedArray(4),
            };
          }
          continue;
        }
        if (!candidateBackend) throw new Error(`missing native candidate backend for ${kindName}`);
        backendCounts[candidateBackend] = (backendCounts[candidateBackend] || 0) + 1;

        supportedRows += 1;
        const arena = scratchArena(wasm);
        const namePtr = arena.alloc(NAME_CAPACITY, 1);
        const svgPtr = arena.alloc(SVG_CAPACITY, 1);
        const indexes = sampleIndexes(total, samplePerKind);
        const width = wasm.lmt_bitmap_compat_target_width_scaled(kindIndex, indexes[0] ?? 0, scale.numerator, scale.denominator);
        const height = wasm.lmt_bitmap_compat_target_height_scaled(kindIndex, indexes[0] ?? 0, scale.numerator, scale.denominator);
        const rgbaBytes = wasm.lmt_bitmap_compat_required_rgba_bytes_scaled(kindIndex, indexes[0] ?? 0, scale.numerator, scale.denominator);
        if (!width || !height || !rgbaBytes) throw new Error(`native RGBA target unavailable for ${kindName} at ${scale.label}`);

        const rgbaPtr = arena.alloc(rgbaBytes, 4);
        const samples = [];
        let kindCompared = 0;
        let kindPassing = 0;
        let kindFailures = 0;
        let kindMaxDrift = 0;

        page.progressEl.textContent = `Generating native RGBA proof for ${kindName} @ ${scale.percentLabel} (${indexes.length}/${total}) [${candidateSource} | ${candidateBackend}]`;
        for (const imageIndex of indexes) {
          const imageName = readCopyString(memory, wasm.lmt_svg_compat_image_name, namePtr, NAME_CAPACITY, kindIndex, imageIndex);
          const candidateWritten = wasm.lmt_bitmap_compat_render_candidate_rgba_scaled(kindIndex, imageIndex, scale.numerator, scale.denominator, rgbaPtr, rgbaBytes);
          if (candidateWritten !== rgbaBytes) {
            kindFailures += 1;
            if (!firstFailure) {
              firstFailure = {
                meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | error=candidate render failed`,
                width,
                height,
                candidate: new Uint8ClampedArray(rgbaBytes),
                reference: new Uint8ClampedArray(rgbaBytes),
                diff: new Uint8ClampedArray(rgbaBytes),
              };
            }
            await yieldToBrowser();
            continue;
          }

          const referenceSvg = await fetchReferenceSvg(refRoot, directory, imageName);
          if (!referenceSvg.ok) {
            kindFailures += 1;
            if (!firstFailure) {
              firstFailure = {
                meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | error=missing reference | url=${referenceSvg.url}`,
                width,
                height,
                candidate: cloneBytes(memory, rgbaPtr, rgbaBytes),
                reference: new Uint8ClampedArray(rgbaBytes),
                diff: new Uint8ClampedArray(rgbaBytes),
              };
            }
            await yieldToBrowser();
            continue;
          }

          const candidateBytes = cloneBytes(memory, rgbaPtr, rgbaBytes);
          const svgLen = writeUtf8(memory, svgPtr, referenceSvg.svg);
          const referenceWritten = wasm.lmt_bitmap_compat_render_reference_svg_rgba_scaled(kindIndex, scale.numerator, scale.denominator, svgPtr, svgLen, rgbaPtr, rgbaBytes);
          if (referenceWritten !== rgbaBytes) {
            kindFailures += 1;
            if (!firstFailure) {
              firstFailure = {
                meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | error=reference raster failed | url=${referenceSvg.url}`,
                width,
                height,
                candidate: candidateBytes,
                reference: new Uint8ClampedArray(rgbaBytes),
                diff: new Uint8ClampedArray(rgbaBytes),
              };
            }
            await yieldToBrowser();
            continue;
          }

          const referenceBytes = cloneBytes(memory, rgbaPtr, rgbaBytes);
          const diff = makeDiff(candidateBytes, referenceBytes, width, height);
          kindCompared += 1;
          compared += 1;
          kindMaxDrift = Math.max(kindMaxDrift, diff.drift);
          if (diff.drift <= threshold) {
            passing += 1;
            kindPassing += 1;
          } else {
            kindFailures += 1;
            if (!firstFailure) {
              firstFailure = {
                meta: `kind=${kindName} | source=${candidateSource} | scale=${scale.label} | image=${imageName} | drift=${diff.drift} | changed=${diff.changedPixels} | url=${referenceSvg.url}`,
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
            candidateBackend,
            drift: diff.drift,
            changedPixels: diff.changedPixels,
            candidate: candidateBytes,
            reference: referenceBytes,
            diff: diff.pixels,
          });
          await yieldToBrowser();
        }

        rows.push({
          kind: kindName,
          directory,
          total,
          scaleKey: scale.key,
          scaleLabel: scale.label,
          scalePercent: scale.percentLabel,
          candidateSource,
          candidateBackend,
          supported: true,
          compared: kindCompared,
          passing: kindPassing,
          failures: kindFailures,
          drift: kindMaxDrift,
          unsupported: 0,
        });
        sampleGroups.push({ key: `${kindName}@${scale.key}`, kind: kindName, scaleKey: scale.key, scalePercent: scale.percentLabel, candidateSource, candidateBackend, samples });
      }
    }

    page.summaryHost.innerHTML = `
      <table>
        <thead>
          <tr><th>Kind</th><th>Scale</th><th>Candidate Source</th><th>Candidate Backend</th><th>Directory</th><th>Images</th><th>Support</th><th>Compared</th><th>Passing</th><th>Failures</th><th>Unsupported</th></tr>
        </thead>
        <tbody>
          ${rows.map((row) => `
            <tr>
              <td class="mono">${row.kind}</td>
              <td class="mono">${row.scalePercent}</td>
              <td class="mono">${row.candidateSource}</td>
              <td class="mono">${row.candidateBackend}</td>
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

    if (firstFailure) setFailurePreview(page, firstFailure);
    else clearFailurePreview(page);
    renderSamples(page, sampleGroups, "No native RGBA samples were collected.");

    page.progressEl.textContent = [
      `Kinds: ${rows.length}`,
      `Scales: ${scales.map((scale) => `${scale.label} (${scale.percentLabel})`).join(", ")}`,
      `Supported rows: ${supportedRows}`,
      `Unsupported rows: ${unsupportedRows}`,
      `Backend rows: ${Object.entries(backendCounts).map(([key, value]) => `${key}=${value}`).join(", ") || "none"}`,
      `Compared samples: ${compared}`,
      `Passing samples: ${passing}`,
      `Failures: ${compared - passing}`,
      `Drift threshold: 0.0001`,
    ].join("\n");
    window.__lmtLastNativeRgbaProof = {
      rows,
      requestedKinds: rows.map((row) => row.kind),
      requestedScales: scales.map((scale) => scale.key),
      supportedRows,
      unsupportedRows,
      backendCounts,
      failures: compared - passing,
      compared,
      passing,
      threshold,
    };
    page.statusEl.textContent = "Native RGBA proof run completed.";
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
    verifyExports(wasm, BASE_REQUIRED_EXPORTS);
    memory = wasm.memory;
    page.scaleListInput.value = defaultScaleInputValue(wasm);
    page.statusEl.textContent = "WASM loaded. Native RGBA proof validation is ready.";
    page.statusEl.style.color = "#1f6c72";
    page.runButton.addEventListener("click", () => {
      runNativeRgbaProof().catch((err) => {
        page.statusEl.textContent = `Native RGBA proof failed: ${err.message}`;
        page.statusEl.style.color = "#b03620";
      });
    });
  } catch (err) {
    page.statusEl.textContent = `Failed to initialize: ${err.message}`;
    page.statusEl.style.color = "#b03620";
  }
}

main();
