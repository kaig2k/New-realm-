package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;

	/** The right-hand sidebar, laid out like RotMG: minimap, bars, gear, inventory, potions, loot. */
	public class Hud extends Sprite {
		public static const W:int = 240;
		private static const MINI_H:int = 196;
		private static const ZOOMS:Array = [1, 2, 4];

		private var g:Game;
		private var mini:BitmapData;
		private var miniDots:Shape;
		private var zoom:int = 1;
		private var frameN:int = 0;
		private var nameTf:TextField;
		private var portrait:Bitmap;
		private var lvlBar:Bar, fameBar:Bar, hpBar:Bar, mpBar:Bar;
		private var equip:Vector.<Slot> = new Vector.<Slot>();
		private var invSlots:Vector.<Slot> = new Vector.<Slot>();
		private var bagSlots:Vector.<Slot> = new Vector.<Slot>();
		private var hpPot:PotSlot, mpPot:PotSlot;
		private var invPage:Sprite, statPage:Sprite;
		private var statTf:TextField;
		private var tabs:Array = [];
		private var bagPanel:Sprite;
		private var bagTf:TextField;
		private var hintTf:TextField;
		private var tip:Tooltip;
		private var hover:Slot;
		private var lastStats:String = "";

		public function Hud(g:Game) {
			this.g = g;
			graphics.beginFill(Ui.PANEL);
			graphics.drawRect(0, 0, W, Ui.H);
			graphics.endFill();
			graphics.beginFill(0x000000);
			graphics.drawRect(0, 0, 2, Ui.H);
			graphics.endFill();

			// --- minimap
			mini = new BitmapData(W - 2, MINI_H, false, 0);
			var miniBmp:Bitmap = new Bitmap(mini);
			miniBmp.x = 2;
			addChild(miniBmp);
			miniDots = new Shape();
			miniDots.x = 2;
			addChild(miniDots);
			addChild(zoomButton("+", W - 26, 6, 1));
			addChild(zoomButton("-", W - 26, 30, -1));

			// --- name row
			portrait = new Bitmap(Sprites.get(g.player.cls.id));
			portrait.scaleX = portrait.scaleY = 0.75;
			portrait.x = 8;
			portrait.y = MINI_H + 4;
			addChild(portrait);
			nameTf = Ui.text(22, 0xffffff, true, "left", 0, true);
			nameTf.x = 46;
			nameTf.y = MINI_H + 4;
			addChild(nameTf);

			// --- bars
			var y:int = MINI_H + 40;
			lvlBar = new Bar(108, 18, 0x9a6a7a, 0x3a2a30, 12);
			lvlBar.x = 8; lvlBar.y = y;
			addChild(lvlBar);
			fameBar = new Bar(108, 18, 0xe07020, 0x4a2a10, 12);
			fameBar.x = 124; fameBar.y = y;
			addChild(fameBar);
			hpBar = new Bar(224, 22, 0xe03434, 0x4a1a1a, 15);
			hpBar.x = 8; hpBar.y = y + 22;
			addChild(hpBar);
			mpBar = new Bar(224, 22, 0x3c6ee6, 0x1a2a50, 15);
			mpBar.x = 8; mpBar.y = y + 48;
			addChild(mpBar);

			// --- equipment
			y = MINI_H + 118;
			var eq:Shape = new Shape();
			Ui.panel(eq.graphics, 6, y, 228, 58, Ui.PANEL_DARK, 0x555555);
			addChild(eq);
			var kinds:Array = ["weapon", "ability", "armor", "ring"];
			for (var i:int = 0; i < 4; i++) {
				equip.push(makeSlot(kinds[i], i, 12 + i * 55, y + 5, false));
				addChild(equip[i]);
			}

			// --- tabs
			y += 64;
			tabs.push(makeTab("Items", 8, y, 0));
			tabs.push(makeTab("Stats", 70, y, 1));

			// --- inventory page
			y += 26;
			invPage = new Sprite();
			addChild(invPage);
			var s:Slot;
			for (i = 0; i < 8; i++) {
				s = makeSlot("inv", i, 12 + (i % 4) * 55, y + int(i / 4) * 52, true);
				invPage.addChild(s);
				invSlots.push(s);
			}
			hpPot = new PotSlot(true);
			hpPot.x = 12; hpPot.y = y + 106;
			hpPot.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.slotClick("pot", 0, false); });
			invPage.addChild(hpPot);
			mpPot = new PotSlot(false);
			mpPot.x = 122; mpPot.y = y + 106;
			mpPot.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.slotClick("pot", 1, false); });
			invPage.addChild(mpPot);

			// --- stats page
			statPage = new Sprite();
			Ui.panel(statPage.graphics, 6, y - 2, 228, 144, Ui.PANEL_DARK, 0x555555);
			statTf = Ui.text(15, 0xdddddd, true, "left", 210);
			statTf.x = 14; statTf.y = y + 2;
			statPage.addChild(statTf);
			statPage.visible = false;
			addChild(statPage);

			// --- loot bag
			y += 146;
			bagPanel = new Sprite();
			Ui.panel(bagPanel.graphics, 6, y, 228, Ui.H - y - 6, 0x2a2420, 0x6a5030);
			bagTf = Ui.text(12, 0xc8a878, true);
			bagTf.x = 12; bagTf.y = y + 2;
			bagPanel.addChild(bagTf);
			for (i = 0; i < 8; i++) {
				s = makeSlot("bag", i, 12 + (i % 4) * 55, y + 20 + int(i / 4) * 46, false);
				s.scaleX = s.scaleY = 0.9;
				bagPanel.addChild(s);
				bagSlots.push(s);
			}
			bagPanel.visible = false;
			addChild(bagPanel);
			hintTf = Ui.text(12, 0x8a8a8a, false, "center", W - 20);
			hintTf.htmlText = "Stand on a loot bag to see its contents\n<font color='#bbbbbb'>R</font> Haven   <font color='#bbbbbb'>I</font> Autofire   <font color='#bbbbbb'>P</font> Pause";
			hintTf.x = 10; hintTf.y = y + 30;
			addChild(hintTf);

			tip = new Tooltip();
			addChild(tip);
		}

		private function zoomButton(label:String, x:int, y:int, dir:int):Sprite {
			var b:Sprite = new Sprite();
			Ui.panel(b.graphics, 0, 0, 20, 20, 0x2a2a2a, 0x777777, 0.85);
			var t:TextField = Ui.text(16, 0xffffff, true, "center", 20);
			t.text = label;
			t.y = -1;
			b.addChild(t);
			b.x = x; b.y = y;
			b.buttonMode = true;
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				zoom = Math.max(0, Math.min(ZOOMS.length - 1, zoom + dir));
				drawMinimap();
			});
			return b;
		}

		private function makeTab(label:String, x:int, y:int, idx:int):Sprite {
			var t:Sprite = new Sprite();
			var tf:TextField = Ui.text(13, 0xffffff, true, "center", 58);
			tf.text = label;
			tf.y = 1;
			t.addChild(tf);
			t.x = x; t.y = y;
			t.buttonMode = true;
			t.mouseChildren = false;
			t.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { selectTab(idx); });
			addChild(t);
			drawTab(t, idx == 0);
			return t;
		}

		private function drawTab(t:Sprite, on:Boolean):void {
			t.graphics.clear();
			Ui.panel(t.graphics, 0, 0, 58, 22, on ? 0x5a5a5a : 0x2a2a2a, on ? 0x9a9a9a : 0x4a4a4a);
		}

		private function selectTab(idx:int):void {
			for (var i:int = 0; i < tabs.length; i++) drawTab(tabs[i], i == idx);
			invPage.visible = idx == 0;
			statPage.visible = idx == 1;
			lastStats = "";
		}

		private function makeSlot(kind:String, idx:int, x:int, y:int, numbered:Boolean):Slot {
			var s:Slot = new Slot(kind, idx, numbered);
			s.x = x; s.y = y;
			s.addEventListener(MouseEvent.MOUSE_DOWN, onSlotDown);
			s.addEventListener(MouseEvent.ROLL_OVER, onSlotOver);
			s.addEventListener(MouseEvent.ROLL_OUT, onSlotOut);
			return s;
		}

		private function onSlotDown(e:MouseEvent):void {
			var s:Slot = Slot(e.currentTarget);
			g.slotClick(s.kind, s.idx, e.shiftKey);
			refresh();
			showTip(s);
		}

		private function onSlotOver(e:MouseEvent):void {
			hover = Slot(e.currentTarget);
			showTip(hover);
		}

		private function onSlotOut(e:MouseEvent):void {
			hover = null;
			tip.visible = false;
		}

		private function showTip(s:Slot):void {
			if (!s || !s.item) { tip.visible = false; return; }
			var hint:String = s.kind == "bag" ? "Click to pick up" : s.kind == "inv" ? "Click to use or equip. Shift+click to drop." : "Equipped";
			tip.show(s.item, hint);
			var lp:Point = globalToLocal(s.localToGlobal(new Point(0, 0)));
			tip.x = lp.x - tip.width - 8;
			tip.y = Math.max(4, Math.min(Ui.H - tip.height - 4, lp.y - 10));
			setChildIndex(tip, numChildren - 1);
		}

		public function refresh():void {
			var p:Player = g.player;
			nameTf.text = p.name;
			if (p.level >= Player.MAX_LEVEL) lvlBar.set(1, "Lvl " + p.level);
			else lvlBar.set(p.xp / p.xpNext, "Lvl " + p.level + "   " + p.xp + "/" + p.xpNext);
			fameBar.set(1, "Fame  " + Ui.commas(p.fame));
			var hb:int = p.bonus("hp"), mb:int = p.bonus("mp");
			hpBar.set(p.hp / p.maxHp, int(Math.max(0, p.hp)) + "/" + p.maxHp + (hb > 0 ? "  (+" + hb + ")" : ""));
			mpBar.set(p.mp / p.maxMp, int(p.mp) + "/" + p.maxMp + (mb > 0 ? "  (+" + mb + ")" : ""));

			equip[0].setItem(p.weapon);
			equip[1].setItem(p.ability);
			equip[2].setItem(p.armor);
			equip[3].setItem(p.ring);
			var i:int;
			for (i = 0; i < 8; i++) invSlots[i].setItem(p.inv[i]);
			hpPot.setCount(p.hpPots, "F");
			mpPot.setCount(p.mpPots, "G");

			if (statPage.visible) {
				var st:String = statLine("ATT", "att") + statLine("DEF", "def") + statLine("SPD", "spd") +
					statLine("DEX", "dex") + statLine("VIT", "vit") + statLine("WIS", "wis") +
					"<font color='#999999' size='13'>Kills " + p.kills + "    Overlords " + p.bossKills + "</font>";
				if (st != lastStats) {
					lastStats = st;
					statTf.htmlText = st;
				}
			}

			var bag:LootBag = g.nearBag;
			bagPanel.visible = bag != null;
			hintTf.visible = bag == null;
			if (bag) {
				bagTf.text = bag.spr == "bag_white" ? "White Bag" : bag.spr == "bag_cyan" ? "Cyan Bag" : bag.spr == "bag_purple" ? "Purple Bag" : "Loot Bag";
				for (i = 0; i < 8; i++) bagSlots[i].setItem(i < bag.items.length ? bag.items[i] : null);
			}
			if (hover && (!hover.item || (hover.kind == "bag" && !bag))) {
				tip.visible = false;
				hover = null;
			}

			if (++frameN % 4 == 0) drawMinimap();
		}

		private function statLine(label:String, key:String):String {
			var p:Player = g.player;
			var base:int = int(p.stats[key]);
			var b:int = p.bonus(key);
			var maxed:Boolean = p.stats[key] >= p.cls.max[key];
			var c:String = maxed ? "#ffd75e" : "#ffffff";
			return "<font color='#9a9a9a'>" + label + "</font>  <font color='" + c + "'>" + (base + b) + "</font>" +
				(b > 0 ? " <font color='#6fd06f'>(+" + b + ")</font>" : "") +
				(maxed ? " <font color='#ffd75e' size='11'>MAX</font>" : "") + "\n";
		}

		private function drawMinimap():void {
			var z:Number = ZOOMS[zoom];
			var p:Player = g.player;
			var mw:int = mini.width, mh:int = mini.height;
			var ox:Number = Math.round(mw / 2 - p.x * z), oy:Number = Math.round(mh / 2 - p.y * z);
			if (zoom == 0) { ox = (mw - World.N) / 2; oy = (mh - World.N) / 2; }
			mini.fillRect(mini.rect, 0xff000000);
			mini.draw(g.world.seen, new Matrix(z, 0, 0, z, ox, oy), null, null, null, false);

			var gr:* = miniDots.graphics;
			gr.clear();
			var ds:Number = Math.max(2, z * 0.8);
			for each (var e:Enemy in g.enemies) {
				if (e.isBoss) continue;
				var ex:Number = ox + e.x * z, ey:Number = oy + e.y * z;
				if (ex < 0 || ey < 0 || ex > mw || ey > mh) continue;
				gr.beginFill(0xe02020);
				gr.drawRect(ex - ds / 2, ey - ds / 2, ds, ds);
				gr.endFill();
			}
			for each (var b:LootBag in g.bags) {
				var lx:Number = ox + b.x * z, ly:Number = oy + b.y * z;
				if (lx < 0 || ly < 0 || lx > mw || ly > mh) continue;
				gr.beginFill(b.spr == "bag_white" ? 0xffffff : 0xc08040);
				gr.drawRect(lx - ds / 2, ly - ds / 2, ds, ds);
				gr.endFill();
			}
			if (g.boss) {
				var bx:Number = Math.max(4, Math.min(mw - 4, ox + g.boss.x * z));
				var by:Number = Math.max(4, Math.min(mh - 4, oy + g.boss.y * z));
				gr.lineStyle(1, 0x000000);
				gr.beginFill(0xff40ff);
				gr.drawRect(bx - 4, by - 4, 8, 8);
				gr.endFill();
				gr.lineStyle();
			}
			// player arrow
			var px:Number = ox + p.x * z, py:Number = oy + p.y * z;
			gr.lineStyle(1, 0x000000);
			gr.beginFill(0x4aa0ff);
			gr.moveTo(px, py - 6);
			gr.lineTo(px + 5, py + 5);
			gr.lineTo(px, py + 2);
			gr.lineTo(px - 5, py + 5);
			gr.lineTo(px, py - 6);
			gr.endFill();
			gr.lineStyle();
		}
	}
}

