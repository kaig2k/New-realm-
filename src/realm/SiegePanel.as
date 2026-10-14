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
		public static const W:int = 356, H:int = 92;
		private var title:TextField, timeTf:TextField, board:TextField, meTf:TextField;
		private var bar:Shape = new Shape();
		/** Seconds since the last word from the server (the panel goes once it's stale). */
		public var quiet:Number = 0;
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
			graphics.drawRoundRect(0, 0, W, H, 12, 12);
			graphics.endFill();
			title = Ui.text(14, 0xffa020, true, "left", W - 80, true);
			title.x = 10; title.y = 4;
			title.filters = [new GlowFilter(0xff4010, 0.7, 8, 8, 2)];
			addChild(title);
			timeTf = Ui.text(15, 0xffffff, true, "right", 64, true);
			timeTf.x = W - 74; timeTf.y = 4;
			addChild(timeTf);
			bar.x = 10; bar.y = 28;
			addChild(bar);
			board = Ui.text(11, 0xe8d8c0, false, "left", W - 20, true);
			board.x = 10; board.y = 44;
			addChild(board);
			meTf = Ui.text(12, 0xffd75e, true, "left", W - 20, true);
			meTf.x = 10; meTf.y = 68;
			addChild(meTf);
		}

		public function update(m:Object):void {
			quiet = 0;
			if (m.on) {
				endT = 0;
				active = true;
				bossId = int(m.id);
				title.text = "REALM SIEGE · " + m.name;
				var left:int = int(m.left);
				timeTf.text = int(left / 60) + ":" + (left % 60 < 10 ? "0" : "") + (left % 60);
				timeTf.textColor = left < 120 ? 0xff6060 : 0xffffff;
				var f:Number = Math.max(0, Math.min(1, Number(m.hp) / Math.max(1, Number(m.max))));
				bar.graphics.clear();
				bar.graphics.beginFill(0x000000, 0.6);
				bar.graphics.drawRoundRect(0, 0, W - 20, 12, 6, 6);
				var bm:Matrix = new Matrix();
				bm.createGradientBox(W - 20, 12, 0);
				bar.graphics.beginGradientFill(GradientType.LINEAR, [0xff3010, 0xffa020], [1, 1], [0, 255], bm);
				bar.graphics.drawRoundRect(0, 0, (W - 20) * f, 12, 6, 6);
				bar.graphics.endFill();
				board.htmlText = topLine(m.top as Array) + (m.n ? "   <font color='#a89878'>" + m.n + " fighting</font>" : "");
				meTf.text = m.rank > 0 ? "You: " + m.me + "% of the damage (#" + m.rank + ")" : "Hit the Warlord to share in the loot  (/glands to get there)";
			} else {
				endT = 7;
				active = false;
				bossId = 0;
				bar.graphics.clear();
				timeTf.text = "";
				if (m.won) {
					title.text = "THE SIEGE IS BROKEN!";
					board.htmlText = topLine(m.top as Array);
					meTf.text = m.mvp ? "MVP: " + m.mvp : "";
				} else {
					title.text = "The Warlord withdraws...";
					board.htmlText = "<font color='#a89878'>Not beaten in time. He'll be back.</font>";
					meTf.text = "";
				}
			}
		}

		private static function topLine(top:Array):String {
			if (!top || !top.length) return "<font color='#a89878'>Nobody has hurt him yet.</font>";
			var cols:Array = ["#ffd75e", "#e0e0f0", "#e0a060"], out:Array = [];
			for (var i:int = 0; i < top.length; i++) out.push("<font color='" + cols[i] + "'>" + (i + 1) + ". " + Ui.esc(top[i][0]) + " " + top[i][1] + "%</font>");
			return out.join("   ");
		}
	}
}
