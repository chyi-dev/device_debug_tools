// 主稿回归验证：右键菜单、复制、四处操作区只留主操作。
// 截图输出到本目录 master-*.png，供人工复核。
import { chromium } from 'playwright';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const master = resolve(root, '..', 'serial-console.html');
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
const errors = [];
let failed = 0;
page.on('pageerror', (e) => errors.push(e.message));
page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
const check = (what, ok) => { if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} ${what}`); };
const shot = (name) => page.screenshot({ path: resolve(root, name + '.png') });
const tab = (id) => page.click('#tabs [data-tab="' + id + '"]');
const ctxText = () => page.locator('#actCtx').innerText();

await page.goto(pathToFileURL(master).href);
await page.evaluate(() => localStorage.setItem('ddt.theme', 'light'));
await page.reload();
await page.waitForSelector('#tabbody .it');

// 快捷指令：行上只有发送和快捷键；右键出 编辑/复制/删除
const qOps = await page.locator('#tabbody .it .ops').first().innerText();
check('快捷指令行尾不含编辑删除', !/编辑|删除/.test(qOps));
await page.locator('#tabbody .it').first().click({ button: 'right' });
await page.waitForSelector('#actCtx:not([hidden])');
check('快捷指令右键 编辑/复制/删除', /编辑/.test(await ctxText()) && /复制/.test(await ctxText()) && /删除/.test(await ctxText()));
await shot('master-quick-menu');
// 点复制：出现「副本」且紧随源条目
await page.click('#actCtx [data-k="dup"]');
await page.waitForFunction(() => document.querySelectorAll('#tabbody .it').length >= 3);
const names = await page.locator('#tabbody .it .nm').allInnerTexts();
check('复制后插到源条目之后', /副本/.test(names[1] || ''));
// 文件夹：行上只有新增；右键出 重命名/删除
const fdText = await page.locator('#tabbody .fd').first().innerText();
check('文件夹行不含重命名删除', !/重命名|删除/.test(fdText));
await page.locator('#tabbody .fd').first().click({ button: 'right' });
await page.waitForSelector('#actCtx:not([hidden])');
check('文件夹右键 重命名/删除', /重命名/.test(await ctxText()) && /删除/.test(await ctxText()) && !/复制/.test(await ctxText()));
await shot('master-folder-menu');
await page.click('#log');

// 批量：下拉居左占满，顶栏留 新建/编辑/删除；右键出 复制/删除
await tab('batch');
await page.waitForSelector('#batchSel');
check('批量顶栏有危险色删除按钮', await page.locator('#tabbody .bar [data-act="batchDel"].danger').count() === 1);
const selBox = await page.locator('#batchSel').boundingBox();
const newBox = await page.locator('#tabbody .bar [data-act="batchNew"]').boundingBox();
check('批量下拉占满剩余宽度', selBox.width > 160 && newBox.x - (selBox.x + selBox.width) <= 12);
await page.locator('#tabbody .steps').click({ button: 'right' });
await page.waitForSelector('#actCtx:not([hidden])');
check('批量右键 复制/删除', /复制/.test(await ctxText()) && /删除/.test(await ctxText()) && !/编辑/.test(await ctxText()));
await shot('master-batch-menu');
await page.click('#actCtx [data-k="dup"]');
await page.waitForFunction(() => /副本/.test(document.querySelector('#batchSel').innerText));
check('批量复制后选中新任务', true);
await shot('master-batch');
// 顶栏「删除」删当前选中任务，仍走确认框
await page.click('#tabbody .bar [data-act="batchDel"]');
await page.waitForSelector('#modal.show');
check('批量删除弹确认框', /副本/.test(await page.locator('#dlgBody').innerText()));
await shot('master-batch-del');
await page.click('#dlgFoot button:has-text("删除")');
await page.waitForFunction(() => !/副本/.test(document.querySelector('#batchSel').innerText));
check('确认后副本任务已删除', true);

// 自动应答：行上只有执行；右键 编辑/复制/删除；复制出来的规则默认停用
await tab('reply');
await page.waitForSelector('#tabbody .sw');
const rOps = await page.locator('#tabbody .it .ops').first().innerText();
check('应答行尾只有执行', /执行/.test(rOps) && !/编辑|删除/.test(rOps));
await page.locator('#tabbody .it').first().click({ button: 'right' });
await page.waitForSelector('#actCtx:not([hidden])');
await shot('master-reply-menu');
await page.click('#actCtx [data-k="dup"]');
await page.waitForFunction(() => document.body.innerText.includes('副本'));
const dupOff = await page.locator('#tabbody .it', { hasText: '副本' }).first().locator('.sw.on').count();
check('应答克隆默认停用', dupOff === 0);
await shot('master-reply');

// 脚本：列表行与停靠标题栏右键 重命名/复制/删除；克隆默认停用并打开
await tab('script');
await page.waitForSelector('#scDockHead');
await page.locator('#scDockHead').click({ button: 'right' });
await page.waitForSelector('#actCtx:not([hidden])');
check('脚本右键 重命名/复制/删除', /重命名/.test(await ctxText()) && /复制/.test(await ctxText()) && /删除/.test(await ctxText()));
await shot('master-script-menu');
await page.click('#actCtx [data-k="dup"]');
await page.waitForFunction(() => document.querySelector('#scDockHead b') && document.querySelector('#scDockHead b').textContent.includes('副本'));
check('脚本克隆打开副本', (await page.locator('#scDockHead b').innerText()).includes('_副本.lua'));
await shot('master-script');

// 历史：仍是 填入/删除，不出右键菜单
await tab('history');
await page.waitForSelector('#tabbody .list.hist .it, #tabbody .explain');
const hCount = await page.locator('#tabbody .list.hist .it').count();
if (hCount) {
  const hOps = await page.locator('#tabbody .list.hist .it .ops').first().innerText();
  check('历史仍是填入/删除', /填入/.test(hOps) && /删除/.test(hOps));
  await page.locator('#tabbody .list.hist .it').first().click({ button: 'right' });
  await page.waitForTimeout(200);
  check('历史无右键菜单', await page.locator('#actCtx:not([hidden])').count() === 0);
}
await shot('master-history');

check('没有页面错误', errors.length === 0);
if (errors.length) console.log(errors.join('\n'));
await browser.close();
if (failed) process.exit(1);
