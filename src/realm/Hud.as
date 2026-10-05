package realm {
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	/** The right-hand sidebar: minimap, bars, stats, equipment, inventory and loot bag. */
	public class Hud extends Sprite {
		public static const W:int = 200;

		private var g:Game;
		private var mini:Bitmap;
		private var miniDots:Shape;
		private var dotT:int = 0;
		private var nameTf:TextField;
		private var fameTf:TextField;
		private var xpBar:Bar, hpBar:Bar, mpBar:Bar;
		private var statTf:TextField;
		private var abilityTf:TextField;
		private var potTf:TextField;
		private var weaponSlot:Slot, armorSlot:Slot;
		private var invSlots:Vector.<Slot> = new Vector.<Slot>();
		private var bagSlots:Vector.<Slot> = new Vector.<Slot>();
		private var bagTf:TextField;
		private var tip:TextField;
		private var hover:Slot;
		private var lastStats:String = "";

		public function Hud(g:Game) {
			this.g = g;
			graphics.beginFill(0x24232c);
			graphics.drawRect(0, 0, W, 600);
			graphics.endFill();
			graphics.lineStyle(2, 0x111111);
			graphics.moveTo(1, 0);
			graphics.lineTo(1, 600);

			mini = new Bitmap(g.world.minimap);
			addChild(mini);
			miniDots = new Shape();
			addChild(miniDots);

			nameTf = Ui.text(14, 0xffffff, true);
			nameTf.x = 6; nameTf.y = 202;
			addChild(nameTf);
			fameTf = Ui.text(12, 0xffa040, true, "right", 90);
			fameTf.x = W - 96; fameTf.y = 204;
			addChild(fameTf);

			xpBar = new Bar(W - 12, 11, 0xd08020);
			xpBar.x = 6; xpBar.y = 224;
			addChild(xpBar);
			hpBar = new Bar(W - 12, 15, 0xc02828);
			hpBar.x = 6; hpBar.y = 239;
			addChild(hpBar);
			mpBar = new Bar(W - 12, 15, 0x2850c8);
			mpBar.x = 6; mpBar.y = 258;
			addChild(mpBar);

			statTf = Ui.text(11, 0xdddddd, false, "left", W - 12);
			statTf.x = 6; statTf.y = 276;
			addChild(statTf);

			weaponSlot = makeSlot("weapon", 0, 6, 330);
			armorSlot = makeSlot("armor", 0, 46, 330);
			abilityTf = Ui.text(10, 0xcccccc, false, "left", 108);
			abilityTf.x = 88; abilityTf.y = 326;
			addChild(abilityTf);
			potTf = Ui.text(10, 0xffffff, true, "left", 108);
			potTf.x = 88; potTf.y = 353;
			addChild(potTf);

			var lbl:TextField = Ui.text(10, 0x999999);
			lbl.text = "Inventory  (keys 1-8)";
			lbl.x = 6; lbl.y = 374;
			addChild(lbl);
			var i:int;
			for (i = 0; i < 8; i++) invSlots.push(makeSlot("inv", i, 6 + (i % 4) * 47, 388 + int(i / 4) * 42));

			bagTf = Ui.text(10, 0x999999);
			bagTf.x = 6; bagTf.y = 474;
			addChild(bagTf);
			for (i = 0; i < 8; i++) bagSlots.push(makeSlot("bag", i, 6 + (i % 4) * 47, 490 + int(i / 4) * 42));

			var help:TextField = Ui.text(10, 0x777777);
			help.text = "R: Haven   I: autofire   P: pause";
			help.x = 6; help.y = 576;
			addChild(help);

			tip = Ui.text(12, 0xffffff, false, "left", 190);
			tip.background = true;
			tip.backgroundColor = 0x15141c;
			tip.border = true;
			tip.borderColor = 0x8a7a50;
			tip.visible = false;
			addChild(tip);
		}

		private function makeSlot(kind:String, idx:int, x:int, y:int):Slot {
			var s:Slot = new Slot(kind, idx);
			s.x = x; s.y = y;
			s.addEventListener(MouseEvent.MOUSE_DOWN, onSlotDown);
			s.addEventListener(MouseEvent.ROLL_OVER, onSlotOver);
			s.addEventListener(MouseEvent.ROLL_OUT, onSlotOut);
			addChild(s);
			return s;
		}

		public function destroy():void {
			// listeners are on our own children, nothing global to clean up
		}

		private function onSlotDown(e:MouseEvent):void {
			var s:Slot = Slot(e.currentTarget);
			g.slotClick(s.kind, s.idx, e.shiftKey);
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
			var extra:String = "";
			if (s.kind == "bag") extra = "<font color='#999999'>Click to pick up</font>";
			else if (s.kind == "inv") extra = "<font color='#999999'>Click to use/equip, shift+click to drop</font>";
			else extra = "<font color='#999999'>Equipped</font>";
			tip.htmlText = Data.describe(s.item) + extra;
			tip.x = s.x - tip.width - 6;
			tip.y = Math.min(600 - tip.height - 4, s.y);
			tip.visible = true;
			setChildIndex(tip, numChildren - 1);
		}

		public function refresh():void {
			var p:Player = g.player;
			nameTf.text = p.cls.name + "  Lv " + p.level;
			fameTf.text = p.fame + " Fame";
			if (p.level >= Player.MAX_LEVEL) xpBar.set(1, "Max level");
			else xpBar.set(p.xp / p.xpNext, "XP " + p.xp + "/" + p.xpNext);
			hpBar.set(p.hp / p.maxHp, int(p.hp) + "/" + p.maxHp);
			mpBar.set(p.mp / p.maxMp, int(p.mp) + "/" + p.maxMp);

			var st:String = statLine("ATT", p.att, "att") + "    " + statLine("DEF", p.def, "def") + "\n" +
				statLine("SPD", p.spd, "spd") + "    " + statLine("DEX", p.dex, "dex") + "\n" +
				statLine("VIT", p.vit, "vit") + "    " + statLine("WIS", p.wis, "wis");
			if (st != lastStats) {
				lastStats = st;
				statTf.htmlText = st;
				abilityTf.htmlText = "<b>SPACE</b> " + p.cls.ability.name + "\n<font color='#8090ff'>" + p.cls.ability.cost + " MP</font>";
			}
			potTf.htmlText = "<font color='#ff6060'>HP " + p.hpPots + "</font> [F]   <font color='#7090ff'>MP " + p.mpPots + "</font> [G]";

			weaponSlot.setItem(p.weapon);
			armorSlot.setItem(p.armor);
			var i:int;
			for (i = 0; i < 8; i++) invSlots[i].setItem(p.inv[i]);
			var bag:LootBag = g.nearBag;
			bagTf.text = bag ? "Loot bag (click items to take)" : "";
			for (i = 0; i < 8; i++) {
				bagSlots[i].visible = bag != null;
				bagSlots[i].setItem(bag && i < bag.items.length ? bag.items[i] : null);
			}
			if (hover && !hover.item) tip.visible = false;

			if (++dotT % 6 == 0) drawDots();
		}

		private function statLine(label:String, v:int, key:String):String {
			var maxed:Boolean = g.player.stats[key] >= g.player.cls.max[key];
			var c:String = maxed ? "#ffd75e" : "#dddddd";
			return "<font color='#999999'>" + label + "</font> <font color='" + c + "'>" + pad(v) + "</font>";
		}

		private function pad(v:int):String {
			var s:String = String(v);
			while (s.length < 3) s = " " + s;
			return s;
		}

		private function drawDots():void {
			var gr:* = miniDots.graphics;
			gr.clear();
			for each (var e:Enemy in g.enemies) {
				if (e.isBoss) continue;
				gr.beginFill(0xff3030);
				gr.drawRect(int(e.x) - 1, int(e.y) - 1, 2, 2);
				gr.endFill();
			}
			for each (var b:LootBag in g.bags) {
				gr.beginFill(b.spr == "bag_white" ? 0xffffff : 0xc08040);
				gr.drawRect(int(b.x) - 1, int(b.y) - 1, 2, 2);
				gr.endFill();
			}
			if (g.boss) {
				gr.lineStyle(1, 0x000000);
				gr.beginFill(0xff40ff);
				gr.drawRect(int(g.boss.x) - 3, int(g.boss.y) - 3, 7, 7);
				gr.endFill();
				gr.lineStyle();
			}
			// view box + player
			var vw:Number = Game.VIEW / Game.TS;
			gr.lineStyle(1, 0xffffff, 0.5);
			gr.drawRect(g.camX - vw / 2, g.camY - vw / 2, vw, vw);
			gr.lineStyle();
			gr.beginFill(0xffffff);
			gr.drawRect(int(g.player.x) - 2, int(g.player.y) - 2, 4, 4);
			gr.endFill();
		}
	}
}

