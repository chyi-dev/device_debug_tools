// 三版各走一遍扫描 → 连接 → 订阅或写入，截 1440×900 白底。
// 需要能解析到 playwright 包；默认使用本机 Edge（PW_CHANNEL 可改）。
import { createRequire } from 'node:module';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { chromium } = require('../../../.design-tmp/node_modules/playwright');

const root = dirname(fileURLToPath(import.meta.url));
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
let failed = 0;

function check(name, what, ok) {
  if (!ok) failed += 1;
  console.log(`${ok ? 'PASS' : 'FAIL'} [${name}] ${what}`);
}

for (const name of ['pipe', 'tree', 'pin']) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });

  await page.goto(pathToFileURL(resolve(root, name + '.html')).href);
  await page.evaluate(() => localStorage.setItem('ddt.theme', 'light'));
  await page.reload();
  await page.waitForSelector('#btnScan');

  await page.click('#btnScan');
  await page.waitForTimeout(850);
  if (await page.$('[data-id="a4"]')) await page.click('[data-id="a4"]');
  check(name, '扫描到 Sensor-A4', !!(await page.$('[data-id="a4"]')));

  await page.click('#btnConnect');
  await page.waitForFunction(() => document.body.innerText.includes('CONNECTED'), { timeout: 4000 });
  check(name, '已连接 Sensor-A4', (await page.textContent('body')).includes('CONNECTED'));

  if (name === 'tree') {
    await page.click('#btnSub');
    await page.waitForTimeout(200);
    await page.click('#btnSend');
  } else if (name === 'pin') {
    await page.click('#btnSub');
    await page.waitForTimeout(120);
    await page.click('#btnPinW');
    await page.waitForTimeout(120);
    await page.click('#btnSend');
  } else {
    await page.click('#btnSend');
  }
  await page.waitForTimeout(400);
  check(name, '日志出现发送或接收', /SEND HEX>|RECV HEX>/.test(await page.textContent('body')));
  await page.evaluate(() => {
    var t = document.getElementById('toast');
    if (!t) return;
    t.className = 'toast';
    t.style.transition = 'none';
    t.style.opacity = '0';
  });
  await page.waitForTimeout(50);

  await page.screenshot({ path: resolve(root, name + '.png') });
  check(name, '无页面错误', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await page.close();
}

await browser.close();
process.exit(failed ? 1 : 0);
