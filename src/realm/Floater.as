package realm {
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.TextField;

	/** Floating combat text (damage numbers, level up, etc.). */
	public class Floater {
		public var tf:TextField;
		public var x:Number, y:Number, life:Number;
		/** Sideways drift (so stacked numbers spread out) and size (crits are bigger). */
		public var vx:Number = 0, size:Number = 1;

		/** Filters per colour (and crit), made once. */
		private static const LOOKS:Object = {};

		public function Floater() {
			tf = Ui.text(17, 0xffffff, true, "left", 0, true);
		}

		public function set(x:Number, y:Number, text:String, color:uint):void {
			this.x = x;
			this.y = y;
			life = 0.9;
			vx = (Math.random() - 0.5) * 0.9;
			size = text.charAt(text.length - 1) == "!" ? 1.35 : 1;
			tf.textColor = color;
			tf.text = text;
			// rimmed in a deep shade of its own colour (crits and the like glow too), not flat black
			var key:String = color + (size > 1 ? "!" : "");
			var fl:Array = LOOKS[key];
			if (!fl) {
				fl = [new GlowFilter(Sprites.shade(color, 0.2), 1, 3, 3, 7)];
				if (size > 1) fl.push(new GlowFilter(color, 0.55, 10, 10, 1.6));
				fl.push(new DropShadowFilter(1.5, 90, 0x000000, 0.6, 2, 2, 1));
				LOOKS[key] = fl;
			}
			tf.filters = fl;
			tf.visible = true;
			tf.alpha = 1;
		}
	}
}
