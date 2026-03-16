#!/usr/bin/env node

import fs from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawn, spawnSync } from 'node:child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');
const host = process.env.LMT_VALIDATION_HOST || '127.0.0.1';
const timeoutMs = Number.parseInt(process.env.LMT_NATIVE_RGBA_PROOF_TIMEOUT_MS || '600000', 10);
const referenceRoot = process.env.LMT_HARMONIOUS_REF_ROOT || '/tmp/harmoniousapp.net';
const installDir = path.join(rootDir, 'zig-out', 'wasm-native-rgba-proof');
const requestedPort = process.env.LMT_VALIDATION_PORT ? Number.parseInt(process.env.LMT_VALIDATION_PORT, 10) : null;
const defaultKinds = ['scale', 'opc', 'optc', 'oc', 'eadgbe', 'wide-chord', 'chord-clipped', 'grand-chord', 'chord', 'center-square-text', 'vert-text-black', 'vert-text-b2t-black'];

function parseArgs(argv) {
  const out = { samplePerKind: 5, kinds: [...defaultKinds], scales: ['55:100', '200:100'] };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--sample-per-kind') {
      out.samplePerKind = Number.parseInt(argv[++i], 10);
      continue;
    }
    if (arg === '--kinds') {
      out.kinds = argv[++i].split(',').map((name) => name.trim()).filter(Boolean);
      continue;
    }
    if (arg === '--scales') {
      out.scales = argv[++i].split(',').map((name) => name.trim()).filter(Boolean);
      continue;
    }
    throw new Error(`unknown argument: ${arg}`);
  }
  if (!Number.isFinite(out.samplePerKind) || out.samplePerKind < 5) throw new Error('--sample-per-kind must be >= 5');
  if (out.scales.length === 0) throw new Error('--scales must provide at least one scale');
  return out;
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function resolvePort() {
  if (requestedPort != null) return Promise.resolve(requestedPort);
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.unref();
    server.once('error', reject);
    server.listen(0, host, () => {
      const address = server.address();
      if (!address || typeof address === 'string') {
        server.close(() => reject(new Error('failed to resolve native proof port')));
        return;
      }
      const port = address.port;
      server.close((err) => (err ? reject(err) : resolve(port)));
    });
  });
}

function ensurePlaywrightModule() {
  const toolsDir = path.join(rootDir, '.zig-cache', 'playwright-node');
  const modulePath = path.join(toolsDir, 'node_modules', 'playwright', 'index.mjs');
  if (fs.existsSync(modulePath)) return modulePath;
  fs.mkdirSync(toolsDir, { recursive: true });
  const result = spawnSync('npm', ['install', '--prefix', toolsDir, '--no-save', 'playwright@1.52.0'], {
    cwd: rootDir,
    stdio: 'inherit',
    env: { ...process.env, PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD: process.env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD || '1' },
  });
  if (result.status !== 0) throw new Error(`failed to install playwright (exit ${result.status})`);
  return modulePath;
}

function resolveBrowserExecutable() {
  const candidates = [
    process.env.LMT_PLAYWRIGHT_BROWSER_PATH,
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ].filter(Boolean);
  return candidates.find((one) => fs.existsSync(one)) || null;
}

