package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;

	/**
	 * The wiki (book button / K): every boss, where to find it and what it
	 * drops; every class's three abilities; and a guide to how things work.
	 */
	public class WikiWindow extends Sprite {
		public static const W:int = 640, H:int = 560;
		private static const PER_PAGE:int = 6;
		private static const ROW:int = 66;
		private static const TABS:Array = ["Events", "Dungeons", "Hard Dgns", "Finales", "Raids", "Abilities", "Guide"];
		private static const ABILITY_TAB:int = 5, GUIDE_TAB:int = 6;
		private static const LOOT:Array = [
			"Event uniques are Eldritch; the biggest events (1,800+ XP) drop Starforged ones. Also: tier 6-7 gear, stat potions, dungeon portals.",
			"Uniques: Runed from the early dungeons, Eldritch from the rest. Also: tiered or Bonded set gear, stat potions.",
			"Uniques here are Starforged. Also: Bonded and Eldritch gear, stat potions, a chance of Starforged. GD items: 1 in 3,000.",
			"Finale uniques are Starforged. Also: Eldritch gear, stat potions, Starforged / Primordial chance. GD items: 1 in 3,000.",
			"Raid uniques: Starforged, and Primordial from each raid's final boss. Also the best SF / PR odds. GD items: 1 in 3,000.",
			"Ability items drop holding one of their class's three abilities. Hover an icon for its full description.",
			""
		];

		/** The Guide tab, one page at a time. */
		private static const GUIDE:Array = [
			"<font size='15' color='#ffd75e'><b>Item rarities</b></font>\n" +
			"Tiered gear goes from T0 to T7. Above that, from common to rarest: " +
			"<font color='#6aa8ff'>Runed</font>, <font color='#4ee08a'>Bonded</font> (class sets, 4-piece bonus), " +
			"<font color='#c85cff'>Eldritch</font>, <font color='#ffc23a'>Starforged</font>, <font color='#ff5533'>Primordial</font> and " +
			"<font color='#fff6e0'>Godly</font>. Godly items drop 1 in 3,000 from the bosses that carry them (a little more with Bounty).\n\n" +
			"<font size='15' color='#ffd75e'><b>Boss uniques</b></font>\n" +
			"Every boss has its own unique items, and their rarity matches the boss: Runed from the early dungeons, Eldritch from the " +
			"other dungeons and realm events, Starforged from the biggest events, endgame dungeons, realm finales and raid bosses, and " +
			"Primordial from the final boss of each raid. Rarer uniques have stronger stats and damage. Uniques never change: they " +
			"can't be forged or rerolled.\n\n" +
			"<font size='15' color='#ffd75e'><b>The Starforge (Nexus, east)</b></font>\n" +
			"<b>Forge</b>: a Runed, Bonded or Eldritch item + 1 Star Shard + 100 Aether = a Starforged item of the same kind.\n" +
			"<b>New prefix</b>: 400 gold gives any weapon a different prefix (Swift, Farshot, Scattershot...); the rest of the weapon stays.\n" +
			"<b>Reroll stats</b>: 60 Aether rolls the bonus stats (and a weapon's passive) of special-rarity gear again.",

			"<font size='15' color='#ffd75e'><b>Abilities</b></font>\n" +
			"Every class has three abilities (see the Abilities tab). An ability item holds one of them: its name says which, " +
			"like a <i>Comet Spell of Storms</i> (Lightning Strike). Each ability costs MP and has its own cooldown, shown on your ability " +
			"slot as a dark sweep with the seconds left. Stronger abilities take longer to come back. Higher tiers make the effect stronger.\n\n" +
			"<font size='15' color='#ffd75e'><b>Stats and potions</b></font>\n" +
			"Stat potions raise a stat by 1 (HP and MP by 5) up to your class's maximum. The stats tab shows how much each stat " +
			"has <b>left to max</b>. You can drink a potion straight from a loot bag: shift+click it (a plain click works when your " +
			"inventory is full).\n\n" +
			"<font size='15' color='#ffd75e'><b>Skill points</b></font>\n" +
			"One per level up to 20 (press T for the tree). After that you keep earning them with XP: the first takes 1,000 XP and each " +
			"one after takes 300 XP more than the last.\n\n" +
			"<font size='15' color='#ffd75e'><b>Pets (Pet Yard, Nexus)</b></font>\n" +
			"Your pet follows you, heals HP and MP every few seconds and shoots the nearest monster about once a second. " +
			"Feed it to level it up: its healing and damage grow with its level, and rare and legendary pets hit harder."
		];

		private var g:Game;
		private var tab:int = 0;
		private var page:int = 0;
		private var lists:Array;
		private var body:Sprite = new Sprite();
		private var tabBar:Sprite = new Sprite();
		private var tip:Tooltip = new Tooltip();

		public function WikiWindow(g:Game) {
			this.g = g;
			lists = collect();
			Ui.panel(graphics, 0, 0, W, H, 0x1c1c22, 0xc8a050, 0.97);
			var title:TextField = Ui.text(22, Ui.GOLD, true, "left", 300, true);
			title.text = "Wiki";
			title.x = 16; title.y = 8;
			addChild(title);
			var close:Sprite = Ui.button("X", 30, 28, function():void { g.toggleWiki(); }, 14);
			close.x = W - 42; close.y = 10;
			addChild(close);
			tabBar.x = 12; tabBar.y = 46;
			addChild(tabBar);
			body.y = 84;
			addChild(body);
			addChild(tip);
			show(0);
		}

		/** Bosses by category, in the order you'd meet them. */
		private static function collect():Array {
			var events:Array = [], dungeons:Array = [], hard:Array = [], finales:Array = [], raids:Array = [];
			var seen:Object = {};
			var add:Function = function(list:Array, id:String, where:String):void {
				if (seen[id] || !Data.ENEMIES[id]) return;
				seen[id] = true;
				list.push({id: id, where: where});
			};
			for each (var ev:String in Data.EVENTS) add(events, ev, "Realm event (Godlands and highlands)");
			for each (var d:Object in Data.DUNGEONS) {
				var finale:Boolean = Bosses.FINALES.indexOf(d.id) >= 0;
				var list:Array = finale ? finales : d.hard ? hard : dungeons;
				var where:String = d.name + (finale ? " (when a realm closes)" : "");
				for each (var gid:String in d.guardians || []) add(list, gid, where + ", guardian");
				for each (var tid:String in d.trio || []) add(list, tid, where);
				if (d.boss) add(list, d.boss, where);
				if (d.toElder) add(finales, "elder", "Dark Elder's Chamber (after the Citadel)");
			}
			for each (var r:Object in Bosses.RAIDS) {
				for (var s:int = 0; s < r.stages.length; s++) {
					for each (var rid:String in r.stages[s]) {
						if (rid.indexOf("sentinel_") == 0 && rid != "sentinel_a") continue;
						if (rid == "zealot_b") continue;
						add(raids, rid, r.name + ", " + (s == r.stages.length - 1 ? "final stage" : "stage " + (s + 1)));
					}
				}
			}
			// the zealot pair and sentinel trio share one entry each; show their partner's drops too
			var abilities:Array = [];
			for each (var cid:String in Data.CLASS_ORDER) abilities.push({cls: cid});
			return [events, dungeons, hard, finales, raids, abilities, GUIDE];
		}

		private function show(t:int):void {
			if (t != tab) page = 0;
			tab = t;
			tabBar.removeChildren();
			for (var i:int = 0; i < TABS.length; i++) {
				var b:Sprite = Ui.button((i == tab ? "> " : "") + TABS[i], 84, 30, tabFn(i), 12);
				b.x = i * 88;
				b.alpha = i == tab ? 1 : 0.7;
				tabBar.addChild(b);
			}
			body.removeChildren();
			body.graphics.clear();
			tip.visible = false;
			var list:Array = lists[tab];
			var per:int = tab == GUIDE_TAB ? 1 : PER_PAGE;
			var pages:int = Math.max(1, Math.ceil(list.length / per));
			if (page >= pages) page = pages - 1;
			if (tab == GUIDE_TAB) {
				var gt:TextField = Ui.text(12, 0xd8d8e0, false, "left", W - 36);
				gt.htmlText = GUIDE[page];
				gt.x = 18; gt.y = 0;
				body.addChild(gt);
			} else for (var k:int = 0; k < PER_PAGE; k++) {
				var idx:int = page * PER_PAGE + k;
				if (idx >= list.length) break;
				if (tab == ABILITY_TAB) abilityRow(list[idx].cls, k * ROW);
				else row(list[idx], k * ROW);
			}
			var note:TextField = Ui.text(12, 0x9a9aaa, true, "left", W - 32, true);
			note.text = LOOT[tab];
			note.x = 16; note.y = PER_PAGE * ROW + 4;
			body.addChild(note);
			if (pages > 1) {
				var prev:Sprite = Ui.button("<", 36, 26, function():void { page = (page + pages - 1) % pages; show(tab); }, 14);
				prev.x = W - 150; prev.y = PER_PAGE * ROW + 26;
				body.addChild(prev);
				var pt:TextField = Ui.text(13, 0xcccccc, true, "center", 60);
				pt.text = (page + 1) + " / " + pages;
				pt.x = W - 110; pt.y = PER_PAGE * ROW + 30;
				body.addChild(pt);
				var next:Sprite = Ui.button(">", 36, 26, function():void { page = (page + 1) % pages; show(tab); }, 14);
				next.x = W - 52; next.y = PER_PAGE * ROW + 26;
				body.addChild(next);
			}
		}

		private function tabFn(i:int):Function { return function():void { show(i); }; }

		/** One class: its portrait and its three abilities, with their cost and cooldown. */
		private function abilityRow(clsId:String, y:int):void {
			var c:Object = Data.CLASSES[clsId];
			body.graphics.lineStyle(1, 0x3a3a44);
			body.graphics.moveTo(12, y + ROW - 2);
			body.graphics.lineTo(W - 12, y + ROW - 2);
			body.graphics.lineStyle();
			var bd:BitmapData = Sprites.get(clsId);
			var pic:Bitmap = new Bitmap(bd);
			var sc:Number = Math.min(1, 56 / Math.max(bd.width, bd.height));
			pic.scaleX = pic.scaleY = sc;
			pic.x = 16 + (56 - bd.width * sc) / 2; pic.y = y + 2 + (56 - bd.height * sc) / 2;
			body.addChild(pic);
			var name:TextField = Ui.text(15, 0xffffff, true, "left", 120, true);
			name.text = c.name;
			name.x = 80; name.y = y + 4;
			body.addChild(name);
			var sub:TextField = Ui.text(11, 0x9a9aaa, true, "left", 120, true);
			sub.text = c.abilityType.charAt(0).toUpperCase() + c.abilityType.substr(1) + " items";
			sub.x = 80; sub.y = y + 26;
			body.addChild(sub);
			var ids:Array = Data.ABILITY_SETS[c.abilityType];
			for (var i:int = 0; i < ids.length; i++) {
				var ab:Object = Data.ABILITIES[ids[i]];
				var x0:int = 200 + i * 146;
				var sl:ItemSlot = new ItemSlot(i);
				sl.setItem(Data.makeAbility(c.abilityType, 5, null, ids[i]));
				sl.x = x0; sl.y = y + 6;
				sl.addEventListener(MouseEvent.ROLL_OVER, over);
				sl.addEventListener(MouseEvent.ROLL_OUT, function(ev:MouseEvent):void { tip.visible = false; });
				body.addChild(sl);
				var at:TextField = Ui.text(11, 0xe8e0a0, true, "left", 92, true);
				at.htmlText = ab.name + "\n<font color='#80a0ff'>" + ab.cost + " MP</font>  <font color='#b0b0b8'>" + ab.cd + "s</font>";
				at.x = x0 + 52; at.y = y + 8;
				body.addChild(at);
			}
		}

		private function row(e:Object, y:int):void {
			var d:Object = Data.ENEMIES[e.id];
			body.graphics.lineStyle(1, 0x3a3a44);
			body.graphics.moveTo(12, y + ROW - 2);
			body.graphics.lineTo(W - 12, y + ROW - 2);
			body.graphics.lineStyle();
			// portrait, scaled to fit
			var bd:BitmapData = Sprites.get(d.spr);
			var pic:Bitmap = new Bitmap(bd);
			var sc:Number = Math.min(1, 56 / Math.max(bd.width, bd.height));
			pic.scaleX = pic.scaleY = sc;
			pic.x = 16 + (56 - bd.width * sc) / 2; pic.y = y + 2 + (56 - bd.height * sc) / 2;
			body.addChild(pic);
			var name:TextField = Ui.text(15, d.col || 0xffffff, true, "left", 300, true);
			name.text = d.name;
			name.x = 80; name.y = y + 4;
			body.addChild(name);
			var phases:int = d.phases ? d.phases.length : 1;
			var info:TextField = Ui.text(11, 0xb0b0b8, true, "left", 250, true);
			info.htmlText = e.where + "\n<font color='#808088'>" + Ui.commas(d.hp) + " HP  -  " + phases + " phase" + (phases == 1 ? "" : "s") + "</font>";
			info.x = 80; info.y = y + 26;
			body.addChild(info);
			// its unique drops
			var ids:Array = (d.uniques || []).concat();
			if (e.id == "zealot_a" && Data.ENEMIES.zealot_b.uniques) ids = ids.concat(Data.ENEMIES.zealot_b.uniques);
			var drops:Array = [];
			for each (var uid:String in ids) { var u:Object = Uniques.make(uid); if (u) drops.push(u); }
			for each (var gd:Array in d.godly || []) drops.push(Godly.make(gd[0], gd[1]));
			if (!drops.length) {
				var none:TextField = Ui.text(11, 0x707078, true, "right", 200, true);
				none.text = "No unique drops";
				none.x = W - 216; none.y = y + 22;
				body.addChild(none);
			}
			for (var i:int = 0; i < drops.length; i++) {
				var sl:ItemSlot = new ItemSlot(i);
				sl.setItem(drops[i]);
				sl.x = W - 16 - (drops.length - i) * 52;
				sl.y = y + 6;
				sl.addEventListener(MouseEvent.ROLL_OVER, over);
				sl.addEventListener(MouseEvent.ROLL_OUT, function(ev:MouseEvent):void { tip.visible = false; });
				body.addChild(sl);
			}
		}

		private function over(e:MouseEvent):void {
			var sl:ItemSlot = ItemSlot(e.currentTarget);
			if (!sl.item) return;
			tip.show(sl.item, "");
			var lp:Point = globalToLocal(sl.localToGlobal(new Point(0, 0)));
			tip.x = Math.max(4, lp.x - tip.width - 6);
			tip.y = Math.max(4, Math.min(H - tip.height - 4, lp.y - 10));
			setChildIndex(tip, numChildren - 1);
		}
	}
}
