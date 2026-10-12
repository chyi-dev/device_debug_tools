// 三版各截快捷指令、批量、自动应答、脚本，并补一张菜单或操作条打开的画面。
// 需要能解析到 playwright 包；默认使用本机 Edge（PW_CHANNEL 可改）。
import { chromium } from 'playwright';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = process.argv[2] ? resolve(process.argv[2]) : dirname(fileURLToPath(import.meta.url));
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
let failed = 0;

for (const name of ['more', 'select', 'context']) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  const check = (what, ok) => { if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} [${name}] ${what}`); };
  const shot = (suffix) => page.screenshot({ path: resolve(root, name + suffix + '.png') });
  const tab = (id) => page.click('#tabs [data-tab="' + id + '"]');

  await page.goto(pathToFileURL(resolve(root, name + '.html')).href);
  await page.evaluate(() => localStorage.setItem('ddt.theme', 'light'));
  await page.reload();
  await page.waitForSelector('#tabbody .it');
  check('没有页面错误', errors.length === 0);
  await shot('-quick');

  if (name === 'more') {
    await page.click('#tabbody [data-act="menuOpen"]');
    await page.waitForSelector('#actCtx:not([hidden])');
    check('更多菜单含复制和删除', /复制/.test(await page.locator('#actCtx').innerText()) && /删除/.test(await page.locator('#actCtx').innerText()));
    await shot('-menu');
    await page.click('#log');
  }
  if (name === 'context') {
    await page.locator('#tabbody .it').first().click({ button: 'right' });
    await page.waitForSelector('#actCtx:not([hidden])');
    check('右键菜单含编辑、复制、删除', /编辑/.test(await page.locator('#actCtx').innerText()) && /复制/.test(await page.locator('#actCtx').innerText()) && /删除/.test(await page.locator('#actCtx').innerText()));
    await shot('-menu');
    await page.click('#log');
  }
  if (name === 'select') {
    await page.locator('#tabbody .it .nm').first().click();
    await page.waitForSelector('#tabbody .actbar');
    check('选中后出现操作条', /编辑/.test(await page.locator('#tabbody .actbar').innerText()) && /复制/.test(await page.locator('#tabbody .actbar').innerText()));
    await shot('-open');
  }

  await tab('batch');
  await page.waitForSelector('#batchSel');
  await shot('-batch');
  await tab('reply');
  await page.waitForSelector('#tabbody .sw');
  await shot('-reply');
  await tab('script');
  await page.waitForSelector('#scDockHead');
  check('脚本标题栏留着运行和收起', /运行/.test(await page.locator('#scDockHead').innerText()) && /收起/.test(await page.locator('#scDockHead').innerText()));
  await shot('-script');
  check('截图结束时没有页面错误', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await page.close();
}

await browser.close();
if (failed) process.exit(1);
