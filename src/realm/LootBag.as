package realm {
	public class LootBag {
		public static const MAX:int = 8;
		public var x:Number, y:Number;
		public var items:Array;
		public var life:Number = 45;
		public var spr:String;

		public function LootBag(x:Number, y:Number, items:Array) {
			this.x = x;
			this.y = y;
			this.items = items;
			refresh();
		}

		public function refresh():void {
			spr = Data.bagColor(items);
		}
	}
}
