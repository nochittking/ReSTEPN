// RE:STEP のPWAアイコン生成スクリプト。
// ブランドSVG(インク地+緑稲妻=靴のかかとバッジと同モチーフ)をChromiumで
// レンダリングして web/icons/*.png と web/favicon.png を書き出す。
// 使い方: node make_icons.js   (CHROMIUM_PATH で実行ファイル指定可)
const { chromium } = require('playwright');
const path = require('path');

const WEB_DIR = path.join(__dirname, '..', 'web');

const INK = '#1E1E22';
const MINT = '#8BEDC7';
const CREAM = '#F0EFE9';
const BOLT = '#41D07E';

// かかとの稲妻バッジ(sneaker_art.dartの_drawBolt)と同じ頂点列。
const BOLT_PTS = [
  [0.3, -1.0], [-0.3, 0.1], [0.05, 0.1], [-0.25, 1.0], [0.45, -0.2], [0.05, -0.2],
];

function boltPath(cx, cy, s) {
  const pts = BOLT_PTS.map(([x, y]) => `${cx + x * s},${cy + y * s}`);
  return `M${pts.join('L')}Z`;
}

// maskable: 角丸なし全面塗り+セーフゾーン(中央80%)に収める。
function svg(size, { maskable }) {
  const rx = maskable ? 0 : Math.round(size * 0.22);
  const s = size * (maskable ? 0.24 : 0.3);
  const cx = size / 2;
  const cy = size / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="${size}" height="${size}" rx="${rx}" fill="${INK}"/>
  <circle cx="${cx}" cy="${cy}" r="${size * 0.36}" fill="${MINT}" opacity="0.16"/>
  <circle cx="${cx}" cy="${cy}" r="${size * 0.36}" fill="none" stroke="${MINT}" stroke-width="${size * 0.02}" opacity="0.55"/>
  <path d="${boltPath(cx, cy, s)}" fill="${BOLT}" stroke="${CREAM}" stroke-width="${size * 0.018}" stroke-linejoin="round"/>
</svg>`;
}

async function render(page, size, opts, outFile) {
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(
    `<style>html,body{margin:0;padding:0;background:transparent}</style>` +
      svg(size, opts),
  );
  await page.locator('svg').screenshot({
    path: path.join(WEB_DIR, outFile),
    omitBackground: true,
  });
  console.log('wrote', outFile);
}

(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
  });
  const page = await browser.newPage();
  await render(page, 192, { maskable: false }, 'icons/Icon-192.png');
  await render(page, 512, { maskable: false }, 'icons/Icon-512.png');
  await render(page, 192, { maskable: true }, 'icons/Icon-maskable-192.png');
  await render(page, 512, { maskable: true }, 'icons/Icon-maskable-512.png');
  await render(page, 64, { maskable: false }, 'favicon.png');
  await browser.close();
})();