function startServer(port) {
  const child = spawn('python3', ['-m', 'http.server', String(port), '--bind', host, '--directory', installDir], {
    cwd: installDir,
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let stderr = '';
  child.stderr.on('data', (chunk) => {
    stderr += chunk.toString();
  });
  return { child, stderrRef: () => stderr };
}

async function waitForServer(url, deadlineMs) {
  const start = Date.now();
  while (Date.now() - start < deadlineMs) {
    try {
      const response = await fetch(url);
      if (response.ok) return;
    } catch (_err) {
      // keep polling
    }
    await delay(150);
  }
  throw new Error(`timed out waiting for server at ${url}`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const pagePath = path.join(installDir, 'index.html');
  if (!fs.existsSync(pagePath)) throw new Error(`missing native RGBA proof page: ${pagePath}`);

  const playwrightPath = ensurePlaywrightModule();
  const { chromium } = await import(pathToFileURL(playwrightPath).href);
  const port = await resolvePort();
  const { child: server, stderrRef } = startServer(port);
  const cleanup = () => { if (!server.killed) server.kill('SIGTERM'); };
  process.on('exit', cleanup);

  try {
    const url = new URL(`http://${host}:${port}/index.html`);
    url.searchParams.set('kinds', args.kinds.join(','));
    url.searchParams.set('scales', args.scales.join(','));
    await waitForServer(url.toString(), 15000);

    const browser = await chromium.launch({ headless: true, ...(resolveBrowserExecutable() ? { executablePath: resolveBrowserExecutable() } : {}) });
    try {
      const page = await browser.newPage({ viewport: { width: 1600, height: 1200 } });
      await page.addInitScript(() => {
        let seed = 123456789;
        Math.random = function seededRandom() {
          seed = (1664525 * seed + 1013904223) >>> 0;
          return seed / 0x100000000;
        };
      });

      await page.goto(url.toString(), { waitUntil: 'domcontentloaded' });
      await page.waitForSelector('#run-proof', { timeout: 30000 });
      await page.fill('#ref-root', referenceRoot);
      await page.fill('#visual-sample-size', String(args.samplePerKind));
      await page.fill('#scale-list', args.scales.map((scale) => scale.replace(':', '/')).join(','));
      await page.click('#run-proof');

      const deadline = Date.now() + timeoutMs;
      while (true) {
        const snapshot = await page.evaluate(() => ({
          status: document.getElementById('status')?.textContent || '',
          progress: document.getElementById('progress')?.textContent || '',
          summary: window.__lmtLastNativeRgbaProof || null,
        }));
        if (snapshot.status.includes('Native RGBA proof failed:')) throw new Error(snapshot.status);
        if (snapshot.summary) {
          const { failures, unsupportedRows, supportedRows, compared, passing, rows } = snapshot.summary;
          const expectedRows = args.kinds.length * args.scales.length;
          if (rows.length !== expectedRows) {
            throw new Error(`native RGBA proof returned ${rows.length} rows for ${expectedRows} requested kind/scale pairs`);
          }
          const invalidSources = rows.filter((row) => row.candidateSource !== 'native-rgba');
          if (invalidSources.length > 0) {
            throw new Error(`native RGBA proof reported invalid candidate sources: ${invalidSources.map((row) => `${row.kind}@${row.scaleKey}:${row.candidateSource}`).join(', ')}`);
          }
          const missingPairs = [];
          for (const kind of args.kinds) {
            for (const scale of args.scales) {
              if (!rows.some((row) => row.kind === kind && row.scaleKey === scale)) {
                missingPairs.push(`${kind}@${scale}`);
              }
            }
          }
          if (missingPairs.length > 0) {
            throw new Error(`native RGBA proof missing requested pairs: ${missingPairs.join(', ')}`);
          }
          if (unsupportedRows !== 0) {
            const unsupportedPairs = rows.filter((row) => !row.supported).map((row) => `${row.kind}@${row.scaleKey}`);
            throw new Error(`native RGBA proof unsupported kind/scale pairs: ${unsupportedPairs.join(', ') || unsupportedRows}`);
          }
          if (supportedRows !== expectedRows) {
            throw new Error(`native RGBA proof supportedRows=${supportedRows} expectedRows=${expectedRows}`);
          }
          if (failures !== 0) throw new Error(`native RGBA proof failures=${failures}`);
          if (compared !== passing) throw new Error(`native RGBA proof compared=${compared} passing=${passing}`);
          console.log(`native RGBA proof passed: supported_rows=${supportedRows} compared=${compared} passing=${passing} scales=${args.scales.join(',')}`);
          return;
        }
        if (Date.now() > deadline) throw new Error(`timed out waiting for native RGBA proof completion; status=${snapshot.status}; progress=${snapshot.progress}`);
        await delay(1000);
      }
    } finally {
      await browser.close();
    }
  } finally {
    cleanup();
    const stderr = stderrRef().trim();
    if (stderr) process.stderr.write(`${stderr}\n`);
  }
}

main().catch((err) => {
  console.error(err.message || String(err));
  process.exit(1);
});
