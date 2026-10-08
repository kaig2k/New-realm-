package realm {
	import flash.utils.getTimer;
	/**
	 * Shared monsters online. The server makes one player in each realm or
	 * dungeon its "host": the host's game runs the monsters (AI, attacks, spawns,
	 * events) and streams them to everyone else in that world, who see remote
	 * copies. Everyone dodges bullets and gets loot in their own game, so
	 * nothing waits on the network when you're hit. If the host leaves, the
	 * server picks another player, whose game takes over the monsters.
	 *
	 * Offline (or in the Nexus) this does nothing and your game runs everything.
	 */
	public class WorldSync {
		private static const SNAP_TIME:Number = 0.1;
		private static const SNAP_RANGE:Number = 24;

		private var g:Game;
		/** Key of the world this game is host of (online). */
		public var hostKey:String = null;
		private var snapT:Number = 0;
		private var counter:int = 0;

		public function WorldSync(g:Game) {
			this.g = g;
		}

		public function get active():Boolean { return g.net != null && g.net.online; }

		/** Does this game run the monsters here? Always true offline. */
		public function get isHost():Boolean { return !active || hostKey == g.world.key; }

		private function send(to:*, d:Object):void { g.net.sendWorld(to, d); }

		/** As the host: tell everyone an arena phase is coming (warn seconds) or happens now (go). */
		public function arenaPhase(e:Enemy, k:int, warn:Number, go:Boolean):void {
			if (active && isHost && e.id) send("all", go ? {t: "sphase", id: e.id, k: k, go: 1} : {t: "sphase", id: e.id, k: k, w: warn});
		}

		private function newId():int {
			// unique across hosts: the player's server id in the high digits
			counter = (counter + 1) % 100000;
			return (g.net.myId % 20000) * 100000 + counter;
		}

		private static function r2(v:Number):Number { return Math.round(v * 100) / 100; }

		private function flags(e:Enemy):int {
			return (e.immune ? 1 : 0) | (e.stunT > 0 ? 2 : 0) | (e.phaseCode << 2);
		}

		private function entry(e:Enemy, w:World):Array {
			return [e.id, e.defId, r2(e.x), r2(e.y), e.zone, int(e.hp), int(e.maxHp), r2(e.dmgMult), flags(e), w.boss == e ? 1 : 0, r2(e.homeX), r2(e.homeY), e.elite, e.spMask];
		}

		// ------------------------------------------------------------ host side
		public function update(dt:Number):void {
			if (!active || !isHost) return;
			var w:World = g.world;
			if (w.key == "nexus") return;
			var fresh:Array = [];
			for each (var e:Enemy in w.enemies) {
				if (e.id || e.dead) continue;
				e.id = newId();
				w.eById[e.id] = e;
				fresh.push(entry(e, w));
			}
			var others:Vector.<RemotePlayer> = g.net.players;
			if (fresh.length && others.length) send("all", {t: "espawn", l: fresh, n: 1});
			snapT -= dt;
			if (snapT > 0 || !others.length) return;
			snapT = SNAP_TIME;
			var flat:Array = [];
			for each (e in w.enemies) {
				if (e.dead || !e.id) continue;
				var near:Boolean = false;
				for each (var rp:RemotePlayer in others) {
					var dx:Number = rp.x - e.x, dy:Number = rp.y - e.y;
					if (dx * dx + dy * dy < SNAP_RANGE * SNAP_RANGE || e.isBoss) { near = true; break; }
				}
				if (near) flat.push(e.id, int(e.x * 100), int(e.y * 100), Math.ceil(Math.max(0, e.hp)), flags(e));
			}
			if (flat.length) send("all", {t: "esnap", l: flat});
		}

		/** The host's monster fired: everyone replays the same attack. */
		public function fired(e:Enemy, i:int, ang:Number, spin:Number, code:int, dist:Number):void {
			if (!active || !isHost || !e.id || !g.net.players.length) return;
			send("all", {t: "efire", id: e.id, i: i, a: Math.round(ang * 1000) / 1000, s: Math.round(spin * 1000) / 1000, p: code, d: Math.round(dist * 10) / 10});
		}

		public function killed(e:Enemy):void {
			if (active && isHost && e.id) send("all", {t: "ekill", id: e.id});
		}

		/** A monster vanished without dying (wandered too far from everyone). */
		public function removed(e:Enemy):void {
			if (e.id) delete g.world.eById[e.id];
			if (active && isHost && e.id && !e.dead) send("all", {t: "edel", id: e.id});
		}

		/** Host: a boss's health grew for more players. */
		public function rescaled(e:Enemy):void {
			if (active && isHost && e.id) send("all", {t: "emax", id: e.id, m: int(e.maxHp), h: int(e.hp), n: e.scalePlayers});
		}

		/** You hit a remote copy: tell the host (it decides when the monster dies). */
		public function hit(e:Enemy, dmg:int, slow:Number, stun:Number):void {
			if (!active || !e.remote || !e.id) return;
			e.ownHitAt = getTimer();
			send("host", {t: "ehit", id: e.id, d: dmg, sl: slow, st: stun});
		}

		/** A dungeon portal appeared (only the host rolls drops). */
		public function portal(p:Object):void {
			if (!active || !isHost) return;
			send("all", {t: "portal", x: r2(p.x), y: r2(p.y), k: p.kind, i: p.idx, c: p.color, l: p.life, s: p.seed});
		}

		// ------------------------------------------------------------ world changes
		/** The server answered our "enter": are we the host of this world? */
		public function entered(key:String, amHost:Boolean):void {
			var w:World = g.world;
			if (key != w.key || key == "nexus") return;
			if (amHost) {
				hostKey = key;
				for each (var e:Enemy in w.enemies) if (e.remote) e.takeOver();
				if (w.pendingPopulate != null) {
					var fn:Function = w.pendingPopulate;
					w.pendingPopulate = null;
					fn();
				}
			} else {
				hostKey = null;
				// the host's monsters replace whatever this game had here
				w.enemies.length = 0;
				w.eById = {};
				w.boss = null;
				w.pendingPopulate = null;
				send("host", {t: "sync"});
			}
		}

		/** The server moved this world's host (the old one left). */
		public function hostChanged(key:String, amHost:Boolean):void {
			if (key != g.world.key) return;
			if (amHost) {
				hostKey = key;
				for each (var e:Enemy in g.world.enemies) if (e.remote) e.takeOver();
				g.msg("You're now running the monsters in this area.", 0x9a9aaa);
			} else if (hostKey == key) {
				hostKey = null;
			}
		}

		// ------------------------------------------------------------ messages
		public function handle(from:int, d:Object):void {
			var w:World = g.world;
			var e:Enemy;
			var i:int;
			switch (d.t) {
				case "espawn":
					if (isHost) return;
					for each (var en:Array in d.l) {
						if (w.eById[en[0]] || !Data.ENEMIES[en[1]]) continue;
						e = new Enemy(en[1], en[2], en[3], en[4]);
						e.id = en[0];
						e.remote = true;
						e.hp = en[5];
						e.maxHp = en[6];
						e.dmgMult = en[7];
						e.invuln = (en[8] & 1) != 0;
						e.setPhase(en[8] >> 2, null);
						e.homeX = en[10]; e.homeY = en[11];
						if (en[12]) e.elite = en[12];
						if (en[13]) e.spMask = en[13];
						e.tx = e.x; e.ty = e.y;
						w.eById[e.id] = e;
						w.enemies.push(e);
						if (en[9]) {
							w.boss = e;
							if (d.n && w.kind == "realm") g.eventAppeared(e);
						}
					}
					break;
				case "esnap":
					if (isHost) return;
					var l:Array = d.l;
					for (i = 0; i + 4 < l.length; i += 5) {
						e = w.eById[l[i]];
						if (!e || e.dead) continue;
						e.netTarget(l[i + 1] / 100, l[i + 2] / 100);
						// the host's health is the truth; only right after our own hit keep the lower
						// guess until it catches up (monsters can heal, and hits can be refused)
						e.hp = getTimer() - e.ownHitAt < 600 ? Math.min(e.hp, l[i + 3]) : l[i + 3];
						e.invuln = (l[i + 4] & 1) != 0;
						if (l[i + 4] & 2) e.stunT = Math.max(e.stunT, 0.15);
						e.setPhase(l[i + 4] >> 2, g);
					}
					break;
				case "emax":
					e = w.eById[d.id];
					if (e && e.remote) { e.maxHp = d.m; e.hp = d.h; e.scalePlayers = d.n; }
					break;
				case "efire":
					e = w.eById[d.id];
					if (e && e.remote && !e.dead) e.remoteFire(d.i, d.a, d.s, d.p, d.d || 0, g);
					break;
				case "ekill":
					e = w.eById[d.id];
					if (e && !e.dead) g.remoteKill(e);
					break;
				case "sphase":
					// the event boss's arena is about to change (w: seconds of warning) or changes now (go)
					if (isHost) return;
					e = w.eById[d.id];
					if (e && !e.dead) g.arenaPhase(e, d.k, d.go ? 0 : d.w, !!d.go);
					break;
				case "edel":
					e = w.eById[d.id];
					if (e) { delete w.eById[d.id]; g.dropEnemy(e); }
					break;
				case "ehit":
					if (!isHost) return;
					e = w.eById[d.id];
					if (!e || e.dead || e.remote) return;
					if (d.sl) e.slowT = Math.max(e.slowT, d.sl);
					if (d.st) e.stunT = Math.max(e.stunT, e.isBoss ? d.st * 0.4 : d.st);
					if (d.d > 0 && !e.immune) {
						e.hp -= d.d;
						e.hitT = 0.08;
						if (e.hp < 1) g.hostKill(e);
					}
					break;
				case "sync":
					if (!isHost) return;
					var all:Array = [];
					for each (e in w.enemies) if (!e.dead && e.id) all.push(entry(e, w));
					send(from, {t: "espawn", l: all, n: 0});
					send(from, {t: "wstate", ev: w.eventsDone, ct: r2(w.closeT), rs: w.raidStage});
					break;
				case "rstage":
					if (isHost || !w.raid) return;
					g.raidStageReached(d.n);
					break;
				case "wstate":
					if (isHost) return;
					w.eventsDone = d.ev;
					if (d.rs != undefined && w.raid && d.rs >= 0) g.raidStageReached(Math.min(d.rs, w.raid.stages.length - 1));
					if (d.ct > 0 && w.closeT <= 0) w.closeT = d.ct;
					break;
				case "loot":
					// the server rolled your drops from a monster you helped kill
					if (!isHost && d.l is Array) g.serverDrop(Number(d.x), Number(d.y), d.l, String(d.n || ""), String(d.hs || ""));
					break;
				case "portal":
					if (isHost && d.k != "raid") return;
					g.netPortal(d.x, d.y, d.k, d.i, d.c, d.l, uint(d.s));
					break;
			}
		}
	}
}