import flash.display.Bitmap;
import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;

import realm.Sprites;
import realm.Ui;

class Bar extends Sprite {
	private var fill:Shape = new Shape();
	private var tf:TextField;
	private var w:int, h:int;
	private var lastFrac:Number = -1;
	private var lastLabel:String = "";

	public function Bar(w:int, h:int, color:uint) {
		this.w = w;
		this.h = h;
		graphics.beginFill(0x111111);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		fill.graphics.beginFill(color);
		fill.graphics.drawRect(0, 0, w, h);
		fill.graphics.endFill();
		addChild(fill);
		tf = Ui.text(h > 12 ? 11 : 9, 0xffffff, true, "center", w, true);
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

	public function Slot(kind:String, idx:int) {
		this.kind = kind;
		this.idx = idx;
		graphics.lineStyle(1, kind == "weapon" || kind == "armor" ? 0x8a7a50 : 0x4a4a55);
		graphics.beginFill(kind == "bag" ? 0x3a2f24 : 0x34333e);
		graphics.drawRoundRect(0, 0, 38, 38, 6, 6);
		graphics.endFill();
		icon.x = 3;
		icon.y = 3;
		icon.scaleX = icon.scaleY = 0.8;
		addChild(icon);
		tierTf = Ui.text(9, 0xffffff, true, "left", 0, true);
		tierTf.x = 21;
		tierTf.y = 24;
		addChild(tierTf);
		mouseChildren = false;
		buttonMode = true;
	}

	public function setItem(it:Object):void {
		if (it == item) return;
		item = it;
		if (!it) {
			icon.bitmapData = null;
			tierTf.text = "";
			return;
		}
		icon.bitmapData = Sprites.icon(it);
		if (it.kind == "weapon" || it.kind == "armor") {
			tierTf.text = it.tier >= 8 ? "UT" : "T" + it.tier;
			tierTf.textColor = it.tier >= 8 ? 0xff70ff : 0xffffff;
		} else tierTf.text = "";
	}
}
