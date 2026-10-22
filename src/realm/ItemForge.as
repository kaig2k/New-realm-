package realm {
	/**
	 * Every item's 8x8 drawing from the item template (the shape sheet): each kind of item is one of a
	 * few silhouette families. A family is
	 *  - a core ("#"): the cells every drawing of it fills;
	 *  - a ring ("+") one cell round the core it may grow into, and for the diagonal weapons a second
	 *    ring ("-") beyond that, never further;
	 *  - a skeleton (cells marked "@", "*" or "%": core, ring and second ring), the line down its middle;
	 *  - a tail and a tip: for the diagonal ("/") families the bottom-left and top-right corners.
	 * What fills the ring is read from the item's name: its material (Rusty, Mithril, Bone...), its
	 * element (Flame, Frost, Void, Star, Venom...) with a motif of its own (flames licking up from the
	 * tip, frost crystals, a star's glint, a drip of blood or venom...), and its shape words (Broad,
	 * Saber, Long, Twin, Short...). Same name, same drawing; different names, different drawings.
	 *
	 * Palette keys (three shades a part, light to dark): metal/cloth H B b, grip Y W w, trim J G g,
	 * gem X R r, motif M m, string S, holes O, glint Z.
	 */
	public class ItemForge {
		// ------------------------------------------------------------ the families
		// weapons and armour, from the template sheet
		/** SHAPE_005: a 2-3px stepped band on the "/" axis; its cross-bar grows into the ring. */
		public static const SWORD:Array = ["----+###", "--.++@##", "--++#@##", "-++#@#++", "++#@#++-", "+#@#++--", "#@#++---", "##++----"];
		/** SHAPE_006: a stepped band with its cross-bar near the top: the hilt up, the blade down. */
		public static const DAGGER:Array = ["--++++##", "--+@+#@#", "--++@@#+", "-++#@@++", "++#@#+@+", "+#@#++++", "#@#++---", "##++----"];
		/** SHAPE_003: a thin 1px line with a small head. */
		public static const WAND:Array = ["----++##", "---++#@#", "---+#@#+", "--++@#++", "-++@+++-", "++@++---", "+@++----", "@++-----"];
		/** SHAPE_004: a hollow two-strand arc: the bow and its string. */
		public static const BOW:Array = ["----++@@", "---++@+@", "--++@++@", "-++@++@+", "++@+++@+", "+@+++@++", "@++@@++-", "@@@+++--"];
		/** SHAPE_007: a hollow two-strand loop: the great bows. */
		public static const GREATBOW:Array = ["-+@@@@+@", "-+@+++@+", "-+@++@+@", "-+@+@++@", "++@@+++@", "+#@@@@@@", "#@#+++++", "##++----"];
		/** SHAPE_008: a stepped band with a heavy head. */
		public static const STAFF:Array = ["--+@+##+", "--++@@##", "-++##@#+", "++##@##+", "@+#@##++", "+@@@#++-", "+@##++--", "@++#+.--"];
		/** SHAPE_001: the armour block, mirrored left and right (breastplates and hides). */
		public static const HEAVY:Array = ["+##++##+", "########", "#@@@####", "###@####", "++#@##++", "-+####+-", "-+####+-", "-++##++-"];
		/** SHAPE_002: the full-width armour slab (robes). */
		public static const ROBE:Array = ["+######+", "########", "@@@##@@@", "@+@@@@+@", "+@@##@@+", "+######+", "########", "########"];
		// the rest of the gear, drawn to the same rules
		public static const SPELL:Array = ["..+##+..", ".+####+.", "+##@@##+", "+#@##@#+", "+#@##@#+", "+##@@##+", ".+####+.", "..+##+.."];
		public static const QUIVER:Array = ["----+##+", "---+###+", "--+##@#+", "-+##@#+-", "+##@#+--", "+#@#+---", "##@+----", "##+-----"];
		public static const SHIELD:Array = ["+######+", "###@@###", "###@@###", "#@@@@@@#", "+##@@##+", ".+#@@#+.", "..+##+..", "...++..."];
		public static const TOME:Array = ["+######.", "+#@@@@#+", "+#@##@#+", "+#@##@#+", "+#@##@#+", "+#@@@@#+", "+######+", "+######."];
		public static const CLOAK:Array = ["..+##+..", ".+####+.", "+##@@##+", "###@@###", "##@##@##", "+#@##@#+", "##@##@##", "########"];
		public static const HELM:Array = ["..+##+..", ".+####+.", "+######+", "###@@###", "########", "########", "+######+", ".+#++#+."];
		public static const SKULL:Array = [".+####+.", "+######+", "########", "########", "########", "+######+", ".+####+.", ".+#++#+."];
		public static const TRAP:Array = ["+..++..+", ".+####+.", ".##@@##.", "+#@##@#+", "+#@##@#+", ".##@@##.", ".+####+.", "+..++..+"];
		public static const LYRE:Array = ["+#+..+#+", "+#+..+#+", "+#++++#+", "+#@@@@#+", ".+####+.", "..+##+..", "..+##+..", ".+####+."];
		public static const FLASK:Array = ["...++...", "..+##+..", "..+##+..", ".+####+.", "+######+", "###@@###", "###@@###", "+######+"];
		public static const HOURGLASS:Array = ["+######+", ".+####+.", "..+##+..", "...@@...", "...@@...", "..+##+..", ".+####+.", "+######+"];
		public static const RING:Array = ["..+##+..", ".+####+.", ".##++##.", "##+..+##", "##+..+##", ".##++##.", ".+####+.", "..+..+.."];
		public static const POTION:Array = ["...++...", "..+##+..", "...##...", "..+##+..", ".+####+.", "+######+", "+######+", ".+####+."];

		// ---- things named for what they are: drawn by part (m metal, t trim, e gem, g grip, f shaft, s string,
		// x motif colour, z glint, o hole, d dark metal); the ring is one cell round the drawing
		public static const BARREL:Array = ["....xz..", ".tttttt.", ".mmmmmm.", "tttttttt", ".mmmmmm.", "tttttttt", ".mmmmmm.", ".tttttt."];
		public static const LANTERN:Array = ["...tt...", "..t..t..", ".tttttt.", ".tzeezt.", ".tzeezt.", ".teeeet.", ".tttttt.", "..tttt.."];
		public static const CROWN:Array = ["........", "z..zz..z", "t..tt..t", "tt.tt.tt", "tttttttt", "teteetet", "tttttttt", "........"];
		public static const HALO:Array = ["........", "..tzzt..", ".t....t.", "z......z", ".t....t.", "..tzzt..", "........", "........"];
		public static const TRIDENT:Array = [".....m.m", "....t.m.", ".....t.m", "....f.t.", "...f....", "..f.....", ".f......", "g......."];
		public static const MAUL:Array = ["...mm...", "....mm..", ".....mm.", "....f.mm", "...f...m", "..f.....", ".f......", "g......."];
		public static const BANNER:Array = ["t.......", "fmmmmmm.", "fmmeemm.", "fmmeemm.", "fmmmmm..", "fmmmm...", "f.......", "f......."];
		public static const SHELL:Array = ["..tmmm..", ".tmddmm.", "tmdmmdmm", "tmdmdmdm", "tmdddmdm", ".tmmmmdm", "..ttmmm.", "....tt.."];
		public static const CHARM:Array = [".s....s.", "..s..s..", "...ss...", "..tttt..", ".tteett.", ".teeeet.", "..tttt..", "...tt..."];
		public static const CHALICE:Array = [".tttttt.", ".teeeet.", ".tmeemt.", "..tmmt..", "...tt...", "...tt...", "..tttt..", ".tttttt."];
		public static const CAULDRON:Array = ["..xzx...", ".x.x.x..", "tttttttt", ".mmeemm.", ".meeeem.", ".mmmmmm.", "..mmmm..", ".t....t."];
		public static const CORE:Array = ["...tt...", "..tmmt..", ".tmzmmt.", "tmmeemmt", "tmmeemmt", ".tmmmmt.", "..tmmt..", "...tt..."];
		public static const EYE:Array = ["........", "..tttt..", ".tzzzzt.", "tzeooezt", "tzeooezt", ".tzzzzt.", "..tttt..", "........"];
		public static const HEART:Array = [".ee..ee.", "eeeeeeee", "eezeeeee", "eeeeeeee", ".eeeeee.", "..eeee..", "...ee...", "........"];
		public static const CORAL:Array = [".x.x..x.", ".x.xx.x.", "..xx.xx.", "...x.x..", "...xx...", "...x....", "..ttt...", ".ttttt.."];
		public static const STONE:Array = ["...mm...", "..mmzm..", ".mmeemm.", "mmeeeemm", "mmeeeemm", ".mmeemm.", "..mmmm..", "...mm..."];
		public static const PHYLACTERY:Array = ["...tt...", "..tzzt..", ".teeeet.", ".teeeet.", ".teeeet.", "..tttt..", "...tt...", "..tttt.."];
		// gear the template has no family for, drawn whole the same way
		public static const ROBE_D:Array = [".mmoomm.", "mmmttmmm", "mmmmmmmm", "tmmmmmmt", ".tteett.", ".mmddmm.", "mmmddmmm", "mmmddmmm"];
		public static const CLOAK_D:Array = ["...mm...", "..mmmm..", ".mmoomm.", ".mmoomm.", "mmmtemmm", "mmmmmmmm", "mmdmmdmm", "mdmmmmdm"];
		public static const HOURGLASS_D:Array = ["tttttttt", ".feeeef.", ".fxxxxf.", ".f.xx.f.", ".f.ex.f.", ".f.ee.f.", ".fxxxxf.", "tttttttt"];
		public static const QUIVER_D:Array = ["..z.z.z.", "..x.x.x.", ".tttttt.", ".gggggg.", ".ggeegg.", ".gggggg.", ".tttttt.", "..gggg.."];
		private static const DRAWN:Object = {robe: ROBE_D, cloak: CLOAK_D, hourglass: HOURGLASS_D, quiver: QUIVER_D};
		/** [the words, the drawing, "w" for weapons only, "n" for anything but weapons]. */
		private static const NOUNS:Array = [
			[["keg", "barrel", "powder"], BARREL, "n"], [["lantern"], LANTERN, "n"], [["crown"], CROWN, "n"], [["halo"], HALO, "n"],
			[["trident"], TRIDENT, "w"], [["maul", "hammer", "siegebreaker", "titanbreaker", "stormbreaker"], MAUL, "w"], [["banner", "standard"], BANNER, "n"],
			[["shell"], SHELL, "n"], [["charm", "amulet", "pendant"], CHARM, "n"], [["chalice", "goblet"], CHALICE, "n"], [["brew", "cauldron"], CAULDRON, "n"],
			[["core", "cube"], CORE, "n"], [["eye"], EYE, "n"], [["heart"], HEART, "n"], [["coral"], CORAL, "n"], [["stone"], STONE, "n"],
			[["phylactery", "reliquary"], PHYLACTERY, "n"]
		];

		private static const WEAPONS:Object = {sword: SWORD, dagger: DAGGER, wand: WAND, bow: BOW, staff: WAND};
		private static const ABILITIES:Object = {spell: SPELL, quiver: QUIVER, shield: SHIELD, tome: TOME, cloak: CLOAK, helm: HELM, skull: SKULL,
			trap: TRAP, lyre: LYRE, flask: FLASK, hourglass: HOURGLASS};
		private static const ARMOURS:Object = {heavy: HEAVY, leather: HEAVY, robe: ROBE};

		// ------------------------------------------------------------ what names mean
		/**
		 * Elements: the words that call them up, then [light, base, dark] for the item's main part, its
		 * gem, its motif's colours and the motif. The first element named wins.
		 */
		private static const ELEMENTS:Array = [
			{w: ["flame", "fire", "ember", "blaze", "pyre", "inferno", "burn", "ash", "phoenix", "magma", "molten", "cinder", "scorch", "hell", "forge", "primal flame", "pyro", "ignis", "lava"],
				m: [0xffe0a0, 0xff8a30, 0xb03a10], gem: 0xffd040, fx: [0xffe060, 0xff5010], motif: "flame"},
			{w: ["frost", "ice", "glaci", "snow", "winter", "rime", "cold", "freez", "hail", "sylith", "glacius", "glacia"],
				m: [0xf0ffff, 0x9ae0ff, 0x4a90c0], gem: 0xe0ffff, fx: [0xffffff, 0x80d8ff], motif: "crystal"},
			{w: ["void", "abyss", "umbra", "rift", "eclipse", "unmade", "nether", "eldritch", "chaos", "vael"],
				m: [0x9a7ad0, 0x4a2a7a, 0x1e1030], gem: 0xd060ff, fx: [0xe0a0ff, 0x8030c0], motif: "wisp"},
			{w: ["star", "astral", "cosmo", "nebula", "comet", "celestial", "nova", "galax", "meteor", "zenith", "astraeon", "heaven"],
				m: [0xe8eaff, 0x6a7ad8, 0x2a2a6a], gem: 0x7aa8ff, fx: [0xffffff, 0xfff0a0], motif: "star"},
			{w: ["blood", "crimson", "vampir", "sanguine", "gore", "carnage", "scarlet", "kael", "slaughter"],
				m: [0xff9090, 0xc02030, 0x5a0a14], gem: 0xff3040, fx: [0xff4050, 0x900818], motif: "drip"},
			{w: ["venom", "viper", "serpent", "snake", "poison", "toxic", "hydra", "naga", "ssythra", "asp", "cobra", "plague", "blight"],
				m: [0xd0ffa0, 0x60c040, 0x245a1a], gem: 0xd0ff40, fx: [0xc0ff60, 0x50a020], motif: "fang"},
			{w: ["storm", "thunder", "lightning", "tempest", "gale", "spark", "volt", "shock", "wind", "sky", "zephyr"],
				m: [0xd0f0ff, 0x5aa0d0, 0x2a4a7a], gem: 0xffff60, fx: [0xffffa0, 0xf0d020], motif: "bolt"},
			{w: ["tide", "sea", "deep", "coral", "leviathan", "kraken", "salt", "wave", "ocean", "pearl", "drown", "brine", "reef", "nerezza"],
				m: [0xa0fff0, 0x30b0b0, 0x0a5a6a], gem: 0xe8f8ff, fx: [0xa0f0ff, 0x30a0c0], motif: "wave"},
			{w: ["bone", "skull", "lich", "grave", "crypt", "ossu", "marrow", "skelet", "death", "tomb", "necro", "corpse"],
				m: [0xfffbe8, 0xe0d8c0, 0x9a9078], gem: 0x60ff90, fx: [0x80ffb0, 0x30a060], motif: "skull"},
			{w: ["shadow", "night", "ghost", "spectr", "phantom", "hollow", "dusk", "dark", "shade", "wraith", "soul", "spirit", "haunt"],
				m: [0x9090a8, 0x4a4a60, 0x1a1a28], gem: 0x80ffd0, fx: [0xb0ffe8, 0x40a080], motif: "wisp"},
			{w: ["thorn", "wood", "twig", "forest", "fey", "oak", "root", "leaf", "vine", "bramble", "moss", "grove", "druid", "wild", "hunt", "hawk", "fletch"],
				m: [0xd8b070, 0x8a5a2a, 0x4a2a14], gem: 0x80e040, fx: [0x90e050, 0x3a8a20], motif: "leaf"},
			{w: ["dragon", "drake", "wyvern", "wyrm"],
				m: [0xffa080, 0xc04030, 0x5a1a14], gem: 0xffd040, fx: [0xffc060, 0x8a2010], motif: "scale"},
			{w: ["moon", "lunar", "silver", "pale", "mirror"],
				m: [0xffffff, 0xc8d0e8, 0x6a7090], gem: 0x80c0ff, fx: [0xe0f0ff, 0x8090c0], motif: "crescent"},
			{w: ["crystal", "agate", "prism", "gem", "diamond", "glass", "shard", "jewel", "seraph"],
				m: [0xffffff, 0xb0e8ff, 0x5a90c0], gem: 0xff70d0, fx: [0xffffff, 0xa0e0ff], motif: "facet"},
			{w: ["sun", "solar", "radian", "holy", "divine", "gold", "gilded", "light", "dawn", "penance", "saint", "sacred", "angel", "halo", "aureate", "king", "royal", "crown"],
				m: [0xffffe0, 0xf0c030, 0x9a7010], gem: 0xffffff, fx: [0xffffff, 0xffe070], motif: "rays"},
			{w: ["rune", "arcane", "mystic", "ether", "magic", "spell", "archmage", "sorcer", "hex", "witch", "curse", "time", "chrono", "clock"],
				m: [0xe0c8ff, 0x8a5ad8, 0x3a2070], gem: 0x60f0ff, fx: [0x90f8ff, 0x3090c0], motif: "rune"}
		];
		/** Materials (no element named): the words, then [light, base, dark]. */
		private static const MATERIALS:Array = [
			{w: ["rusty", "rust", "old", "broken", "cracked", "worn"], m: [0xc0b0a0, 0x8a7868, 0x4a3c30]},
			{w: ["iron", "chain", "ring mail", "buckler", "studded"], m: [0xc8c8d0, 0x8a8a94, 0x4a4a54]},
			{w: ["steel", "plate", "scale armor", "kite", "tower", "broad", "long", "saber", "falchion"], m: [0xe8f0ff, 0xa8b8cc, 0x5a6a80]},
			{w: ["mithril", "elven"], m: [0xe0ffff, 0x90d0e0, 0x4a8090]},
			{w: ["titan", "obsidian", "onyx", "black"], m: [0x8a8aa0, 0x3a3a4a, 0x14141c]},
			{w: ["copper", "bronze", "brass"], m: [0xffd0a0, 0xc0783a, 0x6a3a18]},
			{w: ["leather", "hide", "vest", "ranger"], m: [0xd8a070, 0x8a5a2a, 0x4a2a12]},
			{w: ["silk"], m: [0xd0c0f0, 0x6a5aa0, 0x2a2050]}
		];
		/** Shape words: what they do to the drawing. */
		private static const SHAPES:Array = [
			{w: ["broad", "great", "titan", "heavy", "claymore", "cleaver", "maul", "colossus"], s: "broad"},
			{w: ["saber", "sabre", "falchion", "scimitar", "cutlass", "curved", "crescent", "fang", "kris"], s: "curve"},
			{w: ["long", "spear", "lance", "distant", "pike"], s: "long"},
			{w: ["short", "twig", "dirk", "little", "minor", "small"], s: "short"},
			{w: ["twin", "dual", "double", "pair", "two"], s: "twin"},
			{w: ["crystal", "agate", "shard", "prism", "glass"], s: "facet"}
		];
		/** Plain gear with no element: its tier's metal (rusty, iron, steel, silver, viper, flame, crystal, sunforged). */
		private static const TIER_METAL:Array = [[0xc0b0a0, 0x8a7868, 0x4a3c30], [0xd8d8e0, 0x9a9aa2, 0x5a5a62], [0xeef4ff, 0xa8b8cc, 0x627088],
			[0xffffff, 0xd0d0dc, 0x8a8aa0], [0xe0ffd0, 0x9ad08a, 0x4a8a3a], [0xfff0e0, 0xe08050, 0xa04030], [0xffffff, 0xb0e8ff, 0x5a90c0], [0xffffe8, 0xffe080, 0xc0a050]];
		private static const TIER_GEM:Array = [0x9a6a4a, 0xc04040, 0x40a0ff, 0x60e0ff, 0xe0e040, 0xff7020, 0xc070ff, 0xff4040];
		/** Trims: gold, silver, bronze, obsidian, bone, jade. */
		private static const TRIMS:Array = [[0xffe890, 0xe0b030, 0x8a6a10], [0xffffff, 0xc8c8d8, 0x7a7a90], [0xffc890, 0xb07038, 0x5a3010],
			[0x7a7a8a, 0x3a3a48, 0x16161e], [0xfffbe8, 0xe0d8c0, 0x9a9078], [0xa0ffc0, 0x40b070, 0x1a5a30]];
		private static const GRIPS:Array = [[0xa07040, 0x6a4422, 0x3a2410], [0x6a6a7a, 0x3a3a48, 0x1a1a24], [0xa04050, 0x6a1a2a, 0x3a0a14], [0x50a0a0, 0x1a5a5a, 0x0a2a2a]];
		/** Rarity colours lean named gear this way (Data.RARITY_COLORS). */
		private static const STAT_GEMS:Object = {hp: 0xff4050, mp: 0x4080ff, att: 0xff6020, def: 0xa0a0b0, spd: 0x40e070, dex: 0xffa040, vit: 0xff3080,
			wis: 0x60c0ff, mgt: 0xff4040, luc: 0x40ffa0, prt: 0xc0d0ff, frt: 0xffe040};

		// ------------------------------------------------------------ helpers
		private static function hash(s:String):uint {
			var h:uint = 2166136261;
			for (var i:int = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = uint(h * 16777619); }
			return h;
		}
		private static function shade(c:uint, f:Number):uint {
			return (int(Math.min(255, ((c >> 16) & 255) * f)) << 16) | (int(Math.min(255, ((c >> 8) & 255) * f)) << 8) | int(Math.min(255, (c & 255) * f));
		}
		private static function tint(c:uint, t:Number):uint {
			var r:int = ((c >> 16) & 255), g:int = ((c >> 8) & 255), b:int = (c & 255);
			return (int(r + (255 - r) * t) << 16) | (int(g + (255 - g) * t) << 8) | int(b + (255 - b) * t);
		}
		private static function mix(a:uint, b:uint, t:Number):uint {
			var r:int = ((a >> 16) & 255) * (1 - t) + ((b >> 16) & 255) * t;
			var g:int = ((a >> 8) & 255) * (1 - t) + ((b >> 8) & 255) * t;
			var bl:int = (a & 255) * (1 - t) + (b & 255) * t;
			return (r << 16) | (g << 8) | bl;
		}
		private static function ramp(c:uint):Array { return [tint(c, 0.45), c, shade(c, 0.5)]; }
		/** Where word w starts a word in name (-1 if it doesn't): "oak" isn't in "cloak". */
		private static function wordAt(name:String, w:String):int {
			var i:int = name.indexOf(w);
			while (i >= 0) {
				var c:String = i > 0 ? name.charAt(i - 1) : " ";
				if (c < "a" || c > "z") return i;
				i = name.indexOf(w, i + 1);
			}
			return -1;
		}
		private static function has(name:String, words:Array):Boolean {
			for each (var w:String in words) if (wordAt(name, w) >= 0) return true;
			return false;
		}
		/** The first element named (or null). */
		private static function elementOf(name:String):Object {
			var best:Object = null, at:int = 9999;
			for each (var e:Object in ELEMENTS) for each (var w:String in e.w) {
				var i:int = wordAt(name, w);
				if (i >= 0 && i < at) { at = i; best = e; }
			}
			return best;
		}
		private static function materialOf(name:String):Array {
			for each (var m:Object in MATERIALS) if (has(name, m.w)) return m.m;
			return null;
		}
		private static function shapesOf(name:String):Object {
			var out:Object = {};
			for each (var s:Object in SHAPES) if (has(name, s.w)) out[s.s] = true;
			return out;
		}

		// ------------------------------------------------------------ the drawing
		/** Who an item is (as ItemArt.identity). */
		public static function identity(it:Object):String {
			if (it.gid) return "g:" + it.gid;
			if (it.uid) return "u:" + it.uid;
			if (it.set) return "s:" + it.set + ":" + it.sub;
			if (it.rarity) return "n:" + it.rarity + ":" + it.name;
			return "t:" + it.kind + ":" + it.sub + ":" + it.tier + (it.ab ? ":" + it.ab : "");
		}

		/** The family an item is drawn from, or null. */
		public static function family(it:Object):Array {
			switch (it.kind) {
				case "weapon":
					return WEAPONS[it.sub] || WAND;
				case "ability": return ABILITIES[it.sub] || TOME;
				case "armor": return ARMOURS[it.sub] || ROBE;
				case "ring": return RING;
			}
			return null;
		}

		/** The 8x8 drawing and its colours ({rows, pal}) for a piece of gear, or null. */
		public static function art(it:Object):Object {
			var fam:Array = family(it);
			if (!fam) return null;
			var name:String = String(it.name || "").toLowerCase();
			// something named for what it is (a keg, a crown, a trident...) is drawn as that
			var noun:Array = null;
			for each (var nn:Array in NOUNS) if ((nn[2] == "w") == (it.kind == "weapon") && has(name, nn[0])) { noun = nn[1]; break; }
			// (robes, cloaks, hourglasses and quivers are drawn whole)
			var drawn:Boolean = !noun && DRAWN[it.sub] != null;
			if (drawn) noun = DRAWN[it.sub];
			if (noun) fam = ringed(noun);
			// (crowns, halos and chalices are gold whatever else they are)
			var golden:Boolean = noun == CROWN || noun == HALO || noun == CHALICE;
			var id:String = identity(it);
			var h:uint = hash(id);
			var t:int = Math.max(0, Math.min(7, int(it.tier || 0)));
			var named:Boolean = it.rarity != null && it.rarity != undefined;
			var el:Object = elementOf(name);
			var shp:Object = shapesOf(name);
			var diag:Boolean = it.kind == "weapon";
			// how grand it is: plain tiers grow with tier, named gear is grand
			var grand:int = named ? 3 + (it.rarity == "lg" || it.rarity == "ar" || it.rarity == "gd" ? 1 : 0) : t < 2 ? 0 : t < 4 ? 1 : t < 6 ? 2 : 3;

			// ---- colours
			var metal:Array = el ? el.m : materialOf(name) || TIER_METAL[t];
			if (!el && !named && it.kind == "armor") metal = materialOf(name) || armourCloth(it.sub, t);
			if (it.kind == "ability" && !el) metal = ramp(abilityCol(it.sub));
			var trim:Array = TRIMS[it.rarity == "gd" ? 0 : named ? (h >>> 3) % TRIMS.length : t >= 5 ? 0 : t >= 3 ? 1 : 2];
			var grip:Array = GRIPS[(h >>> 7) % GRIPS.length];
			if (!named && t < 3) grip = GRIPS[0];
			var gem:uint = it.kind == "ring" ? uint(STAT_GEMS[it.sub] || 0xffffff) : el ? uint(el.gem) : TIER_GEM[t];
			var fx:Array = el ? el.fx : [tint(gem, 0.5), gem];
			// (an hourglass's sand is sand, a quiver's fletching red and white, unless an element says otherwise)
			if (!el && it.sub == "hourglass") fx = [0xfff0b0, 0xd8b060];
			if (!el && it.sub == "quiver") fx = [0xffffff, 0xd04040];
			if (named && !el) {
				// named gear with no element: leans toward its rarity's colour
				var rc:uint = Data.RARITY_COLORS[it.rarity] || 0xffffff;
				metal = ramp(mix(metal[1], rc, 0.45));
			}
			if (it.rarity == "gd") { metal = [0xffffff, 0xfff0d0, 0xc8b080]; trim = TRIMS[0]; }
			if (golden) trim = TRIMS[0];
			// shafts of staves, wands and bows are their own wood unless an element runs through them
			var shaft:Array = el && it.sub == "bow" ? [el.m[1], el.m[2], shade(el.m[2], 0.6)] : grip;
			// a wand's or staff's shaft is never shiny metal (it would read as a blade): wood, bone, ebony or pale ash
			if (it.sub == "wand" || it.sub == "staff") {
				shaft = has(name, ["bone", "grave", "skull", "lich", "death", "soul"]) ? [0xf0e8d0, 0xc8bc9c, 0x7a6e58]
					: has(name, ["radian", "holy", "saint", "seraph", "light", "dawn", "sun", "penance"]) ? [0xfff8e0, 0xe0d0a8, 0x9a8458]
					: has(name, ["void", "shadow", "eldritch", "night", "hex", "abyss", "dusk"]) ? [0x5a4a6a, 0x2e2238, 0x140e1a]
					: [[0xb07a48, 0x744a26, 0x40260f], [0x9a6a50, 0x5e3a28, 0x321c12], [0x8a7a5a, 0x5a4a32, 0x30261a]][(h >>> 5) % 3];
			}
			var pal:Object = {H: metal[0], B: metal[1], b: metal[2], Y: grip[0], W: grip[1], w: grip[2], J: trim[0], G: trim[1], g: trim[2],
				X: tint(gem, 0.35), R: gem, r: shade(gem, 0.55), M: fx[0], m: fx[1], S: 0xf0f0e8, O: 0x101018, Z: 0xffffff,
				K: shaft[0], k: shaft[1], q: shaft[2]};

			// ---- which cells: the core, and what of the ring the item grows into
			var cells:Array = [];   // cells[y][x]: "" empty, else a part: m metal, g grip, t trim, e gem, s string, x motif, f shaft, c cloth
			var skel:Array = [];
			var y:int, x:int, ch:String;
			for (y = 0; y < 8; y++) {
				cells.push(["", "", "", "", "", "", "", ""]);
				skel.push([false, false, false, false, false, false, false, false]);
				for (x = 0; x < 8; x++) {
					ch = String(fam[y]).charAt(x);
					if (ch == "@" || ch == "*" || ch == "%") skel[y][x] = true;
					if (ch == "#" || ch == "@") cells[y][x] = "m";
					if (noun && String(noun[y]).charAt(x) != ".") cells[y][x] = String(noun[y]).charAt(x);
				}
			}
			var ring:Function = function(x:int, y:int, deep:Boolean = false):Boolean {
				if (x < 0 || y < 0 || x > 7 || y > 7) return false;
				var c:String = String(fam[y]).charAt(x);
				return c == "+" || c == "*" || (deep && (c == "-" || c == "%"));
			};
			var put:Function = function(x:int, y:int, part:String, deep:Boolean = false):void {
				if (x < 0 || y < 0 || x > 7 || y > 7) return;
				if (cells[y][x] == "" && !ring(x, y, deep)) return;
				cells[y][x] = part;
			};
			var core:Function = function(x:int, y:int):Boolean { var c:String = String(fam[y]).charAt(x); return c == "#" || c == "@"; };

			// along the "/" axis: p 0 at the tail (bottom-left) to 1 at the tip, q across it (+ below-right)
			if (drawn) dressDrawn(it.sub, cells, put, el, grand, h);
			if (noun) { if (el) { if (diag) edgeMotif(el.motif, cells, ring, put, grand, h); else motif(el.motif, cells, ring, put, false, h, ""); } }
			else if (diag) dressWeapon(it, cells, skel, ring, put, core, shp, el, grand, h, fam);
			else if (it.kind == "armor") dressArmour(it, cells, ring, put, el, grand, h, shp);
			else dressSymmetric(it, cells, skel, ring, put, el, grand, h);

			// ---- shading: light from the top-left, five tones a part (glint, light, base, shade, deep)
			var KEYS:Object = {m: ["A", "H", "B", "b", "a"], g: ["y", "Y", "W", "w", "v"], t: ["j", "J", "G", "g", "h"], e: ["E", "X", "R", "r", "c"],
				x: ["N", "M", "M", "m", "n"], f: ["F", "K", "k", "q", "Q"], s: ["S", "S", "S", "S", "S"], o: ["O", "O", "O", "O", "O"],
				z: ["Z", "Z", "Z", "Z", "Z"], d: ["b", "b", "b", "a", "a"]};
			pal.A = tint(pal.H, 0.55); pal.a = shade(pal.b, 0.6); pal.y = tint(pal.Y, 0.4); pal.v = shade(pal.w, 0.6);
			pal.j = tint(pal.J, 0.55); pal.h = shade(pal.g, 0.6); pal.E = tint(pal.X, 0.6); pal.c = shade(pal.r, 0.6);
			pal.F = tint(pal.K, 0.4); pal.Q = shade(pal.q, 0.6); pal.N = tint(pal.M, 0.45); pal.n = shade(pal.m, 0.6);
			pal.R = uint(pal.R); pal.X = uint(pal.X);
			// the light falls across the whole drawing: brighter toward its top-left, darker toward its foot
			var bx0:int = 8, by0:int = 8, bx1:int = -1, by1:int = -1;
			for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) if (cells[y][x] != "") { bx0 = Math.min(bx0, x); by0 = Math.min(by0, y); bx1 = Math.max(bx1, x); by1 = Math.max(by1, y); }
			var mid:Number = (bx0 + bx1 + by0 + by1) / 2, span:Number = Math.max(2, (bx1 - bx0 + by1 - by0) / 2);
			var open:Function = function(x:int, y:int):Boolean { return x < 0 || y < 0 || x > 7 || y > 7 || cells[y][x] == "" || cells[y][x] == "o"; };
			var score:Array = [];
			var best:Object = {};   // each part's brightest cell takes the glint
			for (y = 0; y < 8; y++) {
				score.push([0, 0, 0, 0, 0, 0, 0, 0]);
				for (x = 0; x < 8; x++) {
					var part:String = cells[y][x];
					if (part == "") continue;
					var sc:Number = 0.5 * (mid - x - y) / span;
					// rim light on the edges facing the light, core shadow on the edges turned from it
					if (open(x, y - 1)) sc += 0.7;
					if (open(x - 1, y)) sc += 0.5;
					if (open(x, y + 1)) sc -= 0.7;
					if (open(x + 1, y)) sc -= 0.5;
					// a part sitting under another is in its shadow (a blade under its guard, a gem in its setting)
					if (y > 0 && cells[y - 1][x] != "" && cells[y - 1][x] != part && part != "e") sc -= 0.35;
					if (x > 0 && cells[y][x - 1] != "" && cells[y][x - 1] != part && part != "e") sc -= 0.2;
					// a blade's spine catches the light
					if (part == "m" && diag && skel[y][x]) sc += 0.9;
					score[y][x] = sc;
					if (!best[part] || sc > best[part][2]) best[part] = [x, y, sc];
				}
			}
			var rows:Array = [];
			for (y = 0; y < 8; y++) {
				var row:String = "";
				for (x = 0; x < 8; x++) {
					var pt:String = cells[y][x];
					if (pt == "") { row += "."; continue; }
					var k:Array = KEYS[pt] || KEYS.m;
					var v:Number = score[y][x];
					var b:Array = best[pt];
					var glint:Boolean = b && b[0] == x && b[1] == y && (pt == "e" || ((pt == "m" || pt == "t" || pt == "f") && v >= 1.1));
					row += glint ? k[0] : v >= 0.8 ? k[1] : v >= -0.5 ? k[2] : v >= -1.3 ? k[3] : k[4];
				}
				rows.push(row);
			}
			return {rows: rows, pal: pal};
		}

		/** The drawn gear's details by grandeur and name: gems, hems, tattered edges. */
		private static function dressDrawn(sub:String, cells:Array, put:Function, el:Object, grand:int, h:uint):void {
			var x:int, y:int;
			// plain ones have no gem
			if (grand < 1) for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) if (cells[y][x] == "e" && sub != "hourglass") cells[y][x] = sub == "quiver" ? "g" : sub == "robe" ? "t" : "t";
			if (sub == "robe" && grand >= 2) for (x = 0; x < 8; x++) cells[7][x] = "t";
			if (sub == "robe" && grand >= 3) { put(0, 0, "t"); put(7, 0, "t"); }
			if (sub == "cloak" && el && (el.motif == "wisp")) { cells[7][1] = cells[7][4] = cells[7][6] = ""; }
			if (sub == "cloak" && grand >= 2) { cells[5][0] = cells[5][7] = "t"; }
			if (sub == "quiver" && grand >= 2) { put(0, 2, "t"); put(7, 2, "t"); }
		}

		/** A drawing as a family: its cells the core, one cell round it the ring. */
		private static function ringed(d:Array):Array {
			var out:Array = [];
			for (var y:int = 0; y < 8; y++) {
				var row:String = "";
				for (var x:int = 0; x < 8; x++) {
					if (String(d[y]).charAt(x) != ".") { row += "#"; continue; }
					var near:Boolean = false;
					for (var dy:int = -1; dy <= 1; dy++) for (var dx:int = -1; dx <= 1; dx++) {
						var nx:int = x + dx, ny:int = y + dy;
						if (nx >= 0 && ny >= 0 && nx < 8 && ny < 8 && String(d[ny]).charAt(nx) != ".") near = true;
					}
					row += near ? "+" : "-";
				}
				out.push(row);
			}
			return out;
		}

		private static function armourCloth(sub:String, t:int):Array {
			var cols:Object = {robe: [0x7a6a5a, 0x3a5ab0, 0x5a3a9a, 0x2a7a8a, 0x3a3aa0, 0x8a2a6a, 0xa02a3a, 0x303050],
				leather: [0x8a5a2a, 0x7a4a22, 0x6a6a2a, 0x4a6a2a, 0x8a3a2a, 0x2a6a5a, 0x5a2a5a, 0x2a3a4a],
				heavy: [0x8a8a92, 0x9a8a72, 0x7a8aa6, 0xa0a8b8, 0x6a7a9a, 0x8ab0d0, 0xa04030, 0xc8a040]};
			var a:Array = cols[sub] || cols.robe;
			return ramp(a[Math.min(7, t)]);
		}
		private static function abilityCol(sub:String):uint {
			var c:Object = {spell: 0x8a5ac0, quiver: 0x8a5a2a, shield: 0x6a7aaa, tome: 0xa83a3a, cloak: 0x5a3a8a, helm: 0xa0a0b0, skull: 0xd8d0b8,
				trap: 0x7a7a84, lyre: 0xd0a040, flask: 0x9ac0d0, hourglass: 0xa07a3a};
			return c[sub] || 0x8a8a8a;
		}

		/** A diagonal weapon: grip at the tail, its guard, the blade or shaft, its head, and the motif. */
		private static function dressWeapon(it:Object, cells:Array, skel:Array, ring:Function, put:Function, core:Function, shp:Object, el:Object,
				grand:int, h:uint, fam:Array):void {
			var sub:String = it.kind == "ability" ? "quiver" : it.sub;
			var x:int, y:int, p:Number, q:int;
			// parts along the axis
			for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) {
				if (cells[y][x] == "") continue;
				p = (x + 7 - y) / 14; q = x + y - 7;
				if (sub == "sword") cells[y][x] = p < 0.12 ? "t" : p < 0.24 ? "g" : "m";
				else if (sub == "dagger") cells[y][x] = p > 0.88 ? "t" : p > 0.72 ? "g" : "m";
				else if (sub == "wand" || sub == "staff") cells[y][x] = "f";
				else if (sub == "bow") cells[y][x] = x + y == 6 && x > 0 && y > 0 ? "s" : (p > 0.4 && p < 0.6 ? "g" : "f");
				else if (sub == "quiver") cells[y][x] = p > 0.8 ? "z" : (Math.abs(p - 0.3) < 0.04 || Math.abs(p - 0.6) < 0.04) ? "t" : "g";
			}
			// a bow: trim on its limbs' ends, a gem in its grip, an arrow nocked on the grander ones
			if (sub == "bow") {
				if (grand >= 1) { cells[0][7] = "t"; cells[7][0] = "t"; }
				if (grand >= 2) { put(5, 5, "e"); }
				if (grand >= 3) { put(2, 3, "z", true); put(3, 2, "z", true); }
			}
			// a quiver: arrows' fletching out of its top
			if (sub == "quiver") { put(5, 0, "x"); put(7, 2, "x"); if (grand >= 2) { put(4, 0, "x", true); put(7, 3, "x", true); } }
			// the sword's cross-bar: perpendicular, through the ring at the guard
			if (sub == "sword") {
				var span:int = grand >= 2 || shp.broad ? 2 : 1;
				put(3, 6, "t"); put(1, 4, "t");
				if (span > 1) { put(4, 7, "t", true); put(0, 3, "t", true); }
				// a broad blade grows a cell along its back; a curved one bows out along its edge
				if (shp.broad) { put(4, 2, "m"); put(5, 1, "m"); put(3, 3, "m"); }
				if (shp.curve) { put(6, 3, "m"); put(7, 2, "m"); }
				if (shp.long || grand >= 3) { put(7, 0, "m"); }
				if (grand >= 1) cells[7][0] = "e";   // a gem in the pommel
			}
			if (sub == "dagger") {
				if (shp.curve) { put(1, 5, "m"); put(2, 4, "m"); }
				if (grand >= 2) cells[0][7] = "e";
			}
			if (sub == "wand" || sub == "staff") {
				// the head: an orb of the gem (a plus round (6,1)) on a collar of trim, capped, and held in
				// claws that curl round it; a staff's claws are long horns, and it has a crystal on top
				// (the template's head is a solid wedge in the corner, which reads as a blade's tip: carved
				// round, an orb with air about it)
				cells[0][7] = cells[2][5] = "";
				cells[0][6] = cells[1][5] = cells[1][6] = cells[1][7] = cells[2][6] = "e";
				cells[2][4] = "t";
				// a staff: a crystal point above the orb and two short claws holding it (long horns across
				// the shaft read as a pick); a wand is just the orb
				if (sub == "staff") { cells[0][7] = "e"; put(5, 0, "t"); put(7, 2, "t"); if (grand >= 2) cells[2][5] = "t"; }
				// wraps round the shaft, and a cap at its foot
				cells[4][3] = "t";
				if (grand >= 2) cells[6][1] = "t";
				cells[7][0] = grand >= 1 ? "e" : "t";
			}
			if (shp.twin && sub == "bow") { put(1, 6, "f"); put(6, 1, "f"); }
			// the element's motif, in the ring round the tip and head
			// (a wand's or staff's head keeps its shape: one spark of its element at most)
			var head:Boolean = sub == "wand" || sub == "staff";
			if (el && !head) edgeMotif(el.motif, cells, ring, put, grand, h);
			else if (grand >= 3 && !head) edgeMotif("glint", cells, ring, put, grand, h);
		}

		/** Armour: the slab, then pauldrons, belt and emblem by its name. */
		private static function dressArmour(it:Object, cells:Array, ring:Function, put:Function, el:Object, grand:int, h:uint, shp:Object):void {
			var x:int, y:int;
			if (it.sub == "robe") {
				// a neckline, a seam down the front, a sash and (grander) a hem in trim
				cells[0][3] = cells[0][4] = "o";
				cells[1][3] = cells[1][4] = "t";
				for (y = 1; y < 5; y++) { if (cells[y][0] != "") cells[y][0] = "d"; if (cells[y][7] != "") cells[y][7] = "d"; }
				for (x = 0; x < 8; x++) { if (cells[4][x] != "") cells[4][x] = "t"; if (grand >= 2 && cells[7][x] != "") cells[7][x] = "t"; }
				if (grand >= 1) cells[4][3] = cells[4][4] = "e";
				if (grand >= 3) { put(0, 0, "t"); put(7, 0, "t"); }
			} else {
				// a belt, a collar; heavy armour's pauldrons grow into the shoulders' ring
				for (x = 0; x < 8; x++) if (cells[4][x] != "") cells[4][x] = it.sub == "leather" ? "g" : "t";
				if (it.sub == "heavy") { put(0, 0, "t"); put(7, 0, "t"); if (grand >= 2) { put(3, 0, "t"); put(4, 0, "t"); } }
				else { put(3, 0, "g"); put(4, 0, "g"); }
				if (grand >= 1) { cells[2][3] = "e"; cells[2][4] = "e"; }
				if (shp.broad || grand >= 3) { put(0, 4, "t"); put(7, 4, "t"); put(1, 5, "m"); put(6, 5, "m"); }
			}
			if (el) motif(el.motif, cells, ring, put, false, h, it.sub);
		}

		/** The symmetric gear (abilities and rings): trim and a gem by grandeur, then the motif. */
		private static function dressSymmetric(it:Object, cells:Array, skel:Array, ring:Function, put:Function, el:Object, grand:int, h:uint):void {
			var x:int, y:int;
			var sub:String = it.kind == "ring" ? "ring" : it.sub;
			for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) {
				if (cells[y][x] == "") continue;
				if (skel[y][x]) cells[y][x] = sub == "hourglass" ? "x" : sub == "lyre" ? "s" : "t";
			}
			switch (sub) {
				case "ring":
					for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) if (cells[y][x] != "") cells[y][x] = "t";
					// the stat's gem, big, set on top of the band
					cells[0][3] = cells[0][4] = cells[1][2] = cells[1][3] = cells[1][4] = cells[1][5] = "e";
					if (grand >= 1) { put(2, 0, "e"); put(5, 0, "e"); }
					if (grand >= 3) { put(1, 1, "t"); put(6, 1, "t"); }
					break;
				case "spell": cells[3][3] = cells[3][4] = cells[4][3] = cells[4][4] = "e"; break;
				case "shield": if (grand >= 1) { cells[3][3] = cells[3][4] = "e"; } if (grand >= 3) { put(0, 0, "t"); put(7, 0, "t"); } break;
				case "tome": for (y = 0; y < 8; y++) if (cells[y][0] != "" || ring(0, y)) put(0, y, "g"); cells[3][3] = cells[3][4] = cells[4][3] = cells[4][4] = "e"; break;
				case "cloak": put(3, 0, "t"); put(4, 0, "t"); if (grand >= 1) cells[2][3] = cells[2][4] = "e"; break;
				case "helm": cells[4][2] = cells[4][3] = cells[4][4] = cells[4][5] = "o"; if (grand >= 2) { put(3, 0, "e"); put(4, 0, "e"); } if (grand >= 3) { put(0, 2, "t"); put(7, 2, "t"); } break;
				case "skull": cells[3][2] = cells[3][5] = "o"; cells[3][1] = cells[3][6] = "m"; cells[5][3] = cells[5][4] = "o"; if (grand >= 1) { cells[3][2] = cells[3][5] = "e"; } break;
				case "trap": cells[3][3] = cells[3][4] = cells[4][3] = cells[4][4] = "o"; for each (var c:Array in [[0, 0], [7, 0], [0, 7], [7, 7], [3, 0], [4, 0], [3, 7], [4, 7]]) put(c[0], c[1], "t"); break;
				case "lyre": put(3, 2, "s"); put(4, 2, "s"); for (y = 0; y < 2; y++) { put(3, y, "s"); put(4, y, "s"); } if (grand >= 2) cells[4][3] = cells[4][4] = "e"; break;
				case "flask": cells[5][3] = cells[5][4] = cells[6][3] = cells[6][4] = "e"; for (x = 0; x < 8; x++) if (cells[6][x] != "") cells[6][x] = "e"; put(3, 0, "g"); put(4, 0, "g"); break;
				case "hourglass": for (x = 0; x < 8; x++) { if (cells[0][x] != "") cells[0][x] = "g"; if (cells[7][x] != "") cells[7][x] = "g"; } cells[6][3] = cells[6][4] = "x"; break;
			}
			if (el) motif(el.motif, cells, ring, put, false, h, sub);
		}

		/**
		 * A weapon's motif along its edge: ring cells next to the head half of the weapon, on its back
		 * (up-left: flames, wisps, sparks rise) or under it (down-right: drips and waves fall), every other
		 * one, more for grander weapons. Scales, facets and runes mark the blade itself.
		 */
		private static function edgeMotif(kind:String, cells:Array, ring:Function, put:Function, grand:int, h:uint):void {
			var x:int, y:int;
			if (kind == "scale" || kind == "facet" || kind == "rune") { motif(kind, cells, ring, put, true, h, ""); return; }
			var below:Boolean = kind == "drip" || kind == "fang" || kind == "wave";
			var spots:Array = [];
			for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) {
				if (cells[y][x] != "" || !ring(x, y, true)) continue;
				var p:Number = (x + 7 - y) / 14, q:int = x + y - 7;
				if (p < 0.5 || (below ? q <= 0 : q >= 0)) continue;
				// (next to the weapon)
				var near:Boolean = false;
				for (var dy:int = -1; dy <= 1; dy++) for (var dx:int = -1; dx <= 1; dx++) {
					var nx:int = x + dx, ny:int = y + dy;
					if (nx >= 0 && ny >= 0 && nx < 8 && ny < 8 && cells[ny][nx] != "" && (dx == 0 || dy == 0)) near = true;
				}
				if (near) spots.push([x, y, p]);
			}
			spots.sortOn([2], Array.NUMERIC | Array.DESCENDING);
			var n:int = kind == "glint" ? 1 : 2 + int(grand / 2);
			var bright:Boolean = kind == "star" || kind == "crystal" || kind == "rays" || kind == "crescent" || kind == "glint";
			for (var i:int = 0, k:int = 0; i < spots.length && k < n; i += 2, k++) put(spots[i][0], spots[i][1], bright && k == 0 ? "z" : "x", true);
		}

		/**
		 * The element's motif, in the ring: for weapons round the tip (top-right), for the rest round
		 * the top of the drawing. Only ever ring cells (put refuses anything else).
		 */
		private static function motif(kind:String, cells:Array, ring:Function, put:Function, weapon:Boolean, h:uint, sub:String):void {
			var x:int, y:int;
			// the topmost and rightmost filled cell: the tip
			var tx:int = 0, ty:int = 7, best:int = -99;
			for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) if (cells[y][x] != "" && x - y > best) { best = x - y; tx = x; ty = y; }
			var top:int = 0;
			for (y = 0; y < 8; y++) { var any:Boolean = false; for (x = 0; x < 8; x++) if (cells[y][x] != "") any = true; if (any) { top = y; break; } }
			switch (kind) {
				case "flame":
					// tongues of flame licking up and out from the tip
					if (weapon) { put(tx - 1, ty, "x", true); put(tx - 2, ty, "x", true); put(tx - 1, ty + 1, "x"); put(tx, ty + 2, "x"); }
					else { put(2, top, "x"); put(5, top, "x"); put(3, top + 1, "x"); }
					break;
				case "crystal":
					if (weapon) { put(tx - 1, ty, "z", true); put(tx, ty + 1, "x", true); put(tx - 2, ty + 1, "x", true); }
					else { put(1, top, "z"); put(6, top, "z"); }
					break;
				case "star":
					if (weapon) { put(tx - 1, ty, "z", true); put(tx, ty + 1, "z", true); put(tx - 3, ty, "x", true); }
					else { put(3, top, "z"); put(4, top, "z"); }
					break;
				case "drip":
				case "fang":
					// a drop hanging below the blade (blood, or venom off a fang)
					if (weapon) { put(tx, ty + 2, "x", true); put(tx - 1, ty + 3, "x", true); }
					else { put(2, 7, "x"); put(5, 7, "x"); }
					break;
				case "bolt":
					if (weapon) { put(tx - 1, ty, "x", true); put(tx - 2, ty + 1, "x", true); put(tx, ty + 2, "x", true); }
					else { put(2, top, "x"); put(5, top + 1, "x"); }
					break;
				case "wave":
					if (weapon) { put(tx - 1, ty + 2, "x", true); put(tx + 1 - 3, ty + 3, "x", true); }
					else { put(0, 6, "x"); put(7, 6, "x"); }
					break;
				case "skull":
					if (weapon) { put(tx - 1, ty, "x", true); put(tx, ty + 1, "x", true); }
					else { put(3, top, "z"); put(4, top, "z"); }
					break;
				case "wisp":
					if (weapon) { put(tx - 2, ty, "x", true); put(tx, ty + 2, "x", true); }
					else { put(1, top, "x"); put(6, top, "x"); }
					break;
				case "leaf":
					// leaves sprouting off the shaft
					if (weapon) { put(2, 3, "x", true); put(4, 5, "x", true); put(3, 3, "x"); }
					else { put(0, 3, "x"); put(7, 3, "x"); }
					break;
				case "scale":
					for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) if (cells[y][x] == "m" && (x + y) % 2 == 0 && (y % 3 == 2)) cells[y][x] = "d";
					break;
				case "crescent":
					if (weapon) { put(tx - 1, ty, "z", true); put(tx - 2, ty + 1, "z", true); }
					else { put(2, top, "z"); put(1, top + 1, "z"); }
					break;
				case "facet":
					for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) if (cells[y][x] == "m" && (x * 3 + y * 5 + int(h % 4)) % 7 == 0) cells[y][x] = "z";
					break;
				case "rays":
					if (weapon) { put(tx - 1, ty, "z", true); put(tx, ty + 1, "z", true); }
					else { put(0, top, "z"); put(7, top, "z"); put(3, top, "z"); }
					break;
				case "rune":
					if (!weapon) { put(0, 3, "x"); put(7, 3, "x"); break; }
					for (y = 0; y < 8; y++) for (x = 0; x < 8; x++) if (cells[y][x] == "m" && (x * 5 + y * 3 + int(h % 5)) % 9 == 0) cells[y][x] = "x";
					break;
				case "glint":
					if (weapon) put(tx - 1, ty, "z", true);
					break;
			}
		}
	}
}
