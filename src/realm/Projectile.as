package realm {
	import flash.display.BitmapData;
	import flash.utils.Dictionary;

	public class Projectile {
		public var x:Number, y:Number, vx:Number, vy:Number;
		public var angle:Number;
		public var life:Number;
		public var dmg:int;
		public var enemy:Boolean;
		public var r:Number;
		public var frames:Vector.<BitmapData>;
		public var spin:Boolean;
		public var pierce:Boolean;
		public var hits:Dictionary;
		public var effect:String;
		public var owner:String;
		/** Colour of the faint trail behind player shots. */
		public var trailCol:uint = 0xffffff;
		/** Fired by another player: hurts monsters but gives you nothing. */
		public var bot:Boolean = false;
		/** False when the shooter is hidden by the "Party & guild" setting. */
		public var shown:Boolean = true;
		/** Another real player's shot: drawn, but it can't hit your monsters. */
		public var ghost:Boolean = false;
		/** Special flight: "wave" weaves side to side, "return" flies back halfway through. */
		public var motion:String;
		public var phase:Number = 0;
		public var age:Number = 0;
		public var life0:Number;
		public var bx:Number, by:Number;
		public var turned:Boolean = false;

		public function Projectile(x:Number, y:Number, angle:Number, speed:Number, life:Number, dmg:int, enemy:Boolean,
				r:Number, frames:Vector.<BitmapData>, pierce:Boolean, owner:String, effect:String, spin:Boolean = false) {
			this.x = x;
			this.y = y;
			this.angle = angle;
			this.vx = Math.cos(angle) * speed;
			this.vy = Math.sin(angle) * speed;
			this.life = life0 = life;
			bx = x; by = y;
			this.dmg = dmg;
			this.enemy = enemy;
			this.r = r;
			this.frames = frames;
			if (frames && frames.length) {
				var f:BitmapData = frames[0];
				var c:uint = f.getPixel32(f.width >> 1, f.height >> 1);
				if ((c >>> 24) > 0) trailCol = c & 0xffffff;
			}
			this.pierce = pierce;
			this.owner = owner;
			this.effect = effect;
			this.spin = spin;
			if (pierce) hits = new Dictionary(true);
		}

		/** Moves the shot one step. */
		public function move(dt:Number):void {
			age += dt;
			if (motion == "wave") {
				bx += vx * dt;
				by += vy * dt;
				var off:Number = Math.sin(age * 16 + phase) * 0.5;
				x = bx - Math.sin(angle) * off;
				y = by + Math.cos(angle) * off;
				return;
			}
			if (motion == "return" && !turned && life < life0 * 0.5) {
				turned = true;
				vx = -vx; vy = -vy;
				angle += Math.PI;
				if (hits) hits = new Dictionary(true);
			}
			x += vx * dt;
			y += vy * dt;
		}

		/** Sprite frame; `view` is the camera rotation so bullets point the right way on screen. */
		public function frame(time:Number, view:Number = 0):BitmapData {
			return frames[spin ? int(time * 40) % Sprites.ROT_FRAMES : Sprites.frameFor(angle - view)];
		}
	}
}
