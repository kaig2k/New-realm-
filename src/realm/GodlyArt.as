package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;

	/**
	 * The Godly pieces' own inventory icons: the art drawn for each one, cut from its sheet
	 * (tools/godlyart) and kept exactly as drawn, at the size of an icon (34x34).
	 * Every piece of all 11 sets: weapon, ability, armour and ring.
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
		[Embed(source="../../assets/godly/armor_wizard.png")]
		private static const ARMOR_WIZARD:Class;
		[Embed(source="../../assets/godly/armor_archer.png")]
		private static const ARMOR_ARCHER:Class;
		[Embed(source="../../assets/godly/armor_knight.png")]
		private static const ARMOR_KNIGHT:Class;
		[Embed(source="../../assets/godly/armor_priest.png")]
		private static const ARMOR_PRIEST:Class;
		[Embed(source="../../assets/godly/armor_rogue.png")]
		private static const ARMOR_ROGUE:Class;
		[Embed(source="../../assets/godly/armor_warrior.png")]
		private static const ARMOR_WARRIOR:Class;
		[Embed(source="../../assets/godly/armor_necromancer.png")]
		private static const ARMOR_NECROMANCER:Class;
		[Embed(source="../../assets/godly/armor_huntress.png")]
		private static const ARMOR_HUNTRESS:Class;
		[Embed(source="../../assets/godly/armor_bard.png")]
		private static const ARMOR_BARD:Class;
		[Embed(source="../../assets/godly/armor_alchemist.png")]
		private static const ARMOR_ALCHEMIST:Class;
		[Embed(source="../../assets/godly/armor_chronomancer.png")]
		private static const ARMOR_CHRONOMANCER:Class;
		[Embed(source="../../assets/godly/ability_wizard.png")]
		private static const ABILITY_WIZARD:Class;
		[Embed(source="../../assets/godly/ability_archer.png")]
		private static const ABILITY_ARCHER:Class;
		[Embed(source="../../assets/godly/ability_knight.png")]
		private static const ABILITY_KNIGHT:Class;
		[Embed(source="../../assets/godly/ability_priest.png")]
		private static const ABILITY_PRIEST:Class;
		[Embed(source="../../assets/godly/ability_rogue.png")]
		private static const ABILITY_ROGUE:Class;
		[Embed(source="../../assets/godly/ability_warrior.png")]
		private static const ABILITY_WARRIOR:Class;
		[Embed(source="../../assets/godly/ability_necromancer.png")]
		private static const ABILITY_NECROMANCER:Class;
		[Embed(source="../../assets/godly/ability_huntress.png")]
		private static const ABILITY_HUNTRESS:Class;
		[Embed(source="../../assets/godly/ability_bard.png")]
		private static const ABILITY_BARD:Class;
		[Embed(source="../../assets/godly/ability_alchemist.png")]
		private static const ABILITY_ALCHEMIST:Class;
		[Embed(source="../../assets/godly/ability_chronomancer.png")]
		private static const ABILITY_CHRONOMANCER:Class;
		private static const ART:Object = {
			weapon: {wizard: WIZARD, archer: ARCHER, knight: KNIGHT, priest: PRIEST, rogue: ROGUE, warrior: WARRIOR,
				necromancer: NECROMANCER, huntress: HUNTRESS, bard: BARD, alchemist: ALCHEMIST, chronomancer: CHRONOMANCER},
			ring: {wizard: RING_WIZARD, archer: RING_ARCHER, knight: RING_KNIGHT, priest: RING_PRIEST, rogue: RING_ROGUE, warrior: RING_WARRIOR,
				necromancer: RING_NECROMANCER, huntress: RING_HUNTRESS, bard: RING_BARD, alchemist: RING_ALCHEMIST, chronomancer: RING_CHRONOMANCER},
			armor: {wizard: ARMOR_WIZARD, archer: ARMOR_ARCHER, knight: ARMOR_KNIGHT, priest: ARMOR_PRIEST, rogue: ARMOR_ROGUE, warrior: ARMOR_WARRIOR,
				necromancer: ARMOR_NECROMANCER, huntress: ARMOR_HUNTRESS, bard: ARMOR_BARD, alchemist: ARMOR_ALCHEMIST, chronomancer: ARMOR_CHRONOMANCER},
			ability: {wizard: ABILITY_WIZARD, archer: ABILITY_ARCHER, knight: ABILITY_KNIGHT, priest: ABILITY_PRIEST, rogue: ABILITY_ROGUE, warrior: ABILITY_WARRIOR,
				necromancer: ABILITY_NECROMANCER, huntress: ABILITY_HUNTRESS, bard: ABILITY_BARD, alchemist: ABILITY_ALCHEMIST, chronomancer: ABILITY_CHRONOMANCER}
		};

		/** A Godly piece's drawing (34x34), or null for any other item . */
		public static function icon(item:Object):BitmapData {
			if (!item || item.rarity != "gd" || !ART[item.kind]) return null;
			var c:Class = ART[item.kind][Godly.classOf(item)];
			return c ? Bitmap(new c()).bitmapData : null;
		}
	}
}
