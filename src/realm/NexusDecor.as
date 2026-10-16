package realm {
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;

	/**
	 * The Nexus as the heart of Eldmere, a citadel adrift among the stars: the star of Eldmere
	 * inlaid round the star well, a shard of the fallen star floating over it, rune circles under
	 * the realm portals with light rising from them, violet light round the braziers, the class
	 * banners on the ramparts, flowers and fireflies in the gardens, and all round it the night
	 * sky, with stars twinkling and broken stones drifting past.
	 */
	public class NexusDecor {
		private var g:Game;
		private var sh:Shape = new Shape();
		private var mtx:Matrix = new Matrix();
		private var pt:Point = new Point();
		private var braziers:Array = [];
		private var flowers:Array = [];
		private var motes:Array = [];
		private var labels:Array = [];
		/** Stars twinkling in the sky round the citadel, and stones drifting through it. */
		private var stars:Array = [];
		private var isles:Array = [];

		/** The fountain at the heart of the plaza. */
		public static const FX:Number = 100.5, FY:Number = 98.5;

		/** Banners along the walls: [x, y, class]. */
		private static const BANNERS:Array = [[78.5, 64.9, "wizard"], [82.5, 64.9, "archer"], [118.5, 64.9, "knight"], [122.5, 64.9, "priest"],
			[66.9, 87.5, "rogue"], [66.9, 109.5, "warrior"], [134.1, 87.5, "necromancer"], [134.1, 109.5, "huntress"]];
		private static const CLASS_COL:Object = {wizard: 0xb02a2a, archer: 0x2f7a35, knight: 0x6a7a98, priest: 0xd8c890,
			rogue: 0x4a2f7a, warrior: 0xa0401e, necromancer: 0x2e2238, huntress: 0x8a5a24};

		public function NexusDecor(g:Game, w:World, makeLabel:Function) {
			this.g = g;
			// braziers and garden flowers come from the map itself
			var N:int = w.N;
			var r:uint = 12345;
			for (var y:int = 60; y < 132; y++) for (var x:int = 60; x < 140; x++) {
				var i:int = y * N + x;
				if (w.objs[i] == 7 || w.objs[i] == 30) braziers.push([x + 0.5, y + 0.5, w.objs[i] == 30 ? 0xa070ff : 0xffb050]);
				if (w.tiles[i] == World.GRASS && w.objs[i] == 0) {
					for (var k:int = 0; k < 2; k++) {
						r = (r * 1103515245 + 12345) & 0x7fffffff;
						if (r % 3 != 0) continue;
						var fx:Number = x + (r % 97) / 97, fy:Number = y + ((r >> 8) % 89) / 89;
						flowers.push([fx, fy, [0xff7090, 0xffe060, 0x9ab0ff, 0xffffff, 0xff9a40][(r >> 4) % 5]]);
					}
				}
			}
			for (k = 0; k < 40; k++) motes.push(newMote(true));
			// the sky: stars just past the ramparts, and a few stones drifting by
			for (k = 0; k < 160; k++) {
				r = (r * 1103515245 + 12345) & 0x7fffffff;
				var sx:Number = 52 + (r % 9700) / 100, sy:Number = 50 + ((r >> 9) % 9200) / 100;
				if (w.tiles[int(sy) * N + int(sx)] != World.VOID) continue;
				stars.push([sx, sy, (r >> 3) % 628 / 100, 0.5 + ((r >> 5) % 100) / 100]);
			}
			for (k = 0; k < 9; k++) isles.push({a: k * Math.PI * 2 / 9 + 0.3, r: 42 + (k % 3) * 5, s: 0.006 + (k % 4) * 0.003, size: 1 + (k % 3), seed: k});
			label(makeLabel, "The Realm Gate", 0xffd75e, 100.5, 75.6);
			label(makeLabel, "Hall of Heroes", 0xe8d8b0, 100.5, 86.2);
			label(makeLabel, "The Treasury", 0xf0c030, 70.5, 91.4);
			label(makeLabel, "War Quarter", 0xff8a60, 128.5, 86.2);
		}

		private function label(makeLabel:Function, text:String, col:uint, x:Number, y:Number):void {
			var tf:TextField = makeLabel(text, col);
			labels.push({tf: tf, x: x, y: y});
		}

		/** Gold dust over the plaza, fireflies over the gardens. */
		private function newMote(anywhere:Boolean):Object {
			var garden:Boolean = Math.random() < 0.45;
			var x:Number, y:Number;
			if (garden) {
				var gd:Array = [[79, 82], [121, 82], [79, 113], [121, 113]][int(Math.random() * 4)];
				x = gd[0] + (Math.random() - 0.5) * 12; y = gd[1] + (Math.random() - 0.5) * 8;
			} else {
				var a:Number = Math.random() * Math.PI * 2, d:Number = Math.sqrt(Math.random()) * 12;
				x = FX + Math.cos(a) * d; y = FY + Math.sin(a) * d;
			}
			return {x: x, y: y, ph: Math.random() * 6.28, life: anywhere ? Math.random() * 6 : 0, max: 5 + Math.random() * 4, fly: garden};
		}

		public function setVisible(on:Boolean):void {
			for each (var l:Object in labels) l.tf.visible = on;
		}

		public function update(dt:Number):void {
			var p:Player = g.player;
			for (var i:int = 0; i < motes.length; i++) {
				var m:Object = motes[i];
				m.life += dt;
				m.x += Math.sin(g.time * 0.7 + m.ph) * dt * (m.fly ? 0.8 : 0.25);
				m.y += (m.fly ? Math.cos(g.time * 0.9 + m.ph) * 0.6 : -0.25) * dt;
				if (m.life > m.max) motes[i] = newMote(false);
			}
			if (!Game.opt("parts") || g.parts.length > 360) return;
			// the fountain sprays, the braziers throw sparks
			// the star well rises in motes of light toward the shard above it
			if (Math.random() < dt * 22) {
				var a:Number = Math.random() * Math.PI * 2, s:Number = 0.4 + Math.random() * 1.6;
				g.parts.push(new Particle(FX + Math.cos(a) * s, FY + Math.sin(a) * s * 0.6, -Math.cos(a) * 0.3, -1.2 - Math.random() * 1.2, 1.0, Sprites.glow(Math.random() < 0.5 ? 0xc8b8ff : 0xffffff)));
			}
			for each (var b:Array in braziers) {
				var dx:Number = b[0] - p.x, dy:Number = b[1] - p.y;
				if (dx * dx + dy * dy > 18 * 18 || Math.random() > dt * 5) continue;
				var vio:Boolean = b[2] == 0xa070ff;
				g.parts.push(new Particle(b[0] + (Math.random() - 0.5) * 0.4, b[1] - 0.9, (Math.random() - 0.5) * 0.4, -1.6 - Math.random(), 0.8, Sprites.glow(Math.random() < 0.6 ? (vio ? 0xa070ff : 0xffa030) : (vio ? 0xe0d0ff : 0xffe080))));
			}
		}

		private function X(x:Number, y:Number):Number { return g.scrX(x, y); }
		private function Y(x:Number, y:Number):Number { return g.scrY(x, y) + Game.TS * 0.5; }

		/** On the floor, under everyone. */
		public function drawGround(canvas:BitmapData):void {
			var TS:int = Game.TS, gr:* = sh.graphics, t:Number = g.time, i:int, a:Number, k:int;
			gr.clear();
			var cx:Number = X(FX, FY - 0.5), cy:Number = Y(FX, FY - 0.5);
			// the sky round the citadel: stones drifting slowly round it, stars twinkling
			for each (var isl:Object in isles) {
				var ia:Number = isl.a + t * isl.s;
				var ix:Number = X(FX + Math.cos(ia) * isl.r, FY + Math.sin(ia) * isl.r * 0.8), iy:Number = Y(FX + Math.cos(ia) * isl.r, FY + Math.sin(ia) * isl.r * 0.8) + Math.sin(t * 0.8 + isl.seed) * 6;
				if (ix < -200 || iy < -200 || ix > canvas.width + 200 || iy > canvas.height + 200) continue;
				var isb:BitmapData = isleArt(isl.size, isl.seed);
				pt.x = int(ix - isb.width / 2); pt.y = int(iy - isb.height / 2);
				canvas.copyPixels(isb, isb.rect, pt, null, null, true);
			}
			for each (var st:Array in stars) {
				var sx2:Number = X(st[0], st[1]), sy2:Number = Y(st[0], st[1]);
				if (sx2 < -8 || sy2 < -8 || sx2 > canvas.width + 8 || sy2 > canvas.height + 8) continue;
				var tw:Number = Math.max(0, Math.sin(t * st[3] * 2 + st[2]));
				if (tw < 0.2) continue;
				gr.beginFill(0xc8b8ff, 0.25 * tw);
				gr.drawCircle(sx2, sy2, 4 * st[3]);
				gr.endFill();
				gr.beginFill(0xffffff, 0.9 * tw);
				gr.moveTo(sx2, sy2 - 4 * tw); gr.lineTo(sx2 + 1, sy2 - 1); gr.lineTo(sx2 + 4 * tw, sy2); gr.lineTo(sx2 + 1, sy2 + 1);
				gr.lineTo(sx2, sy2 + 4 * tw); gr.lineTo(sx2 - 1, sy2 + 1); gr.lineTo(sx2 - 4 * tw, sy2); gr.lineTo(sx2 - 1, sy2 - 1);
				gr.endFill();
			}

			// the star of Eldmere inlaid in gold around the fountain
			var R1:Number = 6.3 * TS, R2:Number = 12.1 * TS;
			gr.lineStyle(3, 0xc89a3a, 0.55);
			gr.drawCircle(cx, cy, R1);
			gr.drawCircle(cx, cy, R2);
			gr.lineStyle(1, 0xffe9a0, 0.35);
			gr.drawCircle(cx, cy, R2 - 6);
			gr.lineStyle(2, 0xd8aa48, 0.45);
			gr.beginFill(0xffd070, 0.07);
			for (i = 0; i <= 16; i++) {
				a = i * Math.PI / 8 - Math.PI / 2;
				var rr:Number = i % 2 == 0 ? R2 - 4 : R1 + 10;
				if (i == 0) gr.moveTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr);
				else gr.lineTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr);
			}
			gr.endFill();
			// runes glowing round the outer ring, one after another
			gr.lineStyle();
			for (i = 0; i < 24; i++) {
				a = i * Math.PI / 12 + t * 0.05;
				var glow:Number = 0.35 + 0.65 * Math.max(0, Math.sin(t * 1.5 - i * 0.5));
				var rx:Number = cx + Math.cos(a) * (R2 + 0.5 * TS), ry:Number = cy + Math.sin(a) * (R2 + 0.5 * TS);
				gr.beginFill(0xffd070, 0.25 * glow);
				gr.drawCircle(rx, ry, 7);
				gr.endFill();
				gr.beginFill(0xfff4c0, 0.8 * glow);
				gr.moveTo(rx, ry - 4); gr.lineTo(rx + 3, ry); gr.lineTo(rx, ry + 4); gr.lineTo(rx - 3, ry); gr.lineTo(rx, ry - 4);
				gr.endFill();
			}

			// warm light pooled around every brazier
			for each (var b:Array in braziers) {
				var bx:Number = X(b[0], b[1]), by:Number = Y(b[0], b[1]) - TS * 0.3;
				var flick:Number = 0.85 + 0.15 * Math.sin(t * 9 + b[0]) * Math.sin(t * 13 + b[1]);
				var lr:Number = TS * 3.2 * flick;
				mtx.createGradientBox(lr * 2, lr * 2, 0, bx - lr, by - lr);
				gr.beginGradientFill(GradientType.RADIAL, [b[2], b[2]], [0.28 * flick, 0], [0, 255], mtx);
				gr.drawCircle(bx, by, lr);
				gr.endFill();
			}

			// rune circles under the realm portals
			for each (var p:Object in g.world.portals) {
				if (p.kind != "realm" || !p.label.visible) continue;
				var px:Number = X(p.x, p.y), py:Number = Y(p.x, p.y) - TS * 0.1;
				gr.lineStyle(2, p.color, 0.55);
				gr.drawCircle(px, py, TS * 1.35);
				gr.lineStyle(1, p.color, 0.35);
				gr.drawCircle(px, py, TS * 1.05);
				gr.lineStyle();
				for (k = 0; k < 6; k++) {
					a = k * Math.PI / 3 + t * 0.6;
					gr.beginFill(Sprites.tint(p.color, 0.5), 0.7);
					gr.drawCircle(px + Math.cos(a) * TS * 1.2, py + Math.sin(a) * TS * 1.2, 2.5);
					gr.endFill();
				}
			}

			// garden flowers (small cached pictures, stamped after the shapes below)
			gr.lineStyle();
			canvas.draw(sh);
			for each (var f:Array in flowers) {
				pt.x = int(X(f[0], f[1]) - 4);
				pt.y = int(Y(f[0], f[1]) - TS * 0.5 - 4);
				if (pt.x < -10 || pt.y < -10 || pt.x > canvas.width || pt.y > canvas.height) continue;
				var fb:BitmapData = flowerArt(f[2]);
				canvas.copyPixels(fb, fb.rect, pt, null, null, true);
			}
		}

		private var flowerCache:Object = {};
		private var shardCache:Object = {};

		/** The star-shard (or one of its slivers): a tall faceted crystal, lilac to white, gold-tipped. */
		private function shardArt(small:Boolean = false):BitmapData {
			var key:String = small ? "s" : "b";
			if (shardCache[key]) return shardCache[key];
			var w:int = small ? 7 : 17, h:int = small ? 13 : 33, sc:int = small ? 3 : 4;
			var bd:BitmapData = new BitmapData(w * sc + 2, h * sc + 2, true, 0);
			var cx:Number = (w - 1) / 2;
			for (var y:int = 0; y < h; y++) {
				// widest a third of the way down, a point at each end
				var f:Number = y < h * 0.35 ? y / (h * 0.35) : (h - 1 - y) / (h * 0.65);
				var half:Number = cx * f;
				for (var x:int = 0; x < w; x++) {
					var dx:Number = x - cx;
					if (Math.abs(dx) > half + 0.25) continue;
					var c:uint = dx < -half * 0.35 ? 0x8a6ad8 : dx < 0 ? 0xc0aaff : dx < half * 0.4 ? 0xf0eaff : 0xa088f0;
					if (Math.abs(dx) > half - 0.75) c = 0x5a3ea8;
					if (y == 0 || y == h - 1) c = 0xffe9a0;
					if (!small && y == int(h * 0.35)) c = 0xffffff;
					bd.fillRect(new flash.geom.Rectangle(1 + x * sc, 1 + y * sc, sc, sc), 0xff000000 | c);
				}
			}
			shardCache[key] = bd;
			return bd;
		}

		private var isleCache:Object = {};

		/** A broken stone drifting in the sky: star-stone on top, a jagged rocky underside. */
		private function isleArt(size:int, seed:int):BitmapData {
			var key:String = size + "_" + seed;
			if (isleCache[key]) return isleCache[key];
			var w:int = 10 + size * 6, top:int = 3 + size, deep:int = 6 + size * 4, sc:int = 3;
			var bd:BitmapData = new BitmapData(w * sc, (top + deep) * sc, true, 0);
			var r:uint = 77 + seed * 131;
			for (var x:int = 0; x < w; x++) {
				var e:Number = Math.abs(x - (w - 1) / 2) / (w / 2);
				r = (r * 1103515245 + 12345) & 0x7fffffff;
				var d:int = int(deep * (1 - e * e) * (0.7 + (r % 30) / 100));
				for (var y:int = 0; y < top + d; y++) {
					if (y < top && e > 0.92) continue;
					var c:uint = y == 0 ? 0x4a4270 : y < top ? (y == top - 1 ? 0xd8b048 : 0x2c2642) : (y - top) % 3 == 0 ? 0x1c1630 : 0x261e3c;
					if (y >= top && y == top + d - 1) c = 0x120e1e;
					bd.fillRect(new flash.geom.Rectangle(x * sc, y * sc, sc, sc), 0xff000000 | c);
				}
			}
			isleCache[key] = bd;
			return bd;
		}

		/** A tiny four-petal flower on a stem. */
		private function flowerArt(col:uint):BitmapData {
			var bd:BitmapData = flowerCache[col];
			if (bd) return bd;
			var f:Shape = new Shape();
			f.graphics.beginFill(0x2a5a1a);
			f.graphics.drawRect(3.5, 4, 1.5, 4);
			f.graphics.endFill();
			f.graphics.beginFill(col);
			f.graphics.drawCircle(2, 4, 1.6); f.graphics.drawCircle(6, 4, 1.6);
			f.graphics.drawCircle(4, 2, 1.6); f.graphics.drawCircle(4, 6, 1.6);
			f.graphics.endFill();
			f.graphics.beginFill(0xffe060);
			f.graphics.drawCircle(4, 4, 1.2);
			f.graphics.endFill();
			bd = new BitmapData(9, 9, true, 0);
			bd.draw(f);
			flowerCache[col] = bd;
			return bd;
		}

		/** Above everyone: light rising from the portals, the class banners, dust and fireflies. */
		public function drawTop(canvas:BitmapData):void {
			var TS:int = Game.TS, gr:* = sh.graphics, t:Number = g.time, i:int;
			gr.clear();
			// pillars of light over the realm portals
			for each (var p:Object in g.world.portals) {
				if (p.kind != "realm" || !p.label.visible) continue;
				var px:Number = X(p.x, p.y), py:Number = Y(p.x, p.y) - TS * 0.5;
				var bw:Number = TS * (0.9 + 0.12 * Math.sin(t * 3 + p.idx));
				mtx.createGradientBox(bw, TS * 6, Math.PI / 2, px - bw / 2, py - TS * 6);
				gr.beginGradientFill(GradientType.LINEAR, [p.color, p.color], [0, 0.32], [0, 255], mtx);
				gr.drawRect(px - bw / 2, py - TS * 6, bw, TS * 6);
				gr.endFill();
			}
			// the shard of the fallen star, floating over the well: a soft halo, slow rays, the crystal
			var scx:Number = X(FX, FY), scy:Number = Y(FX, FY) - TS * 3.6 + Math.sin(t * 1.3) * 6;
			var hr:Number = TS * (2.4 + 0.2 * Math.sin(t * 2));
			mtx.createGradientBox(hr * 2, hr * 2, 0, scx - hr, scy - hr);
			gr.beginGradientFill(GradientType.RADIAL, [0xd8c8ff, 0x8a6aff, 0x8a6aff], [0.35, 0.12, 0], [0, 110, 255], mtx);
			gr.drawCircle(scx, scy, hr);
			gr.endFill();
			for (i = 0; i < 8; i++) {
				var ra:Number = i * Math.PI / 4 + t * 0.15, rl:Number = TS * (2.6 + 0.6 * Math.sin(t * 1.7 + i));
				gr.beginFill(0xe8deff, 0.08 + 0.05 * Math.sin(t * 2 + i));
				gr.moveTo(scx, scy);
				gr.lineTo(scx + Math.cos(ra - 0.07) * rl, scy + Math.sin(ra - 0.07) * rl);
				gr.lineTo(scx + Math.cos(ra + 0.07) * rl, scy + Math.sin(ra + 0.07) * rl);
				gr.lineTo(scx, scy);
				gr.endFill();
			}
			canvas.draw(sh);
			gr.clear();
			var shard:BitmapData = shardArt();
			mtx.identity();
			mtx.translate(int(scx - shard.width / 2), int(scy - shard.height / 2));
			canvas.draw(shard, mtx);
			// three slivers circling it
			for (i = 0; i < 3; i++) {
				var oa:Number = t * 0.9 + i * Math.PI * 2 / 3;
				var sl:BitmapData = shardArt(true);
				pt.x = int(scx + Math.cos(oa) * TS * 1.6 - sl.width / 2); pt.y = int(scy + Math.sin(oa) * TS * 0.55 - sl.height / 2 + TS * 0.3);
				canvas.copyPixels(sl, sl.rect, pt, null, null, true);
			}
			// the class banners
			for each (var b:Array in BANNERS) {
				var bx:Number = X(b[0], b[1]), by:Number = Y(b[0], b[1]) - TS * 1.6;
				var sway:Number = Math.sin(t * 1.6 + b[0] * 0.3) * 2.5;
				var col:uint = CLASS_COL[b[2]];
				gr.lineStyle(3, 0x3a2410);
				gr.moveTo(bx - 20, by); gr.lineTo(bx + 20, by);
				gr.lineStyle(1.5, 0x1a0c04);
				gr.beginFill(col);
				gr.moveTo(bx - 16, by);
				gr.lineTo(bx + 16, by);
				gr.lineTo(bx + 16 + sway * 0.5, by + 52);
				gr.lineTo(bx + sway, by + 42);
				gr.lineTo(bx - 16 + sway * 0.5, by + 52);
				gr.lineTo(bx - 16, by);
				gr.endFill();
				gr.lineStyle(2, 0xe8c060, 0.9);
				gr.moveTo(bx - 13, by + 4); gr.lineTo(bx + 13, by + 4);
				gr.moveTo(bx - 13 + sway * 0.4, by + 40); gr.lineTo(bx + sway * 0.6, by + 33);
				gr.lineStyle();
			}
			// dust motes and fireflies
			for each (var m:Object in motes) {
				var fa:Number = Math.min(1, m.life, m.max - m.life);
				if (fa <= 0) continue;
				var blink:Number = m.fly ? Math.max(0, Math.sin(t * 3 + m.ph * 3)) : 0.7 + 0.3 * Math.sin(t * 2 + m.ph);
				var mx:Number = X(m.x, m.y), my:Number = Y(m.x, m.y) - TS * 1.2;
				gr.beginFill(m.fly ? 0xd8ff70 : 0xffe9a0, 0.25 * fa * blink);
				gr.drawCircle(mx, my, m.fly ? 5 : 4);
				gr.endFill();
				gr.beginFill(m.fly ? 0xf0ffb0 : 0xfff8e0, 0.9 * fa * blink);
				gr.drawCircle(mx, my, 1.4);
				gr.endFill();
			}
			canvas.draw(sh);
			// each banner carries its class's portrait
			for each (b in BANNERS) {
				var hero:BitmapData = Sprites.get(b[2]);
				var hx:Number = X(b[0], b[1]), hy:Number = Y(b[0], b[1]) - TS * 1.6;
				mtx.identity();
				mtx.scale(0.6, 0.6);
				mtx.translate(int(hx - hero.width * 0.3 + Math.sin(t * 1.6 + b[0] * 0.3)), int(hy + 8));
				canvas.draw(hero, mtx, null, null, null, false);
			}
			for each (var l:Object in labels) {
				l.tf.x = int(X(l.x, l.y) - l.tf.width / 2);
				l.tf.y = int(Y(l.x, l.y) - TS * 0.5 - l.tf.height / 2);
			}
		}
	}
}
