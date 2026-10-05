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

		public function Net(g:Game) {
			this.g = g;
		}

		/** You moved to another world (Nexus, a realm, a dungeon...). */
		public function enterWorld(w:World):void {}

		/** Called every frame. */
		public function update(dt:Number):void {}

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
