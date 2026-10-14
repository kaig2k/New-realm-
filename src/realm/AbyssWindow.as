package realm {
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;

	/**
	 * The Endless Abyss (/abyss, or its portal in the Nexus): your run, your best
	 * this week, and the week's deepest heroes of each class (the server's board).
	 */
	public class AbyssWindow extends Sprite {
		public static const W:int = 600, H:int = 550;
		private var g:Game;
		private var data:Object;
		private var cls:String;
		private var body:Sprite = new Sprite();

		public function AbyssWindow(g:Game, cls:String) {
			this.g = g;
			this.cls = cls;
			var m:Matrix = new Matrix();
			m.createGradientBox(W, H, Math.PI / 2);
			graphics.lineStyle(2, 0xa060ff);
			graphics.beginGradientFill(GradientType.LINEAR, [0x1e1030, 0x08040e], [0.97, 0.97], [0, 255], m);
			graphics.drawRoundRect(0, 0, W, H, 18, 18);
			graphics.endFill();
			var t:TextField = Ui.text(26, 0xd080ff, true, "center", W, true);
			t.text = "The Endless Abyss";
			t.y = 10;
			t.filters = [new GlowFilter(0x8030ff, 0.9, 14, 14, 2)];
			addChild(t);
			var close:Sprite = Ui.button("X", 32, 28, function():void { g.toggleAbyss(); }, 14);
			close.x = W - 46; close.y = 12;
			addChild(close);
			addChild(body);
			request();
		}

		private function request():void { Online.send({t: "deepBoard", cls: cls}); }

		public function setData(d:Object):void {
			data = d;
			refresh();
		}

		public function refresh():void {
			body.removeChildren();
			var intro:TextField = Ui.text(12, 0xc8b8e0, false, "left", W - 40, true);
			intro.htmlText = "Wave after wave in the Abyss's arena, each tougher than the last. Its monsters drop <b>nothing</b>: every " + Data.DEEP_CHEST_EVERY +
				" waves a chest appears instead, and a boss with it (the <font color='#d080ff'>Abyssal Herald</font> every " + Data.DEEP_HERALD + "th), and you pick a boon for the run. Level 20 heroes only; the board resets every Monday.";
			intro.x = 20; intro.y = 50;
			body.addChild(intro);
			var run:Object = g.abyssRunInfo;
			var rt:TextField = Ui.text(14, 0xffffff, true, "left", W - 200, true);
			if (run) {
				var bn:Array = [];
				for each (var id:String in run.boons || []) { var b:Object = Data.findBoon(id); if (b) bn.push("<font color='" + Ui.hex(b.col) + "'>" + b.name + "</font>"); }
				rt.htmlText = "Your run: wave <font color='#d080ff'>" + run.wave + "</font> cleared<br><font size='12'>" + (bn.length ? bn.join(", ") : "no boons yet") + "</font>";
			} else rt.htmlText = "Not in a run." + (data && data.best ? "  <font color='#c8b8e0'>Your best this week: wave " + data.best + "</font>" : "");
			rt.x = 20; rt.y = 104;
			body.addChild(rt);
			if (!run) {
				var go:Sprite = Ui.button("Enter the Abyss", 160, 34, function():void { g.toggleAbyss(); g.enterDeep(0); }, 14);
				go.x = W - 180; go.y = 104;
				go.alpha = g.player.level >= 20 ? 1 : 0.5;
				body.addChild(go);
			}
			// the board: a tab per class
			var tabs:Array = [];
			for (var cid:String in Data.CLASSES) tabs.push(cid);
			tabs.sort();
			var tx:int = 20, ty:int = 156;
			for each (var c:String in tabs) {
				var tb:Sprite = Ui.button(Data.CLASSES[c].name, 70, 22, tabFn(c), 10);
				tb.x = tx; tb.y = ty;
				tb.alpha = c == cls ? 1 : 0.55;
				body.addChild(tb);
				tx += 74;
				if (tx > W - 90) { tx = 20; ty += 26; }
			}
			var lt:TextField = Ui.text(13, 0xe8dcf8, false, "left", W - 40, true);
			var rows:Array = data && data.cls == cls ? data.list || [] : [];
			var out:String = "<font size='15' color='#d080ff'><b>Best " + Data.CLASSES[cls].name + "s this week</b></font><br>";
			if (!rows.length) out += "<font color='#a898c0'>Nobody yet. Be the first!</font>";
			for (var i:int = 0; i < rows.length; i++) {
				var r:Object = rows[i];
				var col:String = i == 0 ? "#ffd75e" : i == 1 ? "#e0e0f0" : i == 2 ? "#e0a060" : "#c8b8e0";
				out += "<font color='" + col + "'>" + (i + 1) + ".  <b>" + Ui.esc(r.name) + "</b>  " + Ui.esc(r.hero) + "  ·  wave " + r.wave + "</font><br>";
			}
			lt.htmlText = out;
			lt.width = 300;
			lt.x = 20; lt.y = ty + 36;
			body.addChild(lt);
			var ct:TextField = Ui.text(11, 0xc8b8e0, false, "left", 250, true);
			var cs:String = "<font size='14' color='#d080ff'><b>The chests</b></font><br>";
			for (var ci:int = 1; ci < Data.DEEP_CHEST_INFO.length; ci++) cs += "<font color='#e0c0ff'>" + Data.DEEP_CHEST_NAMES[ci] + "</font><br>" + Data.DEEP_CHEST_INFO[ci] + "<br>";
			ct.htmlText = cs;
			ct.x = W - 270; ct.y = ty + 36;
			body.addChild(ct);
		}

		private function tabFn(c:String):Function {
			return function():void { cls = c; refresh(); request(); };
		}
	}
}
