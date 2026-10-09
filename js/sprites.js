'use strict';
// Every picture in the game is drawn here from text grids: one character = one pixel.
// '.' is transparent; every other letter is a colour from PAL.

const PAL = {
  k: '#1b1a24', l: '#4a3428', b: '#7a4a2b', B: '#a8703f',
  g: '#3f8a3c', G: '#67b54a', d: '#2b5a32',
  s: '#8a8f98', S: '#c2c6cc', D: '#5c616b',
  r: '#c8413a', R: '#ee6a5a', y: '#f2cf5b', o: '#ea8a33',
  w: '#f2efe6', c: '#4fb6d0', C: '#a6e6f2',
  p: '#7b4fb8', P: '#a77ee0', n: '#e3b07a', N: '#b5784e',
  u: '#3b5dc9', U: '#6b8ff0', i: '#9fb0c8', I: '#e3ebf5',
  f: '#c9a27a', F: '#a07a55', z: '#7fa77a', Z: '#4c6d4f',
};

const SPRITE_ROWS = {
  player: [
    '..llll..',
    '.llllll.',
    '.lnnnkn.',
    '..nnnn..',
    '.uUuuuu.',
    '.nuuuun.',
    '..bbbb..',
    '..k..k..',
  ],
  player_walk: [
    '..llll..',
    '.llllll.',
    '.lnnnkn.',
    '..nnnn..',
    '.uUuuuu.',
    '.nuuuun.',
    '..bbbb..',
    '.k....k.',
  ],
  rabbit: [
    '........',
    '....f.f.',
    '....f.f.',
    '...ffff.',
    '..fffkf.',
    'wffffff.',
    '.ffffff.',
    '..F..F..',
  ],
  slime: [
    '........',
    '..kkkk..',
    '.kCCcck.',
    'kcCcccck',
    'kckcckck',
    'kcccccck',
    '.kkkkkk.',
    '........',
  ],
  ghoul: [
    '..kkkk..',
    '.kzzzzk.',
    '.kzrzrk.',
    '.kZzzZk.',
    '..pppp..',
    'zppPppz.',
    '..pppp..',
    '..Z..Z..',
  ],
  spider: [
    '........',
    '........',
    'k.k..k.k',
    '.kpPppk.',
    'kpppRpRk',
    '.kppppk.',
    'k.k..k.k',
    '........',
  ],
  golem: [
    '...kkkkkk...',
    '..kSSSsssk..',
    '..ksyssyDk..',
    '..kssssssk..',
    '.kkkDssDkkk.',
    'kSSskssksSSk',
    'kssDksskDssk',
    'kssDksskDssk',
    '.kkksssskkk.',
    '..ksssksssk.',
    '..ksssksssk.',
    '..kkkk.kkkk.',
  ],
  tree: [
    '...dd...',
    '..dGgd..',
    '.dgGggd.',
    'dgGgggGd',
    'dggggGgd',
    '.dgGgggd',
    'dggggggd',
    'dgGggGgd',
    '.dddddd.',
    '...bB...',
    '...bB...',
    '..lbBl..',
  ],
  rock: [
    '........',
    '........',
    '..kkkk..',
    '.kSSssk.',
    'kSssssDk',
    'ksssDDDk',
    '.kkkkkk.',
    '........',
  ],
  iron_rock: [
    '........',
    '........',
    '..kkkk..',
    '.kSIssk.',
    'kSsiIsDk',
    'ksIsDiDk',
    '.kkkkkk.',
    '........',
  ],
  bush: [
    '........',
    '........',
    '..dddd..',
    '.dgrgGd.',
    'dgGgrggd',
    'dgrggrgd',
    '.dddddd.',
    '........',
  ],
  tallgrass: [
    '........',
    '........',
    '........',
    '.G...G..',
    '.g.G.g.G',
    '.gGg.gGg',
    'gdgdgdgd',
    '........',
  ],
  wall: [
    'kkkkkkkk',
    'kBbbkBbk',
    'kbbbkbbk',
    'kkkkkkkk',
    'kBbkBbbk',
    'kbbkbbbk',
    'kkkkkkkk',
    'klllllll',
  ],
  campfire: [
    '........',
    '...y....',
    '..yoy...',
    '..oRoy..',
    '.oRrRo..',
    '.bBbbBb.',
    'bBbbBbbB',
    '........',
  ],
  campfire2: [
    '....y...',
    '...yoy..',
    '..yoRo..',
    '..oRro..',
    '.oRrRo..',
    '.bBbbBb.',
    'bBbbBbbB',
    '........',
  ],
  torch: [
    '...y....',
    '..yoy...',
    '..oRo...',
    '...B....',
    '...b....',
    '...b....',
    '...b....',
    '........',
  ],
  spikes: [
    '........',
    '........',
    '........',
    '.I...I..',
    '.i..Ii.I',
    'Ii..ii.i',
    'llllllll',
    '........',
  ],
  wood: [
    '........',
    '......kk',
    '....kBbk',
    '..kBbbk.',
    '.kBbbk..',
    'kBbbk...',
    '.kkk....',
    '........',
  ],
  stone: [
    '........',
    '........',
    '...kkk..',
    '..kSssk.',
    '.kSsssDk',
    '.ksssDDk',
    '..kkkkk.',
    '........',
  ],
  fiber: [
    '....g...',
    '...gG...',
    '..gGg.g.',
    '..Gg.gG.',
    '.gG.gGg.',
    '.yyyyyy.',
    '.g.gG.g.',
    'g..g...g',
  ],
  berry: [
    '........',
    '.....g..',
    '....g...',
    '..rr.rr.',
    '.rRrrRrr',
    '.rrr.rrr',
    '..r...r.',
    '........',
  ],
  meat: [
    '........',
    '..rrrr..',
    '.rRRrrr.',
    '.rRrrrrw',
    '..rrrrww',
    '......ww',
    '........',
    '........',
  ],
  gel: [
    '........',
    '...C....',
    '..cCc...',
    '.cCccc..',
    '.ccccc..',
    '..ccc...',
    '........',
    '........',
  ],
  bone: [
    '........',
    '.ww.....',
    '.www....',
    '..www...',
    '...www..',
    '....www.',
    '.....ww.',
    '........',
  ],
  silk: [
    '........',
    '..wwww..',
    '.wIwwIw.',
    '.wwIIww.',
    '.wIwwIw.',
    '..wwww..',
    '...w....',
    '....w...',
  ],
  fur: [
    '........',
    '..ffff..',
    '.fFfffF.',
    '.ffffff.',
    '.fFffFf.',
    '..ffff..',
    '........',
    '........',
  ],
  iron_ore: [
    '........',
    '........',
    '..kkkk..',
    '.kDiDsk.',
    '.kIsiDk.',
    '.kDDiDk.',
    '..kkkk..',
    '........',
  ],
  iron_bar: [
    '........',
    '........',
    '...kkkkk',
    '..kIIIik',
    '.kIiiik.',
    'kkkkkk..',
    '........',
    '........',
  ],
  golem_heart: [
    '........',
    '.yy.yy..',
    'yoyyyoy.',
    'yoooooy.',
    '.yoooy..',
    '..yoy...',
    '...y....',
    '........',
  ],
  bandage: [
    '........',
    '........',
    '.wwwwww.',
    '.wwrrww.',
    '.wrrrrw.',
    '.wwrrww.',
    '.wwwwww.',
    '........',
  ],
  stew: [
    '........',
    '..o..o..',
    '...o....',
    '.kkkkkk.',
    'kBoroBok',
    '.kbbbbk.',
    '..kkkk..',
    '........',
  ],
  golem_idol: [
    '..kkkk..',
    '.kSssSk.',
    '.ksyysk.',
    '.kssssk.',
    '..kssk..',
    '.kSssSk.',
    'kkkkkkkk',
    '........',
  ],
  heart: [
    '.rr.rr..',
    'rRrrrrr.',
    'rrrrrrr.',
    '.rrrrr..',
    '..rrr...',
    '...r....',
  ],
};

