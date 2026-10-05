package realm {
	import flash.display.BitmapData;
	import flash.ui.Keyboard;

	public class Player {
		public static const MAX_LEVEL:int = 20;
		public static const MAX_POTS:int = 6;
		public static const R:Number = 0.3;

		public var cls:Object;
		public var name:String;
		public var x:Number, y:Number;
		public var hp:Number, mp:Number;
		public var stats:Object = {};
		public var weapon:Object, ability:Object, armor:Object, ring:Object;
		public var inv:Array = [null, null, null, null, null, null, null, null];
		public var hpPots:int = 1, mpPots:int = 0;
		public var level:int = 1, xp:int = 0, xpNext:int = 60, totalXp:int = 0;
		public var kills:int = 0, bossKills:int = 0, potsDrunk:int = 0;
		public var bossDmg:int = 0;
		public var facingLeft:Boolean = false;
		public var autoFire:Boolean = false;
		public var invulnT:Number = 2;
		public var hitT:Number = 0;
		public var lastHitBy:String = "";
		public var aimX:Number = 0, aimY:Number = 0;
		public var moving:Boolean = false;
		public var burning:Boolean = false;

		private var shootT:Number = 0;
		private var attackT:Number = 0;
		private var abilityT:Number = 0;
		private var walkT:Number = 0;
		private var burnTick:Number = 0;

		public function Player(clsId:String, name:String, x:Number, y:Number) {
			cls = Data.CLASSES[clsId];
			this.name = name;
			this.x = x;
			this.y = y;
			for each (var s:String in Data.STATS) stats[s] = cls.base[s];
			weapon = Data.makeWeapon(cls.weapon, 0);
			ability = Data.makeAbility(cls.abilityType, 0);
			armor = Data.makeArmor(cls.armor, 0);
			ring = null;
			hp = maxHp;
			mp = maxMp;
		}

		/** Stat bonus from armour and ring. */
		public function bonus(s:String):int {
			var b:int = 0;
			if (armor && armor[s]) b += armor[s];
			if (ring && ring[s]) b += ring[s];
			return b;
		}

		public function get maxHp():int { return int(stats.hp) + bonus("hp"); }
		public function get maxMp():int { return int(stats.mp) + bonus("mp"); }
		public function get att():int { return int(stats.att) + bonus("att"); }
		public function get def():int { return int(stats.def) + bonus("def"); }
		public function get spd():int { return int(stats.spd) + bonus("spd"); }
		public function get dex():int { return int(stats.dex) + bonus("dex"); }
		public function get vit():int { return int(stats.vit) + bonus("vit"); }
		public function get wis():int { return int(stats.wis) + bonus("wis"); }
		public function get fame():int { return int(totalXp / 8 + kills * 0.5 + bossKills * 150 + potsDrunk * 5); }

		/** Current animation frame bitmap. */
		public function get sprite():BitmapData {
			var frame:int = 0;
			if (attackT > 0) frame = shootT > (1 / fireRate) * 0.5 ? 2 : 0;
			else if (moving) frame = int(walkT * 6) % 2;
			return hitT > 0 ? Sprites.hit(cls.id, frame, facingLeft) : Sprites.get(cls.id, frame, facingLeft);
		}

		public function get fireRate():Number {
			return (1.5 + 6.5 * dex / 75) * weapon.rate;
		}

		public function update(dt:Number, g:Game):void {
			var inp:Input = g.input;
			var w:World = g.world;
			if (invulnT > 0) invulnT -= dt;
			if (hitT > 0) hitT -= dt;
			if (shootT > 0) shootT -= dt;
			if (attackT > 0) attackT -= dt;
			if (abilityT > 0) abilityT -= dt;

			// --- movement
			var mx:Number = 0, my:Number = 0;
			if (inp.isDown(Keyboard.W) || inp.isDown(Keyboard.UP)) my -= 1;
			if (inp.isDown(Keyboard.S) || inp.isDown(Keyboard.DOWN)) my += 1;
			if (inp.isDown(Keyboard.A) || inp.isDown(Keyboard.LEFT)) mx -= 1;
			if (inp.isDown(Keyboard.D) || inp.isDown(Keyboard.RIGHT)) mx += 1;
			if (mx != 0 && my != 0) { mx *= 0.7071; my *= 0.7071; }
			var speed:Number = 4 + 5.6 * (spd / 75);
			if (mx != 0) {
				var nx:Number = x + mx * speed * dt;
				if (w.canStand(nx, y, R, false)) x = nx;
			}
			if (my != 0) {
				var ny:Number = y + my * speed * dt;
				if (w.canStand(x, ny, R, false)) y = ny;
			}
			moving = mx != 0 || my != 0;
			if (moving) walkT += dt;

			// --- lava
			burning = w.tileAt(x, y) == World.LAVA;
			if (burning) {
				burnTick -= dt;
				if (burnTick <= 0) {
					burnTick = 0.5;
					hp -= 15;
					hitT = 0.1;
					lastHitBy = "Lava";
					g.floatText(x, y - 1, "-15", 0xff8030);
				}
			}

			// --- aim
			aimX = g.screenToWorldX(inp.mx);
			aimY = g.screenToWorldY(inp.my);

			// --- shooting
			if (inp.pressed(Keyboard.I)) {
				autoFire = !autoFire;
				g.msg("Auto-fire " + (autoFire ? "enabled" : "disabled"), 0xaaaaaa);
			}
			var wantShoot:Boolean = autoFire || (inp.mouseDown && inp.mx < Game.VIEW_W);
			if (wantShoot && !w.isSafe(x, y)) {
				facingLeft = aimX < x;
				attackT = 0.25;
				if (shootT <= 0) shoot(g);
			} else if (mx != 0) {
				facingLeft = mx < 0;
			}

			// --- ability / potions / misc
			if (inp.pressed(Keyboard.SPACE)) useAbility(g);
			if (inp.pressed(Keyboard.F)) drinkHp(g);
			if (inp.pressed(Keyboard.G)) drinkMp(g);
			for (var k:int = 0; k < 8; k++) if (inp.pressed(49 + k)) useItem(k, g);
			if (inp.pressed(Keyboard.R)) g.nexus();

			// --- regen
			hp = Math.min(maxHp, hp + (1 + vit * 0.12) * dt);
			mp = Math.min(maxMp, mp + (0.5 + wis * 0.06) * dt);
		}

		private function shoot(g:Game):void {
			var w:Object = weapon;
			shootT = 1 / fireRate;
			var ang:Number = Math.atan2(aimY - y, aimX - x);
			var mult:Number = 0.5 + att / 50;
			var frames:Vector.<BitmapData> = Sprites.projectile(w.shape, w.col, w.sub == "sword" ? 4 : 3);
			for (var k:int = 0; k < w.shots; k++) {
				var a:Number = ang, ox:Number = 0, oy:Number = 0;
				var off:Number = k - (w.shots - 1) / 2;
				if (w.shots > 1) {
					if (w.parallel) {
						ox = -Math.sin(ang) * off * 0.32;
						oy = Math.cos(ang) * off * 0.32;
					} else {
						a = ang + off * w.arc * Math.PI / 180;
					}
				}
				var dmg:int = int((w.dmin + Math.random() * (w.dmax - w.dmin)) * mult);
				g.addShot(new Projectile(x + ox, y + oy, a, w.spd, w.life, dmg, false, 0.25, frames, w.pierce, name, null));
			}
		}

		private function useAbility(g:Game):void {
			var ab:Object = cls.ability;
			if (abilityT > 0) return;
			if (mp < ab.cost) { g.msg("Not enough MP for " + ability.name, 0x8080ff); return; }
			if (g.world.isSafe(x, y) && cls.id != "priest") return;
			mp -= ab.cost;
			abilityT = 0.5;
			attackT = 0.3;
			var pow:Number = ability.power;
			var i:int, a:Number, dmg:int;
			var ang:Number = Math.atan2(aimY - y, aimX - x);
			switch (cls.id) {
				case "wizard":
					var dx:Number = aimX - x, dy:Number = aimY - y;
					var d:Number = Math.sqrt(dx * dx + dy * dy);
					if (d > 9) { dx *= 9 / d; dy *= 9 / d; }
					dmg = (55 + level * 7) * pow;
					var bolt:Vector.<BitmapData> = Sprites.projectile("bolt", 0xff8040, 4);
					for (i = 0; i < 20; i++) {
						a = i * Math.PI * 2 / 20;
						g.addShot(new Projectile(x + dx, y + dy, a, 8, 0.4, dmg, false, 0.25, bolt, false, name, null));
					}
					g.burst(x + dx, y + dy, 0xff8040, 16);
					break;
				case "archer":
					dmg = (100 + level * 12) * pow;
					g.addShot(new Projectile(x, y, ang, 17, 0.75, dmg, false, 0.4, Sprites.projectile("arrow", 0xffff80, 7), true, name, "slow"));
					break;
				case "knight":
					var n:int = g.stunAround(x, y, 3.5, 2.5 * Math.sqrt(pow));
					dmg = (40 + level * 5) * pow;
					var blade:Vector.<BitmapData> = Sprites.projectile("blade", 0xffffff, 4);
					for (i = 0; i < 12; i++) {
						a = i * Math.PI * 2 / 12;
						g.addShot(new Projectile(x, y, a, 10, 0.35, dmg, false, 0.25, blade, true, name, null));
					}
					g.burst(x, y, 0xffffff, 16);
					if (n > 0) g.floatText(x, y - 1.2, "Stunned x" + n, 0xffff60);
					break;
				case "priest":
					var amount:int = (80 + level * 8) * pow;
					var heal:int = Math.min(amount, maxHp - int(hp));
					hp = Math.min(maxHp, hp + amount);
					g.floatText(x, y - 1.2, "+" + heal, 0x60ff60);
					dmg = (30 + level * 4) * pow;
					var orb:Vector.<BitmapData> = Sprites.projectile("orb", 0xffffa0, 4);
					for (i = 0; i < 10; i++) {
						a = i * Math.PI * 2 / 10;
						g.addShot(new Projectile(x, y, a, 9, 0.5, dmg, false, 0.25, orb, false, name, null));
					}
					g.burst(x, y, 0xffffa0, 16);
					break;
			}
		}

		public function drinkHp(g:Game, fromInv:Boolean = false):Boolean {
			if (!fromInv && hpPots <= 0) { g.msg("No health potions! Find them in loot bags.", 0xff8080); return false; }
			if (hp >= maxHp) { g.msg("HP is already full.", 0xaaaaaa); return false; }
			if (!fromInv) hpPots--;
			var before:int = int(hp);
			hp = Math.min(maxHp, hp + 100);
			g.floatText(x, y - 1.2, "+" + (int(hp) - before), 0x60ff60);
			return true;
		}

		public function drinkMp(g:Game, fromInv:Boolean = false):Boolean {
			if (!fromInv && mpPots <= 0) { g.msg("No magic potions!", 0x8080ff); return false; }
			if (mp >= maxMp) { g.msg("MP is already full.", 0xaaaaaa); return false; }
			if (!fromInv) mpPots--;
			var before:int = int(mp);
			mp = Math.min(maxMp, mp + 100);
			g.floatText(x, y - 1.2, "+" + (int(mp) - before), 0x6090ff);
			return true;
		}

		public function useItem(idx:int, g:Game):void {
			var item:Object = inv[idx];
			if (!item) return;
			var old:Object;
			switch (item.kind) {
				case "weapon":
					if (item.sub != cls.weapon) { g.msg("A " + cls.name + " can't use that.", 0xff8080); return; }
					old = weapon; weapon = item; inv[idx] = old;
					break;
				case "ability":
					if (item.sub != cls.abilityType) { g.msg("A " + cls.name + " can't use that.", 0xff8080); return; }
					old = ability; ability = item; inv[idx] = old;
					break;
				case "armor":
					if (item.sub != cls.armor) { g.msg("A " + cls.name + " can't wear that.", 0xff8080); return; }
					old = armor; armor = item; inv[idx] = old;
					break;
				case "ring":
					old = ring; ring = item; inv[idx] = old;
					break;
				case "hp":
					if (drinkHp(g, true)) inv[idx] = null;
					return;
				case "mp":
					if (drinkMp(g, true)) inv[idx] = null;
					return;
				case "stat":
					if (drinkStat(item.sub, g)) inv[idx] = null;
					return;
			}
			hp = Math.min(hp, maxHp);
			mp = Math.min(mp, maxMp);
			g.msg("Equipped " + item.name, 0xffffff);
		}

		public function drinkStat(s:String, g:Game):Boolean {
			var max:Number = cls.max[s];
			if (stats[s] >= max) { g.msg(Data.STAT_NAMES[s] + " is already maxed!", Ui.GOLD); return false; }
			var amt:int = (s == "hp" || s == "mp") ? 5 : 1;
			stats[s] = Math.min(max, stats[s] + amt);
			potsDrunk++;
			g.msg("+" + amt + " " + Data.STAT_NAMES[s] + (stats[s] >= max ? " (MAXED!)" : ""), Data.STAT_COLORS[s]);
			g.floatText(x, y - 1.2, "+" + amt + " " + Data.STAT_NAMES[s], Ui.GOLD);
			return true;
		}

		/** Returns the first empty inventory slot or -1. */
		public function freeSlot():int {
			for (var i:int = 0; i < inv.length; i++) if (!inv[i]) return i;
			return -1;
		}

		public function gainXp(amount:int, g:Game):void {
			totalXp += amount;
			if (level >= MAX_LEVEL) return;
			xp += amount;
			while (xp >= xpNext && level < MAX_LEVEL) {
				xp -= xpNext;
				level++;
				xpNext = 30 + level * 30;
				for each (var s:String in Data.STATS) {
					stats[s] = Math.min(cls.max[s], stats[s] + cls.grow[s] * (0.8 + Math.random() * 0.4));
				}
				hp = maxHp;
				mp = maxMp;
				g.floatText(x, y - 1.4, "Level Up!", 0x60ff60);
				g.msg("You reached level " + level + "!", 0x60ff60);
				g.burst(x, y, 0x60ff60, 20);
			}
			if (level >= MAX_LEVEL) xp = 0;
		}

		public function takeHit(raw:int, src:String, g:Game):void {
			if (invulnT > 0) return;
			var d:int = Math.max(raw - def, int(raw * 0.15));
			hp -= d;
			hitT = 0.12;
			lastHitBy = src;
			g.floatText(x, y - 1.1, "-" + d, 0xff3030);
		}
	}
}
