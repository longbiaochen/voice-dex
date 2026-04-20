#!/usr/bin/env node

import { execFile as execFileCallback } from "node:child_process";
import { existsSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { promisify } from "node:util";

const execFile = promisify(execFileCallback);

const COMPOSE_URL = process.env.CHROME_USE_POST_URL || "https://x.com/compose/post";
const OPEN_WAIT_MS = Number.parseInt(process.env.CHROME_USE_POST_OPEN_WAIT_MS || "1500", 10);
const PUBLISH_TIMEOUT_MS = Number.parseInt(process.env.CHROME_USE_POST_PUBLISH_TIMEOUT_MS || "30000", 10);
const POLL_INTERVAL_MS = 1000;

function usage() {
  console.error(`Usage:
  post_x_via_chrome_use.mjs --text "post text" [--print]

Options:
  --text <text>   Post text to publish.
  --print         Print the resolved chrome-use workflow without sending the post.`);
}

function parseArgs(argv) {
  let text = "";
  let printOnly = false;

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    switch (arg) {
      case "--text":
        text = argv[index + 1] || "";
        index += 1;
        break;
      case "--print":
        printOnly = true;
        break;
      case "-h":
      case "--help":
        usage();
        process.exit(0);
      default:
        throw new Error(`unknown option: ${arg}`);
    }
  }

  if (!text) {
    throw new Error("missing --text value");
  }

  return { text, printOnly };
}

function resolveChromeAuthPaths() {
  const skillDir = process.env.CHROME_AUTH_SKILL_DIR || path.join(os.homedir(), ".codex", "skills", "chrome-auth");
  const openUrlPath = path.join(skillDir, "scripts", "open_url.sh");
  const authCdpPath = path.join(skillDir, "scripts", "auth-cdp");

  if (!existsSync(openUrlPath)) {
    throw new Error(`chrome-auth open_url.sh not found at ${openUrlPath}`);
  }
  if (!existsSync(authCdpPath)) {
    throw new Error(`chrome-auth auth-cdp not found at ${authCdpPath}`);
  }

  return { skillDir, openUrlPath, authCdpPath };
}

async function runCommand(file, args) {
  try {
    const { stdout, stderr } = await execFile(file, args, {
      maxBuffer: 10 * 1024 * 1024,
      env: process.env,
    });
    return { stdout: stdout.trim(), stderr: stderr.trim() };
  } catch (error) {
    const stdout = typeof error.stdout === "string" ? error.stdout.trim() : "";
    const stderr = typeof error.stderr === "string" ? error.stderr.trim() : "";
    const details = [stderr, stdout].filter(Boolean).join("\n");
    throw new Error(details || error.message);
  }
}

