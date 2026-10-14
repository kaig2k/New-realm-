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
		/** Which vault chest this is (0-9), for vault bags. */
		public var chest:int = -1;

		public function LootBag(x:Number, y:Number, items:Array) {
			this.x = x;
			this.y = y;
			this.items = items;
			refresh();
		}

		public function refresh():void {
			spr = vault ? "chest" : Data.bagColor(items);
		}

		/** Loot filter levels (Settings): what a bag needs to hold to be shown. */
		public static const FILTERS:Array = ["Show everything", "Hide gear below T4", "Hide gear below T6", "Rare and better only"];

		/** Does this bag pass loot filter level f? Stat potions, keys, shards, runes and stones always do. */
		public function shown(f:int):Boolean {
			if (vault || f <= 0) return true;
			for each (var it:Object in items) {
				if (!it) continue;
				if (it.kind == "stat" || it.rarity || it.uid) return true;
				if (!Data.isGear(it) && it.kind != "hp" && it.kind != "mp") return true;
				if (f == 1 && Data.isGear(it) && int(it.tier) >= 4) return true;
				if (f == 2 && Data.isGear(it) && int(it.tier) >= 6) return true;
				if (f == 1 && (it.kind == "hp" || it.kind == "mp")) return true;
			}
			return false;
		}
	}
}
