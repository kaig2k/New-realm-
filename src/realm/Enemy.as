package realm {
	import flash.display.BitmapData;
	import flash.utils.getTimer;

	/**
	 * A monster or boss.
	 *
	 * Bosses run a phase script (def.phases). Each phase is either a plain list
	 * of attacks (old style: phases at 66% and 33% health) or an object:
	 *   {hp: 0.6,            enter at or below this fraction of health
	 *    say: "...",         the boss speaks when the phase starts
	 *    banner: "...",      big on-screen text
	 *    shield: 2.5,        seconds of invulnerability while it powers up
	 *    move: "wander" | "still" | "chase" | "orbit" | "charge" | "teleport" | "center",
	 *    speed: 1.5,         movement speed multiplier
	 *    summon: [{what, n}] minions on entering the phase
	 *    attacks: [...]      or cycle: [[...], [...]] with every: seconds
	 *   }
	 * Attack patterns (p): aimed, ring, spiral, flower, wall, nova, rain, summon;
	 * extras: waves + gap (repeat), motion ("wave", "return", "accel", "home"),
	 * split {n, spd, life, dmg} (bursts into a ring when it expires).
	 */
	public class Enemy {
		private static const DEG:Number = Math.PI / 180;
		private static const LEGACY_HP:Array = [1, 0.66, 0.33];
		/** Sprites that hover instead of walking. */
		private static const FLYERS:Array = ["ghost", "ghost_god", "sprite", "sprite_god", "harpy", "djinn", "gazer", "beholder",
			"lich", "shade", "mothling", "cubelet", "crystal"];

		public var def:Object;
		public var x:Number, y:Number;
		public var homeX:Number, homeY:Number;
		public var hp:Number, maxHp:Number;
		public var defense:int;
		public var r:Number;
		public var zone:int;
		public var dead:Boolean = false;
		public var isBoss:Boolean;
		public var stunT:Number = 0, slowT:Number = 0, hitT:Number = 0;
		/** Fan of Knives poison (time left, next tick, damage per tick) and War Cry vulnerability. */
		public var poisonT:Number = 0, poisonTick:Number = 0, poisonDmg:int = 0, vulnT:Number = 0;
		public var facingLeft:Boolean = false;
		/** A realm event boss's set-piece pieces (wards, menders, hazards), set by whoever runs it. */
		public var props:Array;
		/** Set-piece phases started (bit k = phase k), sent to players so late arrivals see the arena as it is. */
		public var spMask:int = 0;
		/** Bosses can be made immune (the Dark Elder while his crystals stand). */
		public var invuln:Boolean = false;
		/** Phase-change shield (seconds). */
		public var shieldT:Number = 0;
		/** Damage multiplier (elite dungeon monsters, enraged kings). */
		public var dmgMult:Number = 1;
		/** You hit it at least once (you only get loot from monsters you fought). */
		public var playerHit:Boolean = false;
		/** Network id (online: shared by every player in the world). */
		public var id:int = 0;
		/**
		 * Online, one player's game (the world host) runs the monsters. Everyone
		 * else gets "remote" copies that just follow the host's updates.
		 */
		public var remote:Boolean = false;
		/** When this game last hit this (remote) monster, for matching the host's health. */
		public var ownHitAt:int = -100000;
		public var tx:Number, ty:Number;
		/** Remote copies: the host's speed between position updates (so they glide, not stop-start). */
		private var netVx:Number = 0, netVy:Number = 0, netAt:int = 0, netAge:Number = 0;
		/** Current velocity: monsters speed up and turn smoothly instead of snapping. */
		private var velX:Number = 0, velY:Number = 0;
		/** Walk cycle, advanced by distance moved (drives the stepping bob). */
		public var stride:Number = 0;
		/** Key into Data.ENEMIES. */
		public var defId:String;
		/** Endgame bosses get more health per player fighting them. */
		public var scaleMult:Number = 1;
		public var scalePlayers:Number = 1;
		public var moving:Boolean = false;
		/** Elite affix ("Swift", "Armored"...; "" for ordinary monsters). */
		public var elite:String = "";
		/** Speed multiplier (Swift and Frenzied elites). */
		public var spdMult:Number = 1;
		/** How much faster than usual it attacks (the Vault's weekly twist). */
		public var rateMult:Number = 1;
		/** The realm landmark this monster guards (host only), or null. */
		public var site:Object;
		/** Seconds alive (treasure goblins escape after a while). */
		public var age:Number = 0;
		/** You've had the boss's entrance (name banner, roar) for this one. */
		public var introduced:Boolean = false;

		private var attacks:Array;
		private var timers:Array;
		private var spins:Array;
		/** Normalised phase objects (bosses). */
		private var phases:Array;
		private var phase:int = 0;
		private var phaseT:Number = 0;
		private var cycleK:int = 0;
		private var dirX:Number = 0, dirY:Number = 0;
		private var moveT:Number = 0;
		private var chargeT:Number = 0;
		private var orbitDir:Number;
		private var orbitA:Number = 0;
		private var blinkT:Number = 2 + Math.random() * 2;

		public function Enemy(id:String, x:Number, y:Number, zone:int) {
			defId = id;
			def = Data.ENEMIES[id];
			this.x = homeX = x;
			this.y = homeY = y;
			this.zone = zone;
			hp = maxHp = def.hp;
			defense = def.def;
			r = def.r || 0.4;
			isBoss = def.ai == "boss";
			if (def.fly == undefined) def.fly = FLYERS.indexOf(def.spr) >= 0;
			orbitDir = Math.random() < 0.5 ? 1 : -1;
			orbitA = Math.random() * Math.PI * 2;
			if (isBoss) {
				phases = normalise(def.phases);
				setAttacks(listFor(0, 0));
			} else setAttacks(def.attacks);
		}

		/** Old-style phase arrays become phase objects at 100% / 66% / 33%. */
		private static function normalise(list:Array):Array {
			if (list.normalised) return list.normalised;
			var out:Array = [];
			for (var i:int = 0; i < list.length; i++) {
				var p:Object = list[i];
				if (p is Array) p = {hp: LEGACY_HP[Math.min(i, 2)], attacks: p};
				if (p.hp == undefined) p.hp = i == 0 ? 1 : 1 - i / list.length;
				out.push(p);
			}
			list.normalised = out;
			return out;
		}

		private function listFor(ph:int, k:int):Array {
			var p:Object = phases[ph];
			if (!p) return [];
			if (p.cycle) return p.cycle[k % p.cycle.length];
			return p.attacks || [];
		}

		private function setAttacks(list:Array):void {
			attacks = list;
			timers = [];
			spins = [];
			for (var i:int = 0; i < list.length; i++) {
				timers.push(0.5 + Math.random() * list[i].cd);
				spins.push(Math.random() * Math.PI * 2);
			}
		}

		/** When it last attacked (ms, getTimer): its attack animation plays for a moment after. */
		public var lastAttack:int = -100000;

		public function get sprite():BitmapData {
			// idle breathing, a stepping walk, or the wind-up and strike of an attack (in its last phase a boss pulses red)
			var now:int = getTimer(), since:int = now - lastAttack, off:int = id * 37;
			var frame:int = since < 380 ? Sprites.anim(Sprites.ATTACK, since < 160 ? 0 : 1)
				: moving ? Sprites.anim(Sprites.MOVE, int((now + off) / (def.spd > 2.5 ? 130 : 190)) % 2)
				: Sprites.anim(Sprites.IDLE, int((now + off) / (isBoss ? 340 : 460)) % 2);
			if (hitT > 0) return Sprites.hit(def.spr, frame, facingLeft);
			if (enraged && int(getTimer() / 140) % 4 == 0) return Sprites.rage(def.spr, frame, facingLeft);
			return Sprites.get(def.spr, frame, facingLeft);
		}

		/** True in a boss's final phase. */
		public function get enraged():Boolean {
			return isBoss && phases && phase == phases.length - 1 && phases.length > 1;
		}

		/** Can't be damaged right now. */
		public function get immune():Boolean { return invuln || shieldT > 0; }

		public function get phaseIndex():int { return phase; }
		public function get phaseCount():int { return phases ? phases.length : 1; }
		/** Phase and attack cycle packed together (for the network). */
		public function get phaseCode():int { return phase + cycleK * 16; }

		public function update(dt:Number, g:Game):void {
			if (hitT > 0) hitT -= dt;
			if (slowT > 0) slowT -= dt;
			if (shieldT > 0) shieldT -= dt;
			if (remote) { follow(dt, g); return; }
			if (props) {
				// its arena: wards keep it immune, menders heal it
				var wards:int = 0, mend:Number = 0;
				for each (var pr:Enemy in props) {
					if (pr.dead) continue;
					if (pr.def.ward) wards++;
					if (pr.def.mend) mend += pr.def.mend;
				}
				if (def.setpiece && def.setpiece.ward) invuln = wards > 0;
				if (mend > 0 && hp > 0 && hp < maxHp) hp = Math.min(maxHp, hp + maxHp * mend * dt);
			}
			// the nearest player it can see (online that includes other players)
			var p:Object = g.aggroTarget(this);
			var dx:Number = p ? p.x - x : 0, dy:Number = p ? p.y - y : 0;
			var dist:Number = p ? Math.sqrt(dx * dx + dy * dy) : 999;
			var aggro:Boolean = p != null && dist < (def.aggro || 9);
			// turn to face only on a clear left/right difference, so it doesn't flicker when you're above or below
			var side:Number = aggro ? (g.scrX(p.x, p.y) - g.scrX(x, y)) / Game.TS : (velX * g.camCos + velY * g.camSin) * 4;
			if (side < -0.3) facingLeft = true;
			else if (side > 0.3) facingLeft = false;

			if (stunT > 0) { stunT -= dt; return; }

			var ph:Object = null;
			if (isBoss) {
				var frac:Number = hp / maxHp;
				var want:int = 0;
				for (var pi:int = 0; pi < phases.length; pi++) if (frac <= phases[pi].hp) want = pi;
				if (want > phase) enterPhase(want, g);
				ph = phases[phase];
				phaseT += dt;
				if (ph.cycle) {
					var k:int = int(phaseT / (ph.every || 6)) % ph.cycle.length;
					if (k != cycleK) { cycleK = k; setAttacks(ph.cycle[k]); }
				}
			}

			var speed:Number = def.spd * spdMult * (slowT > 0 ? 0.45 : 1) * (!def.fly && g.world.inWater(x, y) ? 0.5 : 1) * (ph && ph.speed ? ph.speed : 1);
			var mvx:Number = 0, mvy:Number = 0;
			var mode:String = ph ? (ph.move || "wander") : def.ai;
			if (aggro && dist > 0.01) {
				var ux:Number = dx / dist, uy:Number = dy / dist;
				switch (mode) {
					case "chase":
						if (dist > (def.keep || 2.5)) { mvx = ux; mvy = uy; }
						else { mvx = -uy * orbitDir * 0.5; mvy = ux * orbitDir * 0.5; }
						break;
					case "blink":
					case "teleport":
						// every few seconds vanish and reappear somewhere else
						blinkT -= dt;
						if (blinkT <= 0) {
							blinkT = mode == "teleport" ? 3.5 + Math.random() * 1.5 : 3 + Math.random() * 2;
							for (var bt:int = 0; bt < 10; bt++) {
								var ba:Number = Math.random() * Math.PI * 2, br:Number = 3 + Math.random() * 4;
								var cxp:Number = isBoss ? homeX : p.x, cyp:Number = isBoss ? homeY : p.y;
								var bx2:Number = cxp + Math.cos(ba) * br, by2:Number = cyp + Math.sin(ba) * br;
								if (g.world.canStand(bx2, by2, 0.4, true)) {
									g.burst(x, y, def.col, 14);
									x = bx2; y = by2;
									g.burst(x, y, def.col, 14);
									break;
								}
							}
						}
						if (mode == "teleport") break;
					case "orbit":
						if (isBoss) {
							// circle the arena centre
							orbitA += dt * 0.6 * orbitDir;
							var ox:Number = homeX + Math.cos(orbitA) * 4.5 - x, oy:Number = homeY + Math.sin(orbitA) * 4.5 - y;
							var od:Number = Math.sqrt(ox * ox + oy * oy) || 1;
							mvx = ox / od * Math.min(1, od); mvy = oy / od * Math.min(1, od);
							break;
						}
						var radial:Number = (dist - def.keep) * 0.6;
						if (radial > 1) radial = 1;
						if (radial < -1) radial = -1;
						mvx = -uy * orbitDir + ux * radial;
						mvy = ux * orbitDir + uy * radial;
						break;
					case "flee":
						// run from the nearest player, veering sideways so walls don't trap it
						mvx = -ux + -uy * orbitDir * 0.6; mvy = -uy + ux * orbitDir * 0.6;
						moveT -= dt;
						if (moveT <= 0) { moveT = 1 + Math.random(); if (Math.random() < 0.4) orbitDir = -orbitDir; }
						break;
					case "charge":
						chargeT -= dt;
						if (chargeT <= 0) chargeT = isBoss ? 3 : 2.2;
						if (chargeT < 0.6) { mvx = ux * 3; mvy = uy * 3; }
						break;
					case "center":
						mvx = (homeX - x) * 0.5; mvy = (homeY - y) * 0.5;
						break;
					case "still":
						break;
					default: // boss / wander
						wander(dt);
						mvx = dirX * 0.6; mvy = dirY * 0.6;
						break;
				}
			} else if (!isBoss || mode != "still") {
				wander(dt);
				mvx = dirX * 0.5; mvy = dirY * 0.5;
				// drift back toward home if wandering too far
				var hx:Number = homeX - x, hy:Number = homeY - y;
				if (hx * hx + hy * hy > 64) { mvx = hx * 0.1; mvy = hy * 0.1; }
			}
			if (isBoss) {
				var leash:Number = mode == "chase" || mode == "charge" ? 64 : 25;
				var bx:Number = homeX - x, by:Number = homeY - y;
				if (bx * bx + by * by > leash) { mvx = bx * 0.2; mvy = by * 0.2; }
			}
			if (def.ai == "still" || (isBoss && shieldT > 0 && mode != "orbit")) { mvx = 0; mvy = 0; }
			// ease toward the wanted velocity (charges lunge, everything else turns smoothly)
			var accel:Number = Math.min(1, dt * (mode == "charge" ? 18 : 7));
			velX += (mvx * speed - velX) * accel;
			velY += (mvy * speed - velY) * accel;
			move(velX * dt, velY * dt, g.world);

			if (aggro && dist < (def.range || 10) && shieldT <= 0) {
				var ang:Number = Math.atan2(dy, dx);
				for (var i:int = 0; i < attacks.length; i++) {
					timers[i] -= dt * rateMult;
					if (timers[i] <= 0) {
						timers[i] += attacks[i].cd;
						fire(i, ang, dist, g);
					}
				}
			}
		}

		/** A new boss phase: speech, a shield while it powers up, minions. */
		private function enterPhase(i:int, g:Game):void {
			phase = i;
			phaseT = 0;
			cycleK = 0;
			var ph:Object = phases[i];
			setAttacks(listFor(i, 0));
			if (ph.shield) shieldT = ph.shield;
			if (ph.summon) for each (var s:Object in ph.summon) {
				for (var k:int = 0; k < (s.n || 1); k++) {
					var a:Number = k * Math.PI * 2 / (s.n || 1);
					g.spawnEnemy(s.what, x + Math.cos(a) * 2.5, y + Math.sin(a) * 2.5, zone);
				}
			}
			g.bossPhase(i, this);
		}

		/** Remote copy: glide toward the host's position. */
		private function follow(dt:Number, g:Game):void {
			if (stunT > 0) stunT -= dt;
			if (isNaN(tx)) { tx = x; ty = y; }
			// keep going the way the host was moving until the next update (at most half a second)
			netAge += dt;
			var ahead:Number = Math.min(netAge, 0.5);
			var px:Number = tx + netVx * ahead, py:Number = ty + netVy * ahead;
			var dx:Number = px - x, dy:Number = py - y;
			var d:Number = Math.sqrt(dx * dx + dy * dy);
			moving = d > 0.02 || netVx * netVx + netVy * netVy > 0.04;
			if (d > 5) { x = px; y = py; }
			else {
				var k:Number = Math.min(1, dt * 8);
				var ox:Number = x, oy:Number = y;
				x += dx * k; y += dy * k;
				stride += Math.sqrt((x - ox) * (x - ox) + (y - oy) * (y - oy)) * 3.2;
				var side:Number = (x - ox) * g.camCos + (y - oy) * g.camSin;
				if (side < -0.004) facingLeft = true;
				else if (side > 0.004) facingLeft = false;
			}
		}

		/** A remote copy takes over (its host left): start thinking for itself. */
		public function takeOver():void {
			remote = false;
			if (isBoss) setAttacks(listFor(phase, cycleK));
		}

		/** Remote copy: show a phase change the host reported (code = phase + cycle * 16). */
		public function setPhase(code:int, g:Game = null):void {
			if (!isBoss) return;
			var ph:int = code & 15, k:int = code >> 4;
			if (!phases[ph]) return;
			if (ph != phase) {
				phase = ph;
				cycleK = k;
				setAttacks(listFor(ph, k));
				if (g) g.bossPhase(ph, this);
			} else if (k != cycleK) {
				cycleK = k;
				setAttacks(listFor(ph, k));
			}
		}

		/** Replays an attack the host's copy just fired (same bullets for everyone). */
		public function remoteFire(i:int, ang:Number, spin:Number, code:int, dist:Number, g:Game):void {
			lastAttack = getTimer();
			var list:Array = isBoss ? listFor(code & 15, code >> 4) : def.attacks;
			if (!list || !list[i]) return;
			shootAttack(list[i], ang, spin, dist, g);
		}

		private function wander(dt:Number):void {
			moveT -= dt;
			if (moveT <= 0) {
				moveT = 1 + Math.random() * 2;
				if (Math.random() < 0.3) { dirX = 0; dirY = 0; }
				else {
					var a:Number = Math.random() * Math.PI * 2;
					dirX = Math.cos(a);
					dirY = Math.sin(a);
				}
			}
		}

		private function move(mx:Number, my:Number, w:World):void {
			var step:Number = Math.sqrt(mx * mx + my * my);
			moving = step > 0.0008;
			stride += step * 3.2;
			var nx:Number = x + mx, ny:Number = y + my;
			var rr:Number = Math.min(r, 0.4);
			if (def.ghostly) {
				// ghosts drift through walls (but still never into the safe haven or off the map)
				if (w.canFloat(nx, y, rr)) x = nx; else { dirX = -dirX; orbitDir = -orbitDir; velX *= -0.3; }
				if (w.canFloat(x, ny, rr)) y = ny; else { dirY = -dirY; velY *= -0.3; }
				return;
			}
			if (w.canStand(nx, y, rr, true)) x = nx; else { dirX = -dirX; orbitDir = -orbitDir; velX *= -0.3; }
			if (w.canStand(x, ny, rr, true)) y = ny; else { dirY = -dirY; velY *= -0.3; }
		}

		/** A position update from the world host for this remote copy. */
		public function netTarget(nx:Number, ny:Number):void {
			var now:int = getTimer();
			if (!isNaN(tx) && netAt > 0) {
				var secs:Number = (now - netAt) / 1000;
				if (secs > 0.02 && secs < 1) {
					// blend, so one late packet doesn't make it lurch
					netVx = netVx * 0.4 + (nx - tx) / secs * 0.6;
					netVy = netVy * 0.4 + (ny - ty) / secs * 0.6;
				}
			}
			netAt = now;
			netAge = 0;
			tx = nx; ty = ny;
		}

		private function fire(i:int, ang:Number, dist:Number, g:Game):void {
			lastAttack = getTimer();
			var a:Object = attacks[i];
			var k:int;
			if (a.p == "summon") {
				var alive:int = g.countAlive(a.what);
				if (alive >= (a.max || 8)) return;
				for (k = 0; k < a.n; k++) g.spawnEnemy(a.what, x + Math.random() * 2 - 1, y + Math.random() * 2 - 1, zone);
				return;
			}
			// patterns that rotate or scatter carry their own seed so every player sees the same bullets
			var spin0:Number = a.p == "rain" || a.p == "wall" ? Math.random() * 1000 : spins[i];
			shootAttack(a, ang, spin0, dist, g);
			if (a.p == "ring" || a.p == "spiral" || a.p == "flower") spins[i] += (a.rot || 0) * DEG;
			g.sync.fired(this, i, ang, spin0, phaseCode, dist);
		}

		/** All bullet patterns. Deterministic given the same arguments (online replay). */
		private function shootAttack(a:Object, ang:Number, spin0:Number, dist:Number, g:Game):void {
			var waves:int = a.waves || 1;
			for (var w:int = 0; w < waves; w++) {
				if (w == 0) shootWave(a, ang, spin0, dist, g, 0);
				else g.later(w * (a.gap || 0.2), waveFn(a, ang, spin0, dist, g, w));
			}
		}

		private function waveFn(a:Object, ang:Number, spin0:Number, dist:Number, g:Game, w:int):Function {
			return function():void { if (!dead) shootWave(a, ang, spin0, dist, g, w); };
		}

		private function shootWave(a:Object, ang:Number, spin0:Number, dist:Number, g:Game, w:int):void {
			var n:int = a.n || 1;
			var k:int, t:Number;
			var shape:String = a.shape || (a.p == "aimed" ? "dart" : a.p == "spiral" ? "star" : "orb");
			var col:uint = a.col;
			var bd:Vector.<BitmapData> = Sprites.projectile(shape, col, a.r <= 0.15 ? 3 : a.r <= 0.2 ? 4 : a.r <= 0.3 ? 5 : 6);
			var spinning:Boolean = shape == "star" || a.spin;
			var dmg:int = int(a.dmg * dmgMult);
			var rot:Number = (a.wrot || 0) * DEG * w;
			switch (a.p) {
				case "aimed":
					for (k = 0; k < n; k++) {
						t = n > 1 ? ang + (k / (n - 1) - 0.5) * a.arc * DEG : ang;
						shot(t + rot, a.spd, a, dmg, bd, spinning, g, x, y, k);
					}
					break;
				case "flower":
					// a ring whose petals alternate fast and slow
					for (k = 0; k < n; k++) {
						t = spin0 + rot + k * Math.PI * 2 / n;
						shot(t, k % 2 == 0 ? a.spd : a.spd * (a.slow || 0.55), a, dmg, bd, spinning, g, x, y, k);
					}
					break;
				case "wall":
					// a line of bullets marching at you, with a gap to slip through
					var gap:int = int(spin0) % n;
					var px:Number = -Math.sin(ang), py:Number = Math.cos(ang);
					var spacing:Number = a.spacing || 0.7;
					for (k = 0; k < n; k++) {
						if (Math.abs(k - gap) <= (a.hole || 1) - 1) continue;
						var off:Number = (k - (n - 1) / 2) * spacing;
						shot(ang, a.spd, a, dmg, bd, spinning, g, x + px * off, y + py * off, k);
					}
					break;
				case "nova":
					// a blast marked on the ground where you stand, then a ring bursts out of it
					var nd:Number = Math.min(dist, a.reach || 9);
					var nx:Number = x + Math.cos(ang) * nd, ny:Number = y + Math.sin(ang) * nd;
					g.addMarker(nx, ny, a.radius || 1.6, a.delay || 1, col, novaFn(a, nx, ny, dmg, bd, spinning, g, spin0));
					break;
				case "rain":
					// several blasts scattered around you
					var seed:uint = uint(spin0 * 1000) | 1;
					var rd:Number = Math.min(dist, a.reach || 9);
					var cx:Number = x + Math.cos(ang) * rd, cy:Number = y + Math.sin(ang) * rd;
					for (k = 0; k < n; k++) {
						seed ^= seed << 13; seed ^= seed >>> 17; seed ^= seed << 5;
						var ra:Number = (seed % 6283) / 1000;
						seed ^= seed << 13; seed ^= seed >>> 17; seed ^= seed << 5;
						var rr:Number = k == 0 ? 0 : 1 + (seed % 1000) / 1000 * (a.spread || 4);
						var mx:Number = cx + Math.cos(ra) * rr, my:Number = cy + Math.sin(ra) * rr;
						g.addMarker(mx, my, a.radius || 1.2, (a.delay || 1) + k * (a.stagger || 0.12), col, novaFn(a, mx, my, dmg, bd, spinning, g, ra));
					}
					break;
				default: // ring / spiral
					for (k = 0; k < n; k++) {
						t = spin0 + rot + k * Math.PI * 2 / n;
						shot(t, a.spd, a, dmg, bd, spinning, g, x, y, k);
					}
			}
		}

		private function novaFn(a:Object, nx:Number, ny:Number, dmg:int, bd:Vector.<BitmapData>, spinning:Boolean, g:Game, base:Number):Function {
			return function():void {
				if (a.web) g.addWeb(nx, ny, a.radius || 1.6, a.web);
				g.areaHit(nx, ny, a.radius || 1.6, dmg, def.name, a.eff || null, a.col, attackName(a));
				var m:int = a.burst || 0;
				for (var k:int = 0; k < m; k++) {
					var t:Number = base + k * Math.PI * 2 / m;
					var bs:Projectile = new Projectile(nx, ny, t, a.bspd || 4, a.blife || 1.5, int(dmg * 0.6), true, 0.2, bd, false, def.name, a.eff || null, spinning);
					bs.attack = "blast shards";
					g.addShot(bs);
				}
			};
		}

		/** A name for an attack, for the death recap: "homing blade volley", "ring of stars", "ground blast". */
		public static function attackName(a:Object):String {
			if (!a) return "";
			if (a.name) return a.name;
			if (a.p == "nova") return "ground blast";
			if (a.p == "rain") return "falling blasts";
			var adj:String = a.motion == "home" ? "homing " : a.motion == "wave" ? "weaving " : a.motion == "boomerang" ? "returning " : a.accel > 0 ? "speeding " : "";
			var thing:String = a.shape == "blade" ? "blade" : a.shape == "star" ? "star" : a.shape == "ring" ? "ring" : "shot";
			if (a.p == "spiral") return adj + thing + " spiral";
			if (a.p == "ring") return "ring of " + adj + thing + "s";
			return adj + thing + ((a.n || 1) > 1 ? " volley" : "");
		}

		private function shot(t:Number, spd:Number, a:Object, dmg:int, bd:Vector.<BitmapData>, spinning:Boolean, g:Game, sx:Number, sy:Number, k:int):void {
			var s:Projectile = new Projectile(sx, sy, t, spd, a.life, dmg, true, a.r, bd, false, def.name, a.eff || null, spinning);
			s.attack = attackName(a);
			if (a.motion) {
				s.motion = a.motion;
				s.accel = a.accel || 0;
				if (k % 2 == 1) s.phase = Math.PI;
			}
			if (a.split) s.split = a.split;
			if (a.ghost) s.passWalls = true;
			g.addShot(s);
		}
	}
}
