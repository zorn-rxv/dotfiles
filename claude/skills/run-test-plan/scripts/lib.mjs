// Shared harness for running a manual test plan in headless Chrome.
//
// Copy this file beside a scratchpad `node_modules` that holds
// `playwright-core`: Node resolves the import below from this file's own
// folder, so importing it in place from the skill directory fails. Saved
// logins go in a `state/` folder beside it too, never in the repo under test.
//
// The defaults target verify-doctor's local dev server. Pass options to
// override them for another app.

import { chromium } from 'playwright-core';
import { existsSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));

export const BASE = 'http://localhost:4000';

// Reuse the installed Chrome, so the run downloads no browser.
export function launch() {
  return chromium.launch({ channel: 'chrome', headless: true });
}

// ── Results ──────────────────────────────────────────────

export const results = [];

// One call per Check in the plan. The log line is what the agent reads back
// to tick boxes, so the label should quote the Check.
// A promise here means a missing `await`, and it would always read as a pass.
export function check(section, label, pass, note = '') {
  if (typeof pass?.then === 'function') {
    throw new Error(`check(${section}, "${label}") got a promise: add await`);
  }
  results.push({ section, label, pass: !!pass, note });
  console.log(`${pass ? 'PASS' : 'FAIL'} [${section}] ${label}${note ? ' — ' + note : ''}`);
}

// Run one plan section, and contain its errors. Without this, one missed
// selector times out the whole script, the sections after it never run, and
// the seeded data they need may already be consumed, so the fix costs a reset
// and a full re-run. An error records a FAIL for the section and saves a
// `<n>-debug` screenshot of the last page touched, for triage.
export async function section(n, fn, { dir } = {}) {
  try {
    await fn();
  } catch (e) {
    check(n, 'section stopped on an error', false, e.message.split('\n')[0]);
    console.log(e.message);
    if (dir && lastPage && !lastPage.isClosed()) {
      try {
        await shot(lastPage, dir, `${n}-debug`);
      } catch {}
    }
  }
}

// Print the totals and a JSON line the agent can parse after the run.
export function summary(extra = {}) {
  const failed = results.filter(r => !r.pass);
  console.log(`\n${results.length - failed.length} passed, ${failed.length} failed`);
  console.log('JSON' + JSON.stringify({ ...extra, results }));
}

// ── Sessions ─────────────────────────────────────────────

// The page `section()` shoots when a section fails.
let lastPage = null;

// One browser context per account, standing in for a private window, so two
// accounts never share a cookie. The signed-in storageState is cached in
// `stateDir`, so a later session for the same account skips the login.
//
// A database reset or a logout leaves a cached cookie with no session behind
// it, and every page would then redirect away and fail its Checks. So a cached
// session first visits `homePath`, a page that needs a sign-in, and logs in
// again when the app redirects off it.
export async function session(browser, email, {
  base = BASE,
  loginPath = '/staff/login',
  homePath = '/staff/queue',
  quickLogin = '#dev-quick-login-form select',
  stateDir = join(HERE, 'state'),
} = {}) {
  mkdirSync(stateDir, { recursive: true });
  const statePath = join(stateDir, `${email.replace(/[^a-z0-9]+/gi, '_')}.json`);

  if (existsSync(statePath)) {
    const page = await openPage(browser, statePath);
    await page.goto(base + homePath);
    if (new URL(page.url()).pathname.startsWith(homePath)) return (lastPage = page);
    await page.context().close();
  }

  const page = await openPage(browser);
  await page.goto(base + loginPath);
  await connected(page);
  await page.selectOption(quickLogin, email);
  await page.waitForURL(u => !u.pathname.startsWith(loginPath), { timeout: 20000 });
  await page.context().storageState({ path: statePath });
  return (lastPage = page);
}

async function openPage(browser, statePath) {
  const ctx = await browser.newContext({
    viewport: { width: 1440, height: 900 },
    deviceScaleFactor: 2,
    ...(statePath ? { storageState: statePath } : {}),
  });
  const page = await ctx.newPage();

  // Accept every dialog and keep its wording, so a Check can assert the
  // confirm text.
  page.lastDialog = null;
  page.on('dialog', async d => {
    page.lastDialog = d.message();
    console.log(`dialog: ${d.message()}`);
    await d.accept();
  });
  return page;
}

// LiveView ignores clicks until the socket connects.
export async function connected(page) {
  await page.waitForSelector('.phx-connected');
}

// Pass `live: false` for a page LiveView doesn't render, such as the dev
// mailbox, which never gets `.phx-connected`.
export async function visit(page, path, { base = BASE, live = true } = {}) {
  lastPage = page;
  await page.goto(base + path);
  if (live) await connected(page);
}

// ── Evidence ─────────────────────────────────────────────

// Park the mouse so no hover style shows, then shoot the page or one element.
export async function shot(page, dir, name, selector) {
  mkdirSync(dir, { recursive: true });
  await page.mouse.move(0, 0);
  await page.waitForTimeout(350);
  const path = join(dir, `${name}.png`);
  if (selector) {
    const el = page.locator(selector).first();
    await el.scrollIntoViewIfNeeded();
    await el.screenshot({ path });
  } else {
    await page.screenshot({ path });
  }
}

// The flash markup carries a hidden second copy, so read only the first
// visible one. A LiveView flash renders after the server replies, so wait up
// to `timeout` ms for it. Returns null when none shows by then.
export async function flashText(page, kind, { timeout = 5000 } = {}) {
  const el = page.locator(`[id="flash-${kind}"]:visible`).first();
  try {
    await el.waitFor({ state: 'visible', timeout });
  } catch {
    return null;
  }
  return (await el.innerText()).trim();
}

// Emails from the dev mailbox. Oban delivers within a few seconds, so wait
// before comparing counts.
export async function mailbox({ base = BASE } = {}) {
  const res = await fetch(`${base}/dev/mailbox/json`);
  const body = await res.json();
  return body.data ?? body;
}
