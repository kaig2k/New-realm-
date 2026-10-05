package realm {
	import flash.display.BitmapData;
	import flash.utils.Dictionary;

	public class Projectile {
		public var x:Number, y:Number, vx:Number, vy:Number;
		public var life:Number;
		public var dmg:int;
		public var enemy:Boolean;
		public var r:Number;
		public var bd:BitmapData;
		public var pierce:Boolean;
		public var hits:Dictionary;
		public var effect:String;
		public var owner:String;

		public function Projectile(x:Number, y:Number, angle:Number, speed:Number, life:Number, dmg:int, enemy:Boolean,
				r:Number, bd:BitmapData, pierce:Boolean, owner:String, effect:String) {
			this.x = x;
			this.y = y;
			this.vx = Math.cos(angle) * speed;
			this.vy = Math.sin(angle) * speed;
			this.life = life;
			this.dmg = dmg;
			this.enemy = enemy;
			this.r = r;
			this.bd = bd;
			this.pierce = pierce;
			this.owner = owner;
			this.effect = effect;
			if (pierce) hits = new Dictionary(true);
		}
	}
}
