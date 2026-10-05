package realm {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.text.TextField;

	/** RotMG-style item tooltip: icon, name, tier tag, stats and a usage hint. */
	public class Tooltip extends Sprite {
		private static const W:int = 220;
		private var icon:Bitmap = new Bitmap();
		private var title:TextField;
		private var tier:TextField;
		private var body:TextField;
		private var hint:TextField;

		public function Tooltip() {
			mouseEnabled = mouseChildren = false;
			visible = false;
			icon.x = 8;
			icon.y = 8;
			addChild(icon);
			title = Ui.text(15, 0xffffff, true, "left", W - 90, true);
			title.x = 50; title.y = 8;
			addChild(title);
			tier = Ui.text(15, 0xffffff, true, "right", 40, true);
			tier.x = W - 48; tier.y = 8;
			addChild(tier);
			body = Ui.text(13, 0xb8b8b8, false, "left", W - 20);
			body.x = 10;
			addChild(body);
			hint = Ui.text(12, 0x8a8a8a, false, "left", W - 20);
			hint.x = 10;
			addChild(hint);
		}

		public function show(item:Object, hintText:String):void {
			icon.bitmapData = Sprites.icon(item);
			title.text = item.name;
			var label:String = Data.tierLabel(item);
			tier.text = label;
			tier.textColor = label == "UT" ? 0xc070ff : 0xffffff;
			title.textColor = label == "UT" ? 0xd890ff : item.kind == "stat" ? Ui.GOLD : 0xffffff;
			var top:Number = Math.max(icon.y + icon.height, title.y + title.height) + 6;
			body.htmlText = Data.describe(item);
			body.y = top + 4;
			hint.text = hintText;
			hint.y = body.y + body.height + 4;
			var h:Number = hint.y + hint.height + 8;
			graphics.clear();
			Ui.panel(graphics, 0, 0, W, h, 0x1c1c1c, 0x6a6a6a, 0.96);
			graphics.lineStyle(1, 0x444444);
			graphics.moveTo(8, top);
			graphics.lineTo(W - 8, top);
			graphics.lineStyle();
			visible = true;
		}
	}
}
