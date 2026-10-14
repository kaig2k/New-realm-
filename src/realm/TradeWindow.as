package realm {
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;

	/**
	 * The trade screen: your inventory on the left, theirs on the right. Click
	 * your items to offer them (green), click theirs to ask for them (gold
	 * outline); what they offer turns green. Both press Accept to swap.
	 */
	public class TradeWindow extends Sprite {
		private static const COLS:int = 4, GAP:int = 6;
		private static const OFFER:uint = 0x3ad05a;
		private static const ASK:uint = 0xffd75e;

		private var g:Game;
		private var s:TradeSession;
		private var mySlots:Array = [];
		private var theirSlots:Array = [];
		private var myState:TextField, theirState:TextField;
		private var acceptBtn:Sprite;
		private var acceptTf:TextField;
		private var tip:Tooltip = new Tooltip();
		private var lastLabel:String = "";
		public var W:int, H:int;

		public function TradeWindow(g:Game, s:TradeSession) {
			this.g = g;
			this.s = s;
			var colW:int = COLS * (ItemSlot.SIZE + GAP) - GAP;
			var rows:int = Math.ceil(Math.max(s.mine.length, s.theirs.length) / COLS);
			W = colW * 2 + 90;
			H = 176 + rows * (ItemSlot.SIZE + GAP);
			Ui.panel(graphics, 0, 0, W, H, 0x1e1e24, 0x8a6aff, 0.97);
			var title:TextField = Ui.text(20, 0xd0b8ff, true, "center", W, true);
			title.text = "Trading with " + s.partner.name;
			title.y = 8;
			addChild(title);
			// divider
			graphics.lineStyle(1, 0x4a4a5a);
			graphics.moveTo(W / 2, 46);
			graphics.lineTo(W / 2, stateY + 18);
			graphics.lineStyle();

			var lx:int = 30, rx:int = W - 30 - colW, top:int = 70;
			addChild(header(g.player.name, g.player.spriteId, lx, 40, colW));
			addChild(header(s.partner.name, s.partner.spriteId, rx, 40, colW));
			for (var i:int = 0; i < s.mine.length; i++) mySlots.push(slot(i, lx, top, true));
			for (i = 0; i < s.theirs.length; i++) theirSlots.push(slot(i, rx, top, false));
			var stateY:int = top + rows * (ItemSlot.SIZE + GAP) + 2;
			myState = Ui.text(13, 0xaaaaaa, true, "center", colW, true);
			myState.x = lx; myState.y = stateY;
			addChild(myState);
			theirState = Ui.text(13, 0xaaaaaa, true, "center", colW, true);
			theirState.x = rx; theirState.y = stateY;
			addChild(theirState);
			var hint:TextField = Ui.text(11, 0x8a8a9a, false, "center", W, true);
			hint.text = "Click your items to offer them. Click theirs to ask for them.";
			hint.y = stateY + 24;
			addChild(hint);

			acceptBtn = Ui.button("Accept", 160, 36, onAccept, 17);
			acceptBtn.x = W / 2 - 170; acceptBtn.y = H - 52;
			acceptTf = TextField(acceptBtn.getChildAt(1));
			addChild(acceptBtn);
			var cancel:Sprite = Ui.button("Cancel", 160, 36, function():void { g.closeTrade(); }, 17);
			cancel.x = W / 2 + 10; cancel.y = H - 52;
			addChild(cancel);
			addChild(tip);
			s.onChange = refresh;
			refresh();
		}

		private function header(name:String, spr:String, x:int, y:int, w:int):Sprite {
			var h:Sprite = new Sprite();
			var bm:Bitmap = new Bitmap(Sprites.get(spr));
			bm.scaleX = bm.scaleY = 0.6;
			bm.x = x; bm.y = y - 4;
			h.addChild(bm);
			var tf:TextField = Ui.text(16, 0xffffff, true, "left", w - 30, true);
			tf.text = name;
			tf.x = x + 30; tf.y = y;
			h.addChild(tf);
			h.mouseEnabled = h.mouseChildren = false;
			return h;
		}

		private function slot(i:int, x0:int, y0:int, mine:Boolean):ItemSlot {
			var sl:ItemSlot = new ItemSlot(i, i >= 8 ? 0x4c4a40 : 0x545454);
			sl.x = x0 + (i % COLS) * (ItemSlot.SIZE + GAP);
			sl.y = y0 + int(i / COLS) * (ItemSlot.SIZE + GAP);
			sl.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				if (mine) s.toggleMine(i); else s.toggleWanted(i);
				g.net.tradeChanged();
				Sfx.play("click", 0.5);
				showTip(sl, mine);
			});
			sl.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { showTip(sl, mine); });
			sl.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { tip.visible = false; });
			addChild(sl);
			return sl;
		}

		private function showTip(sl:ItemSlot, mine:Boolean):void {
			if (!sl.item) { tip.visible = false; return; }
			var hint:String = mine ? (s.mySel[sl.idx] ? "Offered. Click to take it back." : sl.item && sl.item.locked ? "Locked: unlock it (right-click it in your inventory) to trade it." : s.asked[sl.idx] ? s.partner.name + " asked for this. Click to offer it." : "Click to offer this item.")
				: s.theirSel[sl.idx] ? s.partner.name + " is offering this." : s.wanted[sl.idx] ? "Asked for. Click to un-ask." : "Click to ask for this item.";
			tip.show(sl.item, hint);
			var lp:Point = globalToLocal(sl.localToGlobal(new Point(0, 0)));
			tip.x = mine ? lp.x - tip.width - 6 : lp.x + ItemSlot.SIZE + 6;
			if (tip.x < -200) tip.x = lp.x + ItemSlot.SIZE + 6;
			tip.y = Math.max(-40, lp.y - 10);
			setChildIndex(tip, numChildren - 1);
		}

		/** The confirm screen (Accept opens it; a change to either offer closes it). */
		private var confirmBox:Sprite;
		private var confirmVer:int = -1;

		private function onAccept():void {
			if (s.myAccept) return;
			var e:String = s.spaceError();
			if (e) { g.msg(e, 0xff8080); return; }
			if (!s.count(s.mySel) && !s.count(s.theirSel)) { g.msg("Nothing is being traded yet.", 0xff8080); return; }
			showConfirm();
		}

		private function itemList(items:Array):String {
			if (!items.length) return "<font color='#777777'>nothing</font>";
			var out:Array = [];
			for each (var it:Object in items) out.push("<font color='" + Ui.hex(Data.RARITY_COLORS[it.rarity] || 0xffffff) + "'>" + String(it.name).replace(/</g, "&lt;") + "</font> <font color='#8a8a9a'>" + Data.tierLabel(it) + "</font>");
			return out.join("<br>");
		}

		private function showConfirm():void {
			closeConfirm();
			confirmVer = s.version;
			confirmBox = new Sprite();
			confirmBox.graphics.beginFill(0x000000, 0.6);
			confirmBox.graphics.drawRoundRect(0, 0, W, H, 12, 12);
			confirmBox.graphics.endFill();
			var bw:int = Math.min(W - 40, 420);
			var give:Array = s.myOffer(), get:Array = [];
			for (var i:int = 0; i < s.theirs.length; i++) if (s.theirSel[i] && s.theirs[i]) get.push(s.theirs[i]);
			var body:TextField = Ui.text(13, 0xdddddd, false, "left", bw - 40, true);
			body.htmlText = "<font color='#ff9090'><b>You give:</b></font><br>" + itemList(give) + "<br><br><font color='#80e080'><b>You get:</b></font><br>" + itemList(get);
			var bh:int = body.height + 120;
			var panel:Shape = new Shape();
			Ui.panel(panel.graphics, (W - bw) / 2, (H - bh) / 2, bw, bh, 0x23232c, 0xffd75e, 1);
			confirmBox.addChild(panel);
			var t:TextField = Ui.text(17, 0xffd75e, true, "center", bw, true);
			t.text = "Confirm the trade with " + s.partner.name;
			t.x = (W - bw) / 2; t.y = (H - bh) / 2 + 10;
			confirmBox.addChild(t);
			body.x = (W - bw) / 2 + 20; body.y = t.y + 34;
			confirmBox.addChild(body);
			var ok:Sprite = Ui.button("Confirm", 150, 34, function():void {
				// (anything changed since it opened: show the new offer instead)
				if (s.version != confirmVer) { showConfirm(); return; }
				closeConfirm();
				var err:String = s.accept();
				if (err) g.msg(err, 0xff8080);
				else Sfx.play("click");
				g.net.tradeChanged();
			}, 16);
			ok.x = W / 2 - 160; ok.y = (H + bh) / 2 - 48;
			confirmBox.addChild(ok);
			var back:Sprite = Ui.button("Back", 150, 34, closeConfirm, 16);
			back.x = W / 2 + 10; back.y = ok.y;
			confirmBox.addChild(back);
			addChild(confirmBox);
			setChildIndex(tip, numChildren - 1);
		}

		private function closeConfirm():void {
			if (confirmBox && confirmBox.parent) removeChild(confirmBox);
			confirmBox = null;
		}

		public function refresh():void {
			// an offer changed while confirming: the confirm screen shows the new one
			if (confirmBox && s.version != confirmVer) { showConfirm(); g.msg("The trade changed. Check it again before confirming.", 0xffd75e); }
			for (var i:int = 0; i < mySlots.length; i++) {
				mySlots[i].setItem(s.mine[i]);
				if (s.mySel[i]) mySlots[i].mark(OFFER);
				else if (s.asked[i] && s.mine[i]) mySlots[i].mark(ASK, false, true);
				else mySlots[i].mark(0);
			}
			for (i = 0; i < theirSlots.length; i++) {
				theirSlots[i].setItem(s.theirs[i]);
				if (s.theirSel[i]) theirSlots[i].mark(OFFER);
				else if (s.wanted[i]) theirSlots[i].mark(ASK, false, true);
				else theirSlots[i].mark(0);
			}
			myState.htmlText = s.myAccept ? "<font color='#5ae06a'>Accepted</font>" : "Offering " + s.count(s.mySel) + " item" + (s.count(s.mySel) == 1 ? "" : "s");
			theirState.htmlText = s.theirAccept ? "<font color='#5ae06a'>Accepted</font>" : "Offering " + s.count(s.theirSel) + " item" + (s.count(s.theirSel) == 1 ? "" : "s");
			update();
		}

		/** Per-frame: the Accept button counts down after a change. */
		public function update():void {
			var label:String = s.myAccept ? "Waiting..." : "Accept";
			if (label != lastLabel) {
				lastLabel = label;
				acceptTf.text = label;
				acceptBtn.alpha = s.myAccept ? 0.55 : 1;
			}
		}
	}
}
