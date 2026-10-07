package realm {
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;

	public class Input {
		private var stage:Stage;
		private var down:Object = {};
		private var hit:Object = {};
		public var mouseDown:Boolean = false;
		public var shift:Boolean = false;
		/** A mouse button went down this frame. */
		public var clicked:Boolean = false;
		public var rightClicked:Boolean = false;
		/** Mouse wheel clicks this frame (positive = up). */
		public var wheel:Number = 0;

		public function Input(stage:Stage) {
			this.stage = stage;
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
			try { stage.addEventListener("rightMouseDown", onRightDown); } catch (e:Error) {}
			stage.addEventListener(Event.DEACTIVATE, onDeactivate);
		}

		public function dispose():void {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
			stage.removeEventListener("rightMouseDown", onRightDown);
			stage.removeEventListener(Event.DEACTIVATE, onDeactivate);
		}

		/** While typing in chat the game ignores keys. */
		public var blocked:Boolean = false;

		public function isDown(code:uint):Boolean { return !blocked && down[code] == true; }
		public function pressed(code:uint):Boolean { return !blocked && hit[code] == true; }
		public function get mx():Number { return stage.mouseX; }
		public function get my():Number { return stage.mouseY; }

		public function endFrame():void { hit = {}; clicked = rightClicked = false; wheel = 0; }

		/** Set by the Controls menu: the next key goes here instead of the game. */
		public var capture:Function = null;

		private function onKeyDown(e:KeyboardEvent):void {
			if (capture != null) {
				var fn:Function = capture;
				capture = null;
				fn(e.keyCode);
				return;
			}
			if (!down[e.keyCode]) hit[e.keyCode] = true;
			down[e.keyCode] = true;
			shift = e.shiftKey;
		}

		private function onKeyUp(e:KeyboardEvent):void {
			down[e.keyCode] = false;
			shift = e.shiftKey;
		}

		private function onMouseDown(e:MouseEvent):void { mouseDown = true; clicked = true; shift = e.shiftKey; }
		private function onWheel(e:MouseEvent):void { wheel += e.delta > 0 ? 1 : e.delta < 0 ? -1 : 0; }
		private function onRightDown(e:MouseEvent):void { rightClicked = true; }
		private function onMouseUp(e:MouseEvent):void { mouseDown = false; }

		private function onDeactivate(e:Event):void {
			down = {};
			mouseDown = false;
		}
	}
}
