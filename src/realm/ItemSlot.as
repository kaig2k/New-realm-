package realm {
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextField;

	/** An item box for windows (trade, inspect): icon, tier tag and a highlight ring. */
	public class ItemSlot extends Sprite {
		public static const SIZE:int = 48;
		public var item:Object;
		public var idx:int;
		private var icon:Bitmap = new Bitmap();
		private var tierTf:TextField;
		private var ring:Shape = new Shape();
		private var base:uint;

		public function ItemSlot(idx:int, base:uint = 0x545454) {
			this.idx = idx;
			this.base = base;
			drawBack(base);
			addChild(icon);
			tierTf = Ui.text(13, 0xffffff, true, "right", 32, true);
			tierTf.x = 15;
			tierTf.y = 28;
			addChild(tierTf);
			addChild(ring);
			mouseChildren = false;
		}

		private function drawBack(c:uint):void {
			graphics.clear();
			graphics.lineStyle(1, 0x1a1a1a);
			graphics.beginFill(c);
			graphics.drawRoundRect(0, 0, SIZE, SIZE, 10, 10);
			graphics.endFill();
		}

		public function setItem(it:Object):void {
			item = it;
			buttonMode = it != null;
			if (!it) {
				icon.bitmapData = null;
				tierTf.text = "";
				return;
			}
			icon.bitmapData = Sprites.icon(it);
			icon.x = int((SIZE - icon.width) / 2);
			icon.y = int((SIZE - icon.height) / 2);
			tierTf.text = Data.tierLabel(it);
			tierTf.textColor = Data.tierColor(it);
		}

		/** Highlight: 0 = none, otherwise a coloured ring (and a tinted fill when `fill`). */
		public function mark(color:uint, fill:Boolean = true, dashed:Boolean = false):void {
			drawBack(color && fill ? Sprites.shade(color, 0.45) : base);
			var g:* = ring.graphics;
			g.clear();
			if (!color) return;
			if (dashed) {
				g.lineStyle(2, color);
				for (var k:int = 0; k < 4; k++) {
					var s:int = 4 + k * 11;
					g.moveTo(s, 1); g.lineTo(s + 6, 1);
					g.moveTo(s, SIZE - 1); g.lineTo(s + 6, SIZE - 1);
					g.moveTo(1, s); g.lineTo(1, s + 6);
					g.moveTo(SIZE - 1, s); g.lineTo(SIZE - 1, s + 6);
				}
			} else {
				g.lineStyle(3, color);
				g.drawRoundRect(1, 1, SIZE - 2, SIZE - 2, 10, 10);
			}
		}
	}
}
