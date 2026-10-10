// 三版各走一遍：脚本页签、开关、运行、钩子输出；1440×900 白底截图。
// 需要能解析到 playwright 包；默认使用本机 Edge（PW_CHANNEL 可改）。
import { chromium } from 'playwright';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = process.argv[2] ? resolve(process.argv[2]) : dirname(fileURLToPath(import.meta.url));
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
let failed = 0;

for (const name of ['panel', 'dialog', 'workspace']) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  const check = (what, ok) => { if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} [${name}] ${what}`); };
  const logCount = () => page.evaluate(() => SC.log.length);

  await page.goto(pathToFileURL(resolve(root, name + '.html')).href);
  await page.evaluate(() => localStorage.setItem('ddt.theme', 'light'));
  await page.reload();
  await page.waitForTimeout(2000);
  check('默认停在脚本页签', await page.evaluate(() => ui.tab === 'script'));
  check('温湿度回包触发 onReceive 输出', (await page.evaluate(() => SC.log.some((e) => e.text.startsWith('temp=')))));

  // 启用 addChecksum，发一帧，应写入 beforeSend 输出
  await page.click('[data-act="scToggle"][data-id="s2"]');
  const n0 = await logCount();
  await page.fill('#txInput', 'A5 01 00 00 01');
  await page.click('#btnSend');
  await page.waitForTimeout(400);
  check('beforeSend 追加 SUM8 并写日志', (await page.evaluate(() => SC.log.slice(-3).some((e) => e.text.includes('追加 SUM8')))) && (await logCount()) > n0);
  check('实际发出带 SUM8 的帧', await page.evaluate(() => Serial.state.lines.some((l) => l.dir === 'tx' && Serial.hex(l.bytes) === 'A5 01 00 00 01 A7')));

  // 手动运行 parseSensor
  const n1 = await logCount();
  await page.click('[data-act="scRun"][data-id="s1"]').catch(() => {});
  if (name === 'workspace') { await page.click('.scdock [data-act="scRun"]'); }
  await page.waitForTimeout(150);
  check('手动运行写入日志', (await logCount()) > n1);

  // 切到其他页签再回来
  await page.click('#tabs [data-tab="quick"]');
  check('切走后快捷指令正常', (await page.textContent('#tabbody')).includes('读取温湿度'));
  if (name === 'workspace') check('切走后中间列收起', !(await page.evaluate(() => document.querySelector('.center').classList.contains('withdock'))));
  await page.click('#tabs [data-tab="script"]');

  if (name === 'dialog') {
    await page.click('[data-act="scEdit"][data-id="s1"]');
    check('编辑浮层打开且加宽', await page.evaluate(() => document.querySelector('#modal .dialog').classList.contains('wide')));
    await page.waitForTimeout(3200);
    await page.screenshot({ path: resolve(root, name + '-edit.png') });
    await page.keyboard.press('Escape');
    check('关闭后去掉加宽', !(await page.evaluate(() => document.querySelector('#modal .dialog').classList.contains('wide'))));
  } else {
    await page.waitForTimeout(3200);
  }
  await page.screenshot({ path: resolve(root, name + '.png') });
  check('无控制台错误', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await page.close();
}
await browser.close();
process.exit(failed ? 1 : 0);
