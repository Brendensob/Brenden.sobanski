'use strict';
// Everything drawn with HTML: the HUD, the bag, crafting, and the menu screens.

const $ = s => document.querySelector(s);

const UI = {
  bagSel: null,
  moveFrom: null,
  potFound: [],
  lastHint: '',
  lastHintAt: 0,
  newArmed: 0,
  cache: {},

  init() {
    const hb = $('#hotbar');
    for (let i = 0; i < HOTBAR; i++) {
      const b = document.createElement('button');
      b.className = 'slot';
      b.addEventListener('click', () => { G.sel = i; G.invDirty = true; });
      hb.append(b);
    }
    const grid = $('#bagGrid');
    for (let i = 0; i < BAG_SIZE; i++) {
      const b = document.createElement('button');
      b.className = 'slot' + (i < HOTBAR ? ' hot' : '');
      b.addEventListener('click', () => this.slotClick(i));
      grid.append(b);
    }
    const pot = $('#pot');
    for (let i = 0; i < 3; i++) {
      const b = document.createElement('button');
      b.className = 'slot pot-slot';
      b.addEventListener('click', () => { G.pot[i] = null; this.potFound = []; this.renderBag(); });
      pot.append(b);
    }

    $('#mixBtn').addEventListener('click', () => { this.potFound = mixPot(); this.renderBag(); });
    $('#bagBtn').addEventListener('click', () => { if (G.bagOpen) this.closeBag(); else if (playing()) this.openBag(); });
    $('#bagClose').addEventListener('click', () => this.closeBag());
    $('#pauseBtn').addEventListener('click', () => this.pause());
    $('#resumeBtn').addEventListener('click', () => this.resume());
    $('#quitBtn').addEventListener('click', () => toTitle());
    $('#deadBtn').addEventListener('click', () => respawn());
    $('#deadQuitBtn').addEventListener('click', () => toTitle());

    $('#continueBtn').addEventListener('click', () => {
      if (!loadSurvival()) this.toast('That save could not be loaded. Start a new island.');
    });
    $('#newBtn').addEventListener('click', () => {
      if (savedInfo() && performance.now() - this.newArmed > 4000) {
        this.newArmed = performance.now();
        $('#newBtn').textContent = 'Tap again to replace your island';
        setTimeout(() => { $('#newBtn').textContent = 'New island'; }, 4000);
        return;
      }
      this.newArmed = 0;
      $('#newBtn').textContent = 'New island';
      newSurvival();
    });
    $('#arenaBtn').addEventListener('click', () => startArena());
    $('#helpBtn').addEventListener('click', () => {
      const h = $('#help');
      h.hidden = !h.hidden;
      $('#helpBtn').setAttribute('aria-expanded', String(!h.hidden));
    });

    const craftClick = e => {
      const b = e.target.closest('[data-craft]');
      if (!b) return;
      craft(RECIPES.find(r => r.out === b.dataset.craft));
      this.renderBag();
    };
    $('#potResult').addEventListener('click', craftClick);
    $('#book').addEventListener('click', craftClick);
    $('#detail').addEventListener('click', e => {
      const b = e.target.closest('[data-act]');
      if (b) this.detailAction(b.dataset.act);
    });
    $('#armorLine').addEventListener('click', e => {
      if (e.target.closest('[data-act="takeoff"]')) { takeOffArmor(); this.renderBag(); }
    });
  },

  // ---------- screens ----------
  hideScreens() { for (const id of ['title', 'pause', 'dead']) $('#' + id).hidden = true; },
  showTitle() {
    this.hideScreens();
    $('#hud').hidden = true;
    $('#bag').hidden = true;
    $('#title').hidden = false;
    const info = savedInfo();
    $('#continueBtn').hidden = !info;
    $('#continueInfo').textContent = info ? `Day ${info.day}` : '';
    const best = +(store.get(BEST_KEY) || 0);
    $('#bestInfo').textContent = best ? `Best: wave ${best}` : '';
  },
  enterGame() {
    this.hideScreens();
    $('#hud').hidden = false;
    $('#hungerRow').hidden = G.mode !== 'survival';
    $('#goal').hidden = G.mode !== 'survival';
    $('#toasts').replaceChildren();
    this.cache = {};
    G.invDirty = true;
  },
  pause() {
    if (!playing()) return;
    G.paused = true;
    Input.release();
    save();
    $('#pauseNote').textContent = G.mode === 'survival' ? 'Your island is saved.' : 'Arena runs are not saved.';
    $('#pause').hidden = false;
    $('#resumeBtn').focus();
  },
  resume() { G.paused = false; $('#pause').hidden = true; },
  showDeath(title, text, button) {
    $('#deadTitle').textContent = title;
    $('#deadText').textContent = text;
    $('#deadBtn').textContent = button;
    setTimeout(() => { if (G.dead) { $('#dead').hidden = false; $('#deadBtn').focus(); } }, 700);
  },

  // ---------- messages ----------
  toast(msg, kind = '') {
    const box = $('#toasts');
    const el = document.createElement('div');
    el.className = 'toast ' + kind;
    el.textContent = msg;
    box.append(el);
    while (box.children.length > 4) box.firstChild.remove();
    setTimeout(() => el.classList.add('out'), 3200);
    setTimeout(() => el.remove(), 3700);
  },
  hint(msg) {
    const now = performance.now();
    if (msg === this.lastHint && now - this.lastHintAt < 3000) return;
    this.lastHint = msg; this.lastHintAt = now;
    this.toast(msg, 'hint');
  },

  // ---------- HUD ----------
  set(key, el, prop, val) {
    if (this.cache[key] === val) return;
    this.cache[key] = val;
    if (prop === 'text') el.textContent = val;
    else if (prop === 'width') el.style.width = val;
    else if (prop === 'hidden') el.hidden = val;
    else if (prop === 'class') el.className = val;
  },
  hud() {
    if (G.mode === 'title' || !G.player) return;
    const p = G.player;
    this.set('hp', $('#hpFill'), 'width', (p.hp / p.maxHp * 100).toFixed(1) + '%');
    this.set('hpn', $('#hpNum'), 'text', String(Math.ceil(Math.max(0, p.hp))));
    this.set('food', $('#foodFill'), 'width', p.hunger.toFixed(1) + '%');
    this.set('foodn', $('#foodNum'), 'text', String(Math.ceil(p.hunger)));
    this.set('low', $('#app'), 'class', p.hp < 30 && !p.dead ? 'low' : '');
    if (G.mode === 'survival') {
      this.set('day', $('#dayLabel'), 'text', `Day ${G.day}`);
      this.set('phase', $('#timeLabel'), 'text', phaseName());
      this.set('icon', $('#clockIcon'), 'class', isNight() ? 'moon' : 'sun');
      const g = GOALS[G.goal];
      this.set('goal', $('#goalText'), 'text', g ? g.text : 'Every goal done. The wilds are yours.');
    } else {
      this.set('day', $('#dayLabel'), 'text', G.wave ? `Wave ${G.wave}` : 'Arena');
      const left = G.creatures.filter(c => !c.d.passive).length;
      this.set('phase', $('#timeLabel'), 'text', G.waveState === 'break' ? `Next wave in ${Math.max(0, Math.ceil(G.waveT))}` : `${left} left`);
      this.set('icon', $('#clockIcon'), 'class', 'moon');
    }
    const boss = G.creatures.find(c => c.d.boss);
    this.set('boss', $('#bossBar'), 'hidden', !boss);
    if (boss) this.set('bossw', $('#bossFill'), 'width', (boss.hp / boss.maxHp * 100).toFixed(1) + '%');
    if (G.invDirty) {
      G.invDirty = false;
      this.renderHotbar();
      if (G.bagOpen) this.renderBag();
    }
  },
  slotHTML(s) {
    if (!s) return '';
    return `<img src="${ICON[s.id]}" alt="${ITEMS[s.id].name}"><span class="count">${s.n > 1 ? s.n : ''}</span>`;
  },
  renderHotbar() {
    const btns = $('#hotbar').children;
    for (let i = 0; i < HOTBAR; i++) {
      const s = G.inv.slots[i];
      btns[i].innerHTML = this.slotHTML(s) + `<span class="key">${i + 1}</span>`;
      btns[i].classList.toggle('sel', i === G.sel);
      btns[i].title = s ? ITEMS[s.id].name : 'Empty';
    }
  },

  // ---------- bag ----------
  openBag() {
    G.bagOpen = true;
    Input.release();
    this.bagSel = null; this.moveFrom = null;
    $('#bag').hidden = false;
    this.renderBag();
    $('#bagClose').focus();
  },
  closeBag() {
    G.bagOpen = false;
    $('#bag').hidden = true;
  },
  slotClick(i) {
    if (this.moveFrom !== null) {
      const s = G.inv.slots;
      [s[this.moveFrom], s[i]] = [s[i], s[this.moveFrom]];
      this.moveFrom = null;
      this.bagSel = s[i] ? i : null;
      G.invDirty = true;
      this.renderBag();
      return;
    }
    this.bagSel = this.bagSel === i || !G.inv.slots[i] ? null : i;
    this.renderBag();
  },
  detailAction(act) {
    const i = this.bagSel;
    const s = G.inv.slots[i];
    if (!s) return;
    const p = G.player;
    if (act === 'use') useItem(i);
    else if (act === 'hold') {
      if (i < HOTBAR) G.sel = i;
      else { const sl = G.inv.slots; [sl[i], sl[G.sel]] = [sl[G.sel], sl[i]]; this.bagSel = G.sel; }
      this.toast(`Holding ${ITEMS[s.id].name}.`);
    } else if (act === 'pot') {
      if (G.pot.includes(s.id)) this.hint('That is already in the pot.');
      else {
        const k = G.pot.indexOf(null);
        if (k < 0) this.hint('The pot holds three ingredients. Tap one to take it out.');
        else { G.pot[k] = s.id; this.potFound = []; }
      }
    } else if (act === 'move') {
      this.moveFrom = i;
    } else if (act === 'drop') {
      G.inv.slots[i] = null;
      dropItem(s.id, s.n, p.x + p.fx * 0.8, p.y + p.fy * 0.8, true);
      this.bagSel = null;
    }
    if (!G.inv.slots[this.bagSel]) this.bagSel = null;
    G.invDirty = true;
    this.renderBag();
  },
  costHTML(cost) {
    return Object.entries(cost).map(([id, n]) => {
      const have = G.inv.count(id);
      return `<span class="cost ${have >= n ? 'ok' : 'lack'}" title="${ITEMS[id].name}: have ${have}, need ${n}"><img src="${ICON[id]}" alt="${ITEMS[id].name}">${have}/${n}</span>`;
    }).join('');
  },
  recipeHTML(r) {
    const can = G.inv.has(r.cost) && (r.near !== 'campfire' || nearCampfire());
    return `<div class="recipe">
      <img class="r-icon" src="${ICON[r.out]}" alt="">
      <div class="r-main">
        <div class="r-name">${ITEMS[r.out].name}${r.n > 1 ? ` <span class="muted">×${r.n}</span>` : ''}</div>
        <div class="r-cost">${this.costHTML(r.cost)}</div>
        ${r.near ? `<div class="r-near ${nearCampfire() ? 'ok' : ''}">${nearCampfire() ? 'Campfire nearby' : 'Needs a campfire nearby'}</div>` : ''}
      </div>
      <button class="btn small" data-craft="${r.out}" ${can ? '' : 'disabled'}>Craft</button>
    </div>`;
  },
  renderBag() {
    if (!G.bagOpen) return;
    const slots = G.inv.slots;
    const btns = $('#bagGrid').children;
    for (let i = 0; i < BAG_SIZE; i++) {
      btns[i].innerHTML = this.slotHTML(slots[i]);
      btns[i].classList.toggle('sel', i === this.bagSel);
      btns[i].classList.toggle('moving', i === this.moveFrom);
      btns[i].classList.toggle('held', i === G.sel);
      btns[i].setAttribute('aria-label', slots[i] ? `${ITEMS[slots[i].id].name} ×${slots[i].n}` : 'Empty slot');
    }

    const p = G.player;
    $('#armorLine').innerHTML = p.armor
      ? `<img src="${ICON[p.armor]}" alt=""> Wearing ${ITEMS[p.armor].name} <button class="link-btn" data-act="takeoff">Take off</button>`
      : '<span class="muted">No armor</span>';

    const d = $('#detail');
    if (this.moveFrom !== null) {
      d.innerHTML = `<p class="muted">Tap a slot to move <b>${ITEMS[slots[this.moveFrom].id].name}</b> there.</p>`;
    } else if (this.bagSel === null || !slots[this.bagSel]) {
      d.innerHTML = '<p class="muted">Tap an item to see what it does.</p>';
    } else {
      const s = slots[this.bagSel], it = ITEMS[s.id];
      const stats = [];
      if (it.tool) stats.push(`${it.tool.dmg} damage`);
      if (it.tool && it.tool.power) stats.push(`${it.tool.power}× ${it.tool.kind === 'axe' ? 'chopping' : 'mining'}`);
      if (it.armor) stats.push(`−${Math.round(it.armor * 100)}% damage taken`);
      if (it.food) stats.push(`+${it.food.hunger} food${it.food.hp ? `, ${it.food.hp > 0 ? '+' : ''}${it.food.hp} health` : ''}`);
      if (it.heal) stats.push(`+${it.heal} health`);
      const useLabel = it.food ? 'Eat' : it.heal ? 'Use' : it.egg ? 'Hatch' : it.summon ? 'Use' : it.armor ? 'Wear' : null;
      d.innerHTML = `<div class="detail-head"><img src="${ICON[s.id]}" alt=""><div><div class="d-name">${it.name}${s.n > 1 ? ` <span class="muted">×${s.n}</span>` : ''}</div>
        <div class="d-desc">${it.desc}</div>${stats.length ? `<div class="d-stats">${stats.join(' · ')}</div>` : ''}</div></div>
        <div class="d-actions">
          ${useLabel ? `<button class="btn small" data-act="use">${useLabel}</button>` : ''}
          <button class="btn small ghost" data-act="hold">${this.bagSel === G.sel ? 'Holding' : 'Hold'}</button>
          <button class="btn small ghost" data-act="pot">Add to pot</button>
          <button class="btn small ghost" data-act="move">Move</button>
          <button class="btn small ghost" data-act="drop">Drop</button>
        </div>`;
    }

    const potBtns = $('#pot').children;
    for (let i = 0; i < 3; i++) {
      const id = G.pot[i];
      potBtns[i].innerHTML = id ? `<img src="${ICON[id]}" alt="${ITEMS[id].name}">` : '<span class="plus">+</span>';
      potBtns[i].title = id ? `Take ${ITEMS[id].name} out` : 'Empty';
    }
    $('#potResult').innerHTML = this.potFound.map(r => this.recipeHTML(r)).join('');

    const known = RECIPES.filter(r => G.discovered.has(r.out));
    $('#bookCount').textContent = `${known.length} of ${RECIPES.length} found`;
    $('#book').innerHTML = known.length ? known.map(r => this.recipeHTML(r)).join('')
      : '<p class="muted">Recipes you discover show up here, so you can craft them again with one tap.</p>';

    const next = RECIPES.find(r => !G.discovered.has(r.out) && Object.keys(r.cost).every(id => G.inv.count(id) > 0));
    const hint = $('#hint');
    if (next) {
      const ids = Object.keys(next.cost);
      const first = ITEMS[ids[0]].name;
      hint.hidden = false;
      hint.textContent = ids.length === 1
        ? `Something new can be made from ${first} alone.`
        : `Something new can be made from ${first} and ${ids.length - 1} other thing${ids.length > 2 ? 's' : ''} you are carrying.`;
    } else hint.hidden = true;
  },
};
