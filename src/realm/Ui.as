package realm {
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	/** Small helpers for text fields and buttons. */
	public class Ui {
		public static const OUTLINE:Array = [new GlowFilter(0x000000, 1, 3, 3, 6)];

		public static function text(size:int, color:uint, bold:Boolean = false, align:String = "left", width:Number = 0, outline:Boolean = false):TextField {
			var tf:TextField = new TextField();
			var fmt:TextFormat = new TextFormat("_sans", size, color, bold);
			fmt.align = align;
			tf.defaultTextFormat = fmt;
			tf.selectable = false;
			tf.mouseEnabled = false;
			if (width > 0) {
				tf.width = width;
				tf.wordWrap = true;
				tf.multiline = true;
				tf.autoSize = align == "center" ? TextFieldAutoSize.CENTER : TextFieldAutoSize.LEFT;
			} else {
				tf.autoSize = TextFieldAutoSize.LEFT;
			}
			if (outline) tf.filters = OUTLINE;
			return tf;
		}

		public static function button(label:String, w:int, h:int, onClick:Function):Sprite {
			var b:Sprite = new Sprite();
			var tf:TextField = text(16, 0xffffff, true, "center", w);
			tf.text = label;
			tf.y = (h - tf.height) / 2;
			b.addChild(tf);
			b.buttonMode = true;
			b.mouseChildren = false;
			var draw:Function = function(hover:Boolean):void {
				b.graphics.clear();
				b.graphics.lineStyle(2, hover ? 0xffd75e : 0x8a7a50);
				b.graphics.beginFill(hover ? 0x4a3f63 : 0x2e2740);
				b.graphics.drawRoundRect(0, 0, w, h, 10, 10);
				b.graphics.endFill();
			};
			draw(false);
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onClick(); });
			return b;
		}

		public static function hex(c:uint):String {
			var s:String = c.toString(16);
			while (s.length < 6) s = "0" + s;
			return "#" + s;
		}
	}
}