import flash.display.Bitmap;
import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;

import realm.Data;
import realm.Sprites;
import realm.Ui;

class Bar extends Sprite {
	private var fill:Shape = new Shape();
	private var tf:TextField;
	private var w:int, h:int;
	private var lastFrac:Number = -1;
	private var lastLabel:String = "";

	public function Bar(w:int, h:int, color:uint, back:uint, size:int) {
		this.w = w;
		this.h = h;
		graphics.lineStyle(1, 0x000000);
		graphics.beginFill(back);
		graphics.drawRoundRect(0, 0, w, h, 6, 6);
		graphics.endFill();
		fill.graphics.beginFill(color);
		fill.graphics.drawRoundRect(1, 1, w - 1, h - 1, 5, 5);
		fill.graphics.beginFill(0xffffff, 0.12);
		fill.graphics.drawRect(2, 2, w - 4, (h - 2) / 2);
		fill.graphics.endFill();
		addChild(fill);
		tf = Ui.text(size, 0xffffff, true, "center", w, true);
		tf.y = (h - tf.height) / 2;
		addChild(tf);
		mouseChildren = false;
	}

	public function set(frac:Number, label:String):void {
		if (frac < 0) frac = 0;
		if (frac > 1) frac = 1;
		if (frac != lastFrac) { fill.scaleX = frac; lastFrac = frac; }
		if (label != lastLabel) {
			tf.text = label;
			tf.y = (h - tf.height) / 2;
			lastLabel = label;
		}
	}
}

