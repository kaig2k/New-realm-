package realm {
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;

	/**
	 * The Realm Siege's panel at the top of the screen (the server's "siege"
	 * messages): the Warlord's health, the time left, the top three damage
	 * dealers and your own share. Then the result, for a few seconds.
	 */
	public class SiegePanel extends Sprite {
		public static const W:int = 270, H:int = 52;
		private var title:TextField, timeTf:TextField, board:TextField, meTf:TextField;
		private var bar:Shape = new Shape();
		/** Seconds since the last word from the server (the panel goes once it's stale). */
		public var quiet:Number = 0;
		/** Which world boss this is (its name): the Warlord's Realm Siege, or the Pumpkin King. */
		private var wb:String = "";
		/** Showing the result: seconds left. */
		public var endT:Number = 0;
		public var bossId:int = 0;
		/** A siege is on (false: showing how it ended). */
		public var active:Boolean = false;

		public function SiegePanel() {
			mouseEnabled = mouseChildren = false;
			var m:Matrix = new Matrix();
			m.createGradientBox(W, H, Math.PI / 2);
			graphics.lineStyle(2, 0xffa020, 0.9);
			graphics.beginGradientFill(GradientType.LINEAR, [0x2a1408, 0x120804], [0.92, 0.92], [0, 255], m);
			graphics.drawRoundRect(0, 0, W, H, 10, 10);
			graphics.endFill();
			// (one small strip: name and clock, the bar, then the top three with your own share)
			title = Ui.text(12, 0xffa020, true, "left", W - 60, true);
			title.x = 8; title.y = 1;
			title.filters = [new GlowFilter(0xff4010, 0.6, 6, 6, 2)];
			addChild(title);
			timeTf = Ui.text(12, 0xffffff, true, "right", 50, true);
			timeTf.x = W - 58; timeTf.y = 1;
			addChild(timeTf);
			bar.x = 8; bar.y = 20;
			addChild(bar);
			board = Ui.text(10, 0xe8d8c0, false, "left", W - 16, true);
			board.x = 8; board.y = 30;
			addChild(board);
			meTf = Ui.text(10, 0xffd75e, true, "right", W - 16, true);
			meTf.x = 8; meTf.y = 30;
			meTf.visible = false;
			addChild(meTf);
		}

		public function update(m:Object):void {
			quiet = 0;
			if (m.on) {
				endT = 0;
				active = true;
				bossId = int(m.id);
				title.text = (m.title || "REALM SIEGE") + " · " + m.name;
				wb = String(m.name);
				var left:int = int(m.left);
				timeTf.text = int(left / 60) + ":" + (left % 60 < 10 ? "0" : "") + (left % 60);
				timeTf.textColor = left < 120 ? 0xff6060 : 0xffffff;
				var f:Number = Math.max(0, Math.min(1, Number(m.hp) / Math.max(1, Number(m.max))));
				bar.graphics.clear();
				bar.graphics.beginFill(0x000000, 0.6);
				bar.graphics.drawRoundRect(0, 0, W - 16, 7, 4, 4);
				var bm:Matrix = new Matrix();
				bm.createGradientBox(W - 16, 7, 0);
				bar.graphics.beginGradientFill(GradientType.LINEAR, [0xff3010, 0xffa020], [1, 1], [0, 255], bm);
				bar.graphics.drawRoundRect(0, 0, (W - 16) * f, 7, 4, 4);
				bar.graphics.endFill();
				board.htmlText = (m.rank > 0 ? "<font color='#ffd75e'><b>You " + m.me + "% (#" + m.rank + ")</b></font>   " : "<font color='#ffd75e'>Hit him for loot</font>   ") +
					topLine(m.top as Array, 2) + (m.n ? "  <font color='#a89878'>· " + m.n + " fighting</font>" : "");
			} else {
				endT = 7;
				active = false;
				bossId = 0;
				bar.graphics.clear();
				timeTf.text = "";
				if (m.won) {
					title.text = m.wonText || "THE SIEGE IS BROKEN!";
					board.htmlText = (m.mvp ? "<font color='#ffd75e'><b>MVP: " + Ui.esc(m.mvp) + "</b></font>   " : "") + topLine(m.top as Array, 3);
				} else {
					title.text = (wb && wb.indexOf("Vorgath") < 0 ? wb : "The Warlord") + " withdraws...";
					board.htmlText = "<font color='#a89878'>Not beaten in time. He'll be back.</font>";
				}
			}
		}

		private static function topLine(top:Array, most:int):String {
			if (!top || !top.length) return "<font color='#a89878'>Nobody has hurt him yet.</font>";
			var cols:Array = ["#ffd75e", "#e0e0f0", "#e0a060"], out:Array = [];
			for (var i:int = 0; i < Math.min(most, top.length); i++) out.push("<font color='" + cols[i] + "'>" + (i + 1) + ". " + Ui.esc(top[i][0]) + " " + top[i][1] + "%</font>");
			return out.join("  ");
		}
	}
}
