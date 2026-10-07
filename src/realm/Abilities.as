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

		public function Abilities(g:Game) { this.g = g; }

		public function clear():void {
			zones.length = 0;
			spirits.length = 0;
			fx.length = 0;
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
					if (dx * dx + dy * dy < z.r * z.r && p.hp > 0 && p.hp < p.maxHp) {
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
			canvas.draw(sh);
		}

		/** Above everything: falling arrows, the planted shield, spirits, streaks. */
		public function drawTop(canvas:BitmapData):void {
			var TS:int = Game.TS, gr:* = sh.graphics, f:Object, q:Number, bd:BitmapData, i:int;
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
