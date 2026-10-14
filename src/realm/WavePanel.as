package realm {
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;

	/**
	 * The Endless Abyss's panel at the top of the screen (the server's "deepWave"
	 * messages): the wave, how many monsters are left or the countdown to the
	 * next wave, and the chest the last boss wave left.
	 */
	public class WavePanel extends Sprite {
		public static const W:int = 300, H:int = 66;
		private var title:TextField, line:TextField, sub:TextField;
		private var wave:int = 0, state:String = "break", left:int = 0, chest:String = "", boss:String = "";
		private var t:Number = 0;

		public function WavePanel() {
			mouseEnabled = mouseChildren = false;
			var m:Matrix = new Matrix();
			m.createGradientBox(W, H, Math.PI / 2);
			graphics.lineStyle(2, 0xa060ff, 0.9);
			graphics.beginGradientFill(GradientType.LINEAR, [0x1e1030, 0x0a0614], [0.92, 0.92], [0, 255], m);
			graphics.drawRoundRect(0, 0, W, H, 12, 12);
			graphics.endFill();
			title = Ui.text(15, 0xd080ff, true, "center", W, true);
			title.y = 4;
			title.filters = [new GlowFilter(0x8030ff, 0.8, 8, 8, 2)];
			addChild(title);
			line = Ui.text(13, 0xffffff, true, "center", W, true);
			line.y = 25;
			addChild(line);
			sub = Ui.text(11, 0xc8b8e0, false, "center", W, true);
			sub.y = 45;
			addChild(sub);
			draw();
		}

		public function update(m:Object):void {
			wave = int(m.wave);
			state = String(m.state || "break");
			left = int(m.left);
			t = Number(m.secs) || 0;
			if (m.boss != undefined) boss = String(m.boss || "");
			if (state == "cleared") chest = String(m.chest || "");
			else if (state == "fight") chest = "";
			draw();
		}

		/** Once a frame: the countdown between waves. */
		public function tick(dt:Number):void {
			if (state == "fight" || t <= 0) return;
			var was:int = Math.ceil(t);
			t = Math.max(0, t - dt);
			if (Math.ceil(t) != was) draw();
		}

		private function draw():void {
			title.text = "THE ENDLESS ABYSS · Wave " + Math.max(1, state == "fight" ? wave : wave + 1);
			if (state == "fight") {
				line.text = (boss ? boss + "  +  " : "") + left + " monster" + (left == 1 ? "" : "s") + " left";
				sub.text = "Monsters here drop nothing. Every 5 waves: a chest.";
			} else {
				line.text = wave == 0 ? "The first wave comes in " + Math.ceil(t) + "s" : "Wave " + wave + " cleared!  Next in " + Math.ceil(t) + "s";
				sub.text = chest ? chest + " in the middle of the arena: open it!" : "Next chest after wave " + (int(wave / Data.DEEP_CHEST_EVERY) + 1) * Data.DEEP_CHEST_EVERY;
			}
		}
	}
}