// Shapes shared by several items; X is the light colour, x the dark one.
const TEMPLATES = {
  sword: [
    '.......X',
    '......Xx',
    '.....Xx.',
    '....Xx..',
    '.k.Xx...',
    '..kx....',
    '.bkk....',
    'b.......',
  ],
  axe: [
    '...bBXX.',
    '...bBXxX',
    '...bBXxX',
    '...bBXX.',
    '...bB...',
    '...bB...',
    '...bB...',
    '...bB...',
  ],
  pick: [
    '.XXXXXX.',
    'Xx.bB.xX',
    'x..bB..x',
    '...bB...',
    '...bB...',
    '...bB...',
    '...bB...',
    '...bB...',
  ],
  armor: [
    '........',
    '.XX..XX.',
    '.XxXXxX.',
    '..xXXx..',
    '..XxxX..',
    '..XXXX..',
    '..x..x..',
    '........',
  ],
  egg: [
    '........',
    '...ww...',
    '..wXww..',
    '.wwwwXw.',
    '.wXwwww.',
    '.wwwXww.',
    '..wwww..',
    '........',
  ],
};

const SPR = {};
const ICON = {};
const GROUND = {};

function makeSprite(rows, map) {
  const w = Math.max(...rows.map(r => r.length)), h = rows.length;
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  const x = c.getContext('2d');
  rows.forEach((row, j) => {
    for (let i = 0; i < row.length; i++) {
      const ch = row[i];
      if (ch === '.') continue;
      const col = (map && map[ch]) || PAL[ch];
      if (!col) continue;
      x.fillStyle = col;
      x.fillRect(i, j, 1, 1);
    }
  });
  return c;
}

