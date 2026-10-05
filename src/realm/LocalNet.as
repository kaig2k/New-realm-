package realm {
	import flash.utils.Dictionary;

	/**
	 * Offline stand-in for the game server: simulated players who walk around the
	 * Nexus and the realms, chat, fight monsters and trade with you. They go
	 * through exactly the same calls a real server connection will.
	 */
	public class LocalNet extends Net {
		private static const SYL1:Array = ["Ka", "Ro", "Thi", "Va", "Lu", "Mor", "Zen", "Ar", "Eli", "Dra", "Fen", "Gor", "Ith", "Jor", "Ky", "Nim",
			"Oz", "Pyr", "Quel", "Sy", "Tor", "Ul", "Vex", "Wyn", "Xa", "Yel", "Bri", "Cael", "Del", "Hal", "Mira", "Sol"];
		private static const SYL2:Array = ["rin", "dor", "ax", "ia", "on", "eth", "ir", "us", "ra", "ek", "yn", "os", "ith", "al", "ur", "en",
			"wen", "mar", "is", "ion", "a", "o", "ix", "an"];
		private static const GREETS:Array = ["hey", "hi", "yo", "hello!", "o/", "sup"];
		private static const IDLE:Array = ["anyone trading?", "lf trade", "gl everyone", "realm is popping rn", "need Star Shards",
			"who wants to run some dungeons?", "trade me if you need pots", "just died to a beholder lol", "nice weather in the Nexus",
			"selling pots, trade me", "how do i get to the godlands", "/glands is the way"];

		/** Bots per world, so each realm keeps its own crowd. */
		private var crowds:Dictionary = new Dictionary(true);
		private var world:World;
		private var chatT:Number = 5;
		private var crowdT:Number = 10;
		private var askT:Number = 70;
		private var names:Object = {};
		private var pending:Array = [];
		/** Guild members online this session, and their bots (when they're in the Nexus). */
		private var online:Object = {};
		private var guildT:Number = 40;
		private static const OTHER_GUILDS:Array = ["Night Owls", "Realm Wardens", "Star Chasers", "Lost Heroes", "The Ember Pact",
			"Godlanders", "Pot Hoarders", "Shoreline", "Midnight Oath"];
		private static const PARTY_SAYS:Array = ["ok", "omw", "lets go", "ty", "sure", "nice", "following you", "lol", "gg"];
		private static const GUILD_SAYS:Array = ["anyone up for a dungeon?", "gz on the drop!", "who wants to run the Godlands?",
			"just maxed my defense", "hi guild", "need someone for a trade", "realm is closing soon, come to the Nexus"];

		public function LocalNet(g:Game) {
			super(g);
			var gd:Object = guild;
			if (gd) for each (var m:Object in gd.members) {
				names[m.name.toLowerCase()] = true;
				if (Math.random() < 0.4) online[m.name] = true;
			}
		}

		// ------------------------------------------------------------ worlds
		override public function enterWorld(w:World):void {
			if (trade) cancelTrade();
			// your party comes with you
			var p:RemotePlayer;
			for each (p in party) {
				var i:int = players.indexOf(p);
				if (i >= 0) players.splice(i, 1);
			}
			world = w;
			if (!crowds[w]) crowds[w] = populate(w);
			players = crowds[w];
			for each (var b:Bot in players) b.x = b.tx, b.y = b.ty;
			var k:int = 0;
			for each (p in party) {
				var pb:Bot = Bot(p);
				var a:Number = k++ * Math.PI * 2 / 5 + Math.PI / 2;
				var px:Number = g.player.x + Math.cos(a) * 1.4, py:Number = g.player.y + Math.sin(a) * 1.4;
				if (!w.canStand(px, py, 0.3, false)) { px = g.player.x; py = g.player.y; }
				pb.x = pb.tx = pb.goalX = pb.homeX = px;
				pb.y = pb.ty = pb.goalY = pb.homeY = py;
				players.push(pb);
			}
		}

		private function populate(w:World):Vector.<RemotePlayer> {
			var list:Vector.<RemotePlayer> = new Vector.<RemotePlayer>();
			var n:int = w.kind == "nexus" ? 9 + int(Math.random() * 4) : w.kind == "realm" ? 6 + int(Math.random() * 4) : 0;
			for (var i:int = 0; i < n; i++) {
				var b:Bot = w.kind == "nexus" ? nexusBot(w) : realmBot(w);
				if (b) list.push(b);
			}
			var gd:Object = guild;
			if (w.kind == "nexus" && gd) for each (var m:Object in gd.members) {
				if (!online[m.name]) continue;
				var gb:Bot = nexusBot(w);
				if (!gb) continue;
				gb.name = m.name;
				gb.profile.cls = m.cls;
				gb.profile.skin = "";
				gb.profile.level = m.level;
				gb.profile.guild = gd.name;
				list.push(gb);
			}
			return list;
		}

		private function nexusBot(w:World):Bot {
			var lvl:int = Math.random() < 0.6 ? 20 : 1 + int(Math.random() * 20);
			for (var t:int = 0; t < 40; t++) {
				var x:Number = 82 + Math.random() * 36, y:Number = 87 + Math.random() * 27;
				if (w.canStand(x, y, 0.4, false)) return makeBot(lvl, x, y);
			}
			return null;
		}

		private function realmBot(w:World):Bot {
			for (var t:int = 0; t < 200; t++) {
				var a:Number = Math.random() * Math.PI * 2, r:Number = 4 + Math.random() * 30;
				var x:Number = w.spawnX + Math.cos(a) * r, y:Number = w.spawnY + Math.sin(a) * r;
				if (!w.canStand(x, y, 0.4, false)) continue;
				var b:Bot = makeBot(4 + int(Math.random() * 17), x, y);
				return b;
			}
			return null;
		}

		private function uniqueName():String {
			for (var t:int = 0; t < 50; t++) {
				var n:String = SYL1[int(Math.random() * SYL1.length)] + SYL2[int(Math.random() * SYL2.length)];
				if (Math.random() < 0.3) n += SYL2[int(Math.random() * SYL2.length)];
				if (!names[n.toLowerCase()] && n.toLowerCase() != g.player.name.toLowerCase()) {
					names[n.toLowerCase()] = true;
					return n;
				}
			}
			return "Player" + int(Math.random() * 9999);
		}

		private function makeBot(level:int, x:Number, y:Number):Bot {
			var clsId:String = Data.CLASS_ORDER[int(Math.random() * Data.CLASS_ORDER.length)];
			var cls:Object = Data.CLASSES[clsId];
			var skins:Array = Data.SKINS[clsId];
			var skin:String = skins && Math.random() < 0.25 ? skins[int(Math.random() * skins.length)].id : "";
			var equip:Array = [];
			for (var s:int = 0; s < 4; s++) equip.push(s == 3 && level < 5 ? null : gear(cls, s, level));
			var inv:Array = [];
			var n:int = 2 + int(Math.random() * 6);
			for (var i:int = 0; i < 8; i++) inv.push(i < n ? loot(level) : null);
			var maxed:int = level >= 20 ? int(Math.random() * 12) : 0;
			var profile:Object = {cls: clsId, skin: skin, level: level, fame: level * 40 + int(Math.random() * level * 120) + maxed * 300,
				maxed: maxed, equip: equip, inv: inv, guild: Math.random() < 0.25 ? OTHER_GUILDS[int(Math.random() * OTHER_GUILDS.length)] : ""};
			var b:Bot = new Bot("bot" + int(Math.random() * 1e9), uniqueName(), x, y, profile);
			b.greed = 0.9 + Math.random() * 0.4;
			b.wants = ["stat", "material", "ut", "st", "fb"][int(Math.random() * 5)];
			b.goalX = x; b.goalY = y;
			b.homeX = x; b.homeY = y;
			b.waitT = Math.random() * 3;
			return b;
		}

		private static function tierFor(level:int, cap:int):int {
			return Math.max(0, Math.min(cap, int(level / 20 * (cap - 1) + Math.random() * 2.2 - 0.6)));
		}

		private static function rarityRoll(level:int):String {
			if (level < 20) return null;
			var r:Number = Math.random();
			return r < 0.005 ? "ar" : r < 0.025 ? "lg" : r < 0.065 ? "fb" : r < 0.16 ? "st" : r < 0.36 ? "ut" : null;
		}

		private static function gear(cls:Object, slot:int, level:int):Object {
			var caps:Array = [7, 6, 7, 5];
			var rar:String = rarityRoll(level);
			return Data.makeForSlot(cls, slot, rar ? 7 : tierFor(level, caps[slot]), rar);
		}

		private static function loot(level:int):Object {
			var r:Number = Math.random();
			if (r < 0.22) return Data.makePotion("stat", Data.randomStat());
			if (r < 0.32) return Data.makeSor();
			if (r < 0.42) return Data.makePotion(Math.random() < 0.5 ? "hp" : "mp");
			var cls:Object = Data.CLASSES[Data.CLASS_ORDER[int(Math.random() * Data.CLASS_ORDER.length)]];
			return gear(cls, int(Math.random() * 4), level);
		}

		// ------------------------------------------------------------ simulation
		override public function update(dt:Number):void {
			for (var i:int = pending.length - 1; i >= 0; i--) {
				pending[i].t -= dt;
				if (pending[i].t <= 0) {
					var fn:Function = pending[i].fn;
					pending.splice(i, 1);
					fn();
				}
			}
			for (i = players.length - 1; i >= 0; i--) {
				var b:Bot = Bot(players[i]);
				if (b.gone) { players.splice(i, 1); continue; }
				think(b, dt);
				b.update(dt);
			}
			if (world && world.kind == "nexus") nexusLife(dt);
			guildLife(dt);
			if (trade) updateTrade(dt);
		}

		private function later(secs:Number, fn:Function):void {
			pending.push({t: secs, fn: fn});
		}

		private function say(b:RemotePlayer, text:String):void {
			if (b.gone || players.indexOf(b) < 0) return;
			g.netSay(b, text);
		}

		private function think(b:Bot, dt:Number):void {
			if (trade && trade.partner == b) { b.moveTo(b.x, b.y); return; }
			// fight anything close (realms only)
			if (world.kind == "realm") {
				b.shootT -= dt;
				var e:Enemy = nearestEnemy(b, 6.5);
				if (e) {
					b.attacking = 0.3;
					b.facingLeft = e.x < b.x;
					if (b.shootT <= 0) {
						b.shootT = 0.35 + Math.random() * 0.15;
						g.botShoot(b, Math.atan2(e.y - b.y, e.x - b.x));
					}
					// keep some distance
					var dx:Number = b.x - e.x, dy:Number = b.y - e.y, d:Number = Math.sqrt(dx * dx + dy * dy) || 1;
					if (d < 4) { b.goalX = b.x + dx / d * 2; b.goalY = b.y + dy / d * 2; }
				}
			}
			if (b.inParty) follow(b);
			var gx:Number = b.goalX - b.tx, gy:Number = b.goalY - b.ty, gd:Number = Math.sqrt(gx * gx + gy * gy);
			if (gd < 0.1) {
				if (b.leaving) { b.gone = true; g.burst(b.x, b.y, 0x9a7cff, 14); return; }
				b.waitT -= dt;
				if (b.waitT <= 0) pickGoal(b);
				return;
			}
			var speed:Number = b.inParty ? 6.5 : world.kind == "nexus" ? 3.2 : 4.4;
			if (world.inWater(b.tx, b.ty)) speed *= 0.5;
			var step:Number = Math.min(gd, speed * dt);
			var nx:Number = b.tx + gx / gd * step, ny:Number = b.ty + gy / gd * step;
			if (world.canStand(nx, ny, 0.3, false)) b.moveTo(nx, ny);
			else if (b.leaving) { b.gone = true; g.burst(b.x, b.y, 0x9a7cff, 14); }
			else { b.goalX = b.tx; b.goalY = b.ty; b.waitT = 0.3; }
		}

		/** Party members stay close to you, and catch up if you get far ahead. */
		private function follow(b:Bot):void {
			var i:int = party.indexOf(b);
			var a:Number = i * Math.PI * 2 / 5 + Math.PI / 2;
			var px:Number = g.player.x + Math.cos(a) * 1.5, py:Number = g.player.y + Math.sin(a) * 1.5;
			var dx:Number = px - b.tx, dy:Number = py - b.ty;
			var d:Number = dx * dx + dy * dy;
			if (d > 18 * 18) { b.moveTo(px, py); b.goalX = px; b.goalY = py; return; }
			if (d > 1.2 * 1.2) { b.goalX = px; b.goalY = py; b.waitT = 0; }
		}

		private function pickGoal(b:Bot):void {
			if (b.inParty) { b.waitT = 0.3; return; }
			b.waitT = world.kind == "nexus" ? 2 + Math.random() * 7 : 0.5 + Math.random() * 2;
			var range:Number = world.kind == "nexus" ? 9 : 14;
			if (world.kind == "realm") {
				// drift inland over time, like a real crowd heading for the Godlands
				var cx:Number = world.N / 2, cy:Number = world.N / 2;
				var hx:Number = cx - b.homeX, hy:Number = cy - b.homeY, hd:Number = Math.sqrt(hx * hx + hy * hy) || 1;
				if (hd > 30) { b.homeX += hx / hd * 3; b.homeY += hy / hd * 3; }
			}
			for (var t:int = 0; t < 20; t++) {
				var x:Number = b.homeX + (Math.random() - 0.5) * range * 2, y:Number = b.homeY + (Math.random() - 0.5) * range * 2;
				if (world.canStand(x, y, 0.4, false)) { b.goalX = x; b.goalY = y; return; }
			}
		}

		private function nearestEnemy(b:Bot, range:Number):Enemy {
			var best:Enemy, bd:Number = range * range;
			for each (var e:Enemy in g.enemies) {
				if (e.dead || e.invuln) continue;
				var dx:Number = e.x - b.x, dy:Number = e.y - b.y, d:Number = dx * dx + dy * dy;
				if (d < bd) { bd = d; best = e; }
			}
			return best;
		}

		/** People come and go, advertise trades and sometimes ask you to trade. */
		private function nexusLife(dt:Number):void {
			chatT -= dt;
			if (chatT <= 0 && players.length) {
				chatT = 7 + Math.random() * 10;
				var b:Bot = Bot(players[int(Math.random() * players.length)]);
				if (!b.leaving && !b.inParty && !(trade && trade.partner == b)) say(b, advert(b));
			}
			crowdT -= dt;
			if (crowdT <= 0) {
				crowdT = 10 + Math.random() * 15;
				if (players.length > 7 && Math.random() < 0.5) {
					var lv:Bot = Bot(players[int(Math.random() * players.length)]);
					if (!(trade && trade.partner == lv) && !lv.inParty && !inGuild(lv)) {
						// walk off through one of the realm portals
						lv.leaving = true;
						lv.goalX = [90.5, 100.5, 110.5][int(Math.random() * 3)];
						lv.goalY = 84.2;
					}
				} else if (players.length < 14) {
					var nb:Bot = makeBot(Math.random() < 0.6 ? 20 : 1 + int(Math.random() * 20), world.spawnX, world.spawnY);
					players.push(nb);
					pickGoal(nb);
					g.burst(nb.x, nb.y, 0x9a7cff, 10);
				}
			}
			askT -= dt;
			if (askT <= 0 && !trade && !g.tradeAsking) {
				askT = 60 + Math.random() * 60;
				var near:Bot = nearestBot(8);
				if (near && near.sellIdx() >= 0) {
					near.offering = near.sellIdx();
					g.tradeRequested(near);
				}
			}
		}

		private function guildLife(dt:Number):void {
			var gd:Object = guild;
			if (!gd) return;
			guildT -= dt;
			if (guildT > 0) return;
			guildT = 50 + Math.random() * 50;
			var on:Array = onlineMembers();
			if (on.length) g.channelSay(on[int(Math.random() * on.length)], GUILD_SAYS[int(Math.random() * GUILD_SAYS.length)], "guild");
		}

		private function onlineMembers():Array {
			var out:Array = [];
			var gd:Object = guild;
			if (gd) for each (var m:Object in gd.members) if (online[m.name]) out.push(m.name);
			return out;
		}

		private function nearestBot(range:Number):Bot {
			var best:Bot, bd:Number = range * range;
			for each (var b:Bot in players) {
				if (b.leaving) continue;
				var dx:Number = b.x - g.player.x, dy:Number = b.y - g.player.y, d:Number = dx * dx + dy * dy;
				if (d < bd) { bd = d; best = b; }
			}
			return best;
		}

		private function advert(b:Bot):String {
			var r:Number = Math.random();
			var sell:int = b.sellIdx();
			if (r < 0.45 && sell >= 0) {
				var it:Object = b.profile.inv[sell];
				return "WTS " + it.name + (Data.tierLabel(it) ? " [" + Data.tierLabel(it) + "]" : "") + ", trade me";
			}
			if (r < 0.6) return "WTB " + wantName(b.wants);
			if (r < 0.7) return "anyone running " + Data.DUNGEONS[int(Math.random() * Data.DUNGEONS.length)].name + "?";
			return IDLE[int(Math.random() * IDLE.length)];
		}

		private static function wantName(w:String):String {
			if (w == "stat") return "stat potions";
			if (w == "material") return "Star Shards";
			return Data.RARITY_NAMES[w] + " items";
		}

		override public function chat(text:String):void {
			if (!/^(hi|hello|hey|yo|sup|o\/)\b/i.test(text)) return;
			var b:Bot = nearestBot(14);
			if (b) later(1 + Math.random(), function():void { say(b, GREETS[int(Math.random() * GREETS.length)]); });
		}

		// ------------------------------------------------------------ party
		override public function inviteParty(p:RemotePlayer):void {
			var b:Bot = Bot(p);
			if (b.inParty) { g.msg(b.name + " is already in your party.", 0xff8080); return; }
			if (party.length + 1 >= PARTY_MAX) { g.msg("Your party is full (" + PARTY_MAX + " players max).", 0xff8080); return; }
			g.msg("You invited " + b.name + " to your party.", 0x7fd8ff);
			later(1 + Math.random(), function():void {
				if (b.gone || players.indexOf(b) < 0) return;
				if (party.length + 1 >= PARTY_MAX) return;
				if (b.leaving || Math.random() < 0.25) {
					say(b, ["no thanks", "solo for now", "maybe later"][int(Math.random() * 3)]);
					g.msg(b.name + " declined your party invite.", 0xff8080);
					return;
				}
				b.inParty = true;
				b.offering = -1;
				party.push(b);
				g.channelSay(b.name, ["hi party!", "ty for the invite", "lets go", "o/"][int(Math.random() * 4)], "party");
				g.msg(b.name + " joined the party. (" + (party.length + 1) + "/" + PARTY_MAX + ")", 0x7fd8ff);
				g.socialChanged();
			});
		}

		override public function leaveParty():void {
			if (!party.length) { g.msg("You're not in a party.", 0xff8080); return; }
			for each (var p:RemotePlayer in party) { Bot(p).inParty = false; Bot(p).homeX = p.x; Bot(p).homeY = p.y; }
			party.length = 0;
			g.msg("You left the party.", 0x7fd8ff);
			g.socialChanged();
		}

		override public function kickParty(p:RemotePlayer):void {
			var i:int = party.indexOf(p);
			if (i < 0) return;
			party.splice(i, 1);
			var b:Bot = Bot(p);
			b.inParty = false;
			b.homeX = b.x; b.homeY = b.y;
			g.msg(b.name + " was removed from the party.", 0x7fd8ff);
			g.socialChanged();
		}

		override public function partyChat(text:String):void {
			if (!party.length || Math.random() < 0.4) return;
			var b:RemotePlayer = party[int(Math.random() * party.length)];
			later(1 + Math.random() * 1.5, function():void {
				if (inParty(b)) g.channelSay(b.name, PARTY_SAYS[int(Math.random() * PARTY_SAYS.length)], "party");
			});
		}

		// ------------------------------------------------------------ guild
		override public function get guild():Object { return Save.data.guild || null; }

		override public function createGuild(name:String):String {
			if (guild) return "You're already in a guild.";
			name = name.replace(/^\s+|\s+$/g, "").replace(/\s+/g, " ");
			if (!/^[A-Za-z][A-Za-z ]{2,19}$/.test(name)) return "Guild names are 3-20 letters (spaces allowed).";
			if (OTHER_GUILDS.indexOf(name) >= 0) return "That guild name is taken.";
			Save.data.guild = {name: name, myRank: FOUNDER, members: []};
			Save.flush();
			return null;
		}

		override public function inviteGuild(p:RemotePlayer):void {
			var gd:Object = guild, b:Bot = Bot(p);
			if (!gd) { g.msg("You're not in a guild. Create one with /guild create Name.", 0xff8080); return; }
			if (gd.myRank < OFFICER) { g.msg("Only Officers and above can invite.", 0xff8080); return; }
			if (gd.members.length + 1 >= GUILD_MAX) { g.msg("Your guild is full (" + GUILD_MAX + " members max).", 0xff8080); return; }
			if (inGuild(b)) { g.msg(b.name + " is already in your guild.", 0xff8080); return; }
			g.msg("You invited " + b.name + " to " + gd.name + ".", 0x80ff80);
			later(1.2 + Math.random(), function():void {
				if (b.gone || players.indexOf(b) < 0 || !guild) return;
				if (b.profile.guild) { say(b, "sorry, i'm in " + b.profile.guild); g.msg(b.name + " is already in a guild.", 0xff8080); return; }
				if (Math.random() < 0.35) { say(b, ["no thanks", "not looking for a guild", "maybe later"][int(Math.random() * 3)]); g.msg(b.name + " declined the guild invite.", 0xff8080); return; }
				b.profile.guild = guild.name;
				guild.members.push({name: b.name, cls: b.profile.cls, level: b.profile.level, fame: b.profile.fame, rank: 0});
				online[b.name] = true;
				Save.flush();
				g.channelSay(b.name, ["thanks for the invite!", "hi guild!", "glad to be here"][int(Math.random() * 3)], "guild");
				g.msg(b.name + " joined " + guild.name + ". (" + (guild.members.length + 1) + "/" + GUILD_MAX + ")", 0x80ff80);
				g.socialChanged();
			});
		}

		override public function leaveGuild():void {
			var gd:Object = guild;
			if (!gd) return;
			for each (var c:Vector.<RemotePlayer> in crowds) for each (var p:RemotePlayer in c) if (p.profile.guild == gd.name) p.profile.guild = "";
			Save.data.guild = null;
			Save.flush();
			g.msg(gd.myRank == FOUNDER ? "You disbanded " + gd.name + "." : "You left " + gd.name + ".", 0x80ff80);
			g.socialChanged();
		}

		private function member(name:String):Object {
			var gd:Object = guild;
			if (gd) for each (var m:Object in gd.members) if (m.name == name) return m;
			return null;
		}

		override public function kickGuild(name:String):void {
			var gd:Object = guild, m:Object = member(name);
			if (!m || gd.myRank < OFFICER || m.rank >= gd.myRank) { g.msg("You can't remove " + name + ".", 0xff8080); return; }
			gd.members.splice(gd.members.indexOf(m), 1);
			for each (var c:Vector.<RemotePlayer> in crowds) for each (var p:RemotePlayer in c) if (p.name == name) p.profile.guild = "";
			Save.flush();
			g.msg(name + " was removed from " + gd.name + ".", 0x80ff80);
			g.socialChanged();
		}

		override public function setRank(name:String, rank:int):void {
			var gd:Object = guild, m:Object = member(name);
			if (!m || rank < 0 || rank >= gd.myRank || m.rank >= gd.myRank) return;
			var up:Boolean = rank > m.rank;
			m.rank = rank;
			Save.flush();
			g.msg(name + " was " + (up ? "promoted" : "demoted") + " to " + RANKS[rank] + ".", 0x80ff80);
			g.socialChanged();
		}

		override public function guildChat(text:String):void {
			var on:Array = onlineMembers();
			if (!on.length || Math.random() < 0.5) return;
			var who:String = on[int(Math.random() * on.length)];
			later(1.5 + Math.random() * 2, function():void { if (member(who)) g.channelSay(who, PARTY_SAYS[int(Math.random() * PARTY_SAYS.length)], "guild"); });
		}

		override public function guildStatus(name:String):String {
			for each (var p:RemotePlayer in players) if (p.name == name) return "here";
			return online[name] ? "online" : "offline";
		}

		// ------------------------------------------------------------ trading
		/** What an item is worth to a bot, in gold. Bots value currency items highly. */
		private static function worth(b:Bot, it:Object):int {
			if (!it) return 0;
			var v:Number = it.kind == "stat" ? 450 : it.kind == "material" ? 650 : Data.sellValue(it);
			if (it.kind == b.wants || it.rarity == b.wants) v *= 1.4;
			return int(v);
		}

		private static function total(b:Bot, items:Array):int {
			var n:int = 0;
			for each (var it:Object in items) n += worth(b, it);
			return n;
		}

		override public function requestTrade(p:RemotePlayer):void {
			var b:Bot = Bot(p);
			g.msg("You sent a trade request to " + b.name + ".", 0xc8a0ff);
			if (b.leaving || Math.random() < 0.12) {
				later(1.2, function():void {
					say(b, ["busy rn sorry", "not now", "nah im good"][int(Math.random() * 3)]);
					g.msg(b.name + " declined the trade.", 0xff8080);
				});
				return;
			}
			later(0.8, function():void { startTrade(b); });
		}

		override public function answerTrade(p:RemotePlayer, yes:Boolean):void {
			var b:Bot = Bot(p);
			if (!yes) { b.offering = -1; say(b, "ok np"); return; }
			startTrade(b);
		}

		private function startTrade(b:Bot):void {
			if (trade || b.gone || players.indexOf(b) < 0) return;
			trade = new TradeSession(b, g.player.inv, b.profile.inv);
			b.lastVersion = -1;
			b.acceptPlan = false;
			b.thinkT = 1;
			g.openTrade(trade);
			if (b.offering >= 0) {
				var sel:Array = [];
				sel[b.offering] = true;
				trade.setTheirs(sel);
				var it:Object = b.profile.inv[b.offering];
				say(b, it.name + " for about " + Ui.commas(int(worth(b, it) * b.greed)) + "g worth of stuff?");
				b.lastVersion = trade.version;
			} else {
				say(b, ["what do you need?", "sure, what are you looking for?", "hey, click what you want"][int(Math.random() * 3)]);
			}
		}

		override public function tradeChanged():void {
			if (!trade) return;
			var b:Bot = Bot(trade.partner);
			b.thinkT = 0.8 + Math.random() * 0.6;
		}

		override public function cancelTrade():void {
			if (!trade) return;
			var b:Bot = Bot(trade.partner);
			trade.closed = true;
			trade = null;
			b.offering = -1;
			g.tradeEnded("Trade cancelled.");
			say(b, ["ok bye", "nvm then", "np"][int(Math.random() * 3)]);
		}

		private function updateTrade(dt:Number):void {
			var b:Bot = Bot(trade.partner);
			trade.update(dt);
			if (b.gone) { cancelTrade(); return; }
			b.thinkT -= dt;
			if (b.thinkT <= 0 && trade.version != b.lastVersion) {
				b.lastVersion = trade.version;
				evaluate(b);
				b.lastVersion = trade.version;
			}
			if (b.acceptPlan && !trade.theirAccept && !trade.locked) {
				trade.setTheirAccept(true);
			}
			// you accepted a gift-only trade, or an offer it already agreed to
			if (trade.bothAccepted) {
				trade.execute();
				var got:Array = trade.myOffer();
				trade = null;
				b.offering = -1;
				g.tradeEnded("Trade successful!", true);
				say(b, got.length ? ["ty!", "pleasure doing business", "gg, thanks"][int(Math.random() * 3)] : "enjoy!");
			}
		}

		private function evaluate(b:Bot):void {
			var give:int = total(b, trade.myOffer());
			var askSel:Array = trade.wanted.concat();
			var asked:Boolean = trade.count(askSel) > 0;
			if (!asked && b.offering >= 0 && trade.theirs[b.offering]) {
				askSel = [];
				askSel[b.offering] = true;
			}
			var ask:Array = [];
			for (var i:int = 0; i < trade.theirs.length; i++) if (askSel[i] && trade.theirs[i]) ask.push(trade.theirs[i]);
			var price:int = int(total(b, ask) * b.greed);
			b.acceptPlan = false;
			if (!ask.length) {
				trade.setTheirs([]);
				if (give > 0) { say(b, "a gift? thanks!"); b.acceptPlan = true; }
				return;
			}
			var space:String = (function():String {
				var empty:int = 0;
				for each (var it:Object in trade.theirs) if (!it) empty++;
				return empty + ask.length < trade.count(trade.mySel) ? "i don't have room for all that" : null;
			})();
			trade.setTheirs(askSel);
			if (space) { say(b, space); return; }
			if (give >= price) {
				b.acceptPlan = true;
				say(b, ["deal", "ok deal", "sounds fair", "sure"][int(Math.random() * 4)]);
			} else if (give == 0) {
				say(b, "what are you offering? i'd want about " + Ui.commas(price) + "g worth for " + (ask.length == 1 ? "that" : "those"));
			} else {
				say(b, "not enough, add about " + Ui.commas(Math.max(50, price - give)) + "g more");
			}
		}
	}
}

