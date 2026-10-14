package realm {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	/** A clipped area whose `content` scrolls with the mouse wheel or by dragging its bar. */
	public class ScrollArea extends Sprite {
		public var content:Sprite = new Sprite();
		private var bar:Sprite = new Sprite();
		private var w:int, h:int;
		private var pos:Number = 0;

		public function ScrollArea(w:int, h:int) {
			this.w = w; this.h = h;
			var mask:Shape = new Shape();
			mask.graphics.beginFill(0);
			mask.graphics.drawRect(0, 0, w, h);
			mask.graphics.endFill();
			addChild(mask);
			content.mask = mask;
			addChild(content);
			// (the whole area takes the wheel, gaps included)
			graphics.beginFill(0, 0.001);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
			bar.x = w - 7;
			bar.buttonMode = true;
			addChild(bar);
			addEventListener(MouseEvent.MOUSE_WHEEL, function(e:MouseEvent):void { scrollTo(pos - e.delta * 36); e.stopPropagation(); });
			bar.addEventListener(MouseEvent.MOUSE_DOWN, barDown);
		}

		public function get scroll():Number { return pos; }

		/** Call after filling content (keeps the place if it can). */
		public function update(keep:Number = 0):void { scrollTo(keep); }

		public function scrollTo(y:Number):void {
			var most:Number = Math.max(0, content.height + 8 - h);
			pos = Math.max(0, Math.min(most, y));
			content.y = -pos;
			bar.graphics.clear();
			if (most <= 0) return;
			bar.graphics.beginFill(0xffffff, 0.08);
			bar.graphics.drawRoundRect(0, 0, 7, h, 6, 6);
			var th:Number = Math.max(28, h * h / (h + most));
			bar.graphics.beginFill(0xb9a9ff, 0.75);
			bar.graphics.drawRoundRect(0, (h - th) * pos / most, 7, th, 6, 6);
			bar.graphics.endFill();
		}

		private function barDown(e:MouseEvent):void {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, barMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, barUp);
			barMove(null);
			e.stopPropagation();
		}

		private function barMove(e:MouseEvent):void {
			var most:Number = Math.max(0, content.height + 8 - h);
			scrollTo(most * Math.max(0, Math.min(1, mouseY / h)));
		}

		private function barUp(e:MouseEvent):void {
			if (stage) { stage.removeEventListener(MouseEvent.MOUSE_MOVE, barMove); stage.removeEventListener(MouseEvent.MOUSE_UP, barUp); }
		}
	}
}
