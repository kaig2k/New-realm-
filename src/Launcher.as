package {
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	import realm.ServerConfig;

	/**
	 * The Eldmere launcher: the one file players keep. Every time it opens it
	 * downloads the latest game from the server (http://server/NewRealm.swf)
	 * and starts it, so an update on the server reaches everyone by itself.
	 *
	 * Build it with the server's address baked in, like the game:
	 *   build.sh play.example.com:2050 launcher
	 */
	[SWF(width="1100", height="640", frameRate="60", backgroundColor="#0a0612")]
	public class Launcher extends Sprite {
		private var server:String;
		private var ui:Sprite = new Sprite();
		private var status:TextField;
		private var bar:Shape = new Shape();
		private var retryBtn:Sprite;
		private var retryTimer:Timer;
		private var loader:URLLoader;
		private var game:Loader;

		public function Launcher() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			stage.align = "";
			stage.frameRate = 60;
			stage.quality = StageQuality.HIGH;
			server = ServerConfig.HOME || String(loaderInfo.parameters.server || "") || "localhost:2050";
			buildUi();
			download();
		}

		private function text(size:int, color:uint, bold:Boolean):TextField {
			var tf:TextField = new TextField();
			tf.defaultTextFormat = new TextFormat("_sans", size, color, bold, null, null, null, null, "center");
			tf.width = 1100;
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.autoSize = TextFieldAutoSize.CENTER;
			return tf;
		}

		private function buildUi():void {
			addChild(ui);
			var title:TextField = text(84, 0xffd75e, true);
			title.text = "ELDMERE";
			title.y = 190;
			title.filters = [new GlowFilter(0x2a1200, 1, 5, 5, 8), new GlowFilter(0xffa020, 0.45, 30, 30, 1.4)];
			ui.addChild(title);
			status = text(17, 0xe8e0c8, true);
			status.y = 340;
			ui.addChild(status);
			bar.x = 350; bar.y = 380;
			ui.addChild(bar);
			retryBtn = new Sprite();
			retryBtn.graphics.lineStyle(2, 0x4a2400);
			retryBtn.graphics.beginFill(0xf0b428);
			retryBtn.graphics.drawRoundRect(0, 0, 200, 46, 12, 12);
			retryBtn.graphics.endFill();
			var rt:TextField = text(20, 0x3a1c00, true);
			rt.autoSize = TextFieldAutoSize.NONE;
			rt.width = 200;
			rt.height = 30;
			rt.text = "Try again";
			rt.y = 10;
			retryBtn.addChild(rt);
			retryBtn.x = 450; retryBtn.y = 410;
			retryBtn.buttonMode = true;
			retryBtn.mouseChildren = false;
			retryBtn.visible = false;
			retryBtn.addEventListener(MouseEvent.CLICK, function(ev:MouseEvent):void { download(); });
			ui.addChild(retryBtn);
		}

		private function drawBar(frac:Number):void {
			bar.graphics.clear();
			bar.graphics.lineStyle(2, 0x6a5020);
			bar.graphics.beginFill(0x1a1208);
			bar.graphics.drawRoundRect(0, 0, 400, 14, 8, 8);
			bar.graphics.endFill();
			bar.graphics.lineStyle();
			bar.graphics.beginFill(0xffc23a);
			bar.graphics.drawRoundRect(2, 2, Math.max(0, Math.min(1, frac)) * 396, 10, 6, 6);
			bar.graphics.endFill();
		}

		/** Fetches the latest game from the server. */
		private function download():void {
			if (retryTimer) { retryTimer.stop(); retryTimer = null; }
			retryBtn.visible = false;
			bar.visible = true;
			drawBar(0);
			status.text = "Loading the latest version of Eldmere...";
			var host:String = server.indexOf(":") > 0 ? server : server + ":2050";
			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(ProgressEvent.PROGRESS, function(ev:ProgressEvent):void {
				if (ev.bytesTotal > 0) drawBar(ev.bytesLoaded / ev.bytesTotal);
			});
			loader.addEventListener(Event.COMPLETE, downloaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, failed);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, failed);
			try {
				// the time stops anything in between from handing back an old copy
				loader.load(new URLRequest("http://" + host + "/NewRealm.swf?t=" + new Date().time + getTimer()));
			} catch (err:Error) {
				failed(null);
			}
		}

		private function failed(e:Event):void {
			bar.visible = false;
			status.text = "Can't reach the Eldmere server right now. It may be restarting for an update.\nTrying again in 10 seconds...";
			retryBtn.visible = true;
			retryTimer = new Timer(10000, 1);
			retryTimer.addEventListener(TimerEvent.TIMER, function(ev:TimerEvent):void { download(); });
			retryTimer.start();
		}

		/** Starts the downloaded game in place of the launcher. */
		private function downloaded(e:Event):void {
			var bytes:ByteArray = ByteArray(loader.data);
			if (!bytes || bytes.length < 1000) { failed(null); return; }
			drawBar(1);
			status.text = "Starting...";
			// its own class space, so the game's classes never mix with the launcher's
			var ctx:LoaderContext = new LoaderContext(false, new ApplicationDomain());
			try { ctx["allowCodeImport"] = true; } catch (err:Error) {}
			try { ctx["allowLoadBytesCodeExecution"] = true; } catch (err:Error) {}
			try { ctx["parameters"] = {server: server}; } catch (err:Error) {}
			game = new Loader();
			game.contentLoaderInfo.addEventListener(Event.INIT, function(ev:Event):void {
				try { Object(game.content).useServer(server); } catch (err:Error) {}
			});
			game.contentLoaderInfo.addEventListener(Event.COMPLETE, function(ev:Event):void {
				removeChild(ui);
			});
			game.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, failed);
			addChild(game);
			try {
				game.loadBytes(bytes, ctx);
			} catch (err:Error) {
				status.text = "Couldn't start the game: " + err.message;
			}
		}
	}
}
