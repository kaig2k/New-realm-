package realm {
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;

	/** Shared look & feel: fonts, text fields, panels and buttons. */
	public class Ui {
		public static const W:int = 1100;
		/** Seconds a frame takes at the frame rate the game runs at (60, or more with V-Sync off: Game.applyVsync). */
		public static var FRAME:Number = 1 / 60;
		public static const H:int = 640;

		public static const PANEL:uint = 0x363636;
		public static const PANEL_DARK:uint = 0x232323;
		public static const PANEL_EDGE:uint = 0x4c4c4c;
		public static const GOLD:uint = 0xffd75e;
		public static const NPC:uint = 0xff9a2e;

		/** Text on the game: a dark rim to read on anything, and a soft shadow under it so it stands off the ground. */
		public static const OUTLINE:Array = [new GlowFilter(0x07040c, 1, 2.5, 2.5, 5), new DropShadowFilter(2, 90, 0x000000, 0.55, 3, 3, 1)];
		public static const OUTLINE_SOFT:Array = [new GlowFilter(0x000000, 0.8, 3, 3, 3)];

		[Embed(source="../../assets/fonts/RealmFonts.swf", mimeType="application/octet-stream")]
		private static const FontSwf:Class;

		public static var embedded:Boolean = false;
		private static var fontLoader:Loader;

		/** Loads the embedded font library, then calls done(). Falls back to device fonts. */
		public static function loadFonts(done:Function):void {
			// the game must start whatever happens to the font (some players' Flash/AIR,
			// or the launcher's sandbox, never answer): give up after 3 seconds
			var called:Boolean = false;
			var guard:Timer = new Timer(3000, 1);
			var finish:Function = function(e:* = null):void {
				if (called) return;
				called = true;
				guard.stop();
				try { for each (var f:Font in Font.enumerateFonts(false)) if (f.fontName == "Realm") embedded = true; } catch (err2:Error) {}
				done();
			};
			guard.addEventListener(TimerEvent.TIMER, finish);
			guard.start();
			try {
				fontLoader = new Loader();
				fontLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, finish);
				fontLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, finish);
				fontLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, finish);
				try { fontLoader.uncaughtErrorEvents.addEventListener("uncaughtError", finish); } catch (err3:Error) {}
				var ctx:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
				try { ctx["allowCodeImport"] = true; } catch (e:Error) {}
				fontLoader.loadBytes(ByteArray(new FontSwf()), ctx);
			} catch (err:Error) {
				finish();
			}
		}

		public static function format(size:int, color:uint, bold:Boolean = false, align:String = "left"):TextFormat {
			var fmt:TextFormat = new TextFormat(embedded ? "Realm" : "_sans", size, color, bold);
			fmt.align = align;
			return fmt;
		}

		public static function text(size:int, color:uint, bold:Boolean = false, align:String = "left", width:Number = 0, outline:Boolean = false):TextField {
			var tf:TextField = new TextField();
			tf.embedFonts = embedded;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.defaultTextFormat = format(size, color, bold, align);
			tf.selectable = false;
			tf.mouseEnabled = false;
			if (width > 0) {
				tf.width = width;
				tf.wordWrap = true;
				tf.multiline = true;
				tf.autoSize = align == "center" ? TextFieldAutoSize.CENTER : align == "right" ? TextFieldAutoSize.RIGHT : TextFieldAutoSize.LEFT;
			} else {
				tf.autoSize = TextFieldAutoSize.LEFT;
			}
			if (outline) tf.filters = OUTLINE;
			return tf;
		}

		/** A window's heading: lit words (BannerFx.lit) centred in w, with gold-tipped rules either side. */
		public static function heading(words:String, size:int, color:uint, w:Number, withRules:Boolean = true):Sprite {
			var sp:Sprite = new Sprite();
			sp.mouseEnabled = sp.mouseChildren = false;
			var b:flash.display.Bitmap = BannerFx.lit(words, size, color, 0.7);
			b.x = int((w - b.width) / 2);
			sp.addChild(b);
			var len:Number = Math.min(70, (w - b.width) / 2 - 22);
			if (withRules && len > 14) {
				var r:Shape = new Shape();
				BannerFx.rules(r.graphics, b.width, len, color);
				r.x = w / 2; r.y = int(b.height / 2);
				sp.addChildAt(r, 0);
			}
			return sp;
		}

		/**
		 * A rounded panel in the HUD's look: dark glass lit from above, a thin rim, a faint sheen along the
		 * top. Plain greys (the old look most windows still ask for) become the HUD's violet; a panel asked
		 * for in a colour keeps it.
		 */
		public static function panel(g:*, x:Number, y:Number, w:Number, h:Number, fill:uint = PANEL_DARK, edge:uint = PANEL_EDGE, alpha:Number = 1):void {
			var f:uint = violet(fill), e:uint = edgeOf(edge);
			var m:Matrix = new Matrix();
			m.createGradientBox(w, h, Math.PI / 2, x, y);
			g.lineStyle(1, 0x05030a, alpha);
			g.beginGradientFill("linear", [Sprites.tint(f, 0.08), Sprites.shade(f, 0.72)], [alpha, alpha], [0, 255], m);
			g.drawRoundRect(x, y, w, h, 12, 12);
			g.endFill();
			g.lineStyle(1, e, 0.9 * alpha);
			g.drawRoundRect(x + 1, y + 1, w - 2, h - 2, 10, 10);
			g.lineStyle(1, 0xffffff, 0.07 * alpha);
			g.moveTo(x + 8, y + 2.5); g.lineTo(x + w - 8, y + 2.5);
			g.lineStyle();
		}

		/** A plain grey turned the HUD's violet of the same depth; anything with a colour of its own kept. */
		private static function violet(c:uint):uint {
			var r:int = (c >> 16) & 255, gr:int = (c >> 8) & 255, b:int = c & 255;
			if (Math.max(r, gr, b) - Math.min(r, gr, b) > 14) return c;
			var l:Number = (r + gr + b) / 3 / 0x2a;
			return (Math.min(255, int(0x22 * l)) << 16) | (Math.min(255, int(0x1a * l)) << 8) | Math.min(255, int(0x38 * l));
		}
		/** Grey rims become the HUD's violet edge, white ones (hover) its bright gold. */
		private static function edgeOf(c:uint):uint {
			var r:int = (c >> 16) & 255, gr:int = (c >> 8) & 255, b:int = c & 255;
			if (Math.max(r, gr, b) - Math.min(r, gr, b) > 14) return c;
			return r > 0xd0 ? Hud.GOLD_HI : Hud.EDGE;
		}

		/** A one-line text box. */
		public static function input(w:int, value:String, maxChars:int = 20, size:int = 14):TextField {
			var f:TextField = text(size, 0xffffff, true, "left", w);
			f.autoSize = "none";
			f.width = w;
			f.height = size + 10;
			f.type = "input";
			f.multiline = false;
			f.wordWrap = false;
			f.selectable = true;
			f.mouseEnabled = true;
			f.background = true;
			f.backgroundColor = 0x141418;
			f.border = true;
			f.borderColor = 0x5a5a6a;
			f.maxChars = maxChars;
			f.text = value || "";
			return f;
		}

		public static function button(label:String, w:int, h:int, onClick:Function, size:int = 18):Sprite {
			var b:Sprite = new Sprite();
			var bg:Shape = new Shape();
			b.addChild(bg);
			var tf:TextField = text(size, 0xffffff, true, "center", w, true);
			tf.text = label;
			tf.y = (h - tf.height) / 2;
			b.addChild(tf);
			b.buttonMode = true;
			b.mouseChildren = false;
			// the HUD's buttons: violet lit from above, a gold rim (brighter, and the face lifted, under the mouse)
			var r:Number = Math.min(h, 12);
			var draw:Function = function(hover:Boolean):void {
				var g:* = bg.graphics;
				g.clear();
				var m:Matrix = new Matrix();
				m.createGradientBox(w, h, Math.PI / 2);
				g.lineStyle(1, 0x05030a);
				g.beginGradientFill("linear", hover ? [0x4a3878, 0x221a38] : [0x2e2448, 0x140f22], [1, 1], [0, 255], m);
				g.drawRoundRect(0, 0, w, h, r, r);
				g.endFill();
				g.lineStyle(1, hover ? Hud.GOLD_HI : Hud.GOLD, hover ? 1 : 0.85);
				g.drawRoundRect(1, 1, w - 2, h - 2, r - 2, r - 2);
				g.lineStyle(1, 0xffffff, hover ? 0.16 : 0.08);
				g.moveTo(r / 2 + 2, 2.5); g.lineTo(w - r / 2 - 2, 2.5);
				g.lineStyle();
			};
			draw(false);
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onClick(); });
			return b;
		}

		/** Horizontal slider for a 0..1 value; onChange(v) fires while dragging. */
		public static function slider(label:String, w:int, value:Number, onChange:Function):Sprite {
			var sp:Sprite = new Sprite();
			var tf:TextField = text(15, 0xffffff, true, "left", w, true);
			sp.addChild(tf);
			var track:Sprite = new Sprite();
			track.y = 26;
			track.buttonMode = true;
			sp.addChild(track);
			var draw:Function = function():void {
				tf.text = label + ": " + Math.round(value * 100) + "%";
				var g:* = track.graphics;
				g.clear();
				g.beginFill(0x000000, 0);
				g.drawRect(-8, -10, w + 16, 24);
				g.endFill();
				panel(g, 0, 0, w, 8, 0x1a1a1a, 0x6a6a6a);
				g.beginFill(GOLD);
				g.drawRoundRect(1, 1, Math.max(4, (w - 2) * value), 6, 6, 6);
				g.endFill();
				g.lineStyle(2, 0x000000);
				g.beginFill(0xffffff);
				g.drawCircle(w * value, 4, 8);
				g.endFill();
			};
			var setFrom:Function = function():void {
				value = Math.max(0, Math.min(1, track.mouseX / w));
				draw();
				onChange(value);
			};
			var move:Function = function(e:MouseEvent):void { setFrom(); };
			var up:Function = function(e:MouseEvent):void {
				sp.stage.removeEventListener(MouseEvent.MOUSE_MOVE, move);
				sp.stage.removeEventListener(MouseEvent.MOUSE_UP, up);
			};
			track.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
				setFrom();
				sp.stage.addEventListener(MouseEvent.MOUSE_MOVE, move);
				sp.stage.addEventListener(MouseEvent.MOUSE_UP, up);
			});
			draw();
			return sp;
		}

		/** Text from players (names, reports) made safe to show in an htmlText field. */
		public static function esc(s:*):String { return String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }

		public static function hex(c:uint):String {
			var s:String = c.toString(16);
			while (s.length < 6) s = "0" + s;
			return "#" + s;
		}

		public static function commas(n:int):String {
			var s:String = String(Math.abs(n));
			var out:String = "";
			while (s.length > 3) {
				out = "," + s.substr(s.length - 3) + out;
				s = s.substr(0, s.length - 3);
			}
			return (n < 0 ? "-" : "") + s + out;
		}
	}
}
