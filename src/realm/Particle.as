package realm {
	import flash.display.BitmapData;

	public class Particle {
		public var x:Number, y:Number, vx:Number, vy:Number, life:Number;
		public var bd:BitmapData;

		public function Particle(x:Number, y:Number, vx:Number, vy:Number, life:Number, bd:BitmapData) {
			this.x = x; this.y = y; this.vx = vx; this.vy = vy; this.life = life; this.bd = bd;
		}
	}
}
