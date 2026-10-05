package realm {
	import flash.display.BitmapData;
	import flash.ui.Keyboard;

	public class Player {
		public static const MAX_LEVEL:int = 20;
		public static const MAX_POTS:int = 6;
		public static const R:Number = 0.3;
		public static const SURGE_MAX:int = 100;

		public var cls:Object;
		public var name:String;
		public var x:Number, y:Number;
		public var hp:Number, mp:Number;
		/** Valor's Protection shield (white bar under MP); absorbs damage before HP. */
		public var pt:Number = 0;
		/** Valor's Surge: +2 per nearby kill, refills PT at 100. */
		public var surge:int = 0;
		public var stats:Object = {};
		public var weapon:Object, ability:Object, armor:Object, ring:Object;
		public var inv:Array = [null, null, null, null, null, null, null, null];
		/** RotMG backpack: 8 extra inventory slots (bought at the Marketplace). */
		public var backpack:Boolean = false;
		/** Which 8-slot page of the inventory the HUD shows (and keys 1-8 use). */
		public var packPage:int = 0;
		public var hpPots:int = 2, mpPots:int = 0;
		public var level:int = 1, xp:int = 0, xpNext:int = 60, totalXp:int = 0;
		public var kills:int = 0, bossKills:int = 0, potsDrunk:int = 0;
		/** Lifetime counters for the death fame bonuses. */
		public var dungeons:int = 0, elders:int = 0, godKills:int = 0, shotsFired:int = 0, shotsHit:int = 0;
		public var bossDmg:int = 0;
		public var facingLeft:Boolean = false;
		public var autoFire:Boolean = false;
		public var invulnT:Number = 2;
		public var invisT:Number = 0;
		public var berserkT:Number = 0;
		public var hitT:Number = 0;
		public var lastHitBy:String = "";
		public var aimX:Number = 0, aimY:Number = 0;
		public var moving:Boolean = false;
		public var burning:Boolean = false;
		public var shotCount:int = 0;
		/** Status effect timers (Valor/RotMG conditions). */
		public var status:Object = {slowed: 0, paralyzed: 0, confused: 0, armorbroken: 0, bleeding: 0};
		public static const STATUS_TIME:Object = {slowed: 3, paralyzed: 1.2, confused: 2.5, armorbroken: 4, bleeding: 3};
		public static const STATUS_NAMES:Object = {slowed: "Slowed", paralyzed: "Paralyzed", confused: "Confused", armorbroken: "Armor Broken", bleeding: "Bleeding"};
		public static const STATUS_COLORS:Object = {slowed: 0x6090ff, paralyzed: 0xffe040, confused: 0xd060ff, armorbroken: 0xb0b0b0, bleeding: 0xff3030};
		/** Saved-character id. */
		public var id:String;
		/** Skill tree ranks by skill id, unspent points and progress to the next point. */
		public var skills:Object = {};
		public var skillPoints:int = 0;
		public var ascXp:int = 0;

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
			pt = maxPt;
		}

		/** Most equipped pieces of any one set. */
		public function get setPieces():int {
			var counts:Object = {}, n:int = 0;
			for each (var it:Object in [weapon, ability, armor, ring]) if (it && it.set) {
				counts[it.set] = (counts[it.set] || 0) + 1;
				n = Math.max(n, counts[it.set]);
			}
			return n;
		}

		/** The set whose 4-piece bonus is active, or null. */
		public function get activeSet():String {
			return setPieces >= 4 ? weapon.set : null;
		}

		/** Stat bonus from all equipped gear (and the 4-piece set bonus). */
		public function bonus(s:String):int {
			var b:int = 0;
			for each (var it:Object in [weapon, ability, armor, ring]) if (it && it[s]) b += it[s];
			var set:String = activeSet;
			if (set && Data.setBonus(set)[s]) b += Data.setBonus(set)[s];
			for (var sk:String in Data.SKILL_STATS) {
				if (skills[sk] && Data.SKILL_STATS[sk][s]) b += skills[sk] * Data.SKILL_STATS[sk][s];
			}
			return b;
		}

		public function stat(s:String):int { return int(stats[s] || 0) + bonus(s); }

		public function get maxHp():int { return stat("hp"); }
		public function get maxMp():int { return stat("mp"); }
		public function get att():int { return stat("att"); }
		public function get def():int { return status.armorbroken > 0 ? 0 : stat("def"); }
		public function get spd():int { return stat("spd"); }
		public function get dex():int { return stat("dex"); }
		public function get vit():int { return stat("vit"); }
		public function get wis():int { return stat("wis"); }
		public function get mgt():int { return stat("mgt"); }
		public function get luc():int { return stat("luc"); }
		public function get prt():int { return stat("prt"); }
		public function get frt():int { return bonus("frt"); }
		/** Every +1 Protection gives about +3 PT. */
		public function get maxPt():int { return prt * 3; }
		/** Base 5%, +1% per 10 Luck (and +10% from the Executioner passive). */
		public function get critChance():Number { return 0.05 + luc / 1000 + (weapon.passive == "critical" ? 0.1 : 0) + rank("precision") * 0.02; }
		/** Base x1.5, +0.1 per 10 Might. */
		public function get critMult():Number { return 1.5 + mgt / 100 + rank("ferocity") * 0.1; }
		public function get damageMult():Number { return 1 + rank("brutality") * 0.05; }
		public function get leech():int { return rank("leech"); }
		public function rank(id:String):int { return int(skills[id] || 0); }

		/** Valor's Ascension: level 20 with all 11 stats maxed unlocks the skill tree. */
		public function get ascended():Boolean { return level >= MAX_LEVEL && maxedCount >= 11; }

		public function spendSkill(id:String, g:Game):void {
			if (!ascended) { g.msg("The skill tree unlocks at level 20 with 11/11 stats.", 0xaaaaaa); return; }
			if (skillPoints <= 0) { g.msg("No skill points. Keep earning XP to gain more.", 0xaaaaaa); return; }
			for each (var sk:Object in Data.SKILLS) {
				if (sk.id != id) continue;
				if (rank(id) >= sk.max) { g.msg(sk.name + " is already at max rank.", Ui.GOLD); return; }
				skills[id] = rank(id) + 1;
				skillPoints--;
				g.msg(sk.name + " rank " + skills[id] + "/" + sk.max + " (" + sk.desc + ")", 0x80e0ff);
			}
		}

		// ------------------------------------------------------------ save / load
		private static const SAVE_FIELDS:Array = ["id", "name", "level", "xp", "xpNext", "totalXp", "kills", "bossKills", "potsDrunk",
			"hpPots", "mpPots", "surge", "backpack", "dungeons", "elders", "godKills", "shotsFired", "shotsHit", "skillPoints", "ascXp", "weapon", "ability", "armor", "ring", "inv", "stats", "skills"];

		public function serialize():Object {
			var o:Object = {cls: cls.id, hp: int(hp), mp: int(mp)};
			for each (var f:String in SAVE_FIELDS) o[f] = this[f];
			return Save.clone(o);
		}

		public function restore(o:Object):void {
			o = Save.clone(o);
			for each (var f:String in SAVE_FIELDS) if (o[f] != undefined) this[f] = o[f];
			while (inv.length < (backpack ? 16 : 8)) inv.push(null);
			for each (var s:String in Data.STATS) if (stats[s] == undefined) stats[s] = cls.base[s];
			hp = maxHp;
			mp = maxMp;
			pt = maxPt;
		}
		public function get fame():int { return int(totalXp / 8 + kills * 0.5 + bossKills * 150 + potsDrunk * 5); }

		/** Count of the 11 potionable stats that are maxed ("11/11"). */
		public function get maxedCount():int {
			var n:int = 0;
			for each (var s:String in Data.STATS) if (stats[s] >= cls.max[s]) n++;
			return n;
		}

		/** Current animation frame bitmap. */
		public function get sprite():BitmapData {
			var frame:int = 0;
			if (attackT > 0) frame = shootT > (1 / fireRate) * 0.5 ? 2 : 0;
			else if (moving) frame = int(walkT * 6) % 2;
			return hitT > 0 ? Sprites.hit(cls.id, frame, facingLeft) : Sprites.get(cls.id, frame, facingLeft);
		}

		public function get fireRate():Number {
			return (1.5 + 6.5 * dex / 75) * weapon.rate * (berserkT > 0 ? 1.5 : 1);
		}

		public function update(dt:Number, g:Game):void {
			var inp:Input = g.input;
			var w:World = g.world;
			if (invulnT > 0) invulnT -= dt;
			if (invisT > 0) invisT -= dt;
			if (berserkT > 0) berserkT -= dt;
			if (hitT > 0) hitT -= dt;
			if (shootT > 0) shootT -= dt;
			if (attackT > 0) attackT -= dt;
			if (abilityT > 0) abilityT -= dt;
			for (var st:String in status) if (status[st] > 0) status[st] -= dt;

			// --- movement
			var mx:Number = 0, my:Number = 0;
			if (inp.isDown(Keyboard.W) || inp.isDown(Keyboard.UP)) my -= 1;
			if (inp.isDown(Keyboard.S) || inp.isDown(Keyboard.DOWN)) my += 1;
			if (inp.isDown(Keyboard.A) || inp.isDown(Keyboard.LEFT)) mx -= 1;
			if (inp.isDown(Keyboard.D) || inp.isDown(Keyboard.RIGHT)) mx += 1;
			if (mx != 0 && my != 0) { mx *= 0.7071; my *= 0.7071; }
			if (status.confused > 0) { mx = -mx; my = -my; }
			if (status.paralyzed > 0) { mx = 0; my = 0; }
			var speed:Number = (4 + 5.6 * (spd / 75)) * (berserkT > 0 ? 1.25 : 1) * (status.slowed > 0 ? 0.5 : 1);
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
				if (shootT <= 0) { shoot(g); Sfx.play("shoot", 0.5, 0.09); }
			} else if (mx != 0) {
				facingLeft = mx < 0;
			}

			// --- ability / potions / misc
			if (inp.pressed(Keyboard.SPACE)) useAbility(g);
			if (inp.pressed(Keyboard.F)) drinkHp(g);
			if (inp.pressed(Keyboard.G)) drinkMp(g);
			for (var k:int = 0; k < 8; k++) if (inp.pressed(49 + k)) useItem(packPage * 8 + k, g);
			if (inp.pressed(Keyboard.R)) g.nexus();

			// --- regen (bleeding drains instead)
			if (status.bleeding > 0) {
				hp -= 18 * dt;
				lastHitBy = lastHitBy || "Bleeding";
			} else hp = Math.min(maxHp, hp + (1 + vit * 0.12) * dt);
			mp = Math.min(maxMp, mp + (0.5 + wis * 0.06) * dt);
			if (pt > maxPt) pt = maxPt;
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
				shotsFired++;
			}
			// Rampage passive: every 12th shot also fires a ring
			if (w.passive == "rampage" && ++shotCount % 12 == 0) {
				var ring:Vector.<BitmapData> = Sprites.projectile("star", w.col, 3);
				for (k = 0; k < 10; k++) {
					var dmg2:int = int((w.dmin + w.dmax) / 2 * mult);
					g.addShot(new Projectile(x, y, k * Math.PI / 5, w.spd * 0.8, w.life, dmg2, false, 0.25, ring, true, name, null, true));
				}
			}
		}

		private function useAbility(g:Game):void {
			var ab:Object = cls.ability;
			if (abilityT > 0) return;
			if (mp < ab.cost) { g.msg("Not enough MP for " + ability.name, 0x8080ff); return; }
			if (g.world.isSafe(x, y) && cls.id != "priest") return;
			mp -= ab.cost;
			abilityT = 0.5;
			Sfx.play("ability");
			attackT = 0.3;
			var pow:Number = ability.power;
			var i:int, a:Number, dmg:int;
			var ang:Number = Math.atan2(aimY - y, aimX - x);
			var dx:Number = aimX - x, dy:Number = aimY - y;
			var d:Number = Math.sqrt(dx * dx + dy * dy);
			if (d > 9) { dx *= 9 / d; dy *= 9 / d; }
			switch (cls.abilityType) {
				case "spell":
					dmg = (55 + level * 7) * pow;
					var bolt:Vector.<BitmapData> = Sprites.projectile("bolt", 0xff8040, 4);
					for (i = 0; i < 20; i++) {
						a = i * Math.PI * 2 / 20;
						g.addShot(new Projectile(x + dx, y + dy, a, 8, 0.4, dmg, false, 0.25, bolt, false, name, null));
					}
					g.burst(x + dx, y + dy, 0xff8040, 16);
					break;
				case "quiver":
					dmg = (100 + level * 12) * pow;
					g.addShot(new Projectile(x, y, ang, 17, 0.75, dmg, false, 0.4, Sprites.projectile("arrow", 0xffff80, 7), true, name, "slow"));
					break;
				case "shield":
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
				case "tome":
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
				case "cloak":
					invisT = 3 * Math.sqrt(pow);
					g.floatText(x, y - 1.2, "Invisible", 0xc0a0ff);
					g.burst(x, y, 0x8060c0, 14);
					break;
				case "helm":
					berserkT = 5 * Math.sqrt(pow);
					g.floatText(x, y - 1.2, "Berserk!", 0xff5040);
					g.burst(x, y, 0xff4030, 14);
					break;
				case "skull":
					dmg = (70 + level * 8) * pow;
					var hits:int = g.blastAt(x + dx, y + dy, 3, dmg);
					var drain:int = Math.min(maxHp - int(hp), 15 * hits + 20);
					hp = Math.min(maxHp, hp + drain);
					if (drain > 0) g.floatText(x, y - 1.2, "+" + drain, 0x60ff60);
					g.burst(x + dx, y + dy, 0xa0ff60, 24);
					break;
				case "trap":
					g.throwTrap(x, y, x + dx, y + dy, int((60 + level * 7) * pow));
					break;
			}
		}

		public function drinkHp(g:Game, fromInv:Boolean = false):Boolean {
			if (!fromInv && hpPots <= 0) { g.msg("No health potions! Buy them at the Marketplace.", 0xff8080); return false; }
			if (hp >= maxHp) { g.msg("HP is already full.", 0xaaaaaa); return false; }
			if (!fromInv) hpPots--;
			var before:int = int(hp);
			hp = Math.min(maxHp, hp + 100);
			g.floatText(x, y - 1.2, "+" + (int(hp) - before), 0x60ff60);
			return true;
		}

		public function drinkMp(g:Game, fromInv:Boolean = false):Boolean {
			if (!fromInv && mpPots <= 0) { g.msg("No magic potions! Buy them at the Marketplace.", 0x8080ff); return false; }
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
				case "material":
					g.msg("Take Sor Crystals to the Sor Forge in the Nexus.", 0xc080ff);
					return;
			}
			hp = Math.min(hp, maxHp);
			mp = Math.min(mp, maxMp);
			g.msg("Equipped " + item.name, item.rarity ? Data.RARITY_COLORS[item.rarity] : 0xffffff);
			if (activeSet && item.set) g.msg(Data.setName(activeSet) + " Set bonus active!", 0xff9a2e);
		}

		public function drinkStat(s:String, g:Game):Boolean {
			var max:Number = cls.max[s];
			if (stats[s] >= max) { g.msg(Data.STAT_NAMES[s] + " is already maxed!", Ui.GOLD); return false; }
			var amt:int = (s == "hp" || s == "mp") ? 5 : 1;
			stats[s] = Math.min(max, stats[s] + amt);
			potsDrunk++;
			if (maxedCount >= 11) g.questEvent("maxed");
			g.questEvent("pots");
			g.msg("+" + amt + " " + Data.STAT_NAMES[s] + (stats[s] >= max ? " (MAXED!)" : "") + "   " + maxedCount + "/11", Data.STAT_COLORS[s]);
			g.floatText(x, y - 1.2, "+" + amt + " " + Data.STAT_NAMES[s], Ui.GOLD);
			return true;
		}

		/** Returns the first empty inventory slot or -1. */
		public function freeSlot():int {
			for (var i:int = 0; i < inv.length; i++) if (!inv[i]) return i;
			return -1;
		}

		/** Surge: +2 for each enemy killed near you; at 100 it refills Protection. */
		public function addSurge(g:Game):void {
			surge += 2;
			if (surge >= SURGE_MAX) {
				surge = 0;
				pt = maxPt;
				g.floatText(x, y - 1.4, "Surge!", 0xf0f0ff);
			}
		}

		public function gainXp(amount:int, g:Game):void {
			totalXp += amount;
			if (ascended) {
				ascXp += amount;
				while (ascXp >= Data.XP_PER_SKILL_POINT) {
					ascXp -= Data.XP_PER_SKILL_POINT;
					skillPoints++;
					g.floatText(x, y - 1.4, "+1 Skill Point", 0x80e0ff);
					g.msg("You earned a skill point! Spend it in the Skills tab.", 0x80e0ff);
				}
			}
			if (level >= MAX_LEVEL) return;
			xp += amount;
			while (xp >= xpNext && level < MAX_LEVEL) {
				xp -= xpNext;
				level++;
				xpNext = 30 + level * 30;
				for each (var s:String in Data.STATS) {
					stats[s] = Math.min(cls.max[s], stats[s] + Data.grow(cls, s) * (0.8 + Math.random() * 0.4));
				}
				hp = maxHp;
				mp = maxMp;
				g.floatText(x, y - 1.4, "Level Up!", 0x60ff60);
				Sfx.play("level");
				g.msg("You reached level " + level + "!", 0x60ff60);
				if (level >= MAX_LEVEL) g.questEvent("level20");
				if (level >= MAX_LEVEL) g.tip("max", "Level 20! Drink stat potions to max all 11 stats; 11/11 unlocks the skill tree (star tab).");
				g.burst(x, y, 0x60ff60, 20);
			}
			if (level >= MAX_LEVEL) xp = 0;
		}

		/** Text for the active status effects, e.g. "Slowed  Bleeding". */
		public function get statusText():String {
			var out:String = "";
			for (var s:String in STATUS_NAMES) {
				if (status[s] > 0) out += (out ? "  " : "") + "<font color='" + Ui.hex(STATUS_COLORS[s]) + "'>" + STATUS_NAMES[s] + "</font>";
			}
			return out;
		}

		public function takeHit(raw:int, src:String, g:Game, effect:String = null):void {
			if (invulnT > 0) return;
			if (effect && STATUS_TIME[effect] != undefined) {
				if (status[effect] <= 0) {
					g.floatText(x, y - 1.5, STATUS_NAMES[effect], STATUS_COLORS[effect]);
					Sfx.play("status");
				}
				status[effect] = STATUS_TIME[effect];
			}
			var d:int = Math.max(raw - def, int(raw * 0.15));
			// Protection absorbs damage first
			if (pt > 0) {
				var absorbed:int = Math.min(int(pt), d);
				pt -= absorbed;
				d -= absorbed;
				if (d <= 0) {
					g.floatText(x, y - 1.1, "-" + absorbed, 0xd8d8e8);
					return;
				}
			}
			hp -= d;
			if (d >= maxHp * 0.15) g.shake(0.25, Math.min(10, 3 + d / maxHp * 20));
			hitT = 0.12;
			lastHitBy = src;
			g.floatText(x, y - 1.1, "-" + d, 0xff3030);
			Sfx.play("hurt", 0.7, 0.08);
		}
	}
}
