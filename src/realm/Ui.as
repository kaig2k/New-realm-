package realm {
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
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
		public static const H:int = 640;

		public static const PANEL:uint = 0x363636;
		public static const PANEL_DARK:uint = 0x232323;
		public static const PANEL_EDGE:uint = 0x4c4c4c;
		public static const GOLD:uint = 0xffd75e;
		public static const NPC:uint = 0xff9a2e;

		public static const OUTLINE:Array = [new GlowFilter(0x000000, 1, 2, 2, 6)];
		public static const OUTLINE_SOFT:Array = [new GlowFilter(0x000000, 0.8, 3, 3, 3)];

		[Embed(source="../../assets/fonts/RealmFonts.swf", mimeType="application/octet-stream")]
		private static const FontSwf:Class;

		public static var embedded:Boolean = false;
		private static var fontLoader:Loader;

		/** Loads the embedded font library, then calls done(). Falls back to device fonts. */
		public static function loadFonts(done:Function):void {
			var finish:Function = function(e:Event = null):void {
				for each (var f:Font in Font.enumerateFonts(false)) if (f.fontName == "Realm") embedded = true;
				done();
			};
			try {
				fontLoader = new Loader();
				fontLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, finish);
				fontLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, finish);
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

		/** Rounded panel like the RotMG sidebar boxes. */
		public static function panel(g:*, x:Number, y:Number, w:Number, h:Number, fill:uint = PANEL_DARK, edge:uint = PANEL_EDGE, alpha:Number = 1):void {
			g.lineStyle(2, edge, alpha);
			g.beginFill(fill, alpha);
			g.drawRoundRect(x, y, w, h, 12, 12);
			g.endFill();
			g.lineStyle();
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
			var draw:Function = function(hover:Boolean):void {
				bg.graphics.clear();
				panel(bg.graphics, 0, 0, w, h, hover ? 0x5a5a5a : 0x3e3e3e, hover ? 0xffffff : 0x6a6a6a);
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