function flipSprite(src) {
  const c = document.createElement('canvas');
  c.width = src.width; c.height = src.height;
  const x = c.getContext('2d');
  x.translate(src.width, 0); x.scale(-1, 1);
  x.drawImage(src, 0, 0);
  return c;
}

// A white copy of a sprite, flashed when something takes a hit.
function whiteSprite(src) {
  const c = document.createElement('canvas');
  c.width = src.width; c.height = src.height;
  const x = c.getContext('2d');
  x.drawImage(src, 0, 0);
  x.globalCompositeOperation = 'source-in';
  x.fillStyle = '#ffffff';
  x.fillRect(0, 0, c.width, c.height);
  return c;
}

function groundTile(base, light, dark, seed, extras) {
  const c = document.createElement('canvas');
  c.width = 8; c.height = 8;
  const x = c.getContext('2d');
  x.fillStyle = base; x.fillRect(0, 0, 8, 8);
  let s = seed * 9301 + 49297;
  const rnd = () => { s = (s * 9301 + 49297) % 233280; return s / 233280; };
  for (let i = 0; i < 7; i++) { x.fillStyle = light; x.fillRect((rnd() * 8) | 0, (rnd() * 8) | 0, 1, 1); }
  for (let i = 0; i < 5; i++) { x.fillStyle = dark; x.fillRect((rnd() * 8) | 0, (rnd() * 8) | 0, 1, 1); }
  if (extras) for (const col of extras) { x.fillStyle = col; x.fillRect((rnd() * 8) | 0, (rnd() * 8) | 0, 1, 1); }
  return c;
}

function waterTile(frame, seed) {
  const c = document.createElement('canvas');
  c.width = 8; c.height = 8;
  const x = c.getContext('2d');
  x.fillStyle = '#2c64a0'; x.fillRect(0, 0, 8, 8);
  x.fillStyle = '#4a8fd0';
  const off = (frame * 2 + seed) % 8;
  x.fillRect((off + 1) % 8, 2, 2, 1);
  x.fillRect((off + 5) % 8, 5, 2, 1);
  x.fillStyle = '#245690';
  x.fillRect((off + 3) % 8, 7, 1, 1);
  return c;
}

