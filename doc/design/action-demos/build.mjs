// 以定稿 serial-console.html 为底，注入三种操作折叠，产出可双击打开的单文件。
// 不改主稿。选定方向之前不要把这里的脚本并回去。
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const src = (name) => (existsSync(join(root, 'src', name)) ? readFileSync(join(root, 'src', name), 'utf8') : '');
const base = readFileSync(join(root, '..', 'serial-console.html'), 'utf8');
const variants = [
  ['more', '版 A · 行尾更多'],
  ['select', '版 B · 选中展开'],
  ['context', '版 C · 右键菜单'],
];

for (const [name, title] of variants) {
  const html = base
    .replace(/<title>[^<]*<\/title>/, () => `<title>设备调试工具 · 操作折叠 · ${title}</title>`)
    .replace('</head>', () => `<style>\n${src('actions.css')}${src(name + '.css')}</style>\n</head>`)
    .replace(/<\/body>\s*<\/html>\s*$/, () => `<script>\n${src('actions.js')}</script>\n<script>\n${src(name + '.js')}</script>\n</body>\n</html>\n`);
  writeFileSync(join(root, name + '.html'), html);
  console.log('built', join(root, name + '.html'));
}
