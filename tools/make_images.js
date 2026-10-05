// Generates the icons and thumbnails in assets/.
// Run: NODE_PATH=$(npm root -g) node tools/make_images.js
// Edit the THUMBNAILS list below to change the text on the thumbnails.

const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const OUT = path.join(__dirname, '..', 'assets');
const PURPLE = '#6d28d9';
const CYAN = '#06b6d4';
const DARK = '#0f172a';
const FONT = "'DejaVu Sans', 'Liberation Sans', Arial, sans-serif";

const gradient = (id) => `
  <linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="${PURPLE}"/><stop offset="1" stop-color="${CYAN}"/>
  </linearGradient>`;

// ---------- Icons (512x512, rounded square) ----------

const iconFrame = (inner) => `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>${gradient('g')}</defs>
  <rect width="512" height="512" rx="112" fill="url(#g)"/>
  ${inner}
</svg>`;

const W = 'fill="none" stroke="#fff" stroke-width="32" stroke-linecap="round" stroke-linejoin="round"';

const ICONS = {
  logo: iconFrame(`<text x="256" y="330" font-family="${FONT}" font-weight="bold" font-size="220"
    text-anchor="middle" fill="#fff" letter-spacing="-8">BS</text>`),
  code: iconFrame(`<g ${W}><path d="M190 160 L100 256 L190 352"/><path d="M322 160 L412 256 L322 352"/>
    <path d="M286 130 L226 382"/></g>`),
  learn: iconFrame(`<g ${W}><path d="M256 170 C210 135 150 130 100 140 V370 C150 360 210 365 256 400
    C302 365 362 360 412 370 V140 C362 130 302 135 256 170 Z"/><path d="M256 170 V400"/></g>`),
  idea: iconFrame(`<g ${W}><path d="M206 330 C206 290 160 270 160 210 A96 96 0 0 1 352 210
    C352 270 306 290 306 330 Z"/><path d="M216 380 H296"/><path d="M230 425 H282"/></g>`),
  game: iconFrame(`<g ${W}><rect x="90" y="170" width="332" height="190" rx="95"/>
    <path d="M170 265 H230 M200 235 V295"/></g>
    <circle cx="320" cy="245" r="20" fill="#fff"/><circle cx="355" cy="290" r="20" fill="#fff"/>`),
  video: iconFrame(`<path d="M200 160 L370 256 L200 352 Z" fill="#fff" stroke="#fff" stroke-width="24"
    stroke-linejoin="round"/>`),
};

const ICON_SIZES = [16, 32, 64, 128, 256, 512];

// ---------- Thumbnails (1280x720, YouTube size) ----------

const THUMBNAILS = [
  { file: 'welcome', tag: 'NEW CHANNEL', title: ['Welcome to', 'My Channel!'], sub: 'Brenden Sobanski', icon: 'video' },
  { file: 'learning-python', tag: 'BEGINNER', title: ['Learning', 'Python'], sub: 'Day 1 — from zero', icon: 'code' },
  { file: 'my-first-project', tag: 'BUILD WITH ME', title: ['My First', 'Project'], sub: 'Let’s make something!', icon: 'idea' },
  { file: 'making-a-game', tag: 'GAME DEV', title: ['Making a', 'Game'], sub: 'Can I do it?', icon: 'game' },
];

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

function thumbnail({ tag, title, sub, icon }) {
  const iconInner = ICONS[icon].replace(/^<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '').replace(/id="g"/, 'id="ig"').replace('url(#g)', 'url(#ig)');
  // Shrink long titles so they never run into the icon (~760px of room).
  const longest = Math.max(...title.map((t) => t.length));
  const titleSize = Math.min(128, Math.floor(760 / (longest * 0.72)));
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
  <defs>${gradient('bg')}
    <radialGradient id="glow" cx="0.8" cy="0.3" r="0.7">
      <stop offset="0" stop-color="${CYAN}" stop-opacity="0.45"/><stop offset="1" stop-color="${CYAN}" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="1280" height="720" fill="${DARK}"/>
  <rect width="1280" height="720" fill="url(#glow)"/>
  <circle cx="1180" cy="660" r="220" fill="${PURPLE}" opacity="0.35"/>
  <circle cx="60" cy="40" r="120" fill="${CYAN}" opacity="0.15"/>
  <rect x="0" y="0" width="22" height="720" fill="url(#bg)"/>

  <rect x="80" y="90" width="${tag.length * 25 + 64}" height="64" rx="32" fill="url(#bg)"/>
  <text x="${80 + (tag.length * 25 + 64) / 2}" y="134" font-family="${FONT}" font-weight="bold" font-size="32"
    text-anchor="middle" fill="#fff" letter-spacing="2">${esc(tag)}</text>

  <g font-family="${FONT}" font-weight="bold" fill="#fff" stroke="#000" stroke-width="10" paint-order="stroke">
    <text x="76" y="320" font-size="${titleSize}">${esc(title[0])}</text>
    <text x="76" y="460" font-size="${titleSize}" fill="#67e8f9">${esc(title[1])}</text>
  </g>
  <text x="82" y="560" font-family="${FONT}" font-size="48" fill="#cbd5e1">${esc(sub)}</text>

  <g transform="translate(870 190) rotate(8 170 170) scale(0.66)">
    <rect x="10" y="24" width="512" height="512" rx="112" fill="#000" opacity="0.35"/>
    ${iconInner}
  </g>
</svg>`;
}

// ---------- Render ----------

async function render(page, svg, size, outFile) {
  const [w, h] = size;
  await page.setViewportSize({ width: w, height: h });
  const html = `<html><body style="margin:0;background:transparent">
    <img src="data:image/svg+xml;base64,${Buffer.from(svg).toString('base64')}" width="${w}" height="${h}"
      style="display:block"></body></html>`;
  await page.setContent(html);
  await page.waitForLoadState('load');
  await page.screenshot({ path: outFile, omitBackground: true, clip: { x: 0, y: 0, width: w, height: h } });
}

(async () => {
  for (const d of ['icons/svg', 'icons/png', 'thumbnails']) fs.mkdirSync(path.join(OUT, d), { recursive: true });

  const browser = await chromium.launch();
  const page = await browser.newPage();

  for (const [name, svg] of Object.entries(ICONS)) {
    fs.writeFileSync(path.join(OUT, 'icons/svg', `${name}.svg`), svg);
    for (const s of ICON_SIZES) {
      await render(page, svg, [s, s], path.join(OUT, 'icons/png', `${name}-${s}.png`));
    }
  }

  for (const t of THUMBNAILS) {
    await render(page, thumbnail(t), [1280, 720], path.join(OUT, 'thumbnails', `${t.file}.png`));
  }

  await browser.close();
  console.log('Done. Images are in', OUT);
})();
