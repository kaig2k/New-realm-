package realm {
	import flash.display.Sprite;
	import flash.text.TextField;

	/**
	 * Testing tools (press ` or type /admin): spawn monsters and bosses, open dungeons,
	 * max your character and give yourself any item.
	 */
	public class AdminMenu extends Sprite {
		public static const W:int = 540, H:int = 470;
		private static const TABS:Array = ["Player", "Monsters", "Bosses", "Dungeons", "Items"];

		private var g:Game;
		private var tab:int = 0;
		private var page:int = 0;
		private var body:Sprite;
		private var tabBtns:Sprite;

		public function AdminMenu(g:Game) {
			this.g = g;
			Ui.panel(graphics, 0, 0, W, H, 0x18181e, 0xd04040, 0.96);
			var title:TextField = Ui.text(20, 0xff6060, true, "left", 300, true);
			title.text = "Admin Menu";
			title.x = 14; title.y = 8;
			addChild(title);
			var hint:TextField = Ui.text(12, 0x999999, false, "right", 300, true);
			hint.text = "` or Esc to close";
			hint.x = W - 350; hint.y = 14;
			addChild(hint);
			var close:Sprite = Ui.button("X", 30, 26, function():void { g.toggleAdmin(); }, 14);
			close.x = W - 40; close.y = 8;
			addChild(close);
			tabBtns = new Sprite();
			tabBtns.y = 42;
			addChild(tabBtns);
			body = new Sprite();
			body.y = 80;
			addChild(body);
			show(0);
		}

		private function show(t:int):void {
			if (t != tab) page = 0;
			tab = t;
			tabBtns.removeChildren();
			for (var i:int = 0; i < TABS.length; i++) {
				var b:Sprite = Ui.button((i == tab ? "> " : "") + TABS[i], 100, 30, tabFn(i), 14);
				b.x = 14 + i * 104;
				b.alpha = i == tab ? 1 : 0.75;
				tabBtns.addChild(b);
			}
			body.removeChildren();
			switch (tab) {
				case 0: buildPlayer(); break;
				case 1: buildSpawnList(false); break;
				case 2: buildSpawnList(true); break;
				case 3: buildDungeons(); break;
				case 4: buildItems(); break;
			}
		}

		private function tabFn(i:int):Function {
			return function():void { show(i); };
		}

		private function btn(label:String, x:int, y:int, w:int, fn:Function, size:int = 13, h:int = 28):Sprite {
			var b:Sprite = Ui.button(label, w, h, function():void { fn(); refresh(); }, size);
			b.x = x; b.y = y;
			body.addChild(b);
			return b;
		}

		private function label(text:String, x:int, y:int, color:uint = 0xcccccc, w:int = 500):void {
			var tf:TextField = Ui.text(13, color, true, "left", w, true);
			tf.htmlText = text;
			tf.x = x; tf.y = y;
			body.addChild(tf);
		}

		private function refresh():void {
			g.adminRefresh();
		}

		// ------------------------------------------------------------ player
		private function buildPlayer():void {
			var p:Player = g.player;
			label("Level " + p.level + "   " + p.maxedCount + "/11 maxed   God mode: " + (g.godMode ? "<font color='#80ff80'>ON</font>" : "off"), 14, 0, 0xffffff);
			var col:Array = [14, 192, 370];
			var w:int = 170, y:int = 26;
			btn("Max level (20)", col[0], y, w, function():void { g.adminMaxLevel(); show(0); });
			btn("Max all stats (11/11)", col[1], y, w, function():void { g.adminMaxStats(); show(0); });
			btn("God mode " + (g.godMode ? "OFF" : "ON"), col[2], y, w, function():void { g.godMode = !g.godMode; show(0); });
			y += 36;
			btn("Full heal + mana", col[0], y, w, function():void { p.hp = p.maxHp; p.mp = p.maxMp; p.pt = p.maxPt; });
			btn("+10 skill points", col[1], y, w, function():void { p.skillPoints += 10; g.msg("+10 skill points (star tab).", 0x80e0ff); });
			btn("Max potions (F/G)", col[2], y, w, function():void { p.hpPots = Player.MAX_POTS; p.mpPots = Player.MAX_POTS; });
			y += 36;
			btn("+10,000 gold", col[0], y, w, function():void { g.addGold(10000); });
			btn("+100 Onrane", col[1], y, w, function():void { g.addOnrane(100); });
			btn("+5,000 account fame", col[2], y, w, function():void { Save.data.fame = int(Save.data.fame || 0) + 5000; Save.flush(); g.msg("+5,000 account fame (Fame Store).", 0xff9a2e); });
			y += 36;
			btn("Give backpack", col[0], y, w, function():void { p.backpack = true; while (p.inv.length < 16) p.inv.push(null); });
			btn("Clear inventory", col[1], y, w, function():void { for (var i:int = 0; i < p.inv.length; i++) p.inv[i] = null; });
			btn("Hatch a pet", col[2], y, w, function():void { Save.data.pet = Data.hatchPet(); Save.data.pet.level = 30; Save.flush(); g.msg("You got a level 30 " + Save.data.pet.name + ".", 0x60c0ff); });
			y += 48;
			label("World", 14, y, 0xffd75e);
			y += 22;
			btn("Kill all monsters", col[0], y, w, function():void { g.adminKillAll(); });
			btn("Teleport: Godlands", col[1], y, w, function():void { g.runCommand("/glands"); });
			btn("Go to the Nexus", col[2], y, w, function():void { g.nexus(); });
			y += 36;
			btn("Finish realm events", col[0], y, w, function():void { g.adminFinishEvents(); });
			btn("Spawn an event now", col[1], y, w, function():void { g.adminSpawnEvent(); });
			btn("Reveal minimap", col[2], y, w, function():void { g.adminRevealMap(); });
		}

		// ------------------------------------------------------------ monsters / bosses
		private function spawnIds(bosses:Boolean):Array {
			var list:Array = [];
			for (var id:String in Data.ENEMIES) {
				var d:Object = Data.ENEMIES[id];
				if ((d.ai == "boss") != bosses) continue;
				list.push({id: id, name: d.name, hp: d.hp});
			}
			list.sortOn("hp", Array.NUMERIC);
			return list;
		}

		private function buildSpawnList(bosses:Boolean):void {
			var list:Array = spawnIds(bosses);
			var per:int = 30, pages:int = Math.ceil(list.length / per);
			if (page >= pages) page = 0;
			label((bosses ? "Bosses" : "Monsters") + " spawn in front of you (toward the mouse). Sorted by health.  Page " + (page + 1) + "/" + pages, 14, 0);
			for (var i:int = 0; i < per && page * per + i < list.length; i++) {
				var e:Object = list[page * per + i];
				btn(e.name, 14 + (i % 3) * 172, 24 + int(i / 3) * 30, 168, spawnFn(e.id, bosses), 12, 26);
			}
			if (pages > 1) {
				btn("< Prev", 14, 330, 100, function():void { page = (page + pages - 1) % pages; show(tab); });
				btn("Next >", 120, 330, 100, function():void { page = (page + 1) % pages; show(tab); });
			}
			if (!bosses) btn("Spawn 5 random", 380, 330, 146, function():void {
				for (var k:int = 0; k < 5; k++) g.adminSpawn(list[int(Math.random() * list.length)].id, false);
			});
		}

		private function spawnFn(id:String, boss:Boolean):Function {
			return function():void { g.adminSpawn(id, boss); };
		}

		// ------------------------------------------------------------ dungeons
		private function buildDungeons():void {
			label("Open a portal next to you, or jump straight in.", 14, 0);
			var y:int = 24;
			for (var i:int = 0; i < Data.DUNGEONS.length; i++) {
				var d:Object = Data.DUNGEONS[i];
				label("<font color='" + Ui.hex(d.color) + "'>" + d.name + "</font>  <font size='11' color='#888888'>" + Data.ENEMIES[d.boss].name + "</font>", 14, y + 4, 0xffffff, 300);
				btn("Portal", 330, y, 90, portalFn(i), 12, 24);
				btn("Enter", 426, y, 90, enterFn(i), 12, 24);
				y += 27;
			}
			y += 8;
			btn("Dark Elder's Chamber", 14, y, 200, function():void { g.adminEnterArena(); });
			btn("Realm portal", 220, y, 140, function():void { g.adminRealmPortal(); });
		}

		private function portalFn(i:int):Function {
			return function():void { g.adminDungeonPortal(i); };
		}

		private function enterFn(i:int):Function {
			return function():void { g.adminEnterDungeon(i); g.toggleAdmin(); };
		}

		// ------------------------------------------------------------ items
		private function buildItems():void {
			var cls:Object = g.player.cls;
			label("Items for your " + cls.name + " go into your inventory (or a bag at your feet when full).", 14, 0);
			var rows:Array = ["Weapon", "Ability", "Armor", "Ring"];
			var caps:Array = [7, 6, 7, 5];
			var rar:Array = ["ut", "st", "fb", "lg", "ar"];
			for (var r:int = 0; r < 4; r++) {
				var y:int = 26 + r * 34;
				label(rows[r], 14, y + 5, 0xffffff, 80);
				for (var t:int = 0; t <= caps[r]; t++) btn("T" + t, 84 + t * 36, y, 34, itemFn(r, t, null), 12, 28);
				for (var k:int = 0; k < rar.length; k++) btn(String(rar[k]).toUpperCase(), 84 + 8 * 36 + 4 + k * 31, y, 30, itemFn(r, 7, rar[k]), 11, 28);
			}
			var y2:int = 26 + 4 * 34 + 10;
			label("Potions and materials", 14, y2, 0xffd75e);
			y2 += 22;
			btn("HP potion", 14, y2, 100, function():void { g.giveItem(Data.makePotion("hp")); });
			btn("MP potion", 120, y2, 100, function():void { g.giveItem(Data.makePotion("mp")); });
			btn("Sor Crystal", 226, y2, 100, function():void { g.giveItem(Data.makeSor()); });
			btn("Full ST set", 332, y2, 100, function():void { for (var s:int = 0; s < 4; s++) g.giveItem(Data.makeForSlot(cls, s, 7, "st")); });
			btn("Random LG", 438, y2, 88, function():void { g.giveItem(Data.makeForSlot(cls, int(Math.random() * 4), 7, "lg")); });
			y2 += 40;
			label("Stat potions", 14, y2, 0xffd75e);
			y2 += 22;
			for (var i:int = 0; i < Data.STATS.length; i++) {
				btn(Data.STAT_SHORT[Data.STATS[i]], 14 + (i % 6) * 86, y2 + int(i / 6) * 32, 82, statFn(Data.STATS[i]), 12, 28);
			}
		}

		private function itemFn(slot:int, tier:int, rarity:String):Function {
			return function():void { g.giveItem(Data.makeForSlot(g.player.cls, slot, tier, rarity)); };
		}

		private function statFn(s:String):Function {
			return function():void { g.giveItem(Data.makePotion("stat", s)); };
		}
	}
}
