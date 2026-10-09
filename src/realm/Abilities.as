package realm {
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;

	/**
	 * Class abilities that outlive the key press (Shield Wall, Sanctuary,
	 * Soul Harvest spirits) and the animations that go with every cast.
	 * Gameplay only runs for your own casts; other players' casts are shown
	 * (a planted Shield Wall blocks bullets for everyone standing behind it).
	 */
	public class Abilities {
		private var g:Game;
		/** Sanctuary circles: {x, y, r, life, tick, dmg, heal}. */
		public var zones:Array = [];
		/** Spirits circling you: {a, life, cd, dmg}. */
		public var spirits:Array = [];
		/** Animations: {k, x, y, t, d, ...}; fn() runs when one finishes. */
		public var fx:Array = [];
		private var sh:Shape = new Shape();
		private var mtx:Matrix = new Matrix();
		private var pt:Point = new Point();

		/** Rallying Banners (yours and your allies'): {x, y, r, life, def, regen, tick}. */
		public var auras:Array = [];
		/** Smoke Bomb clouds: {x, y, r, life, max, mine, tick, seed}. */
		public var clouds:Array = [];
		/** Your summons (Raise Dead skeletons, the Spirit Wolf): {kind, x, y, life, cd, dmg, left}. */
		public var minions:Array = [];

		public function Abilities(g:Game) {
			this.g = g;
			Sprites.recolor("risen", "skeleton", {H: 0xc8e0b0, h: 0x7a9a68, S: 0xc8e0b0, E: 0x70ff60, B: 0x3a5a3a, b: 0x223a22, A: 0x60c060, L: 0x8aa878, W: 0xd8f0c8});
			Sprites.recolor("spirit_wolf", "wolf", {W: 0xb8e0ff, w: 0x6a98d0, E: 0xffffff});
		}

		public function clear():void {
			zones.length = 0;
			spirits.length = 0;
			fx.length = 0;
			auras.length = 0;
			clouds.length = 0;
			minions.length = 0;
			if (g.player) g.player.shieldT = 0;
		}

		public function anim(k:String, x:Number, y:Number, d:Number, o:Object = null):Object {
			var f:Object = o || {};
			f.k = k; f.x = x; f.y = y; f.t = 0; f.d = d;
			if (fx.length < 120 || f.fn) fx.push(f);
			return f;
		}

		// ------------------------------------------------------------ casts
		/**
		 * The look of a cast. mine = your own (also tells the other players);
		 * n is a duration or radius depending on the ability.
		 */
		public function show(k:String, x:Number, y:Number, tx:Number, ty:Number, n:Number, mine:Boolean):void {
			if (mine) g.net.abilityFx(k, x, y, tx, ty, n);
			var i:int;
			switch (k) {
				case "fireball":
					anim("cast", x, y, 0.35, {col: 0xff8030, r: 1.2});
					if (!mine) {
						var a:Number = Math.atan2(ty - y, tx - x);
						var dd:Number = Math.sqrt((tx - x) * (tx - x) + (ty - y) * (ty - y));
						var ghost:Projectile = new Projectile(x, y, a, 12, Math.max(0.15, dd / 12), 0, false, 0.4, Sprites.projectile("fire", 0xff7020, 5), false, "", null);
						ghost.ghost = true;
						ghost.boom = {r: 2.6, dmg: 0};
						g.addShot(ghost);
					}
					break;
				case "boom":
					Sfx.play("boom", 0.9, 0.08);
					anim("nova", x, y, 0.45, {col: 0xff7020, r: n});
					anim("flash", x, y, 0.18, {col: 0xffe0a0, r: n * 0.7});
					g.burst(x, y, 0xff9030, 22);
					g.burst(x, y, 0xffe060, 10);
					puff(x, y, 0x504038, 8, 2);
					break;
				case "shield":
					Sfx.play("clang", 0.8);
					anim("shield", tx, ty, n, {a: Math.atan2(ty - y, tx - x), mine: mine});
					anim("nova", tx, ty, 0.35, {col: 0xc0e0ff, r: 2.2});
					g.burst(tx, ty, 0xd0e8ff, 14);
					puff(tx, ty, 0x9a8a70, 8, 3);
					break;
				case "storm":
					Sfx.play("arrows", 0.7);
					anim("storm", tx, ty, 1.1, {r: 2.4, spawn: 0, fake: !mine});
					anim("cast", x, y, 0.35, {col: 0xffff80, r: 1});
					break;
				case "sanctuary":
					Sfx.play("holy", 0.8);
					anim("sanct", x, y, n, {r: 3});
					anim("nova", x, y, 0.5, {col: 0xfff0a0, r: 3});
					g.ring(x, y, 0xfff0a0, 24);
					break;
				case "shadow":
					Sfx.play("whoosh", 0.9);
					puff(x, y, 0x302838, 14, 4);
					puff(tx, ty, 0x302838, 14, 4);
					anim("streak", x, y, 0.3, {tx: tx, ty: ty, col: 0x8060c0, w: 10});
					break;
				case "charge":
					Sfx.play("whoosh", 1);
					anim("streak", x, y, 0.45, {tx: tx, ty: ty, col: 0xff5030, w: 14});
					puff(x, y, 0x8a7a60, 10, 4);
					break;
				case "harvest":
					anim("nova", tx, ty, 0.45, {col: 0xa0ff60, r: 3});
					anim("souls", tx, ty, 0.6, {px: x, py: y});
					g.burst(tx, ty, 0xa0ff60, 20);
					break;
				case "snare":
					anim("throw", x, y, 0.35, {tx: tx, ty: ty});
					break;
				case "vines":
					Sfx.play("vines", 0.8);
					anim("vines", x, y, 1.6, {r: n, seed: Math.random() * 100});
					g.burst(x, y, 0x60c040, 14);
					break;

				// ---- the second and third abilities
				case "lightning":
					anim("cast", x, y, 0.35, {col: 0x9ab8ff, r: 1.1});
					anim("mark", tx, ty, 0.35, {col: 0xa0c0ff, r: 1.4});
					anim("land", tx, ty, 0.35, {fn: function():void {
						Sfx.play("boom", 1, 0.1);
						anim("bolt", tx, ty, 0.3, {seed: Math.random() * 100});
						anim("flash", tx, ty, 0.2, {col: 0xe0eaff, r: 1.6});
						anim("nova", tx, ty, 0.35, {col: 0xa0c0ff, r: 1.6});
						g.burst(tx, ty, 0xc0d8ff, 18);
						g.flash(0.18);
						g.shake(0.2, 5);
					}});
					break;
				case "frostnova":
					Sfx.play("clang", 0.9);
					anim("nova", x, y, 0.5, {col: 0xa0e8ff, r: n});
					anim("nova", x, y, 0.3, {col: 0xffffff, r: n * 0.6});
					anim("flash", x, y, 0.2, {col: 0xd0f4ff, r: n * 0.6});
					anim("shards", x, y, 0.6, {r: n, seed: Math.random() * 100});
					g.burst(x, y, 0xc0f0ff, 26);
					break;
				case "pierce":
					Sfx.play("arrows", 0.9);
					anim("cast", x, y, 0.3, {col: 0xd8e0ff, r: 1});
					if (!mine) ghostShots(x, y, Math.atan2(ty - y, tx - x), 1, 0, 20, 0.7, Sprites.projectile("arrow", 0xd8e0ff, 6));
					break;
				case "volley":
					Sfx.play("whoosh", 0.9);
					anim("streak", x, y, 0.35, {tx: tx, ty: ty, col: 0xc0ffa0, w: 8});
					puff(x, y, 0x8a7a60, 8, 3);
					if (!mine) ghostShots(x, y, Math.atan2(y - ty, x - tx), 7, 0.13, 16, 0.6, Sprites.projectile("arrow", 0xc0ffa0, 4));
					break;
				case "bash":
					Sfx.play("clang", 1);
					anim("streak", x, y, 0.35, {tx: tx, ty: ty, col: 0xffe0a0, w: 16});
					puff(x, y, 0x9a8a70, 8, 3);
					break;
				case "banner":
					Sfx.play("clang", 0.8);
					// pow back from the length (6s at 100%): every game works out the same bonus
					var bp:Number = (n / 6) * (n / 6);
					auras.push({x: x, y: y, r: 4, life: n, max: n, def: int(10 * bp), pow: bp, tick: 0});
					anim("nova", x, y, 0.5, {col: 0xff6050, r: 4});
					g.burst(x, y, 0xffd060, 16);
					break;
				case "smite":
					anim("cast", x, y, 0.3, {col: 0xfff0a0, r: 1});
					anim("mark", tx, ty, 0.3, {col: 0xfff0a0, r: 1.8});
					anim("land", tx, ty, 0.3, {fn: function():void {
						Sfx.play("holy", 0.9);
						anim("beam", tx, ty, 0.6, {col: 0xfff4b0});
						anim("nova", tx, ty, 0.45, {col: 0xfff0a0, r: 1.8});
						g.burst(tx, ty, 0xfff0a0, 20);
						if (!mine && near(tx, ty, 1.8)) g.player.healBy(int(n), g);
					}});
					break;
				case "ward":
					Sfx.play("holy", 1);
					anim("nova", x, y, 0.6, {col: 0x90c8ff, r: 5});
					anim("beam", x, y, 0.5, {col: 0xc0e0ff});
					g.ring(x, y, 0x90c8ff, 28);
					if (!mine && near(x, y, 5)) {
						var pl:Player = g.player;
						pl.healBy(int(n), g);
						for (var cs:String in pl.status) pl.status[cs] = 0;
						pl.wardHp = Math.max(pl.wardHp, n * 0.67);
						pl.wardT = 6;
					}
					break;
				case "knives":
					Sfx.play("whoosh", 0.8);
					anim("cast", x, y, 0.3, {col: 0x90f070, r: 1.2});
					if (!mine) ghostShots(x, y, Math.atan2(ty - y, tx - x), 12, Math.PI / 6, 11, 0.55, Sprites.projectile("knife", 0x90f070, 3), true);
					break;
				case "smoke":
					Sfx.play("whoosh", 0.7);
					clouds.push({x: x, y: y, r: 3, life: n, max: n, mine: mine, tick: 0, seed: Math.random() * 100});
					puff(x, y, 0x5a5a5a, 22, 4);
					break;
				case "whirlwind":
					Sfx.play("whoosh", 1);
					anim("spin", x, y, n, {follow: mine});
					break;
				case "warcry":
					Sfx.play("boom", 0.8, 0.15);
					anim("nova", x, y, 0.5, {col: 0xff5030, r: n});
					anim("nova", x, y, 0.7, {col: 0xffa040, r: n * 0.7});
					g.ring(x, y, 0xff6040, 26);
					break;
				case "prison":
					Sfx.play("clang", 0.7);
					anim("bones", tx, ty, n, {r: 2.5, seed: Math.random() * 100});
					puff(tx, ty, 0xc0b090, 12, 3);
					break;
				case "raise":
					Sfx.play("vines", 0.8);
					anim("nova", x, y, 0.5, {col: 0x70ff60, r: 2});
					puff(x, y, 0x3a5a3a, 16, 3);
					g.burst(x, y, 0x70ff60, 14);
					break;
				case "explosive":
					anim("throw", x, y, 0.35, {tx: tx, ty: ty});
					break;
				case "wolf":
					Sfx.play("whoosh", 0.8);
					anim("nova", x, y, 0.45, {col: 0xb8e0ff, r: 1.6});
					puff(x, y, 0xb8e0ff, 14, 3);
					break;

				// ---- Bard
				case "valor":
					Sfx.play("lyre", 0.9);
					anim("nova", x, y, 0.6, {col: 0xffd060, r: 6});
					anim("notes", x, y, 1.2, {col: 0xffd060, seed: Math.random() * 100});
					g.ring(x, y, 0xffd060, 24);
					if (!mine && near(x, y, 6)) {
						g.player.buffs.might = Math.max(g.player.buffs.might || 0, n);
						g.floatText(g.player.x, g.player.y - 1.4, "Inspired!", 0xffd060);
					}
					break;
				case "lullaby":
					Sfx.play("lull", 0.8);
					anim("notes", tx, ty, 1.4, {col: 0xb8a8ff, seed: Math.random() * 100});
					anim("nova", tx, ty, 0.8, {col: 0xb8a8ff, r: n});
					puff(tx, ty, 0x8a7ad0, 10, 2);
					break;
				case "requiem":
					Sfx.play("requiem", 0.9, 0.1);
					anim("nova", x, y, 0.45, {col: 0xff6a90, r: n});
					anim("nova", x, y, 0.7, {col: 0xc04a6a, r: n * 0.7});
					anim("notes", x, y, 0.9, {col: 0xff8aa8, seed: Math.random() * 100});
					break;

				// ---- Alchemist
				case "acid":
					anim("throw", x, y, 0.35, {tx: tx, ty: ty});
					anim("land", tx, ty, 0.35, {fn: function():void {
						Sfx.play("bubble", 0.8);
						anim("nova", tx, ty, 0.4, {col: 0x80ff40, r: 2.5});
						puff(tx, ty, 0x60c020, 12, 3);
						g.burst(tx, ty, 0xa0ff60, 16);
						// everyone sees the pool; only the thrower's game hurts monsters with it
						anim("pool", tx, ty, n, {r: 2.5, col: 0x70e030, seed: Math.random() * 100});
					}});
					break;
				case "elixir":
					Sfx.play("glug", 0.9);
					anim("nova", x, y, 0.55, {col: 0xff70c0, r: 5});
					g.ring(x, y, 0xff90d0, 22);
					if (!mine && near(x, y, 5)) {
						var ep:Player = g.player;
						ep.healBy(int(n), g);
						for (var ecs:String in ep.status) ep.status[ecs] = 0;
						ep.buffs.vigor = Math.max(ep.buffs.vigor || 0, 4);
					}
					break;
				case "philbomb":
					anim("throw", x, y, 0.35, {tx: tx, ty: ty});
					Sfx.play("fizz", 0.8);
					anim("mark", tx, ty, 1.85, {col: 0xffb030, r: 3.2});
					anim("land", tx, ty, 1.85, {fn: function():void {
						Sfx.play("boom", 1, 0.05);
						anim("nova", tx, ty, 0.5, {col: 0xffa020, r: 3.2});
						anim("flash", tx, ty, 0.25, {col: 0xfff0b0, r: 2.6});
						g.burst(tx, ty, 0xffc040, 34);
						puff(tx, ty, 0x504038, 14, 4);
						g.flash(0.2);
					}});
					break;

				// ---- Chronomancer
				case "rewind":
					Sfx.play("rewind", 0.9);
					anim("streak", tx, ty, 0.45, {tx: x, ty: y, col: 0x80e0ff, w: 8});
					anim("nova", x, y, 0.4, {col: 0x80e0ff, r: 1.4});
					anim("nova", tx, ty, 0.5, {col: 0xf0c040, r: 1.6});
					g.burst(tx, ty, 0xf0c040, 16);
					break;
				case "timestop":
					Sfx.play("freeze", 0.9);
					anim("nova", x, y, 0.6, {col: 0x9ad8ff, r: 4});
					anim("flash", x, y, 0.25, {col: 0xe0f4ff, r: 3});
					anim("clock", x, y, n, {r: 4});
					// every game freezes its own copy of the bullets
					g.freezeShots(x, y, 4, n);
					break;
				case "hastefield":
					Sfx.play("ticks", 0.8);
					auras.push({x: x, y: y, r: 4, life: n, max: n, def: 0, pow: 0, tick: 0, haste: true});
					anim("nova", x, y, 0.5, {col: 0xf0d050, r: 4});
					g.ring(x, y, 0xf0d050, 20);
					break;
			}
		}

		/** Is your own hero within r of (x, y)? */
		private function near(x:Number, y:Number, r:Number):Boolean {
			var p:Player = g.player;
			return p.hp > 0 && (p.x - x) * (p.x - x) + (p.y - y) * (p.y - y) < r * r;
		}

		/** Harmless copies of another player's shots, so you see what they cast. */
		private function ghostShots(x:Number, y:Number, a:Number, n:int, step:Number, spd:Number, life:Number, frames:Vector.<BitmapData>, ring:Boolean = false):void {
			for (var i:int = 0; i < n; i++) {
				var ang:Number = ring ? a + i * step : a + (i - (n - 1) / 2) * step;
				var s:Projectile = new Projectile(x, y, ang, spd, life, 0, false, 0.3, frames, false, "", null);
				s.ghost = true;
				g.addShot(s);
			}
		}

		/** Lightning Strike lands: the nearest monster, then up to 3 jumps. */
		public function lightning(x:Number, y:Number, dmg:int):void {
			var hit:Array = [];
			var cur:Enemy = nearestEnemy(x, y, 1.8, hit);
			var px:Number = x, py:Number = y;
			for (var j:int = 0; j < 4 && cur; j++) {
				if (j > 0) anim("chain", px, py, 0.3, {tx: cur.x, ty: cur.y, seed: Math.random() * 100});
				g.hurtEnemy(cur, dmg, null, cur.x, cur.y);
				g.burst(cur.x, cur.y, 0xc0d8ff, 6);
				hit.push(cur);
				px = cur.x; py = cur.y;
				dmg = int(dmg * 0.67);
				cur = nearestEnemy(px, py, 4.5, hit);
			}
		}

		private function nearestEnemy(x:Number, y:Number, r:Number, skip:Array):Enemy {
			var best:Enemy = null, bd:Number = r * r;
			for each (var e:Enemy in g.enemies) {
				if (e.dead || skip.indexOf(e) >= 0) continue;
				var dx:Number = e.x - x, dy:Number = e.y - y;
				if (dx * dx + dy * dy < bd) { bd = dx * dx + dy * dy; best = e; }
			}
			return best;
		}

		/** Raise Dead / Spirit Wolf: n summons around you for `life` seconds. */
		public function addMinions(kind:String, n:int, life:Number, dmg:int):void {
			for (var i:int = minions.length - 1; i >= 0; i--) if (minions[i].kind == kind) minions.splice(i, 1);
			var p:Player = g.player;
			for (i = 0; i < n; i++) {
				var a:Number = i * Math.PI * 2 / n + Math.random();
				var mx:Number = p.x + Math.cos(a) * 1.2, my:Number = p.y + Math.sin(a) * 1.2;
				if (!g.world.canStand(mx, my, 0.3, false)) { mx = p.x; my = p.y; }
				minions.push({kind: kind, x: mx, y: my, life: life, cd: 0.4 + i * 0.25, dmg: dmg, left: false, walk: 0});
				puff(mx, my, kind == "risen" ? 0x3a5a3a : 0xb8e0ff, 8, 2);
			}
		}

		private function updateMinions(dt:Number):void {
			var p:Player = g.player;
			var bone:Vector.<BitmapData> = null;
			for (var i:int = minions.length - 1; i >= 0; i--) {
				var m:Object = minions[i];
				m.life -= dt;
				m.cd -= dt;
				if (m.life <= 0) {
					puff(m.x, m.y, m.kind == "risen" ? 0x3a5a3a : 0xb8e0ff, 10, 2);
					minions.splice(i, 1);
					continue;
				}
				var wolf:Boolean = m.kind == "spirit_wolf";
				var t:Enemy = g.world.isSafe(m.x, m.y) ? null : nearestEnemy(m.x, m.y, 9, []);
				var gx:Number = p.x, gy:Number = p.y, keep:Number = 1.6;
				if (t) { gx = t.x; gy = t.y; keep = wolf ? t.r + 0.45 : 4.5; }
				var dx:Number = gx - m.x, dy:Number = gy - m.y, d:Number = Math.sqrt(dx * dx + dy * dy) || 1;
				var spd:Number = wolf ? 7.5 : 3.8;
				if (d > keep) {
					var nx:Number = m.x + dx / d * spd * dt, ny:Number = m.y + dy / d * spd * dt;
					if (g.world.canStand(nx, m.y, 0.3, false)) m.x = nx;
					if (g.world.canStand(m.x, ny, 0.3, false)) m.y = ny;
					m.walk += dt;
					m.left = dx < 0;
				}
				// fell far behind (another room, a portal): catch up
				if ((p.x - m.x) * (p.x - m.x) + (p.y - m.y) * (p.y - m.y) > 20 * 20) { m.x = p.x; m.y = p.y; }
				if (!t || m.cd > 0) continue;
				if (wolf) {
					if (d < t.r + 0.8) {
						m.cd = 0.6;
						g.hurtEnemy(t, m.dmg, "slow", t.x, t.y);
						g.burst(t.x, t.y, 0xb8e0ff, 6);
					}
				} else if (d < 6.5) {
					m.cd = 0.8;
					if (!bone) bone = Sprites.projectile("blade", 0xe8e0c8, 3);
					var s:Projectile = new Projectile(m.x, m.y - 0.3, Math.atan2(t.y - m.y, t.x - m.x), 9, 0.75, m.dmg, false, 0.3, bone, false, p.name, "shard");
					s.trailCol = 0xc8e0b0;
					g.addShot(s);
				}
			}
		}

		/** Smoke and dust: slow dark puffs. */
		public function puff(x:Number, y:Number, col:uint, n:int, spd:Number):void {
			if (!Game.opt("parts")) return;
			var bd:BitmapData = Sprites.glow(col);
			for (var i:int = 0; i < n && g.parts.length < 420; i++) {
				var a:Number = Math.random() * Math.PI * 2, s:Number = spd * (0.4 + Math.random() * 0.6);
				g.parts.push(new Particle(x, y, Math.cos(a) * s, Math.sin(a) * s, 0.5 + Math.random() * 0.4, bd));
			}
		}

		/** A Fireball (or its copy from another player) bursts. */
		public function explode(s:Projectile):void {
			var b:Object = s.boom;
			show("boom", s.x, s.y, 0, 0, b.r, false);
			if (s.bot || b.dmg <= 0) return;
			g.blastAt(s.x, s.y, b.r, b.dmg);
			var ember:Vector.<BitmapData> = Sprites.projectile("fire", 0xffa040, 2);
			for (var k:int = 0; k < 8; k++) {
				g.addShot(new Projectile(s.x, s.y, k * Math.PI / 4 + Math.random() * 0.3, 7, 0.4, int(b.dmg * 0.25), false, 0.25, ember, false, s.owner, "shard"));
			}
		}

		public function addZone(x:Number, y:Number, r:Number, life:Number, dmg:int, heal:int):void {
			zones.push({x: x, y: y, r: r, life: life, tick: 0, dmg: dmg, heal: heal});
		}

		public function addSpirits(n:int, life:Number, dmg:int):void {
			spirits.length = 0;
			for (var i:int = 0; i < n; i++) spirits.push({a: i * Math.PI * 2 / n, life: life, cd: 0.3 + i * 0.3, dmg: dmg});
		}

		/** A planted Shield Wall in front of this enemy shot catches it. */
		public function blocked(s:Projectile):Boolean {
			for each (var f:Object in fx) {
				if (f.k != "shield") continue;
				var dx:Number = Math.cos(f.a), dy:Number = Math.sin(f.a);
				var rx:Number = s.x - f.x, ry:Number = s.y - f.y;
				var u:Number = rx * dx + ry * dy, v:Number = ry * dx - rx * dy;
				if (u > -0.45 && u < 0.45 && v > -1.35 && v < 1.35 && s.vx * dx + s.vy * dy < 0) {
					g.burst(s.x, s.y, 0xd0e8ff, 3);
					return true;
				}
			}
			return false;
		}

		// ------------------------------------------------------------ update
		public function update(dt:Number):void {
			var i:int, p:Player = g.player, e:Enemy, dx:Number, dy:Number;
			for (i = fx.length - 1; i >= 0; i--) {
				var f:Object = fx[i];
				f.t += dt;
				if (f.k == "storm") {
					// arrows rain over the circle (your own storm's real arrows are added on cast)
					f.spawn -= dt;
					if (f.spawn <= 0 && f.t < f.d - 0.35) {
						f.spawn = f.fake ? 0.06 : 0.12;
						var ra:Number = Math.random() * Math.PI * 2, rr:Number = Math.sqrt(Math.random()) * f.r;
						anim("arrow", f.x + Math.cos(ra) * rr, f.y + Math.sin(ra) * rr, 0.3);
					}
				} else if (f.k == "pillar" && Math.random() < dt * 30 && Game.opt("parts") && g.parts.length < 420) {
					var pp:Player = g.player;
					g.parts.push(new Particle(pp.x + (Math.random() - 0.5) * 0.8, pp.y + 0.2, 0, -3 - Math.random() * 3, 0.7, Sprites.glow(Math.random() < 0.5 ? 0xfff080 : 0xb0ff90)));
				} else if (f.k == "sanct" && Math.random() < dt * 14 && Game.opt("parts") && g.parts.length < 420) {
					var sa:Number = Math.random() * Math.PI * 2, sr:Number = Math.sqrt(Math.random()) * f.r;
					g.parts.push(new Particle(f.x + Math.cos(sa) * sr, f.y + Math.sin(sa) * sr, 0, -1.2, 0.7, Sprites.glow(0xfff0a0)));
				}
				if (f.t >= f.d) {
					fx.splice(i, 1);
					if (f.fn != null) f.fn();
				}
			}
			for (i = zones.length - 1; i >= 0; i--) {
				var z:Object = zones[i];
				z.life -= dt;
				z.tick -= dt;
				if (z.tick <= 0) {
					z.tick = 0.5;
					dx = p.x - z.x; dy = p.y - z.y;
					if (z.heal > 0 && dx * dx + dy * dy < z.r * z.r && p.hp > 0 && p.hp < p.maxHp) {
						var before:int = int(p.hp);
						p.hp = Math.min(p.maxHp, p.hp + z.heal);
						if (Game.opt("dmg")) g.floatText(p.x, p.y - 1.2, "+" + (int(p.hp) - before), 0x60ff60);
					}
					if (!g.world.isSafe(z.x, z.y)) {
						for each (e in g.enemies.concat()) {
							dx = e.x - z.x; dy = e.y - z.y;
							if (!e.dead && dx * dx + dy * dy < z.r * z.r) {
								g.hurtEnemy(e, z.dmg, "shard", e.x, e.y);
								g.burst(e.x, e.y, 0xfff0a0, 3);
							}
						}
					}
				}
				if (z.life <= 0) zones.splice(i, 1);
			}
			// Rallying Banners: Defense and healing while you stand near one (Haste Fields: speed and fire rate)
			p.auraDef = 0;
			for (i = auras.length - 1; i >= 0; i--) {
				var au:Object = auras[i];
				au.life -= dt;
				if (au.life <= 0) { auras.splice(i, 1); continue; }
				dx = p.x - au.x; dy = p.y - au.y;
				if (dx * dx + dy * dy >= au.r * au.r || p.hp <= 0) continue;
				if (au.haste) {
					p.buffs.haste = Math.max(p.buffs.haste || 0, 0.25);
					p.buffs.quick = Math.max(p.buffs.quick || 0, 0.25);
					continue;
				}
				p.auraDef = Math.max(p.auraDef, au.def);
				au.tick -= dt;
				if (au.tick <= 0) {
					au.tick = 0.5;
					if (p.hp < p.maxHp) p.hp = Math.min(p.maxHp, p.hp + (4 + p.level * 0.5) * au.pow);
				}
			}
			// Smoke Bombs: hidden inside; monsters in your own cloud are slowed
			for (i = clouds.length - 1; i >= 0; i--) {
				var cl:Object = clouds[i];
				cl.life -= dt;
				if (cl.life <= 0) { clouds.splice(i, 1); continue; }
				if (near(cl.x, cl.y, cl.r)) p.invisT = Math.max(p.invisT, 0.2);
				if (Math.random() < dt * 10 && Game.opt("parts") && g.parts.length < 420) {
					var ca:Number = Math.random() * Math.PI * 2, cr:Number = Math.sqrt(Math.random()) * cl.r;
					g.parts.push(new Particle(cl.x + Math.cos(ca) * cr, cl.y + Math.sin(ca) * cr, 0, -0.3, 1, Sprites.glow(0x606060)));
				}
				if (!cl.mine) continue;
				cl.tick -= dt;
				if (cl.tick > 0) continue;
				cl.tick = 0.5;
				for each (e in g.enemies) {
					dx = e.x - cl.x; dy = e.y - cl.y;
					if (e.dead || dx * dx + dy * dy >= cl.r * cl.r) continue;
					e.slowT = Math.max(e.slowT, 1);
					if (e.remote) g.sync.hit(e, 0, 1, 0);
				}
			}
			updateMinions(dt);
			var skull:Vector.<BitmapData> = spirits.length ? Sprites.projectile("soul", 0x90ff70, 3) : null;
			for (i = spirits.length - 1; i >= 0; i--) {
				var s:Object = spirits[i];
				s.a += dt * 2.6;
				s.life -= dt;
				s.cd -= dt;
				var sx:Number = p.x + Math.cos(s.a) * 1.3, sy:Number = p.y + Math.sin(s.a) * 1.3;
				if (Math.random() < dt * 20 && g.parts.length < 420 && Game.opt("parts")) g.parts.push(new Particle(sx, sy, 0, -0.6, 0.35, Sprites.glow(0x90ff70)));
				if (s.cd <= 0 && !g.world.isSafe(p.x, p.y)) {
					var best:Enemy = null, bd:Number = 64;
					for each (e in g.enemies) {
						if (e.dead) continue;
						dx = e.x - sx; dy = e.y - sy;
						if (dx * dx + dy * dy < bd) { bd = dx * dx + dy * dy; best = e; }
					}
					if (best) {
						s.cd = 0.8;
						g.addShot(new Projectile(sx, sy, Math.atan2(best.y - sy, best.x - sx), 11, 0.8, s.dmg, false, 0.3, skull, false, p.name, "shard"));
					} else s.cd = 0.2;
				}
				if (s.life <= 0) {
					puff(sx, sy, 0x90ff70, 6, 2);
					spirits.splice(i, 1);
				}
			}
		}

		// ------------------------------------------------------------ drawing
		private function X(x:Number, y:Number):Number { return g.scrX(x, y); }
		private function Y(x:Number, y:Number):Number { return g.scrY(x, y) + Game.TS * 0.3; }

		/** Under everything standing: circles, shockwaves, vines. */
		public function drawGround(canvas:BitmapData):void {
			var TS:int = Game.TS, gr:* = sh.graphics, f:Object, q:Number, rx:Number, ry:Number, i:int, a:Number;
			gr.clear();
			for each (f in fx) {
				q = f.t / f.d;
				var cx:Number = X(f.x, f.y), cy:Number = Y(f.x, f.y);
				switch (f.k) {
					case "cast":
						rx = f.r * TS * (0.4 + q * 0.6); ry = rx * 0.6;
						gr.lineStyle(2, f.col, 1 - q);
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						gr.lineStyle();
						for (i = 0; i < 6; i++) {
							a = i * Math.PI / 3 + q * 3;
							gr.beginFill(f.col, 1 - q);
							gr.drawRect(cx + Math.cos(a) * rx - 2, cy + Math.sin(a) * ry - 2, 4, 4);
							gr.endFill();
						}
						break;
					case "nova":
						rx = f.r * TS * Math.sqrt(q); ry = rx * 0.6;
						gr.lineStyle(4 * (1 - q) + 1, f.col, 1 - q);
						gr.beginFill(f.col, 0.25 * (1 - q));
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						gr.endFill();
						gr.lineStyle();
						break;
					case "pool":
						// bubbling acid: a green puddle with bubbles popping
						var pf:Number = Math.min(1, (f.d - f.t) / 0.5, f.t / 0.2);
						rx = f.r * TS; ry = rx * 0.6;
						gr.beginFill(f.col, 0.28 * pf);
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						gr.endFill();
						gr.lineStyle(2, 0xb0ff70, 0.7 * pf);
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						gr.lineStyle();
						for (i = 0; i < 7; i++) {
							var bph:Number = (f.t * 1.7 + i * 0.37 + f.seed) % 1;
							var bba:Number = i * 2.4 + f.seed, bbr:Number = ((i * 0.31 + f.seed * 0.01) % 0.8);
							gr.beginFill(0xd0ff90, (1 - bph) * 0.8 * pf);
							gr.drawCircle(cx + Math.cos(bba) * rx * bbr, cy + Math.sin(bba) * ry * bbr, 1.5 + bph * 3.5);
							gr.endFill();
						}
						break;
					case "clock":
						// Time Stop: a pale clock face, its hand frozen
						var cf:Number = Math.min(1, (f.d - f.t) / 0.4, f.t / 0.15);
						rx = f.r * TS; ry = rx * 0.6;
						gr.beginFill(0x9ad8ff, 0.1 * cf);
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						gr.endFill();
						gr.lineStyle(2, 0xd0f0ff, 0.75 * cf);
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						for (i = 0; i < 12; i++) {
							a = i / 12 * Math.PI * 2;
							gr.moveTo(cx + Math.cos(a) * rx * 0.82, cy + Math.sin(a) * ry * 0.82);
							gr.lineTo(cx + Math.cos(a) * rx, cy + Math.sin(a) * ry);
						}
						gr.lineStyle(3, 0xffffff, 0.8 * cf);
						gr.moveTo(cx, cy); gr.lineTo(cx + rx * 0.5, cy - ry * 0.55);
						gr.lineStyle();
						break;
					case "notes":
						// music: little notes drifting up and out
						for (i = 0; i < 8; i++) {
							var na:Number = i * Math.PI / 4 + f.seed;
							var nr:Number = (0.4 + q * 1.8) * TS;
							var nx:Number = cx + Math.cos(na) * nr, ny:Number = cy + Math.sin(na) * nr * 0.6 - q * TS * 1.2;
							gr.beginFill(f.col, 1 - q);
							gr.drawEllipse(nx - 3, ny - 2, 6, 4);
							gr.endFill();
							gr.lineStyle(1.5, f.col, 1 - q);
							gr.moveTo(nx + 2.5, ny); gr.lineTo(nx + 2.5, ny - 9);
							if (i % 2) gr.lineTo(nx + 6, ny - 7);
							gr.lineStyle();
						}
						break;
					case "sanct":
						var fade:Number = Math.min(1, (f.d - f.t) / 0.4, f.t / 0.2);
						rx = f.r * TS; ry = rx * 0.6;
						gr.beginFill(0xfff0a0, (0.1 + Math.sin(f.t * 5) * 0.04) * fade);
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						gr.endFill();
						gr.lineStyle(2, 0xfff0a0, 0.85 * fade);
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						gr.lineStyle(1, 0xffffff, 0.5 * fade);
						gr.drawEllipse(cx - rx * 0.7, cy - ry * 0.7, rx * 1.4, ry * 1.4);
						gr.lineStyle();
						for (i = 0; i < 8; i++) {
							a = i * Math.PI / 4 + f.t * 0.8;
							gr.beginFill(0xffffff, 0.8 * fade);
							gr.drawRect(cx + Math.cos(a) * rx * 0.85 - 2, cy + Math.sin(a) * ry * 0.85 - 3, 4, 6);
							gr.endFill();
						}
						break;
					case "mark":
						// a warning ring that closes in
						rx = f.r * TS * (1.4 - q * 0.4); ry = rx * 0.6;
						gr.lineStyle(2, f.col, 0.4 + q * 0.6);
						gr.beginFill(f.col, 0.12 + q * 0.18);
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						gr.endFill();
						gr.lineStyle();
						break;
					case "vines":
						var vf:Number = Math.min(1, q * 4) * Math.min(1, (1 - q) * 4);
						gr.lineStyle(3, 0x3a8a2a, vf);
						for (i = 0; i < 9; i++) {
							a = i * Math.PI * 2 / 9 + f.seed;
							var len:Number = f.r * TS * Math.min(1, q * 3);
							gr.moveTo(cx, cy);
							for (var s:int = 1; s <= 5; s++) {
								var l:Number = len * s / 5, wob:Number = Math.sin(s * 1.7 + f.seed + i) * 5;
								gr.lineTo(cx + Math.cos(a) * l - Math.sin(a) * wob, cy + (Math.sin(a) * l + Math.cos(a) * wob) * 0.6);
							}
						}
						gr.lineStyle(2, 0x80e060, vf);
						rx = f.r * TS * Math.min(1, q * 3); ry = rx * 0.6;
						gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
						gr.lineStyle();
						break;
				}
			}
			for each (var au:Object in auras) {
				var af:Number = Math.min(1, au.life / 0.5, (au.max - au.life) / 0.3);
				cx = X(au.x, au.y); cy = Y(au.x, au.y);
				rx = au.r * TS; ry = rx * 0.6;
				if (au.haste) {
					// a golden clock face whose hands race round
					gr.beginFill(0xf0d050, 0.08 * af);
					gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
					gr.endFill();
					gr.lineStyle(2, 0xf0d050, 0.6 * af);
					gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
					for (i = 0; i < 12; i++) {
						a = i / 12 * Math.PI * 2;
						gr.moveTo(cx + Math.cos(a) * rx * 0.85, cy + Math.sin(a) * ry * 0.85);
						gr.lineTo(cx + Math.cos(a) * rx, cy + Math.sin(a) * ry);
					}
					gr.lineStyle(3, 0xfff0a0, 0.7 * af);
					gr.moveTo(cx, cy); gr.lineTo(cx + Math.cos(g.time * 9) * rx * 0.7, cy + Math.sin(g.time * 9) * ry * 0.7);
					gr.lineStyle(2, 0xfff0a0, 0.7 * af);
					gr.moveTo(cx, cy); gr.lineTo(cx + Math.cos(g.time * 2.2) * rx * 0.45, cy + Math.sin(g.time * 2.2) * ry * 0.45);
					gr.lineStyle();
					continue;
				}
				gr.beginFill(0xff5040, 0.07 * af);
				gr.drawEllipse(cx - rx, cy - ry, rx * 2, ry * 2);
				gr.endFill();
				gr.lineStyle(2, 0xffc050, 0.55 * af);
				for (i = 0; i < 24; i += 2) {
					a = i / 24 * Math.PI * 2 + g.time * 0.4;
					gr.moveTo(cx + Math.cos(a) * rx, cy + Math.sin(a) * ry);
					gr.lineTo(cx + Math.cos(a + Math.PI / 12) * rx, cy + Math.sin(a + Math.PI / 12) * ry);
				}
				gr.lineStyle();
			}
			canvas.draw(sh);
		}

		/** Above everything: falling arrows, the planted shield, spirits, streaks. */
		public function drawTop(canvas:BitmapData):void {
			var TS:int = Game.TS, gr:* = sh.graphics, f:Object, q:Number, bd:BitmapData, i:int, a:Number;
			gr.clear();
			var arrow:BitmapData = null;
			for each (f in fx) {
				q = f.t / f.d;
				var cx:Number = X(f.x, f.y), cy:Number = Y(f.x, f.y);
				switch (f.k) {
					case "arrow":
						if (!arrow) arrow = Sprites.projectile("arrow", 0xffffa0, 4)[Sprites.frameFor(Math.PI / 2)];
						pt.x = int(cx - arrow.width / 2);
						pt.y = int(cy - arrow.height - TS * 4 * (1 - q));
						canvas.copyPixels(arrow, arrow.rect, pt, null, null, true);
						break;
					case "pillar":
						// a column of light that follows you as it fades
						var pl:Player = g.player;
						var px:Number = X(pl.x, pl.y), py:Number = Y(pl.x, pl.y);
						var pa:Number = q < 0.15 ? q / 0.15 : (1 - q) / 0.85;
						var pw:Number = 26 + Math.sin(f.t * 12) * 3;
						mtx.createGradientBox(pw, TS * 6, Math.PI / 2, px - pw / 2, py - TS * 6);
						gr.beginGradientFill("linear", [f.col, f.col], [0, 0.55 * pa], [0, 255], mtx);
						gr.drawRect(px - pw / 2, py - TS * 6, pw, TS * 6);
						gr.endFill();
						gr.beginFill(0xffffff, 0.35 * pa);
						gr.drawEllipse(px - pw, py - 8, pw * 2, 16);
						gr.endFill();
						break;
					case "flash":
						var fr:Number = f.r * TS * (0.6 + q * 0.4);
						gr.beginFill(f.col, 0.7 * (1 - q));
						gr.drawEllipse(cx - fr, cy - fr * 0.8 - TS * 0.3, fr * 2, fr * 1.6);
						gr.endFill();
						break;
					case "streak":
						var tx:Number = X(f.tx, f.ty), ty:Number = Y(f.tx, f.ty) - TS * 0.4;
						gr.lineStyle(f.w * (1 - q), f.col, 0.6 * (1 - q));
						gr.moveTo(cx, cy - TS * 0.4);
						gr.lineTo(tx, ty);
						gr.lineStyle(f.w * 0.3 * (1 - q), 0xffffff, 0.7 * (1 - q));
						gr.moveTo(cx, cy - TS * 0.4);
						gr.lineTo(tx, ty);
						gr.lineStyle();
						break;
					case "souls":
						for (i = 0; i < 6; i++) {
							var k:Number = Math.min(1, q * (1 + i * 0.12));
							var bend:Number = Math.sin(k * Math.PI) * (i - 2.5) * 0.5;
							var wx:Number = f.x + (f.px - f.x) * k + bend, wy:Number = f.y + (f.py - f.y) * k - bend * 0.5;
							gr.beginFill(0xa0ff60, 0.9);
							gr.drawCircle(X(wx, wy), Y(wx, wy) - TS * 0.5, 4);
							gr.endFill();
							gr.beginFill(0xffffff, 0.9);
							gr.drawCircle(X(wx, wy), Y(wx, wy) - TS * 0.5, 1.5);
							gr.endFill();
						}
						break;
					case "throw":
						var hx:Number = f.x + (f.tx - f.x) * q, hy:Number = f.y + (f.ty - f.y) * q;
						bd = Sprites.icon({kind: "ability", sub: "trap", tier: 0});
						pt.x = int(X(hx, hy) - bd.width / 2);
						pt.y = int(Y(hx, hy) - bd.height / 2 - TS * 1.6 * Math.sin(q * Math.PI));
						canvas.copyPixels(bd, bd.rect, pt, null, null, true);
						break;
					case "bolt":
						// a jagged bolt from the sky
						var bx:Number = cx, by:Number = cy - TS * 0.3;
						var bf:Number = 1 - q;
						var seg:Array = [];
						var r:Number = f.seed;
						for (i = 0; i <= 8; i++) { r = (r * 9301 + 49297) % 233280; seg.push([bx + (i == 8 ? 0 : (r / 233280 - 0.5) * 26), by - TS * 8 * (1 - i / 8)]); }
						for (var lw:int = 0; lw < 2; lw++) {
							gr.lineStyle(lw ? 2.5 : 9, lw ? 0xffffff : 0x8ab0ff, (lw ? 1 : 0.45) * bf);
							gr.moveTo(seg[0][0], seg[0][1]);
							for (i = 1; i < seg.length; i++) gr.lineTo(seg[i][0], seg[i][1]);
						}
						gr.lineStyle();
						break;
					case "chain":
						var ex2:Number = X(f.tx, f.ty), ey2:Number = Y(f.tx, f.ty) - TS * 0.4;
						var sx2:Number = cx, sy2:Number = cy - TS * 0.4;
						var rs:Number = f.seed;
						for (lw = 0; lw < 2; lw++) {
							gr.lineStyle(lw ? 2 : 6, lw ? 0xffffff : 0x8ab0ff, (lw ? 1 : 0.5) * (1 - q));
							gr.moveTo(sx2, sy2);
							for (i = 1; i <= 5; i++) {
								rs = (rs * 9301 + 49297) % 233280;
								var jit:Number = i == 5 ? 0 : (rs / 233280 - 0.5) * 18;
								gr.lineTo(sx2 + (ex2 - sx2) * i / 5 + jit, sy2 + (ey2 - sy2) * i / 5 - jit * 0.5);
							}
						}
						gr.lineStyle();
						break;
					case "beam":
						var ba:Number = q < 0.2 ? q / 0.2 : (1 - q) / 0.8;
						var bw:Number = 30 + Math.sin(f.t * 20) * 4;
						mtx.createGradientBox(bw, TS * 8, Math.PI / 2, cx - bw / 2, cy - TS * 8);
						gr.beginGradientFill("linear", [f.col, f.col], [0, 0.75 * ba], [0, 255], mtx);
						gr.drawRect(cx - bw / 2, cy - TS * 8, bw, TS * 8);
						gr.endFill();
						gr.beginFill(0xffffff, 0.5 * ba);
						gr.drawEllipse(cx - bw, cy - 10, bw * 2, 20);
						gr.endFill();
						break;
					case "shards":
						// ice shards flying out
						for (i = 0; i < 12; i++) {
							a = i / 12 * Math.PI * 2 + f.seed;
							var sd:Number = f.r * TS * Math.sqrt(q);
							var ix:Number = cx + Math.cos(a) * sd, iy:Number = cy + Math.sin(a) * sd * 0.6 - TS * 0.3;
							gr.beginFill(0xe0f8ff, 1 - q);
							gr.moveTo(ix + Math.cos(a) * 9, iy + Math.sin(a) * 6);
							gr.lineTo(ix + Math.cos(a + 1.6) * 3, iy + Math.sin(a + 1.6) * 3);
							gr.lineTo(ix - Math.cos(a) * 4, iy - Math.sin(a) * 3);
							gr.lineTo(ix + Math.cos(a - 1.6) * 3, iy + Math.sin(a - 1.6) * 3);
							gr.endFill();
						}
						break;
					case "spin":
						var sp:Player = g.player;
						var scx:Number = f.follow ? X(sp.x, sp.y) : cx, scy:Number = (f.follow ? Y(sp.x, sp.y) : cy) - TS * 0.4;
						var sfa:Number = Math.min(1, (f.d - f.t) / 0.3);
						for (i = 0; i < 3; i++) {
							a = f.t * 14 + i * Math.PI * 2 / 3;
							gr.lineStyle(5, 0xd0d8e8, 0.7 * sfa);
							var srx:Number = TS * 3.2, sry:Number = TS * 2.0;
							gr.moveTo(scx + Math.cos(a) * srx, scy + Math.sin(a) * sry);
							for (var st:int = 1; st <= 6; st++) {
								var aa:Number = a - st * 0.12;
								gr.lineTo(scx + Math.cos(aa) * srx, scy + Math.sin(aa) * sry);
							}
							gr.lineStyle(2, 0xffffff, sfa);
							gr.moveTo(scx + Math.cos(a) * srx, scy + Math.sin(a) * sry);
							gr.lineTo(scx + Math.cos(a - 0.3) * srx, scy + Math.sin(a - 0.3) * sry);
						}
						gr.lineStyle();
						break;
					case "bones":
						var rise:Number = Math.min(1, f.t / 0.15), bfade:Number = Math.min(1, (f.d - f.t) / 0.4);
						for (i = 0; i < 16; i++) {
							a = i / 16 * Math.PI * 2 + f.seed;
							var bxs:Number = cx + Math.cos(a) * f.r * TS, bys:Number = cy + Math.sin(a) * f.r * TS * 0.6;
							var bh:Number = (14 + (i % 3) * 6) * rise;
							gr.lineStyle(1.5, 0x3a3020, bfade);
							gr.beginFill(0xe8e0c8, bfade);
							gr.moveTo(bxs - 4, bys);
							gr.lineTo(bxs + Math.cos(a) * -2, bys - bh);
							gr.lineTo(bxs + 4, bys);
							gr.lineTo(bxs - 4, bys);
							gr.endFill();
						}
						gr.lineStyle();
						break;
					case "shield":
						var fade:Number = Math.min(1, (f.d - f.t) / 0.4);
						var dx:Number = Math.cos(f.a), dy:Number = Math.sin(f.a);
						var x1:Number = f.x - dy * 1.3, y1:Number = f.y + dx * 1.3, x2:Number = f.x + dy * 1.3, y2:Number = f.y - dx * 1.3;
						var lift:Number = TS * 0.5;
						gr.lineStyle(14, 0x80b0ff, (0.22 + Math.sin(f.t * 6) * 0.06) * fade);
						gr.moveTo(X(x1, y1), Y(x1, y1) - lift);
						gr.lineTo(X(x2, y2), Y(x2, y2) - lift);
						gr.lineStyle(4, 0xd8ecff, 0.75 * fade);
						gr.moveTo(X(x1, y1), Y(x1, y1) - lift);
						gr.lineTo(X(x2, y2), Y(x2, y2) - lift);
						gr.lineStyle();
						bd = Sprites.icon({kind: "ability", sub: "shield", tier: 3});
						pt.x = int(cx - bd.width / 2);
						pt.y = int(cy - bd.height - 2);
						canvas.copyPixels(bd, bd.rect, pt, null, null, true);
						break;
				}
			}
			// Rallying Banners: a pole with a flag in the wind
			for each (var au:Object in auras) {
				if (au.haste) continue;
				var bfa:Number = Math.min(1, au.life / 0.5);
				var pcx:Number = X(au.x, au.y), pcy:Number = Y(au.x, au.y);
				gr.lineStyle(3, 0x3a2410, bfa);
				gr.moveTo(pcx, pcy); gr.lineTo(pcx, pcy - TS * 2.2);
				gr.lineStyle(1.5, 0x2a1000, bfa);
				gr.beginFill(0xc02828, bfa);
				var wave:Number = Math.sin(g.time * 6) * 3;
				gr.moveTo(pcx, pcy - TS * 2.2);
				gr.curveTo(pcx + 14, pcy - TS * 2.2 + wave, pcx + 30, pcy - TS * 2.1 - wave);
				gr.lineTo(pcx + 30, pcy - TS * 1.45 - wave);
				gr.curveTo(pcx + 14, pcy - TS * 1.55 + wave, pcx, pcy - TS * 1.5);
				gr.lineTo(pcx, pcy - TS * 2.2);
				gr.endFill();
				gr.lineStyle();
				gr.beginFill(0xffd050, bfa);
				gr.drawCircle(pcx + 15, pcy - TS * 1.83, 4);
				gr.drawCircle(pcx, pcy - TS * 2.25, 3);
				gr.endFill();
			}
			// Smoke Bombs: billowing grey
			for each (var cl:Object in clouds) {
				var cfa:Number = Math.min(1, cl.life / 0.8, (cl.max - cl.life) / 0.3);
				for (i = 0; i < 11; i++) {
					var ca:Number = i * 2.4 + cl.seed + g.time * 0.3 * (i % 2 ? 1 : -1);
					var cd:Number = (i % 4) / 4 * cl.r * 0.8;
					var cxx:Number = cl.x + Math.cos(ca) * cd, cyy:Number = cl.y + Math.sin(ca) * cd;
					var cr:Number = TS * (1.1 + (i % 3) * 0.3 + Math.sin(g.time * 2 + i) * 0.1);
					gr.beginFill(i % 2 ? 0x5a5a60 : 0x7a7a80, 0.3 * cfa);
					gr.drawEllipse(X(cxx, cyy) - cr, Y(cxx, cyy) - cr * 0.8 - TS * 0.4, cr * 2, cr * 1.4);
					gr.endFill();
				}
			}
			// Divine Ward: a shimmering bubble while it lasts
			var wp:Player = g.player;
			if (wp.wardT > 0 && wp.wardHp > 0) {
				var wcx:Number = X(wp.x, wp.y), wcy:Number = Y(wp.x, wp.y) - TS * 0.55;
				var wa:Number = Math.min(1, wp.wardT / 0.5) * (0.6 + Math.sin(g.time * 6) * 0.15);
				gr.lineStyle(2, 0xc0e0ff, 0.8 * wa);
				gr.beginFill(0x90c8ff, 0.16 * wa);
				gr.drawEllipse(wcx - TS * 0.75, wcy - TS * 0.8, TS * 1.5, TS * 1.6);
				gr.endFill();
				gr.lineStyle();
			}
			// summons
			for each (var m:Object in minions) {
				var mbd:BitmapData = Sprites.get(m.kind, int(m.walk * 6) % 2, m.left);
				pt.x = int(X(m.x, m.y) - mbd.width / 2);
				pt.y = int(Y(m.x, m.y) - mbd.height);
				canvas.copyPixels(mbd, mbd.rect, pt, null, null, true);
			}
			if (spirits.length) {
				var p:Player = g.player;
				var skull:BitmapData = Sprites.projectile("soul", 0x90ff70, 4)[0];
				for each (var s:Object in spirits) {
					var sx:Number = p.x + Math.cos(s.a) * 1.3, sy:Number = p.y + Math.sin(s.a) * 1.3;
					pt.x = int(X(sx, sy) - skull.width / 2);
					pt.y = int(Y(sx, sy) - skull.height - TS * 0.4 + Math.sin(g.time * 5 + s.a) * 3);
					canvas.copyPixels(skull, skull.rect, pt, null, null, true);
				}
			}
			canvas.draw(sh);
		}
	}
}
