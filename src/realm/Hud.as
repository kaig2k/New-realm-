package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;

	/** The right-hand sidebar, laid out like RotMG. */
	public class Hud extends Sprite {
		public static const W:int = 240;
		private static const MINI_H:int = 176;
		private static const ZOOMS:Array = [1, 2, 4];

		private static const I_TEMPLE:Array = ["...WW...", "..WWWW..", "WWWWWWWW", ".W.WW.W.", ".W.WW.W.", ".W.WW.W.", "WWWWWWWW", "........"];
		private static const I_PACK:Array = ["..WWWW..", ".W....W.", "WWWWWWWW", "WWWDDWWW", "WWWWWWWW", "WWWWWWWW", ".WWWWWW.", "........"];
		private static const I_STAR:Array = ["...W....", "...W....", ".WWWWW..", "..WWW...", "..W.W...", ".W...W..", "........", "........"];
		private static const I_PEOPLE:Array = ["..W..W..", ".WWWWWW.", "..W..W..", "........", ".WW..WW.", "WWWWWWWW", "WWWWWWWW", "........"];
		private static const I_BOOK:Array = ["WWW.WWW.", "W.WWW.W.", "W.WWW.W.", "WWWWWWW.", "W.WWW.W.", "W.WWW.W.", "WWW.WWW.", "........"];
		private static const I_CHART:Array = ["........", "......W.", "......W.", "...W..W.", "...W..W.", "W..W..W.", "W..W..W.", "WWWWWWWW"];

		private var g:Game;
		private var mini:BitmapData;
		private var miniDots:Shape;
		private var zoom:int = 1;
		private var frameN:int = 0;
		private var nameTf:TextField;
		private var portrait:Bitmap;
		private var lvlBar:Bar, fameBar:Bar, hpBar:Bar, mpBar:Bar, ptBar:Bar, sgBar:Bar;
		private var equip:Vector.<Slot> = new Vector.<Slot>();
		private var invSlots:Vector.<Slot> = new Vector.<Slot>();
		private var bagSlots:Vector.<Slot> = new Vector.<Slot>();
		private var hpPot:PotSlot, mpPot:PotSlot;
		private var invPage:Sprite, statPage:Sprite, skillPage:Sprite;
		private var skillTf:TextField;
		private var skillRows:Array = [];
		private var lastSkills:String = "";
		private var statTf:TextField;
		private var tabs:Array = [];
		private var packBtn:Sprite;
		private var packTf:TextField;
		private var bagBox:Shape;
		private var tip:Tooltip;
		private var hover:Slot;
		// drag and drop
		private var dragSlot:Slot;
		private var dragging:Boolean = false;
		private var dragGhost:Bitmap;
		private var downX:Number, downY:Number;
		private var lastStats:String = "";
		private var lastBag:LootBag;

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
			addChild(zoomButton("+", W - 24, 6, 1));
			addChild(zoomButton("-", W - 24, 28, -1));

			// --- name row: portrait, name, nexus button
			var y:int = MINI_H + 4;
			portrait = new Bitmap(Sprites.get(g.player.spriteId));
			portrait.scaleX = portrait.scaleY = 0.72;
			portrait.x = 6;
			portrait.y = y - 2;
			addChild(portrait);
			nameTf = Ui.text(24, 0xffffff, true, "left", 0, true);
			nameTf.x = 44;
			nameTf.y = y - 2;
			addChild(nameTf);
			var nexusBtn:Sprite = iconButton(I_TEMPLE, W - 34, y + 2, 0xe8e8e8);
			nexusBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.nexus(); });
			addChild(nexusBtn);
			var socialBtn:Sprite = iconButton(I_PEOPLE, W - 62, y + 2, 0x9ad0ff);
			socialBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.toggleSocial(); });
			addChild(socialBtn);
			var wikiBtn:Sprite = iconButton(I_BOOK, W - 90, y + 2, 0xffd75e);
			wikiBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.toggleWiki(); });
			addChild(wikiBtn);

			// --- bars
			y = MINI_H + 40;
			lvlBar = new Bar(110, 18, 0x9a7480, 0x2a2224, 11, "", "left");
			lvlBar.x = 6; lvlBar.y = y;
			addChild(lvlBar);
			fameBar = new Bar(110, 18, 0xe0762a, 0x3a2410, 11, "", "left");
			fameBar.x = 124; fameBar.y = y;
			addChild(fameBar);
			hpBar = new Bar(228, 22, 0xe03838, 0x3a1a1a, 15, "HP");
			hpBar.x = 6; hpBar.y = y + 22;
			addChild(hpBar);
			mpBar = new Bar(228, 22, 0x3d6fe8, 0x1a2244, 15, "MP");
			mpBar.x = 6; mpBar.y = y + 48;
			addChild(mpBar);
			// Ward (WD, from Warding) and Fervor (FV) bars
			ptBar = new Bar(110, 18, 0xe8e8f0, 0x2a2a2a, 12, "WD", "left", 0x222222);
			ptBar.x = 6; ptBar.y = y + 74;
			addChild(ptBar);
			sgBar = new Bar(110, 18, 0xd8b030, 0x2a2a2a, 12, "FV", "left");
			sgBar.x = 124; sgBar.y = y + 74;
			addChild(sgBar);

			// --- equipment
			y = MINI_H + 138;
			var eq:Shape = new Shape();
			Ui.panel(eq.graphics, 4, y, 232, 58, 0x262626, 0x4a4a4a);
			addChild(eq);
			var kinds:Array = ["weapon", "ability", "armor", "ring"];
			for (var i:int = 0; i < 4; i++) {
				equip.push(makeSlot(kinds[i], i, 10 + i * 56, y + 5, false));
				addChild(equip[i]);
			}

			// --- tabs (icon buttons)
			y += 62;
			tabs.push(makeTab(I_PACK, 8, y, 0));
			tabs.push(makeTab(I_CHART, 46, y, 1));
			tabs.push(makeTab(I_STAR, 84, y, 2));
			// backpack page toggle
			packBtn = new Sprite();
			Ui.panel(packBtn.graphics, 0, 0, 104, 24, 0x3a3020, 0x8a7040);
			packTf = Ui.text(12, 0xffd75e, true, "center", 104, true);
			packTf.y = 3;
			packBtn.addChild(packTf);
			packBtn.x = 128; packBtn.y = y;
			packBtn.buttonMode = true;
			packBtn.mouseChildren = false;
			packBtn.visible = false;
			packBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				var pl:Player = g.player;
				if (!pl.backpack) return;
				pl.packPage = 1 - pl.packPage;
				selectTab(0);
				refresh();
			});
			addChild(packBtn);

			// --- inventory page
			y += 28;
			invPage = new Sprite();
			addChild(invPage);
			var s:Slot;
			for (i = 0; i < 8; i++) {
				s = makeSlot("inv", i, 10 + (i % 4) * 56, y + int(i / 4) * 52, true);
				invPage.addChild(s);
				invSlots.push(s);
			}
			hpPot = new PotSlot(true);
			hpPot.x = 10; hpPot.y = y + 104;
			hpPot.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.slotClick("pot", 0, false); });
			invPage.addChild(hpPot);
			mpPot = new PotSlot(false);
			mpPot.x = 122; mpPot.y = y + 104;
			mpPot.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.slotClick("pot", 1, false); });
			invPage.addChild(mpPot);

			// --- stats page
			statPage = new Sprite();
			Ui.panel(statPage.graphics, 4, y - 2, 232, 140, 0x262626, 0x4a4a4a);
			statTf = Ui.text(13, 0xdddddd, true, "left", 214);
			statTf.x = 14; statTf.y = y + 2;
			statPage.addChild(statTf);
			statPage.visible = false;
			addChild(statPage);

			// --- skill tree page (Awakening)
			skillPage = new Sprite();
			Ui.panel(skillPage.graphics, 4, y - 2, 232, 140, 0x262626, 0x4a4a4a);
			skillTf = Ui.text(11, 0x80e0ff, true, "left", 220);
			skillTf.x = 10; skillTf.y = y;
			skillPage.addChild(skillTf);
			for (i = 0; i < Data.SKILLS.length; i++) {
				var row:TextField = Ui.text(11, 0xdddddd, false, "left", 200);
				row.x = 10; row.y = y + 14 + i * 13;
				skillPage.addChild(row);
				var plus:Sprite = skillButton(Data.SKILLS[i].id);
				plus.x = 214; plus.y = y + 16 + i * 13;
				skillPage.addChild(plus);
				skillRows.push(row);
			}
			skillPage.visible = false;
			addChild(skillPage);

			// --- loot bag grid (always shown, like the backpack area)
			y += 142;
			bagBox = new Shape();
			addChild(bagBox);
			for (i = 0; i < 8; i++) {
				s = makeSlot("bag", i, 12 + (i % 4) * 56, y + 4 + int(i / 4) * 44, false);
				s.scaleX = s.scaleY = 0.84;
				addChild(s);
				bagSlots.push(s);
			}
			drawBagBox(false, y);

			tip = new Tooltip();
			addChild(tip);
		}

		private var bagY:int;

		private function drawBagBox(active:Boolean, y:int = -1):void {
			if (y >= 0) bagY = y;
			bagBox.graphics.clear();
			Ui.panel(bagBox.graphics, 4, bagY, 232, Ui.H - bagY - 4, active ? 0x3a2c20 : 0x2c2c2c, active ? 0x8a6838 : 0x404040);
			for each (var s:Slot in bagSlots) s.alpha = active ? 1 : 0.45;
		}

		private function pix(rows:Array, color:uint, scale:int):BitmapData {
			return Sprites.build(rows, {W: color, D: 0x303030}, scale, 1);
		}

		private function iconButton(rows:Array, x:int, y:int, color:uint):Sprite {
			var b:Sprite = new Sprite();
			var bmp:Bitmap = new Bitmap(pix(rows, color, 3));
			b.addChild(bmp);
			b.x = x; b.y = y;
			b.buttonMode = true;
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { bmp.alpha = 0.7; });
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { bmp.alpha = 1; });
			return b;
		}

		private function zoomButton(label:String, x:int, y:int, dir:int):Sprite {
			var b:Sprite = new Sprite();
			Ui.panel(b.graphics, 0, 0, 18, 18, 0x2a2a2a, 0x777777, 0.85);
			var t:TextField = Ui.text(15, 0xffffff, true, "center", 18);
			t.text = label;
			t.y = -2;
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

		private function skillButton(id:String):Sprite {
			var b:Sprite = new Sprite();
			Ui.panel(b.graphics, 0, 0, 14, 12, 0x3a5a3a, 0x6aa06a);
			var t:TextField = Ui.text(11, 0xffffff, true, "center", 14);
			t.text = "+";
			t.y = -3;
			b.addChild(t);
			b.buttonMode = true;
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.player.spendSkill(id, g); lastSkills = ""; });
			return b;
		}

		private function refreshSkills(p:Player):void {
			var key:String = p.skillPoints + "|" + p.ascXp + "|" + p.ascended + "|" + p.maxedCount;
			for each (var sk:Object in Data.SKILLS) key += p.rank(sk.id);
			if (key == lastSkills) return;
			lastSkills = key;
			skillTf.text = p.ascended ? "Skill points: " + p.skillPoints + "   next " + p.ascXp + "/" + Data.XP_PER_SKILL_POINT + " XP"
				: "Locked: needs Lvl 20 and 11/11 (" + p.maxedCount + "/11)";
			skillTf.textColor = p.ascended ? 0x80e0ff : 0xff8080;
			for (var i:int = 0; i < Data.SKILLS.length; i++) {
				var s:Object = Data.SKILLS[i];
				var r:int = p.rank(s.id);
				skillRows[i].htmlText = "<b><font color='" + (r >= s.max ? "#ffd75e" : "#ffffff") + "'>" + s.name + "</font></b> " + r + "/" + s.max +
					"  <font color='#9a9a9a'>" + s.desc + "</font>";
			}
		}

		private function makeTab(rows:Array, x:int, y:int, idx:int):Sprite {
			var t:Sprite = new Sprite();
			var bmp:Bitmap = new Bitmap(pix(rows, 0xe8e8e8, 2));
			bmp.x = (32 - bmp.width) / 2;
			bmp.y = (24 - bmp.height) / 2;
			t.addChild(bmp);
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
			Ui.panel(t.graphics, 0, 0, 32, 24, on ? 0x5a5a5a : 0x2a2a2a, on ? 0x9a9a9a : 0x4a4a4a);
		}

		private function selectTab(idx:int):void {
			for (var i:int = 0; i < tabs.length; i++) drawTab(tabs[i], i == idx);
			invPage.visible = idx == 0;
			statPage.visible = idx == 1;
			skillPage.visible = idx == 2;
			lastSkills = "";
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
			// shift+click keeps its shortcuts (sell at the Marketplace, quick drop); clicks on empty slots do nothing
			if (e.shiftKey || !s.item) {
				g.slotClick(s.kind, s.idx, e.shiftKey);
				refresh();
				showTip(s);
				return;
			}
			dragSlot = s;
			dragging = false;
			downX = stage.mouseX; downY = stage.mouseY;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onDragMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onDragUp);
		}

		private function onDragMove(e:MouseEvent):void {
			if (!dragSlot) return;
			if (!dragging) {
				var dx:Number = stage.mouseX - downX, dy:Number = stage.mouseY - downY;
				if (dx * dx + dy * dy < 36) return;
				dragging = true;
				dragGhost = new Bitmap(Sprites.icon(dragSlot.item));
				dragGhost.alpha = 0.9;
				addChild(dragGhost);
				dragSlot.alpha = 0.35;
				tip.visible = false;
			}
			dragGhost.x = mouseX - dragGhost.width / 2;
			dragGhost.y = mouseY - dragGhost.height / 2;
			e.updateAfterEvent();
		}

		private function onDragUp(e:MouseEvent):void {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onDragUp);
			var s:Slot = dragSlot;
			dragSlot = null;
			if (!s) return;
			s.alpha = 1;
			if (!dragging) {
				// a plain click: use, equip or pick up
				g.slotClick(s.kind, s.idx, false);
			} else {
				if (dragGhost) { removeChild(dragGhost); dragGhost = null; }
				dragging = false;
				var target:Slot = slotUnderMouse();
				if (target) g.dragToSlot(s.kind, s.idx, target.kind, target.idx);
				else if (mouseX < 0) g.dragToGround(s.kind, s.idx);
			}
			refresh();
			if (hover) showTip(hover);
		}

		private function slotUnderMouse():Slot {
			var lists:Array = [invSlots, equip, bagSlots];
			for each (var list:Vector.<Slot> in lists) {
				for each (var sl:Slot in list) {
					if (!sl.visible || !sl.parent || !sl.parent.visible) continue;
					if (sl.hitTestPoint(stage.mouseX, stage.mouseY, false)) return sl;
				}
			}
			return null;
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
			var hint:String = s.kind == "bag" ? (g.nearBag && g.nearBag.vault ? "Click to take out of your vault" : "Click to pick up, or drag into a slot") : s.kind == "inv" ? (g.nearMarket ? "Shift+click to sell" : "Click to use or equip. Drag onto the ground to drop.") : "Equipped. Drag into your inventory to take it off.";
			tip.show(s.item, hint);
			var lp:Point = globalToLocal(s.localToGlobal(new Point(0, 0)));
			tip.x = lp.x - tip.width - 8;
			tip.y = Math.max(4, Math.min(Ui.H - tip.height - 4, lp.y - 10));
			setChildIndex(tip, numChildren - 1);
		}

		public function refresh():void {
			var p:Player = g.player;
			nameTf.text = p.name;
			var pbd:BitmapData = Sprites.get(p.spriteId);
			if (portrait.bitmapData != pbd) { portrait.bitmapData = pbd; portrait.scaleX = portrait.scaleY = 0.72; }
			if (p.level >= Player.MAX_LEVEL) lvlBar.set(1, "Lvl " + p.level, "Max");
			else lvlBar.set(p.xp / p.xpNext, "Lvl " + p.level, p.xp + "/" + p.xpNext);
			fameBar.set(1, "Fame", Ui.commas(p.fame));
			var hb:int = p.bonus("hp"), mb:int = p.bonus("mp");
			hpBar.set(p.hp / p.maxHp, "HP", int(Math.max(0, p.hp)) + "/" + p.maxHp + (hb > 0 ? " <font color='#ffe36e'>(+" + hb + ")</font>" : ""));
			mpBar.set(p.mp / p.maxMp, "MP", int(p.mp) + "/" + p.maxMp + (mb > 0 ? " <font color='#ffe36e'>(+" + mb + ")</font>" : ""));
			ptBar.set(p.maxPt > 0 ? p.pt / p.maxPt : 0, "WD", int(p.pt) + "/" + p.maxPt);
			sgBar.set(p.surge / Player.SURGE_MAX, "FV", p.surge + "/" + Player.SURGE_MAX);

			equip[0].setItem(p.weapon);
			equip[1].setItem(p.ability);
			equip[2].setItem(p.armor);
			equip[3].setItem(p.ring);
			var i:int;
			if (!p.backpack) p.packPage = 0;
			packBtn.visible = p.backpack;
			packTf.text = p.packPage == 0 ? "Inventory  1 / 2" : "Backpack  2 / 2";
			for (i = 0; i < 8; i++) {
				invSlots[i].idx = p.packPage * 8 + i;
				invSlots[i].setItem(p.inv[p.packPage * 8 + i]);
			}
			hpPot.setCount(p.hpPots, "F");
			mpPot.setCount(p.mpPots, "G");

			if (skillPage.visible) refreshSkills(p);
			if (statPage.visible) {
				var st:String = "<font color='#ffd75e'>Maxed " + p.maxedCount + "/11</font>\n" +
					statLine("att") + statLine("def") + "\n" + statLine("spd") + statLine("dex") + "\n" +
					statLine("vit") + statLine("wis") + "\n" + statLine("mgt") + statLine("luc") + "\n" +
					statLine("prt") + "<font color='#9a9a9a'>BNT</font> " + p.frt + "\n" +
					"<font color='#aaaaaa' size='12'>Crit " + Math.round(p.critChance * 100) + "%  x" + p.critMult.toFixed(2) +
					(p.setPieces >= 4 ? "   <font color='#4ee08a'>Set bonus</font>" : "") + "</font>";
				if (st != lastStats) {
					lastStats = st;
					statTf.htmlText = st;
				}
			}

			var bag:LootBag = g.nearBag;
			if ((bag != null) != (lastBag != null)) drawBagBox(bag != null);
			lastBag = bag;
			for (i = 0; i < 8; i++) bagSlots[i].setItem(bag && i < bag.items.length ? bag.items[i] : null);
			if (hover && (!hover.item || (hover.kind == "bag" && !bag))) {
				tip.visible = false;
				hover = null;
			}

			if (++frameN % 4 == 0) drawMinimap();
		}

		private function statLine(key:String):String {
			var p:Player = g.player;
			var b:int = p.bonus(key);
			var maxed:Boolean = p.stats[key] >= p.cls.max[key];
			var v:String = String(p.stat(key));
			while (v.length < 4) v += " ";
			return "<font color='#9a9a9a'>" + Data.STAT_SHORT[key] + "</font> <font color='" + (maxed ? "#ffd75e" : "#ffffff") + "'>" + p.stat(key) + "</font>" +
				(b > 0 ? "<font color='#6fd06f'>+" + b + "</font>" : "") + "      ";
		}

		private function drawMinimap():void {
			var p:Player = g.player;
			var mw:int = mini.width, mh:int = mini.height;
			var n:int = g.world.N;
			// zoom 0 fits the whole map
			var z:Number = zoom == 0 ? Math.min(1, Math.min(mw / n, mh / n)) : ZOOMS[zoom];
			var ox:Number = Math.round(mw / 2 - p.x * z), oy:Number = Math.round(mh / 2 - p.y * z);
			if (zoom == 0) { ox = Math.round((mw - n * z) / 2); oy = Math.round((mh - n * z) / 2); }
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
			// shrines you've seen: a small dot in the blessing's colour
			for each (var sh:Object in g.world.shrines) {
				if ((g.world.seen.getPixel32(int(sh.x), int(sh.y)) >>> 24) == 0) continue;
				var hx:Number = ox + sh.x * z, hy:Number = oy + sh.y * z;
				if (hx < 0 || hy < 0 || hx > mw || hy > mh) continue;
				gr.lineStyle(1, 0x000000);
				gr.beginFill(sh.cd > 0 ? 0x606060 : {might: 0xff4040, haste: 0x40e0ff, fortune: 0xffd040, vigor: 0x50e070, arcana: 0xb060ff}[sh.kind]);
				gr.drawCircle(hx, hy, Math.max(2.5, ds));
				gr.endFill();
				gr.lineStyle();
			}
			// landmarks you've seen: a coloured diamond, grey once cleared
			for each (var st:Object in g.world.sites) {
				if (!st.found && (g.world.seen.getPixel32(int(st.x), int(st.y)) >>> 24) == 0) continue;
				var sx:Number = ox + st.x * z, sy:Number = oy + st.y * z;
				if (sx < 0 || sy < 0 || sx > mw || sy > mh) continue;
				var sr:Number = Math.max(3, ds * 1.6);
				gr.lineStyle(1, 0x000000);
				gr.beginFill(st.cleared ? 0x707070 : st.color);
				gr.moveTo(sx, sy - sr); gr.lineTo(sx + sr, sy); gr.lineTo(sx, sy + sr); gr.lineTo(sx - sr, sy); gr.lineTo(sx, sy - sr);
				gr.endFill();
				gr.lineStyle();
			}
			// other players are yellow, like RotMG
			for each (var rp:RemotePlayer in g.net.players) {
				if (!g.shown(rp) && !g.net.isFriend(rp)) continue;
				var rx:Number = ox + rp.x * z, ry:Number = oy + rp.y * z;
				if (rx < 0 || ry < 0 || rx > mw || ry > mh) continue;
				gr.beginFill(g.net.inParty(rp) ? 0x7fd8ff : g.net.inGuild(rp) ? 0x60ff60 : 0xffe040);
				gr.drawRect(rx - ds / 2, ry - ds / 2, ds, ds);
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

/** RotMG-style bar: short label on the left, value centred (or after the label). */
class Bar extends Sprite {
	private var fill:Shape = new Shape();
	private var labelTf:TextField;
	private var valueTf:TextField;
	private var w:int, h:int;
	private var valueAlign:String;
	private var lastFrac:Number = -1;
	private var lastLabel:String = "";
	private var lastValue:String = "";

	public function Bar(w:int, h:int, color:uint, back:uint, size:int, label:String = "", valueAlign:String = "center", textColor:uint = 0xffffff) {
		this.w = w;
		this.h = h;
		this.valueAlign = valueAlign;
		graphics.lineStyle(1, 0x111111);
		graphics.beginFill(back);
		graphics.drawRoundRect(0, 0, w, h, 6, 6);
		graphics.endFill();
		fill.graphics.beginFill(color);
		fill.graphics.drawRoundRect(1, 1, w - 1, h - 1, 5, 5);
		fill.graphics.beginFill(0xffffff, 0.14);
		fill.graphics.drawRect(2, 2, w - 4, (h - 2) / 2);
		fill.graphics.endFill();
		addChild(fill);
		labelTf = Ui.text(size, 0xffffff, true, "left", 0, true);
		labelTf.x = 5;
		addChild(labelTf);
		valueTf = Ui.text(size, 0xffffff, true, valueAlign, valueAlign == "center" ? w : 0, true);
		addChild(valueTf);
		mouseChildren = false;
		if (label) set(0, label, "");
	}

	public function set(frac:Number, label:String, value:String):void {
		if (frac < 0) frac = 0;
		if (frac > 1) frac = 1;
		if (frac != lastFrac) { fill.scaleX = frac; lastFrac = frac; }
		if (label != lastLabel) {
			labelTf.text = label;
			labelTf.y = (h - labelTf.height) / 2;
			lastLabel = label;
			lastValue = "";
		}
		if (value != lastValue) {
			valueTf.htmlText = value;
			valueTf.y = (h - valueTf.height) / 2;
			valueTf.x = valueAlign == "center" ? 0 : labelTf.x + labelTf.width + 2;
			lastValue = value;
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
		graphics.beginFill(kind == "bag" ? 0x4a3e34 : 0x545454);
		graphics.drawRoundRect(0, 0, 48, 48, 10, 10);
		graphics.endFill();
		if (numbered) {
			numTf = Ui.text(24, 0x6e6e6e, true, "center", 48);
			numTf.text = String(idx + 1);
			numTf.y = 7;
			addChild(numTf);
		}
		icon.x = 6;
		icon.y = 6;
		addChild(icon);
		tierTf = Ui.text(13, 0xffffff, true, "right", 32, true);
		tierTf.x = 15;
		tierTf.y = 28;
		addChild(tierTf);
		mouseChildren = false;
		buttonMode = true;
	}

	public function setItem(it:Object):void {
		if (it == item) return;
		item = it;
		var bad:Boolean = it && !Data.canUse(it, Data.viewerClass);
		graphics.clear();
		graphics.lineStyle(1, 0x1a1a1a);
		graphics.beginFill(bad ? 0x7a3434 : kind == "bag" ? 0x4a3e34 : 0x545454);
		graphics.drawRoundRect(0, 0, 48, 48, 10, 10);
		graphics.endFill();
		if (numTf) numTf.visible = !it;
		if (!it) {
			icon.bitmapData = null;
			tierTf.text = "";
			return;
		}
		icon.bitmapData = Sprites.icon(it);
		icon.x = int((48 - icon.width) / 2);
		icon.y = int((48 - icon.height) / 2);
		var label:String = Data.tierLabel(it);
		tierTf.text = label;
		tierTf.textColor = Data.tierColor(it);
	}
}

class PotSlot extends Sprite {
	private var tf:TextField;
	private var key:TextField;
	private var last:int = -1;

	public function PotSlot(health:Boolean) {
		graphics.lineStyle(1, 0x1a1a1a);
		graphics.beginFill(0x545454);
		graphics.drawRoundRect(0, 0, 108, 32, 10, 10);
		graphics.endFill();
		var ic:Bitmap = new Bitmap(Sprites.icon(Data.makePotion(health ? "hp" : "mp")));
		ic.scaleX = ic.scaleY = 0.75;
		ic.x = 30; ic.y = 2;
		addChild(ic);
		tf = Ui.text(18, 0xffffff, true, "left", 0, true);
		tf.x = 62; tf.y = 3;
		addChild(tf);
		key = Ui.text(11, 0x9a9a9a, true);
		key.x = 6; key.y = 1;
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
