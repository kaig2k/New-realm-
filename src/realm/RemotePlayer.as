package realm {
	import flash.display.BitmapData;

	/**
	 * Another player in the same world. The game only ever reads these: their
	 * position and profile come from the connection (Net), which today is the
	 * local simulation (LocalNet) and later a game server. Movement is smoothed
	 * toward the last position the connection reported, the same way it will be
	 * for network updates.
	 */
	public class RemotePlayer {
		/** Unique id for the session (the server's player id later). */
		public var id:String;
		public var name:String;
		public var x:Number, y:Number;
		/** Last position reported by the connection; we glide toward it. */
		public var tx:Number, ty:Number;
		/**
		 * Public profile, the shape a server would send:
		 * {cls, skin, level, fame, maxed, stars, equip:[weapon, ability, armor, ring], inv:[...]}
		 * inv is only filled in for a trade partner.
		 */
		public var profile:Object;
		public var facingLeft:Boolean = false;
		public var moving:Boolean = false;
		public var attacking:Number = 0;
		/** Chat bubble above the head. */
		public var bubble:String = "";
		public var bubbleT:Number = 0;
		/** Set by the connection when the player leaves the world. */
		public var gone:Boolean = false;
		private var walkT:Number = 0;

		public function RemotePlayer(id:String, name:String, x:Number, y:Number, profile:Object) {
			this.id = id;
			this.name = name;
			this.x = tx = x;
			this.y = ty = y;
			this.profile = profile;
		}

		public function get cls():Object { return Data.CLASSES[profile.cls]; }
		public function get spriteId():String { return profile.skin || profile.cls; }

		public function moveTo(nx:Number, ny:Number):void {
			tx = nx;
			ty = ny;
		}

		public function say(text:String):void {
			bubble = text;
			bubbleT = 4 + text.length * 0.05;
		}

		public function update(dt:Number):void {
			var dx:Number = tx - x, dy:Number = ty - y;
			var d:Number = Math.sqrt(dx * dx + dy * dy);
			moving = d > 0.05;
			if (d > 6) { x = tx; y = ty; }
			else if (moving) {
				var step:Number = Math.min(d, Math.max(4.5, d * 6) * dt);
				x += dx / d * step;
				y += dy / d * step;
				if (Math.abs(dx) > 0.05 && attacking <= 0) facingLeft = dx < 0;
				walkT += dt;
			}
			if (attacking > 0) attacking -= dt;
			if (bubbleT > 0) bubbleT -= dt;
		}

		public function get sprite():BitmapData {
			var frame:int = attacking > 0 ? (int(attacking * 8) % 2 == 0 ? 2 : 0) : moving ? int(walkT * 6) % 2 : 0;
			return Sprites.get(spriteId, frame, facingLeft);
		}

		public function get equip():Array { return profile.equip; }
	}
}
