package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	/** Map Builder: paint a boss arena tile by tile. */
	public class MapEditor extends Sprite {
		private static const AREA_X:int = 20, AREA_Y:int = 70, AREA_W:int = 740, AREA_H:int = 550;
		private static const TILES:Array = [
			{id: World.ARENA, name: "Arena"}, {id: World.STONE, name: "Stone"}, {id: World.PLAZA, name: "Plaza"},
			{id: World.BRICK, name: "Brick"}, {id: World.CARPET, name: "Carpet"}, {id: World.BLOODSTONE, name: "Bloodstone"},
			{id: World.GRASS, name: "Grass"}, {id: World.DARK, name: "Dark grass"}, {id: World.SAND, name: "Sand"},
			{id: World.GOD, name: "Godstone"}, {id: World.RUIN, name: "Ruin"}, {id: World.ROAD, name: "Road"},
			{id: World.WATER, name: "Water (slow)"}, {id: World.LAVA, name: "Lava (burns)"}, {id: World.WALL, name: "Wall"},
			{id: World.VOID, name: "Void (empty)"}
		];
		private static const OBJS:Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 19];

		private var onDone:Function;
		private var map:Object;
		private var nameTf:TextField;
		private var info:TextField;
		private var grid:Bitmap = new Bitmap();
		private var marks:Shape = new Shape();
		private var gridLayer:Sprite = new Sprite();
		private var cell:int = 16;
		private var gx:int = 0, gy:int = 0;
		/** "tile", "obj", "erase", "spawn" or "boss". */
		private var tool:String = "tile";
		private var brush:int = World.STONE;
		private var objBrush:int = 1;
		private var painting:Boolean = false;
		private var palette:Sprite = new Sprite();
		private var sizeTf:TextField;

		public function MapEditor(name:String, onDone:Function) {
			this.onDone = onDone;
			map = name ? CreatorData.load("maps", name) : null;
			if (!map) map = Game.defaultArena();
			Ui.panel(graphics, 0, 0, Ui.W, Ui.H, 0x16171c, 0x60c0ff, 1);
			var title:TextField = Ui.text(24, 0x60c0ff, true, "left", 300, true);
			title.text = "Map Builder";
			title.x = 20; title.y = 16;
			addChild(title);
			var nl:TextField = Ui.text(14, 0xbbbbbb, true, "left", 60);
			nl.text = "Name";
			nl.x = 200; nl.y = 24;
			addChild(nl);
			nameTf = Ui.input(180, name || "My Arena", 20);
			nameTf.x = 250; nameTf.y = 20;
			addChild(nameTf);
			var save:Sprite = Ui.button("Save", 90, 30, saveMap, 15);
			save.x = 450; save.y = 18;
			addChild(save);
			var back:Sprite = Ui.button("Back", 90, 30, function():void { onDone(); }, 15);
			back.x = 550; back.y = 18;
			addChild(back);
			info = Ui.text(13, 0x9a9a9a, false, "left", 420);
			info.x = 660; info.y = 24;
			addChild(info);

			gridLayer.addChild(grid);
			gridLayer.addChild(marks);
			addChild(gridLayer);
			gridLayer.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { painting = true; paintAt(e.localX, e.localY); });
			gridLayer.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void { if (painting && e.buttonDown) paintAt(e.localX, e.localY); });
			addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void { painting = false; });
			gridLayer.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { painting = false; });
			addChild(palette);
			buildPalette();
			layout();
			setInfo("Pick a floor or decoration on the right, then click and drag on the map.");
		}

		private function setInfo(t:String):void { info.text = t; }

		// ------------------------------------------------------------ palette
		private function buildPalette():void {
			palette.removeChildren();
			palette.graphics.clear();
			var px:int = 780, y:int = 66;
			Ui.panel(palette.graphics, px - 8, y - 6, 316, Ui.H - y - 6, 0x1e2026, 0x3a3a4a);
			var head:Function = function(t:String):void {
				var h:TextField = Ui.text(13, Ui.GOLD, true, "left", 300);
				h.text = t;
				h.x = px; h.y = y;
				palette.addChild(h);
				y += 20;
			};
			head("Floors");
			for (var i:int = 0; i < TILES.length; i++) {
				var tdef:Object = TILES[i];
				var b:Sprite = swatch(tdef.name, World.MINI_COL[tdef.id], tool == "tile" && brush == tdef.id, tileFn(tdef.id));
				b.x = px + (i % 2) * 150; b.y = y + int(i / 2) * 26;
				palette.addChild(b);
			}
			y += Math.ceil(TILES.length / 2) * 26 + 6;
			head("Decorations");
			for (i = 0; i < OBJS.length; i++) {
				var ob:Sprite = objButton(OBJS[i]);
				ob.x = px + (i % 7) * 42; ob.y = y + int(i / 7) * 42;
				palette.addChild(ob);
			}
			y += Math.ceil(OBJS.length / 7) * 42 + 4;
			head("Markers and tools");
			var tools:Array = [["Start point", "spawn", 0x60ff60], ["Boss spot", "boss", 0xff5050], ["Erase decoration", "erase", 0xaaaaaa]];
			for (i = 0; i < tools.length; i++) {
				var tb:Sprite = swatch(tools[i][0], tools[i][2], tool == tools[i][1], toolFn(tools[i][1]));
				tb.x = px + (i % 2) * 150; tb.y = y + int(i / 2) * 26;
				palette.addChild(tb);
			}
			y += 58;
			var fill:Sprite = Ui.button("Fill with floor", 145, 26, function():void {
				for (var k:int = 0; k < map.tiles.length; k++) { map.tiles[k] = brush; map.objs[k] = 0; }
				redraw();
			}, 12);
			fill.x = px; fill.y = y;
			palette.addChild(fill);
			var border:Sprite = Ui.button("Wall the edges", 145, 26, function():void {
				for (var yy:int = 0; yy < map.h; yy++) for (var xx:int = 0; xx < map.w; xx++)
					if (xx == 0 || yy == 0 || xx == map.w - 1 || yy == map.h - 1) map.tiles[yy * map.w + xx] = World.WALL;
				redraw();
			}, 12);
			border.x = px + 150; border.y = y;
			palette.addChild(border);
			y += 34;
			sizeTf = Ui.text(13, 0xdddddd, true, "left", 120);
			sizeTf.x = px; sizeTf.y = y + 4;
			palette.addChild(sizeTf);
			var sz:Array = [["W-", -1, 0], ["W+", 1, 0], ["H-", 0, -1], ["H+", 0, 1]];
			for (i = 0; i < 4; i++) {
				var sb:Sprite = Ui.button(sz[i][0], 40, 24, sizeFn(sz[i][1], sz[i][2]), 12);
				sb.x = px + 120 + i * 44; sb.y = y;
				palette.addChild(sb);
			}
			sizeTf.text = "Size " + map.w + " x " + map.h;
		}

		private function swatch(label:String, col:uint, on:Boolean, fn:Function):Sprite {
			var b:Sprite = new Sprite();
			Ui.panel(b.graphics, 0, 0, 144, 22, on ? 0x3a4a5a : 0x262830, on ? 0xffd75e : 0x4a4a5a);
			b.graphics.beginFill(col);
			b.graphics.drawRect(4, 4, 14, 14);
			b.graphics.endFill();
			var t:TextField = Ui.text(12, 0xdddddd, false, "left", 120);
			t.text = label;
			t.x = 22; t.y = 2;
			b.addChild(t);
			b.buttonMode = true;
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { fn(); });
			return b;
		}

		private function objButton(o:int):Sprite {
			var b:Sprite = new Sprite();
			var on:Boolean = tool == "obj" && objBrush == o;
			Ui.panel(b.graphics, 0, 0, 38, 38, on ? 0x3a4a5a : 0x262830, on ? 0xffd75e : 0x4a4a5a);
			var bm:Bitmap = new Bitmap(Sprites.get(World.OBJ_NAMES[o]));
			var sc:Number = Math.min(1, 32 / Math.max(bm.width, bm.height));
			bm.scaleX = bm.scaleY = sc;
			bm.x = (38 - bm.width) / 2; bm.y = (38 - bm.height) / 2;
			b.addChild(bm);
			b.buttonMode = true;
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				tool = "obj"; objBrush = o; buildPalette();
				setInfo("Decoration: " + World.OBJ_NAMES[o] + ". Click on the map to place it.");
			});
			return b;
		}

		private function tileFn(id:int):Function {
			return function():void { tool = "tile"; brush = id; buildPalette(); };
		}

		private function toolFn(t:String):Function {
			return function():void {
				tool = t;
				buildPalette();
				setInfo(t == "spawn" ? "Click where the hero starts." : t == "boss" ? "Click where the boss stands." : "Click decorations to remove them.");
			};
		}

		private function sizeFn(dw:int, dh:int):Function {
			return function():void { resize(Math.max(15, Math.min(60, map.w + dw)), Math.max(15, Math.min(60, map.h + dh))); };
		}

		private function resize(w:int, h:int):void {
			var tiles:Array = [], objs:Array = [];
			for (var y:int = 0; y < h; y++) for (var x:int = 0; x < w; x++) {
				var inside:Boolean = x < map.w && y < map.h;
				tiles.push(inside ? map.tiles[y * map.w + x] : World.ARENA);
				objs.push(inside ? map.objs[y * map.w + x] : 0);
			}
			map.w = w; map.h = h; map.tiles = tiles; map.objs = objs;
			map.spawn = [Math.min(map.spawn[0], w - 2), Math.min(map.spawn[1], h - 2)];
			map.boss = [Math.min(map.boss[0], w - 2), Math.min(map.boss[1], h - 2)];
			buildPalette();
			layout();
		}

		// ------------------------------------------------------------ the map
		private function layout():void {
			cell = Math.max(6, Math.min(int(AREA_W / map.w), int(AREA_H / map.h), 24));
			gx = AREA_X + (AREA_W - cell * map.w) / 2;
			gy = AREA_Y + (AREA_H - cell * map.h) / 2;
			gridLayer.x = gx; gridLayer.y = gy;
			if (grid.bitmapData) grid.bitmapData.dispose();
			grid.bitmapData = new BitmapData(cell * map.w, cell * map.h, false, 0);
			redraw();
		}

		private function redraw():void {
			for (var y:int = 0; y < map.h; y++) for (var x:int = 0; x < map.w; x++) drawCell(x, y);
			drawMarks();
		}

		private var rect:Rectangle = new Rectangle();
		private var mtx:Matrix = new Matrix();

		private function drawCell(x:int, y:int):void {
			var bd:BitmapData = grid.bitmapData;
			var t:int = map.tiles[y * map.w + x];
			rect.x = x * cell; rect.y = y * cell; rect.width = cell; rect.height = cell;
			var col:uint = World.MINI_COL[t] || 0;
			bd.fillRect(rect, col);
			// a faint grid and a texture hint so floors read as tiles
			rect.width = cell; rect.height = 1;
			bd.fillRect(rect, Sprites.shade(col, 0.8));
			rect.width = 1; rect.height = cell;
			bd.fillRect(rect, Sprites.shade(col, 0.8));
			if (t == World.WALL) {
				rect.x = x * cell + 1; rect.y = y * cell + cell - 3; rect.width = cell - 1; rect.height = 3;
				bd.fillRect(rect, 0x606068);
			}
			var o:int = map.objs[y * map.w + x];
			if (o > 0) {
				var ob:BitmapData = Sprites.get(World.OBJ_NAMES[o]);
				var sc:Number = cell * 1.1 / Math.max(ob.width, ob.height);
				mtx.identity();
				mtx.scale(sc, sc);
				mtx.translate(x * cell + (cell - ob.width * sc) / 2, y * cell + cell - ob.height * sc);
				bd.draw(ob, mtx, null, null, null, false);
			}
		}

		private function drawMarks():void {
			var g:* = marks.graphics;
			g.clear();
			var pts:Array = [[map.spawn, 0x60ff60, "S"], [map.boss, 0xff5050, "B"]];
			for each (var p:Array in pts) {
				g.lineStyle(2, 0x000000);
				g.beginFill(p[1]);
				g.drawCircle(p[0][0] * cell + cell / 2, p[0][1] * cell + cell / 2, Math.max(4, cell * 0.45));
				g.endFill();
			}
		}

		private function paintAt(lx:Number, ly:Number):void {
			var x:int = int(lx / cell), y:int = int(ly / cell);
			if (x < 0 || y < 0 || x >= map.w || y >= map.h) return;
			var i:int = y * map.w + x;
			switch (tool) {
				case "tile": map.tiles[i] = brush; break;
				case "obj": map.objs[i] = objBrush; break;
				case "erase": map.objs[i] = 0; break;
				case "spawn": map.spawn = [x, y]; map.tiles[i] = floorAt(i); drawMarks(); break;
				case "boss": map.boss = [x, y]; map.tiles[i] = floorAt(i); drawMarks(); break;
			}
			drawCell(x, y);
		}

		/** Markers must stand on floor. */
		private function floorAt(i:int):int {
			var t:int = map.tiles[i];
			return t == World.WALL || t == World.VOID || t == World.LAVA ? World.ARENA : t;
		}

		private function saveMap():void {
			var n:String = nameTf.text.replace(/^\s+|\s+$/g, "");
			if (!n) { setInfo("Give the map a name first."); return; }
			map.objs[map.spawn[1] * map.w + map.spawn[0]] = 0;
			map.objs[map.boss[1] * map.w + map.boss[0]] = 0;
			CreatorData.store("maps", n, map);
			setInfo("Saved \"" + n + "\". Pick it as the arena in the Boss Maker.");
		}
	}
}
