package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
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
		public static const SOVEREIGN:String = Data.OVERLORD;
		public static const LG_THRESHOLD:Number = 5;

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
		public var arenaWorld:World;
		public var dungeonWorld:World;
		private var saveT:Number = 20;
		/** Realms reachable from the nexus portals (created on first entry). */
		public var realms:Array = [null, null, null];
		public var realmNames:Array = [];
		private var nearPortal:Object;
		private var stations:Array = [];
		private var nearStation:Object;
		private var stationPanel:Sprite;
		private var openStation:Object;
		private var traps:Array = [];
		private var petX:Number = 0, petY:Number = 0, petHealT:Number = 3;
		private var petMoving:Boolean = false;
		private var releaseArmed:Boolean = false;
		private var showAch:Boolean = false;
		private var shakeT:Number = 0, shakeAmp:Number = 0;
		private var goldTf:TextField, onraneTf:TextField;
		private var thresholdTf:TextField;
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
		/** RotMG-style quest arrow pointing at the current objective. */
		private var questArrow:Shape;
		private var questTf:TextField;
		private var questTarget:Enemy;
		private var questT:Number = 0;
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
		/** Called (by NewRealm) when the player saves and quits to the menu. */
		public var onQuit:Function;
		private var quitRequested:Boolean = false;
		private var pauseButtons:Sprite;
		private var chatInput:TextField;
		private var drawPool:Array = [];
		private var drawN:int = 0;
		private var mtx:Matrix = new Matrix();
		private var pt:Point = new Point();
		private var bar:Rectangle = new Rectangle();
		private var drawList:Array = [];

		public function Game(clsId:String, name:String, onDeath:Function, saved:Object = null) {
			this.onDeath = onDeath;
			world = nexusWorld = new World("nexus", "Nexus");
			player = new Player(clsId, name, world.spawnX, world.spawnY);
			if (saved) player.restore(saved);
			else player.id = String(new Date().time) + "_" + int(Math.random() * 100000);
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
			questArrow = new Shape();
			var qg:* = questArrow.graphics;
			qg.lineStyle(2, 0x2a1a00);
			qg.beginFill(0xffd75e);
			qg.moveTo(15, 0); qg.lineTo(-8, -10); qg.lineTo(-3, 0); qg.lineTo(-8, 10); qg.lineTo(15, 0);
			qg.endFill();
			questArrow.visible = false;
			addChild(questArrow);
			questTf = Ui.text(12, 0xffd75e, true, "center", 160, true);
			questTf.visible = false;
			addChild(questTf);
			nameTag = Ui.text(13, 0xffe36e, true, "center", 140, true);
			nameTag.text = name;
			addChild(nameTag);

			statusTf = Ui.text(14, 0xff9a40, true, "center", 320, true);
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

			buildChatInput();
			buildPauseMenu();

			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		// ------------------------------------------------------------ chat & commands
		private function buildChatInput():void {
			chatInput = Ui.text(15, 0xffffff, false, "left", 520);
			chatInput.autoSize = "none";
			chatInput.height = 24;
			chatInput.type = "input";
			chatInput.selectable = true;
			chatInput.mouseEnabled = true;
			chatInput.background = true;
			chatInput.backgroundColor = 0x1a1a1a;
			chatInput.border = true;
			chatInput.borderColor = 0x6a6a6a;
			chatInput.maxChars = 80;
			chatInput.x = 8;
			chatInput.y = VIEW_H - 30;
			chatInput.visible = false;
			chatInput.addEventListener(KeyboardEvent.KEY_DOWN, onChatKey);
			addChild(chatInput);
		}

		private function openChat():void {
			if (chatInput.visible) return;
			chatInput.text = "";
			chatInput.visible = true;
			input.blocked = true;
			stage.focus = chatInput;
			chat.y = VIEW_H - chat.height - 36;
		}

		private function closeChat():void {
			chatInput.visible = false;
			input.blocked = false;
			stage.focus = stage;
			chat.y = VIEW_H - chat.height - 6;
		}

		private function onChatKey(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.ENTER) {
				var t:String = chatInput.text.replace(/^\s+|\s+$/g, "");
				closeChat();
				if (t) runCommand(t);
			} else if (e.keyCode == Keyboard.ESCAPE) {
				closeChat();
			}
			e.stopPropagation();
		}

		/** Valor-style slash commands; anything else is said in chat. */
		public function runCommand(t:String):void {
			if (t.charAt(0) != "/") {
				pushChat("<font color='#ffe36e'><b>&lt;" + player.name + "&gt;</b></font> " + t.replace(/</g, "&lt;"));
				return;
			}
			var cmd:String = t.split(" ")[0].toLowerCase();
			switch (cmd) {
				case "/help":
					msg("Commands: /nexus  /realm  /glands  /stats  /quests  /achievements  /tips", 0x8fd0ff);
					break;
				case "/nexus": case "/n":
					nexus();
					break;
				case "/realm":
					enterPortal(int(Math.random() * 3));
					break;
				case "/glands":
					if (world.kind != "realm") { msg("/glands only works inside a realm.", 0xff8080); break; }
					for (var i:int = 0; i < 600; i++) {
						var x:Number = Math.random() * world.N, y:Number = Math.random() * world.N;
						if (world.zoneAt(x, y) == World.GOD_ZONE && world.canStand(x, y, 0.5, false)) {
							player.x = x; player.y = y; player.invulnT = 1.5;
							msg("Teleported to the Godlands.", 0xd090ff);
							Sfx.play("portal");
							return;
						}
					}
					msg("Couldn't find a spot in the Godlands.", 0xff8080);
					break;
				case "/stats":
					msg("Level " + player.level + ", " + player.maxedCount + "/11 maxed, fame " + player.fame + ", kills " + player.kills +
						", crit " + Math.round(player.critChance * 100) + "% x" + player.critMult.toFixed(2), 0x8fd0ff);
					break;
				case "/quests":
					for each (var qs:Object in questState().list) {
						var q:Object = Data.quest(qs.id);
						msg(q.text + "  " + qs.progress + "/" + q.goal + (qs.claimed ? "  (claimed)" : ""), 0x9cff7a);
					}
					break;
				case "/achievements":
				case "/ach":
					var ast:Object = achState(), nd:int = 0;
					for each (var ac:Object in Data.ACHIEVEMENTS) if (ast.done[ac.id]) nd++;
					msg("Achievements: " + nd + "/" + Data.ACHIEVEMENTS.length + " unlocked. See the Quest Board in the Nexus.", 0xffd75e);
					break;
				case "/tips":
					Save.data.tips = {};
					Save.flush();
					msg("Tips will be shown again.", 0x8fd0ff);
					break;
				default:
					msg("Unknown command " + cmd + ". Type /help.", 0xff8080);
			}
		}

		/** One-time hint for new players. */
		public function tip(id:String, text:String):void {
			if (!Save.data.tips) Save.data.tips = {};
			if (Save.data.tips[id]) return;
			Save.data.tips[id] = true;
			Save.flush();
			msg("[Tip] " + text, 0x8fd0ff);
		}

		/** Screen shake (can be turned off in the pause menu). */
		public function shake(secs:Number, amp:Number):void {
			if (!opt("shake")) return;
			if (amp >= shakeAmp || shakeT <= 0) shakeAmp = amp;
			shakeT = Math.max(shakeT, secs);
		}

		// ------------------------------------------------------------ pause / options
		public static function opt(name:String):Boolean {
			var o:Object = Save.data.opt || {};
			return o[name] !== false;
		}

		private static function setOpt(name:String, v:Boolean):void {
			if (!Save.data.opt) Save.data.opt = {};
			Save.data.opt[name] = v;
			Save.flush();
		}

		private function buildPauseMenu():void {
			pauseLayer = new Sprite();
			pauseLayer.graphics.beginFill(0x000000, 0.6);
			pauseLayer.graphics.drawRect(0, 0, Ui.W, Ui.H);
			pauseLayer.graphics.endFill();
			Ui.panel(pauseLayer.graphics, Ui.W / 2 - 170, 110, 340, 430, 0x262626, 0x6a6a6a);
			var pt1:TextField = Ui.text(34, 0xffffff, true, "center", Ui.W, true);
			pt1.text = "Paused";
			pt1.y = 122;
			pauseLayer.addChild(pt1);
			pauseButtons = new Sprite();
			pauseLayer.addChild(pauseButtons);
			pauseLayer.visible = false;
			addChild(pauseLayer);
			refreshPauseMenu();
		}

		private function refreshPauseMenu():void {
			pauseButtons.removeChildren();
			var rows:Array = [
				["Resume", function():void { setPaused(false); }],
				["Sound: " + (Sfx.muted ? "Off" : "On"), function():void { Sfx.muted = !Sfx.muted; refreshPauseMenu(); }],
				["Damage numbers: " + (opt("dmg") ? "On" : "Off"), function():void { setOpt("dmg", !opt("dmg")); refreshPauseMenu(); }],
				["Particles: " + (opt("parts") ? "On" : "Off"), function():void { setOpt("parts", !opt("parts")); refreshPauseMenu(); }],
				["Screen shake: " + (opt("shake") ? "On" : "Off"), function():void { setOpt("shake", !opt("shake")); refreshPauseMenu(); }],
				["Save & Quit to Menu", function():void { saveCharacter(); quitRequested = true; }]
			];
			for (var i:int = 0; i < rows.length; i++) {
				var b:Sprite = Ui.button(rows[i][0], 260, 42, rows[i][1], 17);
				b.x = Ui.W / 2 - 130;
				b.y = 186 + i * 56;
				pauseButtons.addChild(b);
			}
		}

		private function setPaused(v:Boolean):void {
			paused = v;
			pauseLayer.visible = v;
			if (v) refreshPauseMenu();
		}

		private function buildCounters():void {
			var icons:Array = ["fame", "gold", "onrane", "skull"];
			var tfs:Array = [];
			for (var i:int = 0; i < 4; i++) {
				var col:int = i % 2, row:int = int(i / 2);
				var tf:TextField = Ui.text(16, 0xffffff, true, "right", 90, true);
				tf.x = VIEW_W - 250 + col * 122; tf.y = 6 + row * 22;
				var ic:Bitmap = new Bitmap(Sprites.get(icons[i]));
				ic.scaleX = ic.scaleY = 0.7;
				ic.x = tf.x + 92; ic.y = tf.y + 2;
				addChild(tf); addChild(ic);
				tfs.push(tf);
			}
			fameTf = tfs[0]; goldTf = tfs[1]; onraneTf = tfs[2]; killTf = tfs[3];
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
			var icon:Bitmap = new Bitmap(Sprites.get(player.spriteId));
			icon.scaleX = icon.scaleY = 0.45;
			icon.x = 10; icon.y = 50;
			bossPanel.addChild(icon);
			dmgBar = new Shape();
			dmgBar.x = 36; dmgBar.y = 54;
			bossPanel.addChild(dmgBar);
			dmgTf = Ui.text(14, 0xffffff, true, "left", 244, true);
			dmgTf.x = 40; dmgTf.y = 52;
			bossPanel.addChild(dmgTf);
			bossInfo = Ui.text(11, 0xaaaaaa, true, "left", 140, true);
			bossInfo.x = 12; bossInfo.y = 78;
			bossPanel.addChild(bossInfo);
			thresholdTf = Ui.text(11, 0x7fd07f, true, "right", 140, true);
			thresholdTf.x = 138; thresholdTf.y = 78;
			bossPanel.addChild(thresholdTf);
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
		public function get gold():int { return int(Save.data.gold || 0); }
		public function get onrane():int { return int(Save.data.onrane || 0); }
		public function addGold(n:int):void { Save.data.gold = gold + n; }
		public function addOnrane(n:int):void { Save.data.onrane = onrane + n; }
		public function get nearMarket():Boolean { return nearStation != null && nearStation.kind == "market"; }
		public function get inNexus():Boolean { return world == nexusWorld; }

		private static const PORTAL_COLORS:Array = [0x4aa8ff, 0xff5ac8, 0x5ae06a];

		private function buildNexus():void {
			var px:Array = [90.5, 100.5, 110.5];
			for (var i:int = 0; i < 3; i++) addPortal(nexusWorld, px[i], 84.2, "realm", i, PORTAL_COLORS[i]);
			var saved:Array = Save.data.vault as Array;
			var items:Array = [];
			if (saved) for each (var it:Object in saved) if (it && items.length < LootBag.MAX) items.push(it);
			vaultBag = new LootBag(83.5, 100.5, items);
			vaultBag.vault = true;
			vaultBag.refresh();
			nexusWorld.bags.push(vaultBag);
			vaultLabel = makeLabel("Vault", Ui.GOLD);

			// Valor-style nexus stations: the Sor Forge (east) and the Marketplace (by the spawn)
			stations.push({x: 116.5, y: 100.5, kind: "forge", spr: "anvil", label: makeLabel("Sor Forge", 0xc080ff)});
			stations.push({x: 106.5, y: 111.5, kind: "market", spr: "merchant", label: makeLabel("Marketplace", 0x6fe08f)});
			stations.push({x: 94.5, y: 111.5, kind: "quests", spr: "questboard", label: makeLabel("Quest Board", 0xf0d080)});
			stations.push({x: 84.5, y: 93.5, kind: "skins", spr: "famekeeper", label: makeLabel("Fame Store", 0xff9a2e)});
			stations.push({x: 116.5, y: 93.5, kind: "pets", spr: "nest", label: makeLabel("Pet Yard", 0x60c0ff)});

			promptPanel = new Sprite();
			Ui.panel(promptPanel.graphics, 0, 0, 280, 78, 0x262626, 0x6a6a6a, 0.94);
			promptTf = Ui.text(17, 0xffffff, true, "center", 280, true);
			promptTf.y = 6;
			promptPanel.addChild(promptTf);
			var btn:Sprite = Ui.button("Enter", 120, 30, function():void { if (nearPortal) usePortal(nearPortal); });
			btn.x = 80; btn.y = 40;
			promptPanel.addChild(btn);
			promptPanel.x = (VIEW_W - 280) / 2;
			promptPanel.y = VIEW_H - 250;
			promptPanel.visible = false;
			addChild(promptPanel);

			stationPanel = new Sprite();
			stationPanel.visible = false;
			addChild(stationPanel);
		}

		private function makeLabel(text:String, color:uint):TextField {
			var lab:TextField = Ui.text(13, color, true, "center", 160, true);
			lab.htmlText = text;
			addChildAt(lab, getChildIndex(floatLayer));
			return lab;
		}

		private function addPortal(w:World, x:Number, y:Number, kind:String, idx:int, color:uint, life:Number = 0):void {
			var lab:TextField = makeLabel("", 0xffffff);
			lab.visible = w == world;
			w.portals.push({x: x, y: y, kind: kind, idx: idx, color: color, label: lab, life: life});
		}

		private function saveVault():void {
			Save.data.vault = vaultBag.items.concat();
			Save.flush();
		}

		private function realmStatus(i:int):String {
			var r:World = realms[i];
			if (!r) return "New realm";
			if (r.closed) return "Closed - new realm";
			if (r.boss) return r.boss.def.name + " is awake!";
			return "Events " + r.eventsDone + "/" + Data.EVENTS_PER_REALM;
		}

		private function portalTitle(p:Object):String {
			if (p.kind == "realm") return realmNames[p.idx] + " Realm";
			if (p.kind == "dungeon") return Data.DUNGEONS[p.idx].name;
			return "Nexus";
		}

		public function usePortal(p:Object):void {
			if (p.kind == "realm") enterPortal(p.idx);
			else if (p.kind == "dungeon") enterDungeon(p.idx);
			else nexus();
		}

		/** Valor-style dungeon: rooms of monsters with a boss at the end. */
		private function enterDungeon(idx:int):void {
			var th:Object = Data.DUNGEONS[idx];
			dungeonWorld = new World("dungeon", th.name, th);
			Sfx.play("portal");
			switchWorld(dungeonWorld, dungeonWorld.spawnX, dungeonWorld.spawnY);
			var rooms:Array = dungeonWorld.rooms;
			for (var r:int = 1; r < rooms.length - 1; r++) {
				var rm:Object = rooms[r];
				var n:int = 3 + int(Math.random() * 3);
				for (var k:int = 0; k < n; k++) {
					var mx:Number = rm.x + (Math.random() - 0.5) * (rm.w - 3);
					var my:Number = rm.y + (Math.random() - 0.5) * (rm.h - 3);
					spawnEnemy(th.mobs[int(Math.random() * th.mobs.length)], mx, my, th.tier);
				}
			}
			var tr:Object = dungeonWorld.treasure;
			if (tr) {
				spawnEnemy("treasure", tr.x + 0.5, tr.y + 0.5, th.tier);
				for (k = 0; k < 3; k++) spawnEnemy(th.mobs[int(Math.random() * th.mobs.length)], tr.x + 0.5 + (k - 1) * 2, tr.y + 2, th.tier);
			}
			var last:Object = rooms[rooms.length - 1];
			dungeonWorld.boss = new Enemy(th.boss, last.x + 0.5, last.y + 0.5, th.tier);
			dungeonWorld.enemies.push(dungeonWorld.boss);
			player.bossDmg = 0;
			showBanner(th.name, th.color, 3);
			msg("You enter the " + th.name + ". Its master waits in the last chamber.", th.color);
			saveCharacter();
		}

		/** Persist the current character (RotMG keeps characters until they die). */
		public function saveCharacter():void {
			if (deathInfo || player.hp <= 0) return;
			Save.storeChar(player.serialize());
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
			Sfx.play("portal");
			showBanner(r.name + " Realm", PORTAL_COLORS[i], 3);
			msg("You have entered the " + r.name + " realm.", Ui.GOLD);
			tip("realm", "Hold the left mouse button to shoot and dodge the bullets. Better loot lies inland; /glands jumps to the Godlands.");
			taunt(r.boss ? r.boss.def.name + " awaits you, fool!" : "Another fool enters my " + r.name + " realm...");
		}

		private function switchWorld(w:World, x:Number, y:Number):void {
			world = w;
			player.x = x;
			player.y = y;
			player.invulnT = 1.5;
			petX = x - 1; petY = y + 0.5;
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
			for each (var ow:World in [nexusWorld, realms[0], realms[1], realms[2], arenaWorld, dungeonWorld]) {
				if (ow) for each (var p:Object in ow.portals) p.label.visible = ow == world;
			}
			for each (var st:Object in stations) st.label.visible = nx;
			vaultLabel.visible = nx;
			traps.length = 0;
			closeStation();
		}

		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			input = new Input(stage);
			lastT = getTimer();
			addEventListener(Event.ENTER_FRAME, tick);
			showBanner("Nexus", 0xffffff, 2.5);
			msg((player.kills > 0 ? "Welcome back, " : "Welcome to the Nexus, ") + player.name + "!", Ui.GOLD);
			saveCharacter();
			msg("Walk into a portal to the north and press Enter to travel to a realm.", 0xcccccc);
			msg("The fountain heals you. Vault (west) stores items, Sor Forge (east) crafts Legendaries, Marketplace (south) buys and sells.", 0xcccccc);
			msg("In a realm: WASD move, mouse shoots, SPACE ability, F/G potions, R returns to the Nexus.", 0xcccccc);
			tip("nexus", "Press Enter to chat or type commands; /help lists them (try /glands in a realm).");
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

			if (input.pressed(Keyboard.M)) {
				Sfx.muted = !Sfx.muted;
				msg("Sound " + (Sfx.muted ? "muted" : "on") + " (M)", 0xaaaaaa);
			}
			if (input.pressed(Keyboard.ESCAPE) || input.pressed(Keyboard.P)) setPaused(!paused);
			if (!paused) update(dt);
			render();
			hud.refresh();
			updateOverlays();
			input.endFrame();

			if (deathInfo) {
				var info:Object = deathInfo;
				deathInfo = null;
				onDeath(info);
			} else if (quitRequested && onQuit != null) {
				quitRequested = false;
				onQuit();
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
			if (world.kind == "realm") {
				updateSpawns(dt);
				updateEvents(dt);
			}
			updateNexus(dt);
			updateTraps(dt);
			updatePet(dt);

			revealT -= dt;
			if (revealT <= 0) {
				revealT = 0.25;
				world.reveal(player.x, player.y, 14);
			}

			if (world.kind == "realm") tauntT -= dt;
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
				if (lastZone != -2) showBanner(Data.ZONE_NAMES[z], [0xffe8a0, 0x9cff7a, 0x5ad05a, 0xd8d070, 0xd090ff, 0xffffff, 0xff5050, 0xffffff, 0xffffff, 0xffffff][z], 2.5);
				lastZone = z;
			}

			camX = player.x;
			camY = player.y;

			if (player.hp <= 0 && !deathInfo) die();
		}

		private function updateNexus(dt:Number):void {
			// timed portals (dungeon entrances) vanish
			for (var pi:int = world.portals.length - 1; pi >= 0; pi--) {
				var tp:Object = world.portals[pi];
				if (tp.life > 0) {
					tp.life -= dt;
					if (tp.life <= 0) {
						if (tp.label.parent) tp.label.parent.removeChild(tp.label);
						world.portals.splice(pi, 1);
					}
				}
			}
			saveT -= dt;
			if (saveT <= 0) { saveT = 20; saveCharacter(); }
			// portals (nexus realm portals, or the exit portal in the Dark Elder's chamber)
			nearPortal = null;
			for each (var p:Object in world.portals) {
				var dx:Number = p.x - player.x, dy:Number = p.y - player.y;
				if (dx * dx + dy * dy < 1.3 * 1.3) nearPortal = p;
			}
			if (input.pressed(Keyboard.ENTER)) {
				if (nearPortal) { usePortal(nearPortal); return; }
				openChat();
			}

			if (inNexus) {
				// healing fountain
				if (world.tileAt(player.x, player.y) == World.FOUNTAIN) {
					player.hp = Math.min(player.maxHp, player.hp + player.maxHp * 0.6 * dt);
					player.mp = Math.min(player.maxMp, player.mp + player.maxMp * 0.6 * dt);
					player.pt = player.maxPt;
				}
				var was:Object = nearStation;
				nearStation = null;
				for each (var st:Object in stations) {
					var sx:Number = st.x - player.x, sy:Number = st.y - player.y;
					if (sx * sx + sy * sy < 1.7 * 1.7) nearStation = st;
				}
				if (nearStation != was) {
					if (nearStation) openStationPanel(nearStation);
					else closeStation();
				}
			} else if (world.closeT > 0) {
				var before:int = Math.ceil(world.closeT);
				world.closeT -= dt;
				var after:int = Math.ceil(world.closeT);
				if (after != before && (after == 10 || after <= 5) && after > 0) msg("Realm closing in " + after + "...", 0xff8080);
				if (world.closeT <= 0) {
					world.closed = true;
					msg("The " + world.name + " realm has closed.", 0xff8080);
					enterArena();
				}
			}
		}

		// ------------------------------------------------------------ realm events
		private function updateEvents(dt:Number):void {
			if (world.closeT > 0 || world.closed || world.eventsDone >= Data.EVENTS_PER_REALM) return;
			if (world.boss) return;
			world.eventT -= dt;
			if (world.eventT <= 0) spawnEvent();
		}

		/** Valor-style realm event: the overlord announces a boss somewhere inland. */
		private function spawnEvent():void {
			// a random event, avoiding the last few seen in this realm
			if (!world.recentEvents) world.recentEvents = [];
			var id:String;
			do id = Data.EVENTS[int(Math.random() * Data.EVENTS.length)]; while (world.recentEvents.indexOf(id) >= 0);
			for (var tries:int = 0; tries < 500; tries++) {
				var x:Number = world.N / 2 + (Math.random() - 0.5) * world.N * 0.6;
				var y:Number = world.N / 2 + (Math.random() - 0.5) * world.N * 0.6;
				var z:int = world.zoneAt(x, y);
				if (z >= World.MID_ZONE && z <= World.GOD_ZONE && world.canStand(x, y, 0.6, true)) {
					world.nextEvent++;
					world.recentEvents.push(id);
					if (world.recentEvents.length > 4) world.recentEvents.shift();
					world.boss = new Enemy(id, x, y, z);
					enemies.push(world.boss);
					player.bossDmg = 0;
					var nm:String = world.boss.def.name;
					showBanner(nm + " has appeared!", 0xff70ff, 3.5);
					Sfx.play("boss");
					say(SOVEREIGN, "I summon " + nm + " to crush you, mortal!");
					msg("Event boss on the minimap (magenta marker). [" + world.eventsDone + "/" + Data.EVENTS_PER_REALM + "]", 0xff70ff);
					tip("event", "Event bosses drop UT/Set gear, Sor Crystals and dungeon portals. Kill 6 to face the Dark Elder.");
					return;
				}
			}
			world.eventT = 5;
		}

		/** The realm has closed: the Dark Elder pulls you into his chamber. */
		private function enterArena():void {
			arenaWorld = new World("arena", "Dark Elder's Chamber");
			switchWorld(arenaWorld, arenaWorld.spawnX, arenaWorld.spawnY);
			player.invulnT = 3;
			arenaWorld.boss = new Enemy("elder", 100.5, 91.5, World.ARENA_ZONE);
			arenaWorld.enemies.push(arenaWorld.boss);
			player.bossDmg = 0;
			showBanner(Data.OVERLORD, 0xc060ff, 4);
			say(SOVEREIGN, "So, you slew my champions. Now kneel before the Dark Elder!");
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
								p.takeHit(s.dmg, s.owner, this, s.effect);
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
			hurtEnemy(e, s.dmg, s.effect, s.x, s.y);
		}

		/** Player damage to an enemy: defense, crits (Luck/Might), weapon passives. */
		public function hurtEnemy(e:Enemy, raw:int, effect:String, hx:Number, hy:Number):void {
			if (e.dead) return;
			var p:Player = player;
			if (e.invuln) {
				if (opt("dmg") && Math.random() < 0.15) floatText(e.x, e.y - e.r - 0.6, "Immune", 0xff80c0);
				return;
			}
			raw = int(raw * p.damageMult);
			if (p.leech > 0 && effect != "shard") p.hp = Math.min(p.maxHp, p.hp + p.leech);
			var crit:Boolean = Math.random() < p.critChance;
			if (crit) raw = int(raw * p.critMult);
			if (effect != "shard") p.shotsHit++;
			var d:int = Math.max(raw - e.defense, int(raw * 0.15));
			if (d > e.hp) d = Math.ceil(e.hp);
			e.hp -= d;
			e.hitT = 0.08;
			Sfx.play("hit", 0.6, 0.06);
			if (e.isBoss) p.bossDmg += d;
			if (opt("dmg")) floatText(e.x, e.y - e.r - 0.6, crit ? d + "!" : String(d), crit ? 0xffe040 : 0xff4040);
			if (effect == "slow") e.slowT = 3;
			// Legendary passives (not from passive-spawned shards)
			if (effect != "shard") {
				switch (p.weapon.passive) {
					case "lifesteal":
						p.hp = Math.min(p.maxHp, p.hp + 4);
						break;
					case "frost":
						if (Math.random() < 0.12) e.slowT = 2;
						break;
					case "shards":
						if (Math.random() < 0.06) {
							var fr:Vector.<BitmapData> = Sprites.projectile("star", 0xd8e040, 3);
							for (var k:int = 0; k < 8; k++) {
								shots.push(new Projectile(e.x, e.y, k * Math.PI / 4, 9, 0.5, int(raw * 0.6), false, 0.25, fr, true, p.name, "shard", true));
							}
						}
						break;
				}
			}
			sparks(hx, hy, e.def.col, 2);
			if (e.hp <= 0) killEnemy(e);
		}

		/** Area damage (Necromancer skull). Returns number of enemies hit. */
		public function blastAt(x:Number, y:Number, radius:Number, dmg:int):int {
			shake(0.15, 4);
			var n:int = 0;
			for each (var e:Enemy in enemies.concat()) {
				var dx:Number = e.x - x, dy:Number = e.y - y;
				if (!e.dead && dx * dx + dy * dy < radius * radius) {
					hurtEnemy(e, dmg, null, e.x, e.y);
					n++;
				}
			}
			return n;
		}

		/** Huntress trap: lands at the target, arms, then bursts into slowing shards. */
		public function throwTrap(fx:Number, fy:Number, tx:Number, ty:Number, dmg:int):void {
			traps.push({x: tx, y: ty, t: 0.5, life: 6, dmg: dmg});
			burst(tx, ty, 0xc0a060, 8);
		}

		private function updateTraps(dt:Number):void {
			for (var i:int = traps.length - 1; i >= 0; i--) {
				var t:Object = traps[i];
				t.t -= dt;
				t.life -= dt;
				var fire:Boolean = t.life <= 0;
				if (t.t <= 0 && !fire) {
					for each (var e:Enemy in enemies) {
						var dx:Number = e.x - t.x, dy:Number = e.y - t.y;
						if (dx * dx + dy * dy < 2.2 * 2.2) { fire = true; break; }
					}
				}
				if (fire) {
					var fr:Vector.<BitmapData> = Sprites.projectile("dart", 0xe0c070, 3);
					for (var k:int = 0; k < 16; k++) {
						shots.push(new Projectile(t.x, t.y, k * Math.PI / 8, 8, 0.45, t.dmg, false, 0.25, fr, true, player.name, "slow"));
					}
					burst(t.x, t.y, 0xe0c070, 18);
					traps.splice(i, 1);
				}
			}
		}

		private function killEnemy(e:Enemy):void {
			e.dead = true;
			Sfx.play(e.isBoss ? "boss" : "kill", e.isBoss ? 1 : 0.6, 0.04);
			var p:Player = player;
			questEvent("kills");
			if (world.kind == "realm" && e.zone == World.GOD_ZONE) questEvent("godkills");
			if (world.kind == "realm" && e.zone == World.GOD_ZONE) p.godKills++;
			if (e.def.final) { questEvent("elder"); p.elders++; }
			else if (e.def.dungeon) { questEvent("dungeon"); p.dungeons++; }
			else if (e.isBoss) questEvent("events");
			p.kills++;
			p.gainXp(e.def.xp, this);
			petGainXp(e.isBoss ? 20 : 1);
			burst(e.x, e.y, e.def.col, e.isBoss ? 60 : 12);
			var dx:Number = e.x - p.x, dy:Number = e.y - p.y;
			if (dx * dx + dy * dy < 12 * 12) p.addSurge(this);

			// currencies (account-wide, like Valor's gold and Onrane)
			var g:int = e.def.gold || int(e.def.xp / 6);
			if (g > 0) addGold(g);
			if (e.def.onrane) addOnrane(e.def.onrane);
			if (e.isBoss) floatText(e.x, e.y - 1.6, "+" + g + " gold  +" + (e.def.onrane || 0) + " onrane", Ui.GOLD);

			if (e.def.crystal) {
				var left:int = crystalsLeft();
				if (left > 0) msg("Elder Crystal destroyed! " + left + " remaining.", 0xff80c0);
				else if (world.boss && world.boss.invuln) {
					world.boss.invuln = false;
					showBanner("The Dark Elder is vulnerable!", 0xff4080, 3);
					say(world.boss.def.name, "No! My crystals...!");
				}
			}
			if (e.def.treasure) {
				questEvent("treasure");
				msg("You cracked open the treasure chest! (+" + g + " gold)", Ui.GOLD);
				burst(e.x, e.y, Ui.GOLD, 30);
			}
			if (e.isBoss) {
				shake(0.7, 10);
				p.bossKills++;
				world.boss = null;
				if (e.def.dungeon) {
					showBanner(e.def.name + " has been defeated!", Ui.GOLD, 4);
					msg("Dungeon cleared! A portal back to the Nexus has opened.", Ui.GOLD);
					addPortal(world, e.x, e.y + 2, "nexus", 0, 0xffffff);
				} else if (e.def.final) {
					showBanner(e.def.name + " has been defeated!", Ui.GOLD, 5);
					say(SOVEREIGN, "This... is not... the end...");
					msg("Fabled loot has dropped! Take the portal back to the Nexus when you're ready.", 0xff6060);
					addPortal(world, e.x, e.y + 2, "nexus", 0, 0xffffff);
				} else {
					world.eventsDone++;
					world.eventT = 20 + Math.random() * 10;
					// events often leave a dungeon portal behind
					if (Math.random() < Data.DUNGEON_DROP_CHANCE) {
						var di:int = int(Math.random() * Data.EVENT_DUNGEONS);
						addPortal(world, e.x + 1.5, e.y, "dungeon", di, Data.DUNGEONS[di].color, 90);
						msg(e.def.name + " dropped a portal to the " + Data.DUNGEONS[di].name + "! (90s)", Data.DUNGEONS[di].color);
						tip("dungeon", "Stand on the dungeon portal and press Enter before it closes!");
					}
					say(SOVEREIGN, e.def.name + " has been killed! [" + world.eventsDone + "/" + Data.EVENTS_PER_REALM + "][Realm: " + world.name + "]");
					if (world.eventsDone >= Data.EVENTS_PER_REALM) {
						say(SOVEREIGN, "Enough! You have slain my champions. The realm is closing... come to me!");
						showBanner("The realm is closing!", 0xff5050, 4);
						world.closeT = 15;
					}
				}
			} else if (world.kind == "realm" && !world.boss && e.def.drop > 0) {
				world.eventT -= 1.2; // killing speeds up the next event
			}
			// RotMG-style: some monsters drop a portal to their own dungeon
			if (world.kind == "realm" && e.def.portal && Math.random() < e.def.portalChance) {
				var pi:int = Data.dungeonIndex(e.def.portal);
				if (pi >= 0) {
					var dd:Object = Data.DUNGEONS[pi];
					addPortal(world, e.x, e.y, "dungeon", pi, dd.color, 60);
					msg(e.def.name + " dropped a portal to the " + dd.name + "! (60s)", dd.color);
					Sfx.play("portal", 0.6);
					tip("dungeon", "Stand on the dungeon portal and press Enter before it closes!");
				}
			}
			var items:Array = Data.rollLoot(e.def, Math.max(0, Math.min(World.GOD_ZONE, e.zone)), p.cls, p.frt);
			if (items.length) {
				while (items.length > LootBag.MAX) items.pop();
				var bag:LootBag = new LootBag(e.x, e.y, items);
				bags.push(bag);
				tip("bag", "Walk over a loot bag and click its items in the sidebar to take them.");
				// Valor-style rare drop alerts
				if (bag.spr == "bag_relic" || bag.spr == "bag_legendary") questEvent("legendary");
				if (bag.spr == "bag_relic" || bag.spr == "bag_legendary" || bag.spr == "bag_fabled") {
					var kind:String = bag.spr == "bag_relic" ? "Ancient Relic" : bag.spr == "bag_legendary" ? "Legendary" : "Fabled";
					var kc:uint = bag.spr == "bag_relic" ? 0x40e8d8 : bag.spr == "bag_legendary" ? 0xd8e040 : 0xff4a4a;
					showBanner(kind + " drop!", kc, 3);
					msg("A " + kind + " bag dropped from " + e.def.name + "!", kc);
					Sfx.play("rare");
					burst(e.x, e.y, kc, 30);
				} else if (bag.spr != "bag_brown") Sfx.play("loot", 0.7);
				if (bag.spr != "bag_brown") questEvent("rare");
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
			// fewer monsters near the shore so new characters aren't swarmed
			var pz:int = world.zoneAt(player.x, player.y);
			var cap:int = pz == 0 ? 8 : pz == 1 ? 11 : pz == 2 ? 13 : pz == 3 ? 14 : MAX_ENEMIES_NEAR;
			if (near >= cap) return;
			for (var tries:int = 0; tries < 6; tries++) {
				var a:Number = Math.random() * Math.PI * 2;
				var r:Number = 14 + Math.random() * 8;
				var sx:Number = player.x + Math.cos(a) * r;
				var sy:Number = player.y + Math.sin(a) * r;
				var z:int = world.zoneAt(sx, sy);
				if (z < 0 || z > World.GOD_ZONE || !world.canStand(sx, sy, 0.4, true)) continue;
				var list:Array = Data.ZONE_SPAWNS[z];
				var id:String = list[int(Math.random() * list.length)];
				// small packs near the shore, bigger ones inland
				var count:int = 1 + int(Math.random() * (z <= 1 ? 2 : z == World.GOD_ZONE ? 2 : 3));
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


		public function bossPhase(phase:int):void {
			var b:Enemy = world.boss;
			var nm:String = b ? b.def.name : "The boss";
			if (phase == 1) say(nm, "You dare wound me? Feel my power!");
			else if (phase == 2 && b && b.def.final) {
				// the Dark Elder shields himself with four crystals
				say(nm, "Crystals of the Abyss, shield your master!");
				showBanner("The Dark Elder is immune! Destroy the crystals!", 0xff4080, 4);
				b.invuln = true;
				shake(0.5, 7);
				for each (var cp:Array in [[-8, -5], [8, -5], [-8, 5], [8, 5]]) {
					var c:Enemy = spawnEnemy("elder_crystal", b.homeX + cp[0], b.homeY + 7 + cp[1], World.ARENA_ZONE);
					if (c) burst(c.x, c.y, 0xff4080, 20);
				}
				if (crystalsLeft() == 0) b.invuln = false;
				tip("crystals", "While the Elder Crystals stand, the Dark Elder takes no damage.");
			}
			else if (phase == 2) say(nm, "ENOUGH! I will end you!");
		}

		private function crystalsLeft():int {
			var n:int = 0;
			for each (var e:Enemy in enemies) if (!e.dead && e.def.crystal) n++;
			return n;
		}

		private function die():void {
			var p:Player = player;
			var save:Object = Save.data;
			var base:int = p.fame;
			var first:Boolean = !save.bestLevel || !save.bestLevel[p.cls.id];
			var bonuses:Array = Data.fameBonuses(p, first);
			var pct:int = 0;
			for each (var fb:Object in bonuses) { fb.fame = int(base * fb.pct / 100); pct += fb.pct; }
			var fame:int = base + int(base * pct / 100);
			var best:Boolean = fame > (save.bestFame || 0);
			if (best) save.bestFame = fame;
			save.deaths = (save.deaths || 0) + 1;
			save.fame = (save.fame || 0) + fame;
			if (!save.bestLevel) save.bestLevel = {};
			if (p.level > (save.bestLevel[p.cls.id] || 0)) save.bestLevel[p.cls.id] = p.level;
			Save.removeChar(p.id);
			// the graveyard keeps the 30 most recent fallen heroes
			if (!(save.graves is Array)) save.graves = [];
			var now:Date = new Date();
			save.graves.unshift({name: p.name, cls: p.cls.id, skin: p.skin, level: p.level, fame: fame, kills: p.kills,
				killer: p.lastHitBy || "the Realm", date: now.fullYear + "-" + (now.month + 1) + "-" + now.date});
			if (save.graves.length > 30) save.graves.length = 30;
			Save.flush();
			deathInfo = {
				name: p.name, cls: p.cls.name, clsId: p.cls.id, level: p.level, fame: fame, best: best, baseFame: base, bonuses: bonuses,
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
			player.pt = player.maxPt;
			for (var sk:String in player.status) player.status[sk] = 0;
			saveCharacter();
			if (!wasNexus) showBanner("Nexus", 0xffffff, 2);
			msg("You return to the Nexus. HP and MP restored.", 0xffffff);
		}

		public function slotClick(kind:String, idx:int, shift:Boolean):void {
			var p:Player = player;
			var item:Object;
			if (kind == "bag") {
				if (!nearBag || idx >= nearBag.items.length) return;
				item = nearBag.items[idx];
				if (item.kind == "material") tip("sor", "Sor Crystal: bring it with a UT/ST/FB item and 100 Onrane to the Sor Forge to make a Legendary.");
				if (item.kind == "hp" && p.hpPots < Player.MAX_POTS) p.hpPots++;
				else if (item.kind == "mp" && p.mpPots < Player.MAX_POTS) p.mpPots++;
				else {
					var slot:int = p.freeSlot();
					if (slot < 0) { msg("Inventory full! Drag an item onto the ground to drop it.", 0xff8080); return; }
					p.inv[slot] = item;
				}
				nearBag.items.splice(idx, 1);
				nearBag.refresh();
				if (nearBag.vault) saveVault();
			} else if (kind == "inv") {
				item = p.inv[idx];
				if (!item) return;
				if (shift && nearMarket) {
					var value:int = Data.sellValue(item);
					p.inv[idx] = null;
					addGold(value);
					Save.flush();
					msg("Sold " + item.name + " for " + value + " gold.", Ui.GOLD);
					Sfx.play("coin");
					refreshStation();
				} else if (shift) {
					p.inv[idx] = null;
					dropAtPlayer(item);
				} else {
					p.useItem(idx, this);
				}
			} else if (kind == "pot") {
				if (idx == 0) p.drinkHp(this); else p.drinkMp(this);
			}
		}

		// ------------------------------------------------------------- drag and drop
		private static const EQUIP_KINDS:Array = ["weapon", "ability", "armor", "ring"];

		private function itemAt(kind:String, idx:int):Object {
			var p:Player = player;
			if (kind == "inv") return p.inv[idx];
			if (kind == "bag") return nearBag && idx < nearBag.items.length ? nearBag.items[idx] : null;
			if (EQUIP_KINDS.indexOf(kind) >= 0) return p[kind];
			return null;
		}

		/** Drag an item onto the ground (the game view) to drop it, RotMG style. */
		public function dragToGround(kind:String, idx:int):void {
			var item:Object = itemAt(kind, idx);
			if (!item) return;
			if (kind == "inv") {
				player.inv[idx] = null;
				dropAtPlayer(item);
				if (!nearBag || !nearBag.vault) msg("Dropped " + item.name + ".", 0xcccccc);
				Sfx.play("loot", 0.4);
			} else if (EQUIP_KINDS.indexOf(kind) >= 0) {
				msg("Drag your " + kind + " into your inventory first to drop it.", 0xff8080);
			}
		}

		/** Drag an item from one slot to another: move, swap, equip or put in a bag. */
		public function dragToSlot(sk:String, si:int, dk:String, di:int):void {
			var p:Player = player;
			var item:Object = itemAt(sk, si);
			if (!item || (sk == dk && si == di)) return;
			var target:Object;
			if (sk == "inv" && dk == "inv") {
				p.inv[si] = p.inv[di];
				p.inv[di] = item;
			} else if (sk == "inv" && EQUIP_KINDS.indexOf(dk) >= 0) {
				if (item.kind != dk) { msg("That doesn't go in your " + dk + " slot.", 0xff8080); return; }
				p.useItem(si, this);
			} else if (EQUIP_KINDS.indexOf(sk) >= 0 && dk == "inv") {
				target = p.inv[di];
				if (!target) {
					if (sk == "weapon") { msg("You can't fight without a weapon! Swap it for another one instead.", 0xff8080); return; }
					p[sk] = null;
					p.inv[di] = item;
					p.hp = Math.min(p.hp, p.maxHp);
					p.mp = Math.min(p.mp, p.maxMp);
				} else if (target.kind == sk) {
					p.useItem(di, this);
				} else {
					msg("Drop it on an empty slot or an item of the same kind.", 0xff8080);
					return;
				}
			} else if (sk == "bag" && dk == "inv") {
				target = p.inv[di];
				p.inv[di] = item;
				if (target) nearBag.items[si] = target;
				else nearBag.items.splice(si, 1);
				nearBag.refresh();
				if (nearBag.vault) saveVault();
			} else if (sk == "inv" && dk == "bag") {
				if (!nearBag) { dragToGround(sk, si); return; }
				p.inv[si] = null;
				dropAtPlayer(item);
			} else {
				return;
			}
			Sfx.play("loot", 0.35);
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

		// ------------------------------------------------------------- nexus stations
		private static const SHOP:Array = [
			{id: "hp", name: "Health Potion", price: 50},
			{id: "mp", name: "Magic Potion", price: 50},
			{id: "stat", name: "Random Stat Potion", price: 450},
			{id: "sor", name: "Sor Crystal", price: 900},
			{id: "ut", name: "Mystery UT (your class)", price: 2500},
			{id: "backpack", name: "Backpack (+8 slots)", price: 3000}
		];

		private function openStationPanel(st:Object):void {
			openStation = st;
			refreshStation();
		}

		private function closeStation():void {
			openStation = null;
			releaseArmed = false;
			if (stationPanel) {
				stationPanel.visible = false;
				stationPanel.removeChildren();
			}
		}

		/** Rebuilds the open station's panel (after buying / forging). */
		public function refreshStation():void {
			if (!openStation || !stationPanel) return;
			var sp:Sprite = stationPanel;
			sp.removeChildren();
			sp.graphics.clear();
			var w:int = 440, y:int = 10;
			var title:TextField = Ui.text(20, {forge: 0xc080ff, market: 0x6fe08f, quests: 0xf0d080, pets: 0x60c0ff, skins: 0xff9a2e}[openStation.kind], true, "center", w, true);
			title.text = {forge: "Sor Forge", market: "Marketplace", quests: "Daily Quests", pets: "Pet Yard", skins: "Fame Store"}[openStation.kind];
			title.y = y;
			sp.addChild(title);
			y += 32;
			var info:TextField = Ui.text(13, 0xcccccc, false, "center", w - 20, true);
			info.x = 10;
			sp.addChild(info);
			var i:int;
			if (openStation.kind == "forge") {
				var sors:int = 0;
				for each (var it:Object in player.inv) if (it && it.kind == "material") sors++;
				info.htmlText = "Forge a <font color='#d8e040'><b>Legendary</b></font>: a UT, ST or FB item + 1 Sor Crystal + 100 Onrane\n" +
					"You have <b>" + sors + "</b> Sor Crystal" + (sors == 1 ? "" : "s") + " and <b>" + onrane + "</b> Onrane. Click an item to forge it.";
				info.y = y;
				y += info.height + 8;
				var n:int = 0;
				for (i = 0; i < player.inv.length; i++) {
					var item:Object = player.inv[i];
					if (!item || !item.rarity || item.rarity == "lg" || item.rarity == "ar") continue;
					sp.addChild(itemButton(item, 20 + n * 52, y, forgeFn(i)));
					n++;
				}
				if (n == 0) {
					var none:TextField = Ui.text(13, 0x888888, false, "center", w - 20);
					none.x = 10; none.y = y + 10;
					none.text = "No UT, ST or FB items in your inventory.";
					sp.addChild(none);
				}
				y += 56;
			} else if (openStation.kind == "skins") {
				y = buildSkinPanel(sp, info, y, w);
			} else if (openStation.kind == "pets") {
				y = buildPetPanel(sp, info, y, w);
			} else if (openStation.kind == "quests" && showAch) {
				title.text = "Achievements";
				var ast0:Object = achState();
				info.htmlText = "Account-wide goals. Each pays out once, automatically.";
				info.y = y;
				y += info.height + 4;
				for each (var ach:Object in Data.ACHIEVEMENTS) {
					var got:Boolean = ast0.done[ach.id];
					var prog:int = Math.min(ach.goal, int(ast0.counts[ach.ev] || 0));
					var ar:TextField = Ui.text(13, got ? 0xffd75e : 0xffffff, true, "left", 300, true);
					ar.htmlText = ach.name + "  <font size='12' color='#999999'>" + ach.desc +
						(got || ach.goal == 1 ? "" : "  " + Ui.commas(prog) + "/" + Ui.commas(ach.goal)) + "</font>";
					ar.x = 14; ar.y = y;
					sp.addChild(ar);
					var rw:TextField = Ui.text(12, got ? 0x777777 : 0xffd75e, true, "right", 120, true);
					rw.text = ach.gold + "g" + (ach.onrane ? "  " + ach.onrane + " on" : "");
					rw.x = w - 134; rw.y = y + 1;
					sp.addChild(rw);
					y += 22;
				}
				y += 6;
				var bk:Sprite = Ui.button("Back to Daily Quests", 200, 30, function():void { showAch = false; refreshStation(); }, 14);
				bk.x = (w - 200) / 2; bk.y = y;
				sp.addChild(bk);
				y += 36;
			} else if (openStation.kind == "quests") {
				info.htmlText = "Complete these missions with any character. New quests every day.";
				info.y = y;
				y += info.height + 6;
				for each (var qs:Object in questState().list) {
					var q:Object = Data.quest(qs.id);
					var done:Boolean = qs.progress >= q.goal;
					var row:TextField = Ui.text(14, done ? 0x9cff7a : 0xffffff, true, "left", 290, true);
					row.htmlText = q.text + "  <font color='#aaaaaa'>" + qs.progress + "/" + q.goal + "</font>\n<font size='12' color='#ffd75e'>" +
						(q.gold ? q.gold + " gold  " : "") + (q.onrane ? q.onrane + " onrane" : "") + "</font>";
					row.x = 16; row.y = y;
					sp.addChild(row);
					if (qs.claimed) {
						var c:TextField = Ui.text(14, 0x888888, true, "center", 110);
						c.text = "Claimed";
						c.x = 316; c.y = y + 8;
						sp.addChild(c);
					} else if (done) {
						var cb:Sprite = Ui.button("Claim", 100, 30, claimFn(qs), 15);
						cb.x = 320; cb.y = y + 4;
						sp.addChild(cb);
					}
					y += 44;
				}
				var nDone:int = 0;
				for each (var a2:Object in Data.ACHIEVEMENTS) if (achState().done[a2.id]) nDone++;
				var ab:Sprite = Ui.button("Achievements (" + nDone + "/" + Data.ACHIEVEMENTS.length + ")", 200, 30, function():void { showAch = true; refreshStation(); }, 14);
				ab.x = (w - 200) / 2; ab.y = y + 2;
				sp.addChild(ab);
				y += 38;
			} else {
				info.htmlText = "You have <font color='#ffd75e'><b>" + Ui.commas(gold) + "</b></font> gold.  Shift+click inventory items to sell them.";
				info.y = y;
				y += info.height + 8;
				for (i = 0; i < SHOP.length; i++) {
					var e:Object = SHOP[i];
					var b:Sprite = Ui.button(e.name + "  -  " + Ui.commas(e.price) + "g", 205, 30, buyFn(e), 13);
					b.x = 12 + (i % 2) * 211;
					b.y = y + int(i / 2) * 36;
					sp.addChild(b);
				}
				y += int((SHOP.length + 1) / 2) * 36 + 4;
			}
			Ui.panel(sp.graphics, 0, 0, w, y + 6, 0x222222, 0x6a6a6a, 0.95);
			sp.x = (VIEW_W - w) / 2;
			sp.y = 60;
			sp.visible = true;
		}

		private function itemButton(item:Object, x:int, y:int, onClick:Function):Sprite {
			var b:Sprite = new Sprite();
			b.graphics.lineStyle(1, 0x1a1a1a);
			b.graphics.beginFill(0x545454);
			b.graphics.drawRoundRect(0, 0, 48, 48, 10, 10);
			b.graphics.endFill();
			var bmp:Bitmap = new Bitmap(Sprites.icon(item));
			bmp.x = 6; bmp.y = 6;
			b.addChild(bmp);
			var tag:TextField = Ui.text(12, Data.tierColor(item), true, "right", 30, true);
			tag.text = Data.tierLabel(item);
			tag.x = 15; tag.y = 29;
			b.addChild(tag);
			b.x = x; b.y = y;
			b.buttonMode = true;
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.CLICK, function(ev:*):void { onClick(); });
			return b;
		}

		// ------------------------------------------------------------- daily quests
		private static function today():String {
			var d:Date = new Date();
			return d.fullYear + "-" + (d.month + 1) + "-" + d.date;
		}

		/** Today's 3 quests (picked deterministically from the date), stored account-wide. */
		public function questState():Object {
			var st:Object = Save.data.quests;
			var day:String = today();
			if (!st || st.day != day) {
				var seed:int = 0;
				for (var i:int = 0; i < day.length; i++) seed = (seed * 31 + day.charCodeAt(i)) & 0x7fffffff;
				var pool:Array = Data.QUESTS.concat();
				var list:Array = [];
				for (i = 0; i < 3; i++) {
					seed = (seed * 1103515245 + 12345) & 0x7fffffff;
					var q:Object = pool.splice(seed % pool.length, 1)[0];
					list.push({id: q.id, progress: 0, claimed: false});
				}
				st = Save.data.quests = {day: day, list: list};
			}
			return st;
		}

		public function questEvent(id:String, n:int = 1):void {
			achievementEvent(id, n);
			for each (var qs:Object in questState().list) {
				if (qs.id != id || qs.claimed) continue;
				var q:Object = Data.quest(id);
				if (qs.progress >= q.goal) continue;
				qs.progress = Math.min(q.goal, qs.progress + n);
				if (qs.progress >= q.goal) {
					msg("Quest complete: " + q.text + "! Claim it at the Quest Board.", 0x9cff7a);
					Sfx.play("coin");
					Save.flush();
				}
			}
		}

		/** Account achievement progress: {counts: {event: n}, done: {id: true}}. */
		private function achState():Object {
			var a:Object = Save.data.ach;
			if (!a) a = Save.data.ach = {counts: {}, done: {}};
			return a;
		}

		private function achievementEvent(ev:String, n:int):void {
			var a:Object = achState();
			a.counts[ev] = int(a.counts[ev] || 0) + n;
			for each (var ach:Object in Data.ACHIEVEMENTS) {
				if (ach.ev != ev || a.done[ach.id] || a.counts[ev] < ach.goal) continue;
				a.done[ach.id] = true;
				if (ach.gold) addGold(ach.gold);
				if (ach.onrane) addOnrane(ach.onrane);
				showBanner("Achievement: " + ach.name, 0xffd75e, 3);
				msg("Achievement unlocked: " + ach.name + " (" + ach.desc + ")  +" + ach.gold + " gold" + (ach.onrane ? " +" + ach.onrane + " onrane" : ""), 0xffd75e);
				Sfx.play("rare", 0.7);
				Save.flush();
			}
		}

		private function claimFn(qs:Object):Function {
			return function():void {
				if (qs.claimed) return;
				var q:Object = Data.quest(qs.id);
				qs.claimed = true;
				if (q.gold) addGold(q.gold);
				if (q.onrane) addOnrane(q.onrane);
				Save.flush();
				msg("Quest reward: " + (q.gold ? q.gold + " gold " : "") + (q.onrane ? q.onrane + " onrane" : ""), Ui.GOLD);
				Sfx.play("rare");
				refreshStation();
			};
		}

		private function forgeFn(slot:int):Function {
			return function():void { forge(slot); };
		}

		// ------------------------------------------------------------- pets
		public function get pet():Object { return Save.data.pet; }

		/** The pet trails behind the player and heals HP / MP every few seconds. */
		private function updatePet(dt:Number):void {
			var pt:Object = pet;
			if (!pt) return;
			var dx:Number = player.x - petX, dy:Number = player.y - petY;
			var d:Number = Math.sqrt(dx * dx + dy * dy);
			if (d > 10) { petX = player.x - 1; petY = player.y + 0.5; d = 0; }
			petMoving = d > 1.4;
			if (petMoving) {
				var sp:Number = Math.min(d - 1.2, (4 + 5.6 * (player.spd / 75)) * 1.15 * dt);
				petX += dx / d * sp; petY += dy / d * sp;
			}
			petHealT -= dt;
			if (petHealT <= 0) {
				petHealT = 3;
				if (inNexus || player.hp <= 0) return;
				var h:int = Math.min(Data.petHeal(pt), player.maxHp - player.hp);
				var m:int = Math.min(Data.petMagic(pt), player.maxMp - player.mp);
				if (h > 0 && player.status.bleeding <= 0) {
					player.hp += h;
					if (opt("dmg")) floatText(player.x, player.y - 1.2, "+" + h, 0x60ff60);
				}
				if (m > 0) player.mp += m;
				if (h > 0 || m > 0) burst(petX, petY - 0.3, 0x60ff90, 4);
			}
		}

		private function petGainXp(n:int):void {
			var pt:Object = pet;
			if (!pt) return;
			var max:int = Data.PET_RARITIES[pt.rarity].max;
			if (pt.level >= max) return;
			pt.xp += n;
			while (pt.level < max && pt.xp >= Data.petXpNeeded(pt.level)) {
				pt.xp -= Data.petXpNeeded(pt.level);
				pt.level++;
				msg(pt.name + " reached level " + pt.level + "!", Data.PET_RARITIES[pt.rarity].col);
			}
		}

		private function buildPetPanel(sp:Sprite, info:TextField, y:int, w:int):int {
			var pt:Object = pet;
			var b:Sprite;
			if (!pt) {
				info.htmlText = "Pets follow you into the realm and heal your HP and MP every few seconds.\n" +
					"They grow stronger with every kill. Rare and Legendary pets reach higher levels.";
				info.y = y;
				y += info.height + 10;
				b = Ui.button("Hatch an Egg  -  " + Ui.commas(Data.PET_EGG_PRICE) + "g", 240, 34, hatchPet, 15);
				b.x = (w - 240) / 2; b.y = y;
				sp.addChild(b);
				return y + 42;
			}
			var r:Object = Data.PET_RARITIES[pt.rarity];
			var icon:Bitmap = new Bitmap(Sprites.get("pet_" + pt.species));
			icon.x = 24; icon.y = y;
			sp.addChild(icon);
			var max:Boolean = pt.level >= r.max;
			info.htmlText = "<font size='17' color='" + Ui.hex(r.col) + "'><b>" + pt.name + "</b></font>  <font color='" + Ui.hex(r.col) + "'>" + r.name + "</font>\n" +
				"Level <b>" + pt.level + "</b> / " + r.max + (max ? "  (max)" : "   XP " + pt.xp + " / " + Data.petXpNeeded(pt.level)) + "\n" +
				"Heals <font color='#80ff80'>" + Data.petHeal(pt) + " HP</font> and <font color='#80a0ff'>" + Data.petMagic(pt) + " MP</font> every 3 seconds";
			info.x = 80; info.width = w - 90;
			info.autoSize = "left";
			info.y = y;
			y += Math.max(icon.height, info.height) + 10;
			if (!max) {
				b = Ui.button("Feed (+" + Data.PET_FEED_XP + " XP)  -  " + Data.PET_FEED_PRICE + "g", 200, 30, feedPet, 14);
				b.x = 14; b.y = y;
				sp.addChild(b);
			}
			b = Ui.button(releaseArmed ? "Click again to release" : "Release pet", 200, 30, releasePet, 14);
			b.x = w - 214; b.y = y;
			sp.addChild(b);
			return y + 38;
		}

		// ------------------------------------------------------------- fame store (skins)
		private function buildSkinPanel(sp:Sprite, info:TextField, y:int, w:int):int {
			var fame:int = int(Save.data.fame || 0);
			info.htmlText = "Spend account fame (earned when heroes die) on " + player.cls.name + " skins.\n" +
				"You have <font color='#ff9a2e'><b>" + Ui.commas(fame) + "</b></font> fame.";
			info.y = y;
			y += info.height + 8;
			var opts:Array = [{id: "", name: "Classic " + player.cls.name, cost: 0}].concat(Data.SKINS[player.cls.id] || []);
			var owned:Object = Save.data.skins || {};
			for (var i:int = 0; i < opts.length; i++) {
				var sk:Object = opts[i];
				var x:int = 14 + i * 140;
				var box:Sprite = new Sprite();
				var on:Boolean = player.skin == sk.id;
				Ui.panel(box.graphics, 0, 0, 132, 150, on ? 0x3e3424 : 0x2c2c2c, on ? 0xff9a2e : 0x4a4a4a);
				var bmp:Bitmap = new Bitmap(Sprites.get(sk.id || player.cls.id));
				bmp.x = (132 - bmp.width) / 2; bmp.y = 6;
				box.addChild(bmp);
				var nm:TextField = Ui.text(13, 0xffffff, true, "center", 132, true);
				nm.text = sk.name;
				nm.y = 66;
				box.addChild(nm);
				var have:Boolean = !sk.id || owned[sk.id];
				var label:String = on ? "Equipped" : have ? "Equip" : Ui.commas(sk.cost) + " fame";
				var b:Sprite = Ui.button(label, 112, 30, skinFn(sk), 14);
				b.x = 10; b.y = 108;
				box.addChild(b);
				box.x = x; box.y = y;
				sp.addChild(box);
			}
			return y + 158;
		}

		private function skinFn(sk:Object):Function {
			return function():void {
				var owned:Object = Save.data.skins || (Save.data.skins = {});
				if (sk.id && !owned[sk.id]) {
					var fame:int = int(Save.data.fame || 0);
					if (fame < sk.cost) { msg("You need " + Ui.commas(sk.cost) + " fame for " + sk.name + ". Fame is earned when heroes die.", 0xff8080); return; }
					Save.data.fame = fame - sk.cost;
					owned[sk.id] = true;
					showBanner("Unlocked " + sk.name + "!", 0xff9a2e, 3);
					Sfx.play("rare");
				}
				player.skin = sk.id;
				burst(player.x, player.y, 0xff9a2e, 20);
				saveCharacter();
				Save.flush();
				refreshStation();
			};
		}

		private function hatchPet():void {
			if (pet) return;
			if (gold < Data.PET_EGG_PRICE) { msg("You need " + Ui.commas(Data.PET_EGG_PRICE) + " gold to buy a pet egg.", 0xff8080); return; }
			addGold(-Data.PET_EGG_PRICE);
			var pt:Object = Save.data.pet = Data.hatchPet();
			questEvent("pet");
			petX = player.x - 1; petY = player.y + 0.5;
			var r:Object = Data.PET_RARITIES[pt.rarity];
			showBanner("You hatched a " + r.name + " " + pt.name + "!", r.col, 3);
			Sfx.play(pt.rarity == "common" ? "loot" : "rare");
			burst(petX, petY, r.col, 25);
			Save.flush();
			refreshStation();
		}

		private function feedPet():void {
			if (!pet) return;
			if (gold < Data.PET_FEED_PRICE) { msg("Not enough gold to feed your pet.", 0xff8080); return; }
			addGold(-Data.PET_FEED_PRICE);
			petGainXp(Data.PET_FEED_XP);
			burst(petX, petY, 0x60ff90, 10);
			Save.flush();
			refreshStation();
		}

		private function releasePet():void {
			if (!pet) return;
			if (!releaseArmed) { releaseArmed = true; refreshStation(); return; }
			releaseArmed = false;
			msg(pet.name + " returns to the wild.", 0xcccccc);
			delete Save.data.pet;
			Save.flush();
			refreshStation();
		}

		private function buyFn(e:Object):Function {
			return function():void { buy(e); };
		}

		/** Sor Forge: UT/ST/FB item + Sor Crystal + 100 Onrane -> Legendary. */
		private function forge(slot:int):void {
			var item:Object = player.inv[slot];
			if (!item) return;
			var sorSlot:int = -1;
			for (var i:int = 0; i < player.inv.length; i++) if (player.inv[i] && player.inv[i].kind == "material") { sorSlot = i; break; }
			if (sorSlot < 0) { msg("You need a Sor Crystal (event bosses drop them, or buy one at the Marketplace).", 0xff8080); return; }
			if (onrane < 100) { msg("You need 100 Onrane (" + onrane + " now). Event bosses drop Onrane.", 0xff8080); return; }
			addOnrane(-100);
			player.inv[sorSlot] = null;
			var lg:Object = Data.forgeLegendary(item, player.cls);
			player.inv[slot] = lg;
			questEvent("legendary");
			Save.flush();
			showBanner("Forged " + lg.name + "!", Data.RARITY_COLORS.lg, 3);
			Sfx.play("rare");
			msg("The Sor Forge blazes... you forged " + lg.name + "!", Data.RARITY_COLORS.lg);
			burst(player.x, player.y, 0xd8e040, 30);
			saveCharacter();
			refreshStation();
		}

		private function buy(e:Object):void {
			if (gold < e.price) { msg("Not enough gold for " + e.name + ".", 0xff8080); return; }
			var item:Object;
			switch (e.id) {
				case "hp":
					if (player.hpPots < Player.MAX_POTS) { player.hpPots++; break; }
					item = Data.makePotion("hp"); break;
				case "mp":
					if (player.mpPots < Player.MAX_POTS) { player.mpPots++; break; }
					item = Data.makePotion("mp"); break;
				case "stat": item = Data.makePotion("stat", Data.randomStat()); break;
				case "sor": item = Data.makeSor(); break;
				case "ut": item = Data.makeForSlot(player.cls, int(Math.random() * 4), 7, "ut"); break;
				case "backpack":
					if (player.backpack) { msg("This character already has a backpack.", 0xff8080); return; }
					player.backpack = true;
					while (player.inv.length < 16) player.inv.push(null);
					msg("You bought a backpack! Switch inventory pages with the button by the tabs.", Ui.GOLD);
					break;
			}
			if (item) {
				var slot:int = player.freeSlot();
				if (slot < 0) { msg("Inventory full!", 0xff8080); return; }
				player.inv[slot] = item;
			}
			addGold(-e.price);
			Save.flush();
			msg("Bought " + (item ? item.name : e.name) + ".", Ui.GOLD);
			Sfx.play("coin");
			refreshStation();
		}

		// ------------------------------------------------------------- effects
		public function burst(x:Number, y:Number, color:uint, n:int):void {
			if (!opt("parts")) return;
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
			goldTf.text = Ui.commas(gold);
			onraneTf.text = Ui.commas(onrane);
			var stx:String = player.statusText;
			if (player.burning) stx = "<font color='#ff9a40'>Burning!</font>  " + stx;
			if (player.invisT > 0) stx = "<font color='#c0a0ff'>Invisible</font>  " + stx;
			if (player.berserkT > 0) stx = "<font color='#ff5040'>Berserk</font>  " + stx;
			statusTf.htmlText = stx;
			promptPanel.visible = nearPortal != null;
			if (nearPortal) {
				promptTf.htmlText = portalTitle(nearPortal) + "<font size='13' color='#aaaaaa'>  -  press Enter</font>";
			}
			statusTf.x = CX - 160;
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
				g.beginFill(b.invuln ? 0x9a5a7a : 0xc82828);
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
				bossInfo.text = b.invuln ? "IMMUNE: " + crystalsLeft() + " crystals left" : "Boss HP: " + (frac * 100).toFixed(1) + "%";
				var met:Boolean = pct >= LG_THRESHOLD;
				thresholdTf.text = "LG: " + LG_THRESHOLD + "% " + (met ? "met" : "not met");
				thresholdTf.textColor = met ? 0x7fd07f : 0xe05050;
			}
		}

		// ------------------------------------------------------------- render
		public function screenToWorldX(sx:Number):Number { return camX + (sx - CX) / TS; }
		public function screenToWorldY(sy:Number):Number { return camY + (sy - CY) / TS; }

		/** Picks the objective: the area boss (or its crystals), else a monster suited to your level. */
		private function pickQuest():Enemy {
			if (inNexus) return null;
			var b:Enemy = world.boss;
			var e:Enemy, best:Enemy = null, bestD:Number = 1e9, d:Number;
			if (b && !b.dead) {
				if (!b.invuln) return b;
				for each (e in enemies) {
					if (e.dead || !e.def.crystal) continue;
					d = (e.x - player.x) * (e.x - player.x) + (e.y - player.y) * (e.y - player.y);
					if (d < bestD) { bestD = d; best = e; }
				}
				return best || b;
			}
			if (world.kind != "realm") return null;
			var want:int = Math.min(World.GOD_ZONE, int(player.level / 4));
			var bestZone:int = -1;
			for each (e in enemies) {
				if (e.dead || e.def.drop <= 0) continue;
				var z:int = Math.min(e.zone, want);
				d = (e.x - player.x) * (e.x - player.x) + (e.y - player.y) * (e.y - player.y);
				if (z > bestZone || (z == bestZone && d < bestD)) { bestZone = z; bestD = d; best = e; }
			}
			return best;
		}

		private function updateQuestArrow(ox:Number, oy:Number):void {
			questT -= 1 / 30;
			if (questT <= 0 || !questTarget || questTarget.dead) {
				questT = 0.5;
				questTarget = pickQuest();
			}
			var q:Enemy = questTarget;
			questArrow.visible = questTf.visible = q != null && !q.dead && !paused;
			if (!questArrow.visible) return;
			var sx:Number = q.x * TS + ox, sy:Number = q.y * TS + oy;
			var m:Number = 34;
			if (sx > m && sx < VIEW_W - m && sy > m + 40 && sy < VIEW_H - m) {
				// on screen: bob above the target, pointing down
				questArrow.rotation = 90;
				questArrow.x = sx;
				questArrow.y = sy - TS * (q.isBoss ? 2.2 : 1.4) - 4 + Math.sin(time * 6) * 4;
				questTf.visible = false;
				return;
			}
			var dx:Number = sx - CX, dy:Number = sy - CY;
			var ang:Number = Math.atan2(dy, dx);
			// clamp to the edge of the view
			var kx:Number = dx != 0 ? (dx > 0 ? (VIEW_W - m - CX) : (m - CX)) / dx : 1e9;
			var ky:Number = dy != 0 ? (dy > 0 ? (VIEW_H - m - CY) : (m + 40 - CY)) / dy : 1e9;
			var k:Number = Math.min(kx, ky);
			questArrow.x = CX + dx * k;
			questArrow.y = CY + dy * k;
			questArrow.rotation = ang * 180 / Math.PI;
			var dist:int = Math.sqrt((q.x - player.x) * (q.x - player.x) + (q.y - player.y) * (q.y - player.y));
			questTf.text = q.def.name + "  " + dist + "m";
			questTf.x = Math.max(4, Math.min(VIEW_W - 164, questArrow.x - 80));
			questTf.y = questArrow.y + (dy > 0 ? -34 : 14);
		}

		private function render():void {
			var ox:Number = Math.round(CX - camX * TS);
			var oy:Number = Math.round(CY - camY * TS);
			if (shakeT > 0 && !paused) {
				shakeT -= 1 / 30;
				var sa:Number = shakeAmp * Math.min(1, shakeT * 4);
				ox += Math.round((Math.random() * 2 - 1) * sa);
				oy += Math.round((Math.random() * 2 - 1) * sa);
			}
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

			// portals and labels
			for each (var p:Object in world.portals) {
				var pcx:Number = p.x * TS + ox, pcy:Number = p.y * TS + oy;
				var pbd:BitmapData = Sprites.portal(p.color, int(time * 8));
				var ptop:Number = drawEntity(pbd, pcx, pcy, 0);
				var lab:TextField = p.label;
				lab.htmlText = p.kind == "realm" ? realmNames[p.idx] + "\n<font size='11' color='#cccccc'>" + realmStatus(p.idx) + "</font>"
					: p.kind == "dungeon" ? Data.DUNGEONS[p.idx].name + "\n<font size='11' color='#cccccc'>" + Math.ceil(p.life) + "s</font>" : "Nexus";
				lab.x = int(pcx - lab.width / 2);
				lab.y = int(ptop - lab.height - 2);
			}
			if (inNexus) {
				vaultLabel.x = int(vaultBag.x * TS + ox - vaultLabel.width / 2);
				vaultLabel.y = int(vaultBag.y * TS + oy - 58);
				for each (var st:Object in stations) {
					var stop:Number = drawEntity(Sprites.get(st.spr), st.x * TS + ox, st.y * TS + oy, 0);
					st.label.x = int(st.x * TS + ox - st.label.width / 2);
					st.label.y = int(stop - st.label.height);
				}
			}
			var trapIcon:BitmapData = Sprites.icon({kind: "ability", sub: "trap", tier: 0});
			for each (var tr:Object in traps) {
				pt.x = int(tr.x * TS + ox - trapIcon.width / 2);
				pt.y = int(tr.y * TS + oy - trapIcon.height / 2);
				canvas.copyPixels(trapIcon, trapIcon.rect, pt, null, null, true);
			}

			// y-sorted: world objects, enemies, player
			drawList.length = 0;
			drawN = 0;
			var tx0:int = int(camX - CX / TS) - 1, tx1:int = int(camX + (VIEW_W - CX) / TS) + 1;
			var ty0:int = int(camY - CY / TS) - 1, ty1:int = int(camY + (VIEW_H - CY) / TS) + 3;
			for (var ty:int = ty0; ty <= ty1; ty++) {
				for (var tx:int = tx0; tx <= tx1; tx++) {
					var o:int = world.objAt(tx, ty);
					if (o > 0) drawList.push(drawItem(ty + 0.9, o, tx, null, false));
				}
			}
			for each (var e:Enemy in enemies) {
				var sx:Number = e.x * TS + ox, sy:Number = e.y * TS + oy;
				if (sx < -100 || sy < -100 || sx > VIEW_W + 100 || sy > VIEW_H + 120) continue;
				drawList.push(drawItem(e.y, 0, 0, e, false));
			}
			drawList.push(drawItem(player.y, 0, 0, null, true));
			if (pet) drawList.push(drawItem(petY, -1, 0, null, false));
			drawList.sortOn("y", Array.NUMERIC);

			for each (var d:Object in drawList) {
				if (d.o < 0) {
					drawEntity(Sprites.get("pet_" + pet.species, 0, petX > player.x), petX * TS + ox, petY * TS + oy,
						petMoving && int(time * 6) % 2 == 0 ? 2 : 0);
				} else if (d.o) {
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
			updateQuestArrow(ox, oy);

			for each (var f:Floater in floaters) {
				if (!f.tf.visible) continue;
				f.tf.x = f.x * TS + ox - f.tf.width / 2;
				f.tf.y = f.y * TS + oy - f.tf.height / 2;
			}
		}

		/** Reuses draw-list entries between frames instead of allocating new objects. */
		private function drawItem(y:Number, o:int, x:int, e:Enemy, p:Boolean):Object {
			var d:Object = drawPool[drawN];
			if (!d) d = drawPool[drawN] = {};
			drawN++;
			d.y = y; d.o = o; d.x = x; d.e = e; d.p = p;
			return d;
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

		private var auraShape:Shape = new Shape();
		private var auraMtx:Matrix = new Matrix();

		private function drawAura(cx:Number, cy:Number, col:uint):void {
			var pulse:Number = (Math.sin(time * 4) + 1) / 2;
			var rx:Number = TS * 1.15 + pulse * 6, ry:Number = rx * 0.45;
			var g:* = auraShape.graphics;
			g.clear();
			g.beginFill(col, 0.12 + pulse * 0.1);
			g.drawEllipse(-rx * 1.25, -ry * 1.25, rx * 2.5, ry * 2.5);
			g.endFill();
			g.beginFill(col, 0.22 + pulse * 0.12);
			g.drawEllipse(-rx, -ry, rx * 2, ry * 2);
			g.endFill();
			g.lineStyle(2, col, 0.55 + pulse * 0.3);
			g.drawEllipse(-rx * 0.8, -ry * 0.8, rx * 1.6, ry * 1.6);
			auraMtx.tx = cx; auraMtx.ty = cy;
			canvas.draw(auraShape, auraMtx);
		}

		private function drawEnemy(e:Enemy, ox:Number, oy:Number):void {
			var cx:Number = e.x * TS + ox, cy:Number = e.y * TS + oy;
			var bob:int = e.moving && int(time * 5 + e.homeX) % 2 == 0 ? 2 : 0;
			if (e.isBoss) {
				// pulsing aura on the ground and a slow hover
				drawAura(cx, cy + TS * 0.4, e.invuln ? 0xff4080 : e.enraged ? 0xff2020 : uint(e.def.col));
				bob = int((Math.sin(time * 2.5 + e.homeX) + 1) * 2.5);
			}
			var top:Number = drawEntity(e.sprite, cx, cy, bob);
			if (e.hp < e.maxHp) {
				var bw:int = e.isBoss ? 80 : 36;
				hpBar(cx - bw / 2, cy + TS * 0.4 + 6, bw, e.hp / e.maxHp);
			}
			if (e.invuln) statusPip(cx, top - 6, 0xffff4080);
			else if (e.stunT > 0) statusPip(cx, top - 6, 0xfff0f040);
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
