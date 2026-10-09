'use strict';
/*
 * What the converted game code (sim/gen/game.js) needs from the outside:
 * AS3 runtime helpers (int/uint truncation, Vectors, for-each) and stand-ins
 * for the client-only classes (sprites, sound, UI), which do nothing here.
 */
const __int = (v) => (Number(v) | 0);
const __uint = (v) => (Number(v) >>> 0);
/** new Vector.<T>(n, fixed): n zeroes. */
const __vec = (n) => new Array(n | 0).fill(0);
/** for each (x in coll): an array's elements or an object's values. */
const __vals = (o) => (o == null ? [] : Array.isArray(o) ? o : Object.values(o));
const __isNum = (v) => typeof v === 'number';
const __isStr = (v) => typeof v === 'string';
const start = Date.now();
const __getTimer = () => Date.now() - start;

// AS3 Array extras
if (!Array.prototype.sortOn) {
  Object.defineProperty(Array.prototype, 'sortOn', {
    value(field, opts) {
      const numeric = opts & 16, desc = opts & 2, ci = opts & 1;
      this.sort((a, b) => {
        let x = a[field], y = b[field];
        if (!numeric) { x = String(x); y = String(y); if (ci) { x = x.toLowerCase(); y = y.toLowerCase(); } }
        const r = x < y ? -1 : x > y ? 1 : 0;
        return desc ? -r : r;
      });
      return this;
    }
  });
}
Object.assign(Array, { CASEINSENSITIVE: 1, DESCENDING: 2, UNIQUESORT: 4, RETURNINDEXEDARRAY: 8, NUMERIC: 16 });

const noop = () => null;
const Sprites = new Proxy({ shade: (c, f) => c, tint: (c, f) => c, ROT_FRAMES: 32 }, { get: (t, k) => (k in t ? t[k] : noop) });
const Ui = { hex: (c) => '#' + ('000000' + (Number(c) >>> 0).toString(16)).slice(-6), GOLD: 0xffd75e, NPC: 0xff9a2e };
const Sfx = { play: noop };
const Save = { data: {}, flush: noop };
/** An enemy shot as the server sees it (the server follows them to know who should have been hit). */
class Projectile {
  constructor(x, y, angle, speed, life, dmg, enemy, r) {
    this.x = x; this.y = y; this.angle = angle; this.speed = speed; this.life = life;
    this.dmg = dmg; this.enemy = enemy; this.r = r || 0.3;
  }
}
const Game = { TS: 40 };
const Player = { MAX_LEVEL: 20 };

module.exports = { __int, __uint, __vec, __vals, __isNum, __isStr, __getTimer, Sprites, Ui, Sfx, Save, Projectile, Game, Player };
