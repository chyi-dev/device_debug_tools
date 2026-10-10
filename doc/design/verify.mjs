// 走一遍串口调试台主流程并截图白底 / 黑底：node doc/design/verify.mjs
// 需要能解析到 playwright 包；默认使用本机 Edge（PW_CHANNEL 可改）。
import { chromium } from 'playwright';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = process.argv[2] ? resolve(process.argv[2]) : dirname(fileURLToPath(import.meta.url));
const file = resolve(root, 'serial-console.html');
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
const checks = [];
const check = (name, ok) => { checks.push([name, ok]); console.log((ok ? 'PASS ' : 'FAIL ') + name); };
const st = () => page.evaluate(() => ({ rx: Serial.state.rx, tx: Serial.state.tx, open: Serial.state.open, hits: Serial.state.rules.map((r) => r.hits), lines: Serial.state.lines.length }));

await page.goto(pathToFileURL(file).href);
await page.evaluate(() => localStorage.removeItem('ddt.theme'));
await page.reload();
await page.waitForTimeout(2200);
check('启动后串口已打开且有收发', (await st()).open && (await st()).rx > 0);
check('上线帧触发自动应答', (await st()).hits[1] > 0);

const before = await st();
await page.keyboard.press('F1');
await page.waitForTimeout(500);
const after = await st();
check('F1 快捷指令发出并收到回包', after.tx > before.tx && after.rx > before.rx);
check('温湿度回包命中应答规则', after.hits[0] > before.hits[0]);
check('日志区显示 RECV 记录', (await page.textContent('#log')).includes('RECV HEX>'));

await page.check('[name=rxFmt][value=ASCII]');
check('切换 ASCII 显示', (await page.textContent('#log')).includes('RECV ASCII>'));
await page.check('[name=rxFmt][value=HEX]');

await page.check('#txLoop');
await page.fill('#txPeriod', '150');
const loop0 = (await st()).tx;
await page.click('#btnSend');
await page.waitForTimeout(700);
check('循环发送按钮变为停止', (await page.textContent('#btnSend')).includes('停止'));
await page.click('#btnSend');
const loop1 = (await st()).tx;
await page.waitForTimeout(400);
check('循环发送多次且可停止', loop1 - loop0 >= 3 * 6 && (await st()).tx - loop1 <= 6 * 2);
await page.uncheck('#txLoop');

await page.click('[data-tab=calc]');
await page.fill('#calcInput', '01 03 00 00 00 01');
check('校验计算 CRC16 MODBUS', (await page.textContent('#calcTable')).includes('84 0A'));

await page.click('[data-tab=batch]');
await page.click('[data-act=batchRun]');
await page.waitForTimeout(1300);
check('批量发送三条指令完成', (await page.evaluate(() => Serial.state.lines.filter((l) => l.text.includes('批量任务「传感器启动流程」完成')).length)) === 1);

await page.click('[data-tab=reply]');
await page.click('[data-act=ruleEdit]');
check('应答课表默认收起', (await page.$('#rail')) === null);
await page.click('#rtToggle');
check('应答课表在编辑器右侧', (await page.textContent('#rail')).includes('正则') && (await page.textContent('#rail')).includes('?? 抓一字节'));
await page.click('#dAdd');
await page.click('#dlgFoot .btn.pri');
check('空应答数据被对话框拦下', (await page.textContent('#dlgErr')).includes('HEX'));
await page.keyboard.press('Escape');
await page.click('[data-act=ruleNew]');
check('重新打开时课表收起', (await page.$('#rail')) === null);
await page.click('#rtToggle');
await page.click('[data-rt="fill"][data-id="wild"]');
await page.click('#rtToggle');
check('收起课表后表单保留', (await page.$('#rail')) === null && (await page.inputValue('#dPattern')) === 'A5 ?? *');
check('课表填入 ?? 模板', (await page.inputValue('#dPattern')) === 'A5 ?? *' && (await page.inputValue('#dMatch')) === 'frame');
await page.keyboard.press('Escape');

await page.click('[data-tab=history]');
check('历史发送有记录', (await page.$$('.hist .it')).length > 0);

await page.click('[data-tab=quick]');
await page.check('#sigDtr');
check('DTR 回环点亮 DSR', await page.evaluate(() => document.getElementById('pinDsr').classList.contains('on')));
const side = await page.evaluate(() => { const s = document.querySelector('.side'); s.scrollTop = 0; return [s.scrollHeight, s.clientHeight]; });
console.log('左栏内容高度 / 可视高度：' + side.join(' / '));
await page.waitForTimeout(400);
await page.screenshot({ path: resolve(root, 'serial-console-light.png') });

await page.click('[data-tab=script]');
await page.click('[data-act=tutView][data-id=tut]');
await page.click('[data-act=tutOpen][data-id=l3]');
await page.click('[data-act=tutTry][data-id=l3]');
check('教程样例试跑写进运行日志', (await page.textContent('#scLog')).includes('温度 24.6℃'));
await page.screenshot({ path: resolve(root, 'serial-console-tutorial.png') });
await page.click('[data-act=tutNew][data-id=l3]');
check('用课新建脚本并打开编辑区', (await page.inputValue('#scCode')).includes('starts_with') && (await page.textContent('#scList')).includes('lesson3_parse.lua'));
await page.click('[data-tab=quick]');

const fileMenu = async (cmd) => { await page.click('.menu:nth-of-type(1)>button'); await page.click(`[data-cmd=${cmd}]`); };
await fileMenu('packExport');
await page.uncheck('#dlgBody .pk-row input[value=batch]');
const [dl] = await Promise.all([page.waitForEvent('download'), page.click('#dlgFoot .btn.pri')]);
const pack = JSON.parse(readFileSync(await dl.path(), 'utf8'));
check('导出配置只含勾选的类别', pack.kind === 'device-debug-config' && !('batch' in pack) && pack.scripts.length > 0);
const counts = () => page.evaluate(() => ({ s: S.scripts.length, b: S.batch.length }));
const c0 = await counts();
const incoming = JSON.stringify({ kind: 'device-debug-config', version: 1, scripts: [{ name: 'only.lua', code: '', enabled: true }] });
const [fc] = await Promise.all([page.waitForEvent('filechooser'), fileMenu('packImport')]);
await fc.setFiles({ name: 'cfg.json', mimeType: 'application/json', buffer: Buffer.from(incoming) });
await page.waitForSelector('#modal.show');
check('导入清单禁用文件里没有的类别并提示启用脚本', (await page.isDisabled('#dlgBody .pk-row input[value=quick]')) && (await page.textContent('#pkWarn')).includes('1 个脚本'));
await page.click('#dlgFoot .btn.pri');
const c1 = await counts();
check('导入只替换脚本', c1.s === 1 && c1.b === c0.b);

await page.click('#btnOpen');
await page.click('#btnSend');
check('关闭串口后发送被拦下', (await page.textContent('#toast')).includes('串口未打开'));
await page.click('#btnOpen');
await page.waitForTimeout(1500);

await page.click('.menu:nth-of-type(2)>button');
await page.click('[data-cmd=themeDark]');
await page.waitForTimeout(300);
await page.screenshot({ path: resolve(root, 'serial-console-dark.png') });

await browser.close();
console.log(errors.length ? 'PAGE ERRORS: ' + errors.join(' | ') : 'no page errors');
process.exit(errors.length || checks.some((c) => !c[1]) ? 1 : 0);
