package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.utils.getTimer;

	/**
	 * The Fate Crate's opening, CS2 style: a strip of prizes scrolls past a marker, slows down with a
	 * tick for every prize that passes, and stops on what the server rolled (it decides first; this
	 * only shows it). Ten at once: one quick scroll onto the best of them, then all ten in a row. A
	 * gold prize always gets the full slow scroll.
	 */
	public class CrateReel extends Sprite {
		public static const CELL:int = 64, GAP:int = 6;
		private static const SLOW:Number = 5.2, FAST:Number = 1.4;

		private var prizes:Array;
		private var w:int;
		private var strip:Sprite = new Sprite();
		private var flash:Shape = new Shape();
		private var target:Number, t0:int, dur:Number, lastCell:int = -1;
		private var onDone:Function;
		public var done:Boolean = false;

		/** prizes: what the server sent ({id, tier, name, item?, cos?}), in the order opened. */
		public function CrateReel(prizes:Array, w:int, onDone:Function) {
			this.prizes = prizes;
			this.w = w;
			this.onDone = onDone;
			// the reel's window: a dark frame with the marker in the middle
			graphics.beginFill(0x101014);
			graphics.drawRoundRect(0, 0, w, CELL + 24, 10, 10);
			graphics.endFill();
			var maskShape:Shape = new Shape();
			maskShape.graphics.beginFill(0);
			maskShape.graphics.drawRect(4, 4, w - 8, CELL + 16);
			maskShape.graphics.endFill();
			addChild(maskShape);
			strip.mask = maskShape;
			addChild(strip);
			// the prize it lands on is the best one (for ten, the rest show after)
			var best:int = 0;
			for (var i:int = 1; i < prizes.length; i++) if (prizes[i].tier > prizes[best].tier) best = i;
			var win:Object = prizes[best];
			var n:int = 44, at:int = 36;
			for (i = 0; i < n; i++) {
				var p:Object = i == at ? win : filler();
				var c:Sprite = cell(p);
				c.x = i * (CELL + GAP);
				c.y = 12;
				strip.addChild(c);
			}
			// (where in its cell it stops: not always dead centre, like the real thing)
			target = at * (CELL + GAP) + CELL / 2 - w / 2 + (Math.random() - 0.5) * (CELL * 0.6);
			strip.x = 0;
			var marker:Shape = new Shape();
			marker.graphics.beginFill(0xffd23a);
			marker.graphics.moveTo(w / 2 - 7, 0); marker.graphics.lineTo(w / 2 + 7, 0); marker.graphics.lineTo(w / 2, 10);
			marker.graphics.moveTo(w / 2 - 7, CELL + 24); marker.graphics.lineTo(w / 2 + 7, CELL + 24); marker.graphics.lineTo(w / 2, CELL + 14);
			marker.graphics.endFill();
			marker.graphics.lineStyle(2, 0xffd23a, 0.8);
			marker.graphics.moveTo(w / 2, 10); marker.graphics.lineTo(w / 2, CELL + 14);
			addChild(marker);
			addChild(flash);
			dur = win.tier >= 4 || prizes.length == 1 ? (win.tier >= 4 ? SLOW + 1 : SLOW) : FAST;
			t0 = getTimer();
			addEventListener(Event.ENTER_FRAME, tick);
		}

		/** A prize for the strip that wasn't rolled: picked with the table's own odds, so the strip looks honest. */
		private static function filler():Object {
			var p:Object = Data.crateRoll(false);
			return {id: p.id, tier: p.tier, name: p.name};
		}

		/** The icon a prize shows. */
		public static function iconOf(p:Object):BitmapData {
			if (p.item) return Sprites.icon(p.item);
			switch (p.id) {
				case "stat": return Sprites.icon(Data.makePotion("stat", Data.STATS[int(Math.random() * Data.STATS.length)]));
				case "gold": return Sprites.icon(Data.makePouch("gold", 2500));
				case "aether": return Sprites.icon(Data.makePouch("aether", Data.CRATE_AETHER));
				case "reroll": return Sprites.icon(Data.makeCharm("reroll"));
				case "sovereign": return Sprites.icon(Data.makeCharm("sovereign"));
				case "ring": return Sprites.icon(Uniques.make(Uniques.LUCK_RING));
				case "pet":
					var ps:Object = p.cos ? Data.findPetSkin(p.cos) : null;
					var skins:Array = ["pet_skin_rabbit", "pet_skin_cat", "pet_skin_shoe"];
					return Sprites.get(ps && ps.spr ? ps.spr : skins[int(Math.random() * skins.length)]);
			}
			return null;
		}

		public static function cell(p:Object):Sprite {
			var c:Sprite = new Sprite();
			var col:uint = Data.CRATE_TIERS[p.tier].col;
			c.graphics.beginFill(0x24242a);
			c.graphics.lineStyle(2, col);
			c.graphics.drawRoundRect(0, 0, CELL, CELL, 8, 8);
			c.graphics.endFill();
			// a band of its colour along the bottom, like a CS2 case
			c.graphics.lineStyle();
			c.graphics.beginFill(col, 0.85);
			c.graphics.drawRect(2, CELL - 7, CELL - 4, 5);
			c.graphics.endFill();
			var bd:BitmapData = iconOf(p);
			if (bd) {
				var bmp:Bitmap = new Bitmap(bd);
				var s:Number = Math.min(1, 46 / Math.max(bmp.width, bmp.height));
				bmp.scaleX = bmp.scaleY = s;
				bmp.x = (CELL - bmp.width) / 2; bmp.y = (CELL - 7 - bmp.height) / 2;
				c.addChild(bmp);
			} else {
				// a title: its word on a scroll
				var tf:TextField = Ui.text(13, col, true, "center", CELL, true);
				tf.text = "Title";
				tf.y = 20;
				c.addChild(tf);
			}
			return c;
		}

		private function tick(e:Event):void {
			var t:Number = (getTimer() - t0) / 1000 / dur;
			if (t >= 1) t = 1;
			// fast at first, a long slow crawl at the end
			var ease:Number = 1 - Math.pow(1 - t, 4);
			strip.x = -target * ease;
			var under:int = int((-strip.x + w / 2) / (CELL + GAP));
			if (under != lastCell) { lastCell = under; if (t < 1) Sfx.play("click", 0.45, 0.02); }
			if (t >= 1) finish();
		}

		private function finish():void {
			removeEventListener(Event.ENTER_FRAME, tick);
			done = true;
			var best:int = 0;
			for (var i:int = 1; i < prizes.length; i++) if (prizes[i].tier > prizes[best].tier) best = i;
			var col:uint = Data.CRATE_TIERS[prizes[best].tier].col;
			flash.graphics.lineStyle(3, col);
			flash.graphics.drawRoundRect(w / 2 - CELL / 2 - 4, 8, CELL + 8, CELL + 8, 10, 10);
			Sfx.play(prizes[best].tier >= 3 ? "fanfare" : prizes[best].tier >= 2 ? "rare" : "loot");
			if (onDone != null) onDone();
		}

		/** Stops it where it is (the panel closed). */
		public function stop():void {
			if (!done) { removeEventListener(Event.ENTER_FRAME, tick); strip.x = -target; done = true; if (onDone != null) onDone(); }
		}
	}
}
