package {
	import flash.display.*;
	import flash.events.Event;
	import flash.text.*;
	import realm.*;

	/**
	 * Every sprite in the game laid out on a sheet, drawn by the game's own code, to look over the art
	 * (tools/spritesheet/README). Flashvars: what = "monsters" (small sprites), "bosses" (big ones) or
	 * "items"; page = which page (0 up); zoom = how much bigger to draw them.
	 */
	[SWF(width="1600", height="1200", backgroundColor="#3a3a40")]
	public class SpriteSheet extends Sprite {
		private var step:int = 0, todo:Array, drawn:int = 0;

		public function SpriteSheet() {
			// (a frame at a time: Ruffle stops a script that runs too long)
			addEventListener(Event.ENTER_FRAME, tick);
		}

		private function tick(e:Event):void {
			if (step++ == 0) { Bosses.init(); return; }
			if (!todo) { build(); return; }
			for (var k:int = 0; k < 12 && todo.length; k++) todo.shift()();
			if (!todo.length) { removeEventListener(Event.ENTER_FRAME, tick); var done:TextField = new TextField(); done.text = "DONE"; done.textColor = 0x60ff60; done.x = 1500; addChild(done); }
		}

		private function build():void {
			todo = [];
			var p:Object = loaderInfo.parameters;
			var what:String = String(p.what || "monsters"), page:int = int(p.page || 0), zoom:Number = Number(p.zoom || 1);
			var list:Array = [];
			if (what == "items" && p.only) {
				for each (var oid:String in String(p.only).split(",")) { var oi:Object = Uniques.make(oid); if (oi) list.push([oi.name, Sprites.icon(oi)]); }
			} else if (what == "items") {
				var cls:Object = {};
				for each (var c:Object in Data.CLASSES) { cls[c.weapon] = 0; cls["a:" + c.abilityType] = 0; cls["r:" + c.armor] = 0; }
				for (var k:String in cls) for (var t:int = 0; t <= 7; t++) {
					var it:Object = k.indexOf("a:") == 0 ? (t <= 6 ? Data.makeAbility(k.substr(2), t) : null) : k.indexOf("r:") == 0 ? Data.makeArmor(k.substr(2), t) : Data.makeWeapon(k, t);
					if (it) list.push([it.name, Sprites.icon(it)]);
				}
				for each (var st:String in Data.STATS) for (var rt:int = 0; rt <= 5; rt += 5) { var rg:Object = Data.makeRing(st, rt); list.push([rg.name, Sprites.icon(rg)]); }
				for (var u:String in Uniques.ALL) { var ui:Object = Uniques.make(u); if (ui) list.push([ui.name, Sprites.icon(ui)]); }
				for (var g:String in Godly.SETS) for (var s:int = 0; s < 4; s++) { var gi:Object = Godly.make(g, s); list.push([gi.name, Sprites.icon(gi)]); }
				for each (var ps:String in ["hp", "mp"].concat(Data.STATS)) { var pt:Object = Data.makePotion(ps == "hp" || ps == "mp" ? ps : "stat", ps); list.push([pt.name, Sprites.icon(pt)]); }
			} else {
				// (which are big: from their drawings' size, without building them)
				var only:Array = p.only ? String(p.only).split(",") : null;
				if (only) { for each (var on:String in only) list.push([on, null]); }
				else for each (var n:String in Sprites.names()) {
					// (one picture per design: not its animation frames, recolours or older flat drawings)
					if (/_(idle|move|cast|strike|summon|guard|death|ridle|rmove|r|flat)$/.test(n) || /_r$/.test(n)) continue;
					var big:Boolean = Sprites.bigName(n);
					if ((what == "bosses") == big) list.push([n, null]);
				}
			}
			var cell:int = what == "bosses" ? 200 : what == "items" ? 100 : 90;
			var cols:int = int(1600 / cell), rows:int = int(1200 / cell), per:int = cols * rows;
			var tf:TextField = new TextField();
			tf.defaultTextFormat = new TextFormat("_sans", 12, 0xffffff, true);
			tf.text = what + " page " + page + " of " + Math.ceil(list.length / per) + " (" + list.length + ")";
			tf.width = 400; addChild(tf);
			for (var i:int = 0; i < per && page * per + i < list.length; i++) todo.push(cellFn(list[page * per + i], i, cols, cell, zoom));
		}

		private function cellFn(e:Array, i:int, cols:int, cell:int, zoom:Number):Function {
			return function():void {
				var bd:BitmapData = e[1] || Sprites.get(e[0], 0);
				var b:Bitmap = new Bitmap(bd);
				var sc:Number = Math.min(zoom, (cell - 22) / Math.max(1, b.width), (cell - 22) / Math.max(1, b.height));
				b.scaleX = b.scaleY = sc;
				b.x = (i % cols) * cell + (cell - b.width) / 2;
				b.y = 16 + int(i / cols) * cell + (cell - 18 - b.height) / 2;
				addChild(b);
				var l:TextField = new TextField();
				l.defaultTextFormat = new TextFormat("_sans", 9, 0xd8d8d8);
				l.text = e[0]; l.width = cell; l.x = (i % cols) * cell; l.y = 16 + int(i / cols) * cell + cell - 18;
				addChild(l);
			};
		}
	}
}
