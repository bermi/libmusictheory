const statusEl = document.getElementById("status");
const atlasGrid = document.getElementById("atlas-grid");
const summaryCardsEl = document.getElementById("summary-cards");
const summarySvgEl = document.getElementById("summary-svg");
const sourceFrame = document.getElementById("qa-source");

const TEXT_SECTION_MAP = [
  ["Pitch Class Set Operations", "out-pcs"],
  ["Set Classification APIs", "out-classification"],
  ["Scales, Modes, and Key Spelling APIs", "out-scale-mode"],
  ["Chord and Harmony APIs", "out-chord"],
  ["Guitar APIs", "out-guitar"],
];

const SVG_METHODS = [
  ["SVG Diagram APIs", "lmt_svg_clock_optc", "svg-clock"],
  ["SVG Diagram APIs", "lmt_svg_fret_n", "svg-fret"],
  ["SVG Diagram APIs", "lmt_svg_chord_staff", "svg-staff"],
];

function setStatus(message, tone = "ready") {
  statusEl.textContent = message;
  statusEl.style.color = tone === "error" ? "#b03620" : "#1d6b74";
}

function labelForIndex(index) {
  let value = index + 1;
  let out = "";
  while (value > 0) {
    value -= 1;
    out = String.fromCharCode(65 + (value % 26)) + out;
    value = Math.floor(value / 26);
  }
  return out;
}

function parseMethodLine(line) {
  const trimmed = line.trim();
  if (!trimmed) return null;
  const separator = trimmed.indexOf(":");
  if (separator === -1) {
    return { method: trimmed, output: "" };
  }
  return {
    method: trimmed.slice(0, separator).trim(),
    output: trimmed.slice(separator + 1).trim(),
  };
}

function collectTextCards(sourceDoc) {
  const cards = [];
  for (const [sectionName, elementId] of TEXT_SECTION_MAP) {
    const raw = sourceDoc.getElementById(elementId)?.textContent || "";
    const lines = raw.split("\n").map(parseMethodLine).filter(Boolean);
    for (const line of lines) {
      cards.push({
        kind: "text",
        section: sectionName,
        method: line.method,
        output: line.output,
      });
    }
  }
  return cards;
}

function collectSvgMeta(sourceDoc) {
  const raw = sourceDoc.getElementById("out-svg-meta")?.textContent || "";
  const lines = raw.split("\n").map(parseMethodLine).filter(Boolean);
  const map = new Map();
  for (const line of lines) {
    map.set(line.method, line.output);
  }
  return map;
}

function collectVisualCards(sourceDoc) {
  const meta = collectSvgMeta(sourceDoc);
  return SVG_METHODS.map(([section, method, hostId]) => {
    const host = sourceDoc.getElementById(hostId);
    const svg = host?.querySelector("svg");
    return {
      kind: "visual",
      section,
      method,
      svgMarkup: svg ? svg.outerHTML : "",
      meta: [
        meta.get(`${method} bytes`) ? `${method} bytes: ${meta.get(`${method} bytes`)}` : null,
        method === "lmt_svg_fret_n" && meta.get("string_count") ? `string_count: ${meta.get("string_count")}` : null,
        method === "lmt_svg_fret_n" && meta.get("window_start") ? `window_start: ${meta.get("window_start")}` : null,
        method === "lmt_svg_fret_n" && meta.get("visible_frets") ? `visible_frets: ${meta.get("visible_frets")}` : null,
        method === "lmt_svg_chord_staff" && meta.get("aligned") ? `aligned: ${meta.get("aligned")}` : null,
      ].filter(Boolean).join(" | "),
    };
  });
}

function renderCard(card, index) {
  const article = document.createElement("article");
  article.className = "atlas-card";
  article.dataset.kind = card.kind;
  article.dataset.method = card.method;

  const header = document.createElement("div");
  header.className = "atlas-card-header";

  const letter = document.createElement("div");
  letter.className = "atlas-letter";
  letter.textContent = labelForIndex(index);

  const textWrap = document.createElement("div");
  const section = document.createElement("p");
  section.className = "atlas-section";
  section.textContent = card.section;
  const title = document.createElement("h2");
  title.textContent = card.method;

  textWrap.append(section, title);
  header.append(letter, textWrap);
  article.append(header);

  if (card.kind === "visual") {
    const visual = document.createElement("div");
    visual.className = "atlas-visual";
    visual.innerHTML = card.svgMarkup;
    article.append(visual);
    const meta = document.createElement("p");
    meta.className = "atlas-meta";
    meta.textContent = card.meta;
    article.append(meta);
  } else {
    const output = document.createElement("pre");
    output.className = "atlas-output";
    output.textContent = card.output;
    article.append(output);
  }
  return article;
}

async function waitForSourceReady(frame) {
  const deadline = Date.now() + 300000;
  while (Date.now() < deadline) {
    const doc = frame.contentDocument;
    if (doc) {
      const status = doc.getElementById("status")?.textContent || "";
      if (status.includes("All sections rendered successfully.")) {
        return doc;
      }
      if (status.includes("Failed to initialize:") || status.includes("Error:")) {
        throw new Error(status);
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error("timed out waiting for docs source to render");
}

async function buildAtlas() {
  setStatus("Waiting for docs source render…");
  const sourceDoc = await waitForSourceReady(sourceFrame);
  const textCards = collectTextCards(sourceDoc);
  const visualCards = collectVisualCards(sourceDoc);
  const cards = [...textCards, ...visualCards];

  atlasGrid.innerHTML = "";
  cards.forEach((card, index) => {
    atlasGrid.append(renderCard(card, index));
  });

  summaryCardsEl.textContent = String(cards.length);
  summarySvgEl.textContent = String(visualCards.length);
  window.__lmtQaAtlasSummary = {
    ready: true,
    cardCount: cards.length,
    svgCount: visualCards.length,
    methods: cards.map((card, index) => ({
      label: labelForIndex(index),
      method: card.method,
      kind: card.kind,
      section: card.section,
    })),
  };
  setStatus(`QA atlas ready with ${cards.length} labeled method panels.`);
}

buildAtlas().catch((error) => {
  window.__lmtQaAtlasSummary = { ready: false, error: error.message };
  setStatus(`QA atlas failed: ${error.message}`, "error");
});
