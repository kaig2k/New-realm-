package realm {
	import flash.display.Sprite;
	import flash.text.TextField;

	/**
	 * Admins: the bug reports players sent with /bug (/bugs), newest first, with who
	 * sent it, where they were and what they had. Done marks one fixed (it greys
	 * out); Clear fixed forgets those.
	 */
	public class BugsWindow extends Sprite {
		public static const W:int = 660, H:int = 520;
		private var g:Game;
		private var list:Array;
		private var showDone:Boolean = false;
		private var area:ScrollArea;

		public function BugsWindow(g:Game, list:Array) {
			this.g = g;
			this.list = list || [];
			draw();
		}

		private static function ago(t:Number):String {
			var s:int = Math.max(0, ((new Date()).time - t) / 1000);
			return s < 60 ? s + "s ago" : s < 3600 ? int(s / 60) + "m ago" : s < 86400 ? int(s / 3600) + "h ago" : int(s / 86400) + "d ago";
		}

		private static function esc(s:String):String { return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;"); }

		private function draw():void {
			removeChildren();
			graphics.clear();
			Ui.panel(graphics, 0, 0, W, H, 0x1a1a20, 0xffa040, 0.97);
			var open:int = 0;
			for each (var b:Object in list) if (!b.done) open++;
			var title:TextField = Ui.text(20, 0xffa040, true, "left", 360, true);
			title.text = "Bug reports (" + open + " open)";
			title.x = 14; title.y = 8;
			addChild(title);
			var hint:TextField = Ui.text(11, 0x999999, false, "left", W - 28, true);
			hint.text = "Players send these with /bug. They also go to the Discord feed and server/data/bugs.log.";
			hint.x = 14; hint.y = 38;
			addChild(hint);
			var tog:Sprite = Ui.button(showDone ? "Hide fixed" : "Show fixed", 96, 26, function():void { showDone = !showDone; draw(); }, 12);
			tog.x = W - 296; tog.y = 8;
			addChild(tog);
			var clr:Sprite = Ui.button("Clear fixed", 96, 26, function():void { g.net.serverCommand("/bugs clear"); }, 12);
			clr.x = W - 196; clr.y = 8;
			addChild(clr);
			var rf:Sprite = Ui.button("Refresh", 56, 26, function():void { g.net.serverCommand("/bugs"); }, 12);
			rf.x = W - 96; rf.y = 8;
			addChild(rf);
			var close:Sprite = Ui.button("X", 30, 26, function():void { g.closeBugs(); }, 14);
			close.x = W - 36; close.y = 8;
			addChild(close);
			area = new ScrollArea(W - 20, H - 70);
			area.x = 10; area.y = 60;
			addChild(area);
			var y:int = 0;
			for each (b in list) {
				if (b.done && !showDone) continue;
				var r:Sprite = new Sprite();
				var tf:TextField = Ui.text(13, b.done ? 0x777777 : 0xffffff, false, "left", W - 150, true);
				tf.htmlText = "<b><font color='" + (b.done ? "#777777" : "#ffa040") + "'>#" + b.id + "</font> " + esc(b.name) + (b.no ? " <font color='#b9a9d4'>#" + b.no + "</font>" : "") + "</b>" +
					"  <font size='11' color='#888888'>" + ago(b.at) + (b.done ? "  ·  fixed" + (b.by ? " (" + esc(b.by) + ")" : "") : "") + "</font><br>" +
					esc(b.text) + "<br><font size='11' color='#8a9ab0'>" + esc(b.hero) + (b.pet ? " · " + esc(b.pet) : "") + " · " + esc(b.world || "menu") + (b.world ? " (" + b.x + ", " + b.y + ")" : "") +
					(b.game ? " · game " + esc(b.game) : "") + (b.fps ? " · " + b.fps + " fps" : "") + (b.ping ? " · " + b.ping + " ms" : "") + "</font>";
				tf.x = 8; tf.y = 6;
				r.addChild(tf);
				var h:int = Math.max(48, tf.height + 12);
				Ui.panel(r.graphics, 0, 0, W - 34, h, b.done ? 0x1e1e22 : 0x24242c, b.done ? 0x3a3a40 : 0x5a4a3a, 1);
				var db:Sprite = Ui.button(b.done ? "Reopen" : "Done", 62, 22, cmdFn((b.done ? "/bugs open " : "/bugs done ") + b.id), 11);
				db.x = W - 106; db.y = 6;
				r.addChild(db);
				var wb:Sprite = Ui.button("Whois", 62, 22, cmdFn("/whois " + b.name), 11);
				wb.x = W - 106; wb.y = 32;
				r.addChild(wb);
				r.y = y;
				area.content.addChild(r);
				y += h + 6;
			}
			if (!y) {
				var none:TextField = Ui.text(14, 0x80ff80, true, "center", W - 40, true);
				none.text = "No open bug reports.";
				none.y = 20;
				area.content.addChild(none);
			}
			area.update(0);
		}

		private function cmdFn(cmd:String):Function { return function():void { g.net.serverCommand(cmd); }; }
	}
}
