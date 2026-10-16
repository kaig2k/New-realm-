package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldType;

	/** Title screen: scrolling realm backdrop, hero name and class selection. */
	public class Menu extends Sprite {
		[Embed(source="../../assets/branding/name_band.png")]
		private static const NAME_BAND:Class;
		private static const NAMES:Array = ["Ezra", "Vex", "Lyra", "Thorn", "Kael", "Mira", "Orin", "Sable", "Rook", "Nyx", "Bram", "Iris"];

		private var onPick:Function;
		private var onBack:Function;
		private var nameField:TextField;
		/** Under the class cards: the hovered class's description. */
		private var hoverTf:TextField;
		private var classLayer:Sprite;
		private var charLayer:Sprite;

		public function Menu(onPick:Function, onBack:Function = null, onCreate:Function = null) {
			this.onPick = onPick;
			this.onBack = onBack;
			addChild(new Backdrop(0.55));
			// Creator Tools are for the server's admins only (config.json "admins")
			if (onCreate != null && Online.connected && Online.welcome && Online.welcome.admin) {
				var cr:Sprite = Ui.button("Creator Tools", 170, 32, function():void { onCreate(); }, 15);
				cr.x = Ui.W - 340; cr.y = 20;
				addChild(cr);
			}

			var serverName:String = Online.connected ? Online.serverName : Data.WORLD_NAME;
			if (String(serverName).toUpperCase() == Data.WORLD_NAME.toUpperCase()) {
				// Eldmere's pixel-art name band
				var band:Bitmap = new NAME_BAND() as Bitmap;
				band.smoothing = false;
				band.scaleX = band.scaleY = 2;
				band.x = int((Ui.W - band.width) / 2);
				band.y = 14;
				band.filters = [new GlowFilter(0xff4dff, 0.45, 16, 16, 1.3, 2)];
				addChild(band);
			} else {
				var title:Logo = new Logo(serverName, 68);
				title.x = Ui.W / 2;
				title.y = 16;
				addChild(title);
			}
			var sub:TextField = Ui.text(17, 0xd8d0ff, false, "center", Ui.W, true);
			sub.text = "A bullet-hell adventure inspired by Realm of the Mad God";
			sub.y = 104;
			addChild(sub);

			classLayer = new Sprite();
			addChild(classLayer);
			// hero name
			var save:Object = Save.data;
			var nl:TextField = Ui.text(15, 0xbbbbbb, true, "right", 200, true);
			nl.text = "Hero name";
			nl.x = Ui.W / 2 - 316;
			nl.y = 142;
			classLayer.addChild(nl);
			var nameBox:Shape = new Shape();
			Ui.panel(nameBox.graphics, Ui.W / 2 - 104, 136, 208, 32, 0x1c1c1c, 0x6a6a6a);
			classLayer.addChild(nameBox);
			nameField = Ui.text(18, 0xffffff, true, "center", 196);
			nameField.autoSize = "none";
			nameField.height = 28;
			nameField.x = Ui.W / 2 - 98;
			nameField.y = 138;
			nameField.type = TextFieldType.INPUT;
			nameField.selectable = true;
			nameField.mouseEnabled = true;
			nameField.maxChars = 12;
			nameField.restrict = "A-Za-z0-9";
			nameField.text = save.name || Accounts.current || NAMES[int(Math.random() * NAMES.length)];
			classLayer.addChild(nameField);
			seasonBox(classLayer);

			var pick:TextField = Ui.text(18, 0xffffff, true, "left", 400, true);
			pick.text = "Choose your class";
			pick.x = (Ui.W - 4 * 252 - 3 * 10) / 2; pick.y = 178;
			classLayer.addChild(pick);

			// 4 to a row, 3 rows (every class is open from the start)
			for (var i:int = 0; i < Data.CLASS_ORDER.length; i++) {
				var card:Sprite = makeCard(Data.CLASSES[Data.CLASS_ORDER[i]], save);
				card.x = (Ui.W - 4 * 252 - 3 * 10) / 2 + (i % 4) * 262;
				card.y = 206 + int(i / 4) * 108;
				classLayer.addChild(card);
			}

			hoverTf = Ui.text(14, 0xffe8a0, true, "center", Ui.W - 40, true);
			hoverTf.x = 20; hoverTf.y = 532;
			classLayer.addChild(hoverTf);
			modePicker(classLayer);

			var help:TextField = Ui.text(14, 0xcccccc, false, "center", Ui.W, true);
			help.htmlText = "<b>WASD</b> move   <b>Mouse</b> aim + shoot   <b>Space</b> ability   <b>F / G</b> health / magic potion   " +
				"<b>1-8</b> use item   <b>R</b> return to Nexus   <b>I</b> auto-fire   <b>Esc</b> menu (change keys under Controls)\n" +
				"Start in the Nexus, step into a realm portal, clear the realm events, then face the Dark Elder in his chamber.";
			help.y = 556;
			addChild(help);

			var stats:TextField = Ui.text(15, 0xff9a40, true, "center", Ui.W, true);
			stats.text = "Account fame: " + Ui.commas(save.fame || 0) + "      Gold: " + Ui.commas(save.gold || 0) +
				"      Aether: " + Ui.commas(save.onrane || 0) + "      Best fame: " + Ui.commas(save.bestFame || 0) + "      Heroes lost: " + (save.deaths || 0);
			stats.y = 600;
			addChild(stats);

			buildCharLayer(save);

			var gy:Sprite = Ui.button("Graveyard", 130, 32, showGraveyard, 15);
			gy.x = Ui.W - 150; gy.y = 20;
			addChild(gy);

			// account bar: who is logged in, and a way back to the home screen
			var acc:TextField = Ui.text(15, 0xd8d0ff, true, "left", 400, true);
			acc.htmlText = "Account: <font color='#ffd75e'>" + (Accounts.current || "Guest") + "</font>" +
				(Online.connected && Online.welcome && Online.welcome.no ? " <font color='#b9a9d4'>#" + Online.welcome.no + "</font>" : "") + "   " +
				(Online.connected ? "<font color='#5ae06a'>Online characters</font>" : "<font color='#aaaaaa'>Offline characters</font>");
			acc.x = 20; acc.y = 26;
			addChild(acc);
			if (onBack != null) {
				var home:Sprite = Ui.button("Home", 100, 32, function():void { onBack(); }, 15);
				home.x = 20; home.y = 52;
				addChild(home);
			}
		}

		/** "Your Characters": continue a living character, or make a new one. */
		private function buildCharLayer(save:Object):void {
			var all:Array = Save.chars;
			// (no heroes left: the class screen has no list to go back to)
			if (backBtn) backBtn.visible = all.length > 0;
			if (all.length == 0) return;
			if (charLayer && charLayer.parent) removeChild(charLayer);
			charLayer = new Sprite();
			addChild(charLayer);
			classLayer.visible = false;
			var t:TextField = Ui.text(20, 0xffffff, true, "center", Ui.W, true);
			t.text = "Your Characters";
			t.y = 136;
			charLayer.addChild(t);
			// one tab per hero mode: each mode's heroes, and its own vault, are kept apart
			var tabW:int = 190, tx0:int = (Ui.W - Data.MODE_TABS.length * (tabW + 8) + 8) / 2;
			for (var ti:int = 0; ti < Data.MODE_TABS.length; ti++) {
				var tm:String = Data.MODE_TABS[ti];
				var n:int = 0;
				for each (var hc:Object in all) if (hc && (hc.mode || "") == tm) n++;
				var tmo:Object = Data.findMode(tm);
				var tb:Sprite = Ui.button((tm == mode ? "> " : "") + tmo.name + (n ? " (" + n + ")" : ""), tabW, 28, tabFn(tm, save), 14);
				tb.alpha = tm == mode ? 1 : 0.65;
				tb.x = tx0 + ti * (tabW + 8); tb.y = 168;
				charLayer.addChild(tb);
			}
			var chars:Array = all.filter(function(c:Object, ...r):Boolean { return c && (c.mode || "") == mode; });
			for (var i:int = 0; i < Math.min(8, chars.length); i++) {
				var card:Sprite = makeCharCard(chars[i]);
				card.x = (Ui.W - 4 * 240 - 3 * 14) / 2 + (i % 4) * 254;
				card.y = 208 + int(i / 4) * 116;
				charLayer.addChild(card);
				// a small "Delete" under the card's corner (asks first)
				var del:Sprite = Ui.button("Delete", 58, 20, deleteFn(chars[i]), 11);
				del.x = card.x + 240 - 64; del.y = card.y + 108 - 26;
				charLayer.addChild(del);
			}
			var md:Object = Data.findMode(mode);
			if (!chars.length) {
				var none:TextField = Ui.text(14, 0xbbbbbb, false, "center", 720, true);
				none.wordWrap = true; none.multiline = true;
				none.htmlText = "No " + md.name + " heroes yet.\n<font color='" + Ui.hex(md.col) + "'>" + md.desc + "</font>";
				none.x = (Ui.W - 720) / 2; none.y = 270;
				charLayer.addChild(none);
			}
			var nb:Sprite = Ui.button("New " + (mode ? md.name + " " : "") + "Character", 260, 40, function():void {
				charLayer.visible = false;
				classLayer.visible = true;
				if (modeRedraw != null) modeRedraw();
			});
			nb.x = (Ui.W - 260) / 2;
			nb.y = 444;
			charLayer.addChild(nb);
			if (backBtn) return;
			backBtn = Ui.button("Back", 100, 30, function():void {
				if (!charLayer) return;
				classLayer.visible = false;
				charLayer.visible = true;
			}, 14);
			backBtn.x = 20; backBtn.y = 140;
			classLayer.addChild(backBtn);
		}

		private function tabFn(m:String, save:Object):Function {
			return function():void { mode = m; buildCharLayer(save); };
		}

		/** Redraws the class screen's mode buttons (after a tab picked the mode). */
		private var modeRedraw:Function;

		/** The "Seasonal hero" box on the class screen (online only). */
		public static var seasonal:Boolean = false;
		/** The mode picked for a new hero, and the character screen's tab (Data.MODES): "", "ironman", "hardcore" or "group". */
		public static var mode:String = "";

		/** Regular / Ironman / Hardcore / Group Ironman buttons on the class screen, with what each means. */
		private function modePicker(layer:Sprite):void {
			var row:Sprite = new Sprite();
			layer.addChild(row);
			var lab:TextField = Ui.text(13, 0xbbbbbb, true, "right", 90, true);
			lab.text = "Mode";
			lab.x = 0; lab.y = 4;
			row.addChild(lab);
			var draw:Function = function():void {
				while (row.numChildren > 1) row.removeChildAt(1);
				for (var i:int = 0; i < Data.MODES.length; i++) {
					var md:Object = Data.MODES[i];
					var on:Boolean = md.id == mode;
					var b:Sprite = Ui.button((on ? "> " : "") + md.name, 104, 26, pickFn(md.id, draw), 12);
					b.alpha = on ? 1 : 0.6;
					b.x = 98 + i * 108; b.y = 0;
					row.addChild(b);
				}
				if (hoverTf) hoverTf.htmlText = "<font color='" + Ui.hex(Data.findMode(mode).col) + "'><b>" + Data.findMode(mode).name + ":</b></font> " + Data.findMode(mode).desc;
			};
			draw();
			modeRedraw = draw;
			row.x = Ui.W - 540; row.y = 176;
		}

		private function pickFn(id:String, redraw:Function):Function {
			return function():void { mode = id; redraw(); };
		}

		private function seasonBox(layer:Sprite):void {
			var ss:Object = Online.connected && Online.welcome ? Online.welcome.season : null;
			if (!ss) { seasonal = false; return; }
			var box:Sprite = new Sprite();
			var tf:TextField = Ui.text(13, 0x8fd16a, true, "left", 0, true);
			var draw:Function = function():void {
				box.graphics.clear();
				// (the whole line is clickable, label included)
				box.graphics.beginFill(0, 0);
				box.graphics.drawRect(0, 0, 26 + tf.width, 22);
				box.graphics.endFill();
				Ui.panel(box.graphics, 0, 0, 20, 20, 0x1c1c1c, 0x8fd16a);
				if (seasonal) { box.graphics.beginFill(0x8fd16a); box.graphics.drawRect(5, 5, 10, 10); box.graphics.endFill(); }
				tf.htmlText = "<b>Seasonal hero</b> <font color='#b0b0b0'>(scores double on the season ladder)</font>";
			};
			tf.x = 26; tf.y = 1;
			box.addChild(tf);
			draw();
			draw();
			box.buttonMode = true;
			box.mouseChildren = false;
			box.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { seasonal = !seasonal; draw(); });
			box.x = Ui.W / 2 + 120; box.y = 142;
			layer.addChild(box);
		}

		private function makeCharCard(c:Object):Sprite {
			var card:Sprite = new Sprite();
			var w:int = 240, h:int = 108;
			var cls:Object = Data.CLASSES[c.cls];
			var draw:Function = function(hover:Boolean):void {
				card.graphics.clear();
				Ui.panel(card.graphics, 0, 0, w, h, hover ? 0x3e3e3e : 0x262626, hover ? Ui.GOLD : 0x5a5a5a, 0.94);
			};
			draw(false);
			var spr:Bitmap = new Bitmap(Sprites.get(c.skin || c.cls));
			spr.scaleX = spr.scaleY = 1.4;
			spr.x = 10; spr.y = (h - spr.height) / 2;
			card.addChild(spr);
			var nm:TextField = Ui.text(20, 0xffffff, true, "left", 0, true);
			nm.text = c.name;
			nm.x = 82; nm.y = 10;
			card.addChild(nm);
			if (c.mode) {
				// an Ironman or Hardcore hero: its mode under the name
				var mdo:Object = Data.findMode(c.mode);
				var mt:TextField = Ui.text(10, mdo.col, true, "right", 80, true);
				mt.text = mdo.name.toUpperCase();
				mt.x = w - 86; mt.y = c.season ? 18 : 6;
				card.addChild(mt);
			}
			if (c.season) {
				// a Seasonal hero: a leaf-green tag (grey once its season is over)
				var cur:Boolean = Online.welcome && Online.welcome.season && Online.welcome.season.id == c.season;
				var st:TextField = Ui.text(10, cur ? 0x8fd16a : 0x909090, true, "right", 80, true);
				st.text = cur ? "SEASONAL" : "VETERAN";
				st.x = w - 86; st.y = 6;
				card.addChild(st);
			}
			var info:TextField = Ui.text(13, 0xbbbbbb, false, "left", 150);
			var maxed:int = 0;
			for each (var s:String in Data.STATS) if (c.stats[s] >= cls.max[s]) maxed++;
			var gear:String = c.weapon && c.weapon.rarity ? " <font color='" + Ui.hex(Data.RARITY_COLORS[c.weapon.rarity]) + "'>" + Data.tierLabel(c.weapon) + "</font>" : "";
			info.htmlText = "Lvl " + c.level + " " + cls.name + gear + "\n" + maxed + "/11 maxed   " + c.kills + " kills";
			info.x = 82; info.y = 40;
			card.addChild(info);
			card.buttonMode = true;
			card.mouseChildren = false;
			card.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			card.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			card.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onPick(c.cls, c.name, c); });
			return card;
		}

		private function makeCard(cls:Object, save:Object):Sprite {
			var c:Sprite = new Sprite();
			var w:int = 252, h:int = 100;
			var eldmere:Boolean = !!Data.ELDMERE_CLASSES[cls.id];
			var draw:Function = function(hover:Boolean):void {
				c.graphics.clear();
				Ui.panel(c.graphics, 0, 0, w, h, hover ? 0x3e3e3e : 0x262626, hover ? Ui.GOLD : eldmere ? 0x6a5a8a : 0x5a5a5a, 0.94);
				c.graphics.beginFill(0x000000, 0.25);
				c.graphics.drawRoundRect(6, 6, 64, 64, 10, 10);
				c.graphics.endFill();
			};
			draw(false);
			var spr:Bitmap = new Bitmap(Sprites.get(cls.id));
			spr.scaleX = spr.scaleY = 1.2;
			spr.x = 38 - spr.width / 2;
			spr.y = 38 - spr.height / 2;
			c.addChild(spr);
			var name:TextField = Ui.text(18, 0xffffff, true, "left", 0, true);
			name.text = cls.name;
			name.x = 78; name.y = 4;
			c.addChild(name);
			if (eldmere) {
				// (Eldmere's own classes: a little mark under the portrait)
				var tag:TextField = Ui.text(9, 0xc0a0ff, true, "center", 64, true);
				tag.text = "ELDMERE";
				tag.x = 6; tag.y = 56;
				c.addChild(tag);
			}
			var best:int = save.bestLevel ? int(save.bestLevel[cls.id] || 0) : 0;
			var info:TextField = Ui.text(11, 0xaaaaaa, false, "left", w - 84);
			info.htmlText = "<font color='#ffd75e'><b>" + cls.ability.name + "</b></font>  " + cls.ability.desc;
			info.x = 78; info.y = 28;
			c.addChild(info);
			var desc:TextField = Ui.text(11, 0xcccccc, false, "left", w - 14);
			desc.htmlText = "HP " + cls.base.hp + "  ATT " + cls.base.att + "  DEX " + cls.base.dex +
				(best > 0 ? "   <font color='#80ff80'>Best level " + best + "</font>" : "");
			desc.x = 7;
			desc.y = 76;
			c.addChild(desc);

			c.buttonMode = true;
			c.mouseChildren = false;
			c.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); if (hoverTf) hoverTf.text = cls.name + ": " + cls.desc; });
			c.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); if (hoverTf) hoverTf.text = ""; });
			c.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				var n:String = nameField.text.replace(/[^A-Za-z0-9]/g, "");
				if (!n) n = NAMES[int(Math.random() * NAMES.length)];
				Save.data.name = n;
				Save.flush();
				onPick(cls.id, n);
			});
			return c;
		}

		/** The graveyard: your most recent fallen heroes. */
		private var graveLayer:Sprite;
		private var confirmLayer:Sprite;
		/** The class screen's "Back" to the character list (made once). */
		private var backBtn:Sprite;

		private function deleteFn(c:Object):Function {
			return function():void { confirmDelete(c); };
		}

		/** Deleting a hero: it and everything it carries are gone for good, so it asks first. */
		private function confirmDelete(c:Object):void {
			if (confirmLayer) { removeChild(confirmLayer); confirmLayer = null; }
			var cls:Object = Data.CLASSES[c.cls];
			var locked:int = 0, held:int = 0;
			for each (var it:Object in [c.weapon, c.ability, c.armor, c.ring].concat(c.inv || [])) if (it) { held++; if (it.locked) locked++; }
			confirmLayer = new Sprite();
			var w:int = 460, h:int = 220;
			var px:int = (Ui.W - w) / 2, py:int = 190;
			confirmLayer.graphics.beginFill(0x000000, 0.65);
			confirmLayer.graphics.drawRect(0, 0, Ui.W, Ui.H);
			confirmLayer.graphics.endFill();
			Ui.panel(confirmLayer.graphics, px, py, w, h, 0x24181a, 0xc04040, 0.98);
			var t:TextField = Ui.text(22, 0xff8080, true, "center", w, true);
			t.text = "Delete " + c.name + "?";
			t.x = px; t.y = py + 14;
			confirmLayer.addChild(t);
			var body:TextField = Ui.text(14, 0xdddddd, false, "center", w - 40);
			body.wordWrap = true; body.multiline = true;
			body.htmlText = "Lvl " + c.level + " " + (cls ? cls.name : c.cls) + "   " + c.kills + " kills<br><br>" +
				"The hero and <b>everything they carry</b> (" + held + " item" + (held == 1 ? "" : "s") + ") will be gone for good. " +
				"Your vault, gold and fame are kept.<br><font color='#ff9090'>This can't be undone.</font>";
			body.x = px + 20; body.y = py + 52;
			confirmLayer.addChild(body);
			var close:Function = function():void { if (confirmLayer) { removeChild(confirmLayer); confirmLayer = null; } };
			if (locked > 0) {
				// locked gear is the player saying "never lose this": move it to the vault first
				var lk:TextField = Ui.text(13, 0xffd75e, true, "center", w - 40);
				lk.text = c.name + " carries " + locked + " locked item" + (locked == 1 ? "" : "s") + ". Unlock or vault them first.";
				lk.x = px + 20; lk.y = py + h - 82;
				confirmLayer.addChild(lk);
			} else {
				var yes:Sprite = Ui.button("Delete forever", 170, 36, function():void {
					Save.removeChar(c.id);
					close();
					// show the list again without it (or the class picker if none are left)
					if (charLayer) { removeChild(charLayer); charLayer = null; }
					classLayer.visible = true;
					buildCharLayer(Save.data);
				}, 15);
				yes.x = px + w / 2 - 180; yes.y = py + h - 50;
				confirmLayer.addChild(yes);
			}
			var no:Sprite = Ui.button("Cancel", 170, 36, close, 15);
			no.x = locked > 0 ? px + (w - 170) / 2 : px + w / 2 + 10; no.y = py + h - 50;
			confirmLayer.addChild(no);
			addChild(confirmLayer);
		}

		private function showGraveyard():void {
			if (graveLayer) { removeChild(graveLayer); graveLayer = null; return; }
			graveLayer = new Sprite();
			var w:int = 720, h:int = 470;
			var px:int = (Ui.W - w) / 2, py:int = 120;
			graveLayer.graphics.beginFill(0x000000, 0.6);
			graveLayer.graphics.drawRect(0, 0, Ui.W, Ui.H);
			graveLayer.graphics.endFill();
			Ui.panel(graveLayer.graphics, px, py, w, h, 0x1e1e22, 0x6a6a6a, 0.97);
			var t:TextField = Ui.text(24, 0xe0e0e0, true, "center", w, true);
			t.text = "Graveyard";
			t.x = px; t.y = py + 10;
			graveLayer.addChild(t);
			var graves:Array = Save.data.graves as Array || [];
			if (graves.length == 0) {
				var none:TextField = Ui.text(15, 0x999999, false, "center", w, true);
				none.text = "No heroes have fallen yet.";
				none.x = px; none.y = py + 80;
				graveLayer.addChild(none);
			}
			for (var i:int = 0; i < Math.min(10, graves.length); i++) {
				var g:Object = graves[i];
				var ry:int = py + 54 + i * 38;
				var ic:Bitmap = new Bitmap(Sprites.get(g.skin || g.cls));
				ic.scaleX = ic.scaleY = 0.7;
				ic.x = px + 18; ic.y = ry;
				graveLayer.addChild(ic);
				var row:TextField = Ui.text(14, 0xffffff, false, "left", w - 80, true);
				var cls:Object = Data.CLASSES[g.cls];
				row.htmlText = "<b>" + g.name + "</b>  <font color='#aaaaaa'>Lvl " + g.level + " " + (cls ? cls.name : g.cls) +
					"   " + g.kills + " kills   killed by </font><font color='#ff9a40'>" + g.killer + "</font>" +
					"   <font color='#ffb040'><b>" + Ui.commas(g.fame) + " fame</b></font>  <font color='#777777'>" + g.date + "</font>";
				row.x = px + 64; row.y = ry + 6;
				graveLayer.addChild(row);
			}
			var close:Sprite = Ui.button("Close", 120, 32, showGraveyard, 15);
			close.x = px + (w - 120) / 2; close.y = py + h - 44;
			graveLayer.addChild(close);
			addChild(graveLayer);
		}


	}
}
