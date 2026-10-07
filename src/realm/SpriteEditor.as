package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	/** Sprite Editor: a 16x16 pixel sprite with up to 16 colours (letters a-p). */
	public class SpriteEditor extends Sprite {
		public static const SIZE:int = 16;
		private static const CELL:int = 30;
		private static const KEYS:String = "abcdefghijklmnop";
		private static const DEFAULT_PAL:Array = [0x1a1a22, 0xf4f4f4, 0xd03030, 0x8a1818, 0xf0c030, 0x8a5a2a, 0x3a9a3a, 0x1e6a1e,
			0x4a8aff, 0x2a4a9a, 0xa040e0, 0x602090, 0xf5dc72, 0x9a9aa6, 0x5a5a62, 0xff8040];
		private static const PRESETS:Array = [
			0x000000, 0x1a1a22, 0x3a3a44, 0x5a5a62, 0x8a8a96, 0xb8b8c4, 0xe0e0e8, 0xffffff,
			0x5a1010, 0x8a1818, 0xd03030, 0xff6060, 0xff9a9a, 0x6a3010, 0xa05020, 0xff8040,
			0x8a5a2a, 0xc08040, 0xf0c030, 0xffe070, 0xf5dc72, 0x3a4a10, 0x6a8a20, 0xb0e040,
			0x1e6a1e, 0x3a9a3a, 0x60e060, 0xa0ffa0, 0x105048, 0x20a090, 0x60f0d0, 0x2a4a9a,
			0x4a8aff, 0x8ac0ff, 0xc8e4ff, 0x301060, 0x602090, 0xa040e0, 0xd090ff, 0xff60c0];

		private var onDone:Function;
		private var rows:Array = [];
		private var pal:Object = {};
		private var slot:int = 1;
		private var tool:String = "pen";
		private var mirror:Boolean = false;
		private var painting:Boolean = false;
		private var gridBmp:Bitmap = new Bitmap(new BitmapData(SIZE * CELL, SIZE * CELL, false, 0));
		private var gridLayer:Sprite = new Sprite();
		private var side:Sprite = new Sprite();
		private var preview:Sprite = new Sprite();
		private var nameTf:TextField;
		private var info:TextField;

		public function SpriteEditor(name:String, onDone:Function) {
			this.onDone = onDone;
			var saved:Object = name ? CreatorData.load("sprites", name) : null;
			for (var i:int = 0; i < 16; i++) pal[KEYS.charAt(i)] = saved && saved.pal[KEYS.charAt(i)] != undefined ? saved.pal[KEYS.charAt(i)] : DEFAULT_PAL[i];
			if (saved) rows = saved.rows.concat();
			else for (i = 0; i < SIZE; i++) rows.push("................");
			Ui.panel(graphics, 0, 0, Ui.W, Ui.H, 0x16171c, 0x80e080, 1);
			var title:TextField = Ui.text(24, 0x80e080, true, "left", 300, true);
			title.text = "Sprite Editor";
			title.x = 20; title.y = 16;
			addChild(title);
			var nl:TextField = Ui.text(14, 0xbbbbbb, true, "left", 60);
			nl.text = "Name";
			nl.x = 200; nl.y = 24;
			addChild(nl);
			nameTf = Ui.input(180, name || "My Sprite", 20);
			nameTf.x = 250; nameTf.y = 20;
			addChild(nameTf);
			var save:Sprite = Ui.button("Save", 90, 30, saveSprite, 15);
			save.x = 450; save.y = 18;
			addChild(save);
			var back:Sprite = Ui.button("Back", 90, 30, function():void { onDone(); }, 15);
			back.x = 550; back.y = 18;
			addChild(back);
			info = Ui.text(13, 0x9a9a9a, false, "left", 420);
			info.x = 660; info.y = 24;
			addChild(info);
			info.text = "Click and drag to draw. The black outline is added for you.";

			gridLayer.x = 40; gridLayer.y = 90;
			gridLayer.addChild(gridBmp);
			addChild(gridLayer);
			gridLayer.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { painting = true; paint(e.localX, e.localY); });
			gridLayer.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void { if (painting && e.buttonDown) paint(e.localX, e.localY); });
			gridLayer.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { painting = false; });
			addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void { painting = false; });
			addChild(side);
			addChild(preview);
			buildSide();
			redraw();
		}

		private function buildSide():void {
			side.removeChildren();
			side.graphics.clear();
			var x0:int = 540, y:int = 90;
			var label:Function = function(t:String):void {
				var h:TextField = Ui.text(13, Ui.GOLD, true, "left", 300);
				h.text = t;
				h.x = x0; h.y = y;
				side.addChild(h);
				y += 20;
			};
			label("Your colours (click one to draw with it)");
			for (var i:int = 0; i < 16; i++) {
				var sw:Sprite = colourBox(pal[KEYS.charAt(i)], i == slot, slotFn(i), 30);
				sw.x = x0 + (i % 8) * 34; sw.y = y + int(i / 8) * 34;
				side.addChild(sw);
			}
			y += 76;
			label("Change the selected colour");
			for (i = 0; i < PRESETS.length; i++) {
				var ps:Sprite = colourBox(PRESETS[i], false, presetFn(PRESETS[i]), 22);
				ps.x = x0 + (i % 8) * 26; ps.y = y + int(i / 8) * 26;
				side.addChild(ps);
			}
			y += Math.ceil(PRESETS.length / 8) * 26 + 10;
			label("Tools");
			var tools:Array = [["Pen", "pen"], ["Eraser", "erase"], ["Fill", "fill"]];
			for (i = 0; i < tools.length; i++) {
				var tb:Sprite = Ui.button(tools[i][0], 80, 28, toolFn(tools[i][1]), 13);
				tb.alpha = tool == tools[i][1] ? 1 : 0.55;
				tb.x = x0 + i * 86; tb.y = y;
				side.addChild(tb);
			}
			var mb:Sprite = Ui.button("Mirror: " + (mirror ? "On" : "Off"), 110, 28, function():void { mirror = !mirror; buildSide(); }, 13);
			mb.x = x0; mb.y = y + 34;
			side.addChild(mb);
			var cl:Sprite = Ui.button("Clear", 80, 28, function():void {
				for (var k:int = 0; k < SIZE; k++) rows[k] = "................";
				redraw();
			}, 13);
			cl.x = x0 + 116; cl.y = y + 34;
			side.addChild(cl);
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

		private function slotFn(i:int):Function {
			return function():void { slot = i; if (tool == "erase") tool = "pen"; buildSide(); };
		}

		private function presetFn(c:uint):Function {
			return function():void { pal[KEYS.charAt(slot)] = c; buildSide(); redraw(); };
		}

		private function toolFn(t:String):Function {
			return function():void { tool = t; buildSide(); };
		}

		private function setPx(x:int, y:int, ch:String):void {
			var r:String = rows[y];
			rows[y] = r.substr(0, x) + ch + r.substr(x + 1);
		}

		private function paint(lx:Number, ly:Number):void {
			var x:int = int(lx / CELL), y:int = int(ly / CELL);
			if (x < 0 || y < 0 || x >= SIZE || y >= SIZE) return;
			var ch:String = tool == "erase" ? "." : KEYS.charAt(slot);
			if (tool == "fill") { fill(x, y, ch); redraw(); return; }
			setPx(x, y, ch);
			if (mirror) setPx(SIZE - 1 - x, y, ch);
			redraw();
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

		private function redraw():void {
			var bd:BitmapData = gridBmp.bitmapData;
			var r:Rectangle = new Rectangle();
			for (var y:int = 0; y < SIZE; y++) {
				for (var x:int = 0; x < SIZE; x++) {
					var ch:String = String(rows[y]).charAt(x);
					r.x = x * CELL; r.y = y * CELL; r.width = CELL; r.height = CELL;
					// transparent pixels show a checkerboard
					bd.fillRect(r, ch == "." ? ((x + y) % 2 ? 0x2a2a32 : 0x34343e) : pal[ch]);
					r.width = 1;
					bd.fillRect(r, 0x101014);
					r.width = CELL; r.height = 1;
					bd.fillRect(r, 0x101014);
				}
			}
			// previews: the size it has in game, and bigger
			preview.removeChildren();
			var art:BitmapData = Sprites.build(rows, pal, 3, 2);
			var bg:Shape = new Shape();
			Ui.panel(bg.graphics, 0, 0, 230, 120, 0x2a5a2a, 0x4a4a5a);
			preview.addChild(bg);
			var small:Bitmap = new Bitmap(art);
			small.x = 20; small.y = (120 - art.height) / 2;
			preview.addChild(small);
			var big:Bitmap = new Bitmap(art);
			big.scaleX = big.scaleY = 2;
			big.x = 100; big.y = (120 - art.height * 2) / 2;
			preview.addChild(big);
			preview.x = 830; preview.y = 470;
		}

		private function saveSprite():void {
			var n:String = nameTf.text.replace(/^\s+|\s+$/g, "");
			if (!n) { info.text = "Give the sprite a name first."; return; }
			var used:Boolean = false;
			for each (var r:String in rows) if (r.replace(/\./g, "").length) used = true;
			if (!used) { info.text = "Draw something first."; return; }
			CreatorData.store("sprites", n, {rows: rows.concat(), pal: pal});
			CreatorData.useSprite(n);
			info.text = "Saved \"" + n + "\". Pick it as a boss's look in the Boss Maker.";
		}
	}
}
