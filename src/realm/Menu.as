package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldType;

	/**
	 * The hero screens, drawn like the game's own windows: "Your Heroes" (a tab per hero mode,
	 * each hero a card with its gear) and "New Hero" (class list on the left, the picked class
	 * in detail on the right).
	 */
	public class Menu extends Sprite {
		[Embed(source="../../assets/branding/name_band.png")]
		private static const NAME_BAND:Class;
		private static const NAMES:Array = ["Ezra", "Vex", "Lyra", "Thorn", "Kael", "Mira", "Orin", "Sable", "Rook", "Nyx", "Bram", "Iris"];

		// the window both screens sit in
		private static const PX:int = 40, PY:int = 132, PW:int = 1020, PH:int = 448, HEAD:int = 46;
		private static const CARD_W:int = 240, CARD_H:int = 146, PER_PAGE:int = 7;
		private static const EDGE:uint = 0x4c4c4c, BOX:uint = 0x262626, BOX_HI:uint = 0x323232;

		public static var BAND_SCALE:int = 1;
		private var onPick:Function;
		private var onBack:Function;
		private var nameField:TextField;
		private var heroName:String;
		private var classLayer:Sprite;
		private var charLayer:Sprite;
		/** The class picked on the New Hero screen. */
		private var picked:String;
		private var page:int = 0;

		/** The "Seasonal hero" box on the class screen (online only). */
		public static var seasonal:Boolean = false;
		/** The mode picked for a new hero, and the hero screen's tab (Data.MODES): "", "ironman", "hardcore" or "group". */
		public static var mode:String = "";

		public function Menu(onPick:Function, onBack:Function = null, onCreate:Function = null) {
			this.onPick = onPick;
			this.onBack = onBack;
			addChild(new MenuBackdrop());

			var serverName:String = Online.connected ? Online.serverName : Data.WORLD_NAME;
			if (String(serverName).toUpperCase() == Data.WORLD_NAME.toUpperCase()) {
				// Eldmere's pixel-art name band
				var band:Bitmap = new NAME_BAND() as Bitmap;
				band.smoothing = false;
				band.scaleX = band.scaleY = BAND_SCALE;
				band.x = int((Ui.W - band.width) / 2);
				band.y = BAND_SCALE == 1 ? 30 : 18;
				band.filters = [new DropShadowFilter(3, 90, 0, 0.6, 6, 6, 1, 2)];
				addChild(band);
			} else {
				var title:Logo = new Logo(serverName, 68);
				title.x = Ui.W / 2;
				title.y = 16;
				addChild(title);
			}
			var sub:TextField = Ui.text(13, 0x9a90b8, false, "center", Ui.W, true);
			sub.text = "A bullet-hell adventure inspired by Realm of the Mad God";
			sub.y = BAND_SCALE == 1 ? 84 : 102;
			addChild(sub);

			accountBox();
			var gy:Sprite = Ui.button("Graveyard", 130, 32, showGraveyard, 15);
			gy.x = Ui.W - 150; gy.y = 20;
			addChild(gy);
			// Creator Tools are for the server's admins only (config.json "admins")
			if (onCreate != null && Online.connected && Online.welcome && Online.welcome.admin) {
				var cr:Sprite = Ui.button("Creator Tools", 150, 32, function():void { onCreate(); }, 15);
				cr.x = Ui.W - 310; cr.y = 20;
				addChild(cr);
			}

			var help:TextField = Ui.text(13, 0xb8b8b8, false, "center", Ui.W, true);
			help.htmlText = "<b>WASD</b> move   <b>Mouse</b> aim + shoot   <b>Space</b> ability   <b>F / G</b> potions   " +
				"<b>1-8</b> use item   <b>R</b> Nexus   <b>K</b> Wiki   <b>Esc</b> menu and controls";
			help.y = PY + PH + 14;
			addChild(help);

			heroName = Save.data.name || Accounts.current || NAMES[int(Math.random() * NAMES.length)];
			picked = Data.CLASS_ORDER[0];
			if (Save.chars.length) showHeroes(); else showNew();
		}

		// ---- shared pieces ------------------------------------------------------------------------

		/** Top left: who is logged in, online or not, and the way home. */
		private function accountBox():void {
			var box:Sprite = new Sprite();
			Ui.panel(box.graphics, 0, 0, 290, 58, 0x1c1c1c, EDGE, 0.92);
			var acc:TextField = Ui.text(16, Ui.GOLD, true, "left", 200, true);
			acc.htmlText = Ui.esc(Accounts.current || "Guest") +
				(Online.connected && Online.welcome && Online.welcome.no ? " <font color='#b9a9d4' size='13'>#" + Online.welcome.no + "</font>" : "");
			acc.x = 12; acc.y = 6;
			box.addChild(acc);
			var st:TextField = Ui.text(12, Online.connected ? 0x5ae06a : 0xaaaaaa, true, "left", 200, true);
			st.text = Online.connected ? "Online: " + (Online.serverName || "server") : "Offline heroes (this PC only)";
			st.x = 12; st.y = 32;
			box.addChild(st);
			if (onBack != null) {
				var home:Sprite = Ui.button("Home", 70, 30, function():void { onBack(); }, 14);
				home.x = 290 - 80; home.y = 14;
				box.addChild(home);
			}
			box.x = 16; box.y = 16;
			addChild(box);
		}

		/** The window both screens sit in: a shadowed panel with a header strip. */
		private function frame(layer:Sprite, title:String, titleX:int = 18):void {
			var f:Shape = new Shape();
			f.graphics.beginFill(0x000000, 0.35);
			f.graphics.drawRoundRect(PX + 4, PY + 6, PW, PH, 14, 14);
			f.graphics.endFill();
			Ui.panel(f.graphics, PX, PY, PW, PH, 0x1c1c1c, EDGE, 0.95);
			f.graphics.beginFill(0x262626, 0.95);
			f.graphics.drawRoundRect(PX + 1, PY + 1, PW - 2, HEAD, 12, 12);
			f.graphics.drawRect(PX + 1, PY + HEAD - 10, PW - 2, 10);
			f.graphics.endFill();
			f.graphics.lineStyle(1, EDGE);
			f.graphics.moveTo(PX + 1, PY + HEAD); f.graphics.lineTo(PX + PW - 1, PY + HEAD);
			layer.addChild(f);
			var t:TextField = Ui.text(20, 0xffffff, true, "left", 0, true);
			t.text = title;
			t.x = PX + titleX; t.y = PY + (HEAD - t.height) / 2;
			layer.addChild(t);
		}

		/** The hero mode tabs (Regular / Ironman / Hardcore / Group Ironman), right-aligned in the header. */
		private function modeTabs(layer:Sprite, counts:Object, onChange:Function):void {
			var w:int = 150, gap:int = 6, n:int = Data.MODE_TABS.length;
			var x0:int = PX + PW - 12 - n * w - (n - 1) * gap;
			for (var i:int = 0; i < n; i++) {
				var t:Sprite = modeTab(Data.MODE_TABS[i], w, counts ? int(counts[Data.MODE_TABS[i]] || 0) : -1, onChange);
				t.x = x0 + i * (w + gap); t.y = PY + 8;
				layer.addChild(t);
			}
		}

		private function modeTab(m:String, w:int, count:int, onChange:Function):Sprite {
			var md:Object = Data.findMode(m);
			var on:Boolean = m == mode;
			var t:Sprite = new Sprite();
			var lab:TextField = Ui.text(13, on ? 0xffffff : 0xb0b0b0, true, "left", 0, true);
			lab.htmlText = md.name + (count > 0 ? "  <font color='#8a8a8a'>" + count + "</font>" : "");
			lab.x = (w - lab.width) / 2; lab.y = 7;
			var draw:Function = function(hover:Boolean):void {
				t.graphics.clear();
				Ui.panel(t.graphics, 0, 0, w, 30, on ? 0x3a3a3a : hover ? 0x303030 : 0x1e1e1e, on ? md.col : hover ? 0x7a7a7a : 0x444444);
				// the mode's colour along the bottom
				t.graphics.beginFill(md.col, on ? 1 : 0.35);
				t.graphics.drawRect(8, 26, w - 16, 2);
				t.graphics.endFill();
			};
			draw(false);
			t.addChild(lab);
			t.buttonMode = true;
			t.mouseChildren = false;
			t.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			t.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			t.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { if (mode != m) { mode = m; page = 0; onChange(); } });
			return t;
		}

		/** A small coloured label (mode tags, SEASONAL). */
		private static function chip(text:String, col:uint):Sprite {
			var s:Sprite = new Sprite();
			var tf:TextField = Ui.text(10, col, true, "left", 0, true);
			tf.text = text;
			tf.x = 5; tf.y = 1;
			s.graphics.lineStyle(1, col, 0.8);
			s.graphics.beginFill(col, 0.14);
			s.graphics.drawRoundRect(0, 0, tf.width + 10, 16, 6, 6);
			s.graphics.endFill();
			s.addChild(tf);
			s.mouseEnabled = s.mouseChildren = false;
			return s;
		}

		/** A dark inset box with a sprite in the middle (portraits). */
		private static function portrait(id:String, size:int, scale:Number, edge:uint = 0x3a3a3a):Sprite {
			var s:Sprite = new Sprite();
			s.graphics.lineStyle(1, edge);
			s.graphics.beginFill(0x121212, 0.9);
			s.graphics.drawRoundRect(0, 0, size, size, 10, 10);
			s.graphics.endFill();
			var b:Bitmap = new Bitmap(Sprites.get(id));
			b.scaleX = b.scaleY = scale;
			b.x = int((size - b.width) / 2); b.y = int((size - b.height) / 2);
			s.addChild(b);
			return s;
		}

		/** A bar like the HUD's: fill / back, a label on the left and a value on the right. */
		private static function bar(g:*, x:int, y:int, w:int, h:int, f:Number, col:uint, back:uint):void {
			g.beginFill(back);
			g.drawRoundRect(x, y, w, h, 6, 6);
			g.endFill();
			if (f > 0) {
				g.beginFill(col);
				g.drawRoundRect(x, y, Math.max(6, w * Math.min(1, f)), h, 6, 6);
				g.endFill();
			}
		}

		// ---- Your Heroes --------------------------------------------------------------------------

		private function showHeroes():void {
			if (classLayer && classLayer.parent) removeChild(classLayer);
			classLayer = null;
			if (charLayer && charLayer.parent) removeChild(charLayer);
			var all:Array = Save.chars;
			if (!all.length) { showNew(); return; }
			charLayer = new Sprite();
			addChildAt(charLayer, 1);
			frame(charLayer, "Your Heroes");
			var counts:Object = {};
			for each (var hc:Object in all) if (hc) counts[hc.mode || ""] = int(counts[hc.mode || ""] || 0) + 1;
			modeTabs(charLayer, counts, showHeroes);

			var md:Object = Data.findMode(mode);
			var chars:Array = all.filter(function(c:Object, ...r):Boolean { return c && (c.mode || "") == mode; });
			var pages:int = Math.max(1, Math.ceil((chars.length + 1) / (PER_PAGE + 1)));
			if (page >= pages) page = pages - 1;
			var from:int = page * PER_PAGE;
			var shown:Array = chars.slice(from, from + PER_PAGE);
			var x0:int = PX + 12, y0:int = PY + HEAD + 12;
			for (var i:int = 0; i <= shown.length && i < 8; i++) {
				var card:Sprite = i < shown.length ? heroCard(shown[i]) : newCard(md);
				card.x = x0 + (i % 4) * (CARD_W + 12);
				card.y = y0 + int(i / 4) * (CARD_H + 12);
				charLayer.addChild(card);
			}
			if (pages > 1) pager(charLayer, pages, PX + PW - 120, PY + 372, showHeroes);

			// footer: what the mode means, and the account's totals
			var fy:int = PY + 372;
			var tag:Sprite = chip(md.tag || "REGULAR", md.col);
			tag.x = PX + 16; tag.y = fy + 3;
			charLayer.addChild(tag);
			var desc:TextField = Ui.text(13, 0xd0d0d0, false, "left", PW - 300, true);
			desc.htmlText = "<font color='" + Ui.hex(md.col) + "'><b>" + md.name + "</b></font>  " + Ui.esc(md.desc);
			desc.x = tag.x + tag.width + 8; desc.y = fy + 1;
			charLayer.addChild(desc);
			var sv:Object = Save.data;
			var totals:Array = [["fame", Ui.commas(sv.fame || 0), "Account fame"], ["gold", Ui.commas(sv.gold || 0), "Gold"],
				["onrane", Ui.commas(sv.onrane || 0), "Aether"], ["fame", Ui.commas(sv.bestFame || 0), "Best fame"], ["skull", String(sv.deaths || 0), "Heroes lost"]];
			var cw:int = int((PW - 24 - 4 * 8) / 5);
			for (var k:int = 0; k < totals.length; k++) {
				var c:Sprite = statChip(totals[k][0], totals[k][1], totals[k][2], cw);
				c.x = PX + 12 + k * (cw + 8); c.y = PY + PH - 46;
				charLayer.addChild(c);
			}
		}

		private function statChip(icon:String, value:String, label:String, w:int):Sprite {
			var s:Sprite = new Sprite();
			Ui.panel(s.graphics, 0, 0, w, 34, BOX, 0x3c3c3c);
			var ic:Bitmap = new Bitmap(Sprites.get(icon));
			ic.scaleX = ic.scaleY = 0.8;
			ic.x = 10; ic.y = (34 - ic.height) / 2;
			s.addChild(ic);
			var v:TextField = Ui.text(15, 0xffffff, true, "left", 0, true);
			v.text = value;
			v.x = 40; v.y = 7;
			s.addChild(v);
			var l:TextField = Ui.text(11, 0x9a9a9a, true, "right", w - v.x - v.width - 14);
			l.text = label;
			l.x = w - l.width - 10; l.y = 10;
			s.addChild(l);
			return s;
		}

		private function pager(layer:Sprite, pages:int, x:int, y:int, redraw:Function):void {
			var prev:Sprite = Ui.button("<", 28, 24, function():void { if (page > 0) { page--; redraw(); } }, 13);
			prev.x = x; prev.y = y - 2;
			layer.addChild(prev);
			var tf:TextField = Ui.text(13, 0xcccccc, true, "center", 48, true);
			tf.text = (page + 1) + " / " + pages;
			tf.x = x + 32; tf.y = y + 2;
			layer.addChild(tf);
			var next:Sprite = Ui.button(">", 28, 24, function():void { if (page < pages - 1) { page++; redraw(); } }, 13);
			next.x = x + 84; next.y = y - 2;
			layer.addChild(next);
		}

		/** One hero: portrait, name, level, stats maxed and the gear it wears. */
		private function heroCard(c:Object):Sprite {
			var card:Sprite = new Sprite();
			var cls:Object = Data.CLASSES[c.cls] || Data.CLASSES.wizard;
			var md:Object = Data.findMode(c.mode || "");
			var draw:Function = function(hover:Boolean):void {
				card.graphics.clear();
				Ui.panel(card.graphics, 0, 0, CARD_W, CARD_H, hover ? BOX_HI : BOX, hover ? Ui.GOLD : 0x464646, 0.97);
				if (c.mode) { card.graphics.beginFill(md.col, 0.9); card.graphics.drawRect(10, 1, CARD_W - 20, 2); card.graphics.endFill(); }
			};
			draw(false);
			var pt:Sprite = portrait(c.skin || c.cls, 64, 1.4);
			pt.x = 8; pt.y = 10;
			card.addChild(pt);
			var nm:TextField = Ui.text(18, 0xffffff, true, "left", 0, true);
			nm.text = c.name;
			nm.x = 80; nm.y = 6;
			card.addChild(nm);
			var info:TextField = Ui.text(12, 0xb8b8b8, true, "left", 0, true);
			info.htmlText = "Lvl " + c.level + " " + cls.name + (c.asc > 0 ? "  <font color='#ffd75e'>Asc " + c.asc + "</font>" : "");
			info.x = 80; info.y = 30;
			card.addChild(info);
			// level progress (or, at 20, the stats left to max) like the HUD's level bar
			var maxed:int = 0;
			for each (var s:String in Data.STATS) if (c.stats && cls.max && c.stats[s] >= cls.max[s]) maxed++;
			var lv:Shape = new Shape();
			var top:Boolean = c.level >= Player.MAX_LEVEL;
			bar(lv.graphics, 80, 50, 150, 14, top ? maxed / Data.STATS.length : (c.xpNext > 0 ? c.xp / c.xpNext : 0), top ? 0xd8a838 : 0x9a7480, 0x1a1a1a);
			card.addChild(lv);
			var lt:TextField = Ui.text(10, 0xffffff, true, "left", 0, true);
			lt.text = top ? maxed + "/" + Data.STATS.length + " maxed" : int(c.xpNext > 0 ? c.xp * 100 / c.xpNext : 0) + "% to " + (c.level + 1);
			lt.x = 86; lt.y = 50;
			card.addChild(lt);
			var kt:TextField = Ui.text(10, 0xd8d8d8, true, "right", 80, true);
			kt.text = Ui.commas(c.kills || 0) + " kills";
			kt.x = 80 + 150 - 86; kt.y = 50;
			card.addChild(kt);
			// tags: mode, seasonal
			var tx:int = CARD_W - 26;
			if (c.season) {
				var cur:Boolean = Online.welcome && Online.welcome.season && Online.welcome.season.id == c.season;
				var sc:Sprite = chip(cur ? "SEASONAL" : "VETERAN", cur ? 0x8fd16a : 0x909090);
				tx -= sc.width + 4; sc.x = tx; sc.y = 9;
				card.addChild(sc);
			}
			if (c.mode) {
				var mc:Sprite = chip(md.tag, md.col);
				tx -= mc.width + 4; mc.x = tx; mc.y = 9;
				card.addChild(mc);
			}
			// the gear it wears, in the HUD's slots
			var kinds:Array = ["weapon", "ability", "armor", "ring"];
			for (var i:int = 0; i < 4; i++) {
				var sl:Sprite = gearSlot(c[kinds[i]]);
				sl.x = 11 + i * 56; sl.y = 84;
				card.addChild(sl);
			}
			// delete (asks first)
			var del:Sprite = closeBox(0xc05050);
			del.x = CARD_W - 22; del.y = 8;
			del.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); confirmDelete(c); });
			card.addChild(del);
			card.buttonMode = true;
			card.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			card.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			card.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onPick(c.cls, c.name, c); });
			for (var j:int = 0; j < card.numChildren; j++) if (card.getChildAt(j) != del && card.getChildAt(j) is Sprite) Sprite(card.getChildAt(j)).mouseEnabled = Sprite(card.getChildAt(j)).mouseChildren = false;
			return card;
		}

		/** An equipment slot like the HUD's: the item's icon and its tier. */
		private static function gearSlot(it:Object):Sprite {
			var s:Sprite = new Sprite();
			s.graphics.lineStyle(1, 0x1a1a1a);
			s.graphics.beginFill(it ? 0x545454 : 0x3a3a3a);
			s.graphics.drawRoundRect(0, 0, 50, 50, 10, 10);
			s.graphics.endFill();
			if (it && it.kind) {
				var bd:BitmapData = Sprites.icon(it);
				var b:Bitmap = new Bitmap(bd);
				var sc:Number = Math.min(1, 40 / Math.max(bd.width, bd.height));
				b.scaleX = b.scaleY = sc;
				b.x = int((50 - b.width) / 2); b.y = int((50 - b.height) / 2) - 2;
				s.addChild(b);
				var t:TextField = Ui.text(11, Data.tierColor(it), true, "right", 44, true);
				t.text = Data.tierLabel(it);
				t.x = 2; t.y = 33;
				s.addChild(t);
			}
			return s;
		}

		/** A small "x" box (delete a hero). */
		private static function closeBox(col:uint):Sprite {
			var s:Sprite = new Sprite();
			var draw:Function = function(hover:Boolean):void {
				s.graphics.clear();
				Ui.panel(s.graphics, 0, 0, 16, 16, hover ? col : 0x2a2a2a, hover ? 0xffffff : 0x5a5a5a);
				s.graphics.lineStyle(2, hover ? 0xffffff : 0x9a9a9a);
				s.graphics.moveTo(5, 5); s.graphics.lineTo(11, 11);
				s.graphics.moveTo(11, 5); s.graphics.lineTo(5, 11);
				s.graphics.lineStyle();
			};
			draw(false);
			s.buttonMode = true;
			s.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			s.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			return s;
		}

		/** The empty card at the end of the list: make a new hero of this tab's mode. */
		private function newCard(md:Object):Sprite {
			var card:Sprite = new Sprite();
			var draw:Function = function(hover:Boolean):void {
				card.graphics.clear();
				Ui.panel(card.graphics, 0, 0, CARD_W, CARD_H, hover ? 0x262626 : 0x161616, hover ? Ui.GOLD : 0x3e3e3e, 0.8);
				// a dashed inner edge
				card.graphics.lineStyle(1, hover ? Ui.GOLD : md.col, hover ? 0.8 : 0.45);
				for (var x:int = 14; x < CARD_W - 14; x += 10) { card.graphics.moveTo(x, 8); card.graphics.lineTo(x + 5, 8); card.graphics.moveTo(x, CARD_H - 8); card.graphics.lineTo(x + 5, CARD_H - 8); }
				for (var y:int = 14; y < CARD_H - 14; y += 10) { card.graphics.moveTo(8, y); card.graphics.lineTo(8, y + 5); card.graphics.moveTo(CARD_W - 8, y); card.graphics.lineTo(CARD_W - 8, y + 5); }
				card.graphics.lineStyle();
			};
			draw(false);
			var plus:TextField = Ui.text(40, md.col, true, "center", CARD_W, true);
			plus.text = "+";
			plus.y = 24;
			card.addChild(plus);
			var t:TextField = Ui.text(15, 0xffffff, true, "center", CARD_W, true);
			t.text = "New " + (md.id ? md.name + " " : "") + "Hero";
			t.y = 84;
			card.addChild(t);
			card.buttonMode = true;
			card.mouseChildren = false;
			card.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			card.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			card.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { showNew(); });
			return card;
		}

		// ---- New Hero -----------------------------------------------------------------------------

		private function showNew():void {
			if (nameField) heroName = nameField.text;
			if (charLayer && charLayer.parent) removeChild(charLayer);
			charLayer = null;
			if (classLayer && classLayer.parent) removeChild(classLayer);
			classLayer = new Sprite();
			addChildAt(classLayer, 1);
			var hasHeroes:Boolean = Save.chars.length > 0;
			frame(classLayer, "New Hero", hasHeroes ? 112 : 18);
			if (hasHeroes) {
				var back:Sprite = Ui.button("< Heroes", 86, 30, showHeroes, 13);
				back.x = PX + 12; back.y = PY + 8;
				classLayer.addChild(back);
			}
			modeTabs(classLayer, null, showNew);

			// the classes, three to a row
			var cw:int = 206, ch:int = 80, gap:int = 8;
			for (var i:int = 0; i < Data.CLASS_ORDER.length; i++) {
				var card:Sprite = classCard(Data.CLASSES[Data.CLASS_ORDER[i]], cw, ch);
				card.x = PX + 12 + (i % 3) * (cw + gap);
				card.y = PY + HEAD + 12 + int(i / 3) * (ch + gap);
				classLayer.addChild(card);
			}
			var md:Object = Data.findMode(mode);
			var mdesc:TextField = Ui.text(12, 0xc8c8c8, false, "left", 3 * cw + 2 * gap - 8, true);
			mdesc.htmlText = "<font color='" + Ui.hex(md.col) + "'><b>" + md.name + "</b></font>  " + Ui.esc(md.desc);
			mdesc.x = PX + 16; mdesc.y = PY + HEAD + 12 + 4 * (ch + gap) + 2;
			classLayer.addChild(mdesc);
			detailPane(classLayer, PX + 12 + 3 * (cw + gap) + 4, PY + HEAD + 12, PW - (3 * (cw + gap) + 4) - 24, PH - HEAD - 24);
		}

		private function classCard(cls:Object, w:int, h:int):Sprite {
			var c:Sprite = new Sprite();
			var on:Boolean = cls.id == picked;
			var eldmere:Boolean = !!Data.ELDMERE_CLASSES[cls.id];
			var draw:Function = function(hover:Boolean):void {
				c.graphics.clear();
				Ui.panel(c.graphics, 0, 0, w, h, on ? 0x3a3426 : hover ? BOX_HI : BOX, on ? Ui.GOLD : hover ? 0x8a8a8a : eldmere ? 0x5e5078 : 0x464646, 0.97);
			};
			draw(false);
			var pt:Sprite = portrait(cls.id, 64, 1.2, on ? 0x8a7440 : 0x3a3a3a);
			pt.x = 8; pt.y = 8;
			c.addChild(pt);
			var nm:TextField = Ui.text(16, on ? Ui.GOLD : 0xffffff, true, "left", 0, true);
			nm.text = cls.name;
			nm.x = 80; nm.y = 8;
			c.addChild(nm);
			var ab:TextField = Ui.text(12, 0xe8c870, true, "left", w - 86, true);
			ab.text = cls.ability.name;
			ab.x = 80; ab.y = 31;
			c.addChild(ab);
			var best:int = Save.data.bestLevel ? int(Save.data.bestLevel[cls.id] || 0) : 0;
			if (eldmere || best > 0) {
				var tag:Sprite = eldmere ? chip("ELDMERE", 0xc0a0ff) : chip("BEST LVL " + best, 0x80d080);
				tag.x = 80; tag.y = 54;
				c.addChild(tag);
				if (eldmere && best > 0) { var bt:Sprite = chip("LVL " + best, 0x80d080); bt.x = 80 + tag.width + 4; bt.y = 54; c.addChild(bt); }
			}
			c.buttonMode = true;
			c.mouseChildren = false;
			c.doubleClickEnabled = true;
			c.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			c.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			c.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { if (picked != cls.id) { picked = cls.id; showNew(); } });
			c.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent):void { picked = cls.id; create(); });
			return c;
		}

		/** The picked class in full: portrait, what it does, its ability and stats, the name, and Create. */
		private function detailPane(layer:Sprite, x:int, y:int, w:int, h:int):void {
			var cls:Object = Data.CLASSES[picked];
			var p:Sprite = new Sprite();
			Ui.panel(p.graphics, 0, 0, w, h, 0x222222, 0x4a4a4a, 0.97);
			p.x = x; p.y = y;
			layer.addChild(p);
			var pt:Sprite = portrait(cls.id, 84, 2, 0x5a5a5a);
			pt.x = 12; pt.y = 12;
			p.addChild(pt);
			var nm:TextField = Ui.text(24, Ui.GOLD, true, "left", 0, true);
			nm.text = cls.name;
			nm.x = 108; nm.y = 12;
			p.addChild(nm);
			var kit:TextField = Ui.text(12, 0xa8a8a8, true, "left", w - 120, true);
			kit.text = cap(cls.weapon) + "  ·  " + cap(cls.armor) + "  ·  " + cap(cls.abilityType);
			kit.x = 108; kit.y = 46;
			p.addChild(kit);
			if (Data.ELDMERE_CLASSES[cls.id]) { var et:Sprite = chip("ELDMERE CLASS", 0xc0a0ff); et.x = 108; et.y = 68; p.addChild(et); }
			var d:TextField = Ui.text(13, 0xdddddd, false, "left", w - 24, true);
			d.text = cls.desc;
			d.x = 12; d.y = 102;
			p.addChild(d);
			// the ability
			var ay:int = 150;
			Ui.panel(p.graphics, 12, ay, w - 24, 44, 0x1a1a1a, 0x3a3a3a);
			var an:TextField = Ui.text(14, 0xe8c870, true, "left", 0, true);
			an.text = cls.ability.name;
			an.x = 20; an.y = ay + 3;
			p.addChild(an);
			var ac:TextField = Ui.text(11, 0x7fa8ff, true, "right", 80, true);
			ac.text = cls.ability.cost + " MP";
			ac.x = w - 100; ac.y = ay + 5;
			p.addChild(ac);
			var ad:TextField = Ui.text(11, 0xb8b8b8, false, "left", w - 40, true);
			ad.text = cls.ability.desc;
			ad.x = 20; ad.y = ay + 22;
			p.addChild(ad);
			// stats at their max, against the best of any class
			var mh:TextField = Ui.text(10, 0x8a8a8a, true, "left", 0, true);
			mh.text = "MAX STATS";
			mh.x = 12; mh.y = 199;
			p.addChild(mh);
			var sy:int = 214, stats:Array = ["hp", "mp", "att", "def", "spd", "dex", "vit", "wis"];
			var labels:Object = {hp: "HP", mp: "MP", att: "ATT", def: "DEF", spd: "SPD", dex: "DEX", vit: "VIT", wis: "WIS"};
			var cols:Object = {hp: 0xe03838, mp: 0x3d6fe8, att: 0xa040e0, def: 0x8a8a9a, spd: 0x40c040, dex: 0xff9020, vit: 0xd04040, wis: 0x40a0e0};
			var bw:int = int((w - 24 - 10) / 2);
			var sb:Shape = new Shape();
			p.addChild(sb);
			for (var i:int = 0; i < stats.length; i++) {
				var s:String = stats[i];
				var top:Number = 1;
				for each (var o:String in Data.CLASS_ORDER) top = Math.max(top, Data.CLASSES[o].max[s]);
				var bx:int = 12 + (i % 2) * (bw + 10), by:int = sy + int(i / 2) * 18;
				bar(sb.graphics, bx + 34, by, bw - 34, 14, cls.max[s] / top, cols[s], 0x141414);
				var sl:TextField = Ui.text(11, 0xcfcfcf, true, "left", 0, true);
				sl.text = labels[s];
				sl.x = bx; sl.y = by - 1;
				p.addChild(sl);
				var sv:TextField = Ui.text(10, 0xffffff, true, "right", bw - 40, true);
				sv.text = String(cls.max[s]);
				sv.x = bx + 34; sv.y = by;
				p.addChild(sv);
			}
			// name, seasonal, create
			var ny:int = h - 84;
			var nl:TextField = Ui.text(13, 0xbbbbbb, true, "left", 0, true);
			nl.text = "Name";
			nl.x = 12; nl.y = ny + 6;
			p.addChild(nl);
			var seas:Boolean = Online.connected && Online.welcome && Online.welcome.season;
			var fw:int = seas ? 150 : w - 70;
			Ui.panel(p.graphics, 58, ny, fw, 30, 0x141414, 0x6a6a6a);
			nameField = Ui.text(17, 0xffffff, true, "left", fw - 16);
			nameField.autoSize = "none";
			nameField.height = 26;
			nameField.x = 66; nameField.y = ny + 3;
			nameField.type = TextFieldType.INPUT;
			nameField.selectable = true;
			nameField.mouseEnabled = true;
			nameField.maxChars = 12;
			nameField.restrict = "A-Za-z0-9";
			nameField.text = heroName;
			p.addChild(nameField);
			seasonBox(p, 58 + fw + 10, ny + 5);
			var md:Object = Data.findMode(mode);
			var go:Sprite = goldButton("Create " + (md.id ? md.name + " " : "") + cls.name, w - 24, 40, create);
			go.x = 12; go.y = h - 48;
			p.addChild(go);
		}

		private static function cap(s:String):String { return s ? s.charAt(0).toUpperCase() + s.substr(1) : ""; }

		/** The big gold "Create" button. */
		private static function goldButton(label:String, w:int, h:int, onClick:Function):Sprite {
			var b:Sprite = new Sprite();
			var tf:TextField = Ui.text(17, 0xffffff, true, "center", w, true);
			tf.text = label;
			tf.y = (h - tf.height) / 2;
			var draw:Function = function(hover:Boolean):void {
				b.graphics.clear();
				Ui.panel(b.graphics, 0, 0, w, h, hover ? 0x8a6a1e : 0x6a5018, hover ? 0xffe7a0 : Ui.GOLD);
				b.graphics.beginFill(0xffffff, hover ? 0.12 : 0.07);
				b.graphics.drawRoundRect(3, 3, w - 6, h / 2 - 3, 8, 8);
				b.graphics.endFill();
			};
			draw(false);
			b.addChild(tf);
			b.filters = [new DropShadowFilter(2, 90, 0, 0.5, 4, 4, 1, 2)];
			b.buttonMode = true;
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onClick(); });
			return b;
		}

		private function create():void {
			var n:String = (nameField ? nameField.text : heroName).replace(/[^A-Za-z0-9]/g, "");
			if (!n) n = NAMES[int(Math.random() * NAMES.length)];
			Save.data.name = n;
			Save.flush();
			onPick(picked, n);
		}

		private function seasonBox(layer:Sprite, x:int, y:int):void {
			var ss:Object = Online.connected && Online.welcome ? Online.welcome.season : null;
			if (!ss) { seasonal = false; return; }
			var box:Sprite = new Sprite();
			var tf:TextField = Ui.text(12, 0x8fd16a, true, "left", 0, true);
			var draw:Function = function():void {
				box.graphics.clear();
				// (the whole line is clickable, label included)
				box.graphics.beginFill(0, 0);
				box.graphics.drawRect(0, 0, 24 + tf.width, 20);
				box.graphics.endFill();
				Ui.panel(box.graphics, 0, 1, 18, 18, 0x141414, 0x8fd16a);
				if (seasonal) { box.graphics.beginFill(0x8fd16a); box.graphics.drawRect(5, 6, 8, 8); box.graphics.endFill(); }
				tf.htmlText = "<b>Seasonal</b> <font color='#a0a0a0'>x2 ladder</font>";
			};
			tf.x = 24; tf.y = 2;
			box.addChild(tf);
			draw();
			draw();
			box.buttonMode = true;
			box.mouseChildren = false;
			box.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { seasonal = !seasonal; draw(); });
			box.x = x; box.y = y;
			layer.addChild(box);
		}

		// ---- delete and the graveyard ---------------------------------------------------------------

		private var graveLayer:Sprite;
		private var confirmLayer:Sprite;

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
					showHeroes();
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
			Ui.panel(graveLayer.graphics, px, py, w, h, 0x1c1c1c, EDGE, 0.97);
			graveLayer.graphics.beginFill(0x262626);
			graveLayer.graphics.drawRoundRect(px + 1, py + 1, w - 2, HEAD, 12, 12);
			graveLayer.graphics.drawRect(px + 1, py + HEAD - 10, w - 2, 10);
			graveLayer.graphics.endFill();
			var sk:Bitmap = new Bitmap(Sprites.get("skull"));
			sk.x = px + 16; sk.y = py + (HEAD - sk.height) / 2;
			graveLayer.addChild(sk);
			var t:TextField = Ui.text(20, 0xe0e0e0, true, "left", 0, true);
			t.text = "Graveyard";
			t.x = px + 24 + sk.width; t.y = py + (HEAD - t.height) / 2;
			graveLayer.addChild(t);
			var graves:Array = Save.data.graves as Array || [];
			if (graves.length == 0) {
				var none:TextField = Ui.text(15, 0x999999, false, "center", w, true);
				none.text = "No heroes have fallen yet.";
				none.x = px; none.y = py + 90;
				graveLayer.addChild(none);
			}
			for (var i:int = 0; i < Math.min(9, graves.length); i++) {
				var g:Object = graves[i];
				var ry:int = py + HEAD + 10 + i * 40;
				Ui.panel(graveLayer.graphics, px + 12, ry, w - 24, 36, i % 2 ? 0x222222 : 0x262626, 0x363636);
				var ic:Bitmap = new Bitmap(Sprites.get(g.skin || g.cls));
				ic.scaleX = ic.scaleY = 0.7;
				ic.x = px + 20; ic.y = ry + (36 - ic.height) / 2;
				graveLayer.addChild(ic);
				var row:TextField = Ui.text(14, 0xffffff, false, "left", w - 90, true);
				var cls:Object = Data.CLASSES[g.cls];
				row.htmlText = "<b>" + g.name + "</b>  <font color='#aaaaaa'>Lvl " + g.level + " " + (cls ? cls.name : g.cls) +
					"   " + g.kills + " kills   killed by </font><font color='#ff9a40'>" + g.killer + "</font>" +
					"   <font color='#ffb040'><b>" + Ui.commas(g.fame) + " fame</b></font>  <font color='#777777'>" + g.date + "</font>";
				row.x = px + 64; row.y = ry + 8;
				graveLayer.addChild(row);
			}
			var close:Sprite = Ui.button("Close", 120, 32, showGraveyard, 15);
			close.x = px + (w - 120) / 2; close.y = py + h - 44;
			graveLayer.addChild(close);
			addChild(graveLayer);
		}
	}
}
