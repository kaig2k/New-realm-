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
		public static const W:int = 380, H:int = 84;
		private var title:TextField, line:TextField, sub:TextField;
		private var modRow:Sprite = new Sprite();
		private var wave:int = 0, state:String = "break", left:int = 0, chest:String = "", boss:String = "";
		private var mods:Array = [], restless:Boolean = false;
		private var t:Number = 0;

		public function WavePanel() {
			mouseEnabled = mouseChildren = false;
			var m:Matrix = new Matrix();
			m.createGradientBox(W, H, Math.PI / 2);
			graphics.lineStyle(2, 0xa060ff, 0.9);
			graphics.beginGradientFill(GradientType.LINEAR, [0x1e1030, 0x0a0614], [1, 1], [0, 255], m);
			graphics.drawRoundRect(0, 0, W, H, 12, 12);
			graphics.endFill();
			title = Ui.text(15, 0xd080ff, true, "center", W, true);
			title.y = 4;
			title.filters = [new GlowFilter(0x8030ff, 0.8, 8, 8, 2)];
			addChild(title);
			line = Ui.text(12, 0xffffff, true, "center", W, true);
			line.y = 25;
			addChild(line);
			modRow.y = 44;
			addChild(modRow);
			sub = Ui.text(11, 0xc8b8e0, false, "center", W, true);
			sub.y = 63;
			addChild(sub);
			draw();
		}

		public function update(m:Object):void {
			wave = int(m.wave);
			state = String(m.state || "break");
			left = int(m.left);
			t = Number(m.secs) || 0;
			if (m.boss != undefined) boss = String(m.boss || "");
			if (m.mods is Array) mods = m.mods as Array;
			if (state == "restless") { restless = true; state = "fight"; }
			if (state == "cleared") { chest = String(m.chest || ""); restless = false; }
			else if (state == "fight" && m.mods is Array) { chest = ""; restless = false; }
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
			// the modifiers: a name each, in its colour, side by side
			modRow.removeChildren();
			if (state == "fight") {
				var mx:Number = 0;
				for each (var id:String in mods) {
					var md:Object = Data.findDeepMod(id);
					if (!md) continue;
					var mt:TextField = Ui.text(12, md.col, true, "left", 0, false);
					mt.text = md.name;
					mt.x = mx;
					modRow.addChild(mt);
					mx += mt.textWidth + 18;
				}
				modRow.x = int((W - Math.max(0, mx - 18)) / 2);
			}
			if (state == "fight") {
				line.text = boss ? boss + "  (" + left + " left)" : left + " monster" + (left == 1 ? "" : "s") + " left";
				sub.htmlText = restless ? "<font color='#ff5060'><b>The Abyss grows restless: elites are coming!</b></font>" : "Clear it within " + Data.DEEP_RESTLESS + "s or the Abyss sends elites.";
			} else {
				line.text = wave == 0 ? "The first wave comes in " + Math.ceil(t) + "s" : "Wave " + wave + " cleared!  Next in " + Math.ceil(t) + "s";
				sub.text = chest ? chest + " in the middle of the arena: open it!" : "A chest after every wave (a big one after wave " + (int(wave / Data.DEEP_CHEST_EVERY) + 1) * Data.DEEP_CHEST_EVERY + ")";
			}
		}
	}
}
