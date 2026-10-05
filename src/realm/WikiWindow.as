package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;

	/** The boss wiki (book button / K): every boss, where to find it and what it drops. */
	public class WikiWindow extends Sprite {
		public static const W:int = 640, H:int = 560;
		private static const PER_PAGE:int = 6;
		private static const ROW:int = 66;
		private static const TABS:Array = ["Realm Events", "Dungeons", "Hard Dungeons", "Finales", "Raids"];
		private static const LOOT:Array = [
			"All events also drop: tier 6-7 gear, stat potions, sometimes a dungeon portal.",
			"All dungeon bosses also drop: tiered or Bonded set gear, stat potions.",
			"All also drop: Bonded and Eldritch gear, stat potions, a chance of Starforged. GD items: 1 in 5,000.",
			"All finales also drop: Eldritch gear, stat potions, Starforged / Primordial chance. GD items: 1 in 5,000.",
			"All raid bosses also drop: Eldritch and Bonded gear, the best SF / PR odds. GD items: 1 in 5,000."
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
			title.text = "Boss Wiki";
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
			return [events, dungeons, hard, finales, raids];
		}

		private function show(t:int):void {
			if (t != tab) page = 0;
			tab = t;
			tabBar.removeChildren();
			for (var i:int = 0; i < TABS.length; i++) {
				var b:Sprite = Ui.button((i == tab ? "> " : "") + TABS[i], 118, 30, tabFn(i), 13);
				b.x = i * 123;
				b.alpha = i == tab ? 1 : 0.7;
				tabBar.addChild(b);
			}
			body.removeChildren();
			tip.visible = false;
			var list:Array = lists[tab];
			var pages:int = Math.max(1, Math.ceil(list.length / PER_PAGE));
			if (page >= pages) page = pages - 1;
			for (var k:int = 0; k < PER_PAGE; k++) {
				var idx:int = page * PER_PAGE + k;
				if (idx >= list.length) break;
				row(list[idx], k * ROW);
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
