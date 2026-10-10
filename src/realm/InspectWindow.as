package realm {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;

	/** Another player's character: class, level, fame, maxed stats and equipment. */
	public class InspectWindow extends Sprite {
		public static const W:int = 300;
		private var tip:Tooltip = new Tooltip();

		public function InspectWindow(g:Game, p:RemotePlayer, profile:Object) {
			var cls:Object = Data.CLASSES[profile.cls];
			var h:int = 262;
			Ui.panel(graphics, 0, 0, W, h, 0x1e1e24, 0x6a6a7a, 0.97);
			var pic:Bitmap = new Bitmap(Sprites.get(p.spriteId));
			pic.scaleX = pic.scaleY = 1.25;
			pic.x = 14; pic.y = 10;
			addChild(pic);
			var name:TextField = Ui.text(22, 0xffffff, true, "left", 200, true);
			name.htmlText = p.name.replace(/</g, "&lt;") + (profile.no ? " <font size='14' color='#b9a9d4'>#" + int(profile.no) + "</font>" : "");
			name.x = 84; name.y = 12;
			addChild(name);
			var info:TextField = Ui.text(13, 0xcccccc, true, "left", 210, true);
			info.htmlText = "Level " + profile.level + " " + cls.name +
				"\n<font color='#ff9a2e'>" + Ui.commas(profile.fame) + " fame</font>   " +
				"<font color='" + (profile.maxed >= 11 ? "#ffd75e" : "#cccccc") + "'>" + profile.maxed + "/11 maxed</font>";
			info.x = 84; info.y = 42;
			addChild(info);

			var eqTf:TextField = Ui.text(13, 0x9a9aaa, true, "left", 200, true);
			eqTf.text = "Equipment";
			eqTf.x = 18; eqTf.y = 96;
			addChild(eqTf);
			for (var i:int = 0; i < 4; i++) {
				var sl:ItemSlot = new ItemSlot(i);
				sl.setItem(profile.equip[i]);
				sl.x = 18 + i * 68; sl.y = 118;
				sl.addEventListener(MouseEvent.ROLL_OVER, over);
				sl.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { tip.visible = false; });
				addChild(sl);
			}
			// a full set shows its bonus
			var sets:Object = {}, setId:String;
			for each (var it:Object in profile.equip) if (it && it.set) {
				sets[it.set] = (sets[it.set] || 0) + 1;
				if (sets[it.set] >= 4) setId = it.set;
			}
			var setTf:TextField = Ui.text(12, 0x80e0a0, true, "left", W - 36, true);
			setTf.text = setId ? Data.setName(setId) + " set bonus active" : "";
			setTf.x = 18; setTf.y = 172;
			addChild(setTf);

			var trade:Sprite = Ui.button("Trade", 120, 34, function():void { g.closeInspect(); g.net.requestTrade(p); }, 16);
			trade.x = 18; trade.y = h - 50;
			addChild(trade);
			var close:Sprite = Ui.button("Close", 120, 34, function():void { g.closeInspect(); }, 16);
			close.x = W - 138; close.y = h - 50;
			addChild(close);
			addChild(tip);
		}

		private function over(e:MouseEvent):void {
			var sl:ItemSlot = ItemSlot(e.currentTarget);
			if (!sl.item) return;
			tip.show(sl.item, "");
			var lp:Point = globalToLocal(sl.localToGlobal(new Point(0, 0)));
			tip.x = Math.min(W - tip.width, lp.x);
			tip.y = lp.y + ItemSlot.SIZE + 4;
			setChildIndex(tip, numChildren - 1);
		}
	}
}
