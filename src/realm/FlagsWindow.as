package realm {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	/**
	 * Admins: everyone the anti-cheat flagged (/flags), most recent first. The
	 * anti-cheat never disconnects anyone itself: this is where an admin looks
	 * and decides (Whois, Kick, Ban, or Clear for someone who checked out fine).
	 */
	public class FlagsWindow extends Sprite {
		public static const W:int = 620, H:int = 480;
		private static const ROW:int = 104, TOP:int = 70;

		private var g:Game;
		private var list:Array;
		private var rows:Sprite = new Sprite();
		private var scroll:int = 0;

		public function FlagsWindow(g:Game, list:Array) {
			this.g = g;
			this.list = list || [];
			Ui.panel(graphics, 0, 0, W, H, 0x18181e, 0xffb040, 0.97);
			var title:TextField = Ui.text(20, 0xffb040, true, "left", 400, true);
			title.text = "Flagged players (" + this.list.length + ")";
			title.x = 14; title.y = 8;
			addChild(title);
			var hint:TextField = Ui.text(11, 0x999999, false, "left", W - 28, true);
			hint.text = "Nobody is disconnected automatically. Check them out, then Kick or Ban, or Clear if they're honest. Scroll for more.";
			hint.x = 14; hint.y = 38;
			addChild(hint);
			var refresh:Sprite = Ui.button("Refresh", 90, 26, function():void { g.net.serverCommand("/flags"); }, 13);
			refresh.x = W - 140; refresh.y = 8;
			addChild(refresh);
			var close:Sprite = Ui.button("X", 30, 26, function():void { g.closeFlags(); }, 14);
			close.x = W - 40; close.y = 8;
			addChild(close);
			var mask:Shape = new Shape();
			mask.graphics.beginFill(0);
			mask.graphics.drawRect(0, TOP, W, H - TOP - 8);
			mask.graphics.endFill();
			addChild(mask);
			rows.mask = mask;
			rows.y = TOP;
			addChild(rows);
			var n:int = this.list.length;
			addEventListener(MouseEvent.MOUSE_WHEEL, function(e:MouseEvent):void {
				var most:int = Math.max(0, n * ROW - (H - TOP - 8));
				scroll = Math.max(0, Math.min(most, scroll - e.delta * 20));
				rows.y = TOP - scroll;
				e.stopPropagation();
			});
			draw();
		}

		private static function ago(t:Number):String {
			var s:int = Math.max(0, ((new Date()).time - t) / 1000);
			return s < 60 ? s + "s ago" : s < 3600 ? int(s / 60) + "m ago" : s < 86400 ? int(s / 3600) + "h ago" : int(s / 86400) + "d ago";
		}

		private static function esc(s:String):String { return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;"); }

		private function draw():void {
			rows.removeChildren();
			if (!list.length) {
				var none:TextField = Ui.text(15, 0x80ff80, true, "left", W - 28, true);
				none.text = "Nobody is flagged.";
				none.x = 14; none.y = 10;
				rows.addChild(none);
				return;
			}
			for (var i:int = 0; i < list.length; i++) {
				var f:Object = list[i];
				var r:Sprite = new Sprite();
				r.y = i * ROW;
				Ui.panel(r.graphics, 10, 2, W - 20, ROW - 6, 0x22222a, 0x4a4a56);
				var kinds:Array = [];
				for (var k:String in f.kinds) kinds.push(esc(k) + " x" + f.kinds[k]);
				var head:TextField = Ui.text(14, 0xffffff, true, "left", 330, true);
				head.htmlText = esc(f.name) + (f.no ? " <font color='#b9a9d4'>#" + int(f.no) + "</font>" : "") +
					(f.online ? " <font color='#80ff80' size='11'>online</font>" : " <font color='#888888' size='11'>offline</font>") +
					"  <font color='#ffb040' size='12'>" + int(f.n) + " flags, last " + ago(f.last) + "</font>";
				head.x = 18; head.y = 6;
				r.addChild(head);
				var why:TextField = Ui.text(11, 0xffd080, false, "left", W - 50, true);
				why.htmlText = kinds.join(", ");
				why.x = 18; why.y = 26;
				r.addChild(why);
				var notes:Array = [];
				for (var j:int = 0; j < Math.min(3, (f.notes || []).length); j++) {
					var n:Object = f.notes[j];
					notes.push("<font color='#888888'>" + ago(n.at) + (n.world ? " in " + esc(n.world) : "") + ":</font> " + esc(n.note));
				}
				var nt:TextField = Ui.text(11, 0xcccccc, false, "left", W - 50, true);
				nt.htmlText = notes.join("<br>");
				nt.x = 18; nt.y = 42;
				r.addChild(nt);
				var bx:int = W - 18;
				for each (var b:Array in [["Clear", "/flags clear "], ["Ban", "/ban "], ["Kick", "/kick "], ["Whois", "/whois "]]) {
					if (b[0] == "Kick" && !f.online) continue;
					var btn:Sprite = Ui.button(b[0], 58, 22, cmdFn(b[1] + f.name, b[0] == "Ban"), 12);
					bx -= 62;
					btn.x = bx; btn.y = 6;
					r.addChild(btn);
				}
				rows.addChild(r);
			}
		}

		private function cmdFn(cmd:String, ask:Boolean):Function {
			return function():void {
				// a ban goes into the chat box to finish (and add a reason) rather than at one click
				if (ask) { g.closeFlags(); g.chatWith(cmd + " "); return; }
				g.net.serverCommand(cmd);
			};
		}
	}
}
