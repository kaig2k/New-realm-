package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;

	public class Game extends Sprite {
		public static const VIEW:int = 600;
		public static const TS:int = 32;
		private static const HALF:int = VIEW / 2;
		private static const MAX_ENEMIES_NEAR:int = 14;

		private static const TAUNTS:Array = [
			"You are but an insect in my realm!",
			"My minions will feast upon your bones.",
			"Another fool wanders into my lands...",
			"I have slain heroes far mightier than you.",
			"Enjoy your little potions while you can.",
			"The Godlands await you, little one. Come closer."
		];

		public var world:World;
		public var player:Player;
		public var input:Input;
		public var enemies:Vector.<Enemy> = new Vector.<Enemy>();
		public var shots:Vector.<Projectile> = new Vector.<Projectile>();
		public var bags:Vector.<LootBag> = new Vector.<LootBag>();
		public var parts:Vector.<Particle> = new Vector.<Particle>();
		public var boss:Enemy;
		public var nearBag:LootBag;
		public var camX:Number, camY:Number;
		public var time:Number = 0;

		private var canvas:BitmapData;
		private var floatLayer:Sprite;
		private var floaters:Vector.<Floater> = new Vector.<Floater>();
		private var hud:Hud;
		private var chat:TextField;
		private var chatLines:Array = [];
		private var zoneTf:TextField;
		private var lastZone:int = -2;
		private var banner:TextField;
		private var bannerT:Number = 0;
		private var pauseLayer:Sprite;
		private var paused:Boolean = false;
		private var lastT:int;
		private var spawnT:Number = 0;
		private var killsToBoss:int = 40;
		private var tauntT:Number = 30;
		private var deathInfo:Object;
		private var onDeath:Function;
		private var mtx:Matrix = new Matrix();
		private var pt:Point = new Point();
		private var bar:Rectangle = new Rectangle();

		public function Game(clsId:String, onDeath:Function) {
			this.onDeath = onDeath;
			world = new World();
			player = new Player(clsId, world.spawnX, world.spawnY);
			camX = player.x;
			camY = player.y;

			canvas = new BitmapData(VIEW, VIEW, false, 0);
			addChild(new Bitmap(canvas));
			floatLayer = new Sprite();
			floatLayer.mouseEnabled = floatLayer.mouseChildren = false;
			addChild(floatLayer);

			chat = Ui.text(12, 0xffffff, false, "left", 440, true);
			chat.x = 6;
			addChild(chat);

			zoneTf = Ui.text(13, 0xffffff, true, "left", 0, true);
			zoneTf.x = 6;
			zoneTf.y = 4;
			addChild(zoneTf);

			banner = Ui.text(24, 0xffd75e, true, "center", VIEW, true);
			banner.y = 120;
			banner.visible = false;
			addChild(banner);

			hud = new Hud(this);
			hud.x = VIEW;
			addChild(hud);

			pauseLayer = new Sprite();
			pauseLayer.graphics.beginFill(0x000000, 0.6);
			pauseLayer.graphics.drawRect(0, 0, 800, 600);
			pauseLayer.graphics.endFill();
			var pt1:TextField = Ui.text(32, 0xffffff, true, "center", 800, true);
			pt1.text = "PAUSED";
			pt1.y = 230;
			pauseLayer.addChild(pt1);
			var pt2:TextField = Ui.text(14, 0xcccccc, false, "center", 800, true);
			pt2.text = "Press P or Esc to resume";
			pt2.y = 280;
			pauseLayer.addChild(pt2);
			pauseLayer.visible = false;
			pauseLayer.mouseEnabled = false;
			addChild(pauseLayer);

			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			input = new Input(stage);
			lastT = getTimer();
			addEventListener(Event.ENTER_FRAME, tick);
			msg("Welcome to the Realm, " + player.cls.name + "!", 0xffd75e);
			msg("WASD move, mouse aims & shoots, SPACE ability, F/G potions, R returns to the Haven.", 0xcccccc);
			msg("Head inland - the closer to the centre, the deadlier (and richer) the Realm.", 0xcccccc);
			taunt("Welcome to my realm, mortal. You will not leave it alive.");
		}

		public function destroy():void {
			removeEventListener(Event.ENTER_FRAME, tick);
			if (input) input.dispose();
			if (hud) hud.destroy();
		}

		// ------------------------------------------------------------------ loop
		private function tick(e:Event):void {
			var now:int = getTimer();
			var dt:Number = (now - lastT) / 1000;
			lastT = now;
			if (dt > 0.05) dt = 0.05;

			if (input.pressed(Keyboard.ESCAPE) || input.pressed(Keyboard.P)) {
				paused = !paused;
				pauseLayer.visible = paused;
			}
			if (!paused) update(dt);
			render();
			hud.refresh();
			input.endFrame();

			if (deathInfo) {
				var info:Object = deathInfo;
				deathInfo = null;
				onDeath(info);
			}
		}

		private function update(dt:Number):void {
			time += dt;
			var i:int;
			player.update(dt, this);
			for (i = enemies.length - 1; i >= 0; i--) {
				if (!enemies[i].dead) enemies[i].update(dt, this);
			}
			updateShots(dt);
			for (i = enemies.length - 1; i >= 0; i--) {
				if (enemies[i].dead) removeEnemyAt(i);
			}
			updateBags(dt);
			updateParticles(dt);
			updateFloaters(dt);
			updateSpawns(dt);

			tauntT -= dt;
			if (tauntT <= 0) {
				tauntT = 50 + Math.random() * 40;
				taunt(TAUNTS[int(Math.random() * TAUNTS.length)]);
			}
			if (bannerT > 0) {
				bannerT -= dt;
				banner.alpha = Math.min(1, bannerT);
				if (bannerT <= 0) banner.visible = false;
			}

			var z:int = world.zoneAt(player.x, player.y);
			if (z != lastZone && z >= 0) {
				lastZone = z;
				zoneTf.text = Data.ZONE_NAMES[z];
				zoneTf.textColor = [0xffe8a0, 0x9cff7a, 0x5ad05a, 0xd090ff, 0xffffff][z];
			}

			camX = player.x;
			camY = player.y;

			if (player.hp <= 0 && !deathInfo) die();
		}

		private function updateShots(dt:Number):void {
			var p:Player = player;
			for (var i:int = shots.length - 1; i >= 0; i--) {
				var s:Projectile = shots[i];
				s.x += s.vx * dt;
				s.y += s.vy * dt;
				s.life -= dt;
				var remove:Boolean = s.life <= 0;
				if (!remove) {
					if (s.enemy) {
						if (world.isSafe(s.x, s.y)) remove = true;
						else {
							var dx:Number = s.x - p.x, dy:Number = s.y - p.y, rr:Number = s.r + Player.R;
							if (dx * dx + dy * dy < rr * rr && p.invulnT <= 0) {
								p.takeHit(s.dmg, s.owner, this);
								remove = true;
							}
						}
					} else {
						for (var j:int = 0; j < enemies.length; j++) {
							var e:Enemy = enemies[j];
							if (e.dead) continue;
							var ex:Number = s.x - e.x, ey:Number = s.y - e.y, er:Number = s.r + e.r;
							if (ex * ex + ey * ey < er * er) {
								if (s.pierce) {
									if (s.hits[e]) continue;
									s.hits[e] = true;
								}
								damageEnemy(e, s);
								if (!s.pierce) { remove = true; break; }
							}
						}
					}
				}
				if (remove) {
					shots[i] = shots[shots.length - 1];
					shots.length--;
				}
			}
		}

		private function damageEnemy(e:Enemy, s:Projectile):void {
			var d:int = Math.max(s.dmg - e.defense, int(s.dmg * 0.15));
			e.hp -= d;
			e.hitT = 0.08;
			floatText(e.x, e.y - e.r - 0.3, String(d), 0xff5050);
			if (s.effect == "slow") e.slowT = 3;
			sparks(s.x, s.y, e.def.col, 2);
			if (e.hp <= 0) killEnemy(e);
		}

		private function killEnemy(e:Enemy):void {
			e.dead = true;
			player.kills++;
			player.gainXp(e.def.xp, this);
			burst(e.x, e.y, e.def.col, e.isBoss ? 60 : 10);
			if (e.isBoss) {
				player.bossKills++;
				boss = null;
				banner.text = "THE CUBE OVERLORD HAS FALLEN!";
				showBanner();
				taunt("Impossible... my Overlord! You will pay for this!");
				msg("A white bag has dropped!", 0xffffff);
				killsToBoss = 60;
			} else if (!boss && e.def.drop > 0) {
				killsToBoss--;
				if (killsToBoss <= 0) spawnBoss();
			}
			var items:Array = Data.rollLoot(e.def, Math.max(0, e.zone), player.cls);
			if (items.length) {
				while (items.length > LootBag.MAX) items.pop();
				bags.push(new LootBag(e.x, e.y, items));
			}
		}

		private function removeEnemyAt(i:int):void {
			enemies[i] = enemies[enemies.length - 1];
			enemies.length--;
		}

		private function updateBags(dt:Number):void {
			nearBag = null;
			var best:Number = 1.0;
			for (var i:int = bags.length - 1; i >= 0; i--) {
				var b:LootBag = bags[i];
				b.life -= dt;
				if (b.life <= 0 || b.items.length == 0) {
					bags[i] = bags[bags.length - 1];
					bags.length--;
					continue;
				}
				var dx:Number = b.x - player.x, dy:Number = b.y - player.y;
				var d:Number = Math.sqrt(dx * dx + dy * dy);
				if (d < best) { best = d; nearBag = b; }
			}
		}

		private function updateParticles(dt:Number):void {
			for (var i:int = parts.length - 1; i >= 0; i--) {
				var p:Particle = parts[i];
				p.x += p.vx * dt;
				p.y += p.vy * dt;
				p.vx *= 0.9;
				p.vy *= 0.9;
				p.life -= dt;
				if (p.life <= 0) {
					parts[i] = parts[parts.length - 1];
					parts.length--;
				}
			}
		}

		private function updateFloaters(dt:Number):void {
			for each (var f:Floater in floaters) {
				if (!f.tf.visible) continue;
				f.life -= dt;
				f.y -= dt * 1.2;
				if (f.life <= 0) f.tf.visible = false;
				else if (f.life < 0.3) f.tf.alpha = f.life / 0.3;
			}
		}

		private function updateSpawns(dt:Number):void {
			spawnT -= dt;
			if (spawnT > 0) return;
			spawnT = 0.6;
			var near:int = 0;
			for (var i:int = enemies.length - 1; i >= 0; i--) {
				var e:Enemy = enemies[i];
				var dx:Number = e.x - player.x, dy:Number = e.y - player.y;
				var d2:Number = dx * dx + dy * dy;
				if (!e.isBoss && d2 > 34 * 34) { removeEnemyAt(i); continue; }
				if (d2 < 24 * 24) near++;
			}
			if (near >= MAX_ENEMIES_NEAR) return;
			// try a few random spots in a ring around the player
			for (var tries:int = 0; tries < 6; tries++) {
				var a:Number = Math.random() * Math.PI * 2;
				var r:Number = 13 + Math.random() * 9;
				var sx:Number = player.x + Math.cos(a) * r;
				var sy:Number = player.y + Math.sin(a) * r;
				var z:int = world.zoneAt(sx, sy);
				if (z < 0 || z > 3 || !world.canStand(sx, sy, 0.4, true)) continue;
				var list:Array = Data.ZONE_SPAWNS[z];
				var id:String = list[int(Math.random() * list.length)];
				var count:int = 1 + int(Math.random() * (z == 3 ? 2 : 3));
				for (var k:int = 0; k < count; k++) {
					var ox:Number = sx + Math.random() * 2 - 1, oy:Number = sy + Math.random() * 2 - 1;
					if (world.canStand(ox, oy, 0.4, true)) spawnEnemy(id, ox, oy, z);
				}
				return;
			}
		}

		public function spawnEnemy(id:String, x:Number, y:Number, zone:int):Enemy {
			if (!world.canStand(x, y, 0.35, true)) return null;
			var e:Enemy = new Enemy(id, x, y, zone);
			enemies.push(e);
			return e;
		}

		private function spawnBoss():void {
			for (var tries:int = 0; tries < 400; tries++) {
				var x:Number = World.N / 2 + (Math.random() - 0.5) * 50;
				var y:Number = World.N / 2 + (Math.random() - 0.5) * 50;
				if (world.zoneAt(x, y) == 3 && world.canStand(x, y, 0.5, true)) {
					boss = new Enemy("boss", x, y, 3);
					enemies.push(boss);
					banner.text = "The Cube Overlord has appeared in the Godlands!";
					showBanner();
					taunt("My Cube Overlord will crush you, insects! Come face it in the Godlands!");
					msg("Find it on the map (magenta marker) - it guards a white bag.", 0xff70ff);
					return;
				}
			}
		}

		public function bossPhase(phase:int):void {
			if (phase == 1) taunt("You dare wound my Overlord? Rise, my cubelets!");
			else if (phase == 2) taunt("ENOUGH! Feel the full wrath of the Cube!");
		}

		private function die():void {
			var p:Player = player;
			var save:Object = Save.data;
			var fame:int = p.fame;
			var best:Boolean = fame > (save.bestFame || 0);
			if (best) save.bestFame = fame;
			save.deaths = (save.deaths || 0) + 1;
			if (!save.bestLevel) save.bestLevel = {};
			if (p.level > (save.bestLevel[p.cls.id] || 0)) save.bestLevel[p.cls.id] = p.level;
			Save.flush();
			deathInfo = {
				cls: p.cls.name, clsId: p.cls.id, level: p.level, fame: fame, best: best,
				kills: p.kills, bosses: p.bossKills, killer: p.lastHitBy || "the Realm", time: time
			};
		}

		// ------------------------------------------------------------- actions
		public function addShot(s:Projectile):void {
			shots.push(s);
		}

		public function stunAround(x:Number, y:Number, radius:Number, secs:Number):int {
			var n:int = 0;
			for each (var e:Enemy in enemies) {
				var dx:Number = e.x - x, dy:Number = e.y - y;
				if (dx * dx + dy * dy < radius * radius) {
					e.stunT = e.isBoss ? secs * 0.4 : secs;
					n++;
				}
			}
			return n;
		}

		public function nexus():void {
			player.x = world.spawnX;
			player.y = world.spawnY;
			player.hp = player.maxHp;
			player.mp = player.maxMp;
			player.invulnT = 1.5;
			msg("You return to the Safe Haven. HP and MP restored.", 0xffffff);
		}

		public function slotClick(kind:String, idx:int, shift:Boolean):void {
			var p:Player = player;
			var item:Object;
			if (kind == "bag") {
				if (!nearBag || idx >= nearBag.items.length) return;
				item = nearBag.items[idx];
				if (item.kind == "hp" && p.hpPots < Player.MAX_POTS) p.hpPots++;
				else if (item.kind == "mp" && p.mpPots < Player.MAX_POTS) p.mpPots++;
				else {
					var slot:int = p.freeSlot();
					if (slot < 0) { msg("Inventory full! Shift+click an item to drop it.", 0xff8080); return; }
					p.inv[slot] = item;
				}
				nearBag.items.splice(idx, 1);
				nearBag.refresh();
			} else if (kind == "inv") {
				item = p.inv[idx];
				if (!item) return;
				if (shift) {
					p.inv[idx] = null;
					dropAtPlayer(item);
				} else {
					p.useItem(idx, this);
				}
			}
		}

		private function dropAtPlayer(item:Object):void {
			if (nearBag && nearBag.items.length < LootBag.MAX) {
				nearBag.items.push(item);
				nearBag.refresh();
				nearBag.life = 45;
			} else {
				bags.push(new LootBag(player.x, player.y, [item]));
			}
		}

		// ------------------------------------------------------------- effects
		public function burst(x:Number, y:Number, color:uint, n:int):void {
			var bd:BitmapData = Sprites.spark(color);
			for (var i:int = 0; i < n; i++) {
				var a:Number = Math.random() * Math.PI * 2;
				var s:Number = 2 + Math.random() * 6;
				parts.push(new Particle(x, y, Math.cos(a) * s, Math.sin(a) * s, 0.3 + Math.random() * 0.4, bd));
			}
		}

		private function sparks(x:Number, y:Number, color:uint, n:int):void {
			if (parts.length > 300) return;
			burst(x, y, color, n);
		}

		public function floatText(x:Number, y:Number, text:String, color:uint):void {
			var f:Floater = null;
			for each (var c:Floater in floaters) if (!c.tf.visible) { f = c; break; }
			if (!f) {
				if (floaters.length < 50) {
					f = new Floater();
					floaters.push(f);
					floatLayer.addChild(f.tf);
				} else {
					f = floaters[0];
					floaters.push(floaters.shift());
				}
			}
			f.set(x + (Math.random() - 0.5) * 0.3, y, text, color);
		}

		public function msg(text:String, color:uint = 0xffffff):void {
			chatLines.push("<font color='" + Ui.hex(color) + "'>" + text + "</font>");
			while (chatLines.length > 6) chatLines.shift();
			chat.htmlText = chatLines.join("\n");
			chat.y = VIEW - chat.height - 4;
		}

		public function taunt(text:String):void {
			msg("<b>Mad Sovereign:</b> " + text, 0xff9040);
		}

		private function showBanner():void {
			banner.visible = true;
			banner.alpha = 1;
			bannerT = 4;
		}

		// ------------------------------------------------------------- render
		public function screenToWorldX(sx:Number):Number { return camX + (sx - HALF) / TS; }
		public function screenToWorldY(sy:Number):Number { return camY + (sy - HALF) / TS; }

		private function render():void {
			var ox:Number = Math.round(HALF - camX * TS);
			var oy:Number = Math.round(HALF - camY * TS);
			canvas.lock();
			canvas.fillRect(canvas.rect, 0xff0a1830);
			mtx.a = mtx.d = TS / World.PX;
			mtx.tx = ox;
			mtx.ty = oy;
			canvas.draw(world.bitmap, mtx, null, null, null, false);

			var i:int, bd:BitmapData;
			for each (var b:LootBag in bags) {
				bd = Sprites.get(b.spr);
				if (b.life < 8 && int(b.life * 4) % 2 == 0) continue; // blink before vanishing
				blit(bd, b.x * TS + ox, b.y * TS + oy);
			}
			for each (var e:Enemy in enemies) {
				var sx:Number = e.x * TS + ox, sy:Number = e.y * TS + oy;
				if (sx < -80 || sy < -80 || sx > VIEW + 80 || sy > VIEW + 80) continue;
				bd = e.sprite;
				blit(bd, sx, sy);
				if (e.hp < e.maxHp) {
					var bw:int = e.isBoss ? 70 : 30;
					hpBar(sx - bw / 2, sy + bd.height / 2 - 2, bw, e.hp / e.maxHp, 0xff30c030);
				}
				if (e.stunT > 0) canvas.fillRect(new Rectangle(sx - 6, sy - bd.height / 2 - 6, 12, 4), 0xffffff40);
				else if (e.slowT > 0) canvas.fillRect(new Rectangle(sx - 6, sy - bd.height / 2 - 6, 12, 4), 0xff60a0ff);
			}
			// player
			var p:Player = player;
			var psx:Number = p.x * TS + ox, psy:Number = p.y * TS + oy;
			bd = p.hitT > 0 ? Sprites.hit(p.sprite, p.facingLeft) : Sprites.get(p.sprite, p.facingLeft);
			if (!(p.invulnT > 0 && int(time * 12) % 2 == 0)) blit(bd, psx, psy);
			hpBar(psx - 16, psy + bd.height / 2 - 2, 32, p.hp / p.maxHp, 0xff30c030);
			hpBar(psx - 16, psy + bd.height / 2 + 3, 32, p.mp / p.maxMp, 0xff3070ff);

			for each (var s:Projectile in shots) {
				blit(s.bd, s.x * TS + ox, s.y * TS + oy);
			}
			for each (var q:Particle in parts) {
				pt.x = q.x * TS + ox - 2;
				pt.y = q.y * TS + oy - 2;
				canvas.copyPixels(q.bd, q.bd.rect, pt, null, null, false);
			}
			canvas.unlock();

			for each (var f:Floater in floaters) {
				if (!f.tf.visible) continue;
				f.tf.x = f.x * TS + ox - f.tf.width / 2;
				f.tf.y = f.y * TS + oy - f.tf.height / 2;
			}
		}

		private function blit(bd:BitmapData, cx:Number, cy:Number):void {
			pt.x = int(cx - bd.width / 2);
			pt.y = int(cy - bd.height / 2);
			if (pt.x > VIEW || pt.y > VIEW || pt.x < -bd.width || pt.y < -bd.height) return;
			canvas.copyPixels(bd, bd.rect, pt, null, null, true);
		}

		private function hpBar(x:Number, y:Number, w:int, frac:Number, color:uint):void {
			if (frac < 0) frac = 0;
			bar.x = int(x) - 1; bar.y = int(y) - 1; bar.width = w + 2; bar.height = 5;
			canvas.fillRect(bar, 0xff000000);
			bar.x = int(x); bar.y = int(y); bar.width = int(w * frac); bar.height = 3;
			canvas.fillRect(bar, color);
		}
	}
}
