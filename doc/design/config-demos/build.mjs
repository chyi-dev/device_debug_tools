// 以定稿 serial-console.html 为底，注入配置包导入导出，产出三版可双击打开的单文件。
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const src = (name) => (existsSync(join(root, 'src', name)) ? readFileSync(join(root, 'src', name), 'utf8') : '');
const base = readFileSync(join(root, '..', 'serial-console.html'), 'utf8');
const variants = [
  ['checklist', '版 A · 清单'],
  ['bundle', '版 B · 总包'],
  ['tab', '版 C · 页签'],
];

for (const [name, title] of variants) {
  const html = base
    .replace(/<title>[^<]*<\/title>/, () => `<title>设备调试工具 · 配置导入导出 · ${title}</title>`)
    .replace('</head>', () => `<style>\n${src('pack.css')}${src(name + '.css')}</style>\n</head>`)
    .replace(/<\/body>\s*<\/html>\s*$/, () => `<script>\n${src('pack.js')}</script>\n<script>\n${src(name + '.js')}</script>\n</body>\n</html>\n`);
  writeFileSync(join(root, name + '.html'), html);
  console.log('built', join(root, name + '.html'));
}