class Slot extends Sprite {
	public var kind:String;
	public var idx:int;
	public var item:Object;
	private var icon:Bitmap = new Bitmap();
	private var tierTf:TextField;
	private var numTf:TextField;

	public function Slot(kind:String, idx:int, numbered:Boolean) {
		this.kind = kind;
		this.idx = idx;
		graphics.lineStyle(1, 0x1a1a1a);
		graphics.beginFill(kind == "bag" ? 0x4a3a2c : 0x545454);
		graphics.drawRoundRect(0, 0, 48, 48, 10, 10);
		graphics.endFill();
		if (numbered) {
			numTf = Ui.text(22, 0x6a6a6a, true, "center", 48);
			numTf.text = String(idx + 1);
			numTf.y = 9;
			addChild(numTf);
		}
		icon.x = 6;
		icon.y = 6;
		addChild(icon);
		tierTf = Ui.text(12, 0xffffff, true, "right", 30, true);
		tierTf.x = 16;
		tierTf.y = 29;
		addChild(tierTf);
		mouseChildren = false;
		buttonMode = true;
	}

	public function setItem(it:Object):void {
		if (it == item) return;
		item = it;
		if (numTf) numTf.visible = !it;
		if (!it) {
			icon.bitmapData = null;
			tierTf.text = "";
			return;
		}
		icon.bitmapData = Sprites.icon(it);
		var label:String = Data.tierLabel(it);
		tierTf.text = label;
		tierTf.textColor = label == "UT" ? 0xc070ff : 0xffffff;
	}
}

class PotSlot extends Sprite {
	private var tf:TextField;
	private var key:TextField;
	private var last:int = -1;

	public function PotSlot(health:Boolean) {
		graphics.lineStyle(1, 0x1a1a1a);
		graphics.beginFill(0x545454);
		graphics.drawRoundRect(0, 0, 104, 34, 10, 10);
		graphics.endFill();
		var ic:Bitmap = new Bitmap(Sprites.icon(Data.makePotion(health ? "hp" : "mp")));
		ic.scaleX = ic.scaleY = 0.8;
		ic.x = 22; ic.y = 2;
		addChild(ic);
		tf = Ui.text(18, 0xffffff, true, "left", 0, true);
		tf.x = 56; tf.y = 4;
		addChild(tf);
		key = Ui.text(11, 0x9a9a9a, true);
		key.x = 6; key.y = 2;
		addChild(key);
		buttonMode = true;
		mouseChildren = false;
	}

	public function setCount(n:int, k:String):void {
		if (n == last) return;
		last = n;
		tf.text = String(n);
		tf.textColor = n > 0 ? 0xffffff : 0x8a8a8a;
		key.text = k;
	}
}