async function runJSON(file, args) {
  const { stdout } = await runCommand(file, args);
  try {
    return JSON.parse(stdout);
  } catch (error) {
    throw new Error(`Failed to parse JSON from ${path.basename(file)} ${args.join(" ")}\n${stdout}`);
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function normalizeText(value) {
  return String(value || "").replace(/\s+/g, " ").trim().toLowerCase();
}

function textSnippet(value) {
  return normalizeText(value).slice(0, 80);
}

function isStatusURL(value) {
  return /^https:\/\/(?:x|twitter)\.com\/[^/]+\/status\/\d+/i.test(String(value || ""));
}

function normalizeCandidateURL(value) {
  if (!value) {
    return "";
  }
  if (value.startsWith("http://") || value.startsWith("https://")) {
    return value;
  }
  if (value.startsWith("/")) {
    return `https://x.com${value}`;
  }
  return "";
}

function matchesTargetPage(page) {
  const url = String(page?.url || "");
  return url.includes("x.com") || url.includes("twitter.com");
}

function pickTargetPage(beforePages, afterPayload) {
  const afterPages = Array.isArray(afterPayload?.pages) ? afterPayload.pages : [];
  const beforeIDs = new Set((beforePages || []).map((page) => page.id));
  const newPages = afterPages.filter((page) => page?.id && !beforeIDs.has(page.id));
  const preferred = [...newPages, ...afterPages].filter(matchesTargetPage);

  return preferred.at(-1) || afterPayload?.selectedPage || afterPages.at(-1) || null;
}

async function authJSON(authCdpPath, command, extraArgs = []) {
  return runJSON(authCdpPath, [command, ...extraArgs]);
}

async function authFind(authCdpPath, bindingId, selector) {
  return authJSON(authCdpPath, "find", ["--selector", selector, "--binding-id", bindingId]);
}

async function authSnapshot(authCdpPath, bindingId) {
  return authJSON(authCdpPath, "snapshot", ["--mode", "dom", "--binding-id", bindingId]);
}

async function detectLoginPage(authCdpPath, bindingId, snapshot = null) {
  const pageURL = snapshot?.page?.url || "";
  if (pageURL.includes("/i/flow/login") || pageURL.endsWith("/login")) {
    return true;
  }
  const loginLink = await authFind(authCdpPath, bindingId, "a[href='/login']");
  return Boolean(loginLink?.found);
}

async function waitForSelector(authCdpPath, bindingId, selectors, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    for (const selector of selectors) {
      const result = await authFind(authCdpPath, bindingId, selector);
      if (result?.found && result.visible !== false && result.disabled !== true) {
        return { selector, result };
      }
    }
    await sleep(POLL_INTERVAL_MS);
  }
  return null;
}

function extractStatusURL(snapshot) {
  const direct = normalizeCandidateURL(snapshot?.page?.url || "");
  if (isStatusURL(direct)) {
    return direct;
  }

  const interactive = Array.isArray(snapshot?.snapshot?.interactive) ? snapshot.snapshot.interactive : [];
  for (const item of interactive) {
    const candidate = normalizeCandidateURL(item?.href || "");
    if (isStatusURL(candidate)) {
      return candidate;
    }
  }

  return "";
}

function bodyContainsSnippet(snapshot, expectedText) {
  const snippet = textSnippet(expectedText);
  if (!snippet) {
    return true;
  }
  const body = normalizeText(snapshot?.snapshot?.bodyTextSample || "");
  return body.includes(snippet);
}

async function waitForPublishedPost(authCdpPath, bindingId, postText) {
  const deadline = Date.now() + PUBLISH_TIMEOUT_MS;
  let lastSnapshot = null;

  while (Date.now() < deadline) {
    const snapshot = await authSnapshot(authCdpPath, bindingId);
    lastSnapshot = snapshot;

    if (await detectLoginPage(authCdpPath, bindingId, snapshot)) {
      throw new Error("X login is required in Chrome for Testing before posting. Complete the login in the managed browser session and rerun the command.");
    }

    const candidateURL = extractStatusURL(snapshot);
    if (candidateURL && bodyContainsSnippet(snapshot, postText)) {
      return candidateURL;
    }

    await sleep(POLL_INTERVAL_MS);
  }

  const lastURL = lastSnapshot?.page?.url || "unknown";
  const sample = lastSnapshot?.snapshot?.bodyTextSample || "";
  throw new Error(`Timed out waiting for a verified X post URL. Last page: ${lastURL}\nBody sample: ${sample}`);
}

async function main() {
  const { text, printOnly } = parseArgs(process.argv.slice(2));
  const { skillDir, openUrlPath, authCdpPath } = resolveChromeAuthPaths();

  if (printOnly) {
    console.log(`Resolved workflow:
  transport: chrome-use
  browser: Chrome for Testing
  skill_dir: ${skillDir}
  open_url: ${openUrlPath}
  auth_cdp: ${authCdpPath}
  compose_url: ${COMPOSE_URL}
  verification: published post URL + matching body text`);
    return;
  }

  const beforePages = await authJSON(authCdpPath, "list-pages");
  await runCommand(openUrlPath, [COMPOSE_URL]);
  await sleep(OPEN_WAIT_MS);
  const afterPages = await authJSON(authCdpPath, "list-pages");

  const targetPage = pickTargetPage(beforePages.pages, afterPages);
  if (!targetPage?.id) {
    throw new Error("Could not find the X compose page in the Chrome for Testing session.");
  }

  const binding = await authJSON(authCdpPath, "bind-page", ["--page-id", targetPage.id]);
  const bindingId = binding?.binding?.bindingId;
  if (!bindingId) {
    throw new Error("Failed to bind the X compose page in Chrome for Testing.");
  }

  if (!matchesTargetPage(targetPage)) {
    try {
      await authJSON(authCdpPath, "navigate", ["--url", COMPOSE_URL, "--binding-id", bindingId]);
    } catch {
      // X can briefly stall its page-ready signal; keep going and inspect the bound page directly.
    }
  }

  const initialSnapshot = await authSnapshot(authCdpPath, bindingId);
  if (await detectLoginPage(authCdpPath, bindingId, initialSnapshot)) {
    throw new Error("X login is required in Chrome for Testing before posting. Complete the login in the managed browser session and rerun the command.");
  }

  const composer = await waitForSelector(
    authCdpPath,
    bindingId,
    [
      '[data-testid="tweetTextarea_0"]',
      'div[role="textbox"]',
      '[contenteditable="true"][role="textbox"]',
    ],
    10000
  );
  if (!composer) {
    throw new Error("Could not find the X post composer in Chrome for Testing.");
  }

  const fillResult = await authJSON(authCdpPath, "fill", [
    "--selector", composer.selector,
    "--text", text,
    "--binding-id", bindingId,
  ]);
  if (!fillResult?.updated) {
    throw new Error(`Failed to fill the X composer: ${fillResult?.reason || "unknown_reason"}`);
  }

  const postButton = await waitForSelector(
    authCdpPath,
    bindingId,
    [
      'button[data-testid="tweetButton"]',
      'button[data-testid="tweetButtonInline"]',
    ],
    10000
  );
  if (!postButton) {
    throw new Error("Could not find an enabled X post button in Chrome for Testing.");
  }

  const clickResult = await authJSON(authCdpPath, "click", [
    "--selector", postButton.selector,
    "--binding-id", bindingId,
  ]);
  if (!clickResult?.clicked) {
    throw new Error(`Failed to click the X post button: ${clickResult?.reason || "unknown_reason"}`);
  }

  const postURL = await waitForPublishedPost(authCdpPath, bindingId, text);
  console.log(`Posted and verified on X via chrome-use.\nURL: ${postURL}`);
}

main().catch((error) => {
  console.error(error.message || String(error));
  process.exit(1);
});
