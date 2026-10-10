// 以定稿 serial-console.html 为底，注入脚本区，产出三版可双击打开的单文件。
// 留档：方向已选 C 并入主稿，主稿现已自带脚本页，不要再以新版主稿为底重跑。
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const src = (name) => readFileSync(join(root, 'src', name), 'utf8');
const base = readFileSync(join(root, '..', 'serial-console.html'), 'utf8');
const variants = [
  ['panel', '版 A · 窄栏内完成'],
  ['dialog', '版 B · 编辑进浮层'],
  ['workspace', '版 C · 借中间列'],
];

for (const [name, title] of variants) {
  const html = base
    .replace(/<title>[^<]*<\/title>/, () => `<title>设备调试工具 · 脚本 · ${title}</title>`)
    .replace('</head>', () => `<style>\n${src('scripts.css')}${src(name + '.css')}</style>\n</head>`)
    .replace(/<\/body>\s*<\/html>\s*$/, () => `<script>\n${src('scripts.js')}</script>\n<script>\n${src(name + '.js')}</script>\n</body>\n</html>\n`);
  writeFileSync(join(root, name + '.html'), html);
  console.log('built', join(root, name + '.html'));
}
