// 三版各走一遍导出 / 导入 / 替换，并截对话框打开时的画面（1440×900 白底）。
// 需要能解析到 playwright 包；默认使用本机 Edge（PW_CHANNEL 可改）。
import { chromium } from 'playwright';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = process.argv[2] ? resolve(process.argv[2]) : dirname(fileURLToPath(import.meta.url));
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
let failed = 0;

// 另一台电脑导出的配置：没有批量发送；两个脚本是启用状态
const sample = {
  kind: 'device-debug-config', version: 1,
  quick: [
    { type: 'command', id: 'q1', name: '读取温湿度', data: 'A5 01 00 00 01 07', format: 'hex', key: 'F1' },
    { type: 'folder', id: 'f1', name: '产线自检', expanded: true, commands: [
      { type: 'command', id: 'q2', name: '读版本号', data: 'A5 02 00 00 02 08', format: 'hex', key: 'F2' },
      { type: 'command', id: 'q3', name: '进入测试模式', data: 'AT+TEST=1', format: 'ascii', key: 'F2' },
      { type: 'command', id: 'q4', name: '退出测试模式', data: 'AT+TEST=0', format: 'ascii', key: '' },
      { type: 'command', id: 'q5', name: '读序列号', data: 'A5 03 00 00 03 09', format: 'hex', key: '' },
    ] },
  ],
  rules: [
    { id: 'r1', name: '心跳应答', kind: 'template', match: 'frame', format: 'HEX', pattern: 'A5 80 00 00 80', enabled: true, hits: 37, replies: [{ data: 'A5 80 01 00 81', delay: 20 }] },
    { id: 'r2', name: '序号回显', kind: 'template', match: 'prefix', format: 'HEX', pattern: 'A5 30 ??', enabled: true, hits: 5, replies: [{ data: 'A5 31 $1', delay: 0 }] },
  ],
  scripts: [
    { id: 's1', name: 'parse_sensor.lua', enabled: true, code: 'function on_receive(frame)\n  log(frame:hex())\nend' },
    { id: 's2', name: 'add_crc16.lua', enabled: true, code: 'function before_send(frame)\n  return frame:append(crc16(frame))\nend' },
    { id: 's3', name: 'drop_empty.lua', enabled: false, code: 'function before_send(frame)\n  if #frame == 0 then return nil end\n  return frame\nend' },
  ],
};
const file = { name: 'line3-config.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(sample, null, 2)) };
const legacy = { name: 'quick-commands.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify(sample.quick)) };

for (const name of ['checklist', 'bundle', 'tab']) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  const check = (what, ok) => { if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} [${name}] ${what}`); };
  const menu = async (cmd) => { await page.click('.menu>button >> text=文件'); await page.click(`[data-cmd="${cmd}"]`); };
  const choose = async (open, f, modal = true) => {
    const [fc] = await Promise.all([page.waitForEvent('filechooser'), open()]);
    await fc.setFiles(f);
    if (modal) await page.waitForSelector('#modal.show'); else await page.waitForTimeout(300);
  };
  const exported = async (run) => { const [d] = await Promise.all([page.waitForEvent('download'), run()]); return JSON.parse(readFileSync(await d.path(), 'utf8')); };
  const footBtn = (text) => page.click(`#dlgFoot button:has-text("${text}")`);

  await page.goto(pathToFileURL(resolve(root, name + '.html')).href);
  await page.evaluate(() => localStorage.setItem('ddt.theme', 'light'));
  await page.reload();
  await page.waitForTimeout(1500);
  const batchBefore = await page.evaluate(() => S.batch.length);

  if (name === 'checklist') {
    check('文件菜单只剩两项配置', (await page.$$('[data-cmd="exportQuick"]')).length === 0 && !!(await page.$('[data-cmd="packExport"]')));
    await menu('packExport');
    check('导出清单四行', (await page.$$('#dlgBody .pk-row')).length === 4);
    await page.screenshot({ path: resolve(root, 'checklist-export.png') });
    await page.uncheck('#dlgBody .pk-row input[value="batch"]');
    const out = await exported(() => footBtn('导出'));
    check('导出只含勾选的三类', out.kind === 'device-debug-config' && !('batch' in out) && 'scripts' in out);

    await choose(() => menu('packImport'), file);
    check('文件里没有的批量发送被禁用', await page.isDisabled('#dlgBody .pk-row input[value="batch"]'));
    check('提示启用脚本会立即运行', (await page.textContent('#pkWarn')).includes('2 个脚本'));
    await page.waitForTimeout(2000);
    await page.screenshot({ path: resolve(root, 'checklist.png') });
    await page.uncheck('#dlgBody .pk-row input[value="rules"]');
    await footBtn('导入并替换');
    const st = await page.evaluate(() => ({ q: allQuick().length, r: S.rules.length, s: S.scripts.length, b: S.batch.length, keys: allQuick().filter((q) => q.key === 'F2').length }));
    check('快捷指令与脚本已替换', st.q === 5 && st.s === 3);
    check('未勾选的应答、文件里没有的批量保持不变', st.r === 3 && st.b === batchBefore);
    check('重复的 F2 只保留一条', st.keys === 1);

    await choose(() => menu('packImport'), legacy);
    check('旧单列表文件识别为快捷指令', (await page.textContent('#dlgBody')).includes('旧格式') && !(await page.isDisabled('#dlgBody .pk-row input[value="quick"]')) && (await page.isDisabled('#dlgBody .pk-row input[value="rules"]')));
    await page.keyboard.press('Escape');
  }

  if (name === 'bundle') {
    check('分项导入导出仍在', !!(await page.$('[data-cmd="exportQuick"]')) && !!(await page.$('[data-cmd="bundleImport"]')));
    const out = await exported(() => menu('bundleExport'));
    check('导出全部含四类', ['quick', 'rules', 'batch', 'scripts'].every((k) => Array.isArray(out[k])) && out.rules.every((r) => !('hits' in r)));
    await choose(() => menu('bundleImport'), file);
    check('对照表四行，批量写「不变」', (await page.$$('.bd-cmp tbody tr')).length === 4 && (await page.textContent('.bd-cmp tr.same')).includes('不变'));
    await page.screenshot({ path: resolve(root, 'bundle.png') });
    await footBtn('替换');
    const st = await page.evaluate(() => ({ r: S.rules.length, hits: S.rules.map((x) => x.hits), b: S.batch.length }));
    check('应答替换且命中次数归零', st.r === 2 && st.hits.every((h) => h === 0));
    check('批量保持不变', st.b === batchBefore);
  }

  if (name === 'tab') {
    await page.click('#tabs [data-tab="batch"]');
    check('批量页签标题条有导出 / 导入', !!(await page.$('#tabbody .bar [data-act="pkTabImport"]')));
    await page.screenshot({ path: resolve(root, 'tab-bar.png') });
    await choose(() => page.click('#tabbody [data-act="pkTabImport"]'), file, false);
    check('文件里没有批量时不弹框', !(await page.isVisible('#modal.show')));
    await page.click('#tabs [data-tab="script"]');
    const out = await exported(() => page.click('#tabbody [data-act="pkTabExport"]'));
    check('脚本页签只导出脚本', Object.keys(out).filter((k) => !['kind', 'version'].includes(k)).join() === 'scripts');
    await choose(() => page.click('#tabbody [data-act="pkTabImport"]'), file);
    check('单类确认写出替换条数', (await page.textContent('#dlgBody')).includes('替换当前 2'));
    await page.screenshot({ path: resolve(root, 'tab.png') });
    await footBtn('替换');
    check('只替换脚本', await page.evaluate(() => S.scripts.length === 3 && S.rules.length === 3));
  }

  check('无控制台错误', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await page.close();
}
await browser.close();
process.exit(failed ? 1 : 0);
