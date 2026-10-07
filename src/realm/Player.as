package realm {
	import flash.display.BitmapData;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;

	public class Player {
		public static const MAX_LEVEL:int = 20;
		public static const MAX_POTS:int = 6;
		public static const R:Number = 0.3;
		public static const SURGE_MAX:int = 100;

		public var cls:Object;
		public var name:String;
		public var x:Number, y:Number;
		public var hp:Number, mp:Number;
		/** Protection shield (white bar under MP); absorbs damage before HP. */
		public var pt:Number = 0;
		/** Surge: +2 per nearby kill, refills PT at 100. */
		public var surge:int = 0;
		public var stats:Object = {};
		public var weapon:Object, ability:Object, armor:Object, ring:Object;
		public var inv:Array = [null, null, null, null, null, null, null, null];
		/** RotMG backpack: 8 extra inventory slots (bought at the Marketplace). */
		public var backpack:Boolean = false;
		/** Equipped skin id, or "" for the class's default look. */
		public var skin:String = "";
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
		/** Shield Wall: time left and where the shield stands. */
		public var shieldT:Number = 0, shieldX:Number = 0, shieldY:Number = 0;
		/** Shadowstep: the next hit is a Backstab. */
		public var critNext:Boolean = false;
		private var dashT:Number = 0, dashVx:Number = 0, dashVy:Number = 0, dashDmg:int = 0, dashPow:Number = 1;
		private var dashHits:Dictionary;
		public var hitT:Number = 0;
		public var lastHitBy:String = "";
		public var aimX:Number = 0, aimY:Number = 0;
		public var moving:Boolean = false;
		public var burning:Boolean = false;
		public var shotCount:int = 0;
		/** Status effect timers (RotMG-style conditions). */
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
		private var dustT:Number = 0;
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
			return setPieces >= 4 && weapon ? weapon.set : null;
		}

		/** Stat bonus from all equipped gear (and the 4-piece set bonus). */
		public function bonus(s:String):int {
			var b:int = 0;
			// a weapon's "spd" is its bullet speed, not a Speed bonus
			for each (var it:Object in [weapon, ability, armor, ring]) if (it && it[s] && !(s == "spd" && it.kind == "weapon")) b += it[s];
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
		public function get critChance():Number { return 0.05 + luc / 1000 + (weapon && weapon.passive == "critical" ? 0.1 : 0) + rank("precision") * 0.02; }
		/** Base x1.5, +0.1 per 10 Might. */
		public function get critMult():Number { return 1.5 + mgt / 100 + rank("ferocity") * 0.1; }
		public function get damageMult():Number { return (1 + rank("brutality") * 0.05) * (buffs.might > 0 ? 1.3 : 1) * (bloodT > 0 ? 1 + bloodStacks * 0.06 : 1); }
		/** Bloodlust stacks (from kills) and how long they last. */
		public var bloodStacks:int = 0, bloodT:Number = 0;
		public var lastStandT:Number = 0;
		/** High Stakes is switched on (needs the skill). */
		public var highStakes:Boolean = false;
		/** Characters made before the skill tree rework get their level-up points once. */
		public var tree2:Boolean = true;

		/** Shrine blessings: seconds left of might, haste, fortune, vigor and arcana. */
		public var buffs:Object = {};
		public function get leech():int { return rank("leech"); }
		public function rank(id:String):int { return int(skills[id] || 0); }

		/** Ascension: level 20 with all 11 stats maxed. */
		public function get ascended():Boolean { return level >= MAX_LEVEL && maxedCount >= 11; }

		/** Why this skill can't take another rank right now, or null. */
		public function skillBlock(id:String):String {
			var sk:Object = Data.skill(id);
			if (!sk) return "Unknown skill.";
			if (rank(id) >= sk.max) return sk.name + " is already at max rank.";
			var par:Object = Data.skillParent(id);
			if (par && rank(par.id) < 2) return "Needs 2 ranks in " + par.name + " first.";
			if (sk.cap && level < MAX_LEVEL) return "Capstones unlock at level 20.";
			if (skillPoints <= 0) return "No skill points. You get one per level, then one every " + Data.XP_PER_SKILL_POINT + " XP at level 20.";
			return null;
		}

		public function spendSkill(id:String, g:Game):Boolean {
			var why:String = skillBlock(id);
			if (why) { g.msg(why, 0xaaaaaa); return false; }
			var sk:Object = Data.skill(id);
			skills[id] = rank(id) + 1;
			skillPoints--;
			if (id == "highstakes") highStakes = true;
			g.msg(sk.name + (sk.max > 1 ? " rank " + skills[id] + "/" + sk.max : " unlocked") + " (" + sk.desc + ")", 0x80e0ff);
			Sfx.play("level", 0.6);
			return true;
		}

		/** Gives back every point spent in the tree. */
		public function resetSkills():int {
			var n:int = 0;
			for (var id:String in skills) n += rank(id);
			skills = {};
			skillPoints += n;
			highStakes = false;
			return n;
		}

		// ------------------------------------------------------------ save / load
		private static const SAVE_FIELDS:Array = ["id", "name", "level", "xp", "xpNext", "totalXp", "kills", "bossKills", "potsDrunk",
			"hpPots", "mpPots", "surge", "backpack", "skin", "dungeons", "elders", "godKills", "shotsFired", "shotsHit", "skillPoints", "ascXp", "highStakes", "tree2", "weapon", "ability", "armor", "ring", "inv", "stats", "skills"];

		public function serialize():Object {
			var o:Object = {cls: cls.id, hp: int(hp), mp: int(mp)};
			for each (var f:String in SAVE_FIELDS) o[f] = this[f];
			return Save.clone(o);
		}

		public function restore(o:Object):void {
			o = Save.clone(o);
			o.tree2 = o.tree2 || false;
			for each (var f:String in SAVE_FIELDS) if (o[f] != undefined) this[f] = o[f];
			if (!tree2) { tree2 = true; skillPoints += level - 1; }
			while (inv.length < (backpack ? 16 : 8)) inv.push(null);
			// items saved before the renames keep their old names; refresh them
			for each (var it:Object in inv) if (it && it.kind == "material") it.name = "Star Shard";
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
			return hitT > 0 ? Sprites.hit(spriteId, frame, facingLeft) : Sprites.get(spriteId, frame, facingLeft);
		}

		public function get spriteId():String {
			return skin || cls.id;
		}

		public function get fireRate():Number {
			return (1.5 + 6.5 * dex / 75) * (weapon ? weapon.rate : 1) * (berserkT > 0 ? 1.5 : 1);
		}

		public function update(dt:Number, g:Game):void {
			var inp:Input = g.input;
			var w:World = g.world;
			if (invulnT > 0) invulnT -= dt;
			if (invisT > 0) invisT -= dt;
			if (berserkT > 0) berserkT -= dt;
			if (bloodT > 0) { bloodT -= dt; if (bloodT <= 0) bloodStacks = 0; }
			if (lastStandT > 0) lastStandT -= dt;
			if (shieldT > 0) shieldT -= dt;
			if (hitT > 0) hitT -= dt;
			if (shootT > 0) shootT -= dt;
			if (attackT > 0) attackT -= dt;
			if (abilityT > 0) abilityT -= dt;
			for (var st:String in status) if (status[st] > 0) status[st] -= dt;
			for (var bf:String in buffs) if (buffs[bf] > 0) buffs[bf] -= dt;
			if (buffs.vigor > 0 && hp > 0) hp = Math.min(maxHp, hp + maxHp * 0.04 * dt);
			if (buffs.arcana > 0) mp = Math.min(maxMp, mp + maxMp * 0.1 * dt);

			// --- movement
			var mx:Number = 0, my:Number = 0;
			if (inp.isDown(Keys.k("up")) || inp.isDown(Keyboard.UP)) my -= 1;
			if (inp.isDown(Keys.k("down")) || inp.isDown(Keyboard.DOWN)) my += 1;
			if (inp.isDown(Keys.k("left")) || inp.isDown(Keyboard.LEFT)) mx -= 1;
			if (inp.isDown(Keys.k("right")) || inp.isDown(Keyboard.RIGHT)) mx += 1;
			if (mx != 0 && my != 0) { mx *= 0.7071; my *= 0.7071; }
			// movement is relative to the (possibly rotated) screen
			if (g.camAngle != 0 && (mx != 0 || my != 0)) {
				var ca:Number = Math.cos(g.camAngle), sa:Number = Math.sin(g.camAngle);
				var rmx:Number = mx * ca - my * sa;
				my = mx * sa + my * ca;
				mx = rmx;
			}
			if (status.confused > 0) { mx = -mx; my = -my; }
			if (status.paralyzed > 0) { mx = 0; my = 0; }
			if (dashT > 0) { mx = 0; my = 0; updateDash(dt, g); }
			var speed:Number = (4 + 5.6 * (spd / 75)) * (berserkT > 0 ? 1.25 : 1) * (shielded ? 0.55 : 1) * (buffs.haste > 0 ? 1.35 : 1) * (status.slowed > 0 ? 0.5 : 1) * (w.inWater(x, y) ? 0.5 : 1);
			if (mx != 0) {
				var nx:Number = x + mx * speed * dt;
				if (w.canStand(nx, y, R, false)) x = nx;
			}
			if (my != 0) {
				var ny:Number = y + my * speed * dt;
				if (w.canStand(x, ny, R, false)) y = ny;
			}
			moving = mx != 0 || my != 0;
			if (moving) {
				walkT += dt;
				// little puffs of dust from your feet
				dustT -= dt;
				if (dustT <= 0 && !w.inWater(x, y) && Game.opt("parts") && g.parts.length < 380) {
					dustT = 0.2;
					var ground:uint = World.MINI_COL[w.tileAt(x, y)] || 0x808080;
					g.parts.push(new Particle(x + (Math.random() - 0.5) * 0.3, y + 0.3, -mx * 0.8, -0.5, 0.35, Sprites.glow(Sprites.tint(ground, 0.35))));
				}
			}

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
			aimX = g.screenToWorldX(inp.mx, inp.my);
			aimY = g.screenToWorldY(inp.my, inp.mx);

			// --- shooting
			if (inp.pressed(Keys.k("autofire"))) {
				autoFire = !autoFire;
				g.msg("Auto-fire " + (autoFire ? "enabled" : "disabled"), 0xaaaaaa);
			}
			var wantShoot:Boolean = autoFire || (inp.mouseDown && inp.mx < Game.VIEW_W && !g.uiCaptured());
			if (wantShoot && !w.isSafe(x, y)) {
				facingLeft = inp.mx / g.zoom < g.scrX(x, y);
				attackT = 0.25;
				if (shootT <= 0) { shoot(g); Sfx.play("shoot", 0.5, 0.09); }
			} else if (mx != 0) {
				facingLeft = mx < 0;
			}

			// --- ability / potions / misc
			if (inp.pressed(Keys.k("ability"))) useAbility(g);
			if (inp.pressed(Keys.k("hp"))) drinkHp(g);
			if (inp.pressed(Keys.k("mp"))) drinkMp(g);
			if (!g.trading) for (var k:int = 0; k < 8; k++) if (inp.pressed(Keys.k("slot" + (k + 1)))) useItem(packPage * 8 + k, g);
			if (inp.pressed(Keys.k("nexus"))) g.nexus();

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
			if (!w) { shootT = 0.5; g.tip("noweapon", "You have no weapon equipped. Click or drag one into your weapon slot."); return; }
			shootT = 1 / fireRate;
			var ang:Number = Math.atan2(aimY - y, aimX - x);
			var mult:Number = 0.5 + att / 50;
			var frames:Vector.<BitmapData> = Sprites.projectile(w.shape, w.col, w.size || (w.sub == "sword" ? 4 : 3));
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
				var shot:Projectile = new Projectile(x + ox, y + oy, a, w.spd, w.life, dmg, false, 0.25 + (w.form == "heavy" ? 0.12 : 0), frames, w.pierce, name, null);
				shot.motion = w.motion;
				if (k % 2 == 1) shot.phase = Math.PI;
				g.addShot(shot);
				shotsFired++;
			}
			g.net.shoot(ang);
			// muzzle flash at the tip of the weapon
			if (Game.opt("parts") && g.parts.length < 400) {
				var mf:BitmapData = Sprites.glow(Sprites.tint(w.col, 0.5));
				for (k = 0; k < 2; k++) g.parts.push(new Particle(x + Math.cos(ang) * 0.45, y + Math.sin(ang) * 0.45, Math.cos(ang + (Math.random() - 0.5)) * 3, Math.sin(ang + (Math.random() - 0.5)) * 3, 0.1, mf));
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
			if (!ability) { g.msg("Equip an ability item first.", 0xff8080); abilityT = 0.5; return; }
			var cost:int = Math.ceil(ab.cost * (1 - rank("arcane") * 0.06));
			if (mp < cost) { g.msg("Not enough MP for " + ability.name, 0x8080ff); return; }
			if (g.world.isSafe(x, y) && cls.id != "priest") return;
			mp -= cost;
			abilityT = 0.5;
			Sfx.play("ability", 0.5);
			attackT = 0.3;
			var pow:Number = ability.power;
			var i:int, a:Number, dmg:int;
			var ang:Number = Math.atan2(aimY - y, aimX - x);
			var dx:Number = aimX - x, dy:Number = aimY - y;
			var d:Number = Math.sqrt(dx * dx + dy * dy);
			if (d > 9) { dx *= 9 / d; dy *= 9 / d; }
			switch (cls.abilityType) {
				case "spell":
					// Fireball: a slow ball of flame that bursts where it hits (or at the cursor)
					dmg = (130 + level * 16) * pow;
					var fb:Projectile = new Projectile(x, y, ang, 12, Math.max(0.15, Math.sqrt(dx * dx + dy * dy) / 12), 0, false, 0.4,
						Sprites.projectile("fire", 0xff7020, 5), false, name, null);
					fb.ghost = true;
					fb.boom = {r: 2.6 * Math.sqrt(pow), dmg: dmg};
					g.addShot(fb);
					g.abil.show("fireball", x, y, x + dx, y + dy, 0, true);
					break;
				case "quiver":
					// Arrow Storm: arrows rain down over the target area and slow what they hit
					dmg = (40 + level * 5) * pow;
					var cxs:Number = x + dx, cys:Number = y + dy;
					g.abil.show("storm", x, y, cxs, cys, 0, true);
					for (i = 0; i < 6; i++) {
						var ra:Number = Math.random() * Math.PI * 2, rr:Number = Math.sqrt(Math.random()) * 2.2;
						var ao:Object = {dmg: dmg};
						ao.fn = arrowHit(g, ao);
						g.abil.anim("arrow", cxs + Math.cos(ra) * rr, cys + Math.sin(ra) * rr, 0.3 + i * 0.12, ao);
					}
					break;
				case "shield":
					// Shield Wall: plant the shield; bullets from the front stop on it, you take less damage behind it but move slower
					shieldT = 4 * Math.sqrt(pow);
					shieldX = x + Math.cos(ang) * 0.9;
					shieldY = y + Math.sin(ang) * 0.9;
					g.abil.show("shield", x, y, shieldX, shieldY, shieldT, true);
					var n:int = g.stunAround(shieldX + Math.cos(ang) * 1.2, shieldY + Math.sin(ang) * 1.2, 2.2, 1.5 * Math.sqrt(pow));
					if (n > 0) g.floatText(x, y - 1.2, "Bashed x" + n, 0xffff60);
					g.shake(0.15, 4);
					break;
				case "tome":
					// Sanctuary: a holy circle that heals you while you stand in it and burns monsters inside
					var amount:int = (40 + level * 4) * pow;
					var heal:int = Math.min(amount, maxHp - int(hp));
					hp = Math.min(maxHp, hp + amount);
					if (heal > 0) g.floatText(x, y - 1.2, "+" + heal, 0x60ff60);
					var life:Number = 5 * Math.sqrt(pow);
					g.abil.addZone(x, y, 3, life, (20 + level * 2.5) * pow, (10 + level * 1.2) * pow);
					g.abil.show("sanctuary", x, y, x, y, life, true);
					break;
				case "cloak":
					// Shadowstep: vanish in smoke, reappear at the cursor; your next hit is a guaranteed Backstab
					var sx0:Number = x, sy0:Number = y;
					var reach:Number = Math.min(6, Math.sqrt(dx * dx + dy * dy));
					var stx:Number = Math.cos(ang), sty:Number = Math.sin(ang);
					for (var st:Number = 0.1; st <= reach; st += 0.1) {
						if (!g.world.canStand(sx0 + stx * st, sy0 + sty * st, R, false)) break;
						x = sx0 + stx * st;
						y = sy0 + sty * st;
					}
					invisT = 2 * Math.sqrt(pow);
					critNext = true;
					g.abil.show("shadow", sx0, sy0, x, y, 0, true);
					break;
				case "helm":
					// Berserker Charge: rush forward through monsters, then go berserk
					dashT = 0.3;
					dashVx = Math.cos(ang) * 22;
					dashVy = Math.sin(ang) * 22;
					dashDmg = (60 + level * 8) * pow;
					dashPow = pow;
					dashHits = new Dictionary(true);
					invulnT = Math.max(invulnT, 0.3);
					g.abil.show("charge", x, y, x + dashVx * dashT, y + dashVy * dashT, 0, true);
					break;
				case "skull":
					// Soul Harvest: a draining blast, and two spirit skulls circle you and shoot
					dmg = (70 + level * 8) * pow;
					var hits:int = g.blastAt(x + dx, y + dy, 3, dmg);
					var drain:int = Math.min(maxHp - int(hp), 15 * hits + 20);
					hp = Math.min(maxHp, hp + drain);
					if (drain > 0) g.floatText(x, y - 1.2, "+" + drain, 0x60ff60);
					g.abil.addSpirits(2, 5 * Math.sqrt(pow), (18 + level * 2.5) * pow);
					g.abil.show("harvest", x, y, x + dx, y + dy, 0, true);
					break;
				case "trap":
					// Snare: the trap roots monsters in vines, then bursts into slowing shards
					g.abil.show("snare", x, y, x + dx, y + dy, 0, true);
					var tdmg:int = int((60 + level * 7) * pow);
					var tx:Number = x + dx, ty:Number = y + dy;
					g.abil.anim("land", tx, ty, 0.35, {fn: function():void { g.throwTrap(tx, ty, tx, ty, tdmg); }});
					break;
			}
		}

		/** One Arrow Storm arrow landing. */
		private function arrowHit(g:Game, af:Object):Function {
			return function():void {
				g.blastAt(af.x, af.y, 1.3, af.dmg, "slow");
				g.burst(af.x, af.y, 0xffffa0, 6);
			};
		}

		/** True while you stand behind your planted Shield Wall. */
		public function get shielded():Boolean {
			if (shieldT <= 0) return false;
			var sx:Number = x - shieldX, sy:Number = y - shieldY;
			return sx * sx + sy * sy < 2.2 * 2.2;
		}

		/** Berserker Charge in progress: you rush forward and hit what you touch. */
		private function updateDash(dt:Number, g:Game):void {
			dashT -= dt;
			for (var k:int = 0; k < 3; k++) {
				var nx:Number = x + dashVx * dt / 3, ny:Number = y + dashVy * dt / 3;
				if (!g.world.canStand(nx, ny, R, false)) { dashT = 0; break; }
				x = nx; y = ny;
			}
			if (Game.opt("parts") && g.parts.length < 420) g.parts.push(new Particle(x, y, 0, 0, 0.25, Sprites.glow(0xff5030)));
			for each (var e:Enemy in g.enemies.concat()) {
				if (e.dead || dashHits[e]) continue;
				var ex:Number = e.x - x, ey:Number = e.y - y, er:Number = e.r + 0.7;
				if (ex * ex + ey * ey < er * er) {
					dashHits[e] = true;
					g.hurtEnemy(e, dashDmg, null, e.x, e.y);
					g.burst(e.x, e.y, 0xff5030, 8);
					g.shake(0.1, 3);
				}
			}
			if (dashT <= 0) {
				berserkT = 4 * Math.sqrt(dashPow);
				g.ring(x, y, 0xff4030, 20);
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
				case "key":
					if (Data.keyDungeon(item) >= 0 ? g.useDungeonKey(item) : g.useRaidKey(item)) { inv[idx] = null; g.saveCharacter(); }
					return;
				case "material":
					g.msg("Take Star Shards to the Starforge in the Nexus.", 0xc080ff);
					return;
			}
			hp = Math.min(hp, maxHp);
			mp = Math.min(mp, maxMp);
			g.msg("Equipped " + item.name, item.rarity ? Data.RARITY_COLORS[item.rarity] : 0xffffff);
			if (activeSet && item.set) g.msg(Data.setName(activeSet) + " Set bonus active!", Data.RARITY_COLORS.st);
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
				g.floatText(x, y - 1.4, "Fervor!", 0xf0f0ff);
			}
		}

		public function gainXp(amount:int, g:Game):void {
			totalXp += amount;
			if (level >= MAX_LEVEL) {
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
				skillPoints++;
				g.msg("You reached level " + level + "! +1 skill point (press T for the skill tree).", 0x60ff60);
				if (level >= MAX_LEVEL) g.questEvent("level20");
				if (level >= MAX_LEVEL) g.tip("max", "Level 20! Drink stat potions to max all 11 stats. Skill tree capstones (T) are now unlocked.");
				g.burst(x, y, 0x60ff60, 20);
				g.ring(x, y, 0xffe040);
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
			if (invulnT > 0 || g.godMode) return;
			if (effect && STATUS_TIME[effect] != undefined) {
				if (status[effect] <= 0) {
					g.floatText(x, y - 1.5, STATUS_NAMES[effect], STATUS_COLORS[effect]);
					Sfx.play("status");
				}
				status[effect] = STATUS_TIME[effect];
			}
			var d:int = Math.max(raw - def, int(raw * 0.15));
			if (shielded) d = Math.max(1, int(d * 0.4));
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
			if (hp <= 0 && rank("laststand") > 0 && lastStandT <= 0) {
				hp = 1;
				invulnT = 2;
				lastStandT = 60;
				g.floatText(x, y - 1.5, "Last Stand!", 0x60a8ff);
				g.ring(x, y, 0x60a8ff, 24);
				Sfx.play("level");
			}
			if (d >= maxHp * 0.15) g.shake(0.25, Math.min(10, 3 + d / maxHp * 20));
			hitT = 0.12;
			lastHitBy = src;
			g.floatText(x, y - 1.1, "-" + d, 0xff3030);
			Sfx.play("hurt", 0.7, 0.08);
		}
	}
}
