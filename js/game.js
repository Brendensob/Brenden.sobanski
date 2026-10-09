'use strict';
// The game loop: player, creatures, pets, crafting, day/night, saving and drawing.

const SAVE_KEY = 'pixelwilds.save.v1';
const BEST_KEY = 'pixelwilds.arena.best';
const DAY_LEN = 300; // seconds for a full day and night
const HOTBAR = 8;
const BAG_SIZE = 24;

const store = {
  get(k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
  set(k, v) { try { localStorage.setItem(k, v); return true; } catch (e) { return false; } },
};

const G = {
  mode: 'title', // title | survival | arena
  world: null, player: null, inv: null, sel: 0,
  creatures: [], drops: [], particles: [], floaters: [], pet: null,
  clock: 0.08, day: 1, discovered: new Set(), pot: [null, null, null],
  flags: {}, goal: 0, home: null,
  paused: false, bagOpen: false, dead: false,
  shake: 0, time: 0, spawnT: 0, regrowT: 0, saveT: 0, goalT: 0,
  wave: 0, waveState: 'break', waveT: 0,
  invDirty: true, camX: 0, camY: 0,
};

const rint = (a, b) => a + Math.floor(Math.random() * (b - a + 1));
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

class Inventory {
  constructor(n) { this.slots = Array(n).fill(null); }
  max(id) { const it = ITEMS[id]; return (it.tool || it.armor) ? 1 : 99; }
  count(id) { let c = 0; for (const s of this.slots) if (s && s.id === id) c += s.n; return c; }
  space(id) {
    const m = this.max(id);
    return this.slots.some(s => !s || (s.id === id && s.n < m));
  }
  // Returns how many did not fit.
  add(id, n = 1) {
    const m = this.max(id);
    for (const s of this.slots) {
      if (n <= 0) break;
      if (s && s.id === id && s.n < m) { const k = Math.min(n, m - s.n); s.n += k; n -= k; }
    }
    for (let i = 0; i < this.slots.length && n > 0; i++) {
      if (!this.slots[i]) { const k = Math.min(n, m); this.slots[i] = { id, n: k }; n -= k; }
    }
    G.invDirty = true;
    return n;
  }
  // Takes from the back of the bag first so the hotbar stays stocked.
  remove(id, n) {
    for (let i = this.slots.length - 1; i >= 0 && n > 0; i--) {
      const s = this.slots[i];
      if (s && s.id === id) { const k = Math.min(n, s.n); s.n -= k; n -= k; if (s.n <= 0) this.slots[i] = null; }
    }
    G.invDirty = true;
  }
  removeAt(i, n = 1) {
    const s = this.slots[i];
    if (!s) return;
    s.n -= n;
    if (s.n <= 0) this.slots[i] = null;
    G.invDirty = true;
  }
  has(cost) { return Object.entries(cost).every(([id, n]) => this.count(id) >= n); }
}

// ---------- canvas ----------
const canvas = document.getElementById('view');
const ctx = canvas.getContext('2d');
const lightCanvas = document.createElement('canvas');
const lctx = lightCanvas.getContext('2d');
let VW = 0, VH = 0, DPR = 1, TS = 48, PX = 6;

function resize() {
  DPR = Math.min(window.devicePixelRatio || 1, 2);
  VW = window.innerWidth; VH = window.innerHeight;
  for (const c of [canvas, lightCanvas]) { c.width = Math.round(VW * DPR); c.height = Math.round(VH * DPR); }
  canvas.style.width = VW + 'px'; canvas.style.height = VH + 'px';
  TS = clamp(Math.round(Math.min(VW, VH) / 11 / 8) * 8, 32, 64);
  PX = TS / 8;
}

function screenToWorld(sx, sy) {
  return { x: (sx - VW / 2) / TS + G.camX, y: (sy - VH / 2) / TS + G.camY };
}

// ---------- setup ----------
function newPlayer(x, y) {
  return { x, y, r: 0.28, hp: 100, maxHp: 100, hunger: 100, fx: 0, fy: 1, face: 1, moving: false, anim: 0,
    atkCd: 0, swing: 0, swingDir: { x: 0, y: 1 }, hurt: 0, inv: 0, lastHurt: 99, armor: null, dead: false, kbx: 0, kby: 0 };
}

function resetRun() {
  G.creatures = []; G.drops = []; G.particles = []; G.floaters = []; G.pet = null;
  G.pot = [null, null, null]; G.discovered = new Set(); G.flags = {}; G.goal = 0; G.home = null;
  G.paused = false; G.bagOpen = false; G.dead = false; G.shake = 0;
  G.spawnT = 2; G.regrowT = 0; G.saveT = 0; G.goalT = 0; G.sel = 0;
  G.inv = new Inventory(BAG_SIZE);
  G.invDirty = true;
  Input.release();
}

function startSurvival(world) {
  resetRun();
  G.mode = 'survival';
  G.world = world;
  G.player = newPlayer(world.spawn.x + 0.5, world.spawn.y + 0.5);
  G.day = 1; G.clock = 0.08;
}

function newSurvival() {
  const seed = (Math.random() * 1e9) | 0;
  startSurvival(World.generate(seed));
  G.inv.slots[HOTBAR - 1] = { id: 'berry', n: 3 };
  save();
  UI.enterGame();
  UI.toast('Day 1. Punch a tree to start (Space, click, or the A button).', 'big');
}

function loadSurvival() {
  const raw = store.get(SAVE_KEY);
  if (!raw) return false;
  try {
    const d = JSON.parse(raw);
    const w = World.generate(d.seed);
    for (let i = 0; i < w.obj.length; i++) w.obj[i] = d.objs.charCodeAt(i) - 65;
    w.countNatural();
    w.naturalTarget = d.natTarget || w.natural;
    startSurvival(w);
    const p = G.player;
    Object.assign(p, { x: d.p.x, y: d.p.y, hp: d.p.hp, hunger: d.p.hunger, armor: d.p.armor || null });
    d.inv.forEach((s, i) => { if (s && ITEMS[s.id]) G.inv.slots[i] = { id: s.id, n: s.n }; });
    G.sel = d.sel || 0; G.day = d.day; G.clock = d.clock;
    G.discovered = new Set(d.disc || []);
    G.goal = d.goal || 0; G.flags = d.flags || {}; G.home = d.home || null;
    if (d.pet && PETS[d.pet]) hatchPet(d.pet, true);
    UI.enterGame();
    UI.toast(`Welcome back. Day ${G.day}.`, 'big');
    return true;
  } catch (e) {
    console.warn('Save could not be read', e);
    return false;
  }
}

function save() {
  if (G.mode !== 'survival' || !G.world) return;
  const w = G.world, p = G.player;
  let objs = '';
  for (let i = 0; i < w.obj.length; i++) objs += String.fromCharCode(65 + w.obj[i]);
  const data = {
    v: 1, seed: w.seed, objs, natTarget: w.naturalTarget,
    p: { x: p.x, y: p.y, hp: Math.max(p.hp, 1), hunger: p.hunger, armor: p.armor },
    inv: G.inv.slots, sel: G.sel, day: G.day, clock: G.clock,
    disc: [...G.discovered], goal: G.goal, flags: G.flags, pet: G.pet ? G.pet.type : null, home: G.home,
  };
  store.set(SAVE_KEY, JSON.stringify(data));
}

function savedInfo() {
  const raw = store.get(SAVE_KEY);
  if (!raw) return null;
  try { return { day: JSON.parse(raw).day }; } catch (e) { return null; }
}

function startArena() {
  resetRun();
  G.mode = 'arena';
  G.world = World.arena();
  G.player = newPlayer(G.world.spawn.x + 0.5, G.world.spawn.y + 0.5);
  G.inv.add('stone_sword', 1);
  G.inv.add('bandage', 4);
  G.inv.add('cooked_meat', 4);
  G.inv.add('spikes', 4);
  G.player.armor = 'fur_armor';
  G.wave = 0; G.waveState = 'break'; G.waveT = 3;
  UI.enterGame();
  UI.toast('Arena: survive as many waves as you can.', 'big');
}

function toTitle() {
  save();
  G.mode = 'title';
  G.world = titleWorld();
  G.creatures = []; G.drops = []; G.pet = null; G.particles = []; G.floaters = [];
  G.paused = false; G.bagOpen = false; G.dead = false;
  Input.release();
  UI.showTitle();
}

let _titleWorld = null;
function titleWorld() {
  if (!_titleWorld) _titleWorld = World.generate(20240611);
  return _titleWorld;
}

// ---------- time of day ----------
function isNight() { return G.mode === 'survival' && G.clock >= 0.66 && G.clock < 0.95; }
function darkness() {
  if (G.mode === 'arena') return 0.45;
  if (G.mode !== 'survival') return 0;
  const c = G.clock;
  if (c < 0.55) return 0;
  if (c < 0.68) return (c - 0.55) / 0.13 * 0.85;
  if (c < 0.92) return 0.85;
  return (1 - c) / 0.08 * 0.85;
}
function phaseName() {
  const c = G.clock;
  if (c < 0.25) return 'Morning';
  if (c < 0.5) return 'Afternoon';
  if (c < 0.66) return 'Evening';
  if (c < 0.95) return 'Night';
  return 'Dawn';
}

function advanceClock(dt) {
  const before = G.clock;
  G.clock += dt / DAY_LEN;
  if (before < 0.55 && G.clock >= 0.55) UI.toast('The sun is setting. Get near a fire.', '');
  if (before < 0.66 && G.clock >= 0.66) {
    UI.toast(`Night ${G.day}. Ghouls are out.`, 'big');
    if (G.day % 4 === 0) spawnBoss();
  }
  if (G.clock >= 1) {
    G.clock -= 1;
    G.day++;
    UI.toast(`Day ${G.day}`, 'big');
  }
}

// ---------- movement ----------
function blocked(x, y, r) {
  const w = G.world;
  const x0 = Math.floor(x - r), x1 = Math.floor(x + r), y0 = Math.floor(y - r), y1 = Math.floor(y + r);
  for (let ty = y0; ty <= y1; ty++) for (let tx = x0; tx <= x1; tx++) if (w.solid(tx, ty)) return true;
  return false;
}

function moveEntity(e, dx, dy) {
  const steps = Math.max(1, Math.ceil(Math.max(Math.abs(dx), Math.abs(dy)) / 0.2));
  const sx = dx / steps, sy = dy / steps;
  let moved = false;
  for (let i = 0; i < steps; i++) {
    if (sx && !blocked(e.x + sx, e.y, e.r)) { e.x += sx; moved = true; }
    if (sy && !blocked(e.x, e.y + sy, e.r)) { e.y += sy; moved = true; }
  }
  return moved;
}

function applyKnockback(e, dt) {
  if (!e.kbx && !e.kby) return;
  moveEntity(e, e.kbx * dt, e.kby * dt);
  const k = Math.max(0, 1 - dt * 10);
  e.kbx *= k; e.kby *= k;
  if (Math.abs(e.kbx) < 0.05 && Math.abs(e.kby) < 0.05) { e.kbx = 0; e.kby = 0; }
}

function overlapsTile(e, tx, ty) {
  const nx = clamp(e.x, tx, tx + 1), ny = clamp(e.y, ty, ty + 1);
  return Math.hypot(e.x - nx, e.y - ny) < e.r;
}

function nearObject(x, y, r, code) {
  const w = G.world;
  for (let ty = Math.floor(y - r); ty <= Math.floor(y + r); ty++)
    for (let tx = Math.floor(x - r); tx <= Math.floor(x + r); tx++)
      if (w.o(tx, ty) === code && Math.hypot(tx + 0.5 - x, ty + 0.5 - y) <= r) return true;
  return false;
}
const nearCampfire = () => nearObject(G.player.x, G.player.y, 2.6, 8);

// ---------- effects ----------
function burst(x, y, color, n, speed = 3) {
  for (let i = 0; i < n; i++) {
    const a = Math.random() * Math.PI * 2, s = speed * (0.4 + Math.random() * 0.8);
    G.particles.push({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s * 0.6, z: 0.2, vz: 2 + Math.random() * 3, life: 0.5 + Math.random() * 0.4, color });
  }
}
function floater(x, y, text, color) { G.floaters.push({ x, y, text, color, t: 0 }); }

function updateFx(dt) {
  for (const p of G.particles) {
    p.life -= dt; p.x += p.vx * dt; p.y += p.vy * dt;
    p.vz -= 14 * dt; p.z += p.vz * dt;
    if (p.z < 0) { p.z = 0; p.vz *= -0.3; p.vx *= 0.6; p.vy *= 0.6; }
  }
  G.particles = G.particles.filter(p => p.life > 0);
  for (const f of G.floaters) f.t += dt;
  G.floaters = G.floaters.filter(f => f.t < 0.9);
  G.shake = Math.max(0, G.shake - dt * 30);
}

// ---------- items on the ground ----------
function dropItem(id, n, x, y, fromPlayer) {
  const a = Math.random() * Math.PI * 2;
  G.drops.push({ id, n, x, y, vx: Math.cos(a) * 1.4, vy: Math.sin(a) * 1.4, z: 0, vz: 3, t: 0, waitAway: !!fromPlayer });
}

function updateDrops(dt) {
  const p = G.player;
  for (const d of G.drops) {
    d.t += dt;
    if (d.vx || d.vy) {
      const nx = d.x + d.vx * dt, ny = d.y + d.vy * dt;
      if (!G.world.solid(Math.floor(nx), Math.floor(ny))) { d.x = nx; d.y = ny; }
      d.vx *= Math.max(0, 1 - dt * 5); d.vy *= Math.max(0, 1 - dt * 5);
    }
    d.vz -= 14 * dt; d.z = Math.max(0, d.z + d.vz * dt);
    if (p.dead || d.t < 0.35) continue;
    const dist = Math.hypot(p.x - d.x, p.y - d.y);
    if (d.waitAway) { if (dist > 1.8) d.waitAway = false; continue; }
    if (!G.inv.space(d.id)) { if (dist < 0.6 && !d.warned) { UI.hint('Your bag is full.'); d.warned = true; } continue; }
    if (dist < 1.7) {
      const sp = 7 * dt;
      d.x += (p.x - d.x) / dist * Math.min(sp, dist);
      d.y += (p.y - d.y) / dist * Math.min(sp, dist);
    }
    if (dist < 0.45) {
      const left = G.inv.add(d.id, d.n);
      if (left < d.n) floater(p.x, p.y - 1, `+${d.n - left} ${ITEMS[d.id].name}`, '#f2efe6');
      d.n = left;
    }
  }
  G.drops = G.drops.filter(d => d.n > 0 && d.t < 300);
}

// ---------- player ----------
function updatePlayer(dt) {
  const p = G.player;
  p.atkCd -= dt; p.swing -= dt; p.hurt -= dt; p.inv -= dt; p.lastHurt += dt;
  if (p.dead) return;

  const mv = Input.move();
  p.moving = !!(mv.x || mv.y);
  if (p.moving) {
    moveEntity(p, mv.x * 3.6 * dt, mv.y * 3.6 * dt);
    const l = Math.hypot(mv.x, mv.y);
    p.fx = mv.x / l; p.fy = mv.y / l;
    if (Math.abs(mv.x) > 0.1) p.face = mv.x > 0 ? 1 : -1;
    p.anim += dt;
  }
  applyKnockback(p, dt);

  if (Input.aim) {
    const w = screenToWorld(Input.aim.x, Input.aim.y);
    const dx = w.x - p.x, dy = w.y - (p.y - 0.3), l = Math.hypot(dx, dy);
    if (l > 0.05) { p.fx = dx / l; p.fy = dy / l; if (Math.abs(dx) > 0.05) p.face = dx > 0 ? 1 : -1; }
  }
  if ((Input.acting() || Input.queued) && p.atkCd <= 0) { Input.queued = false; playerAct(); }

  if (G.mode === 'survival') {
    p.hunger = Math.max(0, p.hunger - dt * 0.2);
    if (p.hunger <= 0) {
      p.hp -= dt * 1.5;
      if (Math.random() < dt * 0.4) UI.hint('You are starving. Eat something.');
      if (p.hp <= 0) playerDie();
    } else if (p.hunger > 50 && p.lastHurt > 4) {
      p.hp = Math.min(p.maxHp, p.hp + dt * 1.2);
    }
  } else if (p.lastHurt > 5) {
    p.hp = Math.min(p.maxHp, p.hp + dt * 0.6);
  }
}

function heldItem() { const s = G.inv.slots[G.sel]; return s ? ITEMS[s.id] : null; }

function playerAct() {
  const it = heldItem();
  const p = G.player;
  // Food you can't use right now doesn't block punching.
  const wantsFood = it && it.food && (p.hunger < 95 || (it.food.hp > 0 && p.hp < p.maxHp));
  const wantsHeal = it && it.heal && p.hp < p.maxHp;
  if (wantsFood || wantsHeal || (it && (it.egg || it.summon || it.armor))) { p.atkCd = 0.4; useItem(G.sel); return; }
  if (it && it.place) { p.atkCd = 0.25; placeItem(G.sel); return; }
  attack(it && it.tool);
}

function attack(tool) {
  const p = G.player;
  p.atkCd = 0.36; p.swing = 0.18; p.swingDir = { x: p.fx, y: p.fy };
  const dmg = tool ? tool.dmg : 2;
  let best = null, bd = Infinity;
  for (const c of G.creatures) {
    const dx = c.x - p.x, dy = c.y - p.y, dist = Math.hypot(dx, dy);
    if (dist > 1.25 + c.r) continue;
    const dot = dist < 0.01 ? 1 : (dx * p.fx + dy * p.fy) / dist;
    if ((dist < 0.55 + c.r || dot > 0.3) && dist < bd) { bd = dist; best = c; }
  }
  if (best) { hitCreature(best, dmg, p.fx, p.fy); return; }

  const w = G.world;
  let target = null;
  for (const reach of [0.9, 0.45]) {
    const tx = Math.floor(p.x + p.fx * reach), ty = Math.floor(p.y + p.fy * reach);
    if (w.o(tx, ty)) { target = { x: tx, y: ty }; break; }
  }
  if (!target) {
    const tx = Math.floor(p.x), ty = Math.floor(p.y), o = w.o(tx, ty);
    if (o && !OBJ[o].placed) target = { x: tx, y: ty };
  }
  if (target) hitObject(target.x, target.y, tool);
}

function hitObject(tx, ty, tool) {
  const w = G.world, def = OBJ[w.o(tx, ty)];
  if (def.hard && (!tool || tool.kind !== 'pick')) {
    UI.hint('This rock is too hard for that. Use a pickaxe.');
    burst(tx + 0.5, ty + 0.6, def.color, 2);
    return;
  }
  let power = 1;
  if (tool) power = tool.kind === def.need ? tool.power : 1;
  if (def.placed) power = Math.max(power, 4);
  const broke = w.hit(tx, ty, power);
  burst(tx + 0.5, ty + 0.6, def.color, broke ? 10 : 4);
  G.shake = Math.max(G.shake, broke ? 3 : 1.5);
  if (broke) {
    for (const [id, a, b] of def.drops) { const n = rint(a, b); if (n > 0) dropItem(id, n, tx + 0.5, ty + 0.6); }
    if (G.home && G.home.x === tx && G.home.y === ty) G.home = null;
  } else if (!tool && def.need && Math.random() < 0.25) {
    UI.hint(def.need === 'axe' ? 'An axe would chop this much faster.' : 'A pickaxe would break this much faster.');
  }
}

function hurtPlayer(dmg, sx, sy) {
  const p = G.player;
  if (p.dead || p.inv > 0) return;
  const armor = p.armor ? ITEMS[p.armor].armor : 0;
  const real = Math.max(1, Math.round(dmg * (1 - armor)));
  p.hp -= real; p.inv = 0.45; p.hurt = 0.2; p.lastHurt = 0;
  const dx = p.x - sx, dy = p.y - sy, l = Math.hypot(dx, dy) || 1;
  p.kbx = dx / l * 6; p.kby = dy / l * 6;
  G.shake = Math.max(G.shake, 5);
  floater(p.x, p.y - 1, `-${real}`, '#ee6a5a');
  if (p.hp <= 0) playerDie();
}

function playerDie() {
  const p = G.player;
  p.hp = 0; p.dead = true; G.dead = true;
  Input.release();
  burst(p.x, p.y - 0.3, '#ee6a5a', 14);
  if (G.mode === 'arena') {
    const best = Math.max(G.wave, +(store.get(BEST_KEY) || 0));
    store.set(BEST_KEY, String(best));
    UI.showDeath('Arena over', `You reached wave ${G.wave}. Your best is wave ${best}.`, 'Try again');
  } else {
    const home = G.home && G.world.o(G.home.x, G.home.y) === 8;
    UI.showDeath('You fainted', `You keep everything in your bag. You'll wake up ${home ? 'at your campfire' : 'where you started'}.`, 'Wake up');
    save();
  }
}

function respawn() {
  if (G.mode === 'arena') { startArena(); return; }
  const p = G.player, w = G.world;
  let spot = { x: w.spawn.x + 0.5, y: w.spawn.y + 0.5 };
  if (G.home && w.o(G.home.x, G.home.y) === 8) {
    for (const [dx, dy] of [[0, 1], [1, 0], [-1, 0], [0, -1], [1, 1], [-1, 1]]) {
      const x = G.home.x + dx + 0.5, y = G.home.y + dy + 0.5;
      if (!blocked(x, y, p.r)) { spot = { x, y }; break; }
    }
  }
  Object.assign(p, { x: spot.x, y: spot.y, hp: p.maxHp, hunger: Math.max(p.hunger, 60), dead: false, inv: 2, kbx: 0, kby: 0 });
  G.creatures = G.creatures.filter(c => c.d.passive || c.d.boss || Math.hypot(c.x - p.x, c.y - p.y) > 12);
  G.dead = false;
  UI.hideScreens();
}

// ---------- using items ----------
function useItem(i) {
  const s = G.inv.slots[i];
  if (!s) return;
  const id = s.id, it = ITEMS[id], p = G.player;
  if (it.food) {
    if (p.hunger >= 100 && !(it.food.hp > 0 && p.hp < p.maxHp)) { UI.hint('You are full.'); return; }
    p.hunger = Math.min(100, p.hunger + it.food.hunger);
    if (it.food.hp) p.hp = clamp(p.hp + it.food.hp, 1, p.maxHp);
    G.inv.removeAt(i);
    floater(p.x, p.y - 1, `+${it.food.hunger} food`, '#f2cf5b');
    if (id === 'meat') UI.hint('Raw meat upset your stomach. Cook it at a campfire.');
  } else if (it.heal) {
    if (p.hp >= p.maxHp) { UI.hint('You are already at full health.'); return; }
    p.hp = Math.min(p.maxHp, p.hp + it.heal);
    G.inv.removeAt(i);
    floater(p.x, p.y - 1, `+${it.heal}`, '#7cc35a');
  } else if (it.egg) {
    G.inv.removeAt(i);
    if (G.pet) {
      const back = 'egg_' + G.pet.type;
      if (G.inv.add(back, 1)) dropItem(back, 1, p.x, p.y, true);
      UI.toast(`${G.pet.def.name} went back into its egg.`);
    }
    hatchPet(it.egg);
    UI.toast(`Your ${PETS[it.egg].name} hatched! It follows you and fights at your side.`, 'good');
  } else if (it.summon) {
    if (G.creatures.some(c => c.d.boss)) { UI.hint('The Stone Golem is already awake.'); return; }
    if (spawnBoss()) G.inv.removeAt(i);
  } else if (it.armor) {
    wear(i);
  }
}

function wear(i) {
  const p = G.player, id = G.inv.slots[i].id;
  G.inv.slots[i] = p.armor ? { id: p.armor, n: 1 } : null;
  p.armor = id;
  G.invDirty = true;
  UI.toast(`Wearing ${ITEMS[id].name}.`);
}

function takeOffArmor() {
  const p = G.player;
  if (!p.armor) return;
  if (G.inv.add(p.armor, 1)) { UI.hint('No room in your bag.'); return; }
  p.armor = null;
}

function placeItem(i) {
  const s = G.inv.slots[i], it = ITEMS[s.id], p = G.player, w = G.world;
  const def = OBJ[it.place];
  for (const reach of [1.0, 1.6]) {
    const tx = Math.floor(p.x + p.fx * reach), ty = Math.floor(p.y + p.fy * reach);
    if (!w.inb(tx, ty) || w.g(tx, ty) === 0 || w.o(tx, ty) !== 0) continue;
    if (def.solid && (overlapsTile(p, tx, ty) || G.creatures.some(c => overlapsTile(c, tx, ty)) || (G.pet && overlapsTile(G.pet, tx, ty)))) continue;
    w.set(tx, ty, it.place);
    G.inv.removeAt(i);
    burst(tx + 0.5, ty + 0.8, def.color, 5, 2);
    if (it.place === 8) {
      G.home = { x: tx, y: ty };
      if (!G.flags.campfire) UI.toast('Campfire built. You will wake up here, and monsters will not appear close by.', 'good');
      G.flags.campfire = true;
    }
    return;
  }
  UI.hint('No room to place that here. Face an empty spot.');
}

// ---------- crafting ----------
function potRecipes() {
  const key = [...new Set(G.pot.filter(Boolean))].sort().join('+');
  return RECIPES.filter(r => r.key === key);
}

function mixPot() {
  if (!G.pot.some(Boolean)) { UI.hint('Put some ingredients in the pot first.'); return []; }
  const found = potRecipes();
  if (!found.length) { UI.toast('Nothing happens. Try a different mix.'); return []; }
  let fresh = 0;
  for (const r of found) if (!G.discovered.has(r.out)) { G.discovered.add(r.out); fresh++; }
  if (fresh) UI.toast(fresh > 1 ? `${fresh} new recipes found!` : 'New recipe found!', 'good');
  return found;
}

function craft(r) {
  if (r.near === 'campfire' && !nearCampfire()) { UI.hint('Stand next to a campfire to make this.'); return; }
  if (!G.inv.has(r.cost)) { UI.hint('You need more ingredients.'); return; }
  for (const [id, n] of Object.entries(r.cost)) G.inv.remove(id, n);
  const n = r.n || 1;
  const left = G.inv.add(r.out, n);
  if (left) dropItem(r.out, left, G.player.x, G.player.y, true);
  G.discovered.add(r.out);
  UI.toast(`Made ${n > 1 ? n + ' ' : ''}${ITEMS[r.out].name}`, 'good');
}

function checkGoals() {
  while (G.goal < GOALS.length && GOALS[G.goal].done(G)) {
    const goal = GOALS[G.goal];
    G.goal++;
    UI.toast(`Goal complete: ${goal.text}`, 'good');
    if (goal.reward) for (const [id, n] of goal.reward) {
      const left = G.inv.add(id, n);
      if (left) dropItem(id, left, G.player.x, G.player.y);
      floater(G.player.x, G.player.y - 1.3, `+${n} ${ITEMS[id].name}`, '#f2cf5b');
    }
  }
}

// ---------- creatures ----------
function spawnCreature(type, x, y, hpMul = 1) {
  const d = CREATURES[type];
  const c = { type, d, x, y, r: d.r, hp: d.hp * hpMul, maxHp: d.hp * hpMul, face: 1, anim: Math.random() * 5,
    cd: 0.6, hurt: 0, kbx: 0, kby: 0, vx: 0, vy: 0, wt: 0, stuck: 0, detour: 0, slam: 0, slamCd: 3, spikeCd: 0, aggroed: false, dead: false };
  G.creatures.push(c);
  return c;
}

function spawnBoss() {
  const p = G.player;
  for (let t = 0; t < 60; t++) {
    const a = Math.random() * Math.PI * 2, r = 9 + Math.random() * 4;
    const x = Math.floor(p.x + Math.cos(a) * r) + 0.5, y = Math.floor(p.y + Math.sin(a) * r) + 0.5;
    if (G.world.g(Math.floor(x), Math.floor(y)) === 0 || blocked(x, y, 0.7)) continue;
    spawnCreature('golem', x, y, G.mode === 'arena' ? 0.6 + G.wave * 0.04 : 1);
    UI.toast('The ground shakes. The Stone Golem is awake!', 'danger');
    G.shake = 8;
    return true;
  }
  UI.hint('The idol stays quiet. Try somewhere with more open ground.');
  return false;
}

function hitCreature(c, dmg, dx, dy) {
  if (c.dead) return;
  c.hp -= dmg; c.hurt = 0.15; c.aggroed = true;
  const kb = c.d.boss ? 1.2 : 7;
  c.kbx = dx * kb; c.kby = dy * kb;
  floater(c.x, c.y - (c.d.scale || 1) * 0.9, String(Math.round(dmg)), '#ffffff');
  burst(c.x, c.y - 0.3, '#ffffff', 3);
  G.shake = Math.max(G.shake, c.d.boss ? 2 : 1);
  if (c.hp <= 0) killCreature(c);
}

function killCreature(c) {
  c.dead = true;
  const d = c.d;
  burst(c.x, c.y - 0.3, d.boss ? '#c2c6cc' : '#f2efe6', d.boss ? 30 : 10, d.boss ? 5 : 3);
  for (const [id, a, b] of d.drops) { const n = rint(a, b); if (n > 0) dropItem(id, n, c.x, c.y); }
  if (d.egg && Math.random() < d.egg[1]) {
    dropItem(d.egg[0], 1, c.x, c.y);
    UI.toast(`The ${d.name} left an egg behind!`, 'good');
  }
  if (G.mode === 'arena') {
    if (Math.random() < 0.12) dropItem('cooked_meat', 1, c.x, c.y);
    if (Math.random() < 0.08) dropItem('bandage', 1, c.x, c.y);
  }
  if (d.boss) {
    G.flags.golem = true;
    G.shake = 12;
    UI.toast('The Stone Golem crumbles! It dropped its heart.', 'good');
  }
}

function pickTarget(c) {
  const p = G.player, range = c.d.aggro * (c.aggroed ? 1.8 : 1);
  let best = null, bd = range;
  if (!p.dead) { const dd = Math.hypot(p.x - c.x, p.y - c.y); if (dd < bd) { bd = dd; best = p; } }
  const pet = G.pet;
  if (pet && pet.fainted <= 0) { const dd = Math.hypot(pet.x - c.x, pet.y - c.y); if (dd < bd - 0.5) { bd = dd; best = pet; } }
  return best;
}

function updateCreature(c, dt) {
  const d = c.d, p = G.player, w = G.world;
  c.anim += dt; c.cd -= dt; c.hurt -= dt; c.spikeCd -= dt; c.slamCd -= dt; c.detour -= dt;
  applyKnockback(c, dt);

  if (d.nocturnal && G.mode === 'survival' && !isNight()) {
    c.hp -= 14 * dt;
    if (Math.random() < dt * 10) G.particles.push({ x: c.x + (Math.random() - 0.5) * 0.4, y: c.y, vx: 0, vy: 0, z: 0.6, vz: 1.5, life: 0.6, color: '#5c616b' });
    if (c.hp <= 0) { c.dead = true; burst(c.x, c.y - 0.3, '#5c616b', 8); }
    return;
  }
  if (!d.passive && c.spikeCd <= 0 && w.o(Math.floor(c.x), Math.floor(c.y)) === 10) {
    c.spikeCd = 0.6;
    hitCreature(c, OBJ[10].trap, 0, 0);
    if (c.dead) return;
  }
  if (!d.boss && G.mode === 'survival' && Math.hypot(c.x - p.x, c.y - p.y) > 30) { c.dead = true; return; }

  if (c.slam > 0) {
    c.slam -= dt;
    if (c.slam <= 0) golemSlam(c);
    return;
  }

  let vx = 0, vy = 0, speed = d.speed, chasing = false;
  if (c.detour > 0) {
    vx = c.vx; vy = c.vy;
  } else if (d.passive) {
    const dx = c.x - p.x, dy = c.y - p.y, dd = Math.hypot(dx, dy);
    if (!p.dead && dd < 4) { vx = dx / dd; vy = dy / dd; }
    else { wander(c, dt); vx = c.vx; vy = c.vy; speed *= 0.4; }
  } else {
    const t = pickTarget(c);
    if (t) {
      const dx = t.x - c.x, dy = t.y - c.y, dd = Math.hypot(dx, dy) || 0.01;
      if (d.boss && dd < 2.4 && c.slamCd <= 0) { c.slam = 0.8; c.slamCd = 4.5; return; }
      if (dd > c.r + t.r + 0.25) { vx = dx / dd; vy = dy / dd; chasing = true; }
      else if (c.cd <= 0) {
        c.cd = d.atkCd;
        if (t === p) hurtPlayer(d.dmg, c.x, c.y); else hurtPet(d.dmg);
      }
      if (Math.abs(dx) > 0.1) c.face = dx > 0 ? 1 : -1;
    } else {
      wander(c, dt); vx = c.vx; vy = c.vy; speed *= 0.4;
    }
  }
  if (d.hop) speed *= Math.sin(c.anim * 7) > 0 ? 1.7 : 0.15;
  c.moving = !!(vx || vy);
  if (vx || vy) {
    const moved = moveEntity(c, vx * speed * dt, vy * speed * dt);
    if (Math.abs(vx) > 0.05 && c.detour <= 0 && !chasing) c.face = vx > 0 ? 1 : -1;
    c.stuck = moved ? 0 : c.stuck + dt;
    if (c.stuck > 0.5 && chasing) {
      const bx = Math.floor(c.x + vx * (c.r + 0.4)), by = Math.floor(c.y + vy * (c.r + 0.4));
      const o = w.o(bx, by);
      if (d.breaker && o && OBJ[o].placed && OBJ[o].solid) {
        if (c.cd <= 0) {
          c.cd = d.atkCd;
          const broke = w.hit(bx, by, d.dmg / 3);
          burst(bx + 0.5, by + 0.6, OBJ[o].color, broke ? 10 : 3);
          if (broke) UI.hint(`A ${d.name} broke through your ${OBJ[o].name}!`);
        }
      } else {
        const a = Math.atan2(vy, vx) + (Math.random() < 0.5 ? 1 : -1) * (1 + Math.random());
        c.vx = Math.cos(a); c.vy = Math.sin(a); c.detour = 0.6; c.stuck = 0;
      }
    }
  }
}

function wander(c, dt) {
  c.wt -= dt;
  if (c.wt > 0) return;
  if (Math.random() < 0.4) { c.vx = 0; c.vy = 0; }
  else { const a = Math.random() * Math.PI * 2; c.vx = Math.cos(a); c.vy = Math.sin(a); }
  c.wt = 1 + Math.random() * 2.5;
}

function golemSlam(c) {
  const p = G.player, R = 2.6;
  G.shake = 10;
  for (let i = 0; i < 24; i++) {
    const a = i / 24 * Math.PI * 2;
    G.particles.push({ x: c.x + Math.cos(a) * 0.8, y: c.y + Math.sin(a) * 0.5, vx: Math.cos(a) * 5, vy: Math.sin(a) * 3, z: 0.1, vz: 2, life: 0.5, color: '#8a8f98' });
  }
  if (!p.dead && Math.hypot(p.x - c.x, p.y - c.y) < R) hurtPlayer(c.d.dmg * 1.4, c.x, c.y);
  if (G.pet && G.pet.fainted <= 0 && Math.hypot(G.pet.x - c.x, G.pet.y - c.y) < R) hurtPet(c.d.dmg * 1.4);
}

// ---------- pets ----------
function hatchPet(type, quiet) {
  const p = G.player, def = PETS[type];
  G.pet = { type, def, x: p.x + 0.5, y: p.y, r: 0.25, hp: def.hp, maxHp: def.hp, cd: 0, face: 1, anim: 0, hurt: 0, fainted: 0, lastHurt: 9 };
  if (blocked(G.pet.x, G.pet.y, G.pet.r)) G.pet.x = p.x;
  if (!quiet) for (let i = 0; i < 6; i++) G.floaters.push({ x: p.x + (Math.random() - 0.5), y: p.y - 0.8, text: '♥', color: '#ee6a5a', t: Math.random() * 0.3 });
}

function hurtPet(dmg) {
  const pet = G.pet;
  if (!pet || pet.fainted > 0) return;
  pet.hp -= dmg; pet.hurt = 0.15; pet.lastHurt = 0;
  floater(pet.x, pet.y - 0.8, `-${Math.round(dmg)}`, '#ee6a5a');
  if (pet.hp <= 0) {
    pet.fainted = 40;
    burst(pet.x, pet.y - 0.2, '#f2efe6', 8);
    UI.toast(`${pet.def.name} fainted. It will be back soon.`);
  }
}

function updatePet(dt) {
  const pet = G.pet, p = G.player, def = pet.def;
  pet.anim += dt; pet.cd -= dt; pet.hurt -= dt; pet.lastHurt += dt;
  if (pet.fainted > 0) {
    pet.fainted -= dt;
    if (pet.fainted <= 0) { pet.hp = pet.maxHp; pet.x = p.x; pet.y = p.y; UI.toast(`${def.name} is back on its feet.`); }
    return;
  }
  if (pet.lastHurt > 5) pet.hp = Math.min(pet.maxHp, pet.hp + dt * 3);
  let target = null, bd = 6.5;
  for (const c of G.creatures) {
    if (c.d.passive || c.dead) continue;
    const dd = Math.hypot(c.x - p.x, c.y - p.y);
    if (dd < bd) { bd = dd; target = c; }
  }
  let vx = 0, vy = 0;
  if (target) {
    const dx = target.x - pet.x, dy = target.y - pet.y, dd = Math.hypot(dx, dy) || 0.01;
    if (dd > target.r + pet.r + 0.2) { vx = dx / dd; vy = dy / dd; }
    else if (pet.cd <= 0) { pet.cd = 0.8; hitCreature(target, def.dmg, dx / dd, dy / dd); }
    if (Math.abs(dx) > 0.1) pet.face = dx > 0 ? 1 : -1;
  } else {
    const dx = p.x - pet.x, dy = p.y - pet.y, dd = Math.hypot(dx, dy);
    if (dd > 1.6) { vx = dx / dd; vy = dy / dd; if (Math.abs(dx) > 0.1) pet.face = dx > 0 ? 1 : -1; }
  }
  if (Math.hypot(p.x - pet.x, p.y - pet.y) > 12) { pet.x = p.x; pet.y = p.y; }
  if (vx || vy) moveEntity(pet, vx * def.speed * dt, vy * def.speed * dt);
}

// ---------- spawning ----------
function pickSpawnType(ground, night) {
  const r = Math.random();
  if (night) {
    if (ground === 4) return r < 0.6 ? 'spider' : 'ghoul';
    return r < 0.55 ? 'ghoul' : r < 0.8 ? 'slime' : 'spider';
  }
  if (ground === 4) return r < 0.5 ? 'spider' : null;
  if (ground === 2 || ground === 3) return r < 0.6 ? 'rabbit' : 'slime';
  return null;
}

function spawning(dt) {
  G.spawnT -= dt;
  if (G.spawnT > 0) return;
  G.spawnT = 1.6;
  const night = isNight(), p = G.player;
  let hostile = 0, rabbits = 0;
  for (const c of G.creatures) { if (c.d.passive) rabbits++; else if (!c.d.boss) hostile++; }
  const cap = night ? 6 + Math.min(G.day, 8) : 3;
  for (let t = 0; t < 6; t++) {
    const a = Math.random() * Math.PI * 2, r = 11 + Math.random() * 6;
    const tx = Math.floor(p.x + Math.cos(a) * r), ty = Math.floor(p.y + Math.sin(a) * r);
    const ground = G.world.g(tx, ty);
    if (ground === 0 || blocked(tx + 0.5, ty + 0.5, 0.3)) continue;
    const type = pickSpawnType(ground, night);
    if (!type) continue;
    if (type === 'rabbit') { if (rabbits >= 5) continue; }
    else if (hostile >= cap || nearObject(tx + 0.5, ty + 0.5, 8, 8)) continue;
    spawnCreature(type, tx + 0.5, ty + 0.5);
    return;
  }
}

function arenaWaves(dt) {
  const hostile = G.creatures.filter(c => !c.d.passive).length;
  if (G.waveState === 'fight') {
    if (hostile > 0) return;
    G.waveState = 'break'; G.waveT = 5;
    G.player.hp = Math.min(G.player.maxHp, G.player.hp + 25);
    UI.toast(`Wave ${G.wave} cleared! +25 health`, 'good');
    store.set(BEST_KEY, String(Math.max(G.wave, +(store.get(BEST_KEY) || 0))));
    return;
  }
  G.waveT -= dt;
  if (G.waveT > 0) return;
  G.wave++;
  G.waveState = 'fight';
  const n = G.wave, mul = 1 + (n - 1) * 0.08, w = G.world, p = G.player;
  let count = 2 + Math.floor(n * 1.3);
  if (n % 5 === 0) { spawnBoss(); count = Math.floor(count / 2); }
  else UI.toast(`Wave ${n}`, 'big');
  for (let i = 0; i < count; i++) {
    const r = Math.random();
    const type = n < 3 ? 'slime' : r < 0.4 ? 'slime' : r < 0.7 || n < 4 ? 'spider' : 'ghoul';
    for (let t = 0; t < 30; t++) {
      const x = rint(1, w.w - 2) + 0.5, y = rint(1, w.h - 2) + 0.5;
      if (Math.hypot(x - p.x, y - p.y) < 5 || blocked(x, y, 0.3)) continue;
      spawnCreature(type, x, y, mul).aggroed = true;
      break;
    }
  }
}

// ---------- main update ----------
function update(dt) {
  G.time += dt;
  if (G.mode === 'survival') advanceClock(dt);
  updatePlayer(dt);
  for (const c of G.creatures) if (!c.dead) updateCreature(c, dt);
  G.creatures = G.creatures.filter(c => !c.dead);
  if (G.pet) updatePet(dt);
  updateDrops(dt);
  updateFx(dt);
  if (G.mode === 'survival') {
    spawning(dt);
    G.regrowT -= dt;
    if (G.regrowT <= 0) { G.regrowT = 1.2; G.world.regrow(G.player.x, G.player.y); }
    G.goalT -= dt;
    if (G.goalT <= 0) { G.goalT = 0.5; checkGoals(); }
    G.saveT += dt;
    if (G.saveT > 20) { G.saveT = 0; save(); }
  } else if (G.mode === 'arena') {
    arenaWaves(dt);
  }
}

// ---------- drawing ----------
function render() {
  ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  ctx.imageSmoothingEnabled = false;
  ctx.fillStyle = '#2c64a0';
  ctx.fillRect(0, 0, VW, VH);
  const w = G.world;
  if (!w) return;

  if (G.mode === 'title') {
    const t = G.time * 0.04;
    G.camX = w.w / 2 + Math.cos(t) * 20;
    G.camY = w.h / 2 + Math.sin(t * 0.8) * 16;
  } else {
    G.camX = G.player.x; G.camY = G.player.y - 0.4;
  }
  const sh = G.shake;
  const camL = Math.round(VW / 2 - G.camX * TS + (Math.random() - 0.5) * sh);
  const camT = Math.round(VH / 2 - G.camY * TS + (Math.random() - 0.5) * sh);
  const x0 = Math.floor(-camL / TS) - 1, x1 = Math.ceil((VW - camL) / TS) + 1;
  const y0 = Math.floor(-camT / TS) - 1, y1 = Math.ceil((VH - camT) / TS) + 2;
  const wf = Math.floor(G.time * 1.5);

  for (let ty = y0; ty <= y1; ty++) {
    for (let tx = x0; tx <= x1; tx++) {
      const g = w.g(tx, ty);
      const v = w.inb(tx, ty) ? w.variant[ty * w.w + tx] : ((tx * 7 + ty * 13) & 3);
      const spr = g === 0 ? GROUND[0][(wf + tx + ty) & 3][v % 3] : GROUND[g][v];
      ctx.drawImage(spr, camL + tx * TS, camT + ty * TS, TS, TS);
      if (g === 0 && w.g(tx, ty - 1) !== 0) {
        ctx.fillStyle = 'rgba(242,239,230,0.35)';
        ctx.fillRect(camL + tx * TS, camT + ty * TS, TS, PX);
      }
    }
  }

  const sprites = [];
  for (let ty = y0; ty <= y1; ty++) {
    for (let tx = x0; tx <= x1; tx++) {
      const o = w.o(tx, ty);
      if (!o) continue;
      const def = OBJ[o];
      if (def.flat) drawObject(tx, ty, def, camL, camT);
      else sprites.push({ y: ty + 0.9, obj: def, tx, ty });
    }
  }
  for (const d of G.drops) drawDrop(d, camL, camT);
  for (const c of G.creatures) sprites.push({ y: c.y, c });
  if (G.pet && G.pet.fainted <= 0) sprites.push({ y: G.pet.y, pet: G.pet });
  if (G.mode !== 'title') sprites.push({ y: G.player.y, player: true });
  sprites.sort((a, b) => a.y - b.y);

  for (const c of G.creatures) {
    if (c.slam > 0) {
      const k = 1 - c.slam / 0.8;
      ctx.fillStyle = `rgba(226,85,63,${0.15 + k * 0.3})`;
      ctx.beginPath();
      ctx.ellipse(camL + c.x * TS, camT + c.y * TS, 2.6 * TS, 1.7 * TS, 0, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  for (const s of sprites) {
    if (s.obj) drawObject(s.tx, s.ty, s.obj, camL, camT);
    else if (s.c) drawCreature(s.c, camL, camT);
    else if (s.pet) drawPet(s.pet, camL, camT);
    else drawPlayer(camL, camT);
  }

  for (const p of G.particles) {
    ctx.fillStyle = p.color;
    const sz = Math.max(2, PX * 0.9);
    ctx.fillRect(Math.round(camL + p.x * TS - sz / 2), Math.round(camT + (p.y - p.z) * TS - sz / 2), sz, sz);
  }

  drawLighting(camL, camT, x0, x1, y0, y1);

  ctx.textAlign = 'center';
  ctx.font = `${Math.round(TS * 0.3)}px Silkscreen, monospace`;
  ctx.lineWidth = 3;
  ctx.strokeStyle = '#13111b';
  for (const f of G.floaters) {
    const a = 1 - f.t / 0.9;
    ctx.globalAlpha = Math.max(0, a);
    const x = camL + f.x * TS, y = camT + (f.y - f.t * 0.8) * TS;
    ctx.strokeText(f.text, x, y);
    ctx.fillStyle = f.color;
    ctx.fillText(f.text, x, y);
  }
  ctx.globalAlpha = 1;
}

function drawObject(tx, ty, def, camL, camT) {
  let spr = SPR[def.sprite];
  if (def.id === 'campfire' && Math.floor(G.time * 6 + tx) % 2) spr = SPR.campfire2;
  const w = spr.width * PX, h = spr.height * PX;
  let x = camL + tx * TS + (TS - w) / 2;
  const y = camT + (ty + 1) * TS - h;
  const i = ty * G.world.w + tx;
  const hit = G.world.hitAt.get(i);
  const since = hit ? performance.now() - hit : 1e9;
  if (since < 160) x += Math.sin(since / 20) * PX * 0.6;
  ctx.drawImage(spr, Math.round(x), Math.round(y), w, h);
  if (since < 2500) {
    const f = G.world.hpFraction(tx, ty);
    if (f < 1) drawBar(camL + tx * TS + TS * 0.15, camT + ty * TS + TS * 1.02, TS * 0.7, f, '#f2cf5b');
  }
}

function drawBar(x, y, w, f, color) {
  const h = Math.max(3, PX * 0.7);
  ctx.fillStyle = '#13111b';
  ctx.fillRect(Math.round(x - 1), Math.round(y - 1), Math.round(w + 2), Math.round(h + 2));
  ctx.fillStyle = color;
  ctx.fillRect(Math.round(x), Math.round(y), Math.round(w * clamp(f, 0, 1)), Math.round(h));
}

function drawShadow(x, y, rw) {
  ctx.fillStyle = 'rgba(19,17,27,0.28)';
  ctx.beginPath();
  ctx.ellipse(x, y, rw, rw * 0.38, 0, 0, Math.PI * 2);
  ctx.fill();
}

function drawSprite(name, e, scale, camL, camT, lift, flash) {
  const flip = e.face < 0 ? '_l' : '';
  const spr = SPR[name + flip];
  const w = spr.width * PX * scale, h = spr.height * PX * scale;
  const cx = camL + e.x * TS, feet = camT + (e.y + e.r * 0.8) * TS;
  drawShadow(cx, feet - PX * 0.5, w * 0.36);
  const x = Math.round(cx - w / 2), y = Math.round(feet - h - lift);
  ctx.drawImage(spr, x, y, w, h);
  if (flash) {
    const wn = name.startsWith('player') ? 'player_white' : name + '_w';
    ctx.globalAlpha = 0.75;
    ctx.drawImage(SPR[wn + flip], x, y, w, h);
    ctx.globalAlpha = 1;
  }
  return { x, y, w, h };
}

function drawCreature(c, camL, camT) {
  const d = c.d, scale = d.scale || 1;
  let lift = 0;
  if (d.hop) lift = Math.max(0, Math.sin(c.anim * 7)) * PX * 2;
  else if (c.moving) lift = Math.abs(Math.sin(c.anim * 10)) * PX * 0.6;
  if (c.slam > 0) lift = (1 - c.slam / 0.8) * PX * 4;
  const box = drawSprite(c.type, c, scale, camL, camT, lift, c.hurt > 0);
  if (!d.boss && c.hp < c.maxHp) drawBar(box.x + box.w * 0.1, box.y - PX * 1.5, box.w * 0.8, c.hp / c.maxHp, '#e2553f');
}

function drawPet(pet, camL, camT) {
  const lift = pet.def.sprite === 'slime' ? Math.max(0, Math.sin(pet.anim * 8)) * PX * 1.5 : 0;
  const box = drawSprite(pet.def.sprite, pet, pet.def.scale, camL, camT, lift, pet.hurt > 0);
  const hs = PX * 0.6;
  ctx.drawImage(SPR.heart, Math.round(box.x + box.w / 2 - 3.5 * hs), Math.round(box.y - hs * 7), 7 * hs, 6 * hs);
  if (pet.hp < pet.maxHp) drawBar(box.x + box.w * 0.1, box.y - hs * 9, box.w * 0.8, pet.hp / pet.maxHp, '#7cc35a');
}

function drawPlayer(camL, camT) {
  const p = G.player;
  if (p.dead) return;
  const walk = p.moving && Math.floor(p.anim * 8) % 2 === 1;
  const name = `player${walk ? '_walk' : ''}_${p.armor || 'none'}`;
  const flash = p.hurt > 0 || (p.inv > 0 && Math.floor(G.time * 20) % 2 === 0 && p.inv < 0.45);
  const box = drawSprite(name, p, 1, camL, camT, 0, p.hurt > 0);
  if (flash && p.hurt <= 0) { ctx.globalAlpha = 0.4; ctx.drawImage(SPR[name + (p.face < 0 ? '_l' : '')], box.x, box.y, box.w, box.h); ctx.globalAlpha = 1; }

  const cx = camL + p.x * TS, cy = box.y + box.h * 0.62;
  if (p.swing > 0) {
    const a = Math.atan2(p.swingDir.y, p.swingDir.x), k = 1 - p.swing / 0.18;
    ctx.strokeStyle = `rgba(242,239,230,${0.8 * (1 - k)})`;
    ctx.lineWidth = Math.max(3, PX * 1.2);
    ctx.beginPath();
    ctx.arc(cx, cy - TS * 0.1, TS * 0.95, a - 1 + k * 0.6, a + 0.4 + k * 0.6);
    ctx.stroke();
  }
  const s = G.inv.slots[G.sel];
  if (s) {
    const spr = SPR[ITEMS[s.id].sprite || s.id];
    const size = TS * 0.55;
    ctx.save();
    ctx.translate(Math.round(cx + p.face * TS * 0.32), Math.round(cy));
    let ang = 0;
    if (p.swing > 0) ang = (-1.3 + (1 - p.swing / 0.18) * 2.4);
    if (p.face < 0) ctx.scale(-1, 1);
    ctx.rotate(ang);
    ctx.drawImage(spr, -size * 0.2, -size * 0.85, size, size);
    ctx.restore();
  }
}

function drawDrop(d, camL, camT) {
  const size = TS * 0.5;
  const x = camL + d.x * TS, y = camT + d.y * TS;
  const bob = Math.sin(G.time * 4 + d.x * 3) * PX * 0.5 + d.z * TS * 0.4;
  drawShadow(x, y + size * 0.35, size * 0.3);
  ctx.drawImage(SPR[ITEMS[d.id].sprite || d.id], Math.round(x - size / 2), Math.round(y - size * 0.6 - bob), size, size);
}

function drawLighting(camL, camT, x0, x1, y0, y1) {
  const dark = darkness();
  if (dark <= 0.01) return;
  const w = G.world;
  lctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  lctx.globalCompositeOperation = 'source-over';
  lctx.clearRect(0, 0, VW, VH);
  lctx.fillStyle = `rgba(10,12,34,${dark})`;
  lctx.fillRect(0, 0, VW, VH);
  lctx.globalCompositeOperation = 'destination-out';

  const lights = [];
  for (let ty = y0 - 6; ty <= y1 + 6; ty++) for (let tx = x0 - 6; tx <= x1 + 6; tx++) {
    const def = OBJ[w.o(tx, ty)];
    if (def && def.light) lights.push([tx + 0.5, ty + 0.5, def.light, true]);
  }
  const p = G.player;
  if (G.mode !== 'title' && !p.dead) {
    const held = G.inv.slots[G.sel];
    lights.push([p.x, p.y - 0.3, held && held.id === 'torch' ? 4.5 : 2.2, held && held.id === 'torch']);
  }
  for (const c of G.creatures) if (c.type === 'slime') lights.push([c.x, c.y - 0.2, 1.1, false]);

  for (const [x, y, r0, fire] of lights) {
    const r = r0 * TS * (fire ? 1 + Math.sin(G.time * 9 + x) * 0.03 : 1);
    const sx = camL + x * TS, sy = camT + y * TS;
    const g = lctx.createRadialGradient(sx, sy, 0, sx, sy, r);
    g.addColorStop(0, 'rgba(0,0,0,1)');
    g.addColorStop(0.55, 'rgba(0,0,0,0.75)');
    g.addColorStop(1, 'rgba(0,0,0,0)');
    lctx.fillStyle = g;
    lctx.fillRect(sx - r, sy - r, r * 2, r * 2);
  }
  ctx.drawImage(lightCanvas, 0, 0, VW, VH);

  ctx.globalCompositeOperation = 'lighter';
  for (const [x, y, r0, fire] of lights) {
    if (!fire) continue;
    const r = r0 * TS * 0.8, sx = camL + x * TS, sy = camT + y * TS;
    const g = ctx.createRadialGradient(sx, sy, 0, sx, sy, r);
    g.addColorStop(0, `rgba(242,140,50,${0.22 * dark})`);
    g.addColorStop(1, 'rgba(242,140,50,0)');
    ctx.fillStyle = g;
    ctx.fillRect(sx - r, sy - r, r * 2, r * 2);
  }
  ctx.globalCompositeOperation = 'source-over';
}

// ---------- loop ----------
let last = performance.now();
function frame(now) {
  const dt = Math.min(0.05, (now - last) / 1000);
  last = now;
  if (G.mode === 'title') G.time += dt;
  else if (!G.paused && !G.bagOpen && !G.dead) update(dt);
  else if (G.dead) { G.time += dt; updateFx(dt); }
  render();
  UI.hud();
  requestAnimationFrame(frame);
}

function playing() { return G.mode !== 'title' && !G.paused && !G.bagOpen && !G.dead; }

function boot() {
  buildSprites();
  resize();
  window.addEventListener('resize', resize);
  UI.init();
  Input.init({
    playing,
    escape() {
      if (G.bagOpen) UI.closeBag();
      else if (G.paused) UI.resume();
      else if (playing()) UI.pause();
    },
    toggleBag() { if (G.bagOpen) UI.closeBag(); else if (playing()) UI.openBag(); },
    select(i) { G.sel = i; G.invDirty = true; },
    cycle(d) { G.sel = (G.sel + d + HOTBAR) % HOTBAR; G.invDirty = true; },
  });
  G.world = titleWorld();
  UI.showTitle();
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) return;
    save();
    if (playing()) UI.pause();
  });
  window.addEventListener('pagehide', save);
  requestAnimationFrame(frame);
}

boot();
