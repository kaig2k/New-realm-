package realm {
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;

	/**
	 * The Nexus as the heart of Eldmere: the star of Eldmere inlaid around the
	 * fountain, rune circles under the realm portals with light rising from them,
	 * warm light around the braziers, the eight class banners on the walls,
	 * flowers and fireflies in the gardens, and the Sealed Gate where Azrakor
	 * the Dark Elder lies bound beneath the city.
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
		private var sealNoted:Boolean = false;

		/** The fountain at the heart of the plaza, and the Sealed Gate in the entrance hall. */
		public static const FX:Number = 100.5, FY:Number = 98.5;
		public static const SEAL_X:Number = 100.5, SEAL_Y:Number = 121.5;

		/** Banners along the walls: [x, y, class]. */
		private static const BANNERS:Array = [[70.5, 64.9, "wizard"], [75.5, 64.9, "archer"], [125.5, 64.9, "knight"], [130.5, 64.9, "priest"],
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
				if (w.objs[i] == 7) braziers.push([x + 0.5, y + 0.5]);
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
			label(makeLabel, "The Realm Gate", 0xffd75e, 100.5, 75.6);
			label(makeLabel, "Hall of Heroes", 0xe8d8b0, 100.5, 86.2);
			label(makeLabel, "The Sealed Gate", 0xc070ff, SEAL_X, SEAL_Y - 2.6);
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
			if (Math.random() < dt * 22) {
				var a:Number = Math.random() * Math.PI * 2, s:Number = 0.6 + Math.random() * 1.2;
				g.parts.push(new Particle(FX + Math.cos(a) * 0.3, FY - 0.6, Math.cos(a) * s, Math.sin(a) * s * 0.6 - 1.4, 0.7, Sprites.glow(Math.random() < 0.5 ? 0xc8ecff : 0xffffff)));
			}
			for each (var b:Array in braziers) {
				var dx:Number = b[0] - p.x, dy:Number = b[1] - p.y;
				if (dx * dx + dy * dy > 18 * 18 || Math.random() > dt * 5) continue;
				g.parts.push(new Particle(b[0] + (Math.random() - 0.5) * 0.4, b[1] - 0.9, (Math.random() - 0.5) * 0.4, -1.6 - Math.random(), 0.8, Sprites.glow(Math.random() < 0.6 ? 0xffa030 : 0xffe080)));
			}
			// passing the Sealed Gate for the first time tells its story
			if (!sealNoted) {
				var sx:Number = p.x - SEAL_X, sy:Number = p.y - SEAL_Y;
				if (sx * sx + sy * sy < 3.2 * 3.2) {
					sealNoted = true;
					g.tip("seal", "The Sealed Gate: Azrakor the Dark Elder lies bound beneath Eldmere. Every realm that falls weakens the seal, and when a realm closes he drags its heroes into his chamber.");
				}
			}
		}

		private function X(x:Number, y:Number):Number { return g.scrX(x, y); }
		private function Y(x:Number, y:Number):Number { return g.scrY(x, y) + Game.TS * 0.5; }

		/** On the floor, under everyone. */
		public function drawGround(canvas:BitmapData):void {
			var TS:int = Game.TS, gr:* = sh.graphics, t:Number = g.time, i:int, a:Number, k:int;
			gr.clear();
			var cx:Number = X(FX, FY - 0.5), cy:Number = Y(FX, FY - 0.5);

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
				gr.beginGradientFill(GradientType.RADIAL, [0xffb050, 0xffb050], [0.28 * flick, 0], [0, 255], mtx);
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
			// the Sealed Gate: a cracked ring of violet runes over Azrakor's prison
			var sx:Number = X(SEAL_X, SEAL_Y), sy:Number = Y(SEAL_X, SEAL_Y) - TS * 0.5;
			var pulse:Number = 0.65 + 0.35 * Math.sin(t * 2.2);
			var sr:Number = TS * 2.3;
			mtx.createGradientBox(sr * 3.2, sr * 3.2, 0, sx - sr * 1.6, sy - sr * 1.6);
			gr.beginGradientFill(GradientType.RADIAL, [0x8a30e0, 0x8a30e0], [0.5 * pulse, 0], [0, 255], mtx);
			gr.drawCircle(sx, sy, sr * 1.6);
			gr.endFill();
			mtx.createGradientBox(sr * 1.64, sr * 1.64, 0, sx - sr * 0.82, sy - sr * 0.82);
			gr.beginGradientFill(GradientType.RADIAL, [0x3a1060, 0x0e0614], [0.95, 0.95], [0, 255], mtx);
			gr.drawCircle(sx, sy, sr * 0.82);
			gr.endFill();
			gr.lineStyle(4, 0xb060ff, 0.85 * pulse);
			gr.drawCircle(sx, sy, sr);
			gr.lineStyle(2, 0xe0b8ff, 0.8 * pulse);
			gr.drawCircle(sx, sy, sr * 0.82);
			// runes turning slowly around the rim
			gr.lineStyle();
			for (i = 0; i < 12; i++) {
				a = i * Math.PI / 6 - t * 0.2;
				var gx:Number = sx + Math.cos(a) * sr * 0.91, gy:Number = sy + Math.sin(a) * sr * 0.91;
				gr.beginFill(0xf0d8ff, 0.9 * pulse);
				gr.drawRect(gx - 2, gy - 3, 4, 6);
				gr.endFill();
			}
			gr.lineStyle(2, 0xc890ff, 0.75 * pulse);
			// the Dark Elder's sigil: two crossed triangles
			for (k = 0; k < 2; k++) {
				gr.moveTo(sx + Math.cos(k * Math.PI - Math.PI / 2) * sr * 0.75, sy + Math.sin(k * Math.PI - Math.PI / 2) * sr * 0.75);
				for (i = 1; i <= 3; i++) {
					a = k * Math.PI - Math.PI / 2 + i * Math.PI * 2 / 3;
					gr.lineTo(sx + Math.cos(a) * sr * 0.75, sy + Math.sin(a) * sr * 0.75);
				}
			}
			// cracks running out of the seal
			gr.lineStyle(2, 0xd0a0ff, 0.5 * pulse);
			for each (var c:Array in [[0.3, 1.0], [2.2, 0.8], [3.9, 1.1], [5.1, 0.9]]) {
				gr.moveTo(sx + Math.cos(c[0]) * sr, sy + Math.sin(c[0]) * sr);
				gr.lineTo(sx + Math.cos(c[0] + 0.15) * sr * (1 + c[1] * 0.35), sy + Math.sin(c[0] + 0.15) * sr * (1 + c[1] * 0.35));
				gr.lineTo(sx + Math.cos(c[0] - 0.05) * sr * (1 + c[1] * 0.6), sy + Math.sin(c[0] - 0.05) * sr * (1 + c[1] * 0.6));
			}
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
			// the eight class banners
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
