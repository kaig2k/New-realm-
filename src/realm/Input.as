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

		public function Input(stage:Stage) {
			this.stage = stage;
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.DEACTIVATE, onDeactivate);
		}

		public function dispose():void {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(Event.DEACTIVATE, onDeactivate);
		}

		public function isDown(code:uint):Boolean { return down[code] == true; }
		public function pressed(code:uint):Boolean { return hit[code] == true; }
		public function get mx():Number { return stage.mouseX; }
		public function get my():Number { return stage.mouseY; }

		public function endFrame():void { hit = {}; }

		private function onKeyDown(e:KeyboardEvent):void {
			if (!down[e.keyCode]) hit[e.keyCode] = true;
			down[e.keyCode] = true;
			shift = e.shiftKey;
		}

		private function onKeyUp(e:KeyboardEvent):void {
			down[e.keyCode] = false;
			shift = e.shiftKey;
		}

		private function onMouseDown(e:MouseEvent):void { mouseDown = true; shift = e.shiftKey; }
		private function onMouseUp(e:MouseEvent):void { mouseDown = false; }

		private function onDeactivate(e:Event):void {
			down = {};
			mouseDown = false;
		}
	}
}
