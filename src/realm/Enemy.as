package realm {
	import flash.display.BitmapData;
	import flash.utils.getTimer;

	public class Enemy {
		private static const DEG:Number = Math.PI / 180;
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
		public var facingLeft:Boolean = false;
		/** Bosses can be made immune (the Dark Elder while his crystals stand). */
		public var invuln:Boolean = false;
		/** Damage multiplier (elite dungeon monsters, enraged kings). */
		public var dmgMult:Number = 1;

		private var attacks:Array;
		private var timers:Array;
		private var spins:Array;
		private var phase:int = 0;
		private var dirX:Number = 0, dirY:Number = 0;
		private var moveT:Number = 0;
		private var chargeT:Number = 0;
		private var orbitDir:Number;
		private var blinkT:Number = 2 + Math.random() * 2;

		public function Enemy(id:String, x:Number, y:Number, zone:int) {
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
			setAttacks(isBoss ? def.phases[0] : def.attacks);
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

		public var moving:Boolean = false;

		public function get sprite():BitmapData {
			// bosses play a 2-frame idle animation; in their last phase they pulse red
			var frame:int = isBoss ? int(getTimer() / 320 + homeX) % 2 : 0;
			if (hitT > 0) return Sprites.hit(def.spr, frame, facingLeft);
			if (enraged && int(getTimer() / 140) % 4 == 0) return Sprites.rage(def.spr, frame, facingLeft);
			return Sprites.get(def.spr, frame, facingLeft);
		}

		/** True in a boss's final phase. */
		public function get enraged():Boolean {
			return isBoss && phase == 2;
		}

		public function update(dt:Number, g:Game):void {
			if (hitT > 0) hitT -= dt;
			if (slowT > 0) slowT -= dt;
			var p:Player = g.player;
			var dx:Number = p.x - x, dy:Number = p.y - y;
			var dist:Number = Math.sqrt(dx * dx + dy * dy);
			var aggro:Boolean = dist < (def.aggro || 9) && !g.world.isSafe(p.x, p.y) && p.invisT <= 0;
			facingLeft = aggro ? g.scrX(p.x, p.y) < g.scrX(x, y) : (dirX * g.camCos + dirY * g.camSin) < 0;

			if (stunT > 0) { stunT -= dt; return; }

			if (isBoss) {
				var frac:Number = hp / maxHp;
				var want:int = frac > 0.66 ? 0 : frac > 0.33 ? 1 : 2;
				if (want != phase) {
					phase = want;
					setAttacks(def.phases[phase]);
					g.bossPhase(phase, this);
				}
			}

			var speed:Number = def.spd * (slowT > 0 ? 0.45 : 1);
			var mvx:Number = 0, mvy:Number = 0;
			if (aggro && dist > 0.01) {
				var ux:Number = dx / dist, uy:Number = dy / dist;
				switch (def.ai) {
					case "chase":
						if (dist > def.keep) { mvx = ux; mvy = uy; }
						else { mvx = -uy * orbitDir * 0.5; mvy = ux * orbitDir * 0.5; }
						break;
					case "blink":
						// orbit, but every few seconds teleport to a new spot around the player
						blinkT -= dt;
						if (blinkT <= 0) {
							blinkT = 3 + Math.random() * 2;
							for (var bt:int = 0; bt < 8; bt++) {
								var ba:Number = Math.random() * Math.PI * 2, br:Number = 3 + Math.random() * 3;
								var bx2:Number = p.x + Math.cos(ba) * br, by2:Number = p.y + Math.sin(ba) * br;
								if (g.world.canStand(bx2, by2, 0.4, true)) {
									g.burst(x, y, def.col, 10);
									x = bx2; y = by2;
									g.burst(x, y, def.col, 10);
									break;
								}
							}
						}
					case "orbit":
						var radial:Number = (dist - def.keep) * 0.6;
						if (radial > 1) radial = 1;
						if (radial < -1) radial = -1;
						mvx = -uy * orbitDir + ux * radial;
						mvy = ux * orbitDir + uy * radial;
						break;
					case "charge":
						chargeT -= dt;
						if (chargeT <= 0) chargeT = 2.2;
						if (chargeT < 0.6) { mvx = ux * 3; mvy = uy * 3; }
						break;
					case "boss":
					case "wander":
						wander(dt);
						mvx = dirX * 0.6; mvy = dirY * 0.6;
						break;
				}
			} else {
				wander(dt);
				mvx = dirX * 0.5; mvy = dirY * 0.5;
				// drift back toward home if wandering too far
				var hx:Number = homeX - x, hy:Number = homeY - y;
				if (hx * hx + hy * hy > 64) { mvx = hx * 0.1; mvy = hy * 0.1; }
			}
			if (isBoss) {
				var bx:Number = homeX - x, by:Number = homeY - y;
				if (bx * bx + by * by > 25) { mvx = bx * 0.2; mvy = by * 0.2; }
			}
			if (def.ai == "still") { mvx = 0; mvy = 0; }
			move(mvx * speed * dt, mvy * speed * dt, g.world);

			if (aggro && dist < (def.range || 10)) {
				var ang:Number = Math.atan2(dy, dx);
				for (var i:int = 0; i < attacks.length; i++) {
					timers[i] -= dt;
					if (timers[i] <= 0) {
						timers[i] += attacks[i].cd;
						fire(i, ang, g);
					}
				}
			}
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
			moving = mx * mx + my * my > 0.000001;
			var nx:Number = x + mx, ny:Number = y + my;
			var rr:Number = Math.min(r, 0.4);
			if (w.canStand(nx, y, rr, true)) x = nx; else { dirX = -dirX; orbitDir = -orbitDir; }
			if (w.canStand(x, ny, rr, true)) y = ny; else { dirY = -dirY; }
		}

		private function fire(i:int, ang:Number, g:Game):void {
			var a:Object = attacks[i];
			var n:int = a.n;
			var k:int;
			if (a.p == "summon") {
				for (k = 0; k < n; k++) g.spawnEnemy(a.what, x + Math.random() * 2 - 1, y + Math.random() * 2 - 1, zone);
				return;
			}
			var shape:String = a.shape || (a.p == "aimed" ? "dart" : a.p == "spiral" ? "star" : "orb");
			var bd:Vector.<BitmapData> = Sprites.projectile(shape, a.col, a.r <= 0.15 ? 3 : a.r <= 0.2 ? 4 : 5);
			var spin:Boolean = shape == "star";
			var t:Number;
			if (a.p == "aimed") {
				for (k = 0; k < n; k++) {
					t = n > 1 ? ang + (k / (n - 1) - 0.5) * a.arc * DEG : ang;
					g.addShot(new Projectile(x, y, t, a.spd, a.life, int(a.dmg * dmgMult), true, a.r, bd, false, def.name, a.eff || null, spin));
				}
			} else { // ring / spiral
				for (k = 0; k < n; k++) {
					t = spins[i] + k * Math.PI * 2 / n;
					g.addShot(new Projectile(x, y, t, a.spd, a.life, int(a.dmg * dmgMult), true, a.r, bd, false, def.name, a.eff || null, spin));
				}
				spins[i] += (a.rot || 0) * DEG;
			}
		}
	}
}
