package realm {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;

	/**
	 * Testing tools (press ` or type /admin): spawn monsters and bosses, open dungeons,
	 * max your character and give yourself any item. Testers (a server role) get only the
	 * levelling, items and dungeons, for themselves.
	 */
	public class AdminMenu extends Sprite {
		public static const W:int = 540, H:int = 470;
		private static const ALL_TABS:Array = ["Player", "Monsters", "Bosses", "Dungeons", "Items", "Give", "Endgame"];
		/** What a tester sees (the rest is the admins'). */
		private static const TESTER_TABS:Array = ["Player", "Dungeons", "Items", "Give"];
		private var TABS:Array;
		private var tester:Boolean;

		private var g:Game;
		private var tab:int = 0;
		private var page:int = 0;
		private var body:Sprite;
		private var tabBtns:Sprite;

		public function AdminMenu(g:Game) {
			this.g = g;
			tester = g.isTester;
			TABS = tester ? TESTER_TABS : ALL_TABS;
			Ui.panel(graphics, 0, 0, W, H, 0x18181e, tester ? 0x50b080 : 0xd04040, 0.96);
			var title:TextField = Ui.text(20, tester ? 0x80e0a0 : 0xff6060, true, "left", 300, true);
			title.text = tester ? "Tester Menu" : "Admin Menu";
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
				var b:Sprite = Ui.button((i == tab ? "> " : "") + TABS[i], 70, 30, tabFn(i), 12);
				b.x = 14 + i * 74;
				b.alpha = i == tab ? 1 : 0.75;
				tabBtns.addChild(b);
			}
			body.removeChildren();
			switch (ALL_TABS.indexOf(TABS[tab])) {
				case 0: buildPlayer(); break;
				case 1: buildSpawnList(false); break;
				case 2: buildSpawnList(true); break;
				case 3: buildDungeons(); break;
				case 4: buildItems(); break;
				case 5: buildGive(); break;
				case 6: buildEndgame(); break;
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
			var col:Array = [14, 192, 370];
			var w:int = 170, y:int = 26;
			if (tester) {
				label("Level " + p.level + "   " + p.maxedCount + "/11 maxed", 14, 0, 0xffffff);
				btn("Max level (20)", col[0], y, w, function():void { g.adminMaxLevel(); show(0); });
				btn("Max all stats (11/11)", col[1], y, w, function():void { g.adminMaxStats(); show(0); });
				btn("+10 skill points", col[2], y, w, function():void { p.skillPoints += 10; g.msg("+10 skill points (star tab).", 0x80e0ff); });
				y += 36;
				btn("Max skill tree", col[0], y, w, function():void { g.adminMaxTree(); });
				btn("Max Ascension tree", col[1], y, w, function():void { g.adminMaxAscension(); });
				btn("Full heal + mana", col[2], y, w, function():void { p.hp = p.maxHp; p.mp = p.maxMp; p.pt = p.maxPt; });
				y += 48;
				label("<font color='#80e0a0'>You're a tester.</font> What you make here stays with you: you can't trade, sell, list, drop or bank items.", 14, y, 0xcccccc, 510);
				return;
			}
			label("Level " + p.level + "   " + p.maxedCount + "/11 maxed   God mode: " + (g.godMode ? "<font color='#80ff80'>ON</font>" : "off"), 14, 0, 0xffffff);
			btn("Max level (20)", col[0], y, w, function():void { g.adminMaxLevel(); show(0); });
			btn("Max all stats (11/11)", col[1], y, w, function():void { g.adminMaxStats(); show(0); });
			btn("God mode " + (g.godMode ? "OFF" : "ON"), col[2], y, w, function():void { g.godMode = !g.godMode; show(0); });
			y += 36;
			btn("Full heal + mana", col[0], y, w, function():void { p.hp = p.maxHp; p.mp = p.maxMp; p.pt = p.maxPt; });
			btn("+10 skill points", col[1], y, w, function():void { p.skillPoints += 10; g.msg("+10 skill points (star tab).", 0x80e0ff); });
			btn("Max potions (F/G)", col[2], y, w, function():void { p.hpPots = Player.MAX_POTS; p.mpPots = Player.MAX_POTS; });
			y += 36;
			btn("+10,000 gold", col[0], y, w, function():void { g.addGold(10000); });
			btn("+100 Aether", col[1], y, w, function():void { g.addOnrane(100); });
			btn("+5,000 account fame", col[2], y, w, function():void { Save.data.fame = int(Save.data.fame || 0) + 5000; Save.flush(); g.msg("+5,000 account fame (Fame Store).", 0xff9a2e); });
			y += 36;
			btn("Give backpack", col[0], y, w, function():void { p.backpack = true; while (p.inv.length < 16) p.inv.push(null); });
			btn("Clear inventory", col[1], y, w, function():void { for (var i:int = 0; i < p.inv.length; i++) p.inv[i] = null; });
			btn("Hatch a pet", col[2], y, w, function():void { Save.data.pet = Data.hatchPet(); Save.data.pet.level = 30; Save.flush(); g.msg("You got a level 30 " + Save.data.pet.name + ".", 0x60c0ff); });
			y += 36;
			btn("Max skill tree", col[0], y, w, function():void { g.adminMaxTree(); });
			btn("Max Ascension tree", col[1], y, w, function():void { g.adminMaxAscension(); });
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
			var y0:int = 22;
			for (var i:int = 0; i < Data.DUNGEONS.length; i++) {
				var d:Object = Data.DUNGEONS[i];
				var col:int = i % 2, row:int = int(i / 2);
				var x:int = 14 + col * 262, y:int = y0 + row * 20;
				label("<font color='" + Ui.hex(d.color) + "'>" + d.name + "</font>", x, y + 2, 0xffffff, 150);
				btn("Portal", x + 146, y, 54, portalFn(i), 10, 18);
				btn("Enter", x + 204, y, 50, enterFn(i), 10, 18);
			}
			var yy:int = y0 + Math.ceil(Data.DUNGEONS.length / 2) * 20 + 8;
			for (var r:int = 0; r < Bosses.RAIDS.length; r++) {
				btn("Raid: " + Bosses.RAIDS[r].name, 14 + r * 172, yy, 166, raidFn(r), 11, 26);
				btn("Heroic", 14 + r * 172, yy + 30, 166, raidFn(r, true), 11, 22);
			}
			yy += 58;
			btn("Dark Elder's Chamber", 14, yy, 200, function():void { g.adminEnterArena(); });
			btn("Realm portal", 220, yy, 140, function():void { g.adminRealmPortal(); });
			btn("Raid keys", 366, yy, 120, function():void { g.adminGiveKeys(); });
		}

		private function raidFn(i:int, heroic:Boolean = false):Function {
			return function():void { g.adminEnterRaid(i, heroic); g.toggleAdmin(); };
		}

		private function bossNames(d:Object):String {
			var ids:Array = (d.guardians || []).concat(d.trio || []).concat(d.boss ? [d.boss] : []);
			var names:Array = [];
			for each (var id:String in ids) names.push(String(Data.ENEMIES[id].name).split(" ")[0].replace(",", ""));
			return names.join(", ") + (d.toElder ? ", then Azrakor" : "");
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
				for (var k:int = 0; k < rar.length; k++) btn(Data.RARITY_LABELS[rar[k]], 84 + 8 * 36 + 4 + k * 31, y, 30, itemFn(r, 7, rar[k]), 11, 28);
			}
			var y2:int = 26 + 4 * 34 + 10;
			label("Potions and materials", 14, y2, 0xffd75e);
			y2 += 22;
			btn("HP potion", 14, y2, 100, function():void { g.giveItem(Data.makePotion("hp")); });
			btn("MP potion", 120, y2, 100, function():void { g.giveItem(Data.makePotion("mp")); });
			btn("Star Shard", 226, y2, 100, function():void { g.giveItem(Data.makeSor()); });
			btn("Bonded set", 332, y2, 100, function():void { for (var s:int = 0; s < 4; s++) g.giveItem(Data.makeForSlot(cls, s, 7, "st")); });
			btn("Random SF", 438, y2, 88, function():void { g.giveItem(Data.makeForSlot(cls, int(Math.random() * 4), 7, "lg")); });
			y2 += 34;
			btn("Random Godly", 170, y2, 150, function():void {
				var classes:Array = Data.CLASS_ORDER;
				g.giveItem(Godly.make(classes[int(Math.random() * classes.length)], int(Math.random() * 4)));
			});
			btn("My Godly set", 326, y2, 150, function():void {
				for (var gs:int = 0; gs < 4; gs++) g.giveItem(Godly.make(cls.id, gs));
			});
			btn("Random unique", 14, y2, 150, function():void {
				var ids:Array = [];
				for (var u:String in Uniques.ALL) ids.push(u);
				g.giveItem(Uniques.make(ids[int(Math.random() * ids.length)]));
			});
			y2 += 40;
			label("Stat potions", 14, y2, 0xffd75e);
			y2 += 22;
			for (var i:int = 0; i < Data.STATS.length; i++) {
				btn(Data.STAT_SHORT[Data.STATS[i]], 14 + (i % 6) * 86, y2 + int(i / 6) * 32, 82, statFn(Data.STATS[i]), 12, 28);
			}
		}

		// ------------------------------------------------------------ Give: any item by name, to you or a player
		private var query:String = "", toName:String = "", toCount:String = "1";

		/** A text box for the menu: typing in it never reaches the game. */
		private function field(x:int, y:int, w:int, value:String, max:int, onChange:Function):TextField {
			var f:TextField = Ui.input(w, value, max, 13);
			f.x = x; f.y = y;
			f.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void { e.stopPropagation(); if (e.keyCode == 27) g.toggleAdmin(); });
			f.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent):void { e.stopPropagation(); });
			f.addEventListener(Event.CHANGE, function(e:Event):void { onChange(f.text); });
			body.addChild(f);
			return f;
		}

		private var results:Sprite;

		private function buildGive():void {
			label("Any item by name: uniques, Godly, potions, runes, keys, <b>T7 Armor</b>, <b>Starforged Ring</b>...", 14, 0, 0xcccccc, 512);
			label("Item", 14, 34, 0xffd75e, 60);
			var q:TextField = field(60, 32, 290, query, 40, function(t:String):void { query = t; listResults(); });
			if (!tester) {
				label("Player", 362, 34, 0xffd75e, 60);
				field(412, 32, 80, toName, 12, function(t:String):void { toName = t; });
				field(498, 32, 30, toCount, 2, function(t:String):void { toCount = t; });
			}
			label("<font size='11'>" + (tester ? "Me: into your inventory." : "Me: into your inventory. Player: sends /give (they must be online; the count is how many).") + "</font>", 14, 58, 0x999999, 512);
			results = new Sprite();
			results.y = 78;
			body.addChild(results);
			listResults();
			if (stage) stage.focus = q;
			// quick picks for the newer things
			var y:int = 306;
			label("Quick", 14, y + 5, 0xffd75e, 60);
			btn("Evolution Stone", 60, y, 116, function():void { g.giveItem(Data.makeStone()); }, 11, 26);
			btn("Random rune", 180, y, 100, function():void { g.giveItem(Data.makeRune(Data.STATS[int(Math.random() * Data.STATS.length)])); }, 11, 26);
			btn("Cursed gear", 284, y, 100, function():void { g.giveItem(Data.makeCursed(g.player.cls)); }, 11, 26);
			btn("Star Shard", 388, y, 90, function():void { g.giveItem(Data.makeSor()); }, 11, 26);
			y += 30;
			btn("Abyss uniques", 60, y, 116, function():void { for each (var u:String in Data.DEEP_UNIQUES) g.giveItem(Uniques.make(u)); }, 11, 26);
			btn("Siege uniques", 180, y, 100, function():void { for each (var u2:String in ["siegebreaker", "warlords_banner", "rampart_plate"]) g.giveItem(Uniques.make(u2)); }, 11, 26);
			btn("All raid keys", 284, y, 100, function():void { g.adminGiveKeys(); }, 11, 26);
		}

		private function listResults():void {
			if (!results) return;
			results.removeChildren();
			var found:Array = Data.findCatalog(query, 14);
			if (!query) { var hint:TextField = Ui.text(12, 0x888888, false, "left", 500, true); hint.text = "Start typing an item's name..."; results.addChild(hint); return; }
			if (!found.length) { var none:TextField = Ui.text(12, 0xff8080, false, "left", 500, true); none.text = "Nothing called that."; results.addChild(none); return; }
			for (var i:int = 0; i < found.length; i++) {
				var e:Object = found[i];
				var x:int = 14 + (i % 2) * 260, y:int = int(i / 2) * 30;
				var it:Object = Data.makeCatalogItem(e, g.player.cls);
				var nm:TextField = Ui.text(12, it ? (Data.RARITY_COLORS[it.rarity] || 0xffffff) : 0xffffff, true, "left", 150, true);
				nm.text = e.name;
				nm.x = x; nm.y = y + 5;
				results.addChild(nm);
				var me:Sprite = Ui.button("Me", 40, 24, giveMeFn(e), 11);
				me.x = x + 156; me.y = y;
				results.addChild(me);
				if (tester) continue;
				var pl:Sprite = Ui.button("Player", 54, 24, givePlayerFn(e), 11);
				pl.x = x + 198; pl.y = y;
				results.addChild(pl);
			}
		}

		private function giveMeFn(e:Object):Function {
			return function():void {
				var it:Object = Data.makeCatalogItem(e, g.player.cls);
				if (it) { g.giveItem(it); g.msg("Gave you " + it.name + ".", 0x80ff80); }
			};
		}

		private function givePlayerFn(e:Object):Function {
			return function():void {
				var who:String = toName.replace(/\s/g, "");
				if (!who) { g.msg("Type the player's name in the Player box first.", 0xff8080); return; }
				var n:int = Math.max(1, Math.min(16, int(toCount) || 1));
				g.runCommand("/give " + who + " " + n + " " + e.name);
			};
		}

		// ------------------------------------------------------------ Endgame: the newer systems
		private function buildEndgame():void {
			var col:Array = [14, 190, 366], w:int = 168, y:int = 0;
			label("Realm Siege and the Endless Abyss", 14, y, 0xffd75e);
			y += 22;
			btn("Start a Realm Siege now", col[0], y, w, function():void { g.runCommand("/siege"); });
			btn("Enter the Endless Abyss", col[1], y, w, function():void { g.toggleAdmin(); g.enterDeep(0); });
			btn("Abyss board", col[2], y, w, function():void { g.toggleAbyss(); });
			y += 40;
			label("Your hero", 14, y, 0xffd75e);
			y += 22;
			btn("Max hero (to ascend)", col[0], y, w, function():void { g.runCommand("/maxhero"); });
			btn("Ascension window", col[1], y, w, function():void { g.toggleAdmin(); g.toggleAscend(); });
			btn("The Oracle", col[2], y, w, function():void { g.toggleAdmin(); g.toggleOracle(); });
			y += 34;
			btn("Pets window", col[0], y, w, function():void { g.toggleAdmin(); g.togglePet(); });
			btn("+200 pet XP", col[1], y, w, function():void { g.runCommand("/give " + g.player.name + " 200 petxp"); });
			btn("Realm Leaders", col[2], y, w, function():void { g.runCommand("/leaders"); });
			y += 40;
			label("Moderation", 14, y, 0xffd75e);
			y += 22;
			btn("Flagged players", col[0], y, w, function():void { g.toggleAdmin(); g.runCommand("/flags"); });
			btn("Bug reports", col[1], y, w, function():void { g.toggleAdmin(); g.runCommand("/bugs"); });
			btn("Server stats", col[2], y, w, function():void { g.runCommand("/stats"); });
			y += 34;
			btn("Staff list", col[0], y, w, function():void { g.runCommand("/mods"); });
			btn("VIP list", col[1], y, w, function():void { g.runCommand("/vips"); });
			btn("Who's online", col[2], y, w, function():void { g.runCommand("/who"); });
			y += 40;
			label("<font size='11'>Also: /give name [count] item, /vip name [days], /mod name, /rename, /heroname, /maxhero name, /siege, /realms n</font>", 14, y, 0x999999, 512);
		}

		private function itemFn(slot:int, tier:int, rarity:String):Function {
			return function():void { g.giveItem(Data.makeForSlot(g.player.cls, slot, tier, rarity)); };
		}

		private function statFn(s:String):Function {
			return function():void { g.giveItem(Data.makePotion("stat", s)); };
		}
	}
}
