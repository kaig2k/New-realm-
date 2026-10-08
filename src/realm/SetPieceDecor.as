package realm {
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.geom.Matrix;

	/**
	 * The arenas realm event bosses bring with them: a themed ground that rises
	 * when the boss appears (scenery, glow and particles) and crumbles when it
	 * dies, plus beams from its wards and streams of healing from its menders.
	 * Drawing only: the pieces themselves are monsters the boss's host runs.
	 */
	public class SetPieceDecor {
		private var g:Game;
		private var sh:Shape = new Shape();
		private var mtx:Matrix = new Matrix();
		/** Arenas on screen: {e, x, y, st, t, end}. */
		private var list:Array = [];

		/**
		 * Looks per style. floor/rim/accent colours; pattern on the ground; deco = the
		 * scenery standing round the edge; part = particle colour and how they move.
		 */
		private static const STYLES:Object = {
			cube: {floor: 0x2a1040, rim: 0xff60ff, accent: 0xffe060, pattern: "grid", deco: "cube", n: 8, decoCol: 0xff80ff, part: 0xff80ff, move: "rise", beam: 0xff60ff},
			lava: {floor: 0x1e1010, rim: 0xff5010, accent: 0xffb030, pattern: "cracks", deco: "spike", n: 10, decoCol: 0x2a1c1c, part: 0xff7020, move: "rise", beam: 0xff6020},
			frost: {floor: 0xc8e8ff, rim: 0x9ad8ff, accent: 0xffffff, pattern: "cracks", deco: "spike", n: 12, decoCol: 0xd8f0ff, part: 0xffffff, move: "fall", beam: 0x9ad8ff},
			throne: {floor: 0x3a2a40, rim: 0xffd060, accent: 0x8a6ab0, pattern: "tiles", deco: "pillar", n: 8, decoCol: 0xb8a890, part: 0xffd060, move: "drift", beam: 0xffd060},
			bone: {floor: 0x4a3a28, rim: 0xe8d8b0, accent: 0xa02010, pattern: "spokes", deco: "bone", n: 12, decoCol: 0xe8e0c8, part: 0xc8a878, move: "drift", beam: 0xff6040},
			ghost: {floor: 0x202838, rim: 0x90c0ff, accent: 0xd0e0ff, pattern: "tiles", deco: "candle", n: 10, decoCol: 0x6a7a9a, part: 0xa0c8ff, move: "rise", beam: 0x90c0ff},
			sand: {floor: 0xd8bc80, rim: 0xa08048, accent: 0xffe080, pattern: "steps", deco: "pillar", n: 8, decoCol: 0xe8d0a0, part: 0xf0d8a0, move: "drift", beam: 0xffe080},
			sunken: {floor: 0x1e4a50, rim: 0x40d0c0, accent: 0x80fff0, pattern: "waves", deco: "coral", n: 10, decoCol: 0xff80a0, part: 0xa0fff0, move: "rise", beam: 0x40d0c0},
			shell: {floor: 0xe8d8a8, rim: 0x60c0ff, accent: 0xffb0c0, pattern: "waves", deco: "shell", n: 10, decoCol: 0xffd0d8, part: 0xd0f0ff, move: "drift", beam: 0x60c0ff},
			skull: {floor: 0x201820, rim: 0xb060ff, accent: 0xe8e0c8, pattern: "runes", deco: "candle", n: 12, decoCol: 0xe8e0c8, part: 0xc080ff, move: "rise", beam: 0xb060ff},
			obsidian: {floor: 0x100a10, rim: 0xff7030, accent: 0x402030, pattern: "cracks", deco: "spike", n: 12, decoCol: 0x1a121a, part: 0xff9050, move: "rise", beam: 0xff7030},
			fire: {floor: 0x3a1408, rim: 0xff8030, accent: 0xffe060, pattern: "spokes", deco: "flame", n: 14, decoCol: 0xff6020, part: 0xffb040, move: "rise", beam: 0xffa040},
			hex: {floor: 0x1a2a14, rim: 0x70e050, accent: 0xc060ff, pattern: "runes", deco: "mushroom", n: 12, decoCol: 0xc03040, part: 0x90ff70, move: "drift", beam: 0x70e050},
			reef: {floor: 0x103a5a, rim: 0x40a0ff, accent: 0xff80a0, pattern: "waves", deco: "coral", n: 10, decoCol: 0xff80a0, part: 0xc0f0ff, move: "rise", beam: 0xff80a0}
		};

		public function SetPieceDecor(g:Game) { this.g = g; }

		public function clear():void { list.length = 0; }

		/** Finds bosses with an arena, and lets arenas whose boss is gone crumble away. */
		public function update(dt:Number):void {
			for each (var e:Enemy in g.enemies) {
				if (e.dead || !e.isBoss || !e.def.setpiece) continue;
				var known:Boolean = false;
				for each (var a:Object in list) if (a.e == e) { known = true; break; }
				if (known) continue;
				var st:Object = STYLES[e.def.setpiece.style];
				if (!st) continue;
				var cx:Number = isNaN(e.homeX) ? e.x : e.homeX, cy:Number = isNaN(e.homeY) ? e.y : e.homeY;
				list.push({e: e, x: cx, y: cy, st: st, t: 0, end: -1, r: e.def.setpiece.r + 2.5, seed: int(cx * 7 + cy * 13)});
				// the ground splits and the arena rises
				g.shake(0.6, 6);
				g.burst(cx, cy, st.rim, 30);
				g.ring(cx, cy, st.rim, 26);
			}
			for (var i:int = list.length - 1; i >= 0; i--) {
				var ar:Object = list[i];
				ar.t += dt;
				var gone:Boolean = ar.e.dead || g.enemies.indexOf(ar.e) < 0;
				if (gone && ar.end < 0) {
					ar.end = 0;
					// it crumbles: debris flies from the scenery
					for (var k:int = 0; k < ar.st.n; k++) {
						var da:Number = k * Math.PI * 2 / ar.st.n;
						g.burst(ar.x + Math.cos(da) * ar.r * 0.95, ar.y + Math.sin(da) * ar.r * 0.95, ar.st.decoCol, 6);
					}
					g.ring(ar.x, ar.y, ar.st.rim, 30);
				}
				if (ar.end >= 0) {
					ar.end += dt;
					if (ar.end > 1.6) { list.splice(i, 1); continue; }
				}
				// the arena's own particles
				if (Game.opt("parts") && g.parts.length < 380 && Math.random() < dt * 14 * (ar.end < 0 ? 1 : 0.3)) {
					var pa:Number = Math.random() * Math.PI * 2, pr:Number = Math.sqrt(Math.random()) * ar.r;
					var vy:Number = ar.st.move == "rise" ? -1.2 : ar.st.move == "fall" ? 1 : -0.2;
					var vx:Number = ar.st.move == "drift" ? 0.6 : (Math.random() - 0.5) * 0.3;
					g.parts.push(new Particle(ar.x + Math.cos(pa) * pr, ar.y + Math.sin(pa) * pr - (ar.st.move == "fall" ? 2 : 0), vx, vy, 1.2, Sprites.glow(ar.st.part)));
				}
			}
		}

		/** How far the arena has risen (0 to 1, with a little overshoot), or sunk away. */
		private function grow(ar:Object):Number {
			if (ar.end >= 0) return Math.max(0, 1 - ar.end / 1.6);
			var q:Number = Math.min(1, ar.t / 1.3);
			return 1 + 2.2 * Math.pow(q - 1, 3) + 1.2 * Math.pow(q - 1, 2);
		}

		private function X(x:Number, y:Number):Number { return g.scrX(x, y); }
		private function Y(x:Number, y:Number):Number { return g.scrY(x, y) + Game.TS * 0.3; }

		/** The ground and its scenery, under everyone. */
		public function drawGround(canvas:BitmapData):void {
			if (!list.length) return;
			var TS:int = Game.TS, gr:* = sh.graphics, t:Number = g.time;
			gr.clear();
			for each (var ar:Object in list) {
				var st:Object = ar.st, k:Number = grow(ar), fade:Number = ar.end >= 0 ? Math.max(0, 1 - ar.end / 1.6) : 1;
				if (k <= 0.01) continue;
				var cx:Number = X(ar.x, ar.y), cy:Number = Y(ar.x, ar.y);
				if (cx < -400 || cy < -400 || cx > canvas.width + 400 || cy > canvas.height + 400) continue;
				var R:Number = ar.r * TS * k;
				// the floor: a disc that darkens toward the edge, and a glowing rim
				mtx.createGradientBox(R * 2, R * 2, 0, cx - R, cy - R);
				gr.beginGradientFill(GradientType.RADIAL, [st.floor, st.floor, st.floor], [0.75 * fade, 0.6 * fade, 0], [0, 200, 255], mtx);
				gr.drawCircle(cx, cy, R);
				gr.endFill();
				gr.lineStyle(3, st.rim, 0.75 * fade);
				gr.drawCircle(cx, cy, R * 0.86);
				gr.lineStyle(1.5, st.accent, 0.45 * fade);
				gr.drawCircle(cx, cy, R * 0.8);
				gr.lineStyle();
				pattern(gr, st, cx, cy, R * 0.8, t, fade, ar.seed);
				// the scenery round the edge, popping up one by one
				for (var i:int = 0; i < st.n; i++) {
					var pop:Number = ar.end >= 0 ? fade : Math.max(0, Math.min(1, (ar.t - 0.3 - i * 0.06) / 0.35));
					if (pop <= 0) continue;
					var a:Number = (i + 0.5) * Math.PI * 2 / st.n;
					deco(gr, st, cx + Math.cos(a) * R * 0.93, cy + Math.sin(a) * R * 0.93, pop, t + i, fade);
				}
			}
			canvas.draw(sh);
		}

		private function pattern(gr:*, st:Object, cx:Number, cy:Number, R:Number, t:Number, fade:Number, seed:int):void {
			var i:int, a:Number, r:Number, j:int;
			switch (st.pattern) {
				case "grid":
					// a glowing grid that pulses outward
					gr.lineStyle(1, st.rim, 0.35 * fade);
					for (var gx:Number = -R; gx <= R; gx += 22) {
						var hh:Number = Math.sqrt(Math.max(0, R * R - gx * gx));
						gr.moveTo(cx + gx, cy - hh); gr.lineTo(cx + gx, cy + hh);
						gr.moveTo(cx - hh, cy + gx); gr.lineTo(cx + hh, cy + gx);
					}
					gr.lineStyle(2, st.accent, 0.5 * fade * (0.5 + 0.5 * Math.sin(t * 3)));
					gr.drawCircle(cx, cy, R * ((t * 0.5) % 1));
					break;
				case "cracks":
					// glowing cracks running out from the middle
					for (i = 0; i < 9; i++) {
						a = i * Math.PI * 2 / 9 + (seed % 7) * 0.1;
						gr.lineStyle(3, st.rim, (0.45 + 0.25 * Math.sin(t * 2 + i)) * fade);
						gr.moveTo(cx + Math.cos(a) * R * 0.15, cy + Math.sin(a) * R * 0.15);
						r = R * 0.15;
						for (j = 1; j <= 4; j++) {
							r += R * 0.2;
							var w:Number = Math.sin(seed + i * 3 + j * 1.7) * 0.25;
							gr.lineTo(cx + Math.cos(a + w) * r, cy + Math.sin(a + w) * r);
						}
					}
					gr.lineStyle();
					break;
				case "tiles":
					// a checkered floor of faint diamonds
					for (var tx:Number = -R; tx < R; tx += 26) for (var ty:Number = -R; ty < R; ty += 26) {
						if (tx * tx + ty * ty > R * R * 0.9) continue;
						if ((int((tx + R) / 26) + int((ty + R) / 26)) % 2) continue;
						gr.beginFill(st.accent, 0.12 * fade);
						gr.moveTo(cx + tx + 13, cy + ty); gr.lineTo(cx + tx + 26, cy + ty + 13); gr.lineTo(cx + tx + 13, cy + ty + 26); gr.lineTo(cx + tx, cy + ty + 13);
						gr.endFill();
					}
					break;
				case "spokes":
					gr.lineStyle(2, st.rim, 0.4 * fade);
					for (i = 0; i < 12; i++) {
						a = i * Math.PI / 6 + t * 0.15;
						gr.moveTo(cx + Math.cos(a) * R * 0.2, cy + Math.sin(a) * R * 0.2);
						gr.lineTo(cx + Math.cos(a) * R, cy + Math.sin(a) * R);
					}
					gr.lineStyle(2, st.accent, 0.5 * fade);
					gr.drawCircle(cx, cy, R * 0.2);
					gr.lineStyle();
					break;
				case "steps":
					// a sunken pyramid: nested squares
					for (i = 1; i <= 4; i++) {
						r = R * i / 4.4;
						gr.lineStyle(2, i % 2 ? st.rim : st.accent, 0.45 * fade);
						gr.drawRect(cx - r * 0.7, cy - r * 0.7, r * 1.4, r * 1.4);
					}
					gr.lineStyle();
					break;
				case "waves":
					// ripples spreading out from the middle
					for (i = 0; i < 4; i++) {
						r = R * (((t * 0.25) + i / 4) % 1);
						gr.lineStyle(2, st.accent, 0.5 * fade * (1 - r / R));
						gr.drawCircle(cx, cy, r);
					}
					gr.lineStyle();
					break;
				case "runes":
					// a turning circle of runes
					gr.lineStyle(2, st.rim, 0.5 * fade);
					gr.drawCircle(cx, cy, R * 0.55);
					gr.lineStyle();
					for (i = 0; i < 12; i++) {
						a = i * Math.PI / 6 - t * 0.3;
						var rx:Number = cx + Math.cos(a) * R * 0.55, ry:Number = cy + Math.sin(a) * R * 0.55;
						gr.beginFill(st.accent, (0.5 + 0.5 * Math.sin(t * 3 + i)) * fade);
						gr.drawRect(rx - 3, ry - 5, 6, 10);
						gr.endFill();
					}
					break;
			}
		}

		/** One piece of scenery standing on the arena's edge (k = how far it has popped up). */
		private function deco(gr:*, st:Object, x:Number, y:Number, k:Number, t:Number, fade:Number):void {
			var c:uint = st.decoCol, h:Number;
			switch (st.deco) {
				case "spike":
					h = 26 * k;
					gr.lineStyle(1.5, 0x000000, 0.5 * fade);
					gr.beginFill(c, fade);
					gr.moveTo(x - 8, y); gr.lineTo(x - 1, y - h); gr.lineTo(x + 2, y - h * 0.7); gr.lineTo(x + 8, y); gr.lineTo(x - 8, y);
					gr.endFill();
					gr.lineStyle(1.5, st.rim, 0.7 * fade);
					gr.moveTo(x - 1, y - h); gr.lineTo(x + 3, y);
					gr.lineStyle();
					break;
				case "pillar":
					h = 24 * k;
					gr.lineStyle(1.5, 0x000000, 0.5 * fade);
					gr.beginFill(c, fade);
					gr.drawRect(x - 7, y - h, 14, h);
					gr.endFill();
					gr.beginFill(st.accent, 0.8 * fade);
					gr.drawRect(x - 9, y - h - 4, 18, 5);
					gr.endFill();
					gr.lineStyle();
					break;
				case "candle":
					h = 14 * k;
					gr.beginFill(c, fade);
					gr.drawRect(x - 3, y - h, 6, h);
					gr.endFill();
					gr.beginFill(st.part, (0.7 + 0.3 * Math.sin(t * 9)) * fade * k);
					gr.drawEllipse(x - 3, y - h - 9, 6, 9);
					gr.endFill();
					gr.beginFill(st.part, 0.18 * fade * k);
					gr.drawCircle(x, y - h - 5, 11);
					gr.endFill();
					break;
				case "cube":
					var bob:Number = Math.sin(t * 2) * 4 - 18 * k;
					gr.lineStyle(1.5, st.accent, 0.8 * fade);
					gr.beginFill(c, 0.75 * fade);
					gr.drawRect(x - 7 * k, y - 7 * k + bob, 14 * k, 14 * k);
					gr.endFill();
					gr.lineStyle();
					gr.beginFill(st.rim, 0.25 * fade);
					gr.drawEllipse(x - 8, y - 3, 16, 6);
					gr.endFill();
					break;
				case "bone":
					h = 20 * k;
					gr.lineStyle(4, c, fade);
					gr.moveTo(x - 6, y); gr.curveTo(x - 10, y - h * 0.6, x - 2, y - h);
					gr.moveTo(x + 6, y); gr.curveTo(x + 10, y - h * 0.6, x + 2, y - h);
					gr.lineStyle();
					break;
				case "coral":
					h = 20 * k;
					gr.lineStyle(3, c, fade);
					gr.moveTo(x, y); gr.lineTo(x, y - h);
					gr.moveTo(x, y - h * 0.5); gr.lineTo(x - 7, y - h * 0.85);
					gr.moveTo(x, y - h * 0.65); gr.lineTo(x + 7, y - h * 0.95);
					gr.lineStyle();
					break;
				case "shell":
					gr.lineStyle(1.5, 0x8a6a6a, 0.6 * fade);
					gr.beginFill(c, fade);
					gr.drawEllipse(x - 8 * k, y - 8 * k, 16 * k, 10 * k);
					gr.endFill();
					gr.moveTo(x, y - 8 * k); gr.lineTo(x, y + 1);
					gr.moveTo(x - 4 * k, y - 7 * k); gr.lineTo(x - 2, y + 1);
					gr.moveTo(x + 4 * k, y - 7 * k); gr.lineTo(x + 2, y + 1);
					gr.lineStyle();
					break;
				case "flame":
					h = (18 + Math.sin(t * 8) * 5) * k;
					gr.beginFill(c, 0.85 * fade);
					gr.moveTo(x - 6, y); gr.curveTo(x - 6, y - h * 0.6, x, y - h); gr.curveTo(x + 6, y - h * 0.6, x + 6, y); gr.lineTo(x - 6, y);
					gr.endFill();
					gr.beginFill(st.accent, 0.9 * fade);
					gr.moveTo(x - 3, y); gr.curveTo(x - 3, y - h * 0.4, x, y - h * 0.6); gr.curveTo(x + 3, y - h * 0.4, x + 3, y); gr.lineTo(x - 3, y);
					gr.endFill();
					break;
				case "mushroom":
					h = 12 * k;
					gr.beginFill(0xe8e0c8, fade);
					gr.drawRect(x - 2, y - h, 4, h);
					gr.endFill();
					gr.lineStyle(1, 0x000000, 0.4 * fade);
					gr.beginFill(c, fade);
					gr.moveTo(x - 9 * k, y - h); gr.curveTo(x, y - h - 14 * k, x + 9 * k, y - h); gr.lineTo(x - 9 * k, y - h);
					gr.endFill();
					gr.lineStyle();
					gr.beginFill(0xffffff, 0.9 * fade);
					gr.drawCircle(x - 3 * k, y - h - 4 * k, 1.5); gr.drawCircle(x + 3 * k, y - h - 5 * k, 1.5);
					gr.endFill();
					break;
			}
		}

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
					if (dx * dx + dy * dy > (ar.r + 2) * (ar.r + 2)) continue;
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
