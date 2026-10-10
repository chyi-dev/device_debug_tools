// 三版各截一张 1440×900，并点一遍填入 / 换课。
// 用法：node doc/design/reply-tutorial-demos/shoot.mjs
import { chromium } from 'playwright';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
let failed = 0;
const check = (name, what, ok) => {
  if (!ok) failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'} [${name}] ${what}`);
};

for (const name of ['list', 'steps', 'trace']) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  await page.goto(pathToFileURL(resolve(root, name + '.html')).href);
  await page.evaluate(() => localStorage.setItem('ddt.theme', 'light'));
  await page.reload();
  await page.waitForTimeout(400);
  check(name, '停在自动应答且编辑器打开', await page.evaluate(() => ui.tab === 'reply' && document.querySelector('.dialog.wide') && !!document.getElementById('rail')));
  await page.screenshot({ path: resolve(root, name + '.png') });

  if (name === 'list') {
    check(name, '打开时匹配数据仍是空的', (await page.inputValue('#dPattern')) === '');
    check(name, '课表里同时有模板和正则', (await page.textContent('#rail')).includes('正则') && (await page.textContent('#rail')).includes('?? 抓一字节'));
    await page.click('[data-rt="fill"][data-id="wild"]');
    check(name, '填入第 3 课的模板', (await page.inputValue('#dPattern')) === 'A5 ?? *' && (await page.inputValue('#dKind')) === 'template' && (await page.inputValue('#dMatch')) === 'frame');
    await page.click('[data-rt="open"][data-id="reword"]');
    await page.click('[data-rt="fill"][data-id="reword"]');
    check(name, '换到正则后匹配方式隐藏', (await page.inputValue('#dKind')) === 'regex' && (await page.evaluate(() => document.getElementById('dMatchRow').style.display)) === 'none');
    check(name, '正则写进匹配数据', (await page.inputValue('#dPattern')).startsWith('^A5 5A'));
    await page.click('#dlgFoot .btn.pri');
    check(name, '保存后出现在规则列表', await page.evaluate(() => S.rules.some((r) => r.name === '取帧头后一字节' && r.kind === 'regex')));
    await page.click('[data-act="ruleNew"]');
    check(name, '再次打开仍有课表', await page.isVisible('#rail'));
  }

  if (name === 'steps') {
    check(name, '打开时已写入第 3 课的匹配', (await page.inputValue('#dPattern')) === 'A5 ?? *' && (await page.inputValue('#dName')) === '回传抓到的字节');
    check(name, '匹配栏被勾出来', await page.evaluate(() => document.querySelectorAll('.ruleform .hot').length >= 4));
    await page.click('[data-rt="lesson"][data-id="reascii"]');
    await page.click('[data-rt="step"][data-id="match"]');
    await page.click('[data-rt="fill"][data-id="match"]');
    check(name, '写入匹配只改语法和格式', (await page.inputValue('#dKind')) === 'regex' && (await page.inputValue('#dFormat')) === 'ASCII' && (await page.inputValue('#dPattern')) === '^OK,(.+)$');
    await page.click('[data-rt="step"][data-id="reply"]');
    await page.click('[data-rt="fill"][data-id="reply"]');
    check(name, '写入应答补上 $1', await page.evaluate(() => document.querySelector('#dLines .dd').value === '$1'));
    await page.click('[data-rt="fill"][data-id="all"]');
    check(name, '整课填入后应答还在', await page.evaluate(() => document.querySelectorAll('#dLines .line').length === 1));
  }

  if (name === 'trace') {
    check(name, '下方对照出第 3 课的发出字节', (await page.textContent('.detail')).includes('B0 11') && (await page.textContent('.detail')).includes('22 33'));
    check(name, '打开时左边仍是空规则', (await page.inputValue('#dPattern')) === '');
    await page.click('[data-rt="lesson"][data-id="groups"]');
    check(name, '换课切换对照', (await page.textContent('.detail')).includes('B1 11') && (await page.textContent('.detail')).includes('B2 22'));
    await page.click('[data-rt="lesson"][data-id="place"]');
    check(name, '四种位置的表还在', (await page.textContent('.detail')).includes('不中'));
    await page.click('[data-rt="fill"]');
    check(name, '填入包含匹配', (await page.inputValue('#dMatch')) === 'contains' && (await page.inputValue('#dPattern')) === 'A5 5A');
    await page.reload();
    await page.waitForTimeout(300);
    check(name, '填入按钮在对照区里', await page.evaluate(() => {
      var btn = document.querySelector('.detail .btn.pri');
      var pane = document.querySelector('.detail');
      if (!btn || !pane) return false;
      var a = btn.getBoundingClientRect();
      var b = pane.getBoundingClientRect();
      return a.top >= b.top - 1 && a.bottom <= b.bottom + 1;
    }));
  }

  check(name, '无控制台错误', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await page.close();
}

await browser.close();
process.exit(failed ? 1 : 0);
