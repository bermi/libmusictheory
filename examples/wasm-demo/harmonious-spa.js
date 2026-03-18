import { HARMONIOUS_SPA_MANIFEST } from "./harmonious-spa-manifest.js";

const BUNDLE_BASE_URL = new URL("./", import.meta.url);
const SHELL_ENTRY_ROUTE = new URL("./index.html", BUNDLE_BASE_URL).pathname;
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
const KEY_SLIDER_COLOR_INDEX = [2, 7, 0, 5, 10, 3, 8, 1, 6, 11, 4, 9];
const KEY_TRIANGLE_PC_COLORS = "#00c #a4f #f0f #a16 #e02 #f91 #c81 #094 #161 #077 #0bb #28f".split(" ");
const KEY_SLIDER_WHITELIST_COORDS = [
  [0, 1, true, 3], [0, 2, false, 11], [0, 2, true, 8], [0, 3, false, 4], [0, 3, true, 1], [0, 4, false, 9], [0, 4, true, 6],
  [1, 1, false, 2], [1, 2, true, 11], [1, 2, false, 7], [1, 3, true, 4], [1, 3, false, 0], [1, 4, true, 9], [1, 4, false, 5], [1, 5, true, 2],
  [2, 1, true, 2], [2, 2, false, 10], [2, 2, true, 7], [2, 3, false, 3], [2, 3, true, 0], [2, 4, false, 8], [2, 4, true, 5], [2, 5, false, 1],
  [3, 3, true, 3], [3, 4, true, 8],
];
const KEY_SLIDER_MAJOR_ROUTES = "/p/63/Cs-Major /p/63/Cs-Major /p/63/Cs-Major /p/63/Cs-Major /p/63/Cs-Major /p/82/Fs-Major /p/a0/B-Major /p/7c/E-Major /p/ad/A-Major /p/63/D-Major /p/d2/G-Major /p/fb/C-Major /p/ab/F-Major /p/a7/Bb-Major /p/c6/Eb-Major /p/eb/Ab-Major /p/1f/Db-Major /p/0b/Gb-Major /p/39/Cb-Major /p/39/Cb-Major /p/39/Cb-Major /p/39/Cb-Major".split(" ");
const KEY_SLIDER_MINOR_ROUTES = "/p/dd/Cs-Minor /p/dd/Cs-Minor /p/dd/Cs-Minor /p/dd/Cs-Minor /p/dd/Cs-Minor /p/43/Fs-Minor /p/98/B-Minor /p/a5/E-Minor /p/f1/A-Minor /p/62/D-Minor /p/6e/G-Minor /p/4c/C-Minor /p/00/F-Minor /p/69/Bb-Minor /p/49/Eb-Minor /p/49/Ab-Minor /p/dd/Cs-Minor /p/43/Fs-Minor /p/98/B-Minor /p/98/B-Minor /p/98/B-Minor /p/98/B-Minor".split(" ");
const KEY_SLIDER_ROUTE_SET = new Set([...KEY_SLIDER_MAJOR_ROUTES, ...KEY_SLIDER_MINOR_ROUTES]);

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
  keyTriDataUrlCache: new Map(),
  keySliderGroupCache: new Map(),
  keySliderSyncSerial: 0,
  requestLog: [],
  compatReplacements: 0,
  ready: false,
  routeLoads: 0,
  lastRoute: null,
  lastFragmentKind: null,
  observer: null,
  rawHistoryPushState: null,
  rawHistoryReplaceState: null,
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

