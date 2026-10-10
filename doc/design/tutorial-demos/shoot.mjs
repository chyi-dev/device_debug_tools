// 三版各走一遍主操作并截 1440×900 白底图。
// 需要能解析到 playwright 包；默认使用本机 Edge（PW_CHANNEL 可改）。第一个参数可指定 html 所在目录。
import { chromium } from 'playwright';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = process.argv[2] ? resolve(process.argv[2]) : dirname(fileURLToPath(import.meta.url));
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
let failed = 0;

for (const name of ['list', 'book', 'pick']) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  const check = (what, ok) => { if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} [${name}] ${what}`); };
  const lastLog = () => page.evaluate(() => S.scriptLog.slice(-1)[0]?.text || '');

  await page.goto(pathToFileURL(resolve(root, name + '.html')).href);
  await page.evaluate(() => localStorage.setItem('ddt.theme', 'light'));
  await page.reload();
  await page.waitForTimeout(1500);
  check('默认停在脚本页签', await page.evaluate(() => ui.tab === 'script'));

  if (name === 'list') {
    await page.click('[data-act="tutTry"][data-id="l3"]');
    check('样例试跑写出温湿度', (await lastLog()).includes('24.6'));
    await page.screenshot({ path: resolve(root, name + '.png') });
    await page.click('[data-act="tutNew"][data-id="l3"]');
    check('用课新建并打开编辑器', (await page.inputValue('#scCode')).includes('starts_with'));
    check('回到我的脚本', await page.evaluate(() => tutUi.view === 'mine'));
  }
  if (name === 'book') {
    await page.click('#scDock [data-act="bookTry"]');
    check('样例试跑内联显示', (await page.textContent('#tutPane')).includes('24.6'));
    await page.screenshot({ path: resolve(root, name + '.png') });
    await page.click('#scDock [data-act="bookGo"][data-id="1"]');
    check('翻到第 4 课', (await page.textContent('#tutPane')).includes('发送前补校验'));
    await page.click('#scDock [data-act="bookInsert"]');
    check('插入到编辑器', (await page.inputValue('#scCode')).includes('sum8'));
    await page.click('#scDock [data-act="bookPane"][data-id="log"]');
    check('切回运行日志', await page.isVisible('#scLog'));
  }
  if (name === 'pick') {
    await page.screenshot({ path: resolve(root, name + '.png') });
    await page.click('[data-act="scNew"]');
    await page.click('[data-card="l6"]');
    await page.waitForTimeout(300);
    await page.screenshot({ path: resolve(root, name + '-new.png') });
    await page.click('#dlgFoot .btn.pri');
    check('按所选课新建', (await page.inputValue('#scCode')).includes('crc16'));
    await page.click('[data-act="pickInsert"][data-id="l5"]');
    check('片段插入到末尾', (await page.inputValue('#scCode')).trim().endsWith('return frame\nend'));
  }

  await page.click('#tabs [data-tab="quick"]');
  check('切走后中间列收起', !(await page.evaluate(() => document.querySelector('.center').classList.contains('withdock'))));
  check('无控制台错误', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await page.close();
}
await browser.close();
process.exit(failed ? 1 : 0);
