package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;

	/**
	 * The hero screens' backdrop: a deep violet dusk with a soft light behind the window,
	 * a faint pixel grid, and embers drifting up (gold and violet, square like the game's pixels).
	 */
	public class MenuBackdrop extends Sprite {
		private static const N:int = 110;
		private var motes:Vector.<Object> = new Vector.<Object>();
		private var layer:Shape = new Shape();
		private var t:Number = 0;

		public function MenuBackdrop() {
			var W:int = Ui.W, H:int = Ui.H;
			var m:Matrix = new Matrix();
			// dusk: dark at the top and bottom, a little warmer in the middle
			var bg:Shape = new Shape();
			m.createGradientBox(W, H, Math.PI / 2);
			bg.graphics.beginGradientFill(GradientType.LINEAR, [0x0b0912, 0x171022, 0x120c1a, 0x07060a], [1, 1, 1, 1], [0, 110, 190, 255], m);
			bg.graphics.drawRect(0, 0, W, H);
			bg.graphics.endFill();
			addChild(bg);
			// the light behind the window
			var glow:Shape = new Shape();
			m.createGradientBox(W * 1.1, H * 1.1, 0, -W * 0.05, -H * 0.02);
			glow.graphics.beginGradientFill(GradientType.RADIAL, [0x5a3480, 0x2e1a48, 0x2a1840], [0.75, 0.3, 0], [0, 140, 255], m);
			glow.graphics.drawRect(0, 0, W, H);
			glow.graphics.endFill();
			addChild(glow);
			// a faint pixel grid (the world's tiles, just a whisper of them)
			var grid:BitmapData = new BitmapData(W, H, true, 0);
			for (var y:int = 0; y < H; y += 8) for (var x:int = 0; x < W; x += 8) {
				var n:Number = Math.random();
				if (n < 0.55) continue;
				grid.setPixel32(x, y, (int(n * 10 + 4) << 24) | 0xb090ff);
			}
			addChild(new Bitmap(grid));
			addChild(layer);
			// a vignette to finish
			var vig:Shape = new Shape();
			m.createGradientBox(W * 1.3, H * 1.5, 0, -W * 0.15, -H * 0.25);
			vig.graphics.beginGradientFill(GradientType.RADIAL, [0, 0, 0], [0, 0.25, 0.75], [0, 170, 255], m);
			vig.graphics.drawRect(0, 0, W, H);
			vig.graphics.endFill();
			addChild(vig);
			for (var i:int = 0; i < N; i++) motes.push(spawn(Math.random() * H));
			addEventListener(Event.ENTER_FRAME, tick);
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void { removeEventListener(Event.ENTER_FRAME, tick); });
			draw();
		}

		private function spawn(y:Number):Object {
			var gold:Boolean = Math.random() < 0.45;
			return {x: Math.random() * Ui.W, y: y, vy: 6 + Math.random() * 16, sway: Math.random() * Math.PI * 2, s: Math.random() < 0.2 ? 3 : 2,
				col: gold ? (Math.random() < 0.5 ? 0xffd75e : 0xff9a2e) : (Math.random() < 0.5 ? 0xc070ff : 0x8a6aff), a: 0.4 + Math.random() * 0.6, tw: Math.random() * 6};
		}

		private function tick(e:Event):void {
			var dt:Number = Ui.FRAME;
			t += dt;
			for (var i:int = 0; i < motes.length; i++) {
				var p:Object = motes[i];
				p.y -= p.vy * dt;
				p.x += Math.sin(t * 0.6 + p.sway) * 6 * dt;
				if (p.y < -6) motes[i] = spawn(Ui.H + 4);
			}
			draw();
		}

		private function draw():void {
			var g:* = layer.graphics;
			g.clear();
			for each (var p:Object in motes) {
				// fade in at the bottom, out near the top, and twinkle a little
				var f:Number = Math.min(1, (Ui.H - p.y) / 120) * Math.min(1, p.y / 160);
				var a:Number = p.a * f * (0.75 + 0.25 * Math.sin(t * 2 + p.tw));
				if (a <= 0.01) continue;
				g.beginFill(p.col, a * 0.3);
				g.drawRect(int(p.x) - p.s, int(p.y) - p.s, p.s * 3, p.s * 3);
				g.endFill();
				g.beginFill(p.col, a);
				g.drawRect(int(p.x), int(p.y), p.s, p.s);
				g.endFill();
			}
		}
	}
}
