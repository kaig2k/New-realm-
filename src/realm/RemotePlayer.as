package realm {
	import flash.display.BitmapData;
	import flash.utils.getTimer;

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
		/** Out of your sight: not drawn (party and guild members still show on the minimap). */
		public var far:Boolean = false;
		/** Their spot from the server's minimap update (out of sight, the map uses this). */
		public var mapX:Number = NaN, mapY:Number = NaN;
		/** Which way they're heading (radians, 0 = east), for their minimap arrow. */
		public var heading:Number = -Math.PI / 2;
		private var walkT:Number = 0;

		public function RemotePlayer(id:String, name:String, x:Number, y:Number, profile:Object) {
			this.id = id;
			this.name = name;
			this.x = tx = x;
			this.y = ty = y;
			this.profile = profile;
		}

		public function get cls():Object { return Data.CLASSES[profile.cls]; }
		public function get spriteId():String { return Sprites.dyed(profile.skin || profile.cls, profile.dye); }

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
			if (moving && d > 0.1) heading = Math.atan2(dy, dx);
			if (attacking > 0) attacking -= dt;
			if (bubbleT > 0) bubbleT -= dt;
		}

		/** The server's minimap update: their spot, and the way they've been going since the last one. */
		public function setMapPos(nx:Number, ny:Number):void {
			if (!isNaN(mapX)) {
				var dx:Number = nx - mapX, dy:Number = ny - mapY;
				if (dx * dx + dy * dy > 0.25) heading = Math.atan2(dy, dx);
			}
			mapX = nx; mapY = ny;
			if (far) { x = tx = nx; y = ty = ny; }
		}

		public function get sprite():BitmapData {
			var frame:int = attacking > 0 ? Sprites.anim(Sprites.ATTACK, int(attacking * 8) % 2)
				: moving ? Sprites.anim(Sprites.MOVE, int(walkT * 6) % 2)
				: Sprites.anim(Sprites.IDLE, int(getTimer() / 590) % 2);
			return Sprites.get(spriteId, frame, facingLeft);
		}

		public function get equip():Array { return profile.equip; }
	}
}
