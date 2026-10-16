import { createRequire } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const require = createRequire(import.meta.url);
const { chromium } = require('../../.design-tmp/node_modules/playwright');
const root = dirname(fileURLToPath(import.meta.url));
const variants = ['a', 'b', 'c'];
const browser = await chromium.launch();
let failed = false;

for (const variant of variants) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(message.text());
  });

  const htmlPath =
    variant === 'a'
      ? resolve(root, 'option-a', 'index.html')
      : resolve(root, `multi-console-${variant}.html`);
  await page.goto(pathToFileURL(htmlPath).href);
  await page.waitForFunction(() => window.__workbench?.state?.profiles?.length === 4);

  const state = await page.evaluate(() => ({
    kinds: window.__workbench.state.profiles.map((profile) => profile.kind),
    toolCounts: window.__workbench.state.profiles.map((profile) => ({
      quick: profile.quick.length,
      batch: profile.batches.length,
      reply: profile.replies.length,
      scripts: profile.scripts.length,
    })),
  }));

  const kindsOk = ['serial', 'ble', 'mqtt', 'ws'].every((kind) =>
    state.kinds.includes(kind),
  );
  const toolsOk = state.toolCounts.every(
    (value) =>
      value.quick > 0 &&
      value.batch > 0 &&
      value.reply > 0 &&
      value.scripts > 0,
  );

  const tabs = await page.locator('[data-action="tool-tab"]').count();
  const settingsCoverage = await page.evaluate(() => {
    const wb = window.__workbench;
    const expected = {
      serial: '分包超时',
      ble: '分片间隔 ms',
      mqtt: 'Session Expiry',
      ws: 'Per-message Deflate',
    };
    return wb.state.profiles.every((profile) => {
      wb.state.activeId = profile.id;
      wb.render();
      return document.body.innerText.includes(expected[profile.kind]);
    });
  });
  const toolCoverage = await page.evaluate(() => {
    const wb = window.__workbench;
    const profile = wb.state.profiles[0];
    wb.state.activeId = profile.id;
    const expected = {
      quick: '当前连接专属',
      batch: '每一步可覆盖协议目标',
      reply: '模板 / 正则',
      history: '仅记录手动发送',
      calc: 'CRC16',
      script: 'before_send',
    };
    return Object.entries(expected).every(([tool, text]) => {
      profile.activeTool = tool;
      wb.render();
      return document.body.innerText.includes(text);
    });
  });
  await page.evaluate(() => {
    const wb = window.__workbench;
    wb.state.activeId = wb.state.profiles[0].id;
    wb.state.profiles[0].activeTool = 'quick';
    wb.render();
  });
  const sendBefore = await page.evaluate(
    () => window.__workbench.state.profiles[0].history.length,
  );
  await page.locator('[data-action="send"]').last().click();
  const sendAfter = await page.evaluate(
    () => window.__workbench.state.profiles[0].history.length,
  );

  await page.screenshot({
    path:
      variant === 'a'
        ? resolve(root, 'option-a', 'preview.png')
        : resolve(root, `multi-console-${variant}.png`),
    fullPage: false,
  });

  let addOk = true;
  if (variant === 'a') {
    const before = await page.evaluate(() => window.__workbench.state.profiles.length);
    await page.locator('[data-action="add-menu"]').click();
    const opened = await page.evaluate(() => ({
      count: window.__workbench.state.profiles.length,
      open: window.__workbench.state.addMenuOpen,
      labels: [...document.querySelectorAll('.mw-add-item')].map((node) => node.textContent),
    }));
    const menuBox = await page.locator('.mw-add-menu').boundingBox();
    const menuVisible = await page.evaluate(() => {
      const menu = document.querySelector('.mw-add-menu');
      const rect = menu.getBoundingClientRect();
      const hit = document.elementFromPoint(rect.left + 24, rect.top + 18);
      return !!hit && menu.contains(hit);
    });
    await page.locator('[data-action="add-profile"][data-kind="mqtt"]').click();
    const created = await page.evaluate(() => {
      const wb = window.__workbench;
      const active = wb.state.profiles.find((profile) => profile.id === wb.state.activeId);
      return {
        count: wb.state.profiles.length,
        kind: active && active.kind,
        open: wb.state.addMenuOpen,
      };
    });
    addOk =
      opened.count === before &&
      opened.open &&
      opened.labels.length === 4 &&
      menuBox &&
      menuBox.height > 80 &&
      menuVisible &&
      created.count === before + 1 &&
      created.kind === 'mqtt' &&
      !created.open;
  }

  const ok =
    kindsOk &&
    toolsOk &&
    settingsCoverage &&
    toolCoverage &&
    tabs >= 6 &&
    sendAfter === sendBefore + 1 &&
    addOk &&
    errors.length === 0;
  console.log(
    `${ok ? 'PASS' : 'FAIL'} ${variant.toUpperCase()} ` +
      `protocols=${kindsOk} settings=${settingsCoverage} tools=${toolsOk && toolCoverage} ` +
      `tabs=${tabs} send=${sendAfter > sendBefore} add=${addOk}`,
  );
  if (errors.length) console.log(errors.join('\n'));
  failed ||= !ok;
  await page.close();
}

await browser.close();
if (failed) process.exitCode = 1;
