package realm {
	import flash.display.BitmapData;
	import flash.display.Shape;

	/**
	 * Raises and razes realm event bosses' set pieces in this game's copy of the
	 * world: the structure (SetPieces) builds outward from the boss ring by ring
	 * when it appears and crumbles from the edge inward when it dies. Also the
	 * arena's particles, the beams from its wards and the healing from its menders.
	 * (The server lays the same structure down in its own copy all at once.)
	 */
	public class SetPieceDecor {
		private var g:Game;
		private var sh:Shape = new Shape();
		/**
		 * Set pieces up: {e, x, y, st, cells, t, end, upto, from, r (reach of the furthest corner),
		 * done (phases applied, bit k), pend (phases flashing: {k, t, sel, col})}.
		 */
		private var list:Array = [];
		/** Tiles a second the structure builds and falls at. */
		private static const SPEED:Number = 9;
		private static const STEP:Number = 0.11;

		/** Particles and beams per style: particle colour, how they move, beam colour; dust = debris colour. */
		private static const STYLES:Object = {
			cube: {part: 0xff80ff, move: "rise", beam: 0xff60ff, dust: 0x46c0e8},
			lava: {part: 0xff7020, move: "rise", beam: 0xff6020, dust: 0x464242},
			frost: {part: 0xffffff, move: "fall", beam: 0x9ad8ff, dust: 0xe8f8ff},
			throne: {part: 0xffd060, move: "drift", beam: 0xffd060, dust: 0xdcb43c},
			bone: {part: 0xc8a878, move: "drift", beam: 0xff6040, dust: 0xe8e0c8},
			ghost: {part: 0xa0c8ff, move: "rise", beam: 0x90c0ff, dust: 0x8a88b8},
			sand: {part: 0xf0d8a0, move: "drift", beam: 0xffe080, dust: 0xd8b478},
			sunken: {part: 0xa0fff0, move: "rise", beam: 0x40d0c0, dust: 0x6ac0b4},
			shell: {part: 0xd0f0ff, move: "drift", beam: 0x60c0ff, dust: 0xe8d8a8},
			skull: {part: 0xc080ff, move: "rise", beam: 0xb060ff, dust: 0xece4cc},
			obsidian: {part: 0xff9050, move: "rise", beam: 0xff7030, dust: 0x34283e},
			fire: {part: 0xffb040, move: "rise", beam: 0xffa040, dust: 0xff7a28},
			hex: {part: 0x90ff70, move: "drift", beam: 0x70e050, dust: 0x4a3256},
			reef: {part: 0xc0f0ff, move: "rise", beam: 0xff80a0, dust: 0x3c968c}
		};

		public function SetPieceDecor(g:Game) { this.g = g; }

		/** Forget every set piece (the world they were laid in is gone). */
		public function clear():void { list.length = 0; }

		/** Finds bosses with a set piece and raises it; razes the ones whose boss is gone. */
		public function update(dt:Number):void {
			var w:World = g.world;
			if (!w) return;
			for each (var e:Enemy in g.enemies) {
				if (e.dead || !e.isBoss || !e.def.setpiece) continue;
				var known:Boolean = false;
				for each (var a:Object in list) if (a.e == e) { known = true; break; }
				if (known) continue;
				var st:Object = STYLES[e.def.setpiece.style];
				if (!st) continue;
				var tx:int = int(isNaN(e.homeX) ? e.x : e.homeX), ty:int = int(isNaN(e.homeY) ? e.y : e.homeY);
				var nar:Object = {e: e, x: tx + 0.5, y: ty + 0.5, st: st, cells: SetPieces.plan(e.defId, w, tx, ty), t: 0, end: -1, upto: -1, from: 99,
					r: SetPieces.HALF * 1.5, done: 0, pend: []};
				list.push(nar);
				// arriving mid-fight: the arena is already as the fight has left it
				var nph:int = SetPieces.phasesOf(e.defId).length;
				for (var pk:int = 0; pk < nph; pk++) if (e.spMask & (1 << pk)) { nar.done |= 1 << pk; SetPieces.applyPhase(w, e.defId, nar.cells, pk); }
				// the ground splits and the structure starts to rise
				g.shake(0.8, 7);
				g.burst(tx + 0.5, ty + 0.5, st.dust, 30);
				g.ring(tx + 0.5, ty + 0.5, st.part, 26);
			}
			for (var i:int = list.length - 1; i >= 0; i--) {
				var ar:Object = list[i];
				ar.t += dt;
				var gone:Boolean = ar.e.dead || g.enemies.indexOf(ar.e) < 0;
				if (gone && ar.end < 0) {
					ar.end = 0;
					ar.from = ar.r + 1.5;
					g.shake(0.6, 5);
					g.ring(ar.x, ar.y, ar.st.part, 30);
				}
				if (ar.end < 0) phases(ar, dt);
				if (ar.end < 0) {
					// building outward, a ring at a time
					var upto:Number = Math.floor(ar.t / STEP) * STEP * SPEED;
					if (upto > ar.upto && ar.upto < ar.r + 2) {
						ar.upto = upto;
						changed(ar, SetPieces.apply(w, ar.cells, upto), true);
					}
				} else {
					// falling apart from the edge inward
					ar.end += dt;
					var from:Number = ar.r + 1.5 - Math.floor(ar.end / STEP) * STEP * SPEED;
					if (from < ar.from) {
						ar.from = from;
						changed(ar, SetPieces.undo(w, ar.cells, Math.max(0, from)), false);
					}
					if (from < 0) { list.splice(i, 1); continue; }
				}
				// the arena's own particles
				if (ar.end < 0 && Game.opt("parts") && g.parts.length < 380 && Math.random() < dt * 14) {
					var pa:Number = Math.random() * Math.PI * 2, pr:Number = Math.sqrt(Math.random()) * SetPieces.HALF * 0.9;
					var vy:Number = ar.st.move == "rise" ? -1.2 : ar.st.move == "fall" ? 1 : -0.2;
					var vx:Number = ar.st.move == "drift" ? 0.6 : (Math.random() - 0.5) * 0.3;
					g.parts.push(new Particle(ar.x + Math.cos(pa) * pr, ar.y + Math.sin(pa) * pr - (ar.st.move == "fall" ? 2 : 0), vx, vy, 1.2, Sprites.glow(ar.st.part)));
				}
			}
		}

		/** Whoever runs the boss starts phases when their moment comes; everyone counts down the warnings. */
		private function phases(ar:Object, dt:Number):void {
			var e:Enemy = ar.e;
			var host:Boolean = !e.remote && g.sync && g.sync.isHost;
			if (host) {
				var k:int = SetPieces.trigger(e, e.spMask);
				if (k >= 0) {
					g.sync.arenaPhase(e, k, SetPieces.WARN, false);
					phase(e, k, SetPieces.WARN, false);
				}
			}
			for (var i:int = ar.pend.length - 1; i >= 0; i--) {
				var p:Object = ar.pend[i];
				p.t -= dt;
				// the host decides when it happens; if its word never comes, go anyway
				if (host ? p.t <= 0 : p.t <= -2) apply(ar, p.k);
			}
		}

		/** Phase k of boss e's arena: flash the tiles for `warn` seconds, or change them now (go). */
		public function phase(e:Enemy, k:int, warn:Number, go:Boolean):void {
			e.spMask |= 1 << k;
			var ar:Object = null;
			for each (var a:Object in list) if (a.e == e && a.end < 0) { ar = a; break; }
			if (!ar || (ar.done & (1 << k))) return;
			if (go) { apply(ar, k); return; }
			for each (var p:Object in ar.pend) if (p.k == k) return;
			var ph:Object = SetPieces.phasesOf(e.defId)[k];
			if (!ph) return;
			ar.pend.push({k: k, t: warn, max: Math.max(0.1, warn), sel: SetPieces.phaseCells(e.defId, ar.cells, k), col: ph.col});
			g.msg(ph.msg, ph.col);
			g.showBanner(ph.when == "low" ? "The arena shifts!" : "The ward is broken!", ph.col, 2.2);
			g.shake(0.4, 3);
			Sfx.play("boss");
		}

		/** Changes the arena for phase k (and, as the host, brings out its monsters). */
		private function apply(ar:Object, k:int):void {
			if (ar.done & (1 << k)) return;
			ar.done |= 1 << k;
			for (var i:int = ar.pend.length - 1; i >= 0; i--) if (ar.pend[i].k == k) ar.pend.splice(i, 1);
			var e:Enemy = ar.e, w:World = g.world;
			var ph:Object = SetPieces.phasesOf(e.defId)[k];
			var sel:Array = SetPieces.applyPhase(w, e.defId, ar.cells, k);
			var x0:int = int(ar.x) - SetPieces.HALF, y0:int = int(ar.y) - SetPieces.HALF;
			w.redrawArea(x0, y0, x0 + SetPieces.SIZE, y0 + SetPieces.SIZE);
			g.shake(0.7, 7);
			if (Game.opt("parts")) for (var j:int = 0; j < sel.length; j += Math.max(1, int(sel.length / 14))) g.burst(sel[j].x + 0.5, sel[j].y + 0.5, ph ? ph.col : ar.st.dust, 6);
			if (!e.remote && g.sync && g.sync.isHost) {
				g.sync.arenaPhase(e, k, 0, true);
				if (ph && ph.spawn) for each (var sp:Object in SetPieces.spawnSpots(sel, ph.n)) g.spawnEnemy(ph.spawn, sp.x, sp.y, e.zone);
			}
			unstick();
		}

		/** The tiles about to change, flashing faster as the moment comes. */
		public function drawGround(canvas:BitmapData):void {
			var gr:* = sh.graphics, any:Boolean = false;
			gr.clear();
			for each (var ar:Object in list) {
				for each (var p:Object in ar.pend) {
					var left:Number = Math.max(0, p.t) / p.max;
					var a:Number = 0.18 + 0.4 * (0.5 + 0.5 * Math.sin(g.time * (8 + (1 - left) * 18)));
					gr.beginFill(p.col, a);
					for each (var q:Object in p.sel) {
						gr.moveTo(g.scrX(q.x, q.y), g.scrY(q.x, q.y));
						gr.lineTo(g.scrX(q.x + 1, q.y), g.scrY(q.x + 1, q.y));
						gr.lineTo(g.scrX(q.x + 1, q.y + 1), g.scrY(q.x + 1, q.y + 1));
						gr.lineTo(g.scrX(q.x, q.y + 1), g.scrY(q.x, q.y + 1));
						gr.lineTo(g.scrX(q.x, q.y), g.scrY(q.x, q.y));
					}
					gr.endFill();
					any = true;
				}
			}
			if (any) canvas.draw(sh);
		}

		/** After a ring went up (or came down): redraw it, throw up dust where walls and scenery moved, and free anyone caught. */
		private function changed(ar:Object, n:int, rising:Boolean):void {
			if (n <= 0) return;
			var w:World = g.world;
			var x0:int = int(ar.x) - SetPieces.HALF, y0:int = int(ar.y) - SetPieces.HALF;
			w.redrawArea(x0, y0, x0 + SetPieces.SIZE, y0 + SetPieces.SIZE);
			var dusty:int = 0;
			for each (var k:Object in ar.cells) {
				if (rising ? (!k.on || k.d > ar.upto || k.d <= ar.upto - STEP * SPEED) : (k.on || k.d < ar.from || k.d >= ar.from + STEP * SPEED)) continue;
				if ((k.nt == World.WALL || k.no) && dusty < 10 && Game.opt("parts")) { g.burst(k.x + 0.5, k.y + 0.5, ar.st.dust, 5); dusty++; }
			}
			if (rising) unstick();
		}

		/** If a wall or decoration went up where the player stands, step them to the nearest open ground. */
		private function unstick():void {
			var p:Player = g.player, w:World = g.world;
			if (!p || w.canStand(p.x, p.y, 0.3, false)) return;
			for (var r:Number = 0.5; r <= 6; r += 0.5) {
				for (var a:int = 0; a < 16; a++) {
					var nx:Number = p.x + Math.cos(a * Math.PI / 8) * r, ny:Number = p.y + Math.sin(a * Math.PI / 8) * r;
					if (w.canStand(nx, ny, 0.3, false)) { p.x = nx; p.y = ny; return; }
				}
			}
		}

		private function X(x:Number, y:Number):Number { return g.scrX(x, y); }
		private function Y(x:Number, y:Number):Number { return g.scrY(x, y) + Game.TS * 0.3; }

		/** Above everyone: beams from wards to their boss, healing streams from menders. */
		public function drawTop(canvas:BitmapData):void {
			if (!list.length) return;
			var TS:int = Game.TS, gr:* = sh.graphics, t:Number = g.time;
			gr.clear();
			var any:Boolean = false;
			for each (var ar:Object in list) {
				if (ar.end >= 0) continue;
				var b:Enemy = ar.e;
				var bx:Number = X(b.x, b.y), by:Number = Y(b.x, b.y) - TS * 0.9;
				for each (var p:Enemy in g.enemies) {
					if (p.dead || !p.def.prop) continue;
					var dx:Number = p.x - ar.x, dy:Number = p.y - ar.y;
					if (dx * dx + dy * dy > ar.r * ar.r) continue;
					var px:Number = X(p.x, p.y), py:Number = Y(p.x, p.y) - TS * 0.8;
					if (p.def.ward && b.immune) {
						any = true;
						// a crackling beam holding the shield up
						gr.lineStyle(7, ar.st.beam, 0.25 + 0.1 * Math.sin(t * 10));
						gr.moveTo(px, py); gr.lineTo(bx, by);
						gr.lineStyle(2, 0xffffff, 0.7);
						gr.moveTo(px, py);
						for (var s:int = 1; s <= 6; s++) {
							var q:Number = s / 6, j:Number = s == 6 ? 0 : Math.sin(t * 30 + s * 2 + p.x) * 5;
							gr.lineTo(px + (bx - px) * q + j, py + (by - py) * q - j);
						}
					} else if (p.def.mend && b.hp < b.maxHp) {
						any = true;
						// motes of healing flowing to the boss
						gr.lineStyle();
						for (var m:int = 0; m < 5; m++) {
							var f:Number = (t * 0.8 + m / 5) % 1;
							gr.beginFill(0x80ff90, 0.85 * Math.sin(f * Math.PI));
							gr.drawCircle(px + (bx - px) * f, py + (by - py) * f - Math.sin(f * Math.PI) * 20, 3.5);
							gr.endFill();
						}
					}
				}
			}
			gr.lineStyle();
			if (any) canvas.draw(sh);
		}
	}
}
