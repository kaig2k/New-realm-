package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.ColorMatrixFilter;
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
		/** World view scale (mouse wheel): below 1 shows more of the map. */
		public var zoom:Number = 0.8;
		public static const ZOOM_MIN:Number = 0.5, ZOOM_MAX:Number = 1.25;
		/** The world canvas (before scaling): size and centre. */
		private var vw:int = VIEW_W, vh:int = VIEW_H;
		private var cx:Number = VIEW_W / 2, cy:Number = VIEW_H / 2 + 20;
		/** Holds everything drawn in world space; scaled by zoom. */
		private var worldLayer:Sprite;
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
		public var realms:Array = [null, null, null, null, null, null];
		/** Online: players in each realm and the cap. */
		private var realmCounts:Array = [];
		private var realmCap:int = 85;
		public var realmNames:Array = [];
		/** Realm map seeds from the server (online only). */
		private var realmSeeds:Array = [];
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
		// smoothness: fades, death sequence, vignette
		private var canvasBmp:Bitmap;
		private var fadeShape:Shape;
		private var fadeA:Number = 1, fadeTarget:Number = 0;
		private var travelFn:Function;
		private var dyingT:Number = 0;
		private static const DYING_TIME:Number = 2.6;
		private var dustT:Number = 0;
		// admin / testing tools
		public var godMode:Boolean = false;
		private var admin:AdminMenu;
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
		private var lastSite:Object;
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
		// other players (through the connection; LocalNet simulates them for now)
		public var net:Net;
		/** Shared monsters online (see WorldSync). */
		public var sync:WorldSync;
		private var tagLayer:Sprite;
		private var tags:Array = [];
		private var bubbles:Array = [];
		private var playerMenu:Sprite;
		private var tradeWin:TradeWindow;
		private var inspectWin:InspectWindow;
		private var requestPopup:Sprite;
		private var requestT:Number = 0;
		private var hoverRemote:RemotePlayer;
		private var netTf:TextField;
		private var netT:Number = 0;
		private var social:SocialWindow;
		private var wiki:WikiWindow;
		private var tpT:Number = 0;

		public function Game(clsId:String, name:String, onDeath:Function, saved:Object = null) {
			this.onDeath = onDeath;
			world = nexusWorld = new World("nexus", "Nexus");
			nexusWorld.key = "nexus";
			player = new Player(clsId, name, world.spawnX, world.spawnY);
			if (saved) player.restore(saved);
			else player.id = String(new Date().time) + "_" + int(Math.random() * 100000);
			Data.viewerClass = player.cls.id;
			if (Online.connected) {
				// the server picks the realms, and their seeds give everyone the same maps
				for each (var sr:Object in Online.welcome.realms) { realmNames.push(sr.name); realmSeeds.push(uint(sr.seed)); realmCounts.push(sr.count || 0); realmCap = sr.cap || 85; }
			} else {
				var pool:Array = Data.REALM_NAMES.concat();
				for (var ri:int = 0; ri < 3; ri++) realmNames.push(pool.splice(int(Math.random() * pool.length), 1)[0]);
			}
			camX = player.x;
			camY = player.y;
			world.reveal(player.x, player.y, 14);

			worldLayer = new Sprite();
			worldLayer.mouseEnabled = false;
			addChild(worldLayer);
			canvas = new BitmapData(VIEW_W, VIEW_H, false, 0);
			canvasBmp = new Bitmap(canvas);
			worldLayer.addChild(canvasBmp);
			floatLayer = new Sprite();
			floatLayer.mouseEnabled = floatLayer.mouseChildren = false;
			worldLayer.addChild(floatLayer);
			tagLayer = new Sprite();
			tagLayer.mouseEnabled = tagLayer.mouseChildren = false;
			worldLayer.addChild(tagLayer);
			questArrow = new Shape();
			var qg:* = questArrow.graphics;
			qg.lineStyle(2, 0x2a1a00);
			qg.beginFill(0xffd75e);
			qg.moveTo(15, 0); qg.lineTo(-8, -10); qg.lineTo(-3, 0); qg.lineTo(-8, 10); qg.lineTo(15, 0);
			qg.endFill();
			questArrow.visible = false;
			worldLayer.addChild(questArrow);
			questTf = Ui.text(12, 0xffd75e, true, "center", 160, true);
			questTf.visible = false;
			worldLayer.addChild(questTf);
			nameTag = Ui.text(13, 0xffe36e, true, "center", 140, true);
			nameTag.text = name;
			worldLayer.addChild(nameTag);

			statusTf = Ui.text(14, 0xff9a40, true, "center", 320, true);
			worldLayer.addChild(statusTf);
			atmo = new Shape();
			addChild(atmo);
			flashShape = new Shape();
			flashShape.graphics.beginFill(0xffffff);
			flashShape.graphics.drawRect(0, 0, VIEW_W, VIEW_H);
			flashShape.graphics.endFill();
			flashShape.alpha = 0;
			flashShape.visible = false;
			addChild(flashShape);
			addChild(makeVignette());
			streakTf = Ui.text(22, Ui.GOLD, true, "center", 360, true);
			streakTf.x = VIEW_W / 2 - 180; streakTf.y = 78;
			streakTf.visible = false;
			addChild(streakTf);
			buffTf = Ui.text(14, 0xffffff, true, "center", 500, true);
			buffTf.x = VIEW_W / 2 - 250; buffTf.y = 116;
			addChild(buffTf);
			streakBar = new Shape();
			streakBar.x = VIEW_W / 2 - 60; streakBar.y = 108;
			addChild(streakBar);
			setZoom(Save.data.opt && Save.data.opt.zoom ? Number(Save.data.opt.zoom) : 0.8);

			chat = Ui.text(15, 0xffffff, false, "left", 620, true);
			chat.x = 8;
			addChild(chat);

			banner = Ui.text(30, Ui.GOLD, true, "center", VIEW_W, true);
			banner.y = 110;
			banner.visible = false;
			addChild(banner);

			buildCounters();
			netTf = Ui.text(12, 0x9ad0ff, true, "right", 300, true);
			netTf.x = VIEW_W - 312; netTf.y = 50;
			netTf.mouseEnabled = false;
			addChild(netTf);
			buildBossPanel();
			buildNexus();
			sync = new WorldSync(this);
			net = Online.connected ? new ServerNet(this) : new LocalNet(this);
			net.enterWorld(world);

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

		/** slash commands; anything else is said in chat. */
		public function runCommand(t:String):void {
			if (t.charAt(0) != "/") {
				pushChat("<font color='#ffe36e'><b>&lt;" + player.name + "&gt;</b></font> " + t.replace(/</g, "&lt;"));
				net.chat(t);
				return;
			}
			var cmd:String = t.split(" ")[0].toLowerCase();
			switch (cmd) {
				case "/help":
					msg("Commands: /nexus  /realm  /glands  /stats  /quests  /achievements  /who  /trade name  /inspect name", 0x8fd0ff);
					msg("Social: /party  /p msg  /guild  /guild create Name  /g msg  /tp name  /join name  (L opens the party & guild window)", 0x8fd0ff);
					break;
				case "/p":
					var pt:String = t.substr(3);
					if (!net.party.length) { msg("You're not in a party. Invite players from their menu.", 0xff8080); break; }
					if (pt) { channelSay(player.name, pt, "party"); net.partyChat(pt); }
					break;
				case "/g":
					var gt:String = t.substr(3);
					if (!net.guild) { msg("You're not in a guild.", 0xff8080); break; }
					if (gt) { channelSay(player.name, gt, "guild"); net.guildChat(gt); }
					break;
				case "/party": case "/guild":
					var sub:String = (t.split(" ")[1] || "").toLowerCase();
					var rest:String = t.split(" ").slice(2).join(" ");
					var isParty:Boolean = cmd == "/party";
					if (!sub) { toggleSocial(isParty ? 0 : 1); break; }
					if (sub == "create" && !isParty) { createGuild(rest); break; }
					if (sub == "leave") { if (isParty) net.leaveParty(); else net.leaveGuild(); break; }
					if (sub == "invite" || sub == "kick") {
						var who2:RemotePlayer = rest ? net.find(rest) : null;
						if (sub == "kick" && !isParty) { net.kickGuild(rest); break; }
						if (!who2) { msg("No player called " + rest + " here.", 0xff8080); break; }
						if (isParty) { if (sub == "invite") net.inviteParty(who2); else net.kickParty(who2); }
						else net.inviteGuild(who2);
						break;
					}
					msg("Usage: " + cmd + (isParty ? " invite|kick name, /party leave, /p message" : " create Name, /guild invite|kick name, /guild leave, /g message"), 0xff8080);
					break;
				case "/tp": case "/teleport":
					var tpw:RemotePlayer = net.find(t.split(" ")[1] || "");
					if (tpw) teleportTo(tpw); else msg("Usage: /tp name (party or guild member here)", 0xff8080);
					break;
				case "/report": case "/kick": case "/ban": case "/unban": case "/mute": case "/unmute": case "/announce":
					if (!net.online) { msg(cmd + " works when you're playing online.", 0xff8080); break; }
					net.serverCommand(t);
					break;
				case "/wiki":
					toggleWiki();
					break;
				case "/join":
					joinPlayer(t.split(" ")[1] || "");
					break;
				case "/who":
					var who:Array = [];
					for each (var rp:RemotePlayer in net.players) who.push(rp.name);
					msg(who.length ? "Players here (" + who.length + "): " + who.join(", ") : "Nobody else is here.", 0x8fd0ff);
					msg(net.online ? "Online on " + Online.address + "." : "Playing offline (other players are simulated).", 0x8fd0ff);
					break;
				case "/trade": case "/tr":
				case "/inspect": case "/in":
					var arg:String = t.split(" ")[1] || "";
					var target:RemotePlayer = arg ? net.find(arg) : null;
					if (!target) { msg(arg ? "No player called " + arg + " here. Try /who." : "Usage: " + cmd + " <name>", 0xff8080); break; }
					if (cmd == "/trade" || cmd == "/tr") net.requestTrade(target);
					else openInspect(target);
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
				case "/admin":
					toggleAdmin();
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
			Ui.panel(pauseLayer.graphics, Ui.W / 2 - 190, 20, 380, 600, 0x262626, 0x6a6a6a);
			var pt1:TextField = Ui.text(30, 0xffffff, true, "center", Ui.W, true);
			pt1.text = "Paused - Settings";
			pt1.y = 28;
			pauseLayer.addChild(pt1);
			pauseButtons = new Sprite();
			pauseLayer.addChild(pauseButtons);
			pauseLayer.visible = false;
			addChild(pauseLayer);
			refreshPauseMenu();
		}

		private function refreshPauseMenu():void {
			pauseButtons.removeChildren();
			var onOff:Function = function(name:String):String { return opt(name) ? "On" : "Off"; };
			var toggle:Function = function(name:String):Function {
				return function():void { setOpt(name, !opt(name)); refreshPauseMenu(); };
			};
			var rows:Array = [
				["Resume", function():void { setPaused(false); }],
				["slider"],
				["Sound: " + (Sfx.muted ? "Off" : "On"), function():void { Sfx.muted = !Sfx.muted; refreshPauseMenu(); }],
				["Show players: " + (opt("allplayers") ? "Everyone" : "Party & guild"), toggle("allplayers")],
				["Player names: " + onOff("names"), toggle("names")],
				["Chat bubbles: " + onOff("bubbles"), toggle("bubbles")],
				["Damage numbers: " + onOff("dmg"), toggle("dmg")],
				["Particles: " + onOff("parts"), toggle("parts")],
				["Screen shake: " + onOff("shake"), toggle("shake")],
				["Save & Quit to Menu", function():void { saveCharacter(); Online.sendSave(); quitRequested = true; }]
			];
			var y:int = 76;
			for (var i:int = 0; i < rows.length; i++) {
				if (rows[i][0] == "slider") {
					var sl:Sprite = Ui.slider("Volume", 280, Sfx.volume, function(v:Number):void { Sfx.volume = v; });
					sl.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void { Sfx.play("coin"); });
					sl.x = Ui.W / 2 - 140;
					sl.y = y;
					pauseButtons.addChild(sl);
					y += 56;
					continue;
				}
				var b:Sprite = Ui.button(rows[i][0], 300, 40, rows[i][1], 16);
				b.x = Ui.W / 2 - 150;
				b.y = y;
				pauseButtons.addChild(b);
				y += i == rows.length - 2 ? 58 : 50;
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
			// damage meter, styled like the RotMG boss leaderboard
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

		private static const PORTAL_COLORS:Array = [0x4aa8ff, 0xff5ac8, 0x5ae06a, 0xffb040, 0xc080ff, 0x40e0e0];

		private function buildNexus():void {
			// online servers can run up to 6 realms at once
			var px:Array = Online.connected ? [88.5, 93.5, 98.5, 103.5, 108.5, 113.5] : [90.5, 100.5, 110.5];
			for (var i:int = 0; i < px.length; i++) addPortal(nexusWorld, px[i], 84.2, "realm", i, PORTAL_COLORS[i]);
			var saved:Array = Save.data.vault as Array;
			var items:Array = [];
			if (saved) for each (var it:Object in saved) if (it && items.length < LootBag.MAX) items.push(it);
			vaultBag = new LootBag(83.5, 100.5, items);
			vaultBag.vault = true;
			vaultBag.refresh();
			nexusWorld.bags.push(vaultBag);
			vaultLabel = makeLabel("Vault", Ui.GOLD);

			// nexus stations: the Starforge (east) and the Marketplace (by the spawn)
			stations.push({x: 116.5, y: 100.5, kind: "forge", spr: "anvil", label: makeLabel("Starforge", 0xc080ff)});
			stations.push({x: 106.5, y: 111.5, kind: "market", spr: "merchant", label: makeLabel("Marketplace", 0x6fe08f)});
			stations.push({x: 94.5, y: 111.5, kind: "quests", spr: "questboard", label: makeLabel("Quest Board", 0xf0d080)});
			stations.push({x: 84.5, y: 93.5, kind: "skins", spr: "famekeeper", label: makeLabel("Fame Store", 0xff9a2e)});
			stations.push({x: 116.5, y: 93.5, kind: "pets", spr: "nest", label: makeLabel("Pet Yard", 0x60c0ff)});
			stations.push({x: 116.5, y: 107.5, kind: "raids", spr: "raidtable", label: makeLabel("Raid Table", 0xff3050)});

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
			worldLayer.addChildAt(lab, worldLayer.getChildIndex(floatLayer));
			return lab;
		}

		private function addPortal(w:World, x:Number, y:Number, kind:String, idx:int, color:uint, life:Number = 0, seed:uint = 0, share:Boolean = true):void {
			var lab:TextField = makeLabel("", 0xffffff);
			lab.visible = w == world;
			if (kind == "dungeon" && !seed) seed = 1 + uint(Math.random() * 0x7ffffffe);
			var p:Object = {x: x, y: y, kind: kind, idx: idx, color: color, label: lab, life: life, seed: seed};
			w.portals.push(p);
			// dropped dungeon portals are shared: everyone here can enter the same dungeon
			if (share && kind == "dungeon" && w == world && w.key != "nexus") sync.portal(p);
		}

		/** The world host dropped a dungeon portal. */
		public function netPortal(x:Number, y:Number, kind:String, idx:int, color:uint, life:Number, seed:uint):void {
			if (kind == "raid" && Bosses.RAIDS[idx]) {
				addPortal(world, x, y, kind, idx, color, life, seed, false);
				showBanner(Bosses.RAIDS[idx].name + " is open!", color, 3);
				msg("A portal to " + Bosses.RAIDS[idx].name + " has opened by the Raid Table!", color);
				return;
			}
			if (kind != "dungeon" || !Data.DUNGEONS[idx]) return;
			addPortal(world, x, y, kind, idx, color, life, seed, false);
			msg("A portal to the " + Data.DUNGEONS[idx].name + " has opened!", Data.DUNGEONS[idx].color);
		}

		/** A realm event appeared on the host's game. */
		public function eventAppeared(e:Enemy):void {
			showBanner(e.def.name + " has appeared!", 0xff70ff, 3.5);
			Sfx.play("boss");
			player.bossDmg = 0;
		}

		/** Online: run fn once we know this game runs the world's monsters (offline: now). */
		private function whenHost(fn:Function):void {
			if (!net.online || sync.hostKey == world.key) fn();
			else world.pendingPopulate = fn;
		}

		private function saveVault():void {
			Save.data.vault = vaultBag.items.concat();
			Save.flush();
		}

		private function realmStatus(i:int):String {
			if (net && net.online) return (realmCounts[i] || 0) + " / " + realmCap + " players";
			var r:World = realms[i];
			if (!r) return "New realm";
			if (r.closed) return "Closed - new realm";
			if (r.boss) return r.boss.def.name + " is awake!";
			return "Events " + r.eventsDone + "/" + Data.EVENTS_PER_REALM;
		}

		private function portalTitle(p:Object):String {
			if (p.kind == "realm") return realmNames[p.idx] + " Realm";
			if (p.kind == "dungeon") return Data.DUNGEONS[p.idx].name;
			if (p.kind == "elder") return "Dark Elder's Chamber";
			if (p.kind == "raid") return Bosses.RAIDS[p.idx].name;
			return "Nexus";
		}

		public function usePortal(p:Object):void {
			travel(function():void { usePortalNow(p); });
		}

		public function usePortalNow(p:Object):void {
			if (p.kind == "realm") enterPortal(p.idx);
			else if (p.kind == "dungeon") enterDungeon(p.idx, p.seed);
			else if (p.kind == "elder") enterArena();
			else if (p.kind == "raid") enterRaid(p.idx, p.seed);
			else nexusNow();
		}

		// ------------------------------------------------------------- admin menu
		public function toggleAdmin():void {
			// online, only the server's admins get the testing tools
			if (net && net.online && !(Online.welcome && Online.welcome.admin) && !(admin && admin.visible)) {
				msg("The admin menu is turned off on this server.", 0xff8080);
				return;
			}
			if (!admin) {
				admin = new AdminMenu(this);
				admin.x = int((VIEW_W - AdminMenu.W) / 2);
				admin.y = 56;
				admin.visible = false;
			}
			admin.visible = !admin.visible;
			if (admin.visible) {
				addChild(admin);
				if (paused) setPaused(false);
			}
		}

		/** True while the mouse is over a panel that should swallow clicks (no shooting through it). */
		public function uiCaptured():Boolean {
			var mx:Number = stage.mouseX, my:Number = stage.mouseY;
			for each (var w:Sprite in [playerMenu, tradeWin, inspectWin, requestPopup, social, wiki]) if (w && w.hitTestPoint(mx, my, true)) return true;
			return admin != null && admin.visible && admin.hitTestPoint(mx, my, true);
		}

		public function adminRefresh():void {
			hud.refresh();
		}

		public function adminMaxLevel():void {
			for (var n:int = 0; n < 40 && player.level < Player.MAX_LEVEL; n++) player.gainXp(Math.max(1, player.xpNext - player.xp), this);
			player.hp = player.maxHp; player.mp = player.maxMp;
		}

		public function adminMaxStats():void {
			for each (var s:String in Data.STATS) player.stats[s] = player.cls.max[s];
			player.hp = player.maxHp; player.mp = player.maxMp; player.pt = player.maxPt;
			questEvent("maxed");
			msg("All 11 stats maxed.", Ui.GOLD);
		}

		/** Spawns a monster or boss a few tiles in front of you, toward the mouse. */
		public function adminSpawn(id:String, boss:Boolean):void {
			var aim:Number = Math.atan2(screenToWorldY(input.my, input.mx) - player.y, screenToWorldX(input.mx, input.my) - player.x);
			// toward the mouse first, then further out and in other directions (safe zones block monsters)
			for (var tries:int = 0; tries < 120; tries++) {
				var a:Number = aim + (tries < 10 ? 0 : (Math.random() - 0.5) * Math.PI * 2);
				var d:Number = (boss ? 6 : 4) + (tries < 10 ? tries * 0.6 : Math.random() * 10);
				var x:Number = player.x + Math.cos(a) * d + (boss ? 0 : (Math.random() - 0.5) * 2);
				var y:Number = player.y + Math.sin(a) * d + (boss ? 0 : (Math.random() - 0.5) * 2);
				if (!world.canStand(x, y, 0.4, true)) continue;
				var e:Enemy = new Enemy(id, x, y, Math.max(0, Math.min(World.GOD_ZONE, world.zoneAt(x, y))));
				if (boss) {
					e.homeX = x; e.homeY = y;
					if (!world.boss) { world.boss = e; player.bossDmg = 0; }
				}
				enemies.push(e);
				burst(x, y, e.def.col, 12);
				return;
			}
			msg("No room to spawn there (safe zones and walls block monsters).", 0xff8080);
		}

		public function adminKillAll():void {
			for each (var e:Enemy in enemies.concat()) if (!e.dead) killEnemy(e);
		}

		public function adminFinishEvents():void {
			if (world.kind != "realm") { msg("Only works inside a realm.", 0xff8080); return; }
			world.eventsDone = Data.EVENTS_PER_REALM;
			world.closeT = 6;
			showBanner("The realm is closing!", 0xff5050, 3);
		}

		public function adminSpawnEvent():void {
			if (world.kind != "realm") { msg("Only works inside a realm.", 0xff8080); return; }
			if (world.boss) { msg("A boss is already alive here.", 0xff8080); return; }
			spawnEvent();
		}

		public function adminRevealMap():void {
			world.reveal(world.N / 2, world.N / 2, world.N);
		}

		public function adminDungeonPortal(i:int):void {
			addPortal(world, player.x + 1.5, player.y, "dungeon", i, Data.DUNGEONS[i].color, 120);
			msg("Opened a portal to the " + Data.DUNGEONS[i].name + ".", Data.DUNGEONS[i].color);
		}

		public function adminRealmPortal():void {
			var i:int = int(Math.random() * 3);
			addPortal(world, player.x + 1.5, player.y, "realm", i, PORTAL_COLORS[i], 120);
		}

		public function adminEnterDungeon(i:int):void {
			travel(function():void { enterDungeon(i); });
		}

		/** Admin: one key for every raid (into free inventory slots). */
		public function adminGiveKeys():void {
			for (var i:int = 0; i < Bosses.RAIDS.length; i++) {
				var slot:int = player.freeSlot();
				if (slot < 0) { msg("Inventory full.", 0xff8080); break; }
				player.inv[slot] = Data.makeKey(i);
			}
			hud.refresh();
			saveCharacter();
		}

		public function adminEnterRaid(i:int):void {
			travel(function():void { enterRaid(i, 1 + uint(Math.random() * 0x7ffffffe)); });
		}

		public function adminEnterArena():void {
			toggleAdmin();
			travel(enterArena);
		}

		/** Puts an item in the first free inventory slot, or in a bag at your feet. */
		public function giveItem(item:Object):void {
			var slot:int = player.freeSlot();
			if (slot >= 0) player.inv[slot] = item;
			else dropAtPlayer(item);
			msg("Received " + item.name + ".", item.rarity ? Data.RARITY_COLORS[item.rarity] : 0xcccccc);
		}

		/** Fades the view to black, runs fn (a world switch), then fades back in. */
		public function travel(fn:Function):void {
			if (travelFn != null || dyingT > 0 || deathInfo) return;
			travelFn = fn;
			fadeTarget = 1;
		}

		private function updateFade(dt:Number):void {
			if (fadeA < fadeTarget) fadeA = Math.min(fadeTarget, fadeA + dt * 4.5);
			else if (fadeA > fadeTarget) fadeA = Math.max(fadeTarget, fadeA - dt * 2.5);
			if (fadeA >= 1 && travelFn != null) {
				var fn:Function = travelFn;
				travelFn = null;
				fn();
				fadeTarget = 0;
			}
			var deathFade:Number = dyingT > 0 ? Math.max(0, 1 - dyingT / (DYING_TIME * 0.5)) : 0;
			if (fadeShape) {
				fadeShape.alpha = Math.max(fadeA, deathFade);
				fadeShape.visible = fadeShape.alpha > 0.01;
			}
		}

		/** RotMG-style death: the world drains to grey and fades out before the death screen. */
		private function updateDying(dt:Number):void {
			time += dt;
			dyingT -= dt;
			var i:int;
			for (i = enemies.length - 1; i >= 0; i--) if (!enemies[i].dead) enemies[i].update(dt, this);
			updateShots(dt);
			updateParticles(dt);
			updateFloaters(dt);
			var k:Number = Math.min(1, (1 - dyingT / DYING_TIME) * 1.8);
			var s:Number = 1 - k;
			var r:Number = 0.299 * (1 - s), gg:Number = 0.587 * (1 - s), b:Number = 0.114 * (1 - s);
			canvasBmp.filters = [new ColorMatrixFilter([
				r + s, gg, b, 0, 0,
				r, gg + s, b, 0, 0,
				r, gg, b + s, 0, 0,
				0, 0, 0, 1, 0])];
			if (dyingT <= 0) canvasBmp.filters = [];
		}

		private function dustColor():uint {
			var t:int = world.tileAt(player.x, player.y);
			return t == World.SAND ? 0xe8d8a0 : t == World.GRASS || t == World.DARK || t == World.HIGH ? 0x9ab070 : 0xb0b0b8;
		}

		private function makeVignette():Bitmap {
			var sh:Shape = new Shape();
			var m:Matrix = new Matrix();
			m.createGradientBox(VIEW_W * 1.25, VIEW_H * 1.45, 0, -VIEW_W * 0.125, -VIEW_H * 0.225);
			sh.graphics.beginGradientFill("radial", [0x000000, 0x000000], [0, 0.42], [150, 255], m);
			sh.graphics.drawRect(0, 0, VIEW_W, VIEW_H);
			sh.graphics.endFill();
			var bd:BitmapData = new BitmapData(VIEW_W, VIEW_H, true, 0);
			bd.draw(sh);
			return new Bitmap(bd);
		}

		/** A ring of sparks expanding outwards (level ups, big moments). */
		public function ring(x:Number, y:Number, color:uint, n:int = 28):void {
			if (!opt("parts")) return;
			var bd:BitmapData = Sprites.spark(color);
			for (var i:int = 0; i < n; i++) {
				var a:Number = i * Math.PI * 2 / n;
				parts.push(new Particle(x, y, Math.cos(a) * 9, Math.sin(a) * 9, 0.6, bd));
			}
		}

		/** dungeon: rooms of monsters with a boss at the end. */
		private static function soloKey():String {
			return "solo:" + int(Math.random() * 1e9);
		}

		/** seed 0 = a new dungeon; party members can follow you in with /join (same seed, same layout). */
		private function enterDungeon(idx:int, seed:uint = 0):void {
			var th:Object = Data.DUNGEONS[idx];
			if (!seed) seed = 1 + uint(Math.random() * 0x7ffffffe);
			dungeonWorld = new World("dungeon", th.name, th, seed);
			dungeonWorld.key = "dg:" + idx + ":" + seed;
			Sfx.play("portal");
			switchWorld(dungeonWorld, dungeonWorld.spawnX, dungeonWorld.spawnY);
			var dw:World = dungeonWorld;
			whenHost(function():void { populateDungeon(dw, th); });
			player.bossDmg = 0;
			showBanner(th.name, th.color, 3);
			if (th.trio) msg("You enter the " + th.name + ". Three kings rest in the last hall. Each one that falls makes the others stronger.", th.color);
			else if (th.toElder) msg("You storm " + th.name + ". Slay Azrakor's two lieutenants to open the way to his chamber.", th.color);
			else if (th.guardians) msg("You enter the " + th.name + ". Its master is sealed until both guardians fall.", th.color);
			else msg("You enter the " + th.name + ". Its master waits in the last chamber.", th.color);
		}

		private function populateDungeon(dungeonWorld:World, th:Object):void {
			if (world != dungeonWorld) return;
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
			// crates in some rooms (a few of them bite)
			for (r = 1; r < rooms.length - 1; r++) {
				if (Math.random() > 0.45) continue;
				var crm:Object = rooms[r];
				for (k = 1 + int(Math.random() * 2); k > 0; k--) spawnEnemy("crate", crm.x + (Math.random() - 0.5) * (crm.w - 3), crm.y + (Math.random() - 0.5) * (crm.h - 3), th.tier);
			}
			var tr:Object = dungeonWorld.treasure;
			if (tr) {
				spawnEnemy("treasure", tr.x + 0.5, tr.y + 0.5, th.tier);
				for (k = 0; k < 3; k++) spawnEnemy(th.mobs[int(Math.random() * th.mobs.length)], tr.x + 0.5 + (k - 1) * 2, tr.y + 2, th.tier);
			}
			var last:Object = rooms[rooms.length - 1];
			var e:Enemy;
			var gi:int;
			// guardians wait in the middle rooms
			if (th.guardians) {
				for (gi = 0; gi < th.guardians.length; gi++) {
					var gr:Object = rooms[Math.max(1, Math.round((gi + 1) * (rooms.length - 1) / (th.guardians.length + 1)))];
					e = new Enemy(th.guardians[gi], gr.x + 0.5, gr.y + 0.5, th.tier);
					dungeonWorld.enemies.push(e);
				}
			}
			// three kings share the last hall
			if (th.trio) {
				for (gi = 0; gi < th.trio.length; gi++) {
					e = new Enemy(th.trio[gi], last.x + 0.5 + (gi - 1) * 5, last.y + 0.5 + (gi == 1 ? -2 : 1), th.tier);
					dungeonWorld.enemies.push(e);
					if (gi == 0) dungeonWorld.boss = e;
				}
			}
			if (th.boss) {
				dungeonWorld.boss = new Enemy(th.boss, last.x + 0.5, last.y + 0.5, th.tier);
				if (dungeonWorld.boss.def.sealed) dungeonWorld.boss.invuln = true;
				dungeonWorld.enemies.push(dungeonWorld.boss);
			}
			// elite monsters in the hard dungeons
			if (th.hard) {
				for each (e in dungeonWorld.enemies) {
					if (e.def.treasure) continue;
					e.maxHp *= th.hard;
					e.hp = e.maxHp;
					e.dmgMult = 1 + (th.hard - 1) * 0.6;
				}
			}
			if (th.hard) msg("Elite monsters: everything here is tougher than usual.", 0xff8080);
			saveCharacter();
		}

		/** Persist the current character (RotMG keeps characters until they die). */
		public function saveCharacter():void {
			if (deathInfo || player.hp <= 0) return;
			Save.storeChar(player.serialize());
		}

		/** Walk through a nexus portal into its realm. */
		/** The server's realm list changed (new realm, one closed, populations). */
		public function realmsUpdated(list:Array):void {
			for (var i:int = 0; i < 6; i++) {
				var r:Object = list[i];
				if (!r) { realmNames[i] = null; continue; }
				if (realmNames[i] != r.name || realmSeeds[i] != uint(r.seed)) {
					// a different realm in this slot: build it fresh next time
					realmNames[i] = r.name;
					realmSeeds[i] = uint(r.seed);
					realms[i] = null;
				}
				realmCounts[i] = r.count || 0;
				realmCap = r.cap || 85;
			}
		}

		/** The server refused our save: carry on from its copy. */
		public function saveRejected(reason:String):void {
			msg("The server refused your save (" + reason + "). Your character was restored from the server's copy.", 0xff8080);
			for each (var c:Object in Save.chars) if (c && c.id == player.id) { player.restore(c); hud.refresh(); return; }
			msg("This character isn't on the server. Save & Quit and pick a character.", 0xff8080);
		}

		public function enterPortal(i:int):void {
			if (net.online && realmCounts[i] >= realmCap && world != realms[i]) {
				msg(realmNames[i] + " is full (" + realmCap + " players). Try another realm.", 0xff8080);
				return;
			}
			var r:World = realms[i];
			if (!r || r.closed) {
				if (r && r.closed && !net.online) {
					var pool:Array = Data.REALM_NAMES.filter(function(n:String, ...a):Boolean { return realmNames.indexOf(n) < 0; });
					realmNames[i] = pool[int(Math.random() * pool.length)];
				}
				var seed:uint = net.online ? realmSeeds[i] : 0;
				r = realms[i] = new World("realm", realmNames[i], null, seed);
				r.key = net.online ? "realm:" + realmNames[i] + ":" + seed : soloKey();
			}
			switchWorld(r, r.spawnX, r.spawnY);
			Sfx.play("portal");
			showBanner(r.name + " Realm", PORTAL_COLORS[i], 3);
			msg("You have entered the " + r.name + " realm.", Ui.GOLD);
			tip("realm", "Hold the left mouse button to shoot and dodge the bullets. Better loot lies inland; /glands jumps to the Godlands.");
			taunt(r.boss ? r.boss.def.name + " awaits you, fool!" : "Another fool enters my " + r.name + " realm...");
		}

		private function switchWorld(w:World, x:Number, y:Number):void {
			if (world && world != w) world.releaseGround();
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
			lastSite = null;
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
			closePlayerMenu();
			closeInspect();
			closeRequest(true);
			questTarget = null;
			questT = 0;
			if (net) net.enterWorld(w);
		}

		private function onAdded(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			input = new Input(stage);
			fadeShape = new Shape();
			fadeShape.graphics.beginFill(0x000000);
			fadeShape.graphics.drawRect(0, 0, Ui.W, Ui.H);
			fadeShape.graphics.endFill();
			fadeShape.alpha = 1;
			addChild(fadeShape);
			lastT = getTimer();
			addEventListener(Event.ENTER_FRAME, tick);
			showBanner("Nexus", 0xffffff, 2.5);
			msg((player.kills > 0 ? "Welcome back, " : "Welcome to the Nexus, ") + player.name + "!", Ui.GOLD);
			saveCharacter();
			msg("Walk into a portal to the north and press Enter to travel to a realm.", 0xcccccc);
			msg("The fountain heals you. Vault (west) stores items, Starforge (east) crafts Starforged gear, Marketplace (south) buys and sells.", 0xcccccc);
			msg("In a realm: WASD move, mouse shoots, SPACE ability, F/G potions, R returns to the Nexus.", 0xcccccc);
			msg("Click another player to inspect them or trade.", 0xcccccc);
			tip("nexus", "Press Enter to chat or type commands; /help lists them (try /glands in a realm).");
			if (net.online) {
				var self:Game = this;
				Online.onSaveRejected = function(reason:String):void { self.saveRejected(reason); };
				if (Online.welcome.motd) msg("[" + Online.address + "] " + Online.welcome.motd, Ui.GOLD);
			}
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
			if (input.pressed(192) || input.pressed(223)) toggleAdmin();
			if (input.pressed(Keyboard.ESCAPE) && (tradeWin || inspectWin || playerMenu || social || wiki)) {
				if (playerMenu) closePlayerMenu();
				else if (wiki) toggleWiki();
				else if (social) toggleSocial();
				else if (inspectWin) closeInspect();
				else closeTrade();
				input.endFrame();
			}
			if (tradeWin) tradeWin.update();
			if (!(chatInput && chatInput.visible)) updateZoom();
			if (admin && admin.visible && input.pressed(Keyboard.ESCAPE)) toggleAdmin();
			else if (input.pressed(Keyboard.ESCAPE) || input.pressed(Keyboard.P)) setPaused(!paused);
			if (dyingT > 0) updateDying(dt);
			else if (!paused) update(dt);
			updateFade(dt);
			render();
			hud.refresh();
			updateOverlays();
			input.endFrame();

			if (deathInfo && dyingT <= 0) {
				var info:Object = deathInfo;
				deathInfo = null;
				onDeath(info);
			} else if (quitRequested && onQuit != null) {
				quitRequested = false;
				onQuit();
			}
		}

		/** The server is gone for good: back to the title screen (your last save is on the server). */
		public function lostConnection(err:String):void {
			msg("Lost connection to the server (" + err + "). Returning to the title screen...", 0xff8080);
			saveCharacter();
			quitRequested = true;
		}

		private function update(dt:Number):void {
			time += dt;
			Data.viewerLevel = player.level;
			Data.viewerClass = player.cls.id;
			var i:int;
			player.update(dt, this);
			net.update(dt);
			updatePlayerClicks(dt);
			if (tpT > 0) tpT -= dt;
			if (input.pressed(Keyboard.L)) toggleSocial();
			if (input.pressed(Keyboard.K)) toggleWiki();
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
			if (world.kind == "realm" && sync.isHost) {
				updateSpawns(dt);
				updateEvents(dt);
			}
			if (world.raid && sync.isHost) updateRaid(dt);
			updateLightning(dt);
			updateAtmosphere(dt);
			updateAmbient(dt);
			updateStreak(dt);
			updateShrines(dt);
			if (world.kind == "realm" && sync.isHost) updateGoblin(dt);
			if (sync.isHost) updateElites(dt);
			if (sync.isHost) scaleBosses(dt);
			sync.update(dt);
			netT -= dt;
			if (netT <= 0) {
				netT = 0.5;
				var sn:ServerNet = net as ServerNet;
				netTf.htmlText = !sn ? "" : !net.online ? "<font color='#ff8080'>Offline - reconnecting...</font>"
					: "Online  " + net.players.length + " here" + (sn.latency >= 0 ? "  " + sn.latency + " ms" : "") + (sync.isHost && world.key != "nexus" ? "  (host)" : "");
			}
			updateNexus(dt);
			updateTraps(dt);
			updatePet(dt);
			updateBossHelpers(dt);

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

			var here:Object = world.kind == "realm" ? world.siteAt(player.x, player.y, 3) : null;
			if (here != lastSite) {
				lastSite = here;
				if (here) {
					showBanner(here.name, here.color, 2.5);
					if (!here.found && !here.cleared) msg("You found the " + here.name + ". Defeat its leader for a bonus loot bag!", here.color);
					here.found = true;
				}
			}
			var z:int = world.zoneAt(player.x, player.y);
			if (z != lastZone && z >= 0) {
				if (lastZone != -2) showBanner(Data.ZONE_NAMES[z], [0xffe8a0, 0x9cff7a, 0x5ad05a, 0xd8d070, 0xd090ff, 0xffffff, 0xff5050, 0xffffff, 0xffffff, 0xffffff][z], 2.5);
				lastZone = z;
			}

			// the camera glides after the player instead of snapping
			updateCameraRotation(dt);
			var ck:Number = Math.min(1, dt * 12);
			camX += (player.x - camX) * ck;
			camY += (player.y - camY) * ck;

			// little dust puffs while walking
			if (player.moving && opt("parts")) {
				dustT -= dt;
				if (dustT <= 0) {
					dustT = 0.18;
					parts.push(new Particle(player.x + (Math.random() - 0.5) * 0.4, player.y + 0.35, (Math.random() - 0.5) * 0.6, -0.4, 0.3, Sprites.glow(dustColor())));
				}
			}

			if (godMode) player.hp = Math.max(player.hp, player.maxHp);
			if (player.hp <= 0 && !deathInfo) die();
		}

		private function updateNexus(dt:Number):void {
			if (opt("parts")) {
				for each (var sp:Object in world.portals) {
					if (Math.random() < dt * 7) {
						parts.push(new Particle(sp.x + (Math.random() - 0.5) * 0.9, sp.y + 0.2 - Math.random() * 0.6,
							(Math.random() - 0.5) * 0.4, -1.5 - Math.random() * 1.5, 0.7, Sprites.glow(sp.color)));
					}
				}
			}
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
				if (p.kind == "realm" && !realmNames[p.idx]) continue;
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
					if (net.online) net.realmClosed(world.key);
					msg("The " + world.name + " realm has closed.", 0xff8080);
					travel(enterCitadel);
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

		/** realm event: the overlord announces a boss somewhere inland. */
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
					tip("event", "Event bosses drop Runed and Bonded gear, Star Shards and dungeon portals. Kill " + Data.EVENTS_PER_REALM + " to face the Dark Elder.");
					return;
				}
			}
			world.eventT = 5;
		}

		/** The realm has closed: the Dark Elder pulls you into his chamber. */
		private function enterArena():void {
			arenaWorld = new World("arena", "Dark Elder's Chamber");
			// everyone coming from the same Citadel shares the chamber
			arenaWorld.key = net.online && world.kind == "dungeon" ? "arena:" + world.seed : soloKey();
			switchWorld(arenaWorld, arenaWorld.spawnX, arenaWorld.spawnY);
			player.invulnT = 3;
			var aw:World = arenaWorld;
			whenHost(function():void {
				if (world != aw) return;
				aw.boss = new Enemy("elder", 100.5, 91.5, World.ARENA_ZONE);
				aw.enemies.push(aw.boss);
			});
			player.bossDmg = 0;
			showBanner(Data.OVERLORD, 0xc060ff, 4);
			say(SOVEREIGN, "So, you slew my champions. Now kneel before the Dark Elder!");
		}

		private function updateShots(dt:Number):void {
			var p:Player = player;
			for (var i:int = shots.length - 1; i >= 0; i--) {
				var s:Projectile = shots[i];
				s.move(dt);
				s.life -= dt;
				// glowing trail behind your own shots
				if (!s.enemy && !s.bot && parts.length < 420 && Math.random() < 0.55 && opt("parts"))
					parts.push(new Particle(s.x, s.y, 0, 0, 0.14, Sprites.glow(s.trailCol)));
				var remove:Boolean = s.life <= 0;
				if (remove && s.split) splitShot(s);
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
					} else if (!s.ghost) {
						for (var j:int = 0; j < enemies.length; j++) {
							var e:Enemy = enemies[j];
							if (e.dead) continue;
							var ex:Number = s.x - e.x, ey:Number = s.y - e.y, er:Number = s.r + e.r;
							if (ex * ex + ey * ey < er * er) {
								if (s.pierce) {
									if (s.hits[e]) continue;
									s.hits[e] = true;
								}
								if (s.bot) botHit(e, s);
								else damageEnemy(e, s);
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

		/** A splitting boss shot bursts into a ring where it ends. */
		private function splitShot(s:Projectile):void {
			var sp:Object = s.split;
			var n:int = sp.n || 8;
			var fr:Vector.<BitmapData> = Sprites.projectile(sp.shape || "orb", sp.col || s.trailCol, 3);
			for (var k:int = 0; k < n; k++) {
				shots.push(new Projectile(s.x, s.y, s.angle + k * Math.PI * 2 / n, sp.spd || 5, sp.life || 1, sp.dmg || int(s.dmg * 0.6), true, 0.18, fr, false, s.owner, s.effect));
			}
		}

		private function damageEnemy(e:Enemy, s:Projectile):void {
			hurtEnemy(e, s.dmg, s.effect, s.x, s.y);
		}

		/** Player damage to an enemy: defense, crits (Luck/Might), weapon passives. */
		public function hurtEnemy(e:Enemy, raw:int, effect:String, hx:Number, hy:Number):void {
			if (e.dead) return;
			var p:Player = player;
			e.playerHit = true;
			if (e.immune) {
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
			if (e.remote) sync.hit(e, d, effect == "slow" ? 3 : 0, 0);
			if (opt("dmg")) floatText(e.x, e.y - e.r - 0.6, crit ? d + "!" : String(d), crit ? 0xffe040 : 0xff4040);
			if (effect == "slow") e.slowT = 3;
			// Starforged / Primordial passives (not from passive-spawned shards)
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
			// remote copies die when the host says so
			if (e.hp <= 0 && !e.remote) killEnemy(e);
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

		/** The host says a monster died (online). */
		public function remoteKill(e:Enemy):void { killEnemy(e, true); }
		/** Host: another player's hit finished a monster. */
		public function hostKill(e:Enemy):void { killEnemy(e); }

		/** Remove a monster without killing it (the host despawned it). */
		public function dropEnemy(e:Enemy):void {
			var i:int = enemies.indexOf(e);
			if (i >= 0) { enemies[i] = enemies[enemies.length - 1]; enemies.length--; }
			if (world.boss == e) world.boss = null;
		}

		/** remote: the kill came from the world host, so it doesn't roll shared things (portals) again. */
		private function killEnemy(e:Enemy, remote:Boolean = false):void {
			if (e.dead) return;
			e.dead = true;
			if (!remote) sync.killed(e);
			Sfx.play(e.isBoss ? "boss" : "kill", e.isBoss ? 1 : 0.6, 0.04);
			var p:Player = player;
			// kills by other players: you share the XP if you're close, but loot and credit need a hit of your own
			var mine:Boolean = e.playerHit;
			var dx:Number = e.x - p.x, dy:Number = e.y - p.y;
			var near:Boolean = dx * dx + dy * dy < 15 * 15;
			if (mine) {
				if (!e.def.crate) questEvent("kills");
				if (world.kind == "realm" && e.zone == World.GOD_ZONE) questEvent("godkills");
				if (world.kind == "realm" && e.zone == World.GOD_ZONE) p.godKills++;
				if (e.def.final || e.def.finale) { questEvent("elder"); p.elders++; }
				else if (e.def.dungeon && !e.def.guardian && !(e.def.trio && aliveWith("trio") > 0)) { questEvent("dungeon"); p.dungeons++; }
				else if (e.isBoss) questEvent("events");
				p.kills++;
				petGainXp(e.isBoss ? 20 : 1);
			}
			if (mine && !e.def.treasure && !e.def.crate) addStreak(e);
			if (e.def.crate) crateBroken(e, mine, remote);
			var xpMult:Number = 1 + Math.min(0.5, streakN / 100) + (e.elite ? 2 : 0);
			if (mine || near) p.gainXp(int(e.def.xp * xpMult), this);
			if (e.elite && !remote && e.elite == "Splitting") splitElite(e);
			if (e.elite && mine) { addGold(int(e.def.xp / 2) + 20); floatText(e.x, e.y - 1.2, "Elite slain!", eliteCol(e.elite)); }
			if (e.def.goblin) goblinDown(e, mine);
			burst(e.x, e.y, e.def.col, e.isBoss ? 60 : 12);
			if (dx * dx + dy * dy < 12 * 12) p.addSurge(this);

			// currencies (account-wide gold and Aether)
			var g:int = mine ? e.def.gold || int(e.def.xp / 6) : 0;
			if (g > 0) addGold(g);
			if (mine && e.def.onrane) addOnrane(e.def.onrane);
			if (mine && e.isBoss) floatText(e.x, e.y - 1.6, "+" + g + " gold  +" + (e.def.onrane || 0) + " Aether", Ui.GOLD);

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
				if (world.boss == e) world.boss = null;
				if (e.def.guardian) {
					guardianDown(e);
				} else if (e.def.trio && aliveWith("trio") > 0) {
					kingDown(e);
				} else if (e.def.dungeon) {
					showBanner(e.def.name + " has been defeated!", Ui.GOLD, 4);
					msg("Dungeon cleared! A portal back to the Nexus has opened.", Ui.GOLD);
					addPortal(world, e.x, e.y + 2, "nexus", 0, 0xffffff);
				} else if (e.def.raid) {
					var rdw:Object = world.raid;
					if (rdw && world.raidStage >= rdw.stages.length - 1 && aliveBosses() == 0) {
						showBanner(rdw.name + " conquered!", rdw.color, 5);
						msg("Raid complete! A portal back to the Nexus has opened.", Ui.GOLD);
						addPortal(world, e.x, e.y + 2, "nexus", 0, 0xffffff);
						questEvent("dungeon");
					} else showBanner(e.def.name + " has fallen!", rdw ? rdw.color : Ui.GOLD, 3);
				} else if (e.def.final) {
					showBanner(e.def.name + " has been defeated!", Ui.GOLD, 5);
					say(SOVEREIGN, "This... is not... the end...");
					msg("Eldritch loot has dropped! Take the portal back to the Nexus when you're ready.", 0xff6060);
					addPortal(world, e.x, e.y + 2, "nexus", 0, 0xffffff);
				} else {
					world.eventsDone++;
					world.eventT = 20 + Math.random() * 10;
					// events often leave a dungeon portal behind
					if (!remote && Math.random() < Data.DUNGEON_DROP_CHANCE) {
						var di:int = int(Math.random() * Data.EVENT_DUNGEONS);
						if (e.def.hardDungeon && Math.random() < 0.35) di = Data.dungeonIndex(e.def.hardDungeon);
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
			if (!remote && world.kind == "realm" && e.def.portal && Math.random() < e.def.portalChance) {
				var pi:int = Data.dungeonIndex(e.def.portal);
				if (pi >= 0) {
					var dd:Object = Data.DUNGEONS[pi];
					addPortal(world, e.x, e.y, "dungeon", pi, dd.color, 60);
					msg(e.def.name + " dropped a portal to the " + dd.name + "! (60s)", dd.color);
					Sfx.play("portal", 0.6);
					tip("dungeon", "Stand on the dungeon portal and press Enter before it closes!");
				}
			}
			var lootZone:int = Math.max(0, Math.min(World.GOD_ZONE, e.zone));
			var items:Array = mine ? Data.rollLoot(e.def, lootZone, p.cls, p.frt + lootLuck()) : [];
			// elites drop twice; the treasure goblin spills its whole sack
			if (mine && e.elite) items = items.concat(Data.rollLoot(e.def, lootZone, p.cls, p.frt + lootLuck() + 50));
			if (mine && e.def.goblin) items = items.concat(goblinLoot(lootZone));
			if (mine && e.def.crate) items = items.concat(crateLoot(lootZone));
			if (mine && e.def.mimic) items = items.concat(mimicLoot());
			var hoard:Array = siteCleared(e, mine);
			if (hoard) items = items.concat(hoard);
			if (items.length) {
				// more than one bag's worth spills into extra bags beside it
				var spill:Array = items.splice(LootBag.MAX);
				for (var sb:int = 0; spill.length && sb < 3; sb++) bags.push(new LootBag(e.x + 0.9 * (sb + 1), e.y + 0.4 * (sb % 2), spill.splice(0, LootBag.MAX)));
				var bag:LootBag = new LootBag(e.x, e.y, items);
				bags.push(bag);
				tip("bag", "Walk over a loot bag and click its items in the sidebar to take them.");
				// rare drop alerts
				for each (var ki:Object in items) if (ki.kind == "key") {
					showBanner(ki.name + " dropped!", ki.color, 4);
					msg("A raid key dropped: " + ki.name + "! Use it in the Nexus to open the raid.", ki.color);
					Sfx.play("rare");
					ring(e.x, e.y, ki.color, 30);
				}
				if (bag.spr == "bag_godly") {
					// a 1 in 5,000 drop: make a scene
					for each (var gi:Object in items) if (gi.rarity == "gd") {
						showBanner("GODLY DROP: " + gi.name + "!", Data.RARITY_COLORS.gd, 6);
						msg("*** You found a Godly item: " + gi.name + "! (1 in 5,000) ***", Data.RARITY_COLORS.gd);
						if (net.online) net.chat("I just found a Godly " + gi.name + "!!!");
					}
					Sfx.play("rare"); Sfx.play("level");
					shake(0.8, 10);
					burst(e.x, e.y, Data.RARITY_COLORS.gd, 60);
					ring(e.x, e.y, Data.RARITY_COLORS.gd, 40);
					questEvent("legendary");
				}
				if (bag.spr == "bag_relic" || bag.spr == "bag_legendary") questEvent("legendary");
				if (bag.spr == "bag_relic" || bag.spr == "bag_legendary" || bag.spr == "bag_fabled") {
					var kind:String = bag.spr == "bag_relic" ? Data.RARITY_NAMES.ar : bag.spr == "bag_legendary" ? Data.RARITY_NAMES.lg : Data.RARITY_NAMES.fb;
					var kc:uint = bag.spr == "bag_relic" ? Data.RARITY_COLORS.ar : bag.spr == "bag_legendary" ? Data.RARITY_COLORS.lg : Data.RARITY_COLORS.fb;
					showBanner(kind + " drop!", kc, 3);
					msg((/^[AEIOU]/.test(kind) ? "An " : "A ") + kind + " bag dropped from " + e.def.name + "!", kc);
					Sfx.play("rare");
					burst(e.x, e.y, kc, 30);
				} else if (bag.spr != "bag_brown") Sfx.play("loot", 0.7);
				if (bag.spr != "bag_brown") questEvent("rare");
			}
		}

		private function removeEnemyAt(i:int):void {
			sync.removed(enemies[i]);
			enemies[i] = enemies[enemies.length - 1];
			enemies.length--;
		}

		private function updateBags(dt:Number):void {
			nearBag = null;
			var best:Number = 1.0;
			for (var i:int = bags.length - 1; i >= 0; i--) {
				var b:LootBag = bags[i];
				if (!b.vault) b.life -= dt;
				b.age += dt;
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

		/** Everyone monsters care about here: you, plus other real players online. */
		private function playerSpots():Array {
			var out:Array = [player];
			if (net.online) for each (var rp:RemotePlayer in net.players) out.push(rp);
			return out;
		}

		// ------------------------------------------------------------ boss helpers
		private var pending:Array = [];
		private var markers:Array = [];

		/** Runs fn after secs of game time (multi-wave boss attacks). Cleared on leaving the world. */
		public function later(secs:Number, fn:Function):void {
			pending.push({t: secs, fn: fn, w: world});
		}

		/** A telegraphed blast: a circle on the ground fills up, then boom(). */
		public function addMarker(x:Number, y:Number, r:Number, delay:Number, col:uint, boom:Function):void {
			markers.push({x: x, y: y, r: r, t: 0, d: delay, col: col, fn: boom, w: world});
		}

		/** Area damage from a blast (only your own character; others check in their games). */
		public function areaHit(x:Number, y:Number, r:Number, dmg:int, src:String, eff:String, col:uint):void {
			burst(x, y, col, 14);
			ring(x, y, col, 18);
			var dx:Number = player.x - x, dy:Number = player.y - y;
			if (dx * dx + dy * dy < r * r && player.invulnT <= 0 && player.hp > 0) player.takeHit(dmg, src, this, eff);
			var sx:Number = (player.x - x), sy:Number = (player.y - y);
			if (sx * sx + sy * sy < 64) shake(0.15, 3);
		}

		public function countAlive(id:String):int {
			var n:int = 0;
			for each (var e:Enemy in enemies) if (!e.dead && e.defId == id) n++;
			return n;
		}

		private function updateBossHelpers(dt:Number):void {
			var i:int;
			for (i = pending.length - 1; i >= 0; i--) {
				var pd:Object = pending[i];
				if (pd.w != world) { pending.splice(i, 1); continue; }
				pd.t -= dt;
				if (pd.t <= 0) { pending.splice(i, 1); pd.fn(); }
			}
			for (i = markers.length - 1; i >= 0; i--) {
				var m:Object = markers[i];
				if (m.w != world) { markers.splice(i, 1); continue; }
				m.t += dt;
				if (m.t >= m.d) { markers.splice(i, 1); m.fn(); }
			}
			Projectile.homeX = player.x;
			Projectile.homeY = player.y;
		}

		private var markShape:Shape = new Shape();
		private var markMtx:Matrix = new Matrix();

		/** Ground circles for incoming blasts: an outline that fills as it gets closer. */
		private function drawMarkers():void {
			for each (var m:Object in markers) {
				var sx:Number = scrX(m.x, m.y), sy:Number = scrY(m.x, m.y);
				if (sx < -100 || sy < -100 || sx > vw + 100 || sy > vh + 100) continue;
				var f:Number = Math.min(1, m.t / m.d);
				var rx:Number = m.r * TS, ry:Number = rx * 0.6;
				var gr:* = markShape.graphics;
				gr.clear();
				gr.lineStyle(2, m.col, 0.9);
				gr.beginFill(m.col, 0.12);
				gr.drawEllipse(-rx, -ry, rx * 2, ry * 2);
				gr.endFill();
				gr.lineStyle();
				gr.beginFill(m.col, 0.25 + f * 0.25);
				gr.drawEllipse(-rx * f, -ry * f, rx * 2 * f, ry * 2 * f);
				gr.endFill();
				markMtx.tx = sx; markMtx.ty = sy + TS * 0.3;
				canvas.draw(markShape, markMtx);
			}
		}

		/** The nearest player a monster can see (others count online). */
		public function aggroTarget(e:Enemy):Object {
			var best:Object = null, bd:Number = 1e9;
			if (player.hp > 0 && player.invisT <= 0 && !world.isSafe(player.x, player.y) && dyingT <= 0) {
				bd = (player.x - e.x) * (player.x - e.x) + (player.y - e.y) * (player.y - e.y);
				best = player;
			}
			if (net.online) for each (var rp:RemotePlayer in net.players) {
				if (world.isSafe(rp.x, rp.y)) continue;
				var d:Number = (rp.x - e.x) * (rp.x - e.x) + (rp.y - e.y) * (rp.y - e.y);
				if (d < bd) { bd = d; best = rp; }
			}
			return best;
		}

		private function updateSpawns(dt:Number):void {
			spawnT -= dt;
			if (spawnT > 0) return;
			spawnT = 0.6;
			var spots:Array = playerSpots();
			// monsters too far from everyone despawn
			for (var i:int = enemies.length - 1; i >= 0; i--) {
				var e:Enemy = enemies[i];
				if (e.isBoss) continue;
				var keep:Boolean = false;
				for each (var sp:Object in spots) {
					var ddx:Number = e.x - sp.x, ddy:Number = e.y - sp.y;
					if (ddx * ddx + ddy * ddy < 34 * 34) { keep = true; break; }
				}
				if (!keep) removeEnemyAt(i);
			}
			updateSites(spots);
			// top up around one player at a time
			var who:Object = spots[int(Math.random() * spots.length)];
			if (world.isSafe(who.x, who.y)) who = player;
			var near:int = 0;
			for each (e in enemies) {
				var dx:Number = e.x - who.x, dy:Number = e.y - who.y;
				if (dx * dx + dy * dy < 24 * 24) near++;
			}
			// fewer monsters near the shore so new characters aren't swarmed
			var pz:int = world.zoneAt(who.x, who.y);
			var cap:int = pz == 0 ? 8 : pz == 1 ? 11 : pz == 2 ? 13 : pz == 3 ? 14 : MAX_ENEMIES_NEAR;
			if (near >= cap) return;
			for (var tries:int = 0; tries < 6; tries++) {
				var a:Number = Math.random() * Math.PI * 2;
				var r:Number = 14 + Math.random() * 8;
				var sx:Number = who.x + Math.cos(a) * r;
				var sy:Number = who.y + Math.sin(a) * r;
				var z:int = world.zoneAt(sx, sy);
				if (z < 0 || z > World.GOD_ZONE || !world.canStand(sx, sy, 0.4, true)) continue;
				// sometimes a little pile of crates instead of monsters
				if (z >= World.LOW_ZONE && Math.random() < 0.1) {
					for (var cr:int = 1 + int(Math.random() * 3); cr > 0; cr--) {
						var crx:Number = sx + Math.random() * 3 - 1.5, cry:Number = sy + Math.random() * 3 - 1.5;
						if (world.canStand(crx, cry, 0.45, true)) spawnEnemy("crate", crx, cry, z);
					}
					return;
				}
				var list:Array = Data.ZONE_SPAWNS[z];
				var id:String = list[int(Math.random() * list.length)];
				// small packs near the shore, bigger ones inland
				var count:int = 1 + int(Math.random() * (z <= 1 ? 2 : z == World.GOD_ZONE ? 2 : 3));
				for (var k:int = 0; k < count; k++) {
					var ox:Number = sx + Math.random() * 2 - 1, oy:Number = sy + Math.random() * 2 - 1;
					if (!world.canStand(ox, oy, 0.4, true)) continue;
					var ne:Enemy = spawnEnemy(id, ox, oy, z);
					// now and then a monster spawns as an elite with a special trait
					if (ne && z >= World.LOW_ZONE && Math.random() < 0.035) makeElite(ne);
				}
				return;
			}
		}

		/**
		 * Realm landmarks (host only): a player coming near an uncleared site
		 * wakes its leader and band; if they all wander off unbeaten (everyone
		 * left), the site resets for the next visitor.
		 */
		private function updateSites(spots:Array):void {
			for each (var s:Object in world.sites) {
				if (s.cleared) continue;
				var nearby:Boolean = false;
				for each (var sp:Object in spots) {
					var dx:Number = sp.x - s.x, dy:Number = sp.y - s.y, rr:Number = s.r + 12;
					if (dx * dx + dy * dy < rr * rr) { nearby = true; break; }
				}
				var leader:Enemy = siteLeader(s);
				if (s.active && !leader) s.active = false;
				if (s.active || !nearby || leader) continue;
				s.active = true;
				spawnEnemy(s.boss, s.x, s.y, s.zone);
				var extra:int = Math.min(4, Math.max(0, playerSpots().length - 1));
				for (var k:int = 0; k < s.n + extra; k++) {
					var a:Number = k * Math.PI * 2 / (s.n + extra) + Math.random() * 0.4;
					var d:Number = 2 + Math.random() * (s.r - 3);
					spawnEnemy(s.guards[k % s.guards.length], s.x + Math.cos(a) * d, s.y + Math.sin(a) * d, s.zone);
				}
			}
		}

		/** The living leader of a landmark, or null. */
		private function siteLeader(s:Object):Enemy {
			for each (var e:Enemy in enemies) {
				if (e.dead || e.defId != s.boss) continue;
				var dx:Number = e.x - s.x, dy:Number = e.y - s.y, rr:Number = s.r + 14;
				if (dx * dx + dy * dy < rr * rr) return e;
			}
			return null;
		}

		/** A landmark's leader died: the site is cleared for everyone in the realm. */
		private function siteCleared(e:Enemy, mine:Boolean):Array {
			if (world.kind != "realm") return null;
			for each (var s:Object in world.sites) {
				if (s.cleared || e.defId != s.boss) continue;
				var dx:Number = e.x - s.x, dy:Number = e.y - s.y, rr:Number = s.r + 14;
				if (dx * dx + dy * dy >= rr * rr) continue;
				s.cleared = true;
				s.active = false;
				var done:int = 0;
				for each (var o:Object in world.sites) if (o.cleared) done++;
				showBanner(s.name + " cleared!", s.color, 3);
				msg(s.name + " cleared! [" + done + "/" + world.sites.length + " landmarks in " + world.name + "]", s.color);
				ring(s.x, s.y, s.color, 30);
				// the leader's hoard: an extra roll of loot and some gold for whoever helped
				if (!mine) return null;
				addGold(25 + s.zone * 25);
				world.eventT -= 8; // clearing landmarks stirs the overlord
				return Data.rollLoot(e.def, Math.max(0, Math.min(World.GOD_ZONE, e.zone)), player.cls, player.frt);
			}
			return null;
		}

		public function spawnEnemy(id:String, x:Number, y:Number, zone:int):Enemy {
			if (!world.canStand(x, y, 0.35, true)) return null;
			var e:Enemy = new Enemy(id, x, y, zone);
			enemies.push(e);
			return e;
		}


		/** The boss the health panel and quest arrow follow: the nearest living boss, else the area boss. */
		private function focusBoss():Enemy {
			var best:Enemy = null, bestD:Number = 26 * 26;
			for each (var e:Enemy in enemies) {
				if (e.dead || !e.isBoss) continue;
				var d:Number = (e.x - player.x) * (e.x - player.x) + (e.y - player.y) * (e.y - player.y);
				if (d < bestD) { bestD = d; best = e; }
			}
			return best || world.boss;
		}

		private var scaleT:Number = 0;

		/**
		 * Endgame bosses get +80% health for every extra player in the world
		 * (online), or +40% per simulated party member offline. Health only goes
		 * up, keeping the same percentage, so leaving mid-fight doesn't help.
		 */
		private function scaleBosses(dt:Number):void {
			scaleT -= dt;
			if (scaleT > 0) return;
			scaleT = 1;
			var n:Number = 1 + (net.online ? net.players.length : net.party.length * 0.5);
			var mult:Number = 1 + 0.8 * (n - 1);
			for each (var e:Enemy in enemies) {
				if (e.dead || !e.isBoss || !e.def.scales || e.remote || mult <= e.scaleMult + 0.01) continue;
				var frac:Number = e.hp / e.maxHp;
				e.maxHp = e.maxHp / e.scaleMult * mult;
				e.hp = frac * e.maxHp;
				e.scaleMult = mult;
				e.scalePlayers = n;
				sync.rescaled(e);
			}
		}

		private function aliveBosses():int {
			var n:int = 0;
			for each (var e:Enemy in enemies) if (!e.dead && e.isBoss) n++;
			return n;
		}

		private function aliveWith(flag:String):int {
			var n:int = 0;
			for each (var e:Enemy in enemies) if (!e.dead && e.def[flag]) n++;
			return n;
		}

		/** A guardian fell: open the seal (or the way to the Dark Elder) once all are dead. */
		private function guardianDown(e:Enemy):void {
			var left:int = aliveWith("guardian");
			showBanner(e.def.name + " has fallen!", Ui.GOLD, 3);
			if (left > 0) { msg(left + " guardian" + (left == 1 ? "" : "s") + " remain.", 0xffd75e); return; }
			var th:Object = world.theme;
			if (th && th.toElder) {
				addPortal(world, e.x, e.y + 2, "elder", 0, 0xc060ff);
				say(SOVEREIGN, "You dare slay my lieutenants? Come, then. Face me!");
				showBanner("The way to the Dark Elder is open!", 0xc060ff, 4);
				return;
			}
			for each (var s:Enemy in enemies) {
				if (s.dead || !s.def.sealed) continue;
				s.invuln = false;
				world.boss = s;
				showBanner(s.def.name + " awakens!", 0xff60c0, 4);
				say(s.def.name, "The seals are broken... now you face me!");
				shake(0.6, 8);
			}
		}

		/** One of the three kings fell: the survivors heal a little and hit harder. */
		private function kingDown(e:Enemy):void {
			showBanner(e.def.name + " has fallen!", Ui.GOLD, 3);
			for each (var k:Enemy in enemies) {
				if (k.dead || !k.def.trio) continue;
				k.dmgMult *= 1.25;
				k.hp = Math.min(k.maxHp, k.hp + k.maxHp * 0.15);
				burst(k.x, k.y, 0xff4040, 20);
				if (!world.boss || world.boss.dead) world.boss = k;
			}
			msg("The remaining kings grow stronger!", 0xff6040);
		}

		/** The realm has closed: storm Azrakor's Citadel, then face him in his chamber. */
		private function enterCitadel():void {
			// each realm closes into one of several finales; online, everyone from the realm goes to the same one
			var fid:String = finaleFor(world);
			var seed:uint = net.online && world.seed ? ((world.seed * 2654435761) & 0x7fffffff) | 1 : 0;
			enterDungeon(Data.dungeonIndex(fid), seed);
			var lines:Object = {
				citadel: [SOVEREIGN, "You have slain my champions. Now come to my Citadel... if you can."],
				drowned_throne: ["Nerezza, the Tide Empress", "The realm sinks beneath my waves. Come, drown in my throne room."],
				clockwork_foundry: ["Gearmind Omega", "REALM DECOMMISSIONED. SURVIVORS WILL BE RECYCLED."],
				void_rift: ["Vael'thrax the Void Dragon", "The realm is torn open. Step into the rift, little ones."]
			};
			say(lines[fid][0], lines[fid][1]);
		}

		public function bossPhase(phase:int, b:Enemy = null):void {
			if (!b) b = world.boss;
			var nm:String = b ? b.def.name : "The boss";
			var po:Object = b && b.def.phases ? b.def.phases[phase] : null;
			if (po && !(po is Array)) {
				// scripted phase: its own lines, banner and a shake
				if (po.say) say(nm, po.say);
				if (po.banner) showBanner(po.banner, b.def.col, 3);
				if (po.shield) { shake(0.4, 6); burst(b.x, b.y, b.def.col, 30); ring(b.x, b.y, b.def.col, 32); }
				if (!(b.def.final && phase == 2)) return;
			}
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
			dyingT = DYING_TIME;
			burst(p.x, p.y, 0xd02020, 30);
			ring(p.x, p.y, 0xffffff, 20);
			Sfx.play("hurt", 1);
			shake(0.5, 8);
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
					if (e.remote) sync.hit(e, 0, 0, secs);
					n++;
				}
			}
			return n;
		}

		/** R key / temple button: return to the Nexus (full heal). */
		public function nexus():void {
			travel(nexusNow);
		}

		public function nexusNow():void {
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
			if (tradeWin) { msg("Finish or cancel the trade first.", 0xff8080); return; }
			var p:Player = player;
			var item:Object;
			if (kind == "bag") {
				if (!nearBag || idx >= nearBag.items.length) return;
				item = nearBag.items[idx];
				if (item.kind == "material") tip("sor", "Star Shard: bring it with a Runed, Bonded or Eldritch item and 100 Aether to the Starforge to make it Starforged.");
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
			if (tradeWin) { msg("Finish or cancel the trade first.", 0xff8080); return; }
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
			if (tradeWin) { msg("Finish or cancel the trade first.", 0xff8080); return; }
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
			{id: "sor", name: "Star Shard", price: 900},
			{id: "ut", name: "Mystery T7 item", price: 2500},
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
			var title:TextField = Ui.text(20, {forge: 0xc080ff, market: 0x6fe08f, quests: 0xf0d080, pets: 0x60c0ff, skins: 0xff9a2e, raids: 0xff3050}[openStation.kind], true, "center", w, true);
			title.text = {forge: "Starforge", market: "Marketplace", quests: "Daily Quests", pets: "Pet Yard", skins: "Fame Store", raids: "Raid Table"}[openStation.kind];
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
				info.htmlText = "Forge a <font color='" + Ui.hex(Data.RARITY_COLORS.lg) + "'><b>Starforged</b></font> item: Runed, Bonded or Eldritch item + 1 Star Shard + 100 Aether\n" +
					"You have <b>" + sors + "</b> Star Shard" + (sors == 1 ? "" : "s") + " and <b>" + onrane + "</b> Aether. Click an item to forge it.";
				info.y = y;
				y += info.height + 8;
				var n:int = 0;
				for (i = 0; i < player.inv.length; i++) {
					var item:Object = player.inv[i];
					if (!item || !item.rarity || item.rarity == "lg" || item.rarity == "ar" || item.rarity == "gd") continue;
					sp.addChild(itemButton(item, 20 + n * 52, y, forgeFn(i)));
					n++;
				}
				if (n == 0) {
					var none:TextField = Ui.text(13, 0x888888, false, "center", w - 20);
					none.x = 10; none.y = y + 10;
					none.text = "No Runed, Bonded or Eldritch items in your inventory.";
					sp.addChild(none);
				}
				y += 56;
			} else if (openStation.kind == "raids") {
				info.htmlText = "Use a raid key to open a raid portal here in the Nexus. Raids are three boss fights in a row, best with friends, " +
					"and raid bosses drop their own unique items. Keys drop rarely from bosses: realm events, dungeon bosses and, most often, the Dark Elder.";
				info.y = y;
				y += info.height + 10;
				for (i = 0; i < Bosses.RAIDS.length; i++) {
					var rd:Object = Bosses.RAIDS[i];
					var rt:TextField = Ui.text(14, rd.color, true, "left", w - 212, true);
					rt.htmlText = rd.name + "\n<font size='11' color='#aaaaaa'>" + raidBossNames(rd) + "</font>";
					rt.x = 16; rt.y = y;
					sp.addChild(rt);
					var keys:int = keyCount(i);
					if (keys > 0) {
						var rb:Sprite = Ui.button("Use Key (" + keys + ")", 170, 32, raidFn(i), 13);
						rb.x = w - 186; rb.y = y + 2;
						sp.addChild(rb);
					} else {
						var nk:TextField = Ui.text(12, 0x888888, false, "center", 170);
						nk.text = "Needs a key";
						nk.x = w - 186; nk.y = y + 9;
						sp.addChild(nk);
					}
					y += 46;
				}
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
						(q.gold ? q.gold + " gold  " : "") + (q.onrane ? q.onrane + " Aether" : "") + "</font>";
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

		// ------------------------------------------------------------ raids
		private function raidBossNames(rd:Object):String {
			var parts:Array = [];
			for each (var st:Array in rd.stages) {
				var nm:String = Data.ENEMIES[st[0]].name;
				parts.push(st.length > 1 ? st.length + "x " + nm : nm);
			}
			return parts.join("  >  ");
		}

		private function raidFn(i:int):Function {
			return function():void {
				for (var k:int = 0; k < player.inv.length; k++) {
					if (Data.keyRaid(player.inv[k]) != i) continue;
					if (useRaidKey(player.inv[k])) { player.inv[k] = null; saveCharacter(); }
					return;
				}
			};
		}

		/** Raid keys of this raid in your inventory. */
		private function keyCount(i:int):int {
			var n:int = 0;
			for each (var it:Object in player.inv) if (Data.keyRaid(it) == i) n++;
			return n;
		}

		/** Using a raid key: opens its raid in the Nexus. Returns true when the key was used up. */
		public function useRaidKey(item:Object):Boolean {
			var i:int = Data.keyRaid(item);
			if (i < 0) return false;
			if (!inNexus) { msg("Raid keys open their portal in the Nexus. Bring it there and click it.", item.color); return false; }
			openRaid(i);
			return true;
		}

		/** Opens a raid portal next to the table (everyone in the Nexus sees it). */
		public function openRaid(i:int):void {
			var rd:Object = Bosses.RAIDS[i];
			Save.flush();
			var seed:uint = 1 + uint(Math.random() * 0x7ffffffe);
			var px:Number = 113.5, py:Number = 107.5;
			addPortal(nexusWorld, px, py, "raid", i, rd.color, 120, seed, false);
			if (net.online) net.sendWorld("all", {t: "portal", x: px, y: py, k: "raid", i: i, c: rd.color, l: 120, s: seed});
			showBanner(rd.name + " is open!", rd.color, 3);
			msg(player.name + " opened a portal to " + rd.name + "! (2 minutes)", rd.color);
			Sfx.play("portal");
			closeStation();
			hud.refresh();
		}

		/**
		 * Raids are dungeons of their own: guarded halls, then three boss stages
		 * behind seals that open as each stage falls.
		 */
		private function enterRaid(i:int, seed:uint):void {
			var rd:Object = Bosses.RAIDS[i];
			if (!rd) return;
			dungeonWorld = new World("dungeon", rd.name, rd.theme, seed);
			dungeonWorld.key = "raid:" + i + ":" + seed;
			dungeonWorld.raid = rd;
			dungeonWorld.raidStage = -1;
			dungeonWorld.raidT = 1;
			switchWorld(dungeonWorld, dungeonWorld.spawnX, dungeonWorld.spawnY);
			var dw:World = dungeonWorld;
			whenHost(function():void { populateRaid(dw); });
			player.invulnT = 3;
			player.bossDmg = 0;
			lightningT = 6;
			showBanner(rd.name, rd.color, 4);
			msg(rd.intro, rd.color);
			Sfx.play("portal");
		}

		/** Host: the raid's guards, elite like the hardest dungeons (and then some). */
		private function populateRaid(w:World):void {
			if (world != w) return;
			var th:Object = w.raid.theme;
			for each (var rm:Object in w.mobRooms) {
				for (var k:int = 0; k < rm.n; k++) {
					var e:Enemy = spawnEnemy(th.mobs[int(Math.random() * th.mobs.length)], rm.x + (Math.random() - 0.5) * rm.w, rm.y + (Math.random() - 0.5) * rm.h, th.tier);
					if (!e) continue;
					e.maxHp *= th.hard;
					e.hp = e.maxHp;
					e.dmgMult = 1 + (th.hard - 1) * 0.6;
				}
			}
			msg("Raid: everything here is far tougher than anywhere else. Bring friends.", 0xff8080);
			saveCharacter();
		}

		/** Host: start a stage, and when its bosses fall open the next seal and wake the next stage. */
		private function updateRaid(dt:Number):void {
			var w:World = world;
			var rd:Object = w.raid;
			if (!rd || w.raidStage >= rd.stages.length) return;
			if (w.raidStage >= 0) for each (var e:Enemy in enemies) if (!e.dead && e.isBoss) return;
			w.raidT -= dt;
			if (w.raidT > 0) return;
			if (w.raidStage == rd.stages.length - 1) { w.raidStage++; return; }
			w.raidStage++;
			w.raidT = 2;
			var n:int = w.raidStage;
			var st:Array = rd.stages[n];
			var spots:Array = w.stageSpots[n] || [];
			for (var k:int = 0; k < st.length; k++) {
				var at:Array = spots[k] || spots[0] || [100.5, 100.5];
				var b:Enemy = spawnEnemy(st[k], at[0], at[1], World.DUNGEON_ZONE);
				if (b && k == 0) w.boss = b;
			}
			raidStageReached(n);
			if (net.online) net.sendWorld("all", {t: "rstage", n: n});
		}

		/** Stage n has begun: every seal before it is open (also run by other players' games). */
		public function raidStageReached(n:int):void {
			var w:World = world;
			if (!w.raid) return;
			w.raidStage = Math.max(w.raidStage, n);
			var opened:Boolean = false;
			for (var k:int = 0; k < n; k++) if (w.openGate(k)) opened = true;
			if (opened) {
				showBanner("The way to " + w.raid.places[n] + " opens!", w.raid.color, 3.5);
				msg("A seal breaks. The way to " + w.raid.places[n] + " is open.", w.raid.color);
				Sfx.play("portal");
				shake(0.5, 6);
			} else raidStageBanner(n, w.raid);
		}

		// ------------------------------------------------------------ atmosphere
		private var atmo:Shape;
		private var flashShape:Shape;
		private var atmoCol:uint = 0, atmoA:Number = 0;
		private var drawnCol:uint = 1, drawnA:Number = -1;

		/** A white flash over the view (lightning, big hits). */
		public function flash(a:Number):void {
			if (!opt("shake")) a *= 0.5;
			flashShape.alpha = Math.max(flashShape.alpha, a);
			flashShape.visible = true;
		}

		/** The colour the light takes in each place: warm beach, dim forests, violet Godlands, red raids... */
		private function atmoTarget():Array {
			if (world.raid) return world.raid.id == "storm" ? [0x001030, 0.18] : [0x500010, 0.16];
			if (world.kind == "dungeon") return [0x000010, 0.12];
			if (world.kind == "arena") return [0x300008, 0.12];
			if (world.kind != "realm") return [0x000000, 0];
			switch (world.zoneAt(player.x, player.y)) {
				case World.SHORE_ZONE: return [0xfff0c0, 0.04];
				case World.MID_ZONE: return [0x002010, 0.08];
				case World.HIGH_ZONE: return [0x302000, 0.06];
				case World.GOD_ZONE: return [0x2a0040, 0.15];
			}
			return [0x000000, 0];
		}

		private function updateAtmosphere(dt:Number):void {
			var t:Array = atmoTarget();
			var k:Number = Math.min(1, dt * 1.5);
			atmoA += (t[1] - atmoA) * k;
			atmoCol = mixCol(atmoCol, t[0], k);
			if (Math.abs(atmoA - drawnA) > 0.002 || atmoCol != drawnCol) {
				drawnA = atmoA; drawnCol = atmoCol;
				atmo.graphics.clear();
				if (atmoA > 0.003) {
					atmo.graphics.beginFill(atmoCol, atmoA);
					atmo.graphics.drawRect(0, 0, VIEW_W, VIEW_H);
					atmo.graphics.endFill();
				}
			}
			if (flashShape.visible) {
				flashShape.alpha -= dt * 1.8;
				if (flashShape.alpha <= 0) { flashShape.alpha = 0; flashShape.visible = false; }
			}
		}

		private static function mixCol(a:uint, b:uint, t:Number):uint {
			var r:int = ((a >> 16) & 255) + (((b >> 16) & 255) - ((a >> 16) & 255)) * t;
			var g:int = ((a >> 8) & 255) + (((b >> 8) & 255) - ((a >> 8) & 255)) * t;
			var bl:int = (a & 255) + ((b & 255) - (a & 255)) * t;
			return (r << 16) | (g << 8) | bl;
		}

		// ------------------------------------------------------------ ambient particles
		/** Weather and motes drifting through the view: {x, y, vx, vy, life, max, bd: [3 fades]}. */
		private var amb:Array = [];
		private var ambAcc:Number = 0;
		private static var ambBits:Object = {};

		/** A small dot or streak in three fading strengths. */
		private static function ambBit(kind:String, col:uint):Array {
			var key:String = kind + col;
			if (ambBits[key]) return ambBits[key];
			var out:Array = [];
			for each (var a:Number in [1, 0.6, 0.3]) {
				var w:int = kind == "rain" ? 2 : kind == "leaf" ? 5 : kind == "glint" || kind == "ember" ? 6 : 4;
				var h:int = kind == "rain" ? 12 : kind == "leaf" ? 4 : kind == "glint" || kind == "ember" ? 6 : 4;
				var bd:BitmapData = new BitmapData(w, h, true, 0);
				var c:uint = (uint(a * (kind == "rain" ? 150 : 230)) << 24) | col;
				if (kind == "glint") { bd.fillRect(new Rectangle(2, 0, 2, 6), c); bd.fillRect(new Rectangle(0, 2, 6, 2), c); }
				else if (kind == "ember") {
					// a soft glow with a bright core
					bd.fillRect(new Rectangle(1, 0, 4, 6), (uint(a * 90) << 24) | col);
					bd.fillRect(new Rectangle(0, 1, 6, 4), (uint(a * 90) << 24) | col);
					bd.fillRect(new Rectangle(2, 2, 2, 2), (uint(a * 255) << 24) | Sprites.tint(col, 0.5));
				}
				else bd.fillRect(bd.rect, c);
				out.push(bd);
			}
			ambBits[key] = out;
			return out;
		}

		/** What drifts through the air here: [kind, colours, per second]. */
		private function ambientKind():Array {
			if (world.raid) return world.raid.id == "storm" ? ["rain", [0xb0c8ff], 70] : ["ash", [0xa01020, 0x501010], 14];
			if (world.kind == "nexus") return ["mote", [0xffe080, 0xfff0c0], 4];
			if (world.kind == "arena") return ["ember", [0xff3040, 0xff8040], 10];
			if (world.kind == "dungeon") {
				var th:Object = world.theme;
				if (th && th.hazard == "lava") return ["ember", [0xff6020, 0xffa040], 12];
				if (th && th.hazard == "water") return ["mote", [0x80c0ff, 0xc0e0ff], 6];
				return ["mote", [0xa0a0b0, 0x707080], 5];
			}
			switch (world.zoneAt(player.x, player.y)) {
				case World.SHORE_ZONE: return ["mote", [0xfff0d0], 3];
				case World.LOW_ZONE: return ["leaf", [0x8ac040, 0xc0d050, 0x5a9a30], 5];
				case World.MID_ZONE: return ["leaf", [0x4a8a30, 0xd08030, 0x8a6020], 7];
				case World.HIGH_ZONE: return ["mote", [0xd0c090, 0xa09060], 6];
				case World.GOD_ZONE: return ["ember", [0xc060ff, 0xff70d0, 0xff9040], 18];
			}
			return null;
		}

		private function updateAmbient(dt:Number):void {
			var i:int;
			for (i = amb.length - 1; i >= 0; i--) {
				var a:Object = amb[i];
				a.life -= dt;
				if (a.life <= 0) { amb[i] = amb[amb.length - 1]; amb.length--; continue; }
				a.x += a.vx * dt; a.y += a.vy * dt;
				if (a.sway) a.x += Math.sin(time * 2 + a.sway) * dt * 0.6;
			}
			if (!opt("parts") || paused) return;
			var k:Array = ambientKind();
			// sparkles on water near you
			if (Math.random() < 0.35) {
				var gx:int = int(viewX + (Math.random() - 0.5) * vw / TS), gy:int = int(viewY + (Math.random() - 0.5) * vh / TS);
				if (world.tileAt(gx, gy) == World.WATER) amb.push({x: gx + Math.random(), y: gy + Math.random(), vx: 0, vy: 0, life: 0.6, max: 0.6, bd: ambBit("glint", 0xffffff)});
			}
			if (!k) return;
			ambAcc += dt * k[2];
			var cap:int = k[0] == "rain" ? 160 : 90;
			while (ambAcc >= 1) {
				ambAcc -= 1;
				if (amb.length >= cap) continue;
				var col:uint = k[1][int(Math.random() * k[1].length)];
				var p:Object = {x: viewX + (Math.random() - 0.5) * vw / TS * 1.1, y: viewY + (Math.random() - 0.5) * vh / TS * 1.1, bd: ambBit(k[0] == "ash" ? "mote" : k[0], col)};
				switch (k[0]) {
					case "rain": p.vx = -3; p.vy = 20; p.life = p.max = 0.45; p.y -= 3; break;
					case "leaf": p.vx = 0.4 + Math.random() * 0.6; p.vy = 0.9 + Math.random() * 0.6; p.life = p.max = 3 + Math.random() * 2; p.sway = Math.random() * 6; break;
					case "ember": p.vx = (Math.random() - 0.5) * 0.6; p.vy = -0.8 - Math.random() * 0.8; p.life = p.max = 2 + Math.random() * 1.5; p.sway = Math.random() * 6; break;
					case "ash": p.vx = (Math.random() - 0.5) * 0.4; p.vy = 0.5 + Math.random() * 0.4; p.life = p.max = 3 + Math.random() * 2; p.sway = Math.random() * 6; break;
					default: p.vx = (Math.random() - 0.5) * 0.4; p.vy = (Math.random() - 0.5) * 0.4; p.life = p.max = 2.5 + Math.random() * 2;
				}
				amb.push(p);
			}
		}

		private function drawAmbient():void {
			for each (var a:Object in amb) {
				var f:Number = a.life / a.max;
				// fade in over the first fifth of its life and out over the last third
				var lvl:int = f > 0.8 ? (f > 0.9 ? 2 : 1) : f > 0.33 ? 0 : f > 0.15 ? 1 : 2;
				var bd:BitmapData = a.bd[lvl];
				pt.x = scrX(a.x, a.y) - (bd.width >> 1);
				pt.y = scrY(a.x, a.y) - (bd.height >> 1);
				if (pt.x < -8 || pt.y < -8 || pt.x > vw + 8 || pt.y > vh + 8) continue;
				canvas.copyPixels(bd, bd.rect, pt, null, null, true);
			}
		}

		// ------------------------------------------------------------ kill streaks
		private var streakN:int = 0;
		private var streakT:Number = 0;
		private var streakTf:TextField;
		private var streakBar:Shape;
		private static const STREAK_TIME:Number = 3.5;
		private static const STREAK_NAMES:Object = {5: "Killing Spree", 10: "Rampage", 20: "Unstoppable", 35: "Godlike", 50: "Legendary", 75: "Mythical", 100: "Beyond Mortal"};

		/** Loot luck from your streak: +1% per kill, up to +30%. */
		private function streakBonus():int { return Math.min(30, streakN); }

		private function addStreak(e:Enemy):void {
			streakN++;
			streakT = STREAK_TIME;
			var nm:String = STREAK_NAMES[streakN];
			if (nm) {
				showBanner(nm + "!  x" + streakN, streakN >= 35 ? 0xff60ff : streakN >= 10 ? 0xff8040 : Ui.GOLD, 2);
				Sfx.play("level", 0.6);
				ring(player.x, player.y, streakN >= 35 ? 0xff60ff : Ui.GOLD, 22);
			}
		}

		private function updateStreak(dt:Number):void {
			if (streakN > 0 && !paused) {
				streakT -= dt;
				if (streakT <= 0) endStreak();
			}
			var show:Boolean = streakN >= 3;
			streakTf.visible = show;
			streakBar.visible = show;
			if (!show) return;
			var txt:String = "x" + streakN + " STREAK  <font size='14' color='#e0e0e0'>+" + streakBonus() + "% loot</font>";
			if (streakTf.htmlText.indexOf("x" + streakN + " ") < 0) streakTf.htmlText = txt;
			streakTf.textColor = streakN >= 35 ? 0xff80ff : streakN >= 10 ? 0xffa060 : Ui.GOLD;
			var gr:* = streakBar.graphics;
			gr.clear();
			gr.beginFill(0x000000, 0.5); gr.drawRect(0, 0, 120, 4); gr.endFill();
			gr.beginFill(streakN >= 10 ? 0xffa060 : 0xffd75e); gr.drawRect(0, 0, 120 * Math.max(0, streakT / STREAK_TIME), 4); gr.endFill();
		}

		private function endStreak():void {
			if (streakN >= 10) {
				var gold:int = streakN * 5;
				addGold(gold);
				var best:int = int(Save.data.bestStreak || 0);
				var record:Boolean = streakN > best;
				if (record) { Save.data.bestStreak = streakN; Save.flush(); }
				msg("Streak over: " + streakN + " kills (+" + gold + " gold)" + (record ? "  New personal best!" : ""), record ? 0xff80ff : Ui.GOLD);
			}
			streakN = 0;
			streakT = 0;
		}

		// ------------------------------------------------------------ elites
		private static const ELITES:Array = ["Swift", "Armored", "Frenzied", "Giant", "Splitting", "Vampiric"];
		private var eliteLabels:Array = [];
		private var eliteTags:Array = [];

		public static function eliteCol(id:String):uint {
			return {Swift: 0x60e0ff, Armored: 0xc8c8d8, Frenzied: 0xff5040, Giant: 0xffb040, Splitting: 0x80ff60, Vampiric: 0xff3080}[id] || 0xffffff;
		}

		/** Host: turns a fresh monster into an elite with one trait (more health, double loot). */
		private function makeElite(e:Enemy, id:String = null):void {
			id = id || ELITES[int(Math.random() * ELITES.length)];
			e.elite = id;
			e.maxHp *= 2.5;
			switch (id) {
				case "Swift": e.spdMult = 1.7; break;
				case "Armored": e.defense += 15; e.maxHp *= 1.4; break;
				case "Frenzied": e.dmgMult *= 1.4; e.spdMult = 1.25; break;
				case "Giant": e.maxHp *= 2; e.dmgMult *= 1.2; break;
			}
			e.hp = e.maxHp;
		}

		/** Host: Vampiric elites heal over time. */
		private function updateElites(dt:Number):void {
			for each (var e:Enemy in enemies) {
				if (e.elite == "Vampiric" && !e.dead && !e.remote && e.hp < e.maxHp) e.hp = Math.min(e.maxHp, e.hp + e.maxHp * 0.03 * dt);
			}
		}

		/** A Splitting elite bursts into three ordinary copies. */
		private function splitElite(e:Enemy):void {
			for (var k:int = 0; k < 3; k++) {
				var a:Number = k * Math.PI * 2 / 3;
				spawnEnemy(e.defId, e.x + Math.cos(a) * 1.2, e.y + Math.sin(a) * 1.2, e.zone);
			}
			burst(e.x, e.y, eliteCol("Splitting"), 20);
		}

		// ------------------------------------------------------------ shrines
		private var buffTf:TextField;
		private static const BLESSINGS:Object = {
			might: ["Shrine of Might", "+30% damage", 0xff4040],
			haste: ["Shrine of Haste", "+35% speed", 0x40e0ff],
			fortune: ["Shrine of Fortune", "+25% loot luck", 0xffd040],
			vigor: ["Shrine of Vigor", "regenerate 4% HP a second", 0x50e070],
			arcana: ["Shrine of Arcana", "regenerate 10% MP a second", 0xb060ff]
		};

		/** Loot luck on top of Bounty: your kill streak and the Shrine of Fortune. */
		private function lootLuck():int { return streakBonus() + (player.buffs.fortune > 0 ? 25 : 0); }

		/** Touch a shrine for a 60-second blessing; each shrine rests 2 minutes after blessing you. */
		private function updateShrines(dt:Number):void {
			if (world.kind == "realm") {
				for each (var s:Object in world.shrines) {
					if (s.cd > 0) { s.cd -= dt; continue; }
					var dx:Number = s.x - player.x, dy:Number = s.y - player.y;
					if (dx * dx + dy * dy > 2.3 * 2.3 || player.hp <= 0) continue;
					s.cd = 120;
					var bl:Array = BLESSINGS[s.kind];
					player.buffs[s.kind] = 60;
					showBanner(bl[0] + ": " + bl[1], bl[2], 3);
					msg(bl[0] + " blesses you: " + bl[1] + " for 60 seconds.", bl[2]);
					ring(player.x, player.y, bl[2], 30);
					burst(s.x, s.y - 0.5, bl[2], 24);
					Sfx.play("level", 0.7);
				}
			}
			var parts2:Array = [];
			for (var k:String in BLESSINGS) {
				var t:Number = player.buffs[k];
				if (t > 0) parts2.push("<font color='" + Ui.hex(BLESSINGS[k][2]) + "'>" + BLESSINGS[k][0].replace("Shrine of ", "") + " " + Math.ceil(t) + "s</font>");
			}
			var txt:String = parts2.join("   ");
			if (buffTf.htmlText.length == 0 && !txt) return;
			if (txt != lastBuffTxt) { lastBuffTxt = txt; buffTf.htmlText = txt; }
			buffTf.y = streakN >= 3 ? 116 : 84;
		}
		private var lastBuffTxt:String = "";

		/** A glow under every ready shrine, with motes rising off it. */
		private function drawShrineGlow():void {
			if (world.kind != "realm") return;
			for each (var s:Object in world.shrines) {
				if (s.cd > 0) continue;
				var sx:Number = scrX(s.x, s.y), sy:Number = scrY(s.x, s.y);
				if (sx < -60 || sy < -60 || sx > vw + 60 || sy > vh + 60) continue;
				var col:uint = BLESSINGS[s.kind][2];
				drawAura(sx, sy + TS * 0.4, col, 0.9);
				if (Math.random() < 0.25 && opt("parts")) parts.push(new Particle(s.x + (Math.random() - 0.5) * 0.6, s.y - 0.8, 0, -1.2, 0.8, Sprites.glow(col)));
			}
		}

		// ------------------------------------------------------------ crates and mimics
		/** A crate breaks; one in eight was a Mimic all along (the world host decides). */
		private function crateBroken(e:Enemy, mine:Boolean, remote:Boolean):void {
			burst(e.x, e.y, 0xa0703a, 14);
			if (remote || Math.random() > 0.12) return;
			var m:Enemy = spawnEnemy("mimic", e.x, e.y, e.zone);
			if (!m) return;
			m.maxHp = m.hp = 1200 + Math.max(0, e.zone) * 900;
			showBanner("It's a Mimic!", 0xff4040, 2.5);
			shake(0.3, 6);
			Sfx.play("boss", 0.6);
		}

		/** What's in a crate: mostly a little gold, sometimes potions. */
		private function crateLoot(zone:int):Array {
			var r:Number = Math.random();
			if (r < 0.55) {
				var gold:int = (8 + int(Math.random() * 18)) * (Math.max(0, zone) + 1);
				addGold(gold);
				floatText(player.x, player.y - 1.4, "+" + gold + " gold", Ui.GOLD);
				return [];
			}
			if (r < 0.85) return [Data.makePotion(Math.random() < 0.5 ? "hp" : "mp")];
			return [Data.makePotion("stat", Data.randomStat())];
		}

		/** Mimics guard the good stuff. */
		private function mimicLoot():Array {
			var out:Array = [Data.makePotion("stat", Data.randomStat())];
			if (Math.random() < 0.4) out.push(Data.makeForSlot(player.cls, int(Math.random() * 4), 7, "ut"));
			if (Math.random() < 0.15) out.push(Data.makeSor());
			return out;
		}

		// ------------------------------------------------------------ loot beams
		private static const BEAM_BAGS:Array = ["bag_white", "bag_fabled", "bag_legendary", "bag_relic", "bag_godly"];
		private static var beams:Object = {};

		/** A soft column of light (two frames that pulse). */
		private static function lootBeam(col:uint, frame:int):BitmapData {
			var key:String = col + "_" + frame;
			if (beams[key]) return beams[key];
			var w:int = 18, h:int = 170;
			var bd:BitmapData = new BitmapData(w, h, true, 0);
			var peak:Number = frame ? 0.85 : 0.7;
			for (var y:int = 0; y < h; y++) {
				var f:Number = y / h;
				var a:Number = peak * (0.15 + 0.85 * f);
				bd.fillRect(new Rectangle(0, y, w, 1), (uint(a * 60) << 24) | col);
				bd.fillRect(new Rectangle(4, y, w - 8, 1), (uint(a * 140) << 24) | col);
				bd.fillRect(new Rectangle(7, y, w - 14, 1), (uint(a * 230) << 24) | Sprites.tint(col, 0.6));
			}
			beams[key] = bd;
			return bd;
		}

		// ------------------------------------------------------------ treasure goblin
		private var goblinT:Number = 90 + Math.random() * 120;

		/** Host: now and then a Treasure Goblin pops up near a player and runs. It escapes after 30 seconds. */
		private function updateGoblin(dt:Number):void {
			for (var i:int = enemies.length - 1; i >= 0; i--) {
				var g:Enemy = enemies[i];
				if (!g.def.goblin || g.dead) continue;
				g.age += dt;
				if (g.age > 30) {
					burst(g.x, g.y, 0xffe060, 30);
					msg("The Treasure Goblin escaped with its loot!", 0xc0a040);
					removeEnemyAt(i);
				}
				return;
			}
			if (world.closeT > 0) return;
			goblinT -= dt;
			if (goblinT > 0) return;
			goblinT = 150 + Math.random() * 150;
			var spots:Array = playerSpots();
			var who:Object = spots[int(Math.random() * spots.length)];
			for (var tries:int = 0; tries < 20; tries++) {
				var a:Number = Math.random() * Math.PI * 2, r:Number = 9 + Math.random() * 4;
				var gx:Number = who.x + Math.cos(a) * r, gy:Number = who.y + Math.sin(a) * r;
				var z:int = world.zoneAt(gx, gy);
				if (z < World.LOW_ZONE || z > World.GOD_ZONE || !world.canStand(gx, gy, 0.4, true)) continue;
				var gob:Enemy = spawnEnemy("loot_goblin", gx, gy, z);
				if (!gob) return;
				gob.maxHp = gob.hp = 800 + z * 900;
				showBanner("A Treasure Goblin appears!", 0xffe060, 2.5);
				msg("A Treasure Goblin is nearby! Catch it before it escapes (30s).", 0xffe060);
				Sfx.play("rare", 0.7);
				return;
			}
		}

		private function goblinDown(e:Enemy, mine:Boolean):void {
			showBanner("Treasure Goblin slain!", 0xffe060, 3);
			ring(e.x, e.y, 0xffe060, 36);
			burst(e.x, e.y, 0xffe060, 40);
			Sfx.play("rare");
			if (mine) {
				var gold:int = e.def.gold * (Math.max(0, e.zone) + 1);
				addGold(gold);
				floatText(e.x, e.y - 1.6, "+" + gold + " gold", Ui.GOLD);
			}
		}

		/** The goblin's sack: potions, a Runed item for your class, a good chance of a Star Shard. */
		private function goblinLoot(zone:int):Array {
			var out:Array = [];
			var cls:Object = player.cls;
			out.push(Data.makeForSlot(cls, int(Math.random() * 4), 7, "ut"));
			out.push(Data.makePotion("stat", Data.randomStat()));
			out.push(Data.makePotion("stat", Data.randomStat()));
			if (Math.random() < 0.35) out.push(Data.makeSor());
			if (Math.random() < 0.25) out.push(Data.makeForSlot(cls, int(Math.random() * 4), 7, Math.random() < 0.7 ? "st" : "fb"));
			for each (var it:Object in Data.rollLoot(Data.ENEMIES.loot_goblin, zone, player.cls, player.frt + 40)) out.push(it);
			return out;
		}

		/** Heart of the Storm: lightning keeps striking near you (dodge the circles). */
		private var lightningT:Number = 0;
		private function updateLightning(dt:Number):void {
			if (!world.raid || world.raid.id != "storm" || player.hp <= 0) return;
			lightningT -= dt;
			if (lightningT > 0) return;
			lightningT = 1.4 + Math.random() * 1.2;
			var lx:Number = player.x + (Math.random() - 0.5) * 6, ly:Number = player.y + (Math.random() - 0.5) * 6;
			var self:Game = this;
			addMarker(lx, ly, 1.6, 1.1, 0xffff80, function():void {
				self.areaHit(lx, ly, 1.6, 120, "Lightning", "paralyzed", 0xffff80);
				self.flash(0.22);
				Sfx.play("hit", 0.5);
			});
		}

		public function raidStageBanner(n:int, rd:Object = null):void {
			rd = rd || world.raid;
			if (!rd || !rd.stages[n]) return;
			var nm:String = Data.ENEMIES[rd.stages[n][0]].name;
			showBanner((n == rd.stages.length - 1 ? "Final stage: " : "Stage " + (n + 1) + ": ") + nm, rd.color, 3.5);
			Sfx.play("boss");
			shake(0.4, 6);
		}

		/** Where a closing realm sends everyone (the same place for everyone online). */
		private function finaleFor(w:World):String {
			var ids:Array = Bosses.FINALES;
			if (w.seed) return ids[w.seed % ids.length];
			return ids[int(Math.random() * ids.length)];
		}

		private function itemButton(item:Object, x:int, y:int, onClick:Function):Sprite {
			var b:Sprite = new Sprite();
			b.graphics.lineStyle(1, 0x1a1a1a);
			b.graphics.beginFill(0x545454);
			b.graphics.drawRoundRect(0, 0, 48, 48, 10, 10);
			b.graphics.endFill();
			var bmp:Bitmap = new Bitmap(Sprites.icon(item));
			bmp.x = int((48 - bmp.width) / 2); bmp.y = int((48 - bmp.height) / 2);
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
				msg("Achievement unlocked: " + ach.name + " (" + ach.desc + ")  +" + ach.gold + " gold" + (ach.onrane ? " +" + ach.onrane + " Aether" : ""), 0xffd75e);
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
				msg("Quest reward: " + (q.gold ? q.gold + " gold " : "") + (q.onrane ? q.onrane + " Aether" : ""), Ui.GOLD);
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
				var x:int = 14 + (i % 3) * 140;
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
				box.x = x; box.y = y + int(i / 3) * 158;
				sp.addChild(box);
			}
			return y + Math.ceil(opts.length / 3) * 158;
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

		/** Starforge: Runed/Bonded/Eldritch item + Star Shard + 100 Aether -> Starforged. */
		private function forge(slot:int):void {
			var item:Object = player.inv[slot];
			if (!item) return;
			var sorSlot:int = -1;
			for (var i:int = 0; i < player.inv.length; i++) if (player.inv[i] && player.inv[i].kind == "material") { sorSlot = i; break; }
			if (sorSlot < 0) { msg("You need a Star Shard (event bosses drop them, or buy one at the Marketplace).", 0xff8080); return; }
			if (onrane < 100) { msg("You need 100 Aether (" + onrane + " now). Event bosses drop Aether.", 0xff8080); return; }
			addOnrane(-100);
			player.inv[sorSlot] = null;
			var lg:Object = Data.forgeLegendary(item, player.cls);
			player.inv[slot] = lg;
			questEvent("legendary");
			Save.flush();
			showBanner("Forged " + lg.name + "!", Data.RARITY_COLORS.lg, 3);
			Sfx.play("rare");
			msg("The Starforge blazes... you forged " + lg.name + "!", Data.RARITY_COLORS.lg);
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
				case "ut": item = Data.makeForSlot(player.cls, int(Math.random() * 3), 7, null); break;
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
			statusTf.x = cx - 160;
			statusTf.y = cy - 76;

			var b:Enemy = focusBoss();
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
				g.beginFill(b.immune ? 0x9a5a7a : 0xc82828);
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
				bossInfo.text = b.scalePlayers > 1 && !b.immune ? "HP: " + (frac * 100).toFixed(1) + "%  (" + Math.round(b.scalePlayers * 10) / 10 + " players)" : b.shieldT > 0 && !b.invuln ? "SHIELDED" : b.invuln ? (b.def.sealed ? "SEALED: " + aliveWith("guardian") + " guardians left" : "IMMUNE: " + crystalsLeft() + " crystals left") : "Boss HP: " + (frac * 100).toFixed(1) + "%";
				var met:Boolean = pct >= LG_THRESHOLD;
				thresholdTf.text = "Loot: " + LG_THRESHOLD + "% " + (met ? "met" : "not met");
				thresholdTf.textColor = met ? 0x7fd07f : 0xe05050;
			}
		}

		// ------------------------------------------------------------- render
		// camera rotation (Q / E rotate, Z snaps back to 0 degrees)
		public var camAngle:Number = 0;
		public function get camCos():Number { return rc; }
		public function get camSin():Number { return rs; }
		private var camZeroing:Boolean = false;
		private var rc:Number = 1, rs:Number = 0, shx:Number = 0, shy:Number = 0;
		/** Mouse wheel / - and = keys: zoom the world view in or out. */
		public function setZoom(z:Number):void {
			z = Math.max(ZOOM_MIN, Math.min(ZOOM_MAX, z));
			if (Math.abs(z - 1) < 0.04) z = 1;
			zoom = z;
			var w:int = Math.ceil(VIEW_W / z), h:int = Math.ceil(VIEW_H / z);
			if (!canvas || canvas.width != w || canvas.height != h) {
				if (canvas) canvas.dispose();
				canvas = new BitmapData(w, h, false, 0);
				canvasBmp.bitmapData = canvas;
			}
			vw = w; vh = h;
			cx = w / 2; cy = h / 2 + 20 / z;
			worldLayer.scaleX = worldLayer.scaleY = z;
			if (!Save.data.opt) Save.data.opt = {};
			Save.data.opt.zoom = Math.round(z * 100) / 100;
		}

		private function updateZoom():void {
			var steps:Number = input.wheel;
			if (input.pressed(189) || input.pressed(109)) steps -= 1;
			if (input.pressed(187) || input.pressed(107)) steps += 1;
			if (steps == 0) return;
			// the wheel over the sidebar or a window doesn't zoom
			if (input.wheel != 0 && (input.mx >= VIEW_W || uiCaptured())) return;
			setZoom(zoom * Math.pow(1.1, steps > 0 ? 1 : -1));
		}

		/** Camera position used for drawing (pixel-snapped when the view isn't rotated). */
		private var viewX:Number = 0, viewY:Number = 0;

		/** World tile coordinates -> screen pixels (rotated around the camera). */
		public function scrX(x:Number, y:Number):Number { return cx + shx + TS * ((x - viewX) * rc + (y - viewY) * rs); }
		public function scrY(x:Number, y:Number):Number { return cy + shy + TS * ((y - viewY) * rc - (x - viewX) * rs); }

		/** Stage (mouse) coordinates -> world tiles, through the zoom. */
		public function screenToWorldX(sx:Number, sy:Number = NaN):Number {
			if (isNaN(sy)) sy = input ? input.my : cy * zoom;
			sx /= zoom; sy /= zoom;
			var dx:Number = (sx - cx) / TS, dy:Number = (sy - cy) / TS;
			return viewX + dx * rc - dy * rs;
		}
		public function screenToWorldY(sy:Number, sx:Number = NaN):Number {
			if (isNaN(sx)) sx = input ? input.mx : cx * zoom;
			sx /= zoom; sy /= zoom;
			var dx:Number = (sx - cx) / TS, dy:Number = (sy - cy) / TS;
			return viewY + dx * rs + dy * rc;
		}

		private function updateCameraRotation(dt:Number):void {
			if (input.isDown(Keyboard.Q)) { camAngle -= dt * 2.2; camZeroing = false; }
			if (input.isDown(Keyboard.E)) { camAngle += dt * 2.2; camZeroing = false; }
			if (input.pressed(Keyboard.Z)) { camAngle = 0; camZeroing = false; }
			if (camZeroing) {
				while (camAngle > Math.PI) camAngle -= Math.PI * 2;
				while (camAngle < -Math.PI) camAngle += Math.PI * 2;
				camAngle *= Math.max(0, 1 - dt * 10);
				if (Math.abs(camAngle) < 0.002) { camAngle = 0; camZeroing = false; }
			}
		}

		/** Picks the objective: the area boss (or its crystals), else a monster suited to your level. */
		private function pickQuest():Enemy {
			if (inNexus) return null;
			// a treasure goblin nearby is always worth chasing
			for each (var gob:Enemy in enemies) {
				if (gob.dead || !gob.def.goblin) continue;
				if ((gob.x - player.x) * (gob.x - player.x) + (gob.y - player.y) * (gob.y - player.y) < 40 * 40) return gob;
			}
			var b:Enemy = world.boss;
			var e:Enemy, best:Enemy = null, bestD:Number = 1e9, d:Number;
			if (!b || b.dead) {
				// multi-boss dungeons: head for the nearest boss
				for each (e in enemies) {
					if (e.dead || !e.isBoss) continue;
					d = (e.x - player.x) * (e.x - player.x) + (e.y - player.y) * (e.y - player.y);
					if (d < bestD) { bestD = d; best = e; }
				}
				if (best) return best;
				bestD = 1e9;
			}
			if (b && !b.dead) {
				if (!b.immune) return b;
				for each (e in enemies) {
					if (e.dead || !(e.def.crystal || e.def.guardian)) continue;
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

		private function updateQuestArrow():void {
			questT -= 1 / 30;
			if (questT <= 0 || !questTarget || questTarget.dead) {
				questT = 0.5;
				questTarget = pickQuest();
			}
			var q:Enemy = questTarget;
			questArrow.visible = questTf.visible = q != null && !q.dead && !paused;
			if (!questArrow.visible) return;
			var sx:Number = scrX(q.x, q.y), sy:Number = scrY(q.x, q.y);
			var m:Number = 34;
			if (sx > m && sx < vw - m && sy > m + 40 && sy < vh - m) {
				// on screen: bob above the target, pointing down
				questArrow.rotation = 90;
				questArrow.x = sx;
				questArrow.y = sy - TS * (q.isBoss ? 2.2 : 1.4) - 4 + Math.sin(time * 6) * 4;
				questTf.visible = false;
				return;
			}
			var dx:Number = sx - cx, dy:Number = sy - cy;
			var ang:Number = Math.atan2(dy, dx);
			// clamp to the edge of the view
			var kx:Number = dx != 0 ? (dx > 0 ? (vw - m - cx) : (m - cx)) / dx : 1e9;
			var ky:Number = dy != 0 ? (dy > 0 ? (vh - m - cy) : (m + 40 - cy)) / dy : 1e9;
			var k:Number = Math.min(kx, ky);
			questArrow.x = cx + dx * k;
			questArrow.y = cy + dy * k;
			questArrow.rotation = ang * 180 / Math.PI;
			var dist:int = Math.sqrt((q.x - player.x) * (q.x - player.x) + (q.y - player.y) * (q.y - player.y));
			questTf.text = q.def.name + "  " + dist + "m";
			questTf.x = Math.max(4, Math.min(vw - 164, questArrow.x - 80));
			questTf.y = questArrow.y + (dy > 0 ? -34 : 14);
		}

		private function render():void {
			rc = Math.cos(camAngle);
			rs = Math.sin(camAngle);
			shx = shy = 0;
			if (shakeT > 0 && !paused) {
				shakeT -= 1 / 30;
				var sa:Number = shakeAmp * Math.min(1, shakeT * 4);
				shx = Math.round((Math.random() * 2 - 1) * sa);
				shy = Math.round((Math.random() * 2 - 1) * sa);
			}
			// keep the unrotated view pixel-aligned
			viewX = camAngle == 0 ? Math.round(camX * TS) / TS : camX;
			viewY = camAngle == 0 ? Math.round(camY * TS) / TS : camY;
			canvas.lock();
			canvas.fillRect(canvas.rect, 0xff101820);
			mtx.identity();
			mtx.scale(TS / World.PX, TS / World.PX);
			mtx.translate(-viewX * TS, -viewY * TS);
			if (camAngle != 0) mtx.rotate(-camAngle);
			mtx.translate(cx + shx, cy + shy);
			world.drawGround(canvas, mtx, viewX, viewY, Math.sqrt(vw * vw + vh * vh) / 2 / TS + 1);

			var bd:BitmapData;
			// loot bags lie on the ground
			for each (var b:LootBag in bags) {
				if (b.life < 8 && int(b.life * 4) % 2 == 0) continue;
				var bx:Number = scrX(b.x, b.y), by:Number = scrY(b.x, b.y);
				// rare bags glow; new bags bounce as they land
				if (!b.vault && b.spr != "bag_brown") drawAura(bx, by + TS * 0.4, BAG_GLOW[b.spr] || 0xffffff, 0.45);
				// white bags and better shine a beam of light into the sky
				if (!b.vault && BEAM_BAGS.indexOf(b.spr) >= 0) {
					var beam:BitmapData = lootBeam(BAG_GLOW[b.spr] || 0xffffff, int(time * 3 + b.x) % 2);
					pt.x = int(bx - beam.width / 2); pt.y = int(by + TS * 0.3 - beam.height);
					canvas.copyPixels(beam, beam.rect, pt, null, null, true);
				}
				var hop:int = b.age < 0.5 ? int(Math.abs(Math.sin(b.age * 19)) * 22 * (1 - b.age / 0.5)) : 0;
				drawEntity(Sprites.get(b.spr), bx, by, hop);
			}

			// portals and labels
			for each (var p:Object in world.portals) {
				if (p.kind == "realm" && !realmNames[p.idx]) { p.label.visible = false; continue; }
				var pcx:Number = scrX(p.x, p.y), pcy:Number = scrY(p.x, p.y);
				var pbd:BitmapData = Sprites.portal(p.color, int(time * 8));
				var ptop:Number = drawEntity(pbd, pcx, pcy, 0);
				var lab:TextField = p.label;
				lab.htmlText = p.kind == "realm" ? realmNames[p.idx] + "\n<font size='11' color='#cccccc'>" + realmStatus(p.idx) + "</font>"
					: p.kind == "dungeon" ? Data.DUNGEONS[p.idx].name + "\n<font size='11' color='#cccccc'>" + Math.ceil(p.life) + "s</font>"
					: p.kind == "elder" ? "<font color='#c060ff'>Dark Elder's Chamber</font>"
					: p.kind == "raid" ? "<font color='" + Ui.hex(p.color) + "'>" + Bosses.RAIDS[p.idx].name + "</font>\n<font size='11' color='#cccccc'>Raid  " + Math.ceil(p.life) + "s</font>" : "Nexus";
				lab.x = int(pcx - lab.width / 2);
				lab.y = int(ptop - lab.height - 2);
			}
			if (inNexus) {
				vaultLabel.x = int(scrX(vaultBag.x, vaultBag.y) - vaultLabel.width / 2);
				vaultLabel.y = int(scrY(vaultBag.x, vaultBag.y) - 58);
				for each (var st:Object in stations) {
					var stx:Number = scrX(st.x, st.y);
					var stop:Number = drawEntity(Sprites.get(st.spr), stx, scrY(st.x, st.y), 0);
					st.label.x = int(stx - st.label.width / 2);
					st.label.y = int(stop - st.label.height);
				}
			}
			var trapIcon:BitmapData = Sprites.icon({kind: "ability", sub: "trap", tier: 0});
			for each (var tr:Object in traps) {
				pt.x = int(scrX(tr.x, tr.y) - trapIcon.width / 2);
				pt.y = int(scrY(tr.x, tr.y) - trapIcon.height / 2);
				canvas.copyPixels(trapIcon, trapIcon.rect, pt, null, null, true);
			}

			drawMarkers();
			drawShrineGlow();
			// y-sorted: world objects, enemies, player
			drawList.length = 0;
			drawN = 0;
			var reach:int = int(Math.sqrt(vw * vw + vh * vh) / 2 / TS) + 3;
			var tx0:int = int(viewX) - reach, tx1:int = int(viewX) + reach;
			var ty0:int = int(viewY) - reach, ty1:int = int(viewY) + reach;
			for (var ty:int = ty0; ty <= ty1; ty++) {
				for (var tx:int = tx0; tx <= tx1; tx++) {
					var o:int = world.objAt(tx, ty);
					if (o <= 0) continue;
					var osx:Number = scrX(tx + 0.5, ty + 0.5), osy:Number = scrY(tx + 0.5, ty + 0.5);
					if (osx < -80 || osy < -40 || osx > vw + 80 || osy > vh + 160) continue;
					var di:Object = drawItem(osy + TS * 0.4, o, tx, null, false);
					di.t = ty;
					drawList.push(di);
				}
			}
			for each (var e:Enemy in enemies) {
				var sx:Number = scrX(e.x, e.y), sy:Number = scrY(e.x, e.y);
				if (sx < -100 || sy < -100 || sx > vw + 100 || sy > vh + 120) continue;
				drawList.push(drawItem(sy, 0, 0, e, false));
			}
			for each (var rp:RemotePlayer in net.players) {
				if (!shown(rp)) continue;
				var rsx:Number = scrX(rp.x, rp.y), rsy:Number = scrY(rp.x, rp.y);
				if (rsx < -60 || rsy < -60 || rsx > vw + 60 || rsy > vh + 80) continue;
				var rdi:Object = drawItem(rsy, -2, 0, null, false);
				rdi.r = rp;
				drawList.push(rdi);
			}
			drawList.push(drawItem(scrY(player.x, player.y), 0, 0, null, true));
			if (pet) drawList.push(drawItem(scrY(petX, petY), -1, 0, null, false));
			drawList.sortOn("y", Array.NUMERIC);

			for each (var d:Object in drawList) {
				if (d.o == -2) {
					drawRemote(d.r);
				} else if (d.o < 0) {
					drawEntity(Sprites.get("pet_" + pet.species, 0, scrX(petX, petY) > scrX(player.x, player.y)), scrX(petX, petY), scrY(petX, petY),
						petMoving && int(time * 6) % 2 == 0 ? 2 : 0);
				} else if (d.o) {
					bd = Sprites.get(World.OBJ_NAMES[d.o]);
					var ocx:Number = scrX(d.x + 0.5, d.t + 0.5);
					var baseY:Number = scrY(d.x + 0.5, d.t + 0.5) + TS / 2;
					var sh:BitmapData = Sprites.shadow(TS);
					pt.x = int(ocx - TS / 2);
					pt.y = int(baseY - sh.height * 0.7);
					canvas.copyPixels(sh, sh.rect, pt, null, null, true);
					pt.x = int(ocx - bd.width / 2);
					pt.y = int(baseY - bd.height);
					canvas.copyPixels(bd, bd.rect, pt, null, null, true);
				} else if (d.e) {
					drawEnemy(d.e);
				} else {
					drawPlayer();
				}
			}

			for each (var s:Projectile in shots) {
				if (s.bot && !s.shown) continue;
				bd = s.frame(time, camAngle);
				pt.x = int(scrX(s.x, s.y) - bd.width / 2);
				pt.y = int(scrY(s.x, s.y) - bd.height / 2);
				if (pt.x < -bd.width || pt.y < -bd.height || pt.x > vw || pt.y > vh) continue;
				canvas.copyPixels(bd, bd.rect, pt, null, null, true);
			}
			for each (var q:Particle in parts) {
				pt.x = scrX(q.x, q.y) - 3;
				pt.y = scrY(q.x, q.y) - 3;
				canvas.copyPixels(q.bd, q.bd.rect, pt, null, null, true);
			}
			drawAmbient();
			if (world.theme && world.theme.dark) drawDarkness();
			canvas.unlock();
			updateQuestArrow();
			updateTags();

			for each (var f:Floater in floaters) {
				if (!f.tf.visible) continue;
				f.tf.x = scrX(f.x, f.y) - f.tf.width / 2;
				f.tf.y = scrY(f.x, f.y) - f.tf.height / 2;
			}
		}

		private var darkShape:Shape = new Shape();
		private var darkMtx:Matrix = new Matrix();

		/** Dark dungeons: you only see a pool of light around yourself. */
		private function drawDarkness():void {
			var px:Number = scrX(player.x, player.y), py:Number = scrY(player.x, player.y);
			var R:Number = TS * 9;
			darkMtx.createGradientBox(R * 2, R * 2, 0, px - R, py - R);
			var g:* = darkShape.graphics;
			g.clear();
			g.beginGradientFill("radial", [0, 0, 0], [0, 0.55, 0.94], [0, 140, 255], darkMtx);
			g.drawRect(0, 0, vw, vh);
			g.endFill();
			canvas.draw(darkShape);
		}

		/** Reuses draw-list entries between frames instead of allocating new objects. */
		private function drawItem(y:Number, o:int, x:int, e:Enemy, p:Boolean):Object {
			var d:Object = drawPool[drawN];
			if (!d) d = drawPool[drawN] = {};
			drawN++;
			d.y = y; d.o = o; d.x = x; d.e = e; d.p = p; d.r = null;
			return d;
		}

		/** Draws a sprite standing at (cx, cy) with its drop shadow; returns the sprite top. */
		private var wadeRect:Rectangle = new Rectangle();

		/** Draws a sprite standing in water: the bottom is hidden below a ripple line. */
		private function drawWading(bd:BitmapData, cx:Number, cy:Number):Number {
			var foot:Number = cy + TS * 0.4;
			var sink:int = int(bd.height * 0.3);
			wadeRect.x = 0; wadeRect.y = 0; wadeRect.width = bd.width; wadeRect.height = bd.height - sink;
			pt.x = int(cx - bd.width / 2);
			pt.y = int(foot - bd.height + 2 + sink);
			canvas.copyPixels(bd, wadeRect, pt, null, null, true);
			var w:Number = bd.width * 0.4 + Math.sin(time * 6 + cx) * 2;
			var g:* = auraShape.graphics;
			g.clear();
			g.lineStyle(2, 0xcfe4ff, 0.75);
			g.drawEllipse(-w, -4, w * 2, 8);
			auraMtx.tx = cx; auraMtx.ty = foot - 1;
			canvas.draw(auraShape, auraMtx);
			return pt.y;
		}

		private function drawEntity(bd:BitmapData, cx:Number, cy:Number, bob:int, wade:Boolean = false):Number {
			if (wade) return drawWading(bd, cx, cy);
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

		private static const BAG_GLOW:Object = {bag_purple: 0xb050e0, bag_cyan: 0x40d0f0, bag_white: 0x9ad0ff,
			bag_fabled: 0xc85cff, bag_legendary: 0xffc23a, bag_relic: 0xff5533, bag_godly: 0xfff6e0};

		private function drawAura(cx:Number, cy:Number, col:uint, size:Number = 1):void {
			var pulse:Number = (Math.sin(time * 4) + 1) / 2;
			var rx:Number = (TS * 1.15 + pulse * 6) * size, ry:Number = rx * 0.45;
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

		private function drawEnemy(e:Enemy):void {
			var cx:Number = scrX(e.x, e.y), cy:Number = scrY(e.x, e.y);
			// fliers hover, walkers bob as they move and "breathe" when idle
			var bob:int;
			if (e.def.fly) bob = int((Math.sin(time * 3 + e.homeX) + 1) * 3);
			else if (e.moving) bob = int(time * 5 + e.homeX) % 2 == 0 ? 2 : 0;
			else bob = int(time * 1.6 + e.homeX) % 2 == 0 ? 1 : 0;
			if (e.isBoss) {
				// pulsing aura on the ground and a slow hover
				drawAura(cx, cy + TS * 0.4, e.immune ? 0xff4080 : e.enraged ? 0xff2020 : uint(e.def.col));
				bob = int((Math.sin(time * 2.5 + e.homeX) + 1) * 2.5);
			}
			if (e.elite) drawAura(cx, cy + TS * 0.4, eliteCol(e.elite), 0.85);
			if (e.def.goblin) {
				drawAura(cx, cy + TS * 0.4, 0xffe060, 0.7);
				if (Math.random() < 0.5 && opt("parts")) parts.push(new Particle(e.x + Math.random() - 0.5, e.y - 0.3, 0, 1.5, 0.5, Sprites.glow(0xffe060)));
			}
			var top:Number = drawEntity(e.sprite, cx, cy, bob, !e.def.fly && !e.isBoss && world.inWater(e.x, e.y));
			if (e.elite || e.def.goblin) eliteLabels.push({e: e, x: cx, y: top});
			if (e.hp < e.maxHp) {
				var bw:int = e.isBoss ? 80 : 36;
				hpBar(cx - bw / 2, cy + TS * 0.4 + 6, bw, e.hp / e.maxHp);
			}
			if (e.immune) statusPip(cx, top - 6, 0xffff4080);
			else if (e.stunT > 0) statusPip(cx, top - 6, 0xfff0f040);
			else if (e.slowT > 0) statusPip(cx, top - 6, 0xff60a0ff);
		}

		// ------------------------------------------------------------ other players
		private function drawRemote(rp:RemotePlayer):void {
			var cx:Number = scrX(rp.x, rp.y), cy:Number = scrY(rp.x, rp.y);
			if (rp == hoverRemote || (playerMenu && playerMenu.name == rp.id)) drawAura(cx, cy + TS * 0.4, 0xffffff, 0.45);
			drawEntity(rp.sprite, cx, cy, 0, world.inWater(rp.x, rp.y));
		}

		/** Name tags under other players and chat bubbles over their heads. */
		private function updateTags():void {
			// elite and goblin name plates
			var ne:int = 0;
			for each (var el:Object in eliteLabels) {
				var et:TextField = eliteTags[ne];
				if (!et) { et = eliteTags[ne] = Ui.text(11, 0xffffff, true, "center", 200, true); tagLayer.addChild(et); }
				ne++;
				var en:Enemy = el.e;
				var label:String = en.def.goblin ? "Treasure Goblin" : en.elite + " " + en.def.name;
				if (et.text != label) et.text = label;
				et.textColor = en.def.goblin ? 0xffe060 : eliteCol(en.elite);
				et.x = int(el.x - et.width / 2); et.y = int(el.y - 16);
				et.visible = true;
			}
			for (; ne < eliteTags.length; ne++) eliteTags[ne].visible = false;
			eliteLabels.length = 0;
			var n:int = 0, nb:int = 0;
			var names:Boolean = opt("names"), bubblesOn:Boolean = opt("bubbles");
			for each (var rp:RemotePlayer in net.players) {
				if (!shown(rp)) continue;
				var cx:Number = scrX(rp.x, rp.y), cy:Number = scrY(rp.x, rp.y);
				if (cx < -60 || cy < -60 || cx > vw + 60 || cy > vh + 40) continue;
				var friend:uint = net.inParty(rp) ? 0x7fd8ff : net.inGuild(rp) ? 0x80ff80 : 0;
				if (names || rp == hoverRemote || friend) {
				var tf:TextField = tags[n];
				if (!tf) {
					tf = tags[n] = Ui.text(12, 0xffffff, true, "center", 120, true);
					tagLayer.addChild(tf);
				}
				n++;
				if (tf.text != rp.name) tf.text = rp.name;
				tf.textColor = rp == hoverRemote ? Ui.GOLD : friend || 0xe8e8e8;
				tf.visible = true;
				tf.x = int(cx - tf.width / 2);
				tf.y = int(cy + TS * 0.4 + 1);
				}
				if (rp.bubbleT > 0 && bubblesOn) {
					var b:Sprite = bubbles[nb];
					if (!b) {
						b = bubbles[nb] = new Sprite();
						b.addChild(Ui.text(12, 0x202020, true, "center", 170));
						tagLayer.addChild(b);
					}
					nb++;
					var bt:TextField = TextField(b.getChildAt(0));
					if (bt.text != rp.bubble) {
						bt.text = rp.bubble;
						b.graphics.clear();
						Ui.panel(b.graphics, -4, -2, bt.width + 8, bt.height + 4, 0xf4f4f0, 0x303030);
						b.graphics.beginFill(0xf4f4f0);
						b.graphics.moveTo(bt.width / 2 - 5, bt.height + 1);
						b.graphics.lineTo(bt.width / 2 + 5, bt.height + 1);
						b.graphics.lineTo(bt.width / 2, bt.height + 8);
						b.graphics.endFill();
					}
					b.visible = true;
					b.alpha = Math.min(1, rp.bubbleT * 2);
					b.x = int(cx - bt.width / 2);
					b.y = int(cy - TS * 0.6 - bt.height - 10);
				}
			}
			for (; n < tags.length; n++) tags[n].visible = false;
			for (; nb < bubbles.length; nb++) bubbles[nb].visible = false;
		}

		private function remoteAt(sx:Number, sy:Number):RemotePlayer {
			var best:RemotePlayer, bd:Number = 26 * 26;
			for each (var rp:RemotePlayer in net.players) {
				if (!shown(rp)) continue;
				var dx:Number = sx - scrX(rp.x, rp.y), dy:Number = sy - (scrY(rp.x, rp.y) - 4);
				if (dx * dx + dy * dy < bd) { bd = dx * dx + dy * dy; best = rp; }
			}
			return best;
		}

		/** Click another player (right-click in combat zones) for their menu. */
		private function updatePlayerClicks(dt:Number):void {
			hoverRemote = input.mx < VIEW_W && !uiCaptured() ? remoteAt(input.mx / zoom, input.my / zoom) : null;
			if (requestPopup) {
				requestT -= dt;
				if (requestT <= 0) closeRequest(true);
			}
			if (!input.clicked && !input.rightClicked) return;
			if (playerMenu && !playerMenu.hitTestPoint(input.mx, input.my, true)) closePlayerMenu();
			if (hoverRemote && (input.rightClicked || world.isSafe(player.x, player.y))) openPlayerMenu(hoverRemote);
		}

		private function openPlayerMenu(rp:RemotePlayer):void {
			closePlayerMenu();
			var m:Sprite = new Sprite();
			m.name = rp.id;
			var gd:Object = net.guild;
			var rows:Array = [
				["Inspect", function():void { openInspect(rp); }],
				["Trade", function():void { net.requestTrade(rp); }],
				net.inParty(rp) ? ["Kick from party", function():void { net.kickParty(rp); }] : ["Invite to party", function():void { net.inviteParty(rp); }]
			];
			if (gd && gd.myRank >= Net.OFFICER && !net.inGuild(rp)) rows.push(["Invite to guild", function():void { net.inviteGuild(rp); }]);
			if (net.isFriend(rp)) rows.push(["Teleport", function():void { teleportTo(rp); }]);
			var h:int = 40 + rows.length * 36;
			Ui.panel(m.graphics, 0, 0, 160, h, 0x1e1e24, 0x8a8a9a, 0.97);
			var t:TextField = Ui.text(15, net.inParty(rp) ? 0x7fd8ff : net.inGuild(rp) ? 0x80ff80 : Ui.GOLD, true, "center", 160, true);
			t.htmlText = rp.name + (rp.profile.guild ? "\n<font size='11' color='#9a9aaa'>" + rp.profile.guild + "</font>" : "");
			t.y = 4;
			m.addChild(t);
			var y:int = rp.profile.guild ? 40 : 32;
			for each (var r:Array in rows) {
				var b:Sprite = Ui.button(r[0], 140, 30, menuFn(r[1]), 13);
				b.x = 10; b.y = y;
				m.addChild(b);
				y += 36;
			}
			m.graphics.clear();
			Ui.panel(m.graphics, 0, 0, 160, y + 4, 0x1e1e24, 0x8a8a9a, 0.97);
			m.x = int(Math.min(VIEW_W - 166, input.mx + 8));
			m.y = int(Math.max(4, Math.min(VIEW_H - y - 10, input.my - 20)));
			playerMenu = m;
			addChild(m);
			Sfx.play("click", 0.5);
		}

		private function menuFn(fn:Function):Function {
			return function():void { closePlayerMenu(); fn(); };
		}

		private function closePlayerMenu():void {
			if (playerMenu && playerMenu.parent) { removeChild(playerMenu); refocus(); }
			playerMenu = null;
		}

		public function openInspect(rp:RemotePlayer):void {
			closeInspect();
			var self:Game = this;
			net.inspect(rp, function(profile:Object):void {
				closeInspect();
				inspectWin = new InspectWindow(self, rp, profile);
				inspectWin.x = int((VIEW_W - InspectWindow.W) / 2);
				inspectWin.y = 36;
				addChild(inspectWin);
			});
		}

		public function closeInspect():void {
			if (inspectWin && inspectWin.parent) { removeChild(inspectWin); refocus(); }
			inspectWin = null;
		}

		/** The connection says another player said something. */
		public function netSay(rp:RemotePlayer, text:String):void {
			if (!shown(rp)) return;
			pushChat("<font color='#ffffff'><b>&lt;" + rp.name + "&gt;</b></font> <font color='#d8d8d8'>" + text.replace(/</g, "&lt;") + "</font>");
			rp.say(text);
		}

		/** Party / guild chat (the sender may be anywhere). */
		public function channelSay(name:String, text:String, channel:String):void {
			var col:String = channel == "party" ? "#7fd8ff" : "#80ff80";
			pushChat("<font color='" + col + "'><b>[" + (channel == "party" ? "Party" : "Guild") + "] &lt;" + name + "&gt;</b> " + text.replace(/</g, "&lt;") + "</font>");
			for each (var rp:RemotePlayer in net.players) if (rp.name == name) rp.say(text);
		}

		/** Hidden players (the "Party & guild" setting) are not drawn and can't be clicked. */
		public function shown(rp:RemotePlayer):Boolean {
			return opt("allplayers") || net.isFriend(rp);
		}

		/** Party or guild changed. */
		public function socialChanged():void {
			if (social) social.refresh();
		}

		public function toggleSocial(tab:int = -1):void {
			if (social && (tab < 0 || social.tab == tab)) { removeChild(social); social = null; refocus(); return; }
			if (!social) {
				social = new SocialWindow(this);
				social.x = int((VIEW_W - SocialWindow.W) / 2);
				social.y = 40;
				addChild(social);
			}
			if (tab >= 0) social.show(tab);
		}

		/** Book button / K / /wiki: every boss and its drops. */
		public function toggleWiki():void {
			if (wiki) { removeChild(wiki); wiki = null; refocus(); return; }
			wiki = new WikiWindow(this);
			wiki.x = int((VIEW_W - WikiWindow.W) / 2);
			wiki.y = 40;
			addChild(wiki);
		}

		/** Teleport to a party or guild member in the same world (RotMG style). */
		public function teleportTo(rp:RemotePlayer):void {
			if (!net.isFriend(rp)) { msg("You can only teleport to party and guild members.", 0xff8080); return; }
			if (net.players.indexOf(rp) < 0) { msg(rp.name + " isn't in this world.", 0xff8080); return; }
			if (tpT > 0) { msg("Teleport is ready in " + Math.ceil(tpT) + "s.", 0xff8080); return; }
			tpT = 10;
			burst(player.x, player.y, 0x9a7cff, 14);
			player.x = rp.x; player.y = rp.y;
			player.invulnT = Math.max(player.invulnT, 1);
			camX = player.x; camY = player.y;
			burst(player.x, player.y, 0x9a7cff, 18);
			Sfx.play("portal", 0.5);
			msg("Teleported to " + rp.name + ".", 0x9a7cff);
		}

		/** Starts a guild (costs gold). */
		public function createGuild(name:String):void {
			if (gold < Net.GUILD_COST) { msg("Creating a guild costs " + Ui.commas(Net.GUILD_COST) + " gold.", 0xff8080); return; }
			net.createGuild(name, guildMade);
		}

		private function guildMade(err:String):void {
			if (err) { msg(err, 0xff8080); return; }
			if (gold < Net.GUILD_COST) return;
			addGold(-Net.GUILD_COST);
			Save.flush();
			showBanner("Guild founded: " + net.guild.name, 0x80ff80, 3);
			msg("You founded " + net.guild.name + "! Invite players from their menu.", 0x80ff80);
			Sfx.play("level");
			socialChanged();
		}

		/** What other players see of you (sent to the server). */
		public function myProfile():Object {
			var p:Player = player;
			return {cls: p.cls.id, skin: p.skin, level: p.level, fame: p.fame, maxed: p.maxedCount,
				equip: [p.weapon, p.ability, p.armor, p.ring], guild: net && net.guild ? net.guild.name : ""};
		}

		public function get trading():Boolean { return tradeWin != null; }

		/** /join: go to the world a party or guild member is in. */
		public function joinPlayer(name:String):void {
			var key:String = net.worldOf(name);
			if (!net.online) { msg("/join works when you're playing online.", 0xff8080); return; }
			if (!key) { msg("You can only join party or guild members who are online.", 0xff8080); return; }
			if (key == world.key) { msg("You're already there.", 0xaaaaaa); return; }
			var parts:Array = key.split(":");
			if (parts[0] == "nexus") { nexus(); return; }
			if (parts[0] == "realm") {
				var ri:int = realmNames.indexOf(parts[1]);
				if (ri < 0) { msg("That realm is gone.", 0xff8080); return; }
				travel(function():void { enterPortal(ri); });
				return;
			}
			if (parts[0] == "dg") {
				var di:int = int(parts[1]), seed:uint = uint(parts[2]);
				travel(function():void { enterDungeon(di, seed); });
				msg("Following " + name + " into the " + Data.DUNGEONS[di].name + ".", Data.DUNGEONS[di].color);
				return;
			}
			msg(name + " is somewhere you can't follow.", 0xff8080);
		}

		/** Opens the chat box with some text already typed. */
		public function chatWith(text:String):void {
			openChat();
			chatInput.text = text;
			chatInput.setSelection(text.length, text.length);
		}

		public function get tradeAsking():Boolean { return requestPopup != null || tradeWin != null; }

		/** The connection says someone wants to trade with you. */
		public function tradeRequested(rp:RemotePlayer):void {
			askPopup("<font color='#d0b8ff'>" + rp.name + "</font> wants to trade with you.", 0xc8a0ff,
				function():void { net.answerTrade(rp, true); },
				function():void { net.answerTrade(rp, false); });
			Sfx.play("trade", 0.6);
		}

		private var requestNo:Function;

		/** Accept / Decline popup (trade, party and guild invites). Unanswered, it declines itself after 20s. */
		public function askPopup(html:String, color:uint, onYes:Function, onNo:Function):void {
			closeRequest(true);
			requestNo = onNo;
			requestT = 20;
			var w:int = 360;
			var pop:Sprite = new Sprite();
			Ui.panel(pop.graphics, 0, 0, w, 92, 0x1e1e24, color, 0.97);
			var t:TextField = Ui.text(15, 0xffffff, true, "center", w - 20, true);
			t.htmlText = html;
			t.x = 10; t.y = 10;
			pop.addChild(t);
			var yes:Sprite = Ui.button("Accept", 140, 32, function():void { requestNo = null; closeRequest(false); onYes(); }, 15);
			yes.x = 30; yes.y = 50;
			pop.addChild(yes);
			var no:Sprite = Ui.button("Decline", 140, 32, function():void { closeRequest(true); }, 15);
			no.x = w - 170; no.y = 50;
			pop.addChild(no);
			pop.x = int((VIEW_W - w) / 2);
			pop.y = 64;
			requestPopup = pop;
			addChild(pop);
			msg(t.text, color);
		}

		private function closeRequest(decline:Boolean):void {
			if (requestPopup && requestPopup.parent) { removeChild(requestPopup); refocus(); }
			requestPopup = null;
			var no:Function = requestNo;
			requestNo = null;
			if (decline && no != null) no();
		}

		/** The connection opened a trade. */
		public function openTrade(s:TradeSession):void {
			closeStation();
			closePlayerMenu();
			closeInspect();
			closeRequest(false);
			if (tradeWin && tradeWin.parent) removeChild(tradeWin);
			tradeWin = new TradeWindow(this, s);
			tradeWin.x = int((VIEW_W - tradeWin.W) / 2);
			tradeWin.y = int(Math.max(40, (VIEW_H - tradeWin.H) / 2 - 30));
			addChild(tradeWin);
			msg("Trading with " + s.partner.name + ".", 0xc8a0ff);
			Sfx.play("trade", 0.6);
		}

		public function closeTrade():void {
			if (net.trade) net.cancelTrade();
			else tradeEnded(null);
		}

		/** The trade finished (ok) or was called off. */
		/** Keys go back to the game after a window closes (a removed button would keep the focus). */
		private function refocus():void {
			if (stage && !(chatInput && chatInput.visible)) stage.focus = stage;
		}

		public function tradeEnded(text:String, ok:Boolean = false):void {
			if (tradeWin && tradeWin.parent) { removeChild(tradeWin); refocus(); }
			tradeWin = null;
			if (text) msg(text, ok ? 0x5ae06a : 0xff8080);
			if (ok) {
				Sfx.play("trade");
				saveCharacter();
				hud.refresh();
			}
		}

		/** Another player fires at a monster. */
		public function botShoot(rp:RemotePlayer, ang:Number, ghost:Boolean = false):void {
			var w:Object = rp.profile.equip[0];
			if (!w || !w.shape) return;
			var fr:Vector.<BitmapData> = Sprites.projectile(w.shape, w.col, w.size || 3);
			for (var k:int = 0; k < (w.shots || 1); k++) {
				var a:Number = ang + (w.shots > 1 && !w.parallel ? (k - (w.shots - 1) / 2) * w.arc * Math.PI / 180 : 0);
				var s:Projectile = new Projectile(rp.x, rp.y, a, w.spd, w.life, int((w.dmin + w.dmax) / 2 * 0.5), false, 0.25, fr, w.pierce, rp.name, null);
				s.bot = true;
				s.ghost = ghost;
				s.shown = shown(rp);
				s.motion = w.motion;
				if (k % 2 == 1) s.phase = Math.PI;
				shots.push(s);
			}
		}

		private function botHit(e:Enemy, s:Projectile):void {
			if (e.dead || e.immune) return;
			var d:int = Math.max(s.dmg - e.defense, int(s.dmg * 0.15));
			e.hp -= d;
			e.hitT = 0.08;
			sparks(s.x, s.y, e.def.col, 1);
			if (e.hp <= 0) killEnemy(e);
		}

		private function drawPlayer():void {
			var p:Player = player;
			var cx:Number = scrX(p.x, p.y), cy:Number = scrY(p.x, p.y);
			if (dyingT > 0 || p.hp <= 0) drawEntity(Sprites.get("grave"), cx, cy, 0);
			else if (!(p.invulnT > 0 && int(time * 12) % 2 == 0)) drawEntity(p.sprite, cx, cy, 0, world.inWater(p.x, p.y));
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
