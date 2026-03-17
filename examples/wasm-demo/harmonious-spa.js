import { HARMONIOUS_SPA_MANIFEST } from "./harmonious-spa-manifest.js";

const BUNDLE_BASE_URL = new URL("./", import.meta.url);
const PLACEHOLDER_IMAGE = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==";
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
const NAME_CAPACITY = 2048;
const SVG_CAPACITY = 4 * 1024 * 1024;
const textDecoder = new TextDecoder();
const COMPAT_DIR_PREFIXES = [
  "vert-text-black/",
  "even/",
  "scale/",
  "opc/",
  "oc/",
  "optc/",
  "eadgbe/",
  "center-square-text/",
  "wide-chord/",
  "chord-clipped/",
  "grand-chord/",
  "majmin/",
  "chord/",
  "vert-text-b2t-black/",
];

const originalJqueryGet = window.jQuery?.get?.bind(window.jQuery);
const originalElementSetAttribute = Element.prototype.setAttribute;
const imageSrcDescriptor = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, "src");
const pages = HARMONIOUS_SPA_MANIFEST.pages || [];
const pageByRoute = new Map(pages.map((page, index) => [page.route, { ...page, index }]));
const reverseIndex = new Map(Object.entries(HARMONIOUS_SPA_MANIFEST.reverseIndex || {}));
const randomRoutes = HARMONIOUS_SPA_MANIFEST.randomRoutes || [];
const autoRouteMap = HARMONIOUS_SPA_MANIFEST.autoRouteMap || {};

const state = {
  wasm: null,
  memory: null,
  compatIndex: new Map(),
  compatDataUrlCache: new Map(),
  requestLog: [],
  compatReplacements: 0,
  ready: false,
  routeLoads: 0,
  lastRoute: null,
  lastFragmentKind: null,
  observer: null,
};

window.__lmtHarmoniousSpa = {
  ready: false,
  routeLoads: 0,
  compatReplacements: 0,
  lastRoute: null,
  lastFragmentKind: null,
  requestLog: [],
  manifestPages: pages.length,
  indexedCompatRefs: reverseIndex.size,
  bootError: null,
};

