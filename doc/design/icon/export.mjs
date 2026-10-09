// 由 SVG 源导出应用图标：node doc/design/icon/export.mjs [仓库根目录]
// 需要能解析到 playwright 包；默认使用本机 Edge（PW_CHANNEL 可改）。
import { chromium } from 'playwright';
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = process.argv[2] ? resolve(process.argv[2]) : resolve(here, '../../..');
const iconDir = resolve(root, 'doc/design/icon');
const full = readFileSync(resolve(iconDir, 'app_icon.svg'), 'utf8');
const small = readFileSync(resolve(iconDir, 'app_icon_small.svg'), 'utf8');
// 16、24px 用简化稿，否则波形会糊成一团。
const svgFor = (size) => (size <= 24 ? small : full);

const browser = await chromium.launch({ channel: process.env.PW_CHANNEL || 'msedge' });
const page = await browser.newPage();
const render = async (size) => {
  const dataUrl = await page.evaluate(async ([svg, s]) => {
    const img = new Image();
    img.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
    await img.decode();
    const cv = document.createElement('canvas');
    cv.width = s; cv.height = s;
    cv.getContext('2d').drawImage(img, 0, 0, s, s);
    return cv.toDataURL('image/png');
  }, [svgFor(size), size]);
  return Buffer.from(dataUrl.split(',')[1], 'base64');
};

const macDir = resolve(root, 'macos/Runner/Assets.xcassets/AppIcon.appiconset');
for (const s of [16, 32, 64, 128, 256, 512, 1024]) {
  writeFileSync(resolve(macDir, `app_icon_${s}.png`), await render(s));
}

// ICO 直接内嵌 PNG（Vista 起支持），宽高字段 0 表示 256。
const icoSizes = [16, 24, 32, 48, 64, 128, 256];
const pngs = [];
for (const s of icoSizes) pngs.push(await render(s));
const header = Buffer.alloc(6 + 16 * pngs.length);
header.writeUInt16LE(0, 0);
header.writeUInt16LE(1, 2);
header.writeUInt16LE(pngs.length, 4);
let offset = header.length;
pngs.forEach((png, i) => {
  const e = 6 + 16 * i;
  const s = icoSizes[i];
  header.writeUInt8(s >= 256 ? 0 : s, e);
  header.writeUInt8(s >= 256 ? 0 : s, e + 1);
  header.writeUInt16LE(1, e + 4);
  header.writeUInt16LE(32, e + 6);
  header.writeUInt32LE(png.length, e + 8);
  header.writeUInt32LE(offset, e + 12);
  offset += png.length;
});
writeFileSync(resolve(root, 'windows/runner/resources/app_icon.ico'), Buffer.concat([header, ...pngs]));

await browser.close();
console.log('ico:', icoSizes.join(', '));
console.log('mac:', '16, 32, 64, 128, 256, 512, 1024');
