package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;

	public class Game extends Sprite {
		public static const VIEW_W:int = Ui.W - Hud.W;
		public static const VIEW_H:int = Ui.H;
		public static const TS:int = 40;
		private static const CX:int = VIEW_W / 2;
		private static const CY:int = VIEW_H / 2 + 20;
		private static const MAX_ENEMIES_NEAR:int = 15;
		public static const SOVEREIGN:String = "Mad Sovereign";

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
		public var shots:Vector.<Projectile> = new Vector.<Projectile>();
		public var parts:Vector.<Particle> = new Vector.<Particle>();
		public var nearBag:LootBag;
		public var nexusWorld:World;
		/** Realms reachable from the nexus portals (created on first entry). */
		public var realms:Array = [null, null, null];
		public var realmNames:Array = [];
		private var portals:Array = [];
		private var nearPortal:Object;
		private var vaultBag:LootBag;
		private var vaultLabel:TextField;
		private var promptPanel:Sprite;
		private var promptTf:TextField;
		public var camX:Number, camY:Number;
		public var time:Number = 0;

		private var canvas:BitmapData;
		private var floatLayer:Sprite;
		private var floaters:Vector.<Floater> = new Vector.<Floater>();
		private var hud:Hud;
		private var chat:TextField;
		private var chatLines:Array = [];
		private var lastZone:int = -2;
		private var banner:TextField;
		private var bannerT:Number = 0;
		private var bossPanel:Sprite;
		private var bossName:TextField, bossInfo:TextField;
		private var bossBar:Shape, dmgBar:Shape;
		private var dmgTf:TextField;
		private var nameTag:TextField;
		private var fameTf:TextField, killTf:TextField;
		private var statusTf:TextField;
		private var pauseLayer:Sprite;
		private var paused:Boolean = false;
		private var lastT:int;
		private var spawnT:Number = 0;
		private var revealT:Number = 0;
		private var tauntT:Number = 30;
		private var deathInfo:Object;
		private var onDeath:Function;
		private var mtx:Matrix = new Matrix();
		private var pt:Point = new Point();
		private var bar:Rectangle = new Rectangle();
		private var drawList:Array = [];

		public function Game(clsId:String, name:String, onDeath:Function) {
			this.onDeath = onDeath;
			world = nexusWorld = new World("nexus", "Nexus");
			player = new Player(clsId, name, world.spawnX, world.spawnY);
			var pool:Array = Data.REALM_NAMES.concat();
			for (var ri:int = 0; ri < 3; ri++) realmNames.push(pool.splice(int(Math.random() * pool.length), 1)[0]);
			camX = player.x;
			camY = player.y;
			world.reveal(player.x, player.y, 14);

			canvas = new BitmapData(VIEW_W, VIEW_H, false, 0);
			addChild(new Bitmap(canvas));
			floatLayer = new Sprite();
			floatLayer.mouseEnabled = floatLayer.mouseChildren = false;
			addChild(floatLayer);
			nameTag = Ui.text(13, 0xffe36e, true, "center", 140, true);
			nameTag.text = name;
			addChild(nameTag);

			statusTf = Ui.text(14, 0xff9a40, true, "center", 200, true);
			addChild(statusTf);

			chat = Ui.text(15, 0xffffff, false, "left", 620, true);
			chat.x = 8;
			addChild(chat);

			banner = Ui.text(30, Ui.GOLD, true, "center", VIEW_W, true);
			banner.y = 110;
			banner.visible = false;
			addChild(banner);

			buildCounters();
			buildBossPanel();
			buildNexus();

			hud = new Hud(this);
			hud.x = VIEW_W;
			addChild(hud);

			pauseLayer = new Sprite();
			pauseLayer.graphics.beginFill(0x000000, 0.6);
			pauseLayer.graphics.drawRect(0, 0, Ui.W, Ui.H);
			pauseLayer.graphics.endFill();
			var pt1:TextField = Ui.text(40, 0xffffff, true, "center", Ui.W, true);
			pt1.text = "Paused";
			pt1.y = 240;
			pauseLayer.addChild(pt1);
			var pt2:TextField = Ui.text(16, 0xcccccc, false, "center", Ui.W, true);
			pt2.text = "Press P or Esc to resume";
			pt2.y = 296;
			pauseLayer.addChild(pt2);
			pauseLayer.visible = false;
			pauseLayer.mouseEnabled = false;
			pauseLayer.mouseChildren = false;
			addChild(pauseLayer);

			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		private function buildCounters():void {
			var fameIcon:Bitmap = new Bitmap(Sprites.get("fame"));
			var skull:Bitmap = new Bitmap(Sprites.get("skull"));
			fameTf = Ui.text(17, 0xffffff, true, "right", 120, true);
			killTf = Ui.text(17, 0xffffff, true, "right", 120, true);
			fameTf.x = VIEW_W - 160; fameTf.y = 8;
			killTf.x = VIEW_W - 160; killTf.y = 32;
			fameIcon.x = VIEW_W - 36; fameIcon.y = 10;
			skull.x = VIEW_W - 36; skull.y = 34;
			addChild(fameTf); addChild(killTf); addChild(fameIcon); addChild(skull);
		}

		private function buildBossPanel():void {
			// damage meter, styled like the RotMG/Valor boss leaderboard
			bossPanel = new Sprite();
			Ui.panel(bossPanel.graphics, 0, 0, 290, 100, 0x2a2a2a, 0x454545, 0.85);
			bossName = Ui.text(20, 0xc83030, true, "center", 290, true);
			bossName.y = 2;
			bossPanel.addChild(bossName);
			bossBar = new Shape();
			bossBar.x = 12; bossBar.y = 34;
			bossPanel.addChild(bossBar);
			var icon:Bitmap = new Bitmap(Sprites.get(player.cls.id));
			icon.scaleX = icon.scaleY = 0.45;
			icon.x = 10; icon.y = 50;
			bossPanel.addChild(icon);
			dmgBar = new Shape();
			dmgBar.x = 36; dmgBar.y = 54;
			bossPanel.addChild(dmgBar);
			dmgTf = Ui.text(14, 0xffffff, true, "left", 244, true);
			dmgTf.x = 40; dmgTf.y = 52;
			bossPanel.addChild(dmgTf);
			bossInfo = Ui.text(11, 0x7fd07f, true, "center", 290, true);
			bossInfo.y = 78;
			bossPanel.addChild(bossInfo);
			bossPanel.x = 10; bossPanel.y = 10;
			bossPanel.visible = false;
			bossPanel.mouseEnabled = bossPanel.mouseChildren = false;
			addChild(bossPanel);
		}

		// per-world state lives on the World, so each realm keeps its own monsters and loot
		public function get enemies():Vector.<Enemy> { return world.enemies; }
		public function get bags():Vector.<LootBag> { return world.bags; }
		public function get boss():Enemy { return world.boss; }
		public function set boss(e:Enemy):void { world.boss = e; }
		public function get killsToBoss():int { return world.killsToBoss; }
		public function set killsToBoss(n:int):void { world.killsToBoss = n; }
		public function get bossGoal():int { return world.bossGoal; }
		public function set bossGoal(n:int):void { world.bossGoal = n; }
		public function get inNexus():Boolean { return world == nexusWorld; }

		private static const PORTAL_COLORS:Array = [0x4aa8ff, 0xff5ac8, 0x5ae06a];

		private function buildNexus():void {
			var px:Array = [90.5, 100.5, 110.5];
			for (var i:int = 0; i < 3; i++) {
				var lab:TextField = Ui.text(13, 0xffffff, true, "center", 160, true);
				addChildAt(lab, getChildIndex(floatLayer));
				portals.push({x: px[i], y: 84.2, idx: i, label: lab});
			}
			var saved:Array = Save.data.vault as Array;
			var items:Array = [];
			if (saved) for each (var it:Object in saved) if (it && items.length < LootBag.MAX) items.push(it);
			vaultBag = new LootBag(83.5, 100.5, items);
			vaultBag.vault = true;
			vaultBag.refresh();
			nexusWorld.bags.push(vaultBag);
			vaultLabel = Ui.text(13, Ui.GOLD, true, "center", 120, true);
			vaultLabel.text = "Vault";
			addChildAt(vaultLabel, getChildIndex(floatLayer));

			promptPanel = new Sprite();
			Ui.panel(promptPanel.graphics, 0, 0, 280, 78, 0x262626, 0x6a6a6a, 0.94);
			promptTf = Ui.text(17, 0xffffff, true, "center", 280, true);
			promptTf.y = 6;
			promptPanel.addChild(promptTf);
			var btn:Sprite = Ui.button("Enter", 120, 30, function():void { if (nearPortal) enterPortal(nearPortal.idx); });
			btn.x = 80; btn.y = 40;
			promptPanel.addChild(btn);
			promptPanel.x = (VIEW_W - 280) / 2;
			promptPanel.y = VIEW_H - 250;
			promptPanel.visible = false;
			addChild(promptPanel);
		}

		private function saveVault():void {
			Save.data.vault = vaultBag.items.concat();
			Save.flush();
		}

		private function realmStatus(i:int):String {
			var r:World = realms[i];
			if (!r) return "New realm";
			if (r.boss) return "Overlord is awake!";
			return "Overlord " + (r.bossGoal - r.killsToBoss) + "/" + r.bossGoal;
		}

		/** Walk through a nexus portal into its realm. */
		public function enterPortal(i:int):void {
			var r:World = realms[i];
			if (!r || r.closed) {
				if (r && r.closed) {
					var pool:Array = Data.REALM_NAMES.filter(function(n:String, ...a):Boolean { return realmNames.indexOf(n) < 0; });
					realmNames[i] = pool[int(Math.random() * pool.length)];
				}
				r = realms[i] = new World("realm", realmNames[i]);
			}
			switchWorld(r, r.spawnX, r.spawnY);
			showBanner(r.name + " Realm", PORTAL_COLORS[i], 3);
			msg("You have entered the " + r.name + " realm.", Ui.GOLD);
			taunt(r.boss ? "My Overlord awaits you in the Godlands, fool!" : "Another fool enters my " + r.name + " realm...");
		}

		private function switchWorld(w:World, x:Number, y:Number):void {
			world = w;
			player.x = x;
			player.y = y;
			player.invulnT = 1.5;
			shots.length = 0;
			parts.length = 0;
			for each (var f:Floater in floaters) f.tf.visible = false;
			nearBag = null;
			nearPortal = null;
			lastZone = -2;
			camX = x;
			camY = y;
			world.reveal(x, y, 14);
			var nx:Boolean = inNexus;
			for each (var p:Object in portals) p.label.visible = nx;
			vaultLabel.visible = nx;
		}

		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			input = new Input(stage);
			lastT = getTimer();
			addEventListener(Event.ENTER_FRAME, tick);
			showBanner("Nexus", 0xffffff, 2.5);
			msg("Welcome to the Nexus, " + player.name + "!", Ui.GOLD);
			msg("Walk into a portal to the north and press Enter to travel to a realm.", 0xcccccc);
			msg("The fountain heals you. The vault (west) keeps items between characters.", 0xcccccc);
			msg("In a realm: WASD move, mouse shoots, SPACE ability, F/G potions, R returns to the Nexus.", 0xcccccc);
		}

		public function destroy():void {
			removeEventListener(Event.ENTER_FRAME, tick);
			if (input) input.dispose();
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
			updateOverlays();
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
			if (!inNexus) updateSpawns(dt);
			updateNexus(dt);

			revealT -= dt;
			if (revealT <= 0) {
				revealT = 0.25;
				world.reveal(player.x, player.y, 14);
			}

			if (!inNexus) tauntT -= dt;
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
				if (lastZone != -2) showBanner(Data.ZONE_NAMES[z], [0xffe8a0, 0x9cff7a, 0x5ad05a, 0xd090ff, 0xffffff, 0xffffff][z], 2.5);
				lastZone = z;
			}

			camX = player.x;
			camY = player.y;

			if (player.hp <= 0 && !deathInfo) die();
		}

		private function updateNexus(dt:Number):void {
			if (inNexus) {
				// healing fountain
				if (world.tileAt(player.x, player.y) == World.FOUNTAIN) {
					player.hp = Math.min(player.maxHp, player.hp + player.maxHp * 0.6 * dt);
					player.mp = Math.min(player.maxMp, player.mp + player.maxMp * 0.6 * dt);
				}
				nearPortal = null;
				for each (var p:Object in portals) {
					var dx:Number = p.x - player.x, dy:Number = p.y - player.y;
					if (dx * dx + dy * dy < 1.3 * 1.3) nearPortal = p;
				}
				if (nearPortal && input.pressed(Keyboard.ENTER)) enterPortal(nearPortal.idx);
			} else if (world.closeT > 0) {
				var before:int = Math.ceil(world.closeT);
				world.closeT -= dt;
				var after:int = Math.ceil(world.closeT);
				if (after != before && (after == 10 || after <= 5) && after > 0) msg("Realm closing in " + after + "...", 0xff8080);
				if (world.closeT <= 0) {
					world.closed = true;
					msg("The " + world.name + " realm has closed.", 0xff8080);
					nexus();
				}
			}
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
			if (d > e.hp) d = Math.ceil(e.hp);
			e.hp -= d;
			e.hitT = 0.08;
			if (e.isBoss) player.bossDmg += d;
			floatText(e.x, e.y - e.r - 0.6, String(d), 0xff4040);
			if (s.effect == "slow") e.slowT = 3;
			sparks(s.x, s.y, e.def.col, 2);
			if (e.hp <= 0) killEnemy(e);
		}

		private function killEnemy(e:Enemy):void {
			e.dead = true;
			player.kills++;
			player.gainXp(e.def.xp, this);
			burst(e.x, e.y, e.def.col, e.isBoss ? 60 : 12);
			if (e.isBoss) {
				player.bossKills++;
				boss = null;
				showBanner("The Cube Overlord has fallen!", Ui.GOLD, 4);
				say(SOVEREIGN, "Impossible... my Overlord! You will pay for this!");
				msg("A white bag has dropped! The realm closes in 30 seconds - grab your loot.", 0xffffff);
				world.closeT = 30;
				killsToBoss = bossGoal = 60;
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
				if (!b.vault) b.life -= dt;
				if (!b.vault && (b.life <= 0 || b.items.length == 0)) {
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
				f.y -= dt * 1.4;
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
			for (var tries:int = 0; tries < 6; tries++) {
				var a:Number = Math.random() * Math.PI * 2;
				var r:Number = 14 + Math.random() * 8;
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
					player.bossDmg = 0;
					showBanner("The Cube Overlord has appeared in the Godlands!", 0xff70ff, 4);
					say(SOVEREIGN, "My Cube Overlord will crush you, insects! Face it in the Godlands!");
					msg("Find it on the minimap (magenta marker). It guards a white bag.", 0xff70ff);
					return;
				}
			}
		}

		public function bossPhase(phase:int):void {
			if (phase == 1) say("Cube Overlord", "You dare wound me? Rise, my cubelets!");
			else if (phase == 2) say("Cube Overlord", "ENOUGH! Feel the full wrath of the Cube!");
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
				name: p.name, cls: p.cls.name, clsId: p.cls.id, level: p.level, fame: fame, best: best,
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

		/** R key / temple button: return to the Nexus (full heal). */
		public function nexus():void {
			var wasNexus:Boolean = inNexus;
			switchWorld(nexusWorld, nexusWorld.spawnX, nexusWorld.spawnY);
			player.hp = player.maxHp;
			player.mp = player.maxMp;
			if (!wasNexus) showBanner("Nexus", 0xffffff, 2);
			msg("You return to the Nexus. HP and MP restored.", 0xffffff);
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
				if (nearBag.vault) saveVault();
			} else if (kind == "inv") {
				item = p.inv[idx];
				if (!item) return;
				if (shift) {
					p.inv[idx] = null;
					dropAtPlayer(item);
				} else {
					p.useItem(idx, this);
				}
			} else if (kind == "pot") {
				if (idx == 0) p.drinkHp(this); else p.drinkMp(this);
			}
		}

		private function dropAtPlayer(item:Object):void {
			if (nearBag && nearBag.items.length < LootBag.MAX) {
				nearBag.items.push(item);
				nearBag.refresh();
				if (nearBag.vault) { saveVault(); msg("Stored " + item.name + " in your vault.", Ui.GOLD); }
				else nearBag.life = 45;
			} else if (nearBag && nearBag.vault) {
				player.inv[player.inv.indexOf(null)] = item;
				msg("Your vault is full.", 0xff8080);
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

		/** System message in the chat log. */
		public function msg(text:String, color:uint = 0xffffff):void {
			pushChat("<font color='" + Ui.hex(color) + "'>" + text + "</font>");
		}

		/** NPC speech: "<Name> text" with the name in orange. */
		public function say(who:String, text:String):void {
			pushChat("<font color='" + Ui.hex(Ui.NPC) + "'><b>&lt;" + who + "&gt;</b></font> <b>" + text + "</b>");
		}

		public function taunt(text:String):void {
			say(SOVEREIGN, text);
		}

		private function pushChat(line:String):void {
			chatLines.push(line);
			while (chatLines.length > 7) chatLines.shift();
			chat.htmlText = chatLines.join("\n");
			chat.y = VIEW_H - chat.height - 6;
		}

		private function showBanner(text:String, color:uint, secs:Number):void {
			banner.text = text;
			banner.textColor = color;
			banner.visible = true;
			banner.alpha = 1;
			bannerT = secs;
		}

		private function updateOverlays():void {
			fameTf.text = Ui.commas(player.fame);
			killTf.text = Ui.commas(player.kills);
			statusTf.text = player.burning ? "Burning!" : "";
			promptPanel.visible = nearPortal != null;
			if (nearPortal) {
				promptTf.htmlText = realmNames[nearPortal.idx] + " Realm<font size='13' color='#aaaaaa'>  -  press Enter</font>";
			}
			statusTf.x = CX - 100;
			statusTf.y = CY - 76;

			var b:Enemy = boss;
			var show:Boolean = b != null && !b.dead;
			if (show) {
				var dx:Number = b.x - player.x, dy:Number = b.y - player.y;
				show = dx * dx + dy * dy < 22 * 22 || b.hp < b.maxHp;
			}
			bossPanel.visible = show;
			if (show) {
				bossName.text = b.def.name;
				var frac:Number = Math.max(0, b.hp / b.maxHp);
				var g:* = bossBar.graphics;
				g.clear();
				g.beginFill(0x111111);
				g.drawRoundRect(0, 0, 266, 10, 4, 4);
				g.beginFill(0xc82828);
				g.drawRoundRect(0, 0, 266 * frac, 10, 4, 4);
				g.endFill();
				var pct:Number = player.bossDmg / b.maxHp * 100;
				var dg:* = dmgBar.graphics;
				dg.clear();
				dg.beginFill(0x1a1a1a);
				dg.drawRoundRect(0, 0, 242, 20, 6, 6);
				dg.beginFill(0x2f8fc8);
				dg.drawRoundRect(0, 0, Math.max(8, 242 * pct / 100), 20, 6, 6);
				dg.endFill();
				dmgTf.htmlText = player.name + "<font color='#dddddd'>   " + Ui.commas(player.bossDmg) + " (" + pct.toFixed(2) + "%)</font>";
				bossInfo.text = "Boss HP: " + (frac * 100).toFixed(1) + "%";
			}
		}

		// ------------------------------------------------------------- render
		public function screenToWorldX(sx:Number):Number { return camX + (sx - CX) / TS; }
		public function screenToWorldY(sy:Number):Number { return camY + (sy - CY) / TS; }

		private function render():void {
			var ox:Number = Math.round(CX - camX * TS);
			var oy:Number = Math.round(CY - camY * TS);
			canvas.lock();
			canvas.fillRect(canvas.rect, 0xff101820);
			mtx.a = mtx.d = TS / World.PX;
			mtx.tx = ox;
			mtx.ty = oy;
			canvas.draw(world.bitmap, mtx, null, null, null, false);

			var bd:BitmapData;
			// loot bags lie on the ground
			for each (var b:LootBag in bags) {
				if (b.life < 8 && int(b.life * 4) % 2 == 0) continue;
				drawEntity(Sprites.get(b.spr), b.x * TS + ox, b.y * TS + oy, 0);
			}

			// nexus portals and labels
			if (inNexus) {
				for each (var p:Object in portals) {
					var pcx:Number = p.x * TS + ox, pcy:Number = p.y * TS + oy;
					var pbd:BitmapData = Sprites.portal(PORTAL_COLORS[p.idx], int(time * 8));
					var ptop:Number = drawEntity(pbd, pcx, pcy, 0);
					var lab:TextField = p.label;
					lab.htmlText = realmNames[p.idx] + "\n<font size='11' color='#cccccc'>" + realmStatus(p.idx) + "</font>";
					lab.x = int(pcx - lab.width / 2);
					lab.y = int(ptop - lab.height - 2);
				}
				vaultLabel.x = int(vaultBag.x * TS + ox - vaultLabel.width / 2);
				vaultLabel.y = int(vaultBag.y * TS + oy - 58);
			}

			// y-sorted: world objects, enemies, player
			drawList.length = 0;
			var tx0:int = int(camX - CX / TS) - 1, tx1:int = int(camX + (VIEW_W - CX) / TS) + 1;
			var ty0:int = int(camY - CY / TS) - 1, ty1:int = int(camY + (VIEW_H - CY) / TS) + 3;
			for (var ty:int = ty0; ty <= ty1; ty++) {
				for (var tx:int = tx0; tx <= tx1; tx++) {
					var o:int = world.objAt(tx, ty);
					if (o > 0) drawList.push({y: ty + 0.9, o: o, x: tx});
				}
			}
			for each (var e:Enemy in enemies) {
				var sx:Number = e.x * TS + ox, sy:Number = e.y * TS + oy;
				if (sx < -100 || sy < -100 || sx > VIEW_W + 100 || sy > VIEW_H + 120) continue;
				drawList.push({y: e.y, e: e});
			}
			drawList.push({y: player.y, p: true});
			drawList.sortOn("y", Array.NUMERIC);

			for each (var d:Object in drawList) {
				if (d.o) {
					bd = Sprites.get(World.OBJ_NAMES[d.o]);
					var baseY:Number = (d.y + 0.1) * TS + oy;
					var sh:BitmapData = Sprites.shadow(TS);
					pt.x = int(d.x * TS + ox);
					pt.y = int(baseY - sh.height * 0.7);
					canvas.copyPixels(sh, sh.rect, pt, null, null, true);
					pt.x = int(d.x * TS + ox + TS / 2 - bd.width / 2);
					pt.y = int(baseY - bd.height);
					canvas.copyPixels(bd, bd.rect, pt, null, null, true);
				} else if (d.e) {
					drawEnemy(d.e, ox, oy);
				} else {
					drawPlayer(ox, oy);
				}
			}

			for each (var s:Projectile in shots) {
				bd = s.frame(time);
				pt.x = int(s.x * TS + ox - bd.width / 2);
				pt.y = int(s.y * TS + oy - bd.height / 2);
				if (pt.x < -bd.width || pt.y < -bd.height || pt.x > VIEW_W || pt.y > VIEW_H) continue;
				canvas.copyPixels(bd, bd.rect, pt, null, null, true);
			}
			for each (var q:Particle in parts) {
				pt.x = q.x * TS + ox - 3;
				pt.y = q.y * TS + oy - 3;
				canvas.copyPixels(q.bd, q.bd.rect, pt, null, null, false);
			}
			canvas.unlock();

			for each (var f:Floater in floaters) {
				if (!f.tf.visible) continue;
				f.tf.x = f.x * TS + ox - f.tf.width / 2;
				f.tf.y = f.y * TS + oy - f.tf.height / 2;
			}
		}

		/** Draws a sprite standing at (cx, cy) with its drop shadow; returns the sprite top. */
		private function drawEntity(bd:BitmapData, cx:Number, cy:Number, bob:int):Number {
			var foot:Number = cy + TS * 0.4;
			var sh:BitmapData = Sprites.shadow(int(bd.width * 0.7));
			pt.x = int(cx - sh.width / 2);
			pt.y = int(foot - sh.height / 2);
			canvas.copyPixels(sh, sh.rect, pt, null, null, true);
			pt.x = int(cx - bd.width / 2);
			pt.y = int(foot - bd.height + 2 - bob);
			canvas.copyPixels(bd, bd.rect, pt, null, null, true);
			return pt.y;
		}

		private function drawEnemy(e:Enemy, ox:Number, oy:Number):void {
			var cx:Number = e.x * TS + ox, cy:Number = e.y * TS + oy;
			var bob:int = e.moving && int(time * 5 + e.homeX) % 2 == 0 ? 2 : 0;
			var top:Number = drawEntity(e.sprite, cx, cy, bob);
			if (e.hp < e.maxHp) {
				var bw:int = e.isBoss ? 80 : 36;
				hpBar(cx - bw / 2, cy + TS * 0.4 + 6, bw, e.hp / e.maxHp);
			}
			if (e.stunT > 0) statusPip(cx, top - 6, 0xfff0f040);
			else if (e.slowT > 0) statusPip(cx, top - 6, 0xff60a0ff);
		}

		private function drawPlayer(ox:Number, oy:Number):void {
			var p:Player = player;
			var cx:Number = p.x * TS + ox, cy:Number = p.y * TS + oy;
			if (!(p.invulnT > 0 && int(time * 12) % 2 == 0)) drawEntity(p.sprite, cx, cy, 0);
			nameTag.x = int(cx - nameTag.width / 2);
			nameTag.y = int(cy + TS * 0.4 + 1);
			hpBar(cx - 20, cy + TS * 0.4 + 21, 40, p.hp / p.maxHp);
		}

		private function statusPip(cx:Number, y:Number, color:uint):void {
			bar.x = int(cx) - 7; bar.y = int(y) - 1; bar.width = 14; bar.height = 6;
			canvas.fillRect(bar, 0xff000000);
			bar.x += 1; bar.y += 1; bar.width -= 2; bar.height -= 2;
			canvas.fillRect(bar, color);
		}

		private function hpBar(x:Number, y:Number, w:int, frac:Number):void {
			if (frac < 0) frac = 0;
			bar.x = int(x) - 1; bar.y = int(y) - 1; bar.width = w + 2; bar.height = 6;
			canvas.fillRect(bar, 0xff101010);
			bar.x = int(x); bar.y = int(y); bar.width = Math.max(1, int(w * frac)); bar.height = 4;
			canvas.fillRect(bar, frac > 0.5 ? 0xff2ec22e : frac > 0.25 ? 0xffe0c020 : 0xffe02020);
		}
	}
}