class ScratchArena {
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

function syncDebugState() {
  window.__lmtHarmoniousSpa.ready = state.ready;
  window.__lmtHarmoniousSpa.routeLoads = state.routeLoads;
  window.__lmtHarmoniousSpa.compatReplacements = state.compatReplacements;
  window.__lmtHarmoniousSpa.lastRoute = state.lastRoute;
  window.__lmtHarmoniousSpa.lastFragmentKind = state.lastFragmentKind;
  window.__lmtHarmoniousSpa.requestLog = state.requestLog.slice(-50);
}

function setShellStatus(message, tone = "ready") {
  const shell = document.getElementById("spa-shell-loading");
  if (!shell) return;
  shell.textContent = message;
  shell.classList.toggle("error", tone === "error");
}

function bytes() {
  return new Uint8Array(state.memory.buffer);
}

function readCString(ptr, maxBytes = null) {
  const raw = bytes();
  const limit = maxBytes == null ? raw.length : Math.min(raw.length, ptr + maxBytes);
  let end = ptr;
  while (end < limit && raw[end] !== 0) end += 1;
  return textDecoder.decode(raw.subarray(ptr, end));
}

function scratchArena() {
  const ptr = state.wasm.lmt_wasm_scratch_ptr();
  const size = state.wasm.lmt_wasm_scratch_size();
  if (!ptr || !size) throw new Error("missing wasm scratch arena");
  return new ScratchArena(ptr, size);
}

function readCopyString(fn, outPtr, outCap, ...args) {
  const len = fn(...args, outPtr, outCap);
  if (!len) return "";
  return readCString(outPtr, outCap);
}

function verifyExports(exportsObj) {
  const missing = REQUIRED_EXPORTS.filter((name) => !(name in exportsObj));
  if (missing.length > 0) {
    throw new Error(`Missing WASM exports: ${missing.join(", ")}`);
  }
}

async function instantiateWasm() {
  const wasmUrl = new URL("./libmusictheory.wasm", BUNDLE_BASE_URL);
  if (WebAssembly.instantiateStreaming) {
    try {
      const streaming = await WebAssembly.instantiateStreaming(fetch(wasmUrl), {});
      return streaming.instance;
    } catch (_err) {
      // Fall back below.
    }
  }
  const response = await fetch(wasmUrl);
  if (!response.ok) throw new Error(`Failed to fetch ${wasmUrl}: ${response.status}`);
  const buffer = await response.arrayBuffer();
  const module = await WebAssembly.instantiate(buffer, {});
  return module.instance;
}

function htmlEscape(text) {
  return String(text)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function normalizePageRoute(route) {
  if (!route) return "/index.html";
  let normalized = String(route).trim();
  if (!normalized) return "/index.html";
  if (/^https?:\/\//i.test(normalized)) {
    normalized = new URL(normalized).pathname;
  }
  if (!normalized.startsWith("/")) normalized = `/${normalized}`;
  if (normalized === "/") return "/index.html";
  return normalized.replace(/\/+/g, "/");
}

function isCompatPath(pathname) {
  return COMPAT_DIR_PREFIXES.some((prefix) => pathname.startsWith(prefix));
}

function normalizeCompatPath(rawValue, baseHref = window.location.href) {
  if (!rawValue) return null;
  const direct = String(rawValue).replace(/^\/+/, "");
  if (state.compatIndex.has(direct)) return direct;
  if (direct.startsWith("tmp/harmoniousapp.net/")) {
    const stripped = direct.slice("tmp/harmoniousapp.net/".length);
    if (state.compatIndex.has(stripped)) return stripped;
  }
  let resolved = null;
  try {
    resolved = new URL(String(rawValue), baseHref);
  } catch (_err) {
    return null;
  }
  let normalized = resolved.pathname.replace(/^\/+/, "");
  if (normalized.startsWith("tmp/harmoniousapp.net/")) {
    normalized = normalized.slice("tmp/harmoniousapp.net/".length);
  }
  if (!normalized.endsWith(".svg") || !isCompatPath(normalized)) return null;
  return state.compatIndex.has(normalized) ? normalized : null;
}

function buildCompatIndex() {
  const arena = scratchArena();
  const imageNamePtr = arena.alloc(NAME_CAPACITY, 1);
  const kindCount = state.wasm.lmt_svg_compat_kind_count();

  for (let kindIndex = 0; kindIndex < kindCount; kindIndex += 1) {
    const kindName = readCString(state.wasm.lmt_svg_compat_kind_name(kindIndex));
    const directory = readCString(state.wasm.lmt_svg_compat_kind_directory(kindIndex));
    const imageCount = state.wasm.lmt_svg_compat_image_count(kindIndex);
    for (let imageIndex = 0; imageIndex < imageCount; imageIndex += 1) {
      const imageName = readCopyString(state.wasm.lmt_svg_compat_image_name, imageNamePtr, NAME_CAPACITY, kindIndex, imageIndex);
      state.compatIndex.set(`${directory}/${imageName}`, { kindIndex, imageIndex, kindName, directory, imageName });
    }
  }
}

function compatSvgDataUrl(normalizedPath) {
  const cached = state.compatDataUrlCache.get(normalizedPath);
  if (cached) return cached;
  const meta = state.compatIndex.get(normalizedPath);
  if (!meta) throw new Error(`unknown compat image ${normalizedPath}`);
  const arena = scratchArena();
  const svgPtr = arena.alloc(SVG_CAPACITY, 1);
  const len = state.wasm.lmt_svg_compat_generate(meta.kindIndex, meta.imageIndex, svgPtr, SVG_CAPACITY);
  if (!len) throw new Error(`compat generation failed for ${normalizedPath}`);
  const svgText = readCString(svgPtr, SVG_CAPACITY);
  const dataUrl = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svgText)}`;
  state.compatDataUrlCache.set(normalizedPath, dataUrl);
  return dataUrl;
}

function setCompatDataset(img, normalizedPath) {
  originalElementSetAttribute.call(img, "data-lmt-compat-src", normalizedPath);
  originalElementSetAttribute.call(img, "data-lmt-image-source", "wasm-compat");
}

function applyCompatImage(img, rawValue) {
  const normalizedPath = normalizeCompatPath(rawValue, img.baseURI || window.location.href);
  if (!normalizedPath) return false;
  if (
    img.getAttribute("data-lmt-compat-src") === normalizedPath
    && img.getAttribute("data-lmt-image-source") === "wasm-compat"
    && String(img.getAttribute("src") || "").startsWith("data:image/svg+xml")
  ) {
    return true;
  }
  const dataUrl = compatSvgDataUrl(normalizedPath);
  setCompatDataset(img, normalizedPath);
  if (imageSrcDescriptor?.set) {
    imageSrcDescriptor.set.call(img, dataUrl);
  } else {
    originalElementSetAttribute.call(img, "src", dataUrl);
  }
  state.compatReplacements += 1;
  syncDebugState();
  return true;
}

function processCompatImageNode(img) {
  const rawValue = img.getAttribute("data-lmt-compat-src") || img.getAttribute("src");
  if (!rawValue) return;
  applyCompatImage(img, rawValue);
}

function refreshCompatImages(root = document) {
  if (!root) return;
  if (root instanceof HTMLImageElement) {
    processCompatImageNode(root);
    return;
  }
  if (root.querySelectorAll) {
    root.querySelectorAll("img").forEach(processCompatImageNode);
  }
}

function installCompatImageInterceptors() {
  if (state.observer) return;

  Element.prototype.setAttribute = function(name, value) {
    if (this instanceof HTMLImageElement && String(name).toLowerCase() === "src" && applyCompatImage(this, value)) {
      return;
    }
    return originalElementSetAttribute.call(this, name, value);
  };

  if (imageSrcDescriptor?.set && imageSrcDescriptor?.get) {
    Object.defineProperty(HTMLImageElement.prototype, "src", {
      configurable: true,
      enumerable: imageSrcDescriptor.enumerable,
      get() {
        return imageSrcDescriptor.get.call(this);
      },
      set(value) {
        if (applyCompatImage(this, value)) return;
        imageSrcDescriptor.set.call(this, value);
      },
    });
  }

  state.observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      if (mutation.type === "childList") {
        mutation.addedNodes.forEach((node) => {
          if (node instanceof Element) refreshCompatImages(node);
        });
      } else if (mutation.type === "attributes" && mutation.target instanceof HTMLImageElement) {
        processCompatImageNode(mutation.target);
      }
    }
  });
  state.observer.observe(document.documentElement, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ["src", "data-lmt-compat-src"],
  });
}

function logRequest(kind, route, note = "") {
  state.requestLog.push({ kind, route, note, at: Date.now() });
  if (state.requestLog.length > 200) state.requestLog.shift();
  syncDebugState();
}

function canonicalPageFetchRoute(route) {
  const normalized = normalizePageRoute(route);
  if (normalized === "/keyboard" || normalized === "/keyboard/") return "/keyboard/index.html";
  if (normalized === "/eadgbe-frets" || normalized === "/eadgbe-frets/") return "/eadgbe-frets/index.html";
  if (normalized.startsWith("/keyboard/") && !normalized.endsWith(".html")) return `${normalized}.html`;
  if (normalized.startsWith("/eadgbe-frets/") && !normalized.endsWith(".html")) return `${normalized}.html`;
  if (normalized === "/index.html") return normalized;
  return normalized;
}

function routeToBundleContentUrl(route) {
  const normalized = canonicalPageFetchRoute(route);
  return new URL(`./spa-content${normalized}`, BUNDLE_BASE_URL);
}

function normalizeSiteAttribute(rawHref) {
  if (!rawHref) return rawHref;
  if (rawHref.startsWith("auto:")) {
    const token = rawHref.slice("auto:".length);
    return autoRouteMap[token] || "/index.html";
  }
  return String(rawHref)
    .replace(/^https?:\/\/harmoniousapp\.net/i, "")
    .replace(/(^|\/)keyboard\/index\.html(?=([?#].*)?$)/i, "$1keyboard/")
    .replace(/(^|\/)eadgbe-frets\/index\.html(?=([?#].*)?$)/i, "$1eadgbe-frets/")
    .replace(/(^|\/)(keyboard\/[^?#]+)\.html(?=([?#].*)?$)/i, "$1$2")
    .replace(/(^|\/)(eadgbe-frets\/[^?#]+)\.html(?=([?#].*)?$)/i, "$1$2");
}

function rewriteFetchedHtml(htmlText, route) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(window.HarmoniousConfig.ServerStringReplacer(String(htmlText)), "text/html");
  rewriteDocument(doc, route);
  return `<!doctype html>\n${doc.documentElement.outerHTML}`;
}

function rewriteDocument(doc, route) {
  doc.querySelectorAll("a[href]").forEach((anchor) => {
    anchor.setAttribute("href", normalizeSiteAttribute(anchor.getAttribute("href")));
  });

  doc.querySelectorAll("img[src]").forEach((img) => {
    const rawSrc = normalizeSiteAttribute(img.getAttribute("src"));
    const compatPath = normalizeCompatPath(rawSrc, new URL(route, window.location.origin).toString());
    if (compatPath) {
      originalElementSetAttribute.call(img, "data-lmt-compat-src", compatPath);
      img.setAttribute("src", PLACEHOLDER_IMAGE);
    } else {
      img.setAttribute("src", rawSrc);
    }
  });
}

function parsePageDocument(htmlText, route) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(window.HarmoniousConfig.ServerStringReplacer(String(htmlText)), "text/html");
  rewriteDocument(doc, route);
  return doc;
}

function collectInlineBodyScripts(doc) {
  const scripts = [];
  doc.body.querySelectorAll("script").forEach((script, index) => {
    if (script.src) return;
    const text = (script.textContent || "").trim();
    if (!text) return;
    scripts.push({
      text,
      label: `route-inline-${index + 1}`,
    });
  });
  doc.body.querySelectorAll("script").forEach((script) => script.remove());
  return scripts;
}

function executeInlineScripts(scripts, route) {
  for (const script of scripts) {
    try {
      const node = document.createElement("script");
      node.textContent = `${script.text}\n//# sourceURL=harmonious-spa:${route}:${script.label}.js`;
      document.body.appendChild(node);
      node.remove();
    } catch (err) {
      throw new Error(
        `inline script failed for ${route} (${script.label}): ${err?.stack || err?.message || err}`,
      );
    }
  }
}

