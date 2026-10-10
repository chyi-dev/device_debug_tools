// 以定稿 serial-console.html 为底注入 Lua 教程，产出三版可双击打开的单文件。
// 用法：node doc/design/tutorial-demos/build.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const src = (name) => readFileSync(join(root, 'src', name), 'utf8');
const base = readFileSync(join(root, '..', 'serial-console.html'), 'utf8');
const variants = [
  ['list', '版 A · 课表'],
  ['book', '版 B · 课本'],
  ['pick', '版 C · 选题新建'],
];

for (const [name, title] of variants) {
  const html = base
    .replace(/<title>[^<]*<\/title>/, () => `<title>设备调试工具 · Lua 教程 · ${title}</title>`)
    .replace('</head>', () => `<style>\n${src('lessons.css')}${src(name + '.css')}</style>\n</head>`)
    .replace(/<\/body>\s*<\/html>\s*$/, () => `<script>\n${src('lessons.js')}</script>\n<script>\n${src(name + '.js')}</script>\n</body>\n</html>\n`);
  writeFileSync(join(root, name + '.html'), html);
  console.log('built', join(root, name + '.html'));
}
