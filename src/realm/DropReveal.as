package realm {
	import flash.display.BlendMode;
	import flash.display.Bitmap;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.utils.getTimer;

	/**
	 * The big moment when a Godly or Primordial item drops: a flash, spinning
	 * rays, the item bursting in large and glowing, a shimmering title and a
	 * shower of sparks, then it fades. It never takes the mouse, so the fight
	 * goes on underneath it.
	 */
	public class DropReveal extends Sprite {
		private var t:Number = 0;
		private var last:int = 0;
		private var life:Number;
		private var godly:Boolean;
		private var col:uint;
		private var flash:Shape = new Shape();
		private var rays:Shape = new Shape();
		private var band:Shape = new Shape();
		private var holder:Sprite = new Sprite();
		private var icon:Bitmap;
		private var title:TextField, nameTf:TextField, sub:TextField;
		private var sparks:Array = [];
		private var sparkLayer:Sprite = new Sprite();
		private var w:int, h:int, cy:int;
		/** Over (and gone from the screen). */
		public var done:Boolean = false;

		public function DropReveal(item:Object, from:String, w:int, h:int) {
			this.w = w; this.h = h;
			mouseEnabled = mouseChildren = false;
			godly = item.rarity == "gd";
			col = Data.RARITY_COLORS[item.rarity] || 0xffffff;
			life = godly ? 6 : 4.8;
			cy = int(h * 0.3);
			// the screen flashes white (Godly) or ember red (Primordial)
			flash.graphics.beginFill(godly ? 0xffffff : 0xff5020);
			flash.graphics.drawRect(0, 0, w, h);
			flash.graphics.endFill();
			flash.blendMode = BlendMode.ADD;
			addChild(flash);
			// a dark band to set it off
			var m:Matrix = new Matrix();
			m.createGradientBox(w, 360, Math.PI / 2, 0, cy - 180);
			band.graphics.beginGradientFill(GradientType.LINEAR, [0x000000, 0x000000, 0x000000, 0x000000], [0, 0.78, 0.78, 0], [0, 50, 205, 255], m);
			band.graphics.drawRect(0, cy - 180, w, 360);
			band.graphics.endFill();
			addChild(band);
			// spinning rays
			rays.x = w / 2; rays.y = cy;
			rays.blendMode = BlendMode.ADD;
			var n:int = godly ? 18 : 14;
			for (var i:int = 0; i < n; i++) {
				var a0:Number = i * Math.PI * 2 / n, a1:Number = a0 + Math.PI / n * 0.55;
				var rm:Matrix = new Matrix();
				rm.createGradientBox(560, 560, 0, -280, -280);
				rays.graphics.beginGradientFill(GradientType.RADIAL, [godly && i % 2 ? 0xffffff : col, col], [0.55, 0], [0, 255], rm);
				rays.graphics.moveTo(0, 0);
				rays.graphics.lineTo(Math.cos(a0) * 280, Math.sin(a0) * 280);
				rays.graphics.lineTo(Math.cos(a1) * 280, Math.sin(a1) * 280);
				rays.graphics.lineTo(0, 0);
				rays.graphics.endFill();
			}
			addChild(rays);
			addChild(sparkLayer);
			// the item itself, big, on a halo
			holder.x = w / 2; holder.y = cy;
			var halo:Shape = new Shape();
			var hm:Matrix = new Matrix();
			hm.createGradientBox(180, 180, 0, -90, -90);
			halo.graphics.beginGradientFill(GradientType.RADIAL, [0xffffff, col, col], [0.9, 0.45, 0], [0, 90, 255], hm);
			halo.graphics.drawCircle(0, 0, 90);
			halo.graphics.endFill();
			halo.blendMode = BlendMode.ADD;
			holder.addChild(halo);
			icon = new Bitmap(Sprites.icon(item));
			icon.scaleX = icon.scaleY = 3;
			icon.x = -icon.width / 2; icon.y = -icon.height / 2;
			holder.addChild(icon);
			holder.filters = [new GlowFilter(col, 1, 24, 24, 3)];
			holder.scaleX = holder.scaleY = 0;
			addChild(holder);
			// the words
			title = Ui.text(40, godly ? 0xfff6e0 : col, true, "center", w, true);
			title.text = godly ? "G O D L Y   D R O P !" : "P R I M O R D I A L   D R O P !";
			title.y = cy - 150;
			title.filters = [new GlowFilter(col, 1, 18, 18, 3), new GlowFilter(0x000000, 1, 4, 4, 6)];
			addChild(title);
			nameTf = Ui.text(24, col, true, "center", w, true);
			nameTf.text = item.name;
			nameTf.y = cy + 88;
			nameTf.filters = [new GlowFilter(0x000000, 1, 4, 4, 6), new GlowFilter(col, 0.7, 10, 10, 2)];
			addChild(nameTf);
			sub = Ui.text(14, 0xdddddd, false, "center", w, true);
			sub.htmlText = (from ? "from <b>" + from + "</b>   ·   " : "") + (godly ? "1 in 1,000 from the bosses that carry them" : "the rarest gear in the realm");
			sub.y = cy + 122;
			addChild(sub);
			addEventListener(Event.ENTER_FRAME, tick);
		}

		private function spark(burst:Boolean):void {
			var s:Shape = new Shape();
			var c:uint = Math.random() < 0.4 ? 0xffffff : col;
			s.graphics.beginFill(c);
			var r:Number = 1.5 + Math.random() * 2.5;
			s.graphics.moveTo(0, -r * 2); s.graphics.lineTo(r * 0.5, 0); s.graphics.lineTo(0, r * 2); s.graphics.lineTo(-r * 0.5, 0);
			s.graphics.moveTo(-r * 2, 0); s.graphics.lineTo(0, r * 0.5); s.graphics.lineTo(r * 2, 0); s.graphics.lineTo(0, -r * 0.5);
			s.graphics.endFill();
			s.blendMode = BlendMode.ADD;
			var a:Number = Math.random() * Math.PI * 2, sp:Number = burst ? 180 + Math.random() * 320 : 40 + Math.random() * 80;
			s.x = w / 2 + Math.cos(a) * (burst ? 10 : 60 + Math.random() * 60);
			s.y = cy + Math.sin(a) * (burst ? 10 : 60 + Math.random() * 60);
			sparks.push({s: s, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp - (burst ? 0 : 30), life: 0.8 + Math.random() * 0.9, max: 1.7});
			sparkLayer.addChild(s);
		}

		private function tick(e:Event):void {
			// real time, so it lasts as long on a slow PC as on a fast one
			var now:int = getTimer();
			var dt:Number = last ? Math.min(0.1, (now - last) / 1000) : 1 / 30;
			last = now;
			t += dt;
			if (t < dt * 1.5) for (var k:int = 0; k < (godly ? 70 : 45); k++) spark(true);
			else if (t < life - 1 && Math.random() < 0.6) spark(false);
			// flash: bright, then gone
			flash.alpha = Math.max(0, 0.75 - t * 2.2);
			rays.rotation += godly ? 1.2 : 0.9;
			rays.scaleX = rays.scaleY = Math.min(1, t * 2.5) * (1 + Math.sin(t * 3) * 0.05);
			// the item bursts in, overshoots, settles and bobs
			var p:Number = Math.min(1, t / 0.5);
			var sc:Number = p < 1 ? 1 + 0.35 * Math.sin(p * Math.PI) - (1 - p) : 1 + Math.sin(t * 2.2) * 0.04;
			holder.scaleX = holder.scaleY = Math.max(0, sc);
			holder.y = cy + Math.sin(t * 2) * 5;
			var gf:GlowFilter = new GlowFilter(col, 1, 18 + Math.sin(t * 5) * 8, 18 + Math.sin(t * 5) * 8, 3);
			holder.filters = [gf];
			// the title slides in and shimmers (Godly: through pale gold, white and a touch of every colour)
			title.alpha = nameTf.alpha = sub.alpha = Math.min(1, t * 3);
			title.y = cy - 150 - Math.max(0, 0.3 - t) * 120;
			if (godly) {
				var hue:Number = (t * 0.6) % 1;
				title.textColor = mix(0xfff6e0, hsv(hue), 0.3 + 0.2 * Math.sin(t * 4));
			} else title.textColor = mix(col, 0xffd0a0, 0.5 + 0.5 * Math.sin(t * 6));
			for (var i:int = sparks.length - 1; i >= 0; i--) {
				var sp:Object = sparks[i];
				sp.life -= dt;
				sp.vx *= 0.94; sp.vy = sp.vy * 0.94 + 20 * dt;
				sp.s.x += sp.vx * dt; sp.s.y += sp.vy * dt;
				sp.s.rotation += 8;
				sp.s.alpha = Math.max(0, sp.life / sp.max * 1.6);
				if (sp.life <= 0) { sparkLayer.removeChild(sp.s); sparks.splice(i, 1); }
			}
			// fade out at the end
			if (t > life - 0.8) alpha = Math.max(0, (life - t) / 0.8);
			if (t >= life) {
				removeEventListener(Event.ENTER_FRAME, tick);
				if (parent) parent.removeChild(this);
				done = true;
			}
		}

		private static function mix(a:uint, b:uint, k:Number):uint {
			k = Math.max(0, Math.min(1, k));
			var r:int = ((a >> 16) & 255) * (1 - k) + ((b >> 16) & 255) * k;
			var g:int = ((a >> 8) & 255) * (1 - k) + ((b >> 8) & 255) * k;
			var bl:int = (a & 255) * (1 - k) + (b & 255) * k;
			return (r << 16) | (g << 8) | bl;
		}

		private static function hsv(hh:Number):uint {
			var i:int = int(hh * 6), f:Number = hh * 6 - i, q:Number = 1 - f;
			var r:Number, g:Number, b:Number;
			switch (i % 6) {
				case 0: r = 1; g = f; b = 0; break;
				case 1: r = q; g = 1; b = 0; break;
				case 2: r = 0; g = 1; b = f; break;
				case 3: r = 0; g = q; b = 1; break;
				case 4: r = f; g = 0; b = 1; break;
				default: r = 1; g = 0; b = q;
			}
			return (int(r * 255) << 16) | (int(g * 255) << 8) | int(b * 255);
		}
	}
}
