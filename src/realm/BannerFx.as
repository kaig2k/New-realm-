package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;

	/**
	 * The big line across the middle of the screen (Game.showBanner): the words lit from above in
	 * their colour (pale at the top, deep at the foot), a dark rim and a glow of the colour round them,
	 * gold-tipped rules either side; it lands with a little punch, a gleam runs across it, and it
	 * lifts away as it fades.
	 */
	public class BannerFx extends Sprite {
		private var words:Bitmap = new Bitmap();
		private var gleam:Shape = new Shape();
		private var gleamMask:Bitmap = new Bitmap();
		private var ruleShape:Shape = new Shape();
		private var body:Sprite = new Sprite();
		private var t:Number = 0, life:Number = 0;
		private var w:Number;

		public function BannerFx(width:Number) {
			w = width;
			mouseEnabled = mouseChildren = false;
			body.addChild(ruleShape);
			body.addChild(words);
			body.addChild(gleamMask);
			body.addChild(gleam);
			gleam.blendMode = BlendMode.ADD;
			gleam.mask = gleamMask;
			gleamMask.cacheAsBitmap = gleam.cacheAsBitmap = true;
			addChild(body);
			visible = false;
		}

		/**
		 * Words lit from above in their colour (pale at the top, deep at the foot), with a dark rim of the
		 * colour, a glow and a shadow: the look of the banner and of window headings (Ui.heading). Also hands
		 * back the plain shape of the words (white) in shapeOut[0] when asked.
		 */
		public static function lit(text:String, size:int, col:uint, glow:Number = 1, shapeOut:Array = null):Bitmap {
			var tf:TextField = Ui.text(size, 0xffffff, true, "left", 0, false);
			tf.text = text;
			var tw:int = Math.ceil(tf.width) + 4, th:int = Math.ceil(tf.height) + 2;
			var shape:BitmapData = new BitmapData(tw, th, true, 0);
			shape.draw(tf, new Matrix(1, 0, 0, 1, 2, 1));
			var grad:Shape = new Shape();
			var m:Matrix = new Matrix();
			m.createGradientBox(tw, th, Math.PI / 2);
			grad.graphics.beginGradientFill(GradientType.LINEAR, [Sprites.tint(col, 0.72), Sprites.tint(col, 0.25), col, Sprites.shade(col, 0.62)], [1, 1, 1, 1], [0, 70, 140, 255], m);
			grad.graphics.drawRect(0, 0, tw, th);
			grad.graphics.endFill();
			var bd:BitmapData = new BitmapData(tw, th, true, 0);
			bd.draw(grad);
			bd.copyChannel(shape, shape.rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
			if (shapeOut) shapeOut[0] = shape; else shape.dispose();
			var b:Bitmap = new Bitmap(bd);
			b.smoothing = true;
			var rim:Number = Math.max(2, size / 8);
			b.filters = glow > 0 ? [new GlowFilter(Sprites.shade(col, 0.18), 1, rim, rim, 10), new GlowFilter(col, 0.5 * glow, size * 0.7, size * 0.45, 1.6),
				new DropShadowFilter(Math.max(2, size / 11), 90, 0x000000, 0.7, 4, 4, 1)] : [new GlowFilter(Sprites.shade(col, 0.18), 1, rim, rim, 10)];
			return b;
		}

		/** Gold-tipped rules either side of words tw wide (centred on 0), each len long. */
		public static function rules(g:*, tw:Number, len:Number, col:uint):void {
			for each (var s:int in [-1, 1]) {
				var x0:Number = s * (tw / 2 + 14);
				var rm:Matrix = new Matrix();
				rm.createGradientBox(len, 4, 0, s < 0 ? x0 - len : x0, -2);
				g.beginGradientFill(GradientType.LINEAR, [col, col], s < 0 ? [0, 0.9] : [0.9, 0], [0, 255], rm);
				g.drawRect(s < 0 ? x0 - len : x0, -1, len, 2);
				g.endFill();
				g.lineStyle(1, 0x2a1a06);
				g.beginFill(0xffe08a);
				g.moveTo(x0, -5); g.lineTo(x0 + 5, 0); g.lineTo(x0, 5); g.lineTo(x0 - 5, 0); g.lineTo(x0, -5);
				g.endFill();
				g.lineStyle();
			}
		}

		/** Show text in colour col for secs seconds. */
		public function show(text:String, col:uint, secs:Number):void {
			var so:Array = [];
			var b:Bitmap = lit(text, 32, col, 1, so);
			var shape:BitmapData = so[0];
			var tw:int = b.bitmapData.width, th:int = b.bitmapData.height;
			if (words.bitmapData) words.bitmapData.dispose();
			words.bitmapData = b.bitmapData;
			words.smoothing = true;
			words.filters = b.filters;
			if (gleamMask.bitmapData) gleamMask.bitmapData.dispose();
			gleamMask.bitmapData = shape;
			words.x = gleamMask.x = -tw / 2;
			words.y = gleamMask.y = -th / 2;
			// the gleam: a slanted bar of light that runs across the words once
			gleam.graphics.clear();
			var gm:Matrix = new Matrix();
			gm.createGradientBox(60, th, 0, -30, -th / 2);
			gleam.graphics.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xffffff, 0xffffff], [0, 0.85, 0], [0, 128, 255], gm);
			gleam.graphics.drawRect(-30, -th / 2, 60, th);
			gleam.graphics.endFill();
			// the rules either side: a line fading out from the words, a gold diamond at its inner end
			ruleShape.graphics.clear();
			var len:Number = Math.min(150, (w - tw) / 2 - 24);
			if (len > 20) rules(ruleShape.graphics, tw, len, col);
			ruleShape.filters = [new GlowFilter(col, 0.6, 8, 8, 1.5)];
			t = 0;
			life = secs;
			visible = true;
			tick(0);
		}

		/** Hide it at once. */
		public function hide():void { visible = false; life = 0; }

		public function get showing():Boolean { return visible; }

		public function tick(dt:Number):void {
			if (!visible) return;
			t += dt;
			if (t >= life) { visible = false; return; }
			// lands with a punch (big, then a hair under, then settles)
			var k:Number = Math.min(1, t / 0.24);
			var sc:Number = k < 1 ? 1.32 - 0.36 * k + Math.sin(k * Math.PI) * 0.04 : 1;
			body.scaleX = body.scaleY = sc;
			// in quickly; out over the last 0.6 seconds, lifting away
			var out:Number = Math.max(0, 1 - (life - t) / 0.6);
			alpha = Math.min(1, t / 0.12) * (1 - out);
			body.y = -out * 14;
			// the gleam runs across once, just after it lands
			var gk:Number = (t - 0.2) / 0.7;
			gleam.visible = gk > 0 && gk < 1;
			if (gleam.visible) gleam.x = -words.width / 2 - 40 + gk * (words.width + 80);
		}
	}
}
