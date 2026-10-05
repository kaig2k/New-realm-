package realm {
	public class LootBag {
		public static const MAX:int = 8;
		public var x:Number, y:Number;
		public var items:Array;
		public var life:Number = 45;
		/** Seconds since the bag dropped (for the landing bounce). */
		public var age:Number = 0;
		public var spr:String;
		/** The nexus vault: never expires, persists between characters. */
		public var vault:Boolean = false;

		public function LootBag(x:Number, y:Number, items:Array) {
			this.x = x;
			this.y = y;
			this.items = items;
			refresh();
		}

		public function refresh():void {
			spr = vault ? "chest" : Data.bagColor(items);
		}
	}
}
