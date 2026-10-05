package realm {
	/**
	 * The connection to the other players. Everything the game knows about other
	 * players comes through here, so a game server can be plugged in by writing a
	 * subclass that sends these calls over a socket and feeds the replies back
	 * through the same Game callbacks (netSay, tradeRequested, openTrade,
	 * tradeEnded). LocalNet is the offline version: it simulates the other players.
	 */
	public class Net {
		protected var g:Game;
		/** Other players in the world you are in. */
		public var players:Vector.<RemotePlayer> = new Vector.<RemotePlayer>();
		/** The trade in progress, if any. */
		public var trade:TradeSession;
		/** Your party (not counting you). */
		public var party:Vector.<RemotePlayer> = new Vector.<RemotePlayer>();

		public static const PARTY_MAX:int = 6;
		public static const GUILD_MAX:int = 27;
		public static const GUILD_COST:int = 1000;
		public static const RANKS:Array = ["Initiate", "Member", "Officer", "Leader", "Founder"];
		public static const OFFICER:int = 2, FOUNDER:int = 4;

		public function Net(g:Game) {
			this.g = g;
		}

		/** You moved to another world (Nexus, a realm, a dungeon...). */
		public function enterWorld(w:World):void {}

		/** Called every frame. */
		public function update(dt:Number):void {}

		/** True when connected to a real server. */
		public function get online():Boolean { return false; }

		/** Your server id (0 offline). */
		public function get myId():int { return 0; }

		/** Monster sync message to "host", "all" or a player id in your world (see WorldSync). */
		public function sendWorld(to:*, d:Object):void {}

		/** You fired your weapon (so others see your shots). */
		public function shoot(ang:Number):void {}

		/** World key ("nexus", "realm:...", "dg:...") a party or guild member is in, or null. */
		public function worldOf(name:String):String { return null; }

		/** A slash command the server handles (/report, moderation). */
		public function serverCommand(text:String):void {}

		/** A realm closed in your game (the server replaces it). */
		public function realmClosed(key:String):void {}

		/** You said something in chat. */
		public function chat(text:String):void {}

		/** Fetches a player's public profile (equipment, level, fame) for the inspect window. */
		public function inspect(p:RemotePlayer, done:Function):void { done(p.profile); }

		/** Ask another player to trade. */
		public function requestTrade(p:RemotePlayer):void {}

		/** Answer a trade request someone sent you. */
		public function answerTrade(p:RemotePlayer, yes:Boolean):void {}

		/** Your side of the trade changed (selection or Accept). */
		public function tradeChanged():void {}

		/** You closed the trade window. */
		public function cancelTrade():void {}

		// ---- party
		public function inviteParty(p:RemotePlayer):void {}
		public function leaveParty():void {}
		public function kickParty(p:RemotePlayer):void {}
		public function partyChat(text:String):void {}
		public function inParty(p:RemotePlayer):Boolean { return party.indexOf(p) >= 0; }

		// ---- guild
		/**
		 * Your guild: {name, myRank, members: [{name, cls, level, fame, rank}]}
		 * (members does not include you), or null.
		 */
		public function get guild():Object { return null; }
		/** Founds a guild; done(error) gets null when it worked. */
		public function createGuild(name:String, done:Function):void { done("Guilds need a server connection."); }
		public function inviteGuild(p:RemotePlayer):void {}
		public function leaveGuild():void {}
		public function kickGuild(name:String):void {}
		public function setRank(name:String, rank:int):void {}
		public function guildChat(text:String):void {}
		/** "here" (in your world), "online" or "offline". */
		public function guildStatus(name:String):String { return "offline"; }
		public function inGuild(p:RemotePlayer):Boolean {
			return guild != null && p.profile.guild == guild.name;
		}

		/** Party or guild: always shown, even with "Show players: Party & guild". */
		public function isFriend(p:RemotePlayer):Boolean { return inParty(p) || inGuild(p); }

		public function find(name:String):RemotePlayer {
			name = name.toLowerCase();
			var best:RemotePlayer;
			for each (var p:RemotePlayer in players) {
				var n:String = p.name.toLowerCase();
				if (n == name) return p;
				if (!best && n.indexOf(name) == 0) best = p;
			}
			return best;
		}
	}
}
