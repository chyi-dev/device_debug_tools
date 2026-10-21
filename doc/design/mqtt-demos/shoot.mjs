// 三版各走一遍连接 / 发布 / 查看报文，并截 1440×900。
// 需要能解析到 playwright 包；默认使用本机 Edge（PW_CHANNEL 可改）。
import { createRequire } from 'node:module';
import { existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const playwrightRoot = [
  resolve(here, '../../../.design-tmp/node_modules/playwright'),
  'playwright'
].find((p) => p === 'playwright' || existsSync(p));
const { chromium } = createRequire(import.meta.url)(playwrightRoot);

const root = here;
const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
let failed = 0;

for (const name of ['inherit', 'tree', 'stream']) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  const check = (what, ok) => {
    if (!ok) failed += 1;
    console.log(`${ok ? 'PASS' : 'FAIL'} [${name}] ${what}`);
  };

  await page.goto(pathToFileURL(resolve(root, name + '.html')).href);
  await page.waitForFunction(() => window.MqttDemo && window.MqttDemo.state);
  const start = await page.evaluate(() => ({
    open: window.MqttDemo.state.connected,
    n: window.MqttDemo.state.messages.length,
    topic: document.body.innerText.includes('device/room1/telemetry')
  }));
  check('启动后已连接且有演示报文', start.open && start.n >= 4 && start.topic);

  if (name === 'inherit') {
    const beforeFill = await page.evaluate(() => ({
      n: window.MqttDemo.state.messages.length,
      topic: window.MqttDemo.state.pub.topic,
      payload: window.MqttDemo.state.pub.payload
    }));
    check('默认发送 Topic 是指示灯', beforeFill.topic === 'device/demo/command');
    await page.locator('.ptopic[data-id="t2"] button[data-act="fill-topic"]').click();
    const afterFill = await page.evaluate(() => ({
      n: window.MqttDemo.state.messages.length,
      topic: window.MqttDemo.state.pub.topic,
      payload: window.MqttDemo.state.pub.payload
    }));
    check('填入读遥测只改 Topic 不发送', afterFill.topic === 'device/room1/command' && afterFill.n === beforeFill.n && afterFill.payload === beforeFill.payload);
  }

  await page.screenshot({ path: resolve(root, name + '.png') });

  await page.click('[data-act="select"]');
  const selected = await page.evaluate(() => window.MqttDemo.state.selectedId);
  check('点开一条报文', !!selected);

  const beforePub = await page.evaluate(() => window.MqttDemo.state.messages.length);
  await page.click('[data-act="pub"]');
  await page.waitForTimeout(350);
  const afterPub = await page.evaluate(() => ({
    n: window.MqttDemo.state.messages.length,
    ack: window.MqttDemo.state.messages.some((m) => m.topic === 'device/ack')
  }));
  check('发布后收到 ack', afterPub.n >= beforePub + 2 && afterPub.ack);

  await page.click('[data-act="toggle"]');
  const closed = await page.evaluate(() => window.MqttDemo.state.connected);
  check('可以断开', closed === false);
  await page.click('[data-act="pub"]');
  await page.waitForTimeout(80);
  const blocked = await page.evaluate(() => document.body.innerText.includes('未连接') && document.body.innerText.includes('拦截'));
  check('未连接时发布被拦截', blocked);

  await page.click('[data-act="toggle"]');
  const reopened = await page.evaluate(() => window.MqttDemo.state.connected);
  check('可以再次连接', reopened === true);

  const beforeSub = await page.evaluate(() => window.MqttDemo.state.subs.length);
  await page.fill('[data-draft="topic"]', 'gateway/+/event');
  await page.click('[data-act="sub"]');
  const afterSub = await page.evaluate(() => window.MqttDemo.state.subs.map((s) => s.topic));
  check('可以新增订阅', afterSub.length === beforeSub + 1 && afterSub.includes('gateway/+/event'));
  await page.locator('[data-act="unsub"]').last().click();
  const afterUnsub = await page.evaluate(() => window.MqttDemo.state.subs.length);
  check('可以退订', afterUnsub === beforeSub);

  check('无控制台错误', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await page.close();
}

await browser.close();
process.exit(failed ? 1 : 0);
