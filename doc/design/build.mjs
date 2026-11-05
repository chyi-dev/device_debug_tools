// 把 src/*.js 内联进设计稿，产出可双击打开的单文件 HTML。
// 用法：node doc/design/build.mjs
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));

function build(name, jsFiles, sourceName = name, cssFiles = [], outputDir = root) {
  let html = readFileSync(join(root, 'src', `${sourceName}.html`), 'utf8');
  for (const [slot, file] of cssFiles) {
    const css = readFileSync(join(root, 'src', file), 'utf8');
    // 用函数替换，避免内容里的 $' / $& 被 String.replace 当成特殊替换符
    html = html.replace(slot, () => css);
  }
  for (const [slot, file] of jsFiles) {
    const js = readFileSync(join(root, 'src', file), 'utf8');
    html = html.replace(slot, () => `<script>\n${js}</script>`);
  }
  mkdirSync(outputDir, { recursive: true });
  const output = join(outputDir, `${name}.html`);
  writeFileSync(output, html);
  console.log('built', output);
}

build('serial-console', [
  ['<!-- @engine -->', 'engine.js'],
  ['<!-- @reply-tutor -->', 'reply-tutor.js'],
]);

build('multi-console', [
  ['<!-- @multi-engine -->', 'multi-engine.js'],
]);

build('multi-console-b', [
  ['<!-- @multi-workbench -->', 'multi-workbench.js'],
], 'multi-pro-b', [
  ['<!-- @multi-css -->', 'multi-workbench.css'],
]);

build('multi-console-c', [
  ['<!-- @multi-workbench -->', 'multi-workbench.js'],
], 'multi-pro-c', [
  ['<!-- @multi-css -->', 'multi-workbench.css'],
]);
