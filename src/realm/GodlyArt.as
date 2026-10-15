package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;

	/**
	 * The Godly weapons' own inventory icons: the art drawn for each one, cut from its sheet
	 * (tools/godlyart) and kept exactly as drawn, at the size of an icon (34x34).
	 */
	public class GodlyArt {
		[Embed(source="../../assets/godly/wizard.png")]
		private static const WIZARD:Class;
		[Embed(source="../../assets/godly/archer.png")]
		private static const ARCHER:Class;
		[Embed(source="../../assets/godly/knight.png")]
		private static const KNIGHT:Class;
		[Embed(source="../../assets/godly/priest.png")]
		private static const PRIEST:Class;
		[Embed(source="../../assets/godly/rogue.png")]
		private static const ROGUE:Class;
		[Embed(source="../../assets/godly/warrior.png")]
		private static const WARRIOR:Class;
		[Embed(source="../../assets/godly/necromancer.png")]
		private static const NECROMANCER:Class;
		[Embed(source="../../assets/godly/huntress.png")]
		private static const HUNTRESS:Class;
		[Embed(source="../../assets/godly/bard.png")]
		private static const BARD:Class;
		[Embed(source="../../assets/godly/alchemist.png")]
		private static const ALCHEMIST:Class;
		[Embed(source="../../assets/godly/chronomancer.png")]
		private static const CHRONOMANCER:Class;
		private static const ART:Object = {wizard: WIZARD, archer: ARCHER, knight: KNIGHT, priest: PRIEST, rogue: ROGUE, warrior: WARRIOR,
			necromancer: NECROMANCER, huntress: HUNTRESS, bard: BARD, alchemist: ALCHEMIST, chronomancer: CHRONOMANCER};

		/** A Godly weapon's drawing (34x34), or null for any other item. */
		public static function weapon(item:Object):BitmapData {
			if (!item || item.kind != "weapon" || item.rarity != "gd") return null;
			var c:Class = ART[Godly.classOf(item)];
			return c ? Bitmap(new c()).bitmapData : null;
		}
	}
}