import realm.Data;
import realm.RemotePlayer;

/** A simulated player with a little bit of brain. */
class Bot extends RemotePlayer {
	public var goalX:Number, goalY:Number;
	public var homeX:Number, homeY:Number;
	public var waitT:Number = 0;
	public var shootT:Number = 0;
	public var leaving:Boolean = false;
	/** 0.9 = generous, 1.3 = greedy. */
	public var greed:Number = 1;
	/** The kind of item it values extra: "stat", "material" or a rarity id. */
	public var wants:String;
	/** Inventory slot it is trying to sell to you, or -1. */
	public var offering:int = -1;
	public var lastVersion:int = -1;
	public var thinkT:Number = 0;
	public var acceptPlan:Boolean = false;
	public var inParty:Boolean = false;

	public function Bot(id:String, name:String, x:Number, y:Number, profile:Object) {
		super(id, name, x, y, profile);
	}

	/** Its best item (what it advertises), or -1. */
	public function sellIdx():int {
		var best:int = -1, bv:int = 0;
		for (var i:int = 0; i < profile.inv.length; i++) {
			var it:Object = profile.inv[i];
			if (!it || it.kind == "hp" || it.kind == "mp") continue;
			var v:int = Data.sellValue(it);
			if (v > bv) { bv = v; best = i; }
		}
		return best;
	}
}
