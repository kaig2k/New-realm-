package realm {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class DeathScreen extends Sprite {
		private var onDone:Function;

		public function DeathScreen(info:Object, onDone:Function) {
			this.onDone = onDone;
			graphics.beginFill(0x0c0a10);
			graphics.drawRect(0, 0, 800, 600);
			graphics.endFill();

			var grave:Bitmap = new Bitmap(Sprites.hit(info.clsId));
			grave.scaleX = grave.scaleY = 2;
			grave.x = 400 - grave.width / 2;
			grave.y = 60;
			grave.alpha = 0.7;
			addChild(grave);

			var t:TextField = Ui.text(40, 0xff4040, true, "center", 800, true);
			t.text = "YOU DIED";
			t.y = 150;
			addChild(t);

			var mins:int = int(info.time / 60), secs:int = int(info.time % 60);
			var body:TextField = Ui.text(16, 0xdddddd, false, "center", 800, true);
			body.htmlText = "Your level " + info.level + " " + info.cls + " was killed by <font color='#ff8080'><b>" + info.killer + "</b></font>\n\n" +
				"Monsters slain: " + info.kills + "      Overlords slain: " + info.bosses + "\n" +
				"Time survived: " + mins + "m " + (secs < 10 ? "0" : "") + secs + "s";
			body.y = 215;
			addChild(body);

			var fame:TextField = Ui.text(28, 0xffa040, true, "center", 800, true);
			fame.htmlText = info.fame + " Fame" + (info.best ? "\n<font size='16' color='#ffd75e'>NEW PERSONAL BEST!</font>" : "");
			fame.y = 330;
			addChild(fame);

			var btn:Sprite = Ui.button("Return to Menu", 220, 44, finish);
			btn.x = 290;
			btn.y = 450;
			addChild(btn);

			addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void {
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			});
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void {
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
			});
		}

		private function onKey(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.ENTER) finish();
		}

		private function finish():void {
			var f:Function = onDone;
			onDone = null;
			if (f != null) f();
		}
	}
}
