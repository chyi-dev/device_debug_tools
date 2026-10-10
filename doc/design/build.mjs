// 把 src/engine.js 内联进设计稿，产出可双击打开的单文件 HTML。
// 用法：node doc/design/build.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const engine = readFileSync(join(root, 'src', 'engine.js'), 'utf8');
const tutor = readFileSync(join(root, 'src', 'reply-tutor.js'), 'utf8');
const html = readFileSync(join(root, 'src', 'serial-console.html'), 'utf8')
  .replace('<!-- @engine -->', () => `<script>\n${engine}</script>`)
  .replace('<!-- @reply-tutor -->', () => `<script>\n${tutor}</script>`);
writeFileSync(join(root, 'serial-console.html'), html);
console.log('built', join(root, 'serial-console.html'));