const SHIRTS = {
  none: { u: PAL.u, U: PAL.U },
  fur_armor: { u: PAL.F, U: PAL.f },
  bone_armor: { u: PAL.S, U: PAL.w },
  iron_armor: { u: PAL.i, U: PAL.I },
};

function buildSprites() {
  for (const [name, rows] of Object.entries(SPRITE_ROWS)) SPR[name] = makeSprite(rows);

  SPR.stone_wall = makeSprite(SPRITE_ROWS.wall, { B: PAL.S, b: PAL.s, l: PAL.D });
  SPR.cooked_meat = makeSprite(SPRITE_ROWS.meat, { r: '#8a4a24', R: '#c07a3a' });

  const mat = {
    wood: { X: PAL.B, x: PAL.b }, stone: { X: PAL.S, x: PAL.s },
    iron: { X: PAL.I, x: PAL.i }, heart: { X: PAL.y, x: PAL.o },
  };
  SPR.wood_sword = makeSprite(TEMPLATES.sword, mat.wood);
  SPR.stone_sword = makeSprite(TEMPLATES.sword, mat.stone);
  SPR.iron_sword = makeSprite(TEMPLATES.sword, mat.iron);
  SPR.heart_blade = makeSprite(TEMPLATES.sword, mat.heart);
  SPR.stone_axe = makeSprite(TEMPLATES.axe, mat.stone);
  SPR.iron_axe = makeSprite(TEMPLATES.axe, mat.iron);
  SPR.stone_pick = makeSprite(TEMPLATES.pick, mat.stone);
  SPR.iron_pick = makeSprite(TEMPLATES.pick, mat.iron);
  SPR.fur_armor = makeSprite(TEMPLATES.armor, { X: PAL.f, x: PAL.F });
  SPR.bone_armor = makeSprite(TEMPLATES.armor, { X: PAL.w, x: PAL.S });
  SPR.iron_armor = makeSprite(TEMPLATES.armor, { X: PAL.I, x: PAL.i });
  SPR.egg_slime = makeSprite(TEMPLATES.egg, { X: PAL.c });
  SPR.egg_spider = makeSprite(TEMPLATES.egg, { X: PAL.p });
  SPR.egg_golem = makeSprite(TEMPLATES.egg, { X: PAL.o });

  // The player's shirt changes colour with the armour they wear.
  for (const [armor, map] of Object.entries(SHIRTS)) {
    for (const base of ['player', 'player_walk']) {
      const s = makeSprite(SPRITE_ROWS[base], map);
      SPR[`${base}_${armor}`] = s;
      SPR[`${base}_${armor}_l`] = flipSprite(s);
    }
  }
  SPR.player_white = whiteSprite(SPR.player);
  SPR.player_white_l = flipSprite(SPR.player_white);

  for (const name of ['rabbit', 'slime', 'ghoul', 'spider', 'golem']) {
    SPR[name + '_l'] = flipSprite(SPR[name]);
    SPR[name + '_w'] = whiteSprite(SPR[name]);
    SPR[name + '_w_l'] = flipSprite(SPR[name + '_w']);
  }

  // Ground: 0 water, 1 sand, 2 grass, 3 forest floor, 4 rocky ground
  GROUND[0] = [0, 1, 2, 3].map(f => [0, 3, 6].map(s => waterTile(f, s)));
  GROUND[1] = [1, 2, 3, 4].map(s => groundTile('#dcc68a', '#ecdcaa', '#c9b073', s));
  GROUND[2] = [1, 2, 3, 4].map(s => groundTile('#4f9a44', '#62b252', '#428538', s, s === 3 ? ['#f2cf5b', '#f2efe6'] : null));
  GROUND[3] = [1, 2, 3, 4].map(s => groundTile('#3a7639', '#468a43', '#2e6230', s));
  GROUND[4] = [1, 2, 3, 4].map(s => groundTile('#7d7a72', '#908c83', '#696760', s));

  for (const id of Object.keys(ITEMS)) {
    const spr = SPR[ITEMS[id].sprite || id];
    if (spr) ICON[id] = spr.toDataURL();
  }
}
