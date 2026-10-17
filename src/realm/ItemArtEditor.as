package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	/**
	 * Item Art Maker (Creator Tools, admins): redraw the inventory art of any tiered
	 * weapon, ability, armour or ring, 8x8 like the game's own. Saving sends it to the
	 * server, which keeps it and hands it to everyone (Sprites.itemArt). Rings are drawn
	 * once per tier: colours "o" and "p" become each stat's gem shade and gem.
	 */
	public class ItemArtEditor extends Sprite {
		public static const SIZE:int = 8;
		private static const CELL:int = 44;
		private static const KEYS:String = "abcdefghijklmnop";
		private static const DEFAULT_PAL:Array = [0x1a1a22, 0xf4f4f4, 0xd03030, 0x8a1818, 0xf0c030, 0x8a5a2a, 0x3a9a3a, 0x1e6a1e,
			0x4a8aff, 0x2a4a9a, 0xa040e0, 0x602090, 0xf5dc72, 0x9a9aa6, 0x6a3a9a, 0xa060ff];
		private static const PRESETS:Array = [
			0x000000, 0x1a1a22, 0x3a3a44, 0x5a5a62, 0x8a8a96, 0xb8b8c4, 0xe0e0e8, 0xffffff,
			0x5a1010, 0x8a1818, 0xd03030, 0xff6060, 0xff9a9a, 0x6a3010, 0xa05020, 0xff8040,
			0x3a2414, 0x8a5a2a, 0xc08040, 0xf0c030, 0xffe070, 0x3a4a10, 0x6a8a20, 0xb0e040,
			0x1e6a1e, 0x3a9a3a, 0x60e060, 0xa0ffa0, 0x105048, 0x20a090, 0x60f0d0, 0x2a4a9a,
			0x4a8aff, 0x8ac0ff, 0xc8e4ff, 0x301060, 0x602090, 0xa040e0, 0xd090ff, 0xff60c0];
		private static const CATS:Array = [
			{id: "weapon", name: "Weapons", subs: ["staff", "bow", "sword", "wand", "dagger"], tiers: 8},
			{id: "ability", name: "Abilities", subs: ["spell", "quiver", "shield", "tome", "cloak", "helm", "skull", "trap", "lyre", "flask", "hourglass"], tiers: 7},
			{id: "armor", name: "Armour", subs: ["robe", "leather", "heavy"], tiers: 8},
			{id: "ring", name: "Rings", subs: ["ring"], tiers: 6}
		];
		private static const RING_STATS:Array = ["att", "def", "spd", "dex", "vit", "wis", "hp", "mp"];

		private var onDone:Function;
		private var cat:Object = CATS[0];
		private var sub:String = "staff";
		private var tier:int = 0;
		private var ringStat:String = "att";
		private var rows:Array = [];
		private var pal:Object = {};
		private var slot:int = 1;
		private var tool:String = "pen";
		private var mirror:Boolean = false;
		private var painting:Boolean = false;
		private var erasing:Boolean = false;
		private var dirty:Boolean = false;
		private var undo:Array = [];
		private var gridBmp:Bitmap = new Bitmap(new BitmapData(SIZE * CELL, SIZE * CELL, false, 0));
		private var gridLayer:Sprite = new Sprite();
		private var left:Sprite = new Sprite();
		private var side:Sprite = new Sprite();
		private var tools:Sprite = new Sprite();
		private var preview:Sprite = new Sprite();
		private var info:TextField;
		private var hexTf:TextField;

		public function ItemArtEditor(onDone:Function) {
			this.onDone = onDone;
			Ui.panel(graphics, 0, 0, Ui.W, Ui.H, 0x16171c, 0xffd75e, 1);
			var title:TextField = Ui.text(24, Ui.GOLD, true, "left", 300, true);
			title.text = "Item Art Maker";
			title.x = 20; title.y = 14;
			addChild(title);
			var save:Sprite = Ui.button("Save for everyone", 160, 30, saveArt, 14);
			save.x = 680; save.y = 14;
			addChild(save);
			var reset:Sprite = Ui.button("Back to game art", 150, 30, resetArt, 14);
			reset.x = 848; reset.y = 14;
			addChild(reset);
			var back:Sprite = Ui.button("Back", 80, 30, function():void { Online.onItemArt = null; onDone(); }, 14);
			back.x = 1006; back.y = 14;
			addChild(back);
			info = Ui.text(13, 0x9a9a9a, false, "left", 640);
			info.x = 20; info.y = 50;
			addChild(info);

			gridLayer.x = 310; gridLayer.y = 82;
			gridLayer.addChild(gridBmp);
			addChild(gridLayer);
			gridLayer.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { stroke(false, e); });
			gridLayer.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, function(e:MouseEvent):void { stroke(true, e); });
			gridLayer.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void { if (painting) paint(e.localX, e.localY); });
			gridLayer.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { painting = false; });
			addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void { painting = false; });
			addEventListener(MouseEvent.RIGHT_MOUSE_UP, function(e:MouseEvent):void { painting = false; });
			addChild(left);
			addChild(side);
			addChild(tools);
			addChild(preview);
			// someone (or this editor) saved art: the list and the drawing follow
			Online.onItemArt = function():void { buildLeft(); };
			pick(CATS[0], "staff", 0);
		}

		// ------------------------------------------------------------ which item
		private function item(t:int = -1):Object {
			if (t < 0) t = tier;
			switch (cat.id) {
				case "weapon": return Data.makeWeapon(sub, t);
				case "ability": return Data.makeAbility(sub, t);
				case "armor": return Data.makeArmor(sub, t);
			}
			return Data.makeRing(ringStat, t);
		}

		private function key():String { return Sprites.itemArtKey(item()); }

		private function pick(c:Object, s:String, t:int):void {
			cat = c; sub = s; tier = t;
			undo.length = 0;
			var saved:Object = Sprites.itemArt[key()];
			if (saved) {
				rows = saved.rows.concat();
				for (var i:int = 0; i < 16; i++) pal[KEYS.charAt(i)] = saved.pal[KEYS.charAt(i)] != undefined ? saved.pal[KEYS.charAt(i)] : DEFAULT_PAL[i];
				info.text = item().name + ": your drawing. Change it and Save for everyone.";
			} else {
				fromGame();
				info.text = item().name + ": the game's own art, to start from. Draw over it, or Clear and start fresh.";
			}
			dirty = false;
			buildLeft();
			buildSide();
			buildTools();
			redraw();
		}

		/** Loads the game's own 8x8 drawing of this item into the grid (rings: the gem becomes o/p). */
		private function fromGame():void {
			for (var i:int = 0; i < 16; i++) pal[KEYS.charAt(i)] = DEFAULT_PAL[i];
			rows = [];
			for (i = 0; i < SIZE; i++) rows.push("........");
			var art:Object = ItemArt.art(item());
			if (!art) return;
			var ring:Boolean = cat.id == "ring";
			var letterOf:Object = {}, next:int = 0;
			var limit:int = ring ? 14 : 16;
			for (var y:int = 0; y < SIZE && y < art.rows.length; y++) {
				var row:String = "";
				for (var x:int = 0; x < SIZE; x++) {
					var ch:String = String(art.rows[y]).charAt(x);
					if (!ch || ch == "." || art.pal[ch] == undefined) { row += "."; continue; }
					if (ring && ch == "R") { row += "p"; continue; }
					if (ring && ch == "r") { row += "o"; continue; }
					var col:uint = art.pal[ch];
					if (letterOf[col] == undefined) {
						if (next < limit) { letterOf[col] = KEYS.charAt(next); pal[KEYS.charAt(next)] = col; next++; }
						else letterOf[col] = KEYS.charAt(limit - 1);
					}
					row += letterOf[col];
				}
				rows[y] = row;
			}
		}

		private function buildLeft():void {
			left.removeChildren();
			var x0:int = 20, y:int = 82;
			for (var i:int = 0; i < CATS.length; i++) {
				var cb:Sprite = Ui.button(CATS[i].name, 64, 28, catFn(CATS[i]), 12);
				cb.alpha = CATS[i] == cat ? 1 : 0.5;
				cb.x = x0 + i * 68; cb.y = y;
				left.addChild(cb);
			}
			y += 36;
			if (cat.id != "ring") {
				for (i = 0; i < cat.subs.length; i++) {
					var sb:Sprite = Ui.button(cap(cat.subs[i]), 86, 24, subFn(cat.subs[i]), 12);
					sb.alpha = cat.subs[i] == sub ? 1 : 0.5;
					sb.x = x0 + (i % 3) * 90; sb.y = y + int(i / 3) * 28;
					left.addChild(sb);
				}
				y += Math.ceil(cat.subs.length / 3) * 28 + 6;
			}
			for (var t:int = 0; t < cat.tiers; t++) {
				var it:Object = item(t);
				var r:Sprite = new Sprite();
				Ui.panel(r.graphics, 0, 0, 266, 28, t == tier ? 0x3a3424 : 0x24262e, t == tier ? Ui.GOLD : 0x3a3a4a);
				var ic:Bitmap = new Bitmap(Sprites.icon(it));
				ic.scaleX = ic.scaleY = 24 / ic.width;
				ic.x = 4; ic.y = 2;
				r.addChild(ic);
				var nm:TextField = Ui.text(12, 0xffffff, true, "left", 190);
				nm.text = "T" + t + "  " + (cat.id == "ring" ? it.name.replace(/ ?[A-Z][a-z]+$/, "") + " ..." : it.name);
				nm.x = 32; nm.y = 6;
				r.addChild(nm);
				if (Sprites.itemArt[Sprites.itemArtKey(it)]) {
					var mk:TextField = Ui.text(11, 0x80e080, true, "right", 50);
					mk.text = "drawn";
					mk.x = 210; mk.y = 7;
					r.addChild(mk);
				}
				r.buttonMode = true;
				r.mouseChildren = false;
				r.addEventListener(MouseEvent.CLICK, tierFn(t));
				r.x = x0; r.y = y + t * 31;
				left.addChild(r);
			}
		}

		private static function cap(s:String):String { return s.charAt(0).toUpperCase() + s.substr(1); }
		private function catFn(c:Object):Function { return function():void { if (leaveOk()) pick(c, c.subs[0], 0); }; }
		private function subFn(s:String):Function { return function():void { if (leaveOk()) pick(cat, s, 0); }; }
		private function tierFn(t:int):Function { return function(e:MouseEvent):void { if (leaveOk()) pick(cat, sub, t); }; }

		/** Leaving a drawing you haven't saved: click again to go anyway. */
		private var warned:Boolean = false;
		private function leaveOk():Boolean {
			if (!dirty || warned) { warned = false; return true; }
			warned = true;
			info.text = "You haven't saved this drawing. Click again to leave it anyway.";
			info.textColor = 0xffb040;
			return false;
		}

		// ------------------------------------------------------------ colours and tools
		private function buildSide():void {
			side.removeChildren();
			var x0:int = 690, y:int = 82;
			var label:Function = function(t:String):void {
				var h:TextField = Ui.text(13, Ui.GOLD, true, "left", 390);
				h.text = t;
				h.x = x0; h.y = y;
				side.addChild(h);
				y += 20;
			};
			label("Your colours (click one to draw with it)");
			for (var i:int = 0; i < 16; i++) {
				var sw:Sprite = colourBox(pal[KEYS.charAt(i)], i == slot, slotFn(i), 34);
				sw.x = x0 + (i % 8) * 40; sw.y = y + int(i / 8) * 40;
				side.addChild(sw);
				if (cat.id == "ring" && i >= 14) {
					var gl:TextField = Ui.text(10, 0xffffff, true, "center", 34, true);
					gl.text = i == 15 ? "GEM" : "gem\nshade";
					gl.mouseEnabled = false;
					gl.x = sw.x; gl.y = sw.y + (i == 15 ? 9 : 2);
					side.addChild(gl);
				}
			}
			y += 84;
			label("Change the selected colour");
			for (i = 0; i < PRESETS.length; i++) {
				var ps:Sprite = colourBox(PRESETS[i], false, presetFn(PRESETS[i]), 24);
				ps.x = x0 + (i % 8) * 28; ps.y = y + int(i / 8) * 28;
				side.addChild(ps);
			}
			y += 5 * 28 + 4;
			hexTf = Ui.input(90, "#" + hex6(pal[KEYS.charAt(slot)]), 7, 13);
			hexTf.x = x0; hexTf.y = y;
			side.addChild(hexTf);
			var set:Sprite = Ui.button("Set colour", 90, 24, function():void {
				var v:Number = parseInt(String(hexTf.text).replace(/[^0-9a-fA-F]/g, ""), 16);
				if (!isNaN(v) && v >= 0 && v <= 0xffffff) { pal[KEYS.charAt(slot)] = uint(v); changed(); buildSide(); }
			}, 12);
			set.x = x0 + 98; set.y = y - 1;
			side.addChild(set);
			if (cat.id == "ring") {
				var st:Sprite = Ui.button("Gem: " + Data.STAT_NAMES[ringStat], 150, 24, function():void {
					ringStat = RING_STATS[(RING_STATS.indexOf(ringStat) + 1) % RING_STATS.length];
					buildSide(); buildLeft(); redraw();
				}, 12);
				st.x = x0 + 196; st.y = y - 1;
				side.addChild(st);
			}
		}

		private static function hex6(c:uint):String { var s:String = c.toString(16); while (s.length < 6) s = "0" + s; return s; }

		private function buildTools():void {
			tools.removeChildren();
			var x0:int = 310, y:int = 82 + SIZE * CELL + 12;
			var list:Array = [["Pen", "pen"], ["Eraser", "erase"], ["Fill", "fill"], ["Pick colour", "pick"]];
			for (var i:int = 0; i < list.length; i++) {
				var tb:Sprite = Ui.button(list[i][0], 84, 28, toolFn(list[i][1]), 12);
				tb.alpha = tool == list[i][1] ? 1 : 0.5;
				tb.x = x0 + i * 89; tb.y = y;
				tools.addChild(tb);
			}
			var row2:Array = [
				["Mirror: " + (mirror ? "On" : "Off"), function():void { mirror = !mirror; buildTools(); }],
				["Undo", function():void { if (undo.length) { rows = undo.pop(); changed(); } }],
				["Clear", function():void { keep(); for (var k:int = 0; k < SIZE; k++) rows[k] = "........"; changed(); }],
				["Game's art", function():void { keep(); var p:Object = {}; for (var c:String in pal) p[c] = pal[c]; fromGame(); changed(); buildSide(); }]
			];
			for (i = 0; i < row2.length; i++) {
				var b2:Sprite = Ui.button(row2[i][0], 84, 28, row2[i][1], 12);
				b2.x = x0 + i * 89; b2.y = y + 34;
				tools.addChild(b2);
			}
			var tip:TextField = Ui.text(12, 0x8a8a9a, false, "left", 360);
			tip.text = "Left-click draws, right-click erases. The dark outline is added for you." + (cat.id == "ring" ? " The GEM colours turn into each stat's colour." : "");
			tip.x = x0; tip.y = y + 72;
			tools.addChild(tip);
		}

		private function colourBox(col:uint, on:Boolean, fn:Function, s:int):Sprite {
			var b:Sprite = new Sprite();
			b.graphics.lineStyle(2, on ? 0xffd75e : 0x4a4a5a);
			b.graphics.beginFill(col);
			b.graphics.drawRect(0, 0, s, s);
			b.graphics.endFill();
			b.buttonMode = true;
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { fn(); });
			return b;
		}

		private function slotFn(i:int):Function { return function():void { slot = i; if (tool == "erase" || tool == "pick") tool = "pen"; buildSide(); buildTools(); }; }
		private function presetFn(c:uint):Function { return function():void { pal[KEYS.charAt(slot)] = c; changed(); buildSide(); }; }
		private function toolFn(t:String):Function { return function():void { tool = t; buildTools(); }; }

		// ------------------------------------------------------------ drawing
		private function keep():void {
			undo.push(rows.concat());
			if (undo.length > 60) undo.shift();
		}

		private function stroke(right:Boolean, e:MouseEvent):void {
			erasing = right;
			if (tool != "pick") keep();
			painting = tool == "pen" || tool == "erase" || right;
			paint(e.localX, e.localY);
		}

		private function setPx(x:int, y:int, ch:String):void {
			var r:String = rows[y];
			rows[y] = r.substr(0, x) + ch + r.substr(x + 1);
		}

		private function paint(lx:Number, ly:Number):void {
			var x:int = int(lx / CELL), y:int = int(ly / CELL);
			if (x < 0 || y < 0 || x >= SIZE || y >= SIZE) return;
			var ch:String = erasing || tool == "erase" ? "." : KEYS.charAt(slot);
			if (!erasing && tool == "pick") {
				var got:String = String(rows[y]).charAt(x);
				if (got != ".") { slot = KEYS.indexOf(got); tool = "pen"; buildSide(); buildTools(); }
				return;
			}
			if (!erasing && tool == "fill") { fill(x, y, ch); changed(); return; }
			setPx(x, y, ch);
			if (mirror) setPx(SIZE - 1 - x, y, ch);
			changed();
		}

		private function fill(x:int, y:int, ch:String):void {
			var from:String = String(rows[y]).charAt(x);
			if (from == ch) return;
			var stack:Array = [[x, y]];
			while (stack.length) {
				var p:Array = stack.pop();
				if (p[0] < 0 || p[1] < 0 || p[0] >= SIZE || p[1] >= SIZE) continue;
				if (String(rows[p[1]]).charAt(p[0]) != from) continue;
				setPx(p[0], p[1], ch);
				stack.push([p[0] + 1, p[1]], [p[0] - 1, p[1]], [p[0], p[1] + 1], [p[0], p[1] - 1]);
			}
		}

		private function changed():void {
			dirty = true;
			warned = false;
			info.textColor = 0x9a9a9a;
			redraw();
		}

		/** The colours as the game shows them (rings: o/p are the gem of the stat being previewed). */
		private function shownPal():Object {
			var p:Object = {};
			for (var k:String in pal) p[k] = pal[k];
			if (cat.id == "ring") { var gem:uint = Data.STAT_COLORS[ringStat]; p.p = gem; p.o = Sprites.shade(gem, 0.6); }
			return p;
		}

		private function redraw():void {
			var bd:BitmapData = gridBmp.bitmapData;
			var sp:Object = shownPal();
			var r:Rectangle = new Rectangle();
			for (var y:int = 0; y < SIZE; y++) {
				for (var x:int = 0; x < SIZE; x++) {
					var ch:String = String(rows[y]).charAt(x);
					r.x = x * CELL; r.y = y * CELL; r.width = CELL; r.height = CELL;
					bd.fillRect(r, ch == "." ? ((x + y) % 2 ? 0x2a2a32 : 0x34343e) : sp[ch]);
					r.width = 1;
					bd.fillRect(r, 0x101014);
					r.width = CELL; r.height = 1;
					bd.fillRect(r, 0x101014);
				}
			}
			// previews: in an inventory slot as the game shows it, bigger, and the game's old art
			preview.removeChildren();
			preview.x = 690; preview.y = 452;
			var bg:Shape = new Shape();
			Ui.panel(bg.graphics, 0, 0, 390, 166, 0x1c1e24, 0x4a4a5a);
			preview.addChild(bg);
			var art:BitmapData = Sprites.build(rows, sp, 4, 2);
			var s1:Sprite = slotBox(art, "In your bag");
			s1.x = 14; s1.y = 30;
			preview.addChild(s1);
			var big:Bitmap = new Bitmap(art);
			big.scaleX = big.scaleY = 3;
			big.x = 104; big.y = 26;
			preview.addChild(big);
			var cap1:TextField = Ui.text(11, 0x9a9a9a, false, "center", 108);
			cap1.text = "Up close";
			cap1.x = 104; cap1.y = 8;
			preview.addChild(cap1);
			var was:Object = ItemArt.art(item());
			if (was) {
				var s2:Sprite = slotBox(Sprites.build(was.rows, was.pal, 4, 2), "Game's art");
				s2.x = 300; s2.y = 30;
				preview.addChild(s2);
			}
			var nm:TextField = Ui.text(13, 0xffffff, true, "left", 360, true);
			nm.text = item().name + (dirty ? "  (not saved)" : "");
			nm.x = 14; nm.y = 136;
			preview.addChild(nm);
		}

		private function slotBox(art:BitmapData, label:String):Sprite {
			var b:Sprite = new Sprite();
			b.graphics.lineStyle(1, 0x1a1a1a);
			b.graphics.beginFill(0x545454);
			b.graphics.drawRoundRect(0, 0, 48, 48, 10, 10);
			b.graphics.endFill();
			var ic:Bitmap = new Bitmap(art);
			ic.x = int((48 - art.width) / 2); ic.y = int((48 - art.height) / 2);
			b.addChild(ic);
			var tt:TextField = Ui.text(13, 0xffffff, true, "right", 32, true);
			tt.text = Data.tierLabel(item());
			tt.x = 15; tt.y = 28;
			b.addChild(tt);
			var lb:TextField = Ui.text(11, 0x9a9a9a, false, "center", 80);
			lb.text = label;
			lb.x = -16; lb.y = -22;
			b.addChild(lb);
			return b;
		}

		// ------------------------------------------------------------ saving
		private function saveArt():void {
			var used:Boolean = false;
			for each (var rr:String in rows) if (rr.replace(/\./g, "").length) used = true;
			if (!used) { info.text = "Draw something first."; return; }
			if (!Online.connected) { info.text = "Not connected to the server: can't save."; return; }
			var p:Object = {};
			for (var i:int = 0; i < 16; i++) p[KEYS.charAt(i)] = pal[KEYS.charAt(i)];
			Online.send({t: "itemArtPut", key: key(), rows: rows.concat(), pal: p});
			dirty = false;
			info.textColor = 0x80e080;
			info.text = "Saved " + item().name + (cat.id == "ring" ? " (every stat)" : "") + ": everyone sees it now.";
			redraw();
		}

		private function resetArt():void {
			if (!Sprites.itemArt[key()]) { keep(); fromGame(); dirty = false; buildSide(); redraw(); info.text = "This item already uses the game's own art."; return; }
			if (!Online.connected) { info.text = "Not connected to the server."; return; }
			Online.send({t: "itemArtPut", key: key(), del: true});
			fromGame();
			dirty = false;
			buildSide();
			redraw();
			info.textColor = 0x80e080;
			info.text = item().name + " is back to the game's own art.";
		}
	}
}
