// 打开三版 WebSocket 调试稿：发一帧 Text、确认无页面错误，并截 1440×900。
import { createRequire } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
let chromium;
try {
  ({ chromium } = await import('playwright'));
} catch {
  ({ chromium } = require(resolve(root, '../../../.design-tmp/node_modules/playwright')));
}
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
let failed = 0;

for (const name of ['log', 'inspect', 'session']) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  const check = (what, ok) => {
    if (!ok) failed += 1;
    console.log(`${ok ? 'PASS' : 'FAIL'} [${name}] ${what}`);
  };

  await page.goto(pathToFileURL(resolve(root, name + '.html')).href);
  await page.waitForFunction(() => window.__ws && window.__ws.state.status === 'open');
  const before = await page.evaluate(() => window.__ws.state.frames.length);
  await page.click('#btnSend');
  await page.waitForFunction((n) => window.__ws.state.frames.length > n, before);
  const afterSend = await page.evaluate(() => ({
    frames: window.__ws.state.frames.length,
    last: window.__ws.state.frames.at(-1),
  }));
  check('启动为 OPEN', true);
  check('发送 Text 增加帧', afterSend.frames > before);

  if (name === 'inspect') {
    await page.locator('#rows tr').first().click();
    const pay = await page.textContent('#payload');
    check('点帧表出现载荷', /握手|101|hello|type/.test(pay || ''));
    await page.locator('#rows tr').last().click();
  }
  if (name === 'session') {
    await page.click('#filters [data-f="control"]');
    const text = await page.textContent('#log');
    check('控制过滤能看到 PING', /PING/.test(text || ''));
    await page.click('#filters [data-f="all"]');
  }

  await page.waitForTimeout(250);
  await page.screenshot({ path: resolve(root, name + '.png'), fullPage: false });

  await page.click('#btnOpen');
  await page.waitForFunction(() => window.__ws.state.status === 'closed');
  await page.click('#btnSend');
  const toast = await page.locator('#toast').innerText();
  check('未连接拦截发送', /拦截/.test(toast || ''));
  check('没有页面错误', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await page.close();
}

await browser.close();
if (failed) process.exitCode = 1;
