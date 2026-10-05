package realm {
	/**
	 * One trade between you and another player, RotMG-style: each side ticks the
	 * items it offers, any change un-ticks both Accepts, and Accept unlocks a
	 * moment after the last change so nobody can swap an item at the last second.
	 *
	 * The window drives "my" side; the connection (Net) drives "their" side and
	 * carries out the swap. You can also tick the other player's items to ask for
	 * them; that is only a request they see and may answer by offering them.
	 */
	public class TradeSession {
		public static const LOCK_TIME:Number = 1.5;

		public var partner:RemotePlayer;
		/** Your inventory (the live array) and theirs (a copy sent by the connection). */
		public var mine:Array;
		public var theirs:Array;
		public var mySel:Array = [];
		public var theirSel:Array = [];
		/** Their items you have asked for. */
		public var wanted:Array = [];
		/** Your items they have asked for. */
		public var asked:Array = [];
		public var myAccept:Boolean = false;
		public var theirAccept:Boolean = false;
		/** Seconds since anything changed. */
		public var sinceChange:Number = 0;
		/** Bumped on every change so the other side knows to re-check the offer. */
		public var version:int = 0;
		public var closed:Boolean = false;
		/** Called when the window needs redrawing. */
		public var onChange:Function;

		public function TradeSession(partner:RemotePlayer, mine:Array, theirs:Array) {
			this.partner = partner;
			this.mine = mine;
			this.theirs = theirs;
			for (var i:int = 0; i < mine.length; i++) mySel.push(false);
			for (i = 0; i < theirs.length; i++) { theirSel.push(false); wanted.push(false); }
		}

		public function update(dt:Number):void {
			sinceChange += dt;
		}

		public function get locked():Boolean { return sinceChange < LOCK_TIME; }

		private function changed():void {
			myAccept = theirAccept = false;
			sinceChange = 0;
			version++;
			if (onChange != null) onChange();
		}

		public function toggleMine(i:int):void {
			if (closed || !mine[i]) return;
			mySel[i] = !mySel[i];
			changed();
		}

		public function toggleWanted(i:int):void {
			if (closed || !theirs[i]) return;
			wanted[i] = !wanted[i];
			changed();
		}

		/** The other side changed what it offers. */
		public function setTheirs(sel:Array):void {
			var diff:Boolean = false;
			for (var i:int = 0; i < theirSel.length; i++) {
				var v:Boolean = sel[i] == true && theirs[i] != null;
				if (v != theirSel[i]) diff = true;
				theirSel[i] = v;
			}
			if (diff) changed();
		}

		public function setTheirAccept(v:Boolean):void {
			if (theirAccept == v) return;
			theirAccept = v;
			if (onChange != null) onChange();
		}

		/** Returns an error to show, or null when your Accept went through. */
		public function accept():String {
			if (closed) return "The trade is over.";
			if (locked) return "Wait a moment after a change before accepting.";
			var e:String = spaceError();
			if (e) return e;
			myAccept = true;
			if (onChange != null) onChange();
			return null;
		}

		public function get bothAccepted():Boolean { return myAccept && theirAccept; }

		public function count(sel:Array):int {
			var n:int = 0;
			for each (var b:Boolean in sel) if (b) n++;
			return n;
		}

		private static function empty(list:Array):int {
			var n:int = 0;
			for each (var it:Object in list) if (!it) n++;
			return n;
		}

		/** Both sides need room for what they receive. */
		public function spaceError():String {
			var give:int = count(mySel), get:int = count(theirSel);
			if (empty(mine) + give < get) return "You don't have enough inventory space.";
			if (empty(theirs) + get < give) return partner.name + " doesn't have enough inventory space.";
			return null;
		}

		public function myOffer():Array { return picked(mine, mySel); }
		public function theirOffer():Array { return picked(theirs, theirSel); }
		public function wantedItems():Array { return picked(theirs, wanted); }

		private static function picked(list:Array, sel:Array):Array {
			var out:Array = [];
			for (var i:int = 0; i < list.length; i++) if (sel[i] && list[i]) out.push(list[i]);
			return out;
		}

		/**
		 * Swaps the offered items between the two inventories (the connection calls
		 * this once both sides accepted; a server would do it and send the results).
		 */
		public function execute():void {
			var give:Array = myOffer(), get:Array = theirOffer();
			var i:int;
			for (i = 0; i < mine.length; i++) if (mySel[i]) mine[i] = null;
			for (i = 0; i < theirs.length; i++) if (theirSel[i]) theirs[i] = null;
			put(mine, get);
			put(theirs, give);
			closed = true;
		}

		private static function put(list:Array, items:Array):void {
			for each (var it:Object in items) {
				for (var i:int = 0; i < list.length; i++) {
					if (!list[i]) { list[i] = it; break; }
				}
			}
		}
	}
}
