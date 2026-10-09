'use strict';
// The island: ground tiles, objects on them, and how both are generated.
// Ground codes: 0 water, 1 sand, 2 grass, 3 forest floor, 4 rocky ground.

function hash2(x, y, seed) {
  let h = (Math.imul(x, 374761393) + Math.imul(y, 668265263) + Math.imul(seed, 982451653)) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  h ^= h >>> 16;
  return (h >>> 0) / 4294967296;
}

function valueNoise(x, y, seed) {
  const xi = Math.floor(x), yi = Math.floor(y);
  const xf = x - xi, yf = y - yi;
  const sm = t => t * t * (3 - 2 * t);
  const a = hash2(xi, yi, seed), b = hash2(xi + 1, yi, seed);
  const c = hash2(xi, yi + 1, seed), d = hash2(xi + 1, yi + 1, seed);
  const u = sm(xf), v = sm(yf);
  return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
}

function fbm(x, y, seed) {
  let sum = 0, amp = 0.5, freq = 1, norm = 0;
  for (let o = 0; o < 4; o++) {
    sum += amp * valueNoise(x * freq, y * freq, seed + o * 101);
    norm += amp; amp *= 0.5; freq *= 2;
  }
  return sum / norm;
}

// Which natural objects grow on each ground type, and how densely.
const GROWTH = {
  1: [[2, 0.012]],
  2: [[1, 0.05], [4, 0.04], [5, 0.11], [2, 0.012]],
  3: [[1, 0.27], [4, 0.05], [5, 0.05]],
  4: [[2, 0.15], [3, 0.05]],
};

function rollGrowth(ground, r) {
  const list = GROWTH[ground];
  if (!list) return 0;
  let acc = 0;
  for (const [code, p] of list) { acc += p; if (r < acc) return code; }
  return 0;
}

class World {
  constructor(w, h, seed) {
    this.w = w; this.h = h; this.seed = seed;
    this.ground = new Uint8Array(w * h);
    this.obj = new Uint8Array(w * h);
    this.variant = new Uint8Array(w * h);
    this.dmg = new Map();   // tile index -> health left after being hit
    this.hitAt = new Map(); // tile index -> time of the last hit, for the wobble
    this.natural = 0;
    this.naturalTarget = 0;
  }
  inb(x, y) { return x >= 0 && y >= 0 && x < this.w && y < this.h; }
  g(x, y) { return this.inb(x, y) ? this.ground[y * this.w + x] : 0; }
  o(x, y) { return this.inb(x, y) ? this.obj[y * this.w + x] : 0; }
  solid(x, y) {
    if (!this.inb(x, y)) return true;
    const i = y * this.w + x;
    if (this.ground[i] === 0) return true;
    const o = this.obj[i];
    return o > 0 && OBJ[o].solid;
  }
  set(x, y, code) {
    const i = y * this.w + x;
    const old = this.obj[i];
    if (old >= 1 && old <= NATURAL_MAX) this.natural--;
    if (code >= 1 && code <= NATURAL_MAX) this.natural++;
    this.obj[i] = code;
    this.dmg.delete(i);
  }
  // Returns true when the object breaks.
  hit(x, y, amount) {
    const i = y * this.w + x;
    const def = OBJ[this.obj[i]];
    if (!def) return false;
    const left = (this.dmg.has(i) ? this.dmg.get(i) : def.hp) - amount;
    this.hitAt.set(i, performance.now());
    if (left <= 0) { this.set(x, y, 0); return true; }
    this.dmg.set(i, left);
    return false;
  }
  hpFraction(x, y) {
    const i = y * this.w + x;
    const def = OBJ[this.obj[i]];
    if (!def || !this.dmg.has(i)) return 1;
    return this.dmg.get(i) / def.hp;
  }
  countNatural() {
    let n = 0;
    for (const o of this.obj) if (o >= 1 && o <= NATURAL_MAX) n++;
    this.natural = n;
    return n;
  }
  // Slowly replants trees, rocks and bushes so resources never run out.
  regrow(px, py) {
    if (this.natural >= this.naturalTarget) return;
    for (let t = 0; t < 30; t++) {
      const x = (Math.random() * this.w) | 0, y = (Math.random() * this.h) | 0;
      if (Math.abs(x - px) < 10 && Math.abs(y - py) < 8) continue;
      const i = y * this.w + x;
      if (this.obj[i] !== 0 || this.ground[i] === 0) continue;
      const code = rollGrowth(this.ground[i], Math.random() * 0.6);
      if (code) { this.set(x, y, code); return; }
    }
  }
  findSpawn() {
    const cx = this.w >> 1, cy = this.h >> 1;
    for (let r = 0; r < this.w / 2; r++) {
      for (let dy = -r; dy <= r; dy++) for (let dx = -r; dx <= r; dx++) {
        const x = cx + dx, y = cy + dy;
        if (this.g(x, y) === 2) return { x, y };
      }
    }
    return { x: cx, y: cy };
  }
  clearAround(x, y, r) {
    for (let dy = -r; dy <= r; dy++) for (let dx = -r; dx <= r; dx++) {
      if (this.inb(x + dx, y + dy) && OBJ[this.o(x + dx, y + dy)]?.solid) this.set(x + dx, y + dy, 0);
    }
  }
}

World.generate = function (seed, size = 128) {
  const w = new World(size, size, seed);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = y * size + x;
      const nx = x / size - 0.5, ny = y / size - 0.5;
      const d = Math.sqrt(nx * nx + ny * ny) * 2;
      const e = fbm(x / 24, y / 24, seed) + 0.28 - d * d * 0.85;
      const m = fbm(x / 18, y / 18, seed + 3);
      const rk = fbm(x / 14, y / 14, seed + 7);
      let g;
      if (e < 0.38) g = 0;
      else if (e < 0.43) g = 1;
      else if (rk > 0.6 && e > 0.5) g = 4;
      else if (m > 0.54) g = 3;
      else g = 2;
      w.ground[i] = g;
      w.variant[i] = (hash2(x, y, seed + 5) * 4) | 0;
      if (g !== 0) w.obj[i] = rollGrowth(g, hash2(x, y, seed + 999));
    }
  }
  const sp = w.findSpawn();
  w.clearAround(sp.x, sp.y, 2);
  w.spawn = sp;
  w.naturalTarget = w.countNatural();
  return w;
};

World.arena = function () {
  const W = 24, H = 18;
  const w = new World(W, H, 1);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const i = y * W + x;
    const edge = x === 0 || y === 0 || x === W - 1 || y === H - 1;
    w.ground[i] = edge ? 0 : (hash2(x, y, 3) < 0.07 ? 1 : 4);
    w.variant[i] = (hash2(x, y, 9) * 4) | 0;
  }
  for (const [x, y] of [[3, 3], [W - 4, 3], [3, H - 4], [W - 4, H - 4]]) w.obj[y * W + x] = 9;
  for (const [x, y] of [[7, 6], [16, 6], [7, 11], [16, 11], [11, 4], [12, 13]]) w.obj[y * W + x] = 2;
  w.spawn = { x: W >> 1, y: H >> 1 };
  w.naturalTarget = 0;
  w.countNatural();
  return w;
};