async function renderPageRoute(route) {
  const normalizedRoute = canonicalPageFetchRoute(route);
  const response = await fetch(routeToBundleContentUrl(normalizedRoute));
  if (!response.ok) {
    throw new Error(`Failed to fetch local page ${normalizedRoute}: ${response.status}`);
  }

  const doc = parsePageDocument(await response.text(), normalizedRoute);
  const title = doc.querySelector("title")?.textContent?.trim() || "Harmonious";
  const bodyClass = doc.body.getAttribute("class") || "";
  const inlineScripts = collectInlineBodyScripts(doc);

  window.HarmoniousClient.tryClearTimeouts();
  window.scrollTo(0, 0);
  document.body.className = bodyClass;
  document.body.innerHTML = doc.body.innerHTML;
  document.title = title.replace("&amp;", "&");

  refreshCompatImages(document);
  executeInlineScripts(inlineScripts, normalizedRoute);
  refreshCompatImages(document);

  state.lastRoute = normalizedRoute;
  state.lastFragmentKind = null;
  state.routeLoads += 1;
  syncDebugState();
  window.dispatchEvent(new CustomEvent("lmt-harmonious-spa-route-loaded", { detail: { route: normalizedRoute } }));
}

function routeTitleFallback(route) {
  const stem = route.split("/").pop() || route;
  return stem.replace(/\.html$/i, "").replace(/[-_]/g, " ");
}

