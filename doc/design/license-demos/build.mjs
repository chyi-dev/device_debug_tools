// 以定稿 serial-console.html 为底，注入授权层，产出三版可双击打开的单文件。
// 用法：node doc/design/license-demos/build.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const src = (name) => readFileSync(join(root, 'src', name), 'utf8');
const base = readFileSync(join(root, '..', 'serial-console.html'), 'utf8');
const variants = [
  ['tab', '版 A · 页签上锁'],
  ['bar', '版 B · 日志状态条'],
  ['panel', '版 C · 右栏即授权'],
];

for (const [name, title] of variants) {
  const html = base
    .replace(/<title>[^<]*<\/title>/, () => `<title>设备调试工具 · 授权 · ${title}</title>`)
    .replace('</head>', () => `<style>\n${src('license.css')}${src(name + '.css')}</style>\n</head>`)
    .replace(/<\/body>\s*<\/html>\s*$/, () => `<script>var LIC_VARIANT = '${name}';</script>\n<script>\n${src('license.js')}</script>\n<script>\n${src(name + '.js')}</script>\n</body>\n</html>\n`);
  writeFileSync(join(root, name + '.html'), html);
  console.log('built', join(root, name + '.html'));
}
