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
			graphics.drawRect(0, 0, Ui.W, Ui.H);
			graphics.endFill();
			Ui.panel(graphics, Ui.W / 2 - 280, 40, 560, 520, 0x1e1e22, 0x4a4a4a);

			var grave:Bitmap = new Bitmap(Sprites.get("grave"));
			grave.scaleX = grave.scaleY = 2;
			grave.x = Ui.W / 2 - grave.width / 2;
			grave.y = 64;
			addChild(grave);

			var t:TextField = Ui.text(44, 0xe03030, true, "center", Ui.W, true);
			t.text = "You Died";
			t.y = 164;
			addChild(t);

			var mins:int = int(info.time / 60), secs:int = int(info.time % 60);
			var body:TextField = Ui.text(18, 0xdddddd, false, "center", Ui.W, true);
			body.htmlText = "<b>" + info.name + "</b>, a level " + info.level + " " + info.cls + ",\nwas killed by <font color='#ff9a2e'><b>" + info.killer + "</b></font>\n\n" +
				"Monsters slain: <b>" + info.kills + "</b>      Overlords slain: <b>" + info.bosses + "</b>\n" +
				"Time survived: <b>" + mins + "m " + (secs < 10 ? "0" : "") + secs + "s</b>";
			body.y = 230;
			addChild(body);

			var fameIcon:Bitmap = new Bitmap(Sprites.get("fame"));
			var fame:TextField = Ui.text(34, 0xff9a2e, true, "center", Ui.W, true);
			fame.text = Ui.commas(info.fame) + " Fame";
			fame.y = 372;
			addChild(fame);
			fameIcon.x = Ui.W / 2 - fame.textWidth / 2 - 40;
			fameIcon.y = 382;
			addChild(fameIcon);
			if (info.best) {
				var best:TextField = Ui.text(17, Ui.GOLD, true, "center", Ui.W, true);
				best.text = "New personal best!";
				best.y = 418;
				addChild(best);
			}

			var btn:Sprite = Ui.button("Return to Menu", 240, 46, finish);
			btn.x = Ui.W / 2 - 120;
			btn.y = 476;
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
