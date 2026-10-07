package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * The server's name as a logo: gold lettering with a dark rim and a warm
	 * glow, and a band of light that sweeps across it now and then.
	 * Centred on x = 0; `y` is the top of the letters.
	 */
	public class Logo extends Sprite {
		private var face:Bitmap = new Bitmap();
		private var shine:Bitmap = new Bitmap();
		private var letters:BitmapData;
		private var band:BitmapData;
		private var bandShape:Shape = new Shape();
		private var size:int;
		private var t:Number = 0;
		private var text:String = "";

		public function Logo(name:String, size:int) {
			this.size = size;
			mouseEnabled = mouseChildren = false;
			addChild(face);
			addChild(shine);
			// a warm glow outside a dark rim
			face.filters = [
				new GlowFilter(0x2a1200, 1, 5, 5, 8, 2),
				new DropShadowFilter(5, 90, 0x000000, 0.7, 6, 6, 1.5, 2),
				new GlowFilter(0xffa020, 0.45, 34, 34, 1.4, 2)
			];
			// the moving shine: a soft slanted white band
			var g:* = bandShape.graphics;
			var m:Matrix = new Matrix();
			m.createGradientBox(120, 10, 0, -60, 0);
			g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xffffff, 0xffffff], [0, 0.85, 0], [0, 128, 255], m);
			g.drawRect(-60, -400, 120, 800);
			g.endFill();
			bandShape.rotation = 18;
			setText(name);
			addEventListener(Event.ENTER_FRAME, tick);
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void { removeEventListener(Event.ENTER_FRAME, tick); });
		}

		public function setText(name:String):void {
			name = name.toUpperCase();
			if (name == text) return;
			text = name;
			var tf:TextField = Ui.text(size, 0xffffff, true, "left");
			tf.text = name;
			var fmt:TextFormat = Ui.format(size, 0xffffff, true, "left");
			fmt.letterSpacing = Math.round(size * 0.06);
			tf.setTextFormat(fmt);
			var w:int = Math.ceil(tf.width) + 8, h:int = Math.ceil(tf.height) + 4;
			// the letters' shape
			if (letters) letters.dispose();
			letters = new BitmapData(w, h, true, 0);
			letters.draw(tf, new Matrix(1, 0, 0, 1, 4, 2));
			// gold, pale at the top and deep amber at the bottom, with a bright edge across the middle
			var grad:Shape = new Shape();
			var gm:Matrix = new Matrix();
			gm.createGradientBox(w, h * 0.78, Math.PI / 2, 0, h * 0.14);
			grad.graphics.beginGradientFill(GradientType.LINEAR, [0xfffbe0, 0xffe27a, 0xffc22e, 0xfff0a0, 0xd88a18, 0x9a5208],
				[1, 1, 1, 1, 1, 1], [0, 70, 120, 132, 190, 255], gm);
			grad.graphics.drawRect(0, 0, w, h);
			grad.graphics.endFill();
			var col:BitmapData = new BitmapData(w, h, true, 0);
			col.draw(grad);
			var fbd:BitmapData = new BitmapData(w, h, true, 0);
			fbd.copyPixels(col, col.rect, new Point(), letters, new Point(), false);
			col.dispose();
			if (face.bitmapData) face.bitmapData.dispose();
			face.bitmapData = fbd;
			face.smoothing = true;
			face.x = -w / 2;
			if (band) band.dispose();
			band = new BitmapData(w, h, true, 0);
			if (shine.bitmapData) shine.bitmapData.dispose();
			shine.bitmapData = new BitmapData(w, h, true, 0);
			shine.x = face.x;
		}

		/** Width of the lettering. */
		public function get logoWidth():Number { return face.width; }

		private function tick(e:Event):void {
			t += 1 / 60;
			// one sweep every five seconds
			var cyc:Number = t % 5;
			var sb:BitmapData = shine.bitmapData;
			if (cyc > 1.4) {
				if (shine.visible) { sb.fillRect(sb.rect, 0); shine.visible = false; }
				return;
			}
			shine.visible = true;
			bandShape.x = -150 + (sb.width + 300) * (cyc / 1.4);
			bandShape.y = sb.height / 2;
			band.fillRect(band.rect, 0);
			band.draw(bandShape, bandShape.transform.matrix);
			sb.fillRect(sb.rect, 0);
			sb.copyPixels(band, band.rect, new Point(), letters, new Point(), false);
		}
	}
}
