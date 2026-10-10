// 三版各走一遍授权主流程并截 1440×900 白底图。
// 需要能解析到 playwright 包；默认使用本机 Edge（PW_CHANNEL 可改）。第一个参数可指定 html 所在目录。
import { chromium } from 'playwright';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = process.argv[2] ? resolve(process.argv[2]) : dirname(fileURLToPath(import.meta.url));
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
const WRONG = 'DDT1-0000-19C8-7B03-E6D1';
const VALID = 'DDT1-4F2A-19C8-7B03-E6D1';
let failed = 0;

for (const name of ['tab', 'bar', 'panel']) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  const check = (what, ok) => { if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} [${name}] ${what}`); };
  const shot = (suffix) => page.screenshot({ path: resolve(root, name + suffix + '.png') });

  await page.goto(pathToFileURL(resolve(root, name + '.html')).href);
  await page.evaluate((n) => { localStorage.setItem('ddt.theme', 'light'); localStorage.setItem('ddt.license.' + n, 'expired'); }, name);
  await page.reload();
  await page.waitForTimeout(1800);
  check('状态栏显示试用已结束', (await page.textContent('#stLic')).includes('试用已结束'));
  check('自动应答已暂停', (await page.textContent('#stReply')).startsWith('自动应答 0/'));
  await shot('');

  if (name === 'tab') {
    check('落在校验计算页', await page.evaluate(() => ui.tab === 'calc'));
    await page.click('#tabs [data-tab="quick"]');
  }
  if (name === 'bar') {
    await page.click('#tabs [data-tab="quick"]');
    check('被锁页签仍可查看', await page.evaluate(() => ui.tab === 'quick'));
    await page.click('#tabbody [data-act="quickSend"]');
    check('点被锁的发送弹出授权', await page.isVisible('#modal.show'));
    await page.keyboard.press('Escape');
    await page.click('#lkBar [data-act="licOpen"]');
  }
  if (name === 'panel') {
    check('右栏是授权页', await page.evaluate(() => ui.tab === 'license'));
    await page.fill('#licCode', WRONG);
    await page.click('[data-act="licActivate"]');
    check('不匹配时栏内红字', (await page.textContent('#licErr')).includes('不属于本机'));
    await shot('-error');
    await page.fill('#licCode', VALID);
    await page.click('[data-act="licActivate"]');
  } else {
    check('弹出授权对话框', await page.isVisible('#modal.show'));
    await shot('-dialog');
    await page.fill('#licCode', 'abc');
    await page.click('#dlgFoot .pri');
    check('格式不对时对话框不关', (await page.textContent('#dlgErr')).includes('格式不对'));
    await page.fill('#licCode', VALID.toLowerCase().replace(/-/g, ''));
    check('输入自动分组大写', (await page.inputValue('#licCode')) === VALID);
    await page.click('#dlgFoot .pri');
  }
  check('激活后显示已授权', (await page.textContent('#stLic')).includes('已授权'));
  check('激活后自动应答恢复', !(await page.textContent('#stReply')).startsWith('自动应答 0/'));
  await page.click('#tabs [data-tab="quick"]');
  check('激活后可切到快捷指令', await page.evaluate(() => ui.tab === 'quick'));
  check('无脚本错误', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await page.close();
}

await browser.close();
if (failed) { console.log(failed + ' 项失败'); process.exit(1); }