function buildSearchEntry(route, label, thumbRef, priority = 0) {
  const page = pageByRoute.get(route);
  return {
    route,
    title: label || page?.title || routeTitleFallback(route),
    excerpt: page?.excerpt || "",
    thumbRef,
    priority,
  };
}

function renderSearchFragment(groupTitle, metaText, entries, emptyMessage) {
  if (!entries.length) {
    return [
      `<div class="spa-search-group">`,
      `  <div class="rhs link-label above-line">${htmlEscape(groupTitle)}</div>`,
      `  <p class="spa-search-empty">${htmlEscape(emptyMessage)}</p>`,
      `</div>`,
    ].join("\n");
  }

  return [
    `<div class="spa-search-group">`,
    `  <div class="rhs link-label above-line">${htmlEscape(groupTitle)}</div>`,
    `  <p class="spa-search-count">${htmlEscape(metaText)}</p>`,
    entries.map((entry) => {
      const thumb = entry.thumbRef
        ? `<img class="rhs fullicon" src="${PLACEHOLDER_IMAGE}" data-lmt-compat-src="${htmlEscape(entry.thumbRef)}" alt="">`
        : "";
      const excerpt = entry.excerpt ? `<div class="spa-search-excerpt">${htmlEscape(entry.excerpt)}</div>` : "";
      return [
        `  <div class="entry rhs parent">`,
        `    <a class="rhs" href="${htmlEscape(entry.route)}">${thumb}${htmlEscape(entry.title)}</a>`,
        `    ${excerpt}`,
        `  </div>`,
      ].join("\n");
    }).join("\n"),
    `</div>`,
  ].join("\n");
}

