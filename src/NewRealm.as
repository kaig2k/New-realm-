package {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.display.StageQuality;
	import flash.events.Event;

	import realm.DeathScreen;
	import realm.Game;
	import realm.Menu;
	import realm.Accounts;
	import realm.TitleScreen;
	import realm.Online;
	import realm.Save;
	import realm.Ui;

	[SWF(width="1100", height="640", frameRate="60", backgroundColor="#000000")]
	public class NewRealm extends Sprite {
		private var screen:Sprite;
		/** Black overlay that fades out whenever the screen changes. */
		private var fade:Shape;

		public function NewRealm() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			stage.align = "";
			stage.frameRate = 60;
			stage.quality = StageQuality.HIGH;
			realm.Bosses.init();
			Ui.loadFonts(showTitle);
		}

		private function setScreen(s:Sprite):void {
			if (screen) {
				if (screen is Game) Game(screen).destroy();
				removeChild(screen);
			}
			screen = s;
			addChild(s);
			stage.focus = stage;
			if (!fade) {
				fade = new Shape();
				fade.graphics.beginFill(0x000000);
				fade.graphics.drawRect(0, 0, 1100, 640);
				fade.graphics.endFill();
				addEventListener(Event.ENTER_FRAME, fadeStep);
			}
			addChild(fade);
			fade.alpha = 1;
			fade.visible = true;
		}

		/** Home screen: PLAY (after logging in) leads to character select. */
		private function fadeStep(e:Event):void {
			if (!fade.visible) return;
			fade.alpha -= 1 / 60 / 0.35;
			if (fade.alpha <= 0) fade.visible = false;
		}

		private function showTitle():void {
			setScreen(new TitleScreen(showMenu, showCreator));
		}

		private function showMenu():void {
			// the game is online-only: without a connection, back to the title screen to log in
			if (!Online.connected) { showTitle(); return; }
			setScreen(new Menu(startGame, showTitle));
		}

		/** Creator tools: Map Builder, Sprite Editor and Boss Maker (with test fights). */
		private function showCreator(tab:String = "bosses"):void {
			setScreen(new realm.CreatorScreen(showTitle, testFight, tab));
		}

		/** A Boss Maker test fight: offline, on a throwaway save. */
		private function testFight(sb:Object):void {
			Save.beginSandbox();
			Game.sandbox = sb;
			var back:Function = function(info:Object = null):void {
				Game.sandbox = null;
				Save.endSandbox();
				showCreator("bosses");
			};
			var g:Game = new Game(sb.cls, "Tester", back, null);
			g.onQuit = back;
			setScreen(g);
		}

		private function startGame(clsId:String, name:String, saved:Object = null):void {
			var g:Game = new Game(clsId, name, onDeath, saved);
			g.onQuit = showMenu;
			setScreen(g);
		}

		private function onDeath(info:Object):void {
			setScreen(new DeathScreen(info, showMenu));
		}
	}
}
