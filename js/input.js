'use strict';
// Keyboard, mouse and touch controls, all folded into one movement vector and one action button.

const Input = {
  keys: new Set(),
  stick: { id: null, ox: 0, oy: 0, x: 0, y: 0 },
  actPointers: new Set(),
  mouseDown: false,
  queued: false, // a press that has not been acted on yet, so quick taps are never lost
  aim: null, // screen point the mouse is aiming at
  touchMode: false,

  move() {
    let x = 0, y = 0;
    const k = this.keys;
    if (k.has('KeyA') || k.has('ArrowLeft')) x -= 1;
    if (k.has('KeyD') || k.has('ArrowRight')) x += 1;
    if (k.has('KeyW') || k.has('ArrowUp')) y -= 1;
    if (k.has('KeyS') || k.has('ArrowDown')) y += 1;
    x += this.stick.x; y += this.stick.y;
    const len = Math.hypot(x, y);
    if (len > 1) { x /= len; y /= len; }
    return { x, y };
  },
  acting() {
    return this.keys.has('Space') || this.keys.has('KeyJ') || this.keys.has('Enter') || this.mouseDown || this.actPointers.size > 0;
  },
  release() {
    this.queued = false;
    this.keys.clear();
    this.mouseDown = false;
    this.actPointers.clear();
    this.resetStick();
  },
  resetStick() {
    this.stick.id = null; this.stick.x = 0; this.stick.y = 0;
    const base = document.getElementById('stickBase');
    if (base) base.hidden = true;
  },

  init(handlers) {
    window.addEventListener('keydown', e => {
      if (e.target.closest && e.target.closest('input, textarea')) return;
      const playing = handlers.playing();
      if (playing && ['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Tab'].includes(e.code)) e.preventDefault();
      if (e.repeat) { if (playing) this.keys.add(e.code); return; }
      if (e.code === 'Escape') { handlers.escape(); return; }
      if (e.code === 'KeyE' || e.code === 'KeyI' || e.code === 'Tab') { handlers.toggleBag(); return; }
      if (!playing) return;
      if (/^Digit[1-8]$/.test(e.code)) { handlers.select(+e.code.slice(5) - 1); return; }
      if (e.code === 'KeyQ') { handlers.cycle(-1); return; }
      if (e.code === 'KeyR') { handlers.cycle(1); return; }
      if (['Space', 'KeyJ', 'Enter'].includes(e.code)) this.queued = true;
      this.keys.add(e.code);
    });
    window.addEventListener('keyup', e => this.keys.delete(e.code));
    window.addEventListener('blur', () => this.release());

    const canvas = document.getElementById('view');
    const pad = document.getElementById('touchpad');
    const mouseDown = e => {
      if (e.pointerType !== 'mouse' || e.button !== 0 || !handlers.playing()) return;
      this.mouseDown = true;
      this.queued = true;
      this.aim = { x: e.clientX, y: e.clientY };
    };
    canvas.addEventListener('pointerdown', mouseDown);
    pad.addEventListener('pointerdown', mouseDown);
    window.addEventListener('pointermove', e => {
      if (e.pointerType === 'mouse' && this.mouseDown) this.aim = { x: e.clientX, y: e.clientY };
    });
    window.addEventListener('pointerup', e => {
      if (e.pointerType === 'mouse') { this.mouseDown = false; this.aim = null; }
    });
    const wheel = e => {
      if (!handlers.playing()) return;
      e.preventDefault();
      handlers.cycle(e.deltaY > 0 ? 1 : -1);
    };
    canvas.addEventListener('wheel', wheel, { passive: false });
    pad.addEventListener('wheel', wheel, { passive: false });

    // Touch: drag anywhere on the left half to move, tap the right half or the A button to act.
    const base = document.getElementById('stickBase');
    const knob = document.getElementById('stickKnob');
    const R = 46;
    pad.addEventListener('pointerdown', e => {
      if (e.pointerType === 'mouse') return;
      this.setTouchMode(true);
      if (!handlers.playing()) return;
      e.preventDefault();
      pad.setPointerCapture?.(e.pointerId);
      if (e.clientX < window.innerWidth * 0.5 && this.stick.id === null) {
        this.stick.id = e.pointerId;
        this.stick.ox = e.clientX; this.stick.oy = e.clientY;
        base.style.left = e.clientX + 'px'; base.style.top = e.clientY + 'px';
        knob.style.transform = 'translate(-50%, -50%)';
        base.hidden = false;
      } else {
        this.actPointers.add(e.pointerId);
        this.queued = true;
      }
    });
    pad.addEventListener('pointermove', e => {
      if (e.pointerId !== this.stick.id) return;
      let dx = e.clientX - this.stick.ox, dy = e.clientY - this.stick.oy;
      const len = Math.hypot(dx, dy);
      if (len > R) { dx = dx / len * R; dy = dy / len * R; }
      this.stick.x = dx / R; this.stick.y = dy / R;
      if (Math.hypot(this.stick.x, this.stick.y) < 0.18) { this.stick.x = 0; this.stick.y = 0; }
      knob.style.transform = `translate(calc(-50% + ${dx}px), calc(-50% + ${dy}px))`;
    });
    const end = e => {
      if (e.pointerId === this.stick.id) this.resetStick();
      this.actPointers.delete(e.pointerId);
    };
    pad.addEventListener('pointerup', end);
    pad.addEventListener('pointercancel', end);

    const act = document.getElementById('actBtn');
    act.addEventListener('pointerdown', e => {
      e.preventDefault();
      if (!handlers.playing()) return;
      this.actPointers.add(e.pointerId);
      this.queued = true;
    });
    act.addEventListener('pointerup', e => this.actPointers.delete(e.pointerId));
    act.addEventListener('pointercancel', e => this.actPointers.delete(e.pointerId));
    act.addEventListener('pointerleave', e => this.actPointers.delete(e.pointerId));

    if (window.matchMedia && matchMedia('(pointer: coarse)').matches) this.setTouchMode(true);
    window.addEventListener('touchstart', () => this.setTouchMode(true), { passive: true, once: true });
  },
  setTouchMode(on) {
    if (this.touchMode === on) return;
    this.touchMode = on;
    document.body.classList.toggle('touch', on);
  },
};
