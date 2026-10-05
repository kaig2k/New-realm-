package realm {
	import flash.text.TextField;

	/** Floating combat text (damage numbers, level up, etc.). */
	public class Floater {
		public var tf:TextField;
		public var x:Number, y:Number, life:Number;

		public function Floater() {
			tf = Ui.text(14, 0xffffff, true, "left", 0, true);
		}

		public function set(x:Number, y:Number, text:String, color:uint):void {
			this.x = x;
			this.y = y;
			life = 0.9;
			tf.textColor = color;
			tf.text = text;
			tf.visible = true;
			tf.alpha = 1;
		}
	}
}
