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

		public function LocalNet(g:Game) {
			super(g);
		}

		// ------------------------------------------------------------ worlds
		override public function enterWorld(w:World):void {
			if (trade) cancelTrade();
			world = w;
			if (!crowds[w]) crowds[w] = populate(w);
			players = crowds[w];
			for each (var b:Bot in players) b.x = b.tx, b.y = b.ty;
		}

		private function populate(w:World):Vector.<RemotePlayer> {
			var list:Vector.<RemotePlayer> = new Vector.<RemotePlayer>();
			var n:int = w.kind == "nexus" ? 9 + int(Math.random() * 4) : w.kind == "realm" ? 6 + int(Math.random() * 4) : 0;
			for (var i:int = 0; i < n; i++) {
				var b:Bot = w.kind == "nexus" ? nexusBot(w) : realmBot(w);
				if (b) list.push(b);
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
				maxed: maxed, equip: equip, inv: inv};
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
			var gx:Number = b.goalX - b.tx, gy:Number = b.goalY - b.ty, gd:Number = Math.sqrt(gx * gx + gy * gy);
			if (gd < 0.1) {
				if (b.leaving) { b.gone = true; g.burst(b.x, b.y, 0x9a7cff, 14); return; }
				b.waitT -= dt;
				if (b.waitT <= 0) pickGoal(b);
				return;
			}
			var speed:Number = world.kind == "nexus" ? 3.2 : 4.4;
			var step:Number = Math.min(gd, speed * dt);
			var nx:Number = b.tx + gx / gd * step, ny:Number = b.ty + gy / gd * step;
			if (world.canStand(nx, ny, 0.3, false)) b.moveTo(nx, ny);
			else if (b.leaving) { b.gone = true; g.burst(b.x, b.y, 0x9a7cff, 14); }
			else { b.goalX = b.tx; b.goalY = b.ty; b.waitT = 0.3; }
		}

		private function pickGoal(b:Bot):void {
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
				if (!b.leaving && !(trade && trade.partner == b)) say(b, advert(b));
			}
			crowdT -= dt;
			if (crowdT <= 0) {
				crowdT = 10 + Math.random() * 15;
				if (players.length > 7 && Math.random() < 0.5) {
					var lv:Bot = Bot(players[int(Math.random() * players.length)]);
					if (!(trade && trade.partner == lv)) {
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
