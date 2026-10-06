package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;

	/** Slowly scrolling realm used behind the home and character screens. */
	public class Backdrop extends Sprite {
		private static var world:World;
		private static var camX:Number, camY:Number;

		private var bg:BitmapData;
		private var mtx:Matrix = new Matrix();

		public function Backdrop(darken:Number) {
			if (!world) {
				world = new World();
				camX = world.spawnX;
				camY = world.spawnY - 10;
			}
			bg = new BitmapData(Ui.W, Ui.H, false, 0);
			addChild(new Bitmap(bg));
			var shade:Shape = new Shape();
			shade.graphics.beginFill(0x000000, darken);
			shade.graphics.drawRect(0, 0, Ui.W, Ui.H);
			shade.graphics.endFill();
			addChild(shade);
			draw();
			addEventListener(Event.ENTER_FRAME, animate);
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void {
				removeEventListener(Event.ENTER_FRAME, animate);
				bg.dispose();
			});
		}

		private function draw():void {
			bg.lock();
			mtx.a = mtx.d = Game.TS / World.PX;
			mtx.tx = Math.round(Ui.W / 2 - camX * Game.TS);
			mtx.ty = Math.round(Ui.H / 2 - camY * Game.TS);
			world.drawGround(bg, mtx, camX, camY, Math.sqrt(Ui.W * Ui.W + Ui.H * Ui.H) / 2 / Game.TS + 1);
			bg.unlock();
		}

		private function animate(e:Event):void {
			camY -= 0.02;
			camX += 0.008;
			if (camY < 30) camY = world.spawnY - 10;
			draw();
		}
	}
}