function updateShellCanonical() {
  const canonical = document.getElementById("spa-shell-canonical");
  if (!canonical) return;
  canonical.setAttribute("href", window.location.href);
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

function isShellPageRoute(route) {
  const normalized = normalizePageRoute(route);
  return normalized === "/index.html"
    || normalized.startsWith("/p/")
    || normalized === "/keyboard"
    || normalized === "/keyboard/"
    || normalized.startsWith("/keyboard/")
    || normalized === "/eadgbe-frets"
    || normalized === "/eadgbe-frets/"
    || normalized.startsWith("/eadgbe-frets/");
}

function barePageRoute(route) {
  return normalizePageRoute(route).replace(/\.html$/i, "");
}

function interactiveRouteFamily(route) {
  const bareRoute = barePageRoute(route);
  if (bareRoute.startsWith("/keyboard/")) return "keyboard";
  if (bareRoute.startsWith("/eadgbe-frets/")) return "frets";
  return null;
}

function absoluteRouteUrl(route) {
  return new URL(barePageRoute(route), window.location.origin).toString();
}

function shellHrefForRoute(route) {
  const normalized = normalizePageRoute(route);
  if (normalized === "/index.html") return SHELL_ENTRY_ROUTE;
  return `${SHELL_ENTRY_ROUTE}?route=${encodeURIComponent(normalized)}`;
}

function resolveShellNavigationRoute(rawValue, baseHref = window.location.href) {
  if (!rawValue) return "/index.html";
  try {
    const resolved = new URL(String(rawValue), baseHref);
    const routeParam = resolved.searchParams.get("route");
    if (routeParam) {
      return canonicalPageFetchRoute(normalizeSiteAttribute(routeParam));
    }
    return canonicalPageFetchRoute(normalizePageRoute(resolved.pathname));
  } catch (_err) {
    return canonicalPageFetchRoute(normalizePageRoute(rawValue));
  }
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

function normalizeKeyTriPath(rawValue, baseHref = window.location.href) {
  if (!rawValue) return null;
  try {
    const resolved = new URL(String(rawValue), baseHref);
    const normalized = resolved.pathname.replace(/^\/+/, "");
    if (!normalized.startsWith("key-tri/")) return null;
    const stem = normalized.slice("key-tri/".length);
    if (!/^(?:0|[1-9]\d*[bs]?),\d+$/.test(stem)) return null;
    return `key-tri/${stem}`;
  } catch (_err) {
    return null;
  }
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

function keyTriSpecFromPath(normalizedPath) {
  const stem = normalizedPath.replace(/^key-tri\//, "");
  const [token, heightText] = stem.split(",");
  const height = Number.parseInt(heightText, 10);
  if (!Number.isFinite(height) || height <= 0) {
    throw new Error(`invalid key-tri height in ${normalizedPath}`);
  }
  return {
    knum: parseKixToken(token),
    height,
  };
}

function keyTriPolygon(row, column, downTriangle, stride, rowHeight, corx) {
  if (!downTriangle) {
    let col = column;
    if ((row + 1) % 2) {
      col -= 0.5;
    }
    return [
      [1 + corx + stride + col * stride, 1 + row * rowHeight],
      [1 + corx + stride + (col + 0.5) * stride, 1 + (row + 1) * rowHeight],
      [1 + corx + stride + (col - 0.5) * stride, 1 + (row + 1) * rowHeight],
    ];
  }
  let col = column;
  if (row % 2) {
    col -= 0.5;
  }
  col -= 0.5;
  return [
    [1 + corx + stride + col * stride, 1 + row * rowHeight],
    [1 + corx + stride + (col + 0.5) * stride, 1 + (row + 1) * rowHeight],
    [1 + corx + stride + (col + 1.0) * stride, 1 + row * rowHeight],
  ];
}

function keyTriSvgDataUrl(normalizedPath) {
  const cached = state.keyTriDataUrlCache.get(normalizedPath);
  if (cached) return cached;

  const { knum, height } = keyTriSpecFromPath(normalizedPath);
  const width = Math.ceil(height * 1400 / 694);
  const stride = 138 * height / 480;
  const rowHeight = stride * 0.5 * 1.732;
  const rat = window.devicePixelRatio || 1;
  let corx = 0;
  if (rat < 2) corx = -stride * 0.25;
  if (rat > 2.9 && rat < 3.1) corx = 0.08 * stride;
  const colorOffset = KEY_SLIDER_COLOR_INDEX[((knum + 11 + 3) % 12 + 12) % 12] || 0;

  const polygons = KEY_SLIDER_WHITELIST_COORDS.map(([row, column, downTriangle, relativeColor]) => {
    const color = KEY_TRIANGLE_PC_COLORS[(colorOffset + relativeColor) % 12];
    const points = keyTriPolygon(row, column, Boolean(downTriangle), stride, rowHeight, corx)
      .map(([x, y]) => `${x.toFixed(3)},${y.toFixed(3)}`)
      .join(" ");
    return `<polygon points="${points}" fill="${color}" stroke="#ffffff" stroke-width="${Math.max(1, height / 190).toFixed(3)}" stroke-linejoin="round"/>`;
  }).join("");

  const svgText = [
    `<?xml version="1.0" encoding="UTF-8"?>`,
    `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`,
    `<rect width="${width}" height="${height}" fill="#eeeeee"/>`,
    polygons,
    `</svg>`,
  ].join("");
  const dataUrl = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svgText)}`;
  state.keyTriDataUrlCache.set(normalizedPath, dataUrl);
  return dataUrl;
}

function setCompatDataset(img, normalizedPath) {
  originalElementSetAttribute.call(img, "data-lmt-compat-src", normalizedPath);
  originalElementSetAttribute.call(img, "data-lmt-image-source", "wasm-compat");
}

function setKeyTriDataset(img, normalizedPath) {
  originalElementSetAttribute.call(img, "data-lmt-key-tri-src", normalizedPath);
  originalElementSetAttribute.call(img, "data-lmt-image-source", "spa-key-tri");
}

function applyCompatImage(img, rawValue) {
  const normalizedPath = normalizeCompatPath(rawValue, img.baseURI || window.location.href);
  if (normalizedPath) {
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

  const keyTriPath = normalizeKeyTriPath(rawValue, img.baseURI || window.location.href);
  if (!keyTriPath) return false;
  if (
    img.getAttribute("data-lmt-key-tri-src") === keyTriPath
    && img.getAttribute("data-lmt-image-source") === "spa-key-tri"
    && String(img.getAttribute("src") || "").startsWith("data:image/svg+xml")
  ) {
    return true;
  }
  const dataUrl = keyTriSvgDataUrl(keyTriPath);
  setKeyTriDataset(img, keyTriPath);
  if (imageSrcDescriptor?.set) {
    imageSrcDescriptor.set.call(img, dataUrl);
  } else {
    originalElementSetAttribute.call(img, "src", dataUrl);
  }
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
  if (normalized.startsWith("/p/") && !normalized.endsWith(".html")) return `${normalized}.html`;
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
  const normalized = String(rawHref)
    .replace(/^https?:\/\/harmoniousapp\.net/i, "")
    .replace(/(^|\/)keyboard\/index\.html(?=([?#].*)?$)/i, "$1keyboard/")
    .replace(/(^|\/)eadgbe-frets\/index\.html(?=([?#].*)?$)/i, "$1eadgbe-frets/")
    .replace(/(^|\/)(keyboard\/[^?#]+)\.html(?=([?#].*)?$)/i, "$1$2")
    .replace(/(^|\/)(eadgbe-frets\/[^?#]+)\.html(?=([?#].*)?$)/i, "$1$2");
  const pageMatch = normalized.match(/^([^?#]+)\.html((?:[?#].*)?)$/i);
  if (pageMatch && KEY_SLIDER_ROUTE_SET.has(pageMatch[1])) {
    return `${pageMatch[1]}${pageMatch[2] || ""}`;
  }
  return normalized;
}

function rewriteFetchedHtml(htmlText, route) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(window.HarmoniousConfig.ServerStringReplacer(String(htmlText)), "text/html");
  rewriteDocument(doc, route);
  return serializeDocument(doc);
}

function rewriteDocument(doc, route) {
  doc.querySelectorAll("a[href]").forEach((anchor) => {
    const normalizedHref = normalizeSiteAttribute(anchor.getAttribute("href"));
    if (isShellPageRoute(normalizedHref)) {
      anchor.setAttribute("data-lmt-shell-route", normalizePageRoute(normalizedHref));
      anchor.setAttribute("href", shellHrefForRoute(normalizedHref));
    } else {
      anchor.setAttribute("href", normalizedHref);
    }
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

function serializeDocument(doc) {
  return `<!doctype html>\n${doc.documentElement.outerHTML}`;
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
  window.__lmtCurrentPageUrlPath = normalizedRoute.replace(/\.html$/i, "");
  window.__lmtCurrentSliderUrlPath = window.__lmtCurrentPageUrlPath;
  updateShellCanonical();

  refreshCompatImages(document);
  executeInlineScripts(inlineScripts, normalizedRoute);
  await scheduleKeyPageSliderSynchronization(normalizedRoute);
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

function routeRelativeTo(baseRoute, rawValue) {
  if (!rawValue) return "";
  if (String(rawValue).startsWith("auto:")) {
    return normalizeSiteAttribute(String(rawValue));
  }
  try {
    const resolved = new URL(String(rawValue), new URL(baseRoute, window.location.origin));
    return normalizeSiteAttribute(`${resolved.pathname}${resolved.search}${resolved.hash}`);
  } catch (_err) {
    return normalizeSiteAttribute(String(rawValue));
  }
}

function historyRestoreSnapshot() {
  const href = `${window.location.pathname}${window.location.search}${window.location.hash}`;
  return {
    href: href || shellHrefForRoute("/index.html"),
    state: history.state,
  };
}

function rawHistoryReplaceState(historyState, title, url) {
  const replaceState = state.rawHistoryReplaceState || history.replaceState.bind(history);
  return replaceState(historyState, title, url);
}

function withTemporaryVisibleRoute(route, fn, restoreSnapshot = null) {
  const bareRoute = barePageRoute(route);
  const restore = restoreSnapshot || historyRestoreSnapshot();
  rawHistoryReplaceState({ url: bareRoute }, "Harmonious", bareRoute);
  try {
    return fn();
  } finally {
    rawHistoryReplaceState(restore.state, "Harmonious", restore.href);
  }
}

function normalizedShellRouteFromValue(rawValue, baseHref = window.location.href) {
  if (rawValue == null || rawValue === "") return null;
  const normalized = resolveShellNavigationRoute(rawValue, baseHref);
  return isShellPageRoute(normalized) ? barePageRoute(normalized) : null;
}

function syncInteractiveRouteState(route) {
  const bareRoute = normalizedShellRouteFromValue(route);
  if (!bareRoute || !interactiveRouteFamily(bareRoute)) return;
  window.__lmtCurrentPageUrlPath = bareRoute;
  state.lastRoute = canonicalPageFetchRoute(bareRoute);
  syncDebugState();
}

function resolvePopTargetRoute(eventState, fallbackUrl) {
  const primary = eventState && typeof eventState === "object"
    ? (eventState.__lmtShellRoute || eventState.url)
    : null;
  return normalizedShellRouteFromValue(primary || fallbackUrl);
}

function normalizePopEventState(eventState, fallbackUrl) {
  const targetRoute = resolvePopTargetRoute(eventState, fallbackUrl);
  if (!targetRoute) {
    if (!eventState || typeof eventState !== "object") return eventState;
    return { ...eventState };
  }
  return {
    ...(eventState && typeof eventState === "object" ? eventState : {}),
    url: absoluteRouteUrl(targetRoute),
    __lmtShellRoute: targetRoute,
  };
}

function installShellHistoryOverride() {
  if (state.rawHistoryPushState && state.rawHistoryReplaceState) return;
  state.rawHistoryPushState = history.pushState.bind(history);
  state.rawHistoryReplaceState = history.replaceState.bind(history);

  function normalizeHistoryCall(historyState, title, url) {
    const normalizedRoute = normalizedShellRouteFromValue(
      url != null ? url : historyState && typeof historyState === "object" ? historyState.url : null,
      window.location.href,
    );
    if (!normalizedRoute) {
      return [historyState, title, url];
    }
    const nextState = {
      ...(historyState && typeof historyState === "object" ? historyState : {}),
      url: absoluteRouteUrl(normalizedRoute),
      __lmtShellRoute: normalizedRoute,
    };
    syncInteractiveRouteState(normalizedRoute);
    return [nextState, title, shellHrefForRoute(normalizedRoute)];
  }

  history.pushState = function(historyState, title, url) {
    const normalizedArgs = normalizeHistoryCall(historyState, title, url);
    const result = state.rawHistoryPushState(...normalizedArgs);
    updateShellCanonical();
    return result;
  };
  history.replaceState = function(historyState, title, url) {
    const normalizedArgs = normalizeHistoryCall(historyState, title, url);
    const result = state.rawHistoryReplaceState(...normalizedArgs);
    updateShellCanonical();
    return result;
  };
}

function normalizeLabelText(labelText) {
  return String(labelText)
    .replaceAll("\u266d", "b")
    .replaceAll("\u266f", "#")
    .replaceAll("\u00b0", "o")
    .replaceAll(/\s+/g, " ")
    .trim();
}

function parseKixToken(token) {
  const raw = String(token || "").trim();
  if (!raw || raw === "0") return 0;
  if (raw.endsWith("s")) return -Number.parseInt(raw.slice(0, -1), 10);
  if (raw.endsWith("b")) return Number.parseInt(raw.slice(0, -1), 10);
  throw new Error(`invalid key-slider key token: ${token}`);
}

function sliderQueryToColumn(row, downTriangle, j) {
  if (downTriangle) {
    return row % 2 === 1 ? j + 1 : j;
  }
  return row % 2 === 0 ? j + 1 : j;
}

function sliderRelativeColorIndex(row, column, downTriangle) {
  for (const one of KEY_SLIDER_WHITELIST_COORDS) {
    if (one[0] === row && one[1] === column && Boolean(one[2]) === Boolean(downTriangle)) {
      return one[3];
    }
  }
  return null;
}

function sliderCurrentKeyRoute(knum, row) {
  const majorMinorIndex = row > 1 ? 1 : 0;
  const keyLinks = majorMinorIndex === 0 ? KEY_SLIDER_MAJOR_ROUTES : KEY_SLIDER_MINOR_ROUTES;
  const index = Math.max(0, Math.min(keyLinks.length - 1, knum + 11));
  return canonicalPageFetchRoute(keyLinks[index]);
}

function keySliderTokenFromIndex(index) {
  const knum = index - 11;
  if (knum < 0) return `${-knum}s`;
  if (knum > 0) return `${knum}b`;
  return "0";
}

function keySliderInitialSpecForRoute(route) {
  const bareRoute = canonicalPageFetchRoute(route).replace(/\.html$/i, "");
  if (bareRoute === "/p/a7/Keys") {
    return {
      bareRoute,
      currentRoute: "/p/fb/C-Major",
      searchRoute: "/search-key-tri/0,1,3,1",
      currentText: "Key of C Major",
    };
  }

  const majorIndex = KEY_SLIDER_MAJOR_ROUTES.indexOf(bareRoute);
  if (majorIndex >= 0) {
    return {
      bareRoute,
      currentRoute: bareRoute,
      searchRoute: `/search-key-tri/${keySliderTokenFromIndex(majorIndex)},1,3,1`,
      currentText: document.title.replace(/\s*-\s*Harmonious$/i, "").trim(),
    };
  }

  const minorIndex = KEY_SLIDER_MINOR_ROUTES.indexOf(bareRoute);
  if (minorIndex >= 0) {
    return {
      bareRoute,
      currentRoute: bareRoute,
      searchRoute: `/search-key-tri/${keySliderTokenFromIndex(minorIndex)},0,3,2`,
      currentText: document.title.replace(/\s*-\s*Harmonious$/i, "").trim(),
    };
  }

  return null;
}

function sliderAbsoluteNoteColor(knum, row, column, downTriangle) {
  const relative = sliderRelativeColorIndex(row, column, downTriangle);
  if (relative == null) return null;
  const colorOffset = KEY_SLIDER_COLOR_INDEX[((knum + 11 + 3) % 12 + 12) % 12] || 0;
  return (colorOffset + relative) % 12;
}

function parseSearchKeyTriRoute(route) {
  const rest = route.replace(/^\/search-key-tri\//, "");
  const parts = rest.split(",");
  if (parts.length !== 4) return null;
  const knum = parseKixToken(parts[0]);
  const z = Number.parseInt(parts[1], 10);
  const j = Number.parseInt(parts[2], 10);
  const row = Number.parseInt(parts[3], 10);
  if (![z, j, row].every((value) => Number.isFinite(value))) return null;
  const downTriangle = z === 0;
  const column = sliderQueryToColumn(row, downTriangle, j);
  const keyRoute = sliderCurrentKeyRoute(knum, row);
  const noteColor = sliderAbsoluteNoteColor(knum, row, column, downTriangle);
  return {
    knum,
    row,
    column,
    downTriangle,
    keyRoute,
    noteColor,
  };
}

function sliderGroupBucket(group) {
  const firstTitle = normalizeLabelText(group.entries[0]?.titleText || "");
  const joinedTitles = group.entries.map((entry) => normalizeLabelText(entry.titleText)).join(" | ");
  const label = group.labelText;
  if (/\b(?:min|dim)\b/i.test(firstTitle) || /^vii|iio|#vio/i.test(label) || /^i(?:$|[^A-Z])/.test(label)) return "down";
  if (/\b(?:Maj|Dom|aug|Fr\. 6|Gr\. 6|N\.)\b/i.test(firstTitle)) return "up";
  if (/\b(?:min|dim)\b/i.test(joinedTitles)) return "down";
  if (/^V(?:\/|\b|\s*\()/.test(label) || /\+/.test(label) || /\((?:Fr\.|Gr\.|N\.|It\.)/.test(label)) return "up";
  return "down";
}

function sliderGroupRank(group) {
  const label = group.labelText;
  if (/^[ivIV]+$/.test(label) || /^(?:i|I{1,3}|IV|V|VI|VII)$/.test(label)) return 0;
  if (/^V(?:\/|\b|\s*\()/.test(label)) return 1;
  if (/^vii/.test(label)) return 2;
  return 3;
}

function sliderGroupSubtitle(group) {
  const label = group.labelText;
  if (/^V(?:\/|\b|\s*\()/.test(label)) return "Secondary Dominant";
  if (/^vii/.test(label)) return "Leading-Tone Function";
  if (/\((?:Fr\.|Gr\.|N\.|It\.)/.test(label) || /\+/.test(label)) return "Chromatic Function";
  return "Diatonic Function";
}

async function keySliderGroupsForRoute(keyRoute) {
  const cached = state.keySliderGroupCache.get(keyRoute);
  if (cached) return cached;

  const response = await fetch(routeToBundleContentUrl(keyRoute));
  if (!response.ok) {
    throw new Error(`Failed to fetch key page ${keyRoute}: ${response.status}`);
  }
  const rawText = await response.text();
  const doc = new DOMParser().parseFromString(rawText, "text/html");
  const groups = Array.from(doc.querySelectorAll("span.grouper.lhs.chord-type.page-t9key.func")).map((group) => {
    const className = group.getAttribute("class") || "";
    const noteColorMatch = className.match(/\bnoteColor(\d+)\b/);
    const keyClassMatch = className.match(/\bpage-named-key-of-[^\s"]+/);
    const labelNode = group.querySelector("div.link-label.above-line");
    const labelHtml = labelNode?.innerHTML?.trim() || "";
    const labelText = normalizeLabelText(labelNode?.textContent || "");
    const entries = Array.from(group.querySelectorAll("div.smchord a.lhs.parent")).map((anchor) => {
      const href = routeRelativeTo(keyRoute, anchor.getAttribute("href") || "");
      const imgNode = anchor.querySelector("img.smicon");
      const rawSrc = imgNode?.getAttribute("src") || "";
      const compatRef = normalizeCompatPath(rawSrc, new URL(keyRoute, window.location.origin).toString());
      const resolvedSrc = compatRef ? PLACEHOLDER_IMAGE : routeRelativeTo(keyRoute, rawSrc);
      const titleNode = anchor.querySelector(".centery");
      return {
        href,
        rawSrc,
        compatRef,
        resolvedSrc,
        titleHtml: titleNode?.innerHTML?.trim() || "",
        titleText: titleNode?.textContent?.trim() || "",
      };
    });
    const parsed = {
      className,
      keyClass: keyClassMatch?.[0] || "",
      noteColor: noteColorMatch ? Number.parseInt(noteColorMatch[1], 10) : -1,
      labelHtml,
      labelText,
      entries,
    };
    parsed.bucket = sliderGroupBucket(parsed);
    parsed.rank = sliderGroupRank(parsed);
    return parsed;
  }).filter((group) => group.noteColor >= 0 && group.labelText && group.entries.length > 0);

  state.keySliderGroupCache.set(keyRoute, groups);
  return groups;
}

function renderKeySliderCard(group) {
  const keyClass = group.keyClass ? ` ${group.keyClass}` : "";
  const baseClass = `lhs chord page-t9key func noteColor${group.noteColor}${keyClass}`;
  const sliderEntries = group.entries.slice(0, 3).map((entry) => {
    const img = entry.compatRef
      ? `<img class="slider-icon2" src="${PLACEHOLDER_IMAGE}" data-lmt-compat-src="${htmlEscape(entry.compatRef)}" alt="">`
      : entry.rawSrc
        ? `<img class="slider-icon2" src="${htmlEscape(entry.resolvedSrc)}" alt="">`
        : "";
    return [
      `  <div class="slider-entry">`,
      `    <a href="${htmlEscape(entry.href)}">${img}</a><a href="${htmlEscape(entry.href)}" class="slider-text">${entry.titleHtml || htmlEscape(entry.titleText)}</a>`,
      `  </div>`,
    ].join("\n");
  }).join("\n");

  return [
    `<span class="${baseClass} slider-info spa-slider-info">`,
    `  <div class="${baseClass} link-label above-line lr-container"><span class="lr-item lr-bold lr-function">${group.labelHtml}</span><span class="link-label lr-item lr-function">${htmlEscape(sliderGroupSubtitle(group))}</span></div>`,
    sliderEntries,
    `</span>`,
  ].join("\n");
}

function renderEmptyKeySliderCard(message) {
  return [
    `<span class="lhs chord page-t9key slider-info spa-slider-empty">`,
    `  <div class="lhs chord page-t9key link-label above-line lr-container"><span class="lr-item lr-bold lr-function">Key Slider</span><span class="link-label lr-item lr-function">Local Reconstruction</span></div>`,
    `  <div class="slider-entry"><span class="slider-text">${htmlEscape(message)}</span></div>`,
    `</span>`,
  ].join("\n");
}

async function keySliderResponse(route) {
  const parsed = parseSearchKeyTriRoute(route);
  if (!parsed) {
    return renderEmptyKeySliderCard("Select a triangle to see related chords.");
  }

  const groups = await keySliderGroupsForRoute(parsed.keyRoute);
  const noteColorGroups = groups
    .filter((group) => group.noteColor === parsed.noteColor)
    .sort((a, b) => a.rank - b.rank || a.labelText.localeCompare(b.labelText));

  const bucket = parsed.downTriangle ? "down" : "up";
  let selected = noteColorGroups.filter((group) => group.bucket === bucket);
  if (!selected.length) {
    selected = noteColorGroups;
  }
  selected = selected.slice(0, 3);

  if (!selected.length) {
    return renderEmptyKeySliderCard(`No local key-slider cards matched ${parsed.keyRoute}.`);
  }

  return selected.map((group) => renderKeySliderCard(group)).join("\n");
}

async function synchronizeKeyPageSliderOnce(route) {
  const spec = keySliderInitialSpecForRoute(route);
  if (!spec) return;

  const current = document.getElementById("current");
  const currentHref = document.getElementById("current-href");
  const currentKeyIm = document.getElementById("current-key-im");
  const only3 = document.querySelector(".only3");
  const indicator = document.getElementById("indicator");
  if (!current || !currentHref || !currentKeyIm || !only3 || !indicator) return;

  const selfKeyIcon = document.querySelector(".rhs.t9key.entry.self img.keyicon, .lhs.t9key.entry.self img.keyicon");
  if (selfKeyIcon?.getAttribute("src")) {
    currentKeyIm.setAttribute("src", selfKeyIcon.getAttribute("src"));
  }
  current.textContent = spec.currentText;
  currentHref.setAttribute("href", shellHrefForRoute(spec.currentRoute));

  const html = await keySliderResponse(spec.searchRoute);
  only3.innerHTML = html;
  const num = only3.children.length;
  only3.style.width = `${16 * Math.max(1, num)}rem`;
  if (num === 1) indicator.classList.add("invisible");
  else indicator.classList.remove("invisible");
  refreshCompatImages(only3);
}

function scheduleKeyPageSliderSynchronization(route) {
  const spec = keySliderInitialSpecForRoute(route);
  if (!spec) return Promise.resolve();

  state.keySliderSyncSerial += 1;
  const syncSerial = state.keySliderSyncSerial;
  const syncNow = async () => {
    if (syncSerial !== state.keySliderSyncSerial) return;
    await synchronizeKeyPageSliderOnce(route);
  };

  return syncNow().then(() => {
    window.setTimeout(() => {
      void syncNow().catch((err) => {
        console.error(`key slider sync retry failed for ${route}: ${err?.stack || err?.message || err}`);
      });
    }, 900);
  });
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

async function fetchPagePayload(route) {
  const response = await fetch(routeToBundleContentUrl(route));
  if (!response.ok) {
    throw new Error(`Failed to fetch local page ${route}: ${response.status}`);
  }
  const doc = parsePageDocument(await response.text(), route);
  const inlineScripts = collectInlineBodyScripts(doc);
  return {
    html: serializeDocument(doc),
    inlineScripts,
  };
}

async function resolveBridgeResponse(route) {
  if (route === "/random/") {
    logRequest("random", route);
    return randomRouteResponse();
  }
  if (route.startsWith("/search-key-tri/")) {
    logRequest("search-key-tri", route);
    state.lastFragmentKind = "search-key-tri";
    syncDebugState();
    return keySliderResponse(route);
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
    return fetchPagePayload(route);
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
    const normalizedRoute = resolveShellNavigationRoute(request, window.location.href);
    const handled = (
      normalizedRoute === "/random/"
      || normalizedRoute.startsWith("/search-key-tri/")
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
        let inlineScripts = null;
        let responseBody = payload;
        if (
          normalizedRoute === "/index.html"
          || normalizedRoute.startsWith("/p/")
          || normalizedRoute.startsWith("/keyboard/")
          || normalizedRoute.startsWith("/eadgbe-frets/")
        ) {
          inlineScripts = payload.inlineScripts || [];
          responseBody = payload.html || "";
        }
        if (
          normalizedRoute === "/index.html"
          || normalizedRoute.startsWith("/p/")
          || normalizedRoute.startsWith("/keyboard/")
          || normalizedRoute.startsWith("/eadgbe-frets/")
        ) {
          window.__lmtCurrentPageUrlPath = canonicalPageFetchRoute(normalizedRoute).replace(/\.html$/i, "");
          window.__lmtCurrentSliderUrlPath = window.__lmtCurrentPageUrlPath;
        }
        if (success) {
          try {
            success(responseBody);
          } catch (err) {
            console.error(
              `SPA success callback failed for ${normalizedRoute}: ${err?.stack || err?.message || err}`,
            );
            deferred.reject(err);
            return;
          }
        }
        deferred.resolve(responseBody);
        requestAnimationFrame(() => {
          void (async () => {
            if (inlineScripts?.length) {
              executeInlineScripts(inlineScripts, normalizedRoute);
            }
            await scheduleKeyPageSliderSynchronization(normalizedRoute);
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
          })().catch((err) => {
            console.error(`SPA route finalization failed for ${normalizedRoute}: ${err?.stack || err?.message || err}`);
          });
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

function installSliderPathOverride() {
  if (!window.HarmoniousClient || window.HarmoniousClient.__lmtSliderPathOverrideInstalled) return;
  window.HarmoniousClient.onSliderLoad = function(onKeyPage) {
    console.log("onSliderLoad");
    window.HarmoniousClient.sliderScroll = new IScroll(".iscroller3", {
      eventPassthrough: true,
      scrollX: true,
      scrollY: false,
      mouseWheel: true,
      snap: true,
      indicators: {
        el: document.getElementById("indicator"),
        resize: false,
      },
    });
    let urlPath = null;
    if (onKeyPage) {
      urlPath = window.__lmtCurrentSliderUrlPath || document.location.pathname;
    }
    window.HarmoniousClient.keysSlider = new Slider("canvas", urlPath);
  };
  window.HarmoniousClient.__lmtSliderPathOverrideInstalled = true;
}

function installKeyboardRouteOverride() {
  if (!window.KeyboardClient || window.KeyboardClient.__lmtRouteOverrideInstalled) return;
  const originalOnLoad = window.KeyboardClient.onLoad;
  window.KeyboardClient.onLoad = function(...args) {
    const currentRoute = String(window.__lmtCurrentPageUrlPath || "");
    if (!currentRoute.startsWith("/keyboard/")) {
      return originalOnLoad.apply(this, args);
    }
    return withTemporaryVisibleRoute(currentRoute, () => originalOnLoad.apply(this, args));
  };
  window.KeyboardClient.__lmtRouteOverrideInstalled = true;
}

function installKeyboardOnPopOverride() {
  if (!window.KeyboardClient || window.KeyboardClient.__lmtOnPopOverrideInstalled) return;
  const originalOnPop = window.KeyboardClient.onPop;
  window.KeyboardClient.onPop = function(event, ...args) {
    const currentRoute = normalizedShellRouteFromValue(window.__lmtCurrentPageUrlPath || state.lastRoute || "");
    const currentFamily = interactiveRouteFamily(currentRoute || "");
    if (currentFamily !== "keyboard") {
      return originalOnPop.call(this, event, ...args);
    }
    const restoreSnapshot = historyRestoreSnapshot();
    const normalizedState = normalizePopEventState(event?.state, this.firstUrl);
    const targetRoute = resolvePopTargetRoute(normalizedState, this.firstUrl);
    const normalizedEvent = { state: normalizedState };
    const handled = withTemporaryVisibleRoute(currentRoute, () => originalOnPop.call(this, normalizedEvent, ...args), restoreSnapshot);
    if (handled && interactiveRouteFamily(targetRoute || "") === "keyboard") {
      syncInteractiveRouteState(targetRoute);
    }
    return handled;
  };
  window.KeyboardClient.__lmtOnPopOverrideInstalled = true;
}

function installFretRouteOverride() {
  if (!window.FretsClient || window.FretsClient.__lmtRouteOverrideInstalled) return;
  const originalOnLoad = window.FretsClient.onLoad;
  window.FretsClient.onLoad = function(...args) {
    const currentRoute = String(window.__lmtCurrentPageUrlPath || "");
    if (!currentRoute.startsWith("/eadgbe-frets/")) {
      return originalOnLoad.apply(this, args);
    }
    return withTemporaryVisibleRoute(currentRoute, () => originalOnLoad.apply(this, args));
  };
  window.FretsClient.__lmtRouteOverrideInstalled = true;
}

function installFretOnPopOverride() {
  if (!window.FretsClient || window.FretsClient.__lmtOnPopOverrideInstalled) return;
  const originalOnPop = window.FretsClient.onPop;
  window.FretsClient.onPop = function(event, ...args) {
    const currentRoute = normalizedShellRouteFromValue(window.__lmtCurrentPageUrlPath || state.lastRoute || "");
    const currentFamily = interactiveRouteFamily(currentRoute || "");
    if (currentFamily !== "frets") {
      return originalOnPop.call(this, event, ...args);
    }
    const restoreSnapshot = historyRestoreSnapshot();
    const normalizedState = normalizePopEventState(event?.state, this.firstUrl);
    const targetRoute = resolvePopTargetRoute(normalizedState, this.firstUrl);
    const normalizedEvent = { state: normalizedState };
    const handled = withTemporaryVisibleRoute(currentRoute, () => originalOnPop.call(this, normalizedEvent, ...args), restoreSnapshot);
    if (handled && interactiveRouteFamily(targetRoute || "") === "frets") {
      syncInteractiveRouteState(targetRoute);
    }
    return handled;
  };
  window.FretsClient.__lmtOnPopOverrideInstalled = true;
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
  installShellHistoryOverride();
  buildCompatIndex();
  installCompatImageInterceptors();
  installRequestBridge();
  installSliderPathOverride();
  installKeyboardRouteOverride();
  installKeyboardOnPopOverride();
  installFretRouteOverride();
  installFretOnPopOverride();
  window.HarmoniousClient.loadUrlBodyIntoBody = function(request) {
    const resolvedRoute = resolveShellNavigationRoute(request, window.location.href);
    renderPageRoute(resolvedRoute).catch((err) => {
      console.error(`AJAX request for URL '${request}' failed`);
      console.error(err?.stack || err?.message || String(err));
    });
  };
  refreshCompatImages(document);
  window.HarmoniousClient.onLoad_OnePageLoadEver();
  updateShellCanonical();

  const initialRoute = resolveShellNavigationRoute(window.location.href, window.location.href)
    || canonicalPageFetchRoute(window.location.pathname || HARMONIOUS_SPA_MANIFEST.homeRoute || "/index.html");
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
