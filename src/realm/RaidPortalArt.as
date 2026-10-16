package realm {
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	/**
	 * A raid's portal: an obsidian gate (two rune-carved pillars and a spiked crown) around a
	 * swirling vortex in the raid's colour, a rune circle turning on the ground, and a beam of
	 * light into the sky. Heroic raids get a gold gate with taller spikes. Pixel art, made once
	 * per raid colour and frame (Game.drawRaidPortal plays it).
	 */
	public class RaidPortalArt {
		public static const FRAMES:int = 12;
		/** Logical size (drawn at 2x). */
		private static const W:int = 64, H:int = 78, SCALE:int = 2;
		private static var cache:Object = {};

		private static function shade(c:uint, f:Number):uint {
			return (uint(((c >> 16) & 255) * f) << 16) | (uint(((c >> 8) & 255) * f) << 8) | uint((c & 255) * f);
		}
		private static function tint(c:uint, f:Number):uint {
			var r:int = (c >> 16) & 255, g:int = (c >> 8) & 255, b:int = c & 255;
			return (uint(r + (255 - r) * f) << 16) | (uint(g + (255 - g) * f) << 8) | uint(b + (255 - b) * f);
		}

		/** The gate and its vortex, frame f of FRAMES. */
		public static function gate(col:uint, heroic:Boolean, f:int):BitmapData {
			f = ((f % FRAMES) + FRAMES) % FRAMES;
			var key:String = "g" + col + (heroic ? "h" : "") + "_" + f;
			if (cache[key]) return cache[key];
			var bd:BitmapData = new BitmapData(W, H, true, 0);
			var ph:Number = f / FRAMES * Math.PI * 2;
			var pal:Array = [0xff000000 | shade(col, 0.18), 0xff000000 | shade(col, 0.42), 0xff000000 | shade(col, 0.72), 0xff000000 | col, 0xff000000 | tint(col, 0.45), 0xff000000 | tint(col, 0.85)];
			var stone:uint = heroic ? 0xff3a2c14 : 0xff1c1628, stoneHi:uint = heroic ? 0xff6a5020 : 0xff342a48, stoneLo:uint = heroic ? 0xff1c1408 : 0xff0e0a16;
			var rune:uint = 0xff000000 | tint(col, 0.6);
			var cx:Number = 32, cy:Number = 42, rx:Number = 18, ry:Number = 25;
			var x:int, y:int;
			// --- the vortex
			for (y = 0; y < H; y++) for (x = 0; x < W; x++) {
				var dx:Number = (x + 0.5 - cx) / rx, dy:Number = (y + 0.5 - cy) / ry;
				var d:Number = Math.sqrt(dx * dx + dy * dy);
				if (d >= 1.18) continue;
				var a:Number = Math.atan2(dy, dx);
				if (d < 1) {
					// three spiral arms turning inward, brightest at the heart
					var swirl:Number = Math.sin(a * 3 + d * 7.5 - ph) * 0.5 + 0.5;
					var v:Number = Math.pow(1 - d, 0.8) * 0.9 + swirl * 0.45 * (0.3 + d);
					if (d < 0.16) v = 1.5;
					bd.setPixel32(x, y, pal[Math.max(0, Math.min(5, int(v * 4.2)))]);
				} else {
					// the rim: dark stone with runes that travel around it
					var on:Boolean = false;
					for (var k:int = 0; k < 10; k++) {
						var ra:Number = k * Math.PI * 2 / 10 + ph * 0.5;
						var diff:Number = Math.abs(Math.atan2(Math.sin(a - ra), Math.cos(a - ra)));
						if (diff < 0.09) on = true;
					}
					bd.setPixel32(x, y, on ? rune : (d < 1.08 ? stoneHi : stone));
				}
			}
			// --- the pillars, with a glowing rune slit that pulses
			var glow:Number = 0.55 + 0.45 * Math.sin(ph);
			var slit:uint = 0xff000000 | (glow > 0.6 ? tint(col, 0.3) : col);
			for each (var px:int in [6, 52]) {
				for (y = 16; y < 72; y++) for (x = px; x < px + 7; x++) {
					var edge:Boolean = x == px || x == px + 6;
					var c:uint = edge ? stoneLo : ((y + (x - px)) % 9 == 0 ? stoneLo : (x == px + 1 ? stoneHi : stone));
					if (x == px + 3 && y > 22 && y < 66 && (y % 7) != 0) c = slit;
					bd.setPixel32(x, y, c);
				}
				// capitals
				for (x = px - 1; x < px + 8; x++) { bd.setPixel32(x, 15, stoneHi); bd.setPixel32(x, 14, stone); bd.setPixel32(x, 72, stoneHi); }
			}
			// --- the crown: a lintel with spikes (taller and gold for Heroic)
			for (x = 8; x < 56; x++) for (y = 9; y < 15; y++) bd.setPixel32(x, y, y == 9 ? stoneHi : (x % 6 == 0 ? stoneLo : stone));
			var spikes:Array = heroic ? [[14, 6], [23, 9], [32, 13], [41, 9], [50, 6]] : [[20, 6], [32, 9], [44, 6]];
			for each (var sp:Array in spikes) {
				for (var h:int = 1; h <= sp[1]; h++) {
					var half:int = int((sp[1] - h) / 3);
					for (x = sp[0] - half; x <= sp[0] + half; x++) bd.setPixel32(x, 9 - h, h == sp[1] ? rune : (x == sp[0] - half ? stoneHi : stone));
				}
			}
			// a gem in the middle of the lintel, burning in the raid's colour
			for (y = 10; y < 14; y++) for (x = 30; x < 34; x++) bd.setPixel32(x, y, (x + y) % 2 ? pal[5] : pal[3]);
			// --- steps at its foot
			for (y = 72; y < 78; y++) for (x = 3 + (y - 72); x < 61 - (y - 72); x++) bd.setPixel32(x, y, y == 72 ? stoneHi : (x % 8 == 0 ? stoneLo : stone));
			outline(bd);
			var big:BitmapData = new BitmapData(W * SCALE, H * SCALE, true, 0);
			var m:Matrix = new Matrix();
			m.scale(SCALE, SCALE);
			big.draw(bd, m);
			bd.dispose();
			cache[key] = big;
			return big;
		}

		/** A rune circle on the ground, turning (drawn additively under the gate). */
		public static function circle(col:uint, f:int):BitmapData {
			f = ((f % FRAMES) + FRAMES) % FRAMES;
			var key:String = "c" + col + "_" + f;
			if (cache[key]) return cache[key];
			var w:int = 220, h:int = 76;
			var bd:BitmapData = new BitmapData(w, h, true, 0);
			var cx:Number = w / 2, cy:Number = h / 2;
			var ph:Number = f / FRAMES * Math.PI * 2 / 6;
			var lit:uint = tint(col, 0.5);
			for (var y:int = 0; y < h; y++) for (var x:int = 0; x < w; x++) {
				var dx:Number = (x - cx) / (w / 2 - 2), dy:Number = (y - cy) / (h / 2 - 2);
				var d:Number = Math.sqrt(dx * dx + dy * dy);
				var a:Number = Math.atan2(dy, dx);
				var al:int = 0, c:uint = col;
				if (d > 0.94 && d < 1) al = 200;
				else if (d > 0.7 && d < 0.74) al = 150;
				else if (d >= 0.74 && d <= 0.94) {
					// glyphs between the rings, turning
					var g:Number = (a + ph) * 12 / Math.PI;
					var cell:Number = g - Math.floor(g);
					if (cell < 0.35 && Math.abs(d - 0.84) < 0.06) { al = 230; c = lit; }
				} else if (d < 0.7) {
					// a star drawn inside
					var st:Number = Math.abs(Math.cos(2.5 * (a - ph * 2)));
					if (Math.abs(d - (0.25 + 0.42 * st)) < 0.025) al = 120;
					else al = int(40 * (1 - d));
				}
				if (al) bd.setPixel32(x, y, (uint(al) << 24) | c);
			}
			cache[key] = bd;
			return bd;
		}

		/** A beam of light from the vortex into the sky. */
		public static function beam(col:uint):BitmapData {
			var key:String = "b" + col;
			if (cache[key]) return cache[key];
			var w:int = 44, h:int = 340;
			var bd:BitmapData = new BitmapData(w, h, true, 0);
			for (var y:int = 0; y < h; y++) {
				var f:Number = y / h;
				for (var x:int = 0; x < w; x++) {
					var e:Number = Math.abs(x - w / 2) / (w / 2);
					var a:Number = Math.pow(1 - e, 2.2) * (0.1 + 0.9 * f);
					if (a > 0.01) bd.setPixel32(x, y, (uint(a * 255) << 24) | (e < 0.25 ? tint(col, 0.7) : col));
				}
			}
			cache[key] = bd;
			return bd;
		}

		/** A dark 1px outline round everything drawn (like the game's other sprites). */
		private static function outline(bd:BitmapData):void {
			var src:BitmapData = bd.clone();
			for (var y:int = 0; y < bd.height; y++) for (var x:int = 0; x < bd.width; x++) {
				if ((src.getPixel32(x, y) >>> 24) > 0) continue;
				if (((x > 0 ? src.getPixel32(x - 1, y) : 0) >>> 24) || ((x < bd.width - 1 ? src.getPixel32(x + 1, y) : 0) >>> 24) ||
					((y > 0 ? src.getPixel32(x, y - 1) : 0) >>> 24) || ((y < bd.height - 1 ? src.getPixel32(x, y + 1) : 0) >>> 24)) bd.setPixel32(x, y, 0xff07050c);
			}
			src.dispose();
		}
	}
}
