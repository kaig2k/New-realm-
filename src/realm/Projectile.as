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

		public function Projectile(x:Number, y:Number, angle:Number, speed:Number, life:Number, dmg:int, enemy:Boolean,
				r:Number, frames:Vector.<BitmapData>, pierce:Boolean, owner:String, effect:String, spin:Boolean = false) {
			this.x = x;
			this.y = y;
			this.angle = angle;
			this.vx = Math.cos(angle) * speed;
			this.vy = Math.sin(angle) * speed;
			this.life = life;
			this.dmg = dmg;
			this.enemy = enemy;
			this.r = r;
			this.frames = frames;
			this.pierce = pierce;
			this.owner = owner;
			this.effect = effect;
			this.spin = spin;
			if (pierce) hits = new Dictionary(true);
		}

		public function frame(time:Number):BitmapData {
			return frames[spin ? int(time * 40) % Sprites.ROT_FRAMES : Sprites.frameFor(angle)];
		}
	}
}
