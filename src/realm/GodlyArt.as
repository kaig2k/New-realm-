package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;

	/**
	 * The Godly pieces' own inventory icons: the art drawn for each one, cut from its sheet
	 * (tools/godlyart) and kept exactly as drawn, at the size of an icon (34x34).
	 * So far the weapons and the rings; the rest keep their generated look until theirs is drawn.
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
		[Embed(source="../../assets/godly/ring_wizard.png")]
		private static const RING_WIZARD:Class;
		[Embed(source="../../assets/godly/ring_archer.png")]
		private static const RING_ARCHER:Class;
		[Embed(source="../../assets/godly/ring_knight.png")]
		private static const RING_KNIGHT:Class;
		[Embed(source="../../assets/godly/ring_priest.png")]
		private static const RING_PRIEST:Class;
		[Embed(source="../../assets/godly/ring_rogue.png")]
		private static const RING_ROGUE:Class;
		[Embed(source="../../assets/godly/ring_warrior.png")]
		private static const RING_WARRIOR:Class;
		[Embed(source="../../assets/godly/ring_necromancer.png")]
		private static const RING_NECROMANCER:Class;
		[Embed(source="../../assets/godly/ring_huntress.png")]
		private static const RING_HUNTRESS:Class;
		[Embed(source="../../assets/godly/ring_bard.png")]
		private static const RING_BARD:Class;
		[Embed(source="../../assets/godly/ring_alchemist.png")]
		private static const RING_ALCHEMIST:Class;
		[Embed(source="../../assets/godly/ring_chronomancer.png")]
		private static const RING_CHRONOMANCER:Class;
		private static const ART:Object = {
			weapon: {wizard: WIZARD, archer: ARCHER, knight: KNIGHT, priest: PRIEST, rogue: ROGUE, warrior: WARRIOR,
				necromancer: NECROMANCER, huntress: HUNTRESS, bard: BARD, alchemist: ALCHEMIST, chronomancer: CHRONOMANCER},
			ring: {wizard: RING_WIZARD, archer: RING_ARCHER, knight: RING_KNIGHT, priest: RING_PRIEST, rogue: RING_ROGUE, warrior: RING_WARRIOR,
				necromancer: RING_NECROMANCER, huntress: RING_HUNTRESS, bard: RING_BARD, alchemist: RING_ALCHEMIST, chronomancer: RING_CHRONOMANCER}
		};

		/** A Godly piece's drawing (34x34), or null for any other item (or a piece not drawn yet). */
		public static function icon(item:Object):BitmapData {
			if (!item || item.rarity != "gd" || !ART[item.kind]) return null;
			var c:Class = ART[item.kind][Godly.classOf(item)];
			return c ? Bitmap(new c()).bitmapData : null;
		}
	}
}
