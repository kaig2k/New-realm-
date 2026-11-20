package {
	import flash.display.*;
	import flash.events.Event;
	import flash.geom.*;
	import realm.*;
	import flash.text.TextField;
	import flash.utils.getTimer;

	/**
	 * A patch of the realm drawn by the game's own code (ground, objects, monsters and a boss), to look over
	 * the realm's art without logging in. Flashvars: zone = 0 (beach) .. 4 (godlands), seed, boss (an id).
	 * Build: mxmlc -source-path=src -source-path+=tools/realmview tools/realmview/RealmView.as
	 */
	[SWF(width="960", height="640", backgroundColor="#000000")]
	public class RealmView extends Sprite {
		private var step:int = 0, w:World, canvas:BitmapData;
		private static const TS:int = 40;

		public function RealmView() { addEventListener(Event.ENTER_FRAME, tick); }

		private function tick(ev:Event):void {
			var p:Object = loaderInfo.parameters;
			if (step == 0) { Bosses.init(); step++; return; }
			if (step == 1) { w = new World("realm", "View", null, uint(p.seed || 1234)); step++; return; }
			removeEventListener(Event.ENTER_FRAME, tick);
			var zone:int = int(p.zone || 1);
			// a spot in the zone with some objects and no water underfoot
			var vx:Number = w.N / 2, vy:Number = w.N / 2, best:int = -1;
			for (var tries:int = 0; tries < 4000; tries++) {
				var x:int = int(Math.random() * w.N), y:int = int(Math.random() * w.N);
				if (w.zoneAt(x, y) != zone || !w.canStand(x + 0.5, y + 0.5, 0.4, true)) continue;
				var n:int = 0, mix:Object = {};
				for (var dy:int = -6; dy <= 6; dy++) for (var dx:int = -10; dx <= 10; dx++) {
					var i:int = (y + dy) * w.N + x + dx;
					if (i < 0 || i >= w.N * w.N) continue;
					if (w.objs[i]) n++;
					mix[w.tiles[i]] = 1;
				}
				var kinds:int = 0; for (var k:String in mix) kinds++;
				var score:int = Math.min(n, 14) + kinds * 4;
				if (score > best) { best = score; vx = x + 0.5; vy = y + 0.5; }
			}
			if (p.classic) w.px = World.PX;
			// (arena=1: lay the boss's set piece round it, as when a realm event appears)
			if (p.arena && Bosses.SETPIECES[String(p.boss || "ev_wrecker")]) {
				var bx:int = int(vx + 3), by:int = int(vy + 1.5);
				SetPieces.apply(w, SetPieces.plan(String(p.boss || "ev_wrecker"), w, bx, by));
			}
			canvas = new BitmapData(960, 640, false, 0);
			var mtx:Matrix = new Matrix();
			mtx.scale(TS / w.px, TS / w.px);
			mtx.translate(-vx * TS + 480, -vy * TS + 320);
			w.drawGround(canvas, mtx, vx, vy, 20);
			w.drawGround(canvas, mtx, vx, vy, 20);
			w.drawGround(canvas, mtx, vx, vy, 20);
			w.drawGround(canvas, mtx, vx, vy, 20);
			w.drawGround(canvas, mtx, vx, vy, 20);
			w.drawGround(canvas, mtx, vx, vy, 20);
			// things standing on it, back to front
			var list:Array = [];
			for (y = int(vy - 9); y <= int(vy + 9); y++) for (x = int(vx - 13); x <= int(vx + 13); x++) {
				var o:int = w.objs[y * w.N + x];
				if (o) list.push({y: y + 0.5, o: o, x: x});
			}
			var mobs:Array = String(p.mobs || ["snake,pirate,crab", "goblin,spider,bandit", "orc,skeleton,ogre", "minotaur,lich,golem", "djinn,medusa,beholder"][zone]).split(",");
			for (var m:int = 0; m < mobs.length * 2; m++) {
				var ex:Number = vx + (Math.random() - 0.5) * 18, ey:Number = vy + (Math.random() - 0.5) * 11;
				if (Data.ENEMIES[mobs[m % mobs.length]]) list.push({y: ey, e: new Enemy(mobs[m % mobs.length], ex, ey, zone), x: ex});
			}
			var bid:String = String(p.boss || "ev_wrecker");
			if (Data.ENEMIES[bid]) list.push({y: vy + 1.5, e: new Enemy(bid, vx + 3, vy + 1.5, zone), x: vx + 3});
			var hero:BitmapData = Sprites.get("wizard");
			list.push({y: vy, hero: true, x: vx});
			list.sortOn("y", Array.NUMERIC);
			var pt:Point = new Point();
			for each (var d:Object in list) {
				var bd:BitmapData = d.hero ? hero : d.e ? d.e.sprite : Sprites.get(World.OBJ_NAMES[d.o]);
				var sx:Number = (d.e || d.hero ? d.x : d.x + 0.5) * TS - vx * TS + 480, base:Number = d.y * TS - vy * TS + 320 + TS / 2;
				var sh:BitmapData = Sprites.shadow(TS);
				pt.x = int(sx - TS / 2); pt.y = int(base - sh.height * 0.7);
				canvas.copyPixels(sh, sh.rect, pt, null, null, true);
				pt.x = int(sx - bd.width / 2); pt.y = int(base - bd.height);
				canvas.copyPixels(bd, bd.rect, pt, null, null, true);
			}
			addChild(new Bitmap(canvas));
			if (p.time) {
				// how long a fresh chunk of ground takes to draw (the realm draws one a frame as you walk)
				var t0:int = getTimer(), n0:int = 0;
				for (var ci:int = 0; ci < 6; ci++) { w.drawGround(new BitmapData(64, 64), mtx, 40 + ci * 70, 40 + ci * 64, 1); n0++; }
				var tf:TextField = new TextField();
				tf.width = 400; tf.textColor = 0xffff00; tf.background = true; tf.backgroundColor = 0;
				tf.text = "ms per chunk: " + ((getTimer() - t0) / n0).toFixed(1);
				addChild(tf);
			}
		}
	}
}
