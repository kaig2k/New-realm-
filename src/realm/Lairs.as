package realm {
	/**
	 * Lairs: every realm event boss leaves a portal to its own dungeon, built in its image, with its own
	 * way through and its own master waiting at the end. The rules here run wherever the dungeon's monsters
	 * run (the server online, the game itself offline), through a small api:
	 *   {spawn(id, x, y, zone, force):Enemy, remove(e), say(text, color, banner), players:Array of {x, y}}
	 *
	 * What a lair can ask of you (th.lair):
	 *   shield: {ids, n, where: "rooms"|"boss", r, regrow, text}  its master can't be hurt while any of these stand
	 *           ("rooms": hidden through the dungeon, find them all; "boss": round its throne, regrowing)
	 *   mend:   {id, n, r, rate}        totems round the master that heal it while they stand
	 *   waves:  {mobs, n, size}         the master's hall fills with waves first; it comes when they're done
	 *   rebirth:{egg, t, into}          the master falls, then rises again: from an egg you can break in time,
	 *                                   or (no egg) at once in its second form
	 *   feed:   {id, every, n, heal, speed, text}  things drift in from the hall's edge toward the master and
	 *                                   heal it if they reach it (cut them down on the way)
	 *   shield.order: true             its shield breaks one piece at a time, in turn (only the lit one can be
	 *                                   hurt); shield.overclock: each that breaks makes the master fire faster
	 *   ascend: {ids, at, n, text}       at each fraction of its health in `at` the master rises out of reach,
	 *                                   and n of these appear out in the dungeon's rooms to drag it back down
	 *   quiet: true                      a finale: its master's own death opens the ways out (Game), not the lair
	 *   (and on the master's def: splitInto {what, n}: it breaks into lesser copies that must all fall)
	 * Trios (th.trio) share the last hall as in the other dungeons.
	 */
	public class Lairs {
		/** The lairs (Bosses.init appends them to Data.DUNGEONS). by: the realm boss whose lair it is. */
		public static const DUNGEONS:Array = [
			{id: "tesseract", wall: "metal_violet", by: "ev_cube", name: "The Tesseract", color: 0xc040ff, layout: "grid", floor: 24, accent: 30, tier: 4, hard: 1.2, lair: {
				boss: "tesseract", intro: "Four Prism Nodes feed the Tesseract its shield. Find them in the halls and shatter them.",
				shield: {ids: ["prism_node"], n: 4, where: "rooms", text: "A Prism Node shatters! The Tesseract's shield flickers."}},
				mobs: ["cubelet", "cube_shard", "gazer", "beholder"]},
			{id: "titan_forge", wall: "basalt", by: "ev_titan", name: "Titan's Forge", color: 0xff6018, layout: "cave", hazard: "lava", floor: 20, accent: 7, tier: 4, hard: 1.2, lair: {
				boss: "forgemaster", intro: "The Forgemaster's bellows breathe fire into him. Silence them or he never tires.",
				mend: {id: "forge_bellows", n: 3, r: 8, rate: 0.012}},
				mobs: ["imp", "lesser_demon", "dwarf", "golem"]},
			{id: "wyrm_cradle", wall: "ice", by: "ev_wyrm", name: "The Wyrm Cradle", color: 0x80d8ff, layout: "ring", hazard: "water", floor: 19, accent: 0, tier: 4, hard: 1.2, lair: {
				boss: "glacia", intro: "Glacia sleeps inside a ring of ice obelisks. Break them, and keep breaking them: the cold grows them back.",
				shield: {ids: ["cradle_obelisk"], n: 4, where: "boss", r: 8, regrow: 28, text: "The ice obelisks grow back! Glacia is warded again!"}},
				mobs: ["ice_wolf", "ice_wolf", "ghost", "djinn"]},
			{id: "hollow_court", wall: "gilded", by: "ev_king", name: "The Hollow Court", color: 0x9aff7a, layout: "grid", dark: true, floor: 33, accent: 11, tier: 4, hard: 1.2, lair: {
				boss: "hollow_prince", intro: "Three Crown Knights each keep a shard of the Hollow Prince's crown. He can't be touched while one stands.",
				shield: {ids: ["crown_knight"], n: 3, where: "rooms", text: "A Crown Knight falls and its shard goes dark."}},
				mobs: ["skeleton", "royal_guard", "shade", "grave_wraith"]},
			{id: "bone_pit", wall: "bone_blood", by: "ev_behemoth", name: "The Bone Pit", color: 0xff3a30, layout: "cave", floor: 25, accent: 14, tier: 4, hard: 1.2, lair: {
				boss: "rendmaw", intro: "Gorehorn's brood nests in the Pit. Survive their rush in the great den and their alpha comes for you.",
				waves: {mobs: ["gore_spawn", "gore_spawn", "blood_hound", "minotaur"], n: 3, size: 7}},
				mobs: ["gore_spawn", "blood_hound", "ogre", "minotaur"]},
			{id: "phantom_court", wall: "spectral", by: "ev_regent", name: "The Phantom Court", color: 0xc090ff, layout: "islands", dark: true, floor: 28, accent: 8, tier: 4, hard: 1.2, lair: {
				boss: "mirror_regent", intro: "The Mirror Regent hides among its own reflections. Shatter the echoes and the true Regent is laid bare.",
				shield: {ids: ["regent_echo"], n: 3, where: "boss", r: 7, text: "An echo shatters into mist!"}},
				mobs: ["shade", "ghost", "void_wisp", "grave_wraith"]},
			{id: "tomb_of_riddles", wall: "sandstone", by: "ev_sphinx", name: "The Tomb of Riddles", color: 0xffc040, layout: "maze", floor: 21, accent: 26, tier: 4, hard: 1.2, lair: {
				boss: "pharaoh", intro: "Ankhamun's heart lies in four canopic jars hidden in the maze. While one is whole, he cannot die.",
				shield: {ids: ["canopic_jar"], n: 4, where: "rooms", text: "A canopic jar breaks! Ankhamun howls in his tomb."}},
				mobs: ["temple_scorpion", "scorpion", "great_snake", "medusa"]},
			{id: "drowned_keep", wall: "mossy", by: "ev_lord", name: "The Drowned Keep", color: 0x50a0c0, layout: "rooms", hazard: "water", floor: 18, accent: 0, tier: 4, hard: 1.2, lair: {
				boss: "admiral_brine", intro: "Admiral Brine drowned with his keep, and the sea will not let him stay dead.",
				rebirth: {into: "admiral_drowned"}},
				mobs: ["pirate", "pirate_brawler", "tide_spawn", "crab"]},
			{id: "coral_grotto", wall: "coral", by: "ev_hermit", name: "The Coral Grotto", color: 0x30c8b0, layout: "cave", hazard: "water", floor: 23, accent: 0, tier: 4, hard: 1.2, lair: {
				boss: "pearlmaw", intro: "Pearlmaw's giant clams pour their pearls into it. Crack the clams or it heals faster than you can hurt it.",
				mend: {id: "pearl_clam", n: 3, r: 8, rate: 0.014}},
				mobs: ["crab", "tide_spawn", "snake", "great_snake"]},
			{id: "ossuary", wall: "bone_violet", by: "ev_shrine", name: "The Ossuary", color: 0xb070ff, layout: "grid", dark: true, floor: 25, accent: 28, tier: 4, hard: 1.2, lair: {
				boss: "ossarion", intro: "Ossarion is bound to five soulfire candles. Snuff them all, and keep them snuffed: they relight.",
				shield: {ids: ["soul_candle"], n: 5, where: "boss", r: 8, regrow: 25, text: "The soulfire candles relight! Ossarion is warded again!"}},
				mobs: ["skeleton", "bone_thrall", "lich", "ghost"]},
			{id: "obsidian_quarry", wall: "obsidian", by: "ev_colossus", name: "The Obsidian Quarry", color: 0x9060ff, layout: "cave", floor: 20, accent: 4, tier: 4, hard: 1.2, lair: {
				boss: "quarry_heart", intro: "The Quarry Heart is a colossus of living glass. Break it and it breaks into more of itself."},
				mobs: ["golem", "thunder_golem", "dwarf", "dwarf_king"]},
			{id: "ashen_aerie", wall: "ash", by: "ev_phoenix", name: "The Ashen Aerie", color: 0xff8a20, layout: "islands", hazard: "lava", floor: 27, accent: 7, tier: 4, hard: 1.2, lair: {
				boss: "ignaria", intro: "Ignaria, mother of phoenixes, rises from her own ashes. When she falls, break her egg before it hatches.",
				rebirth: {egg: "ember_egg", t: 10, into: "ignaria_reborn"}},
				mobs: ["imp", "harpy", "gale_harpy", "lesser_demon"]},
			{id: "hexwood", wall: "hexroots", by: "ev_witch", name: "The Hexwood", color: 0x60e040, layout: "maze", dark: true, floor: 22, accent: 29, tier: 4, hard: 1.2, lair: {
				intro: "Mother Hexis's three sisters hold court in the heart of the Hexwood. Each one that dies feeds the others."},
				trio: ["crone_bramble", "crone_bog", "crone_ash"],
				mobs: ["ent", "spider", "green_slime", "crimson_cultist"]},
			{id: "krakens_maw", wall: "coral_deep", by: "ev_kraken", name: "The Kraken's Maw", color: 0x8040c0, layout: "islands", hazard: "water", floor: 23, accent: 0, tier: 4, hard: 1.2, lair: {
				boss: "leviathan", intro: "The Leviathan sleeps beneath its tentacles. Sever them all to drag it up, before they grow back.",
				shield: {ids: ["maw_tentacle"], n: 4, where: "boss", r: 9, regrow: 32, text: "The tentacles grow back! The Leviathan sinks out of reach!"}},
				mobs: ["tide_spawn", "crab", "pirate", "cloud_serpent"]}
		];

		/** The lair a realm boss leaves (its dungeon index), or -1. */
		public static function lairOf(bossId:String):int {
			for each (var th:Object in DUNGEONS) if (th.by == bossId) return Data.dungeonIndex(th.id);
			return -1;
		}

		/** The lair's own monsters, after the usual ones: its objectives and its master. */
		public static function populate(w:World, th:Object, api:Object):void {
			var L:Object = th.lair;
			var last:Object = w.rooms[w.rooms.length - 1];
			w.lair = {woke: !L.waves, wave: 0, regrowT: 0, eggs: [], shielded: false, done: false, pending: !!L.waves, order: [], feedT: 4, ascK: 0};
			if (L.shield) placeShield(w, L.shield, last, th.tier, api);
			if (L.mend) for (var k:int = 0; k < L.mend.n; k++) {
				var a:Number = k * Math.PI * 2 / L.mend.n + 0.4;
				api.spawn(L.mend.id, last.x + 0.5 + Math.cos(a) * L.mend.r, last.y + 0.5 + Math.sin(a) * L.mend.r, th.tier, true);
			}
			if (L.boss && !L.waves) master(w, L.boss, last.x + 0.5, last.y + 0.5, th.tier, api);
		}

		private static function placeShield(w:World, sh:Object, last:Object, zone:int, api:Object, n:int = 0):void {
			var rooms:Array = w.rooms;
			for (var k:int = 0; k < (n || sh.n); k++) {
				var x:Number, y:Number;
				if (sh.where == "rooms") {
					// spread through the middle rooms, never in the first or the last
					var rm:Object = rooms[Math.max(1, Math.min(rooms.length - 2, Math.round((k + 1) * (rooms.length - 1) / (sh.n + 1))))];
					x = rm.x + 0.5; y = rm.y + 0.5;
				} else {
					var a:Number = k * Math.PI * 2 / sh.n + 0.2;
					x = last.x + 0.5 + Math.cos(a) * sh.r; y = last.y + 0.5 + Math.sin(a) * sh.r;
				}
				var e:Enemy = api.spawn(sh.ids[k % sh.ids.length], x, y, zone, true);
				if (e) { e.lairShield = true; if (sh.order) w.lair.order.push(e); }
			}
		}

		/** n of the ids out in the dungeon's rooms (not the first or the master's own), each in a different one. */
		private static function placeAbroad(w:World, ids:Array, n:int, zone:int, api:Object):void {
			var rooms:Array = w.rooms.slice(1, w.rooms.length - 1);
			for (var k:int = 0; k < n && rooms.length; k++) {
				var rm:Object = rooms.splice(int(Math.random() * rooms.length), 1)[0];
				var e:Enemy = api.spawn(ids[k % ids.length], rm.x + 0.5, rm.y + 0.5, zone, true);
				if (e) e.lairShield = true;
			}
		}

		private static function master(w:World, id:String, x:Number, y:Number, zone:int, api:Object):Enemy {
			var e:Enemy = api.spawn(id, x, y, zone, true);
			if (e) w.boss = e;
			return e;
		}

		/** Whether a lair still has a master to beat (or one about to come). */
		public static function cleared(w:World):Boolean {
			var st:Object = w.lair;
			if (!st || st.pending) return false;
			for each (var egg:Enemy in st.eggs) if (!egg.dead) return false;
			var L:Object = w.theme && w.theme.lair;
			for each (var e:Enemy in w.enemies) if (!e.dead && (e.def.lairBoss || e.def.trio || (L && e.defId == L.boss))) return false;
			return true;
		}

		/** Every tick, where the lair's monsters run. */
		public static function update(w:World, dt:Number, api:Object):void {
			var th:Object = w.theme, L:Object = th && th.lair, st:Object = w.lair;
			if (!L || !st || st.done) return;
			var last:Object = w.rooms[w.rooms.length - 1];
			var e:Enemy;
			// waves: when someone steps into the master's hall
			if (!st.woke) {
				for each (var p:Object in api.players) {
					if (Math.abs(p.x - last.x) < last.w / 2 && Math.abs(p.y - last.y) < last.h / 2) { st.woke = true; break; }
				}
				if (!st.woke) return;
				api.say(th.name + " stirs! Hold the den!", th.color, true);
				st.waveT = 1;
			}
			if (L.waves && st.pending) {
				var alive:int = 0;
				for each (e in w.enemies) if (!e.dead && e.lairWave) alive++;
				if (alive == 0) {
					st.waveT -= dt;
					if (st.waveT > 0) return;
					if (st.wave >= L.waves.n) {
						st.pending = false;
						var b:Enemy = master(w, L.boss, last.x + 0.5, last.y + 0.5, th.tier, api);
						if (b) api.say(b.def.name + " comes for you!", th.color, true);
					} else {
						st.wave++;
						for (var k:int = 0; k < L.waves.size + st.wave; k++) {
							var a:Number = Math.random() * Math.PI * 2, rr:Number = 4 + Math.random() * 6;
							var m:Enemy = api.spawn(L.waves.mobs[int(Math.random() * L.waves.mobs.length)], last.x + 0.5 + Math.cos(a) * rr, last.y + 0.5 + Math.sin(a) * rr, th.tier, false);
							if (m) m.lairWave = true;
						}
						api.say("Wave " + st.wave + " of " + L.waves.n + "!", th.color, false);
						st.waveT = 2.5;
					}
				}
			}
			var boss:Enemy = w.boss && !w.boss.dead ? w.boss : null;
			// rising out of reach: at each mark of its health it goes up, and what drags it down appears abroad
			if (L.ascend && boss && !st.shielded && st.ascK < L.ascend.at.length && boss.hp <= boss.maxHp * L.ascend.at[st.ascK]) {
				boss.hp = boss.maxHp * L.ascend.at[st.ascK];
				st.ascK++;
				placeAbroad(w, L.ascend.ids, L.ascend.n, th.tier, api);
				api.say(L.ascend.text, th.color, true);
			}
			// shields: its master can't be hurt while one stands (and round its throne they grow back)
			if ((L.shield || L.ascend) && boss) {
				var up:int = 0;
				for each (e in w.enemies) if (!e.dead && (e.lairShield || e.def.lairShield)) up++;
				if (up > 0 && !st.shielded) { st.shielded = true; boss.invuln = true; }
				else if (up == 0 && st.shielded) {
					st.shielded = false; boss.invuln = false; st.regrowT = 0;
					api.say(boss.def.name + " is vulnerable!", th.color, true);
				}
				// in turn: only the first one still standing can be hurt (and only it fights)
				if (st.order.length) {
					var lit:Boolean = false;
					for each (e in st.order) {
						if (e.dead) continue;
						e.invuln = lit;
						e.rateMult = lit ? 0 : 1;
						lit = true;
					}
				}
				if (up == 0 && L.shield && L.shield.regrow) {
					st.regrowT += dt;
					if (st.regrowT >= L.shield.regrow) {
						st.regrowT = 0;
						// (only half of them come back: the master can be worn down window by window)
						placeShield(w, L.shield, last, th.tier, api, Math.max(2, Math.ceil(L.shield.n / 2)));
						api.say(L.shield.text, th.color, true);
					}
				}
			}
			// feeders: they drift in from the edge of its hall and heal it if they reach it
			if (L.feed && boss) {
				var near:Boolean = false;
				for each (p in api.players) if (Math.abs(p.x - last.x) < last.w / 2 + 2 && Math.abs(p.y - last.y) < last.h / 2 + 2) { near = true; break; }
				if (near) st.feedT -= dt;
				if (st.feedT <= 0) {
					st.feedT = L.feed.every;
					for (var fk:int = 0; fk < L.feed.n; fk++) {
						var fa:Number = Math.random() * Math.PI * 2, fr:Number = Math.min(last.w, last.h) / 2 - 1.5;
						var f:Enemy = api.spawn(L.feed.id, boss.x + Math.cos(fa) * fr, boss.y + Math.sin(fa) * fr, th.tier, true);
						if (f) f.lairFeed = true;
					}
				}
				for each (e in w.enemies) {
					if (e.dead || !e.lairFeed) continue;
					var fdx:Number = boss.x - e.x, fdy:Number = boss.y - e.y, fd:Number = Math.sqrt(fdx * fdx + fdy * fdy);
					if (fd < 1.4) {
						boss.hp = Math.min(boss.maxHp, boss.hp + boss.maxHp * L.feed.heal);
						api.remove(e);
						api.say(L.feed.text, th.color, false);
						continue;
					}
					e.x += fdx / fd * L.feed.speed * dt;
					e.y += fdy / fd * L.feed.speed * dt;
				}
			}
			// menders: they pour health into it while they stand
			if (L.mend && boss && boss.hp < boss.maxHp) {
				var n:int = 0;
				for each (e in w.enemies) if (!e.dead && e.defId == L.mend.id) n++;
				if (n > 0) boss.hp = Math.min(boss.maxHp, boss.hp + boss.maxHp * L.mend.rate * n * dt);
			}
			// eggs: break them in time, or what fell rises again
			for (var i:int = st.eggs.length - 1; i >= 0; i--) {
				var egg:Enemy = st.eggs[i];
				if (egg.dead) { st.eggs.splice(i, 1); continue; }
				egg.eggT -= dt;
				if (egg.eggT <= 0) {
					st.eggs.splice(i, 1);
					api.remove(egg);
					var reborn:Enemy = master(w, L.rebirth.into, egg.x, egg.y, th.tier, api);
					if (reborn) api.say(reborn.def.name + " rises from the ashes!", th.color, true);
				}
			}
		}

		/** One of the lair's monsters died (call before deciding whether the lair is cleared). */
		public static function killed(w:World, e:Enemy, api:Object):void {
			var th:Object = w.theme, L:Object = th && th.lair, st:Object = w.lair;
			if (!L || !st) return;
			if (L.shield && e.lairShield && L.shield.text && !L.shield.regrow) api.say(L.shield.text, th.color, false);
			// a piece of a shield in turn: the next one lights, and the master runs hotter
			if (e.lairShield && st.order.length && L.shield.overclock && w.boss && !w.boss.dead) w.boss.rateMult *= 1 + L.shield.overclock;
			var sp:Object = e.def.splitInto;
			if (sp) {
				for (var k:int = 0; k < sp.n; k++) {
					var a:Number = k * Math.PI * 2 / sp.n;
					var piece:Enemy = api.spawn(sp.what, e.x + Math.cos(a) * 2.5, e.y + Math.sin(a) * 2.5, th.tier, true);
					if (piece && k == 0) w.boss = piece;
				}
				api.say(e.def.name + " breaks apart!", th.color, true);
			}
			if (L.rebirth && e.defId == L.boss) {
				if (L.rebirth.egg) {
					var egg:Enemy = api.spawn(L.rebirth.egg, e.x, e.y, th.tier, true);
					if (egg) {
						egg.eggT = L.rebirth.t;
						st.eggs.push(egg);
						api.say("Break the egg before it hatches! (" + L.rebirth.t + "s)", th.color, true);
					}
				} else {
					var r:Enemy = master(w, L.rebirth.into, e.x, e.y, th.tier, api);
					if (r) api.say(e.def.name + " rises again as " + r.def.name + "!", th.color, true);
				}
			}
			if (!st.done && cleared(w)) {
				st.done = true;
				if (!L.quiet) {
					api.say(th.name + " is cleared!", th.color, true);
					api.done(e.x, e.y);
				}
			}
		}
	}
}
