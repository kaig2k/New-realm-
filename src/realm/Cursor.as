package realm {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.ui.Mouse;
	import flash.utils.getTimer;

	/**
	 * The game's own mouse cursor, drawn above everything: a crosshair over the
	 * game world (red over a monster, tightening while you fire) and a pointer
	 * everywhere else. Can be turned off in Menu > Settings.
	 */
	public class Cursor extends Sprite {
		public static const ARROW:int = 0, AIM:int = 1, AIM_FOE:int = 2;
		/** Set by the running game: returns ARROW, AIM or AIM_FOE for the mouse right now. */
		public static var modeFn:Function = null;
		private static var inst:Cursor;

		private var arrow:Shape = new Shape();
		private var aim:Shape = new Shape();
		private var dot:Shape = new Shape();
		private var spread:Number = 1;
		private var foe:Number = 0;
		private var pulse:Number = 0;
		private var down:Boolean = false;
		private var hidden:Boolean = false;
		private var lastT:int = 0;

		public static function install(stage:Stage):void {
			if (inst) return;
			inst = new Cursor();
			stage.addChild(inst);
			stage.addEventListener(Event.ENTER_FRAME, inst.tick);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, inst.move);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, inst.press);
			stage.addEventListener(MouseEvent.MOUSE_UP, inst.release);
			stage.addEventListener(Event.MOUSE_LEAVE, inst.leave);
		}

		/** A shot or hit: the crosshair kicks out a little. */
		public static function kick(amount:Number = 0.35):void {
			if (inst) inst.spread = Math.min(1.8, inst.spread + amount);
		}

		public function Cursor() {
			mouseEnabled = mouseChildren = false;
			drawArrow();
			addChild(arrow);
			addChild(aim);
			addChild(dot);
			dot.graphics.beginFill(0x000000, 0.6); dot.graphics.drawCircle(0, 0, 2.6);
			dot.graphics.beginFill(0xffffff); dot.graphics.drawCircle(0, 0, 1.4); dot.graphics.endFill();
			aim.filters = [new GlowFilter(0x000000, 0.8, 3, 3, 3)];
		}

		private function drawArrow():void {
			var g:* = arrow.graphics;
			var pts:Array = [[0, 0], [0, 17], [4.5, 13], [7.5, 20], [10.5, 18.8], [7.6, 12], [13, 12]];
			g.lineStyle(3, 0x1a1208, 1, true);
			g.moveTo(pts[0][0], pts[0][1]);
			for (var i:int = 1; i < pts.length; i++) g.lineTo(pts[i][0], pts[i][1]);
			g.lineTo(0, 0);
			g.lineStyle(1.2, 0xffd75e, 1, true);
			g.beginFill(0xfff4d6);
			g.moveTo(pts[0][0], pts[0][1]);
			for (i = 1; i < pts.length; i++) g.lineTo(pts[i][0], pts[i][1]);
			g.lineTo(0, 0);
			g.endFill();
			// a little shine down the edge
			g.lineStyle(1, 0xffffff, 0.9);
			g.moveTo(1.6, 3); g.lineTo(1.6, 12);
			arrow.filters = [new GlowFilter(0x000000, 0.45, 4, 4, 1.5)];
		}

		private function move(e:MouseEvent):void {
			x = stage.mouseX; y = stage.mouseY;
			if (hidden) { visible = true; hidden = false; }
			e.updateAfterEvent();
		}

		private function press(e:MouseEvent):void { down = true; pulse = 1; }
		private function release(e:MouseEvent):void { down = false; }
		private function leave(e:Event):void { visible = false; hidden = true; }

		private function tick(e:Event):void {
			var now:int = getTimer();
			var dt:Number = Math.min(0.05, (now - lastT) / 1000);
			lastT = now;
			// stay on top of whatever screen was just added
			if (parent && parent.getChildIndex(this) != parent.numChildren - 1) parent.setChildIndex(this, parent.numChildren - 1);
			if (!Game.opt("cursor")) {
				if (visible) { visible = false; Mouse.show(); }
				return;
			}
			if (!hidden) visible = true;
			Mouse.hide();
			x = stage.mouseX; y = stage.mouseY;
			var mode:int = ARROW;
			if (modeFn != null) {
				try { mode = int(modeFn()); } catch (err:Error) { mode = ARROW; }
			}
			arrow.visible = mode == ARROW;
			aim.visible = dot.visible = mode != ARROW;
			if (mode == ARROW) return;
			// firing pulls the ring in; kicks push it out; both settle back
			var target:Number = down ? 0.72 : 1;
			spread += (target - spread) * Math.min(1, dt * 14);
			foe += ((mode == AIM_FOE ? 1 : 0) - foe) * Math.min(1, dt * 16);
			pulse = Math.max(0, pulse - dt * 4);
			drawAim();
		}

		private function drawAim():void {
			var g:* = aim.graphics;
			g.clear();
			var col:uint = lerp(0xf4f4f4, 0xff5a4a, foe);
			var r:Number = 9 * spread;
			// ring
			g.lineStyle(1.6, col, 0.95);
			g.drawCircle(0, 0, r);
			// four ticks that close in on the target
			var gap:Number = r + 2, len:Number = 6 + foe * 2;
			g.lineStyle(2, col, 1);
			g.moveTo(-gap - len, 0); g.lineTo(-gap, 0);
			g.moveTo(gap, 0); g.lineTo(gap + len, 0);
			g.moveTo(0, -gap - len); g.lineTo(0, -gap);
			g.moveTo(0, gap); g.lineTo(0, gap + len);
			// over a monster: corner brackets lock on
			if (foe > 0.05) {
				var b:Number = r + 6 - foe * 2, c:Number = 4;
				g.lineStyle(1.6, col, foe);
				for (var sx:int = -1; sx <= 1; sx += 2) for (var sy:int = -1; sy <= 1; sy += 2) {
					g.moveTo(sx * b, sy * (b - c)); g.lineTo(sx * b, sy * b); g.lineTo(sx * (b - c), sy * b);
				}
			}
			// click ripple
			if (pulse > 0) {
				g.lineStyle(1.4, col, pulse * 0.7);
				g.drawCircle(0, 0, r + (1 - pulse) * 10);
			}
		}

		private static function lerp(a:uint, b:uint, t:Number):uint {
			var r:int = ((a >> 16) & 255) + (((b >> 16) & 255) - ((a >> 16) & 255)) * t;
			var gg:int = ((a >> 8) & 255) + (((b >> 8) & 255) - ((a >> 8) & 255)) * t;
			var bb:int = (a & 255) + ((b & 255) - (a & 255)) * t;
			return (r << 16) | (gg << 8) | bb;
		}
	}
}
