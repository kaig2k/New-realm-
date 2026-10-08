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

		/** The Eldmere launcher hands over its server (also passed as the "server" parameter). */
		public function useServer(addr:String):void {
			if (addr) realm.ServerConfig.launched = addr;
		}

		/** The Eldmere launcher hands over a way to download and start the latest game (for updates). */
		public function setReloader(fn:Function):void { Online.reloader = fn; }

		/** A newer copy of the game is taking over: let go of the server, timers and the shared stage. */
		public function shutdown():void {
			Online.stopAll();
			realm.Cursor.uninstall();
			if (screen) {
				if (screen is Game) Game(screen).destroy();
				removeChild(screen);
				screen = null;
			}
		}

		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			try { useServer(String(loaderInfo.parameters.server || "")); } catch (err:Error) {}
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			stage.align = "";
			stage.frameRate = 60;
			stage.quality = StageQuality.HIGH;
			realm.Bosses.init();
			realm.Cursor.install(stage);
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

		/** The connection dropped (a server restart): from the menus, back to the title screen to wait for it. */
		private function connectionDropped():void {
			if (!screen || screen is Game || screen is TitleScreen) return;
			if (screen is realm.CreatorScreen) return;
			Online.dropped = true;
			showTitle();
		}

		private function showTitle():void {
			Online.onDropped = connectionDropped;
			setScreen(new TitleScreen(showMenu));
		}

		private function showMenu():void {
			// the game is online-only: without a connection, back to the title screen to log in
			if (!Online.connected) { showTitle(); return; }
			setScreen(new Menu(startGame, showTitle, showCreator));
		}

		/** Creator tools: Map Builder, Sprite Editor and Boss Maker (with test fights). */
		private function showCreator(tab:String = "bosses"):void {
			// admins only (the button is only shown to them)
			if (!Online.connected || !Online.welcome || !Online.welcome.admin) { showMenu(); return; }
			setScreen(new realm.CreatorScreen(showMenu, testFight, tab));
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
			// the connection dropped while on the menu: get it back first, so the game starts online
			if (!Online.connected && Online.address) {
				Online.connect(Online.address, function(err:String):void {
					if (err) { showTitle(); return; }
					startGame(clsId, name, saved);
				});
				return;
			}
			var g:Game = new Game(clsId, name, onDeath, saved);
			g.onQuit = showMenu;
			setScreen(g);
		}

		private function onDeath(info:Object):void {
			setScreen(new DeathScreen(info, showMenu));
		}
	}
}