function uniqueEntries(entries) {
  const seen = new Set();
  return entries.filter((entry) => {
    if (seen.has(entry.route)) return false;
    seen.add(entry.route);
    return true;
  });
}

function sortEntries(entries) {
  return entries.sort((a, b) => {
    if (b.priority !== a.priority) return b.priority - a.priority;
    return a.title.localeCompare(b.title) || a.route.localeCompare(b.route);
  });
}

function buildIndexedEntries(candidateRefs) {
  const entryMap = new Map();
  for (const ref of candidateRefs) {
    const pageIndexes = reverseIndex.get(ref);
    if (!pageIndexes) continue;
    for (const pageIndex of pageIndexes) {
      const page = pages[pageIndex];
      if (!page) continue;
      let current = entryMap.get(page.route);
      if (!current) {
        current = buildSearchEntry(page.route, page.title, ref, 1);
        entryMap.set(page.route, current);
      } else {
        if (!current.thumbRef) {
          current.thumbRef = ref;
        }
        current.priority += 1;
      }
    }
  }
  return [...entryMap.values()];
}

function parseSearchKeyboardRoute(route) {
  const rest = route.replace(/^\/search-keyboard\//, "");
  const parts = rest.split(",").filter(Boolean);
  if (parts.length < 2) return null;
  const preferAccid = parts[0];
  const midinotes = parts.slice(1).map((token) => Number.parseInt(token, 10)).filter((value) => Number.isFinite(value));
  if (!midinotes.length) return null;
  return { preferAccid, midinotes };
}

function keyboardSearchResponse(route) {
  const parsed = parseSearchKeyboardRoute(route);
  if (!parsed) {
    return renderSearchFragment("Keyboard Search", "", [], "Select notes to see related pages.");
  }
  const pcs = window.HarmoniousClient?.PCS || window.PitchClassSet();
  const noteStem = pcs.makeNoteUrlStringFromMidinotes("/keyboard/", parsed.preferAccid, parsed.midinotes);
  const grandStem = pcs.makeNoteUrlStringFromMidinotes("/grand-chord/", parsed.preferAccid, parsed.midinotes);
  const wideStem = pcs.makeNoteUrlStringFromMidinotes("/wide-chord/", parsed.preferAccid, parsed.midinotes);
  const chordStem = pcs.makeNoteUrlStringFromMidinotes("/chord/", parsed.preferAccid, parsed.midinotes);
  const clippedStem = pcs.makeNoteUrlStringFromMidinotes("/chord-clipped/", parsed.preferAccid, parsed.midinotes);
  const scaleStem = pcs.makeNoteUrlStringFromMidinotes("/scale/", parsed.preferAccid, parsed.midinotes);
  const candidateRefs = [grandStem, wideStem, chordStem, clippedStem, scaleStem]
    .filter((stem) => stem && stem !== "/")
    .map((stem) => `${stem.replace(/^\//, "")}.svg`)
    .filter((ref, index, arr) => arr.indexOf(ref) === index);
  const entries = [buildSearchEntry(`${noteStem}.html`, "Interactive Keyboard", `${grandStem.replace(/^\//, "")}.svg`, 100)];
  entries[0].route = noteStem;
  entries.push(...buildIndexedEntries(candidateRefs));
  const sorted = sortEntries(uniqueEntries(entries)).slice(0, 48);
  return renderSearchFragment(
    "Keyboard Search",
    `${sorted.length} related page${sorted.length === 1 ? "" : "s"}`,
    sorted,
    "No related pages were found for the current note collection.",
  );
}

function parseSearchFretsRoute(route) {
  const stem = route.replace(/^\/search-eadgbe\//, "");
  return stem ? stem : null;
}

function fretsSearchResponse(route) {
  const stem = parseSearchFretsRoute(route);
  if (!stem) {
    return renderSearchFragment("Fret Search", "", [], "Select frets to see related pages.");
  }
  const pcs = window.HarmoniousClient?.PCS || window.PitchClassSet();
  const fretsRoute = `/eadgbe-frets/${stem}`;
  const fretsArray = pcs.fretsUrlToFretsArray(fretsRoute, "/eadgbe-frets/");
  const midinotes = window.HarmoniousClient?.fretsArrayToMidiNotes(fretsArray) || [];
  const candidateRefs = [`eadgbe/${stem}.svg`];
  if (midinotes.length > 0) {
    candidateRefs.push(
      `${pcs.makeNoteUrlStringFromMidinotes("/grand-chord/", "a", midinotes).replace(/^\//, "")}.svg`,
      `${pcs.makeNoteUrlStringFromMidinotes("/wide-chord/", "a", midinotes).replace(/^\//, "")}.svg`,
      `${pcs.makeNoteUrlStringFromMidinotes("/chord/", "a", midinotes).replace(/^\//, "")}.svg`,
      `${pcs.makeNoteUrlStringFromMidinotes("/scale/", "a", midinotes).replace(/^\//, "")}.svg`,
    );
  }
  const entries = [buildSearchEntry(`${fretsRoute}.html`, "Interactive Guitar Fretboard", `eadgbe/${stem}.svg`, 100)];
  entries[0].route = fretsRoute;
  entries.push(...buildIndexedEntries(candidateRefs.filter((ref, index, arr) => ref && arr.indexOf(ref) === index)));
  const sorted = sortEntries(uniqueEntries(entries)).slice(0, 48);
  return renderSearchFragment(
    "Fret Search",
    `${sorted.length} related page${sorted.length === 1 ? "" : "s"}`,
    sorted,
    "No related pages were found for the current fret selection.",
  );
}

function randomRouteResponse() {
  if (!randomRoutes.length) {
    return "index.html";
  }
  const index = Math.floor(Math.random() * randomRoutes.length);
  return randomRoutes[index].replace(/^\//, "");
}

async function fetchPageHtml(route) {
  const response = await fetch(routeToBundleContentUrl(route));
  if (!response.ok) {
    throw new Error(`Failed to fetch local page ${route}: ${response.status}`);
  }
  return rewriteFetchedHtml(await response.text(), route);
}

async function resolveBridgeResponse(route) {
  if (route === "/random/") {
    logRequest("random", route);
    return randomRouteResponse();
  }
  if (route.startsWith("/search-keyboard/")) {
    logRequest("search-keyboard", route);
    state.lastFragmentKind = "search-keyboard";
    syncDebugState();
    return keyboardSearchResponse(route);
  }
  if (route.startsWith("/search-eadgbe/")) {
    logRequest("search-eadgbe", route);
    state.lastFragmentKind = "search-eadgbe";
    syncDebugState();
    return fretsSearchResponse(route);
  }
  if (
    route === "/index.html"
    || route.startsWith("/p/")
    || route.startsWith("/keyboard/")
    || route.startsWith("/eadgbe-frets/")
  ) {
    logRequest("page", route);
    return fetchPageHtml(route);
  }
  return null;
}

function installRequestBridge() {
  if (!window.jQuery || !originalJqueryGet) {
    throw new Error("jQuery is required for the harmonious SPA bridge");
  }

  window.jQuery.get = function(request, dataOrSuccess, maybeSuccess) {
    const success = typeof dataOrSuccess === "function"
      ? dataOrSuccess
      : typeof maybeSuccess === "function"
        ? maybeSuccess
        : null;
    const normalizedRoute = normalizePageRoute(new URL(String(request), window.location.href).pathname);
    const handled = (
      normalizedRoute === "/random/"
      || normalizedRoute.startsWith("/search-keyboard/")
      || normalizedRoute.startsWith("/search-eadgbe/")
      || normalizedRoute === "/index.html"
      || normalizedRoute.startsWith("/p/")
      || normalizedRoute.startsWith("/keyboard/")
      || normalizedRoute.startsWith("/eadgbe-frets/")
    );

    if (!handled) {
      return originalJqueryGet(request, dataOrSuccess, maybeSuccess);
    }

    const deferred = window.jQuery.Deferred();
    resolveBridgeResponse(normalizedRoute)
      .then((payload) => {
        if (success) {
          try {
            success(payload);
          } catch (err) {
            console.error(
              `SPA success callback failed for ${normalizedRoute}: ${err?.stack || err?.message || err}`,
            );
            deferred.reject(err);
            return;
          }
        }
        deferred.resolve(payload);
        requestAnimationFrame(() => {
          refreshCompatImages(document);
          if (normalizedRoute === "/index.html" || normalizedRoute.startsWith("/p/") || normalizedRoute.startsWith("/keyboard/") || normalizedRoute.startsWith("/eadgbe-frets/")) {
            state.lastRoute = normalizedRoute;
            state.routeLoads += 1;
            syncDebugState();
            window.dispatchEvent(new CustomEvent("lmt-harmonious-spa-route-loaded", { detail: { route: normalizedRoute } }));
          } else {
            syncDebugState();
            window.dispatchEvent(new CustomEvent("lmt-harmonious-spa-fragment-loaded", { detail: { route: normalizedRoute } }));
          }
        });
      })
      .catch((err) => {
        console.error(
          `SPA request bridge failed for ${normalizedRoute}: ${err?.stack || err?.message || err}`,
        );
        deferred.reject(err);
      });
    return deferred.promise();
  };
}

function loadRoute(route) {
  const normalizedRoute = canonicalPageFetchRoute(route);
  return new Promise((resolve, reject) => {
    const onLoaded = (event) => {
      if (event.detail?.route !== normalizedRoute) return;
      window.removeEventListener("lmt-harmonious-spa-route-loaded", onLoaded);
      resolve();
    };
    window.addEventListener("lmt-harmonious-spa-route-loaded", onLoaded);
    try {
      window.HarmoniousClient.loadUrlBodyIntoBody(normalizedRoute);
    } catch (err) {
      window.removeEventListener("lmt-harmonious-spa-route-loaded", onLoaded);
      reject(err);
    }
  });
}

async function boot() {
  setShellStatus("Loading Harmonious SPA…");
  state.wasm = await instantiateWasm();
  verifyExports(state.wasm.exports);
  state.wasm = state.wasm.exports;
  state.memory = state.wasm.memory;
  buildCompatIndex();
  installCompatImageInterceptors();
  installRequestBridge();
  window.HarmoniousClient.loadUrlBodyIntoBody = function(request) {
    const resolvedRoute = normalizePageRoute(new URL(String(request), window.location.href).pathname);
    renderPageRoute(resolvedRoute).catch((err) => {
      console.error(`AJAX request for URL '${request}' failed`);
      console.error(err?.stack || err?.message || String(err));
    });
  };
  refreshCompatImages(document);
  window.HarmoniousClient.onLoad_OnePageLoadEver();

  const initialRoute = canonicalPageFetchRoute(window.location.pathname || HARMONIOUS_SPA_MANIFEST.homeRoute || "/index.html");
  await loadRoute(initialRoute);
  state.ready = true;
  syncDebugState();
}

window.HarmoniousSPA = {
  refreshCompatImages: () => refreshCompatImages(document),
  loadRoute,
  state: window.__lmtHarmoniousSpa,
};

boot().catch((err) => {
  console.error(err);
  window.__lmtHarmoniousSpa.bootError = err.message || String(err);
  syncDebugState();
  setShellStatus(`Failed to initialize Harmonious SPA: ${err.message || err}`, "error");
});
