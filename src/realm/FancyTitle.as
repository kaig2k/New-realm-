package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	/**
	 * A big drop title made of separate letters (DropReveal): each one slams in
	 * from above in turn, then they ride a slow wave. The letters are cut out of a
	 * metal that a bright shine keeps sweeping across: white gold with a prismatic
	 * glint for Godly, molten lava that shimmers with heat and sheds embers for
	 * Primordial. Ornate lines with diamonds grow out on both sides.
	 */
	public class FancyTitle extends Sprite {
		private static const SIZE:int = 50;
		private var godly:Boolean;
		private var letters:Array = [];
		private var flourish:Shape = new Shape();
		private var embers:Array = [];
		private var emberLayer:Sprite = new Sprite();
		private var width0:Number = 0;
		private var grad:Shape = new Shape();
		private var gm:Matrix = new Matrix();

		public function FancyTitle(text:String, godly:Boolean) {
			this.godly = godly;
			mouseEnabled = mouseChildren = false;
			addChild(flourish);
			addChild(emberLayer);
			// each letter: its shape (white, from the game's font) kept as an alpha mask
			var x:Number = 0;
			for (var i:int = 0; i < text.length; i++) {
				var ch:String = text.charAt(i);
				if (ch == " ") { x += SIZE * 0.42; continue; }
				var tf:TextField = Ui.text(SIZE, 0xffffff, true, "left", 0, false);
				tf.text = ch;
				var lw:int = Math.ceil(tf.textWidth) + 8, lh:int = Math.ceil(tf.textHeight) + 8;
				var mask:BitmapData = new BitmapData(lw, lh, true, 0);
				mask.draw(tf, new Matrix(1, 0, 0, 1, 2, 0));
				var bmp:Bitmap = new Bitmap(new BitmapData(lw, lh, true, 0));
				var holder:Sprite = new Sprite();
				bmp.x = -lw / 2; bmp.y = -lh;
				holder.addChild(bmp);
				holder.filters = godly
					? [new GlowFilter(0x3a2a00, 1, 3, 3, 8), new GlowFilter(0xffe9a0, 0.9, 16, 16, 2), new DropShadowFilter(4, 90, 0x000000, 0.8, 4, 4, 2)]
					: [new GlowFilter(0x2a0400, 1, 3, 3, 8), new GlowFilter(0xff5020, 1, 18, 18, 2.5), new DropShadowFilter(4, 90, 0x000000, 0.8, 4, 4, 2)];
				holder.x = x + lw / 2;
				addChild(holder);
				letters.push({h: holder, bmp: bmp, mask: mask, x: holder.x, i: letters.length});
				x += tf.textWidth - 1;
			}
			width0 = x;
			for each (var l:Object in letters) { l.x -= width0 / 2; l.h.x = l.x; l.h.visible = false; }
		}

		/** Paints letter l's metal for time t (the shine at position `shine`, 0..1 across the word). */
		private function paint(l:Object, t:Number, shine:Number):void {
			var bd:BitmapData = l.bmp.bitmapData;
			var g:* = grad.graphics;
			g.clear();
			var lw:int = bd.width, lh:int = bd.height;
			gm.createGradientBox(lw, lh, Math.PI / 2, 0, 0);
			if (godly) g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xfff0b0, 0xe8b830, 0xfff6d8, 0xb07818], [1, 1, 1, 1, 1], [0, 70, 130, 175, 255], gm);
			else {
				// lava: dark at the bottom, white-hot at the top, flickering
				var f:Number = 0.5 + 0.5 * Math.sin(t * 9 + l.i * 1.7);
				g.beginGradientFill(GradientType.LINEAR, [0xfff0a0, 0xffb030, 0xff5010, 0xa01800, 0x400800], [1, 1, 1, 1, 1], [0, int(50 + f * 30), 140, 200, 255], gm);
			}
			g.drawRect(0, 0, lw, lh);
			g.endFill();
			// the shine: a bright slanted band passing through this letter
			var mine:Number = (l.x + width0 / 2) / Math.max(1, width0);
			var d:Number = (shine - mine) * width0;
			if (Math.abs(d) < 60) {
				var a:Number = 1 - Math.abs(d) / 60;
				gm.createGradientBox(34, lh * 1.6, 0.35, lw / 2 - d - 17, -lh * 0.3);
				g.beginGradientFill(GradientType.LINEAR, [godly ? 0xffffff : 0xffffd0, godly ? 0xffffff : 0xffffd0, 0xffffff], [0, a * 0.95, 0], [0, 128, 255], gm);
				g.drawRect(0, 0, lw, lh);
				g.endFill();
			}
			// Godly: a faint rainbow glint drifting through the gold
			if (godly) {
				gm.createGradientBox(lw * 3, lh, 0, -((t * 90 + l.i * 9) % (lw * 2)), 0);
				g.beginGradientFill(GradientType.LINEAR, [0xff80c0, 0x80c0ff, 0x80ffb0, 0xffe080, 0xff80c0], [0.22, 0.22, 0.22, 0.22, 0.22], [0, 64, 128, 192, 255], gm);
				g.drawRect(0, 0, lw, lh);
				g.endFill();
			}
			bd.fillRect(bd.rect, 0);
			bd.draw(grad);
			bd.copyChannel(l.mask, l.mask.rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
		}

		/** Draws the title at time t (seconds since the reveal began). */
		public function update(t:Number, dt:Number):void {
			var shine:Number = ((t - 0.9) * 0.55) % 1.6 - 0.3;
			for each (var l:Object in letters) {
				var start:Number = 0.12 + l.i * 0.05;
				var p:Number = (t - start) / 0.22;
				if (p < 0) { l.h.visible = false; continue; }
				l.h.visible = true;
				if (p < 1) {
					// slam: from big and high, down past its place, then settle
					var e:Number = 1 - (1 - p) * (1 - p);
					l.h.scaleX = l.h.scaleY = 2.4 - 1.4 * e;
					l.h.y = -60 * (1 - e);
					l.h.alpha = Math.min(1, p * 2);
					l.h.rotation = (l.i % 2 ? 12 : -12) * (1 - e);
				} else {
					var after:Number = t - start - 0.22;
					// a squash on landing, then the wave
					var squash:Number = after < 0.15 ? Math.sin(after / 0.15 * Math.PI) * 0.18 : 0;
					l.h.scaleX = 1 + squash;
					l.h.scaleY = 1 - squash;
					l.h.rotation = 0;
					l.h.y = Math.sin(t * 3 + l.i * 0.55) * 4;
					l.h.alpha = 1;
					// Primordial letters shiver with heat
					if (!godly) l.h.x = l.x + Math.sin(t * 31 + l.i * 2.3) * 0.8;
					if (!godly && Math.random() < 0.08) ember(l.h.x, l.h.y - SIZE * 0.6);
				}
				paint(l, t, shine);
			}
			drawFlourish(t);
			for (var i:int = embers.length - 1; i >= 0; i--) {
				var em:Object = embers[i];
				em.life -= dt;
				em.s.x += em.vx * dt; em.s.y += em.vy * dt;
				em.vy -= 18 * dt;
				em.s.alpha = Math.max(0, em.life / em.max);
				if (em.life <= 0) { emberLayer.removeChild(em.s); embers.splice(i, 1); }
			}
		}

		private function ember(x:Number, y:Number):void {
			var s:Shape = new Shape();
			s.graphics.beginFill(Math.random() < 0.5 ? 0xffd040 : 0xff6020);
			s.graphics.drawCircle(0, 0, 1 + Math.random() * 1.8);
			s.graphics.endFill();
			s.blendMode = BlendMode.ADD;
			s.x = x + (Math.random() - 0.5) * 20; s.y = y;
			var life:Number = 0.6 + Math.random() * 0.7;
			embers.push({s: s, vx: (Math.random() - 0.5) * 20, vy: -30 - Math.random() * 40, life: life, max: life});
			emberLayer.addChild(s);
		}

		/** Ornate lines with diamonds, growing out from both sides once the word has landed. */
		private function drawFlourish(t:Number):void {
			var g:* = flourish.graphics;
			g.clear();
			var p:Number = Math.max(0, Math.min(1, (t - 0.25 - letters.length * 0.05) / 0.5));
			if (p <= 0) return;
			var c1:uint = godly ? 0xffe9a0 : 0xff7030, c2:uint = godly ? 0xffffff : 0xffd080;
			var y:Number = -SIZE * 0.42;
			var len:Number = 150 * (1 - (1 - p) * (1 - p));
			for (var side:int = -1; side <= 1; side += 2) {
				var x0:Number = side * (width0 / 2 + 14);
				g.lineStyle(3, c1, 0.9);
				g.moveTo(x0, y); g.lineTo(x0 + side * len, y);
				g.lineStyle(1, c2, 0.9);
				g.moveTo(x0, y - 5); g.lineTo(x0 + side * len * 0.7, y - 5);
				g.moveTo(x0, y + 5); g.lineTo(x0 + side * len * 0.7, y + 5);
				g.lineStyle();
				// diamonds: one at the end, a small one near the word
				diamond(g, x0 + side * len, y, 7, c2, c1);
				diamond(g, x0 + side * 4, y, 4, c2, c1);
				if (p >= 1) diamond(g, x0 + side * len * 0.5, y + Math.sin(t * 4 + side) * 2, 3, c2, c1);
			}
		}

		private static function diamond(g:*, x:Number, y:Number, r:Number, fill:uint, edge:uint):void {
			g.lineStyle(1.5, edge, 1);
			g.beginFill(fill);
			g.moveTo(x, y - r); g.lineTo(x + r, y); g.lineTo(x, y + r); g.lineTo(x - r, y); g.lineTo(x, y - r);
			g.endFill();
			g.lineStyle();
		}
	}
}
