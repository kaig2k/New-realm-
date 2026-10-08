package realm {
	import flash.utils.getTimer;

	/**
	 * Net over a real server connection (Online): the other players are real.
	 * Monsters still run in your own game; the server shares players, chat,
	 * parties, guilds and trades.
	 */
	public class ServerNet extends Net {
		/** Everyone we've heard of this session, by server id (same object across worlds). */
		private var known:Object = {};
		private var worldKey:String = "";
		private var sendT:Number = 0, profT:Number = 0;
		private var lastX:Number = NaN, lastY:Number = NaN;
		private var lastProfile:String = "";
		private var myGuild:Object;
		/** Party members as the server sent them: {id, name, profile, world}. */
		private var partyInfo:Array = [];
		private var sentVersion:int = -1;
		private var sentAccept:Boolean = false;
		private var guildDone:Function;
		private var pingT:Number = 2;
		/** Round trip to the server in ms (-1 until measured). */
		public var latency:int = -1;
		private var retryT:Number = 0;
		private var lastHid:int = 0;
		private var retries:int = 0;
		private var reconnecting:Boolean = false;

		public function ServerNet(g:Game) {
			super(g);
			Online.onClose = function():void {
				g.msg("Lost the connection to the server. Reconnecting...", 0xff8080);
				if (trade) endTrade("Trade cancelled.");
				players.length = 0;
				party.length = 0;
				partyInfo = [];
				// keep playing: this game runs the monsters until we're back
				g.sync.hostChanged(g.world.key, true);
				g.socialChanged();
				retries = 0;
				retryT = 3;
			};
			Online.onMessage = onMessage;
		}

		override public function get myId():int { return Online.welcome ? Online.welcome.id : 0; }

		override public function sendWorld(to:*, d:Object):void { Online.send({t: "w", to: to, d: d}); }

		override public function enterWorld(w:World):void {
			if (trade) cancelTrade();
			worldKey = w.key;
			players.length = 0;
			lastProfile = JSON.stringify(g.myProfile());
			Online.send({t: "enter", key: w.key, label: w.name, cid: g.player.id, x: g.player.x, y: g.player.y, profile: g.myProfile()});
		}

		override public function get online():Boolean { return Online.connected; }

		/** Asks the server where a party or guild member is right now (it answers with tppos). */
		override public function requestTeleport(p:RemotePlayer):void { Online.send({t: "tpreq", id: p.id}); }

		override public function update(dt:Number):void {
			for each (var p:RemotePlayer in players) p.update(dt);
			if (trade) trade.update(dt);
			if (!Online.connected) { tryReconnect(dt); return; }
			pingT -= dt;
			if (pingT <= 0) { pingT = 5; Online.send({t: "ping", at: getTimer()}); }
			sendT -= dt;
			if (sendT <= 0) {
				sendT = 0.1;
				var pl:Player = g.player;
				// h: invisible (monsters, which the server runs, can't see you)
				var hid:int = pl.invisT > 0 ? 1 : 0;
				if (pl.x != lastX || pl.y != lastY || hid != lastHid) {
					lastX = pl.x; lastY = pl.y; lastHid = hid;
					Online.send({t: "move", x: Math.round(pl.x * 100) / 100, y: Math.round(pl.y * 100) / 100, f: pl.facingLeft ? 1 : 0, h: hid});
				}
			}
			profT -= dt;
			if (profT <= 0) {
				profT = 1.5;
				var prof:Object = g.myProfile();
				var js:String = JSON.stringify(prof);
				if (js != lastProfile) { lastProfile = js; Online.send({t: "profile", profile: prof}); }
			}
		}

		private function tryReconnect(dt:Number):void {
			if (reconnecting || retries >= 10 || !Online.address) return;
			retryT -= dt;
			if (retryT > 0) return;
			reconnecting = true;
			retries++;
			Online.connect(Online.address, function(err:String):void {
				reconnecting = false;
				if (err) {
					retryT = 5;
					if (retries >= 10) g.lostConnection(err);
					return;
				}
				g.msg("Reconnected to " + Online.serverName + ".", 0x5ae06a);
				lastX = NaN;
				lastProfile = "";
				enterWorld(g.world);
			});
		}

		override public function serverCommand(text:String):void { Online.send({t: "cmd", text: text}); }

		/** Sends a shop or forge request along with your latest save (the server checks and answers). */
		override public function shopRequest(req:Object):Boolean {
			if (!Online.welcome || !Online.welcome.serverMonsters) return false;
			// the shops are on the server: nothing to buy until we're reconnected
			if (!Online.connected) { g.msg("You're not connected right now. Try again once you're back online.", 0xff8080); return true; }
			g.saveCharacter();
			req.data = Save.data;
			Online.send(req);
			return true;
		}
		override public function realmClosed(key:String):void { Online.send({t: "realmClosed", key: key}); }

		/** The server trades from its copy of your inventory, so it gets your latest save first. */
		private function syncForTrade():void {
			g.saveCharacter();
			Online.sendSave();
		}

		override public function chat(text:String):void { Online.send({t: "chat", text: text}); }
		override public function shoot(ang:Number):void { Online.send({t: "shoot", ang: Math.round(ang * 1000) / 1000}); }
		override public function abilityFx(k:String, x:Number, y:Number, tx:Number, ty:Number, n:Number):void {
			var r:Function = function(v:Number):Number { return Math.round(v * 100) / 100; };
			Online.send({t: "fx", k: k, x: r(x), y: r(y), tx: r(tx), ty: r(ty), n: r(n)});
		}

		// ------------------------------------------------------------ players
		private function meet(info:Object):RemotePlayer {
			var rp:RemotePlayer = known[info.id];
			if (!rp) rp = known[info.id] = new RemotePlayer(String(info.id), info.name, info.x || 0, info.y || 0, info.profile || {});
			if (info.profile) rp.profile = info.profile;
			if (!rp.profile.equip) rp.profile.equip = [null, null, null, null];
			if (!rp.profile.cls) rp.profile.cls = "wizard";
			rp.gone = false;
			return rp;
		}

		private function arrive(info:Object):void {
			var rp:RemotePlayer = meet(info);
			rp.x = rp.tx = info.x; rp.y = rp.ty = info.y;
			if (players.indexOf(rp) < 0) players.push(rp);
		}

		private function byId(id:*):RemotePlayer {
			var rp:RemotePlayer = known[id];
			return rp && players.indexOf(rp) >= 0 ? rp : null;
		}

		private function onMessage(m:Object):void {
			var rp:RemotePlayer;
			switch (m.t) {
				case "players":
					players.length = 0;
					for each (var info:Object in m.list) arrive(info);
					if (m.key == worldKey) g.sync.entered(worldKey, m.host == myId);
					break;
				case "host":
					g.sync.hostChanged(m.key, m.id == myId);
					break;
				case "w":
					g.sync.handle(m.from, m.d);
					break;
				case "join":
					arrive(m.p);
					break;
				case "leave":
					rp = byId(m.id);
					if (rp) players.splice(players.indexOf(rp), 1);
					if (trade && trade.partner == rp) endTrade(rp.name + " left.");
					break;
				case "move":
					rp = byId(m.id);
					if (rp) {
						if (m.far) {
							// a friend out of sight: just keep their spot up to date
							rp.x = rp.tx = m.x; rp.y = rp.ty = m.y;
							rp.far = true;
						} else {
							if (rp.far) { rp.x = m.x; rp.y = m.y; }
							rp.far = false;
							rp.moveTo(m.x, m.y);
							if (!rp.moving) rp.facingLeft = m.f == 1;
						}
					}
					break;
				case "banner":
					g.showBanner(m.text, m.color || 0xffd75e, 4);
					g.msg(m.msg || m.text, m.color || 0xffd75e);
					Sfx.play("portal");
					break;
				case "quests":
					g.questsArrived(m.q);
					break;
				case "questDone":
					g.questClaimed(m);
					break;
				case "questComplete":
					g.questComplete(m.text);
					break;
				case "records":
					g.recordsArrived(m.r);
					break;
				case "far":
					rp = byId(m.id);
					if (rp) rp.far = true;
					break;
				case "tppos":
					g.teleportArrive(m.x, m.y, m.name);
					break;
				case "fx":
					rp = byId(m.id);
					if (rp && g.shown(rp)) {
						rp.attacking = 0.3;
						g.abil.show(String(m.k), Number(m.x), Number(m.y), Number(m.tx), Number(m.ty), Number(m.n), false);
					}
					break;
				case "shoot":
					rp = byId(m.id);
					if (rp) {
						rp.attacking = 0.3;
						g.botShoot(rp, m.ang, true);
					}
					break;
				case "profile":
					rp = known[m.id];
					if (rp) rp.profile = m.profile;
					break;
				case "chat":
					if (m.ch) g.channelSay(m.name, m.text, m.ch);
					else if ((rp = byId(m.id))) g.netSay(rp, m.text);
					break;
				case "msg":
					g.msg(m.text, m.color || 0xff8080);
					break;
				case "kicked":
					g.msg(m.msg, 0xff8080);
					retries = 10;
					break;
				case "pong":
					if (m.at != undefined) latency = getTimer() - int(m.at);
					break;

				// trading
				case "tradeReq":
					rp = byId(m.from);
					if (rp) g.tradeRequested(rp);
					break;
				case "tradeStart":
					rp = byId(m["with"]);
					if (!rp) { Online.send({t: "tradeCancel"}); break; }
					var theirs:Array = m.inv || [];
					while (theirs.length < 8) theirs.push(null);
					trade = new TradeSession(rp, g.player.inv, theirs);
					theirOffers = 0;
					sentVersion = trade.version;
					sentAccept = false;
					g.openTrade(trade);
					if (m.sendInv) Online.send({t: "tradeInv", inv: g.player.inv});
					break;
				case "tradeOffer":
					if (!trade) break;
					trade.asked = m.want || [];
					theirOffers = int(m.n);
					trade.setTheirs(m.sel || []);
					sentVersion = trade.version;
					sentAccept = false;
					if (trade.onChange != null) trade.onChange();
					break;
				case "tradeAccept":
					if (trade) trade.setTheirAccept(true);
					break;
				case "realms":
					g.realmsUpdated(m.list);
					break;
				case "shopDone":
				case "shopFail":
					g.shopResult(m);
					break;
				case "tradeDone":
					if (!trade) break;
					if (m.inv) {
						// the server did the swap on its copy: take its result
						var inv:Array = g.player.inv;
						for (var ii:int = 0; ii < inv.length; ii++) inv[ii] = ii < m.inv.length ? m.inv[ii] : null;
						Save.data.tradeSeq = m.seq;
						trade.closed = true;
					} else trade.execute();
					trade = null;
					g.tradeEnded("Trade successful!", true);
					break;
				case "tradeCancel":
					if (trade) endTrade(m.msg);
					break;

				// party
				case "party":
					partyInfo = m.members || [];
					party.length = 0;
					for each (var pm:Object in partyInfo) if (pm.id != myId) party.push(meet(pm));
					g.socialChanged();
					break;
				case "partyInvite":
					var from:int = m.from;
					g.askPopup(m.name + " invited you to their party.", 0x7fd8ff,
						function():void { Online.send({t: "partyAns", from: from, yes: true}); },
						function():void { Online.send({t: "partyAns", from: from, yes: false}); });
					break;

				// guild
				case "guild":
					myGuild = m.guild;
					g.socialChanged();
					break;
				case "guildInvite":
					var gfrom:int = m.from;
					g.askPopup(m.name + " invited you to join the guild " + m.guild + ".", 0x80ff80,
						function():void { Online.send({t: "guildAns", from: gfrom, yes: true}); },
						function():void { Online.send({t: "guildAns", from: gfrom, yes: false}); });
					break;
				case "guildCreated":
					var cb:Function = guildDone;
					guildDone = null;
					if (cb != null) cb(m.err || null);
					break;
			}
		}

		// ------------------------------------------------------------ trading
		override public function requestTrade(p:RemotePlayer):void {
			syncForTrade();
			Online.send({t: "tradeReq", to: int(p.id)});
			g.msg("You sent a trade request to " + p.name + ".", 0xc8a0ff);
		}

		override public function answerTrade(p:RemotePlayer, yes:Boolean):void {
			if (yes) syncForTrade();
			Online.send({t: "tradeAns", to: int(p.id), yes: yes, inv: yes ? g.player.inv : null});
		}

		/** How many offers the partner has made (an accept is for the latest one). */
		private var theirOffers:int = 0;

		override public function tradeChanged():void {
			if (!trade) return;
			if (trade.version != sentVersion) {
				sentVersion = trade.version;
				sentAccept = false;
				Online.send({t: "tradeOffer", sel: trade.mySel, want: trade.wanted});
			}
			if (trade.myAccept && !sentAccept) {
				sentAccept = true;
				Online.send({t: "tradeAccept", seen: theirOffers});
			}
		}

		override public function cancelTrade():void {
			if (!trade) return;
			Online.send({t: "tradeCancel"});
			endTrade("Trade cancelled.");
		}

		private function endTrade(text:String):void {
			if (trade) trade.closed = true;
			trade = null;
			g.tradeEnded(text);
		}

		// ------------------------------------------------------------ party
		override public function inviteParty(p:RemotePlayer):void {
			if (party.length + 1 >= PARTY_MAX) { g.msg("Your party is full (" + PARTY_MAX + " players max).", 0xff8080); return; }
			Online.send({t: "partyInvite", to: int(p.id)});
		}
		override public function leaveParty():void { Online.send({t: "partyLeave"}); }
		override public function kickParty(p:RemotePlayer):void { Online.send({t: "partyKick", name: p.name}); }
		override public function partyChat(text:String):void { Online.send({t: "pchat", text: text}); }

		// ------------------------------------------------------------ guild
		override public function get guild():Object { return myGuild; }

		override public function createGuild(name:String, done:Function):void {
			guildDone = done;
			Online.send({t: "guildCreate", name: name});
		}

		override public function inviteGuild(p:RemotePlayer):void { Online.send({t: "guildInvite", to: int(p.id)}); }
		override public function leaveGuild():void { Online.send({t: "guildLeave"}); }
		override public function kickGuild(name:String):void { Online.send({t: "guildKick", name: name}); }
		override public function setRank(name:String, rank:int):void { Online.send({t: "guildRank", name: name, rank: rank}); }
		override public function guildChat(text:String):void { Online.send({t: "gchat", text: text}); }

		override public function guildStatus(name:String):String {
			if (myGuild) for each (var m:Object in myGuild.members) if (m.name == name) {
				if (!m.online) return "offline";
				return m.world == worldKey ? "here" : "online";
			}
			return "offline";
		}

		override public function worldOf(name:String):String {
			name = name.toLowerCase();
			for each (var pm:Object in partyInfo) if (String(pm.name).toLowerCase() == name) return pm.world;
			if (myGuild) for each (var m:Object in myGuild.members) if (String(m.name).toLowerCase() == name && m.online) return m.world;
			return null;
		}


	}
}
