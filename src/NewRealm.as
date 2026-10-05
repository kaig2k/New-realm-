package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;

	import realm.DeathScreen;
	import realm.Game;
	import realm.Menu;

	[SWF(width="800", height="600", frameRate="60", backgroundColor="#000000")]
	public class NewRealm extends Sprite {
		private var screen:Sprite;

		public function NewRealm() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			stage.align = "";
			stage.frameRate = 60;
			showMenu();
		}

		private function setScreen(s:Sprite):void {
			if (screen) {
				if (screen is Game) Game(screen).destroy();
				removeChild(screen);
			}
			screen = s;
			addChild(s);
			stage.focus = stage;
		}

		private function showMenu():void {
			setScreen(new Menu(startGame));
		}

		private function startGame(clsId:String):void {
			setScreen(new Game(clsId, onDeath));
		}

		private function onDeath(info:Object):void {
			setScreen(new DeathScreen(info, showMenu));
		}
	}
}
