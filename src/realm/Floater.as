package realm {
	import flash.text.TextField;

	/** Floating combat text (damage numbers, level up, etc.). */
	public class Floater {
		public var tf:TextField;
		public var x:Number, y:Number, life:Number;
		/** Sideways drift (so stacked numbers spread out) and size (crits are bigger). */
		public var vx:Number = 0, size:Number = 1;

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
			tf.visible = true;
			tf.alpha = 1;
		}
	}
}
