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

		/** Item tooltip; with `worn`, also how it compares to what is equipped in that slot. */
		/** Why your hero can't put an item on yet (Hardcore's tier climb), or null; set by the game. */
		public static var blockFn:Function;

		public function show(item:Object, hintText:String, worn:Object = null):void {
			icon.bitmapData = Sprites.icon(item);
			title.text = item.name;
			var label:String = Data.tierLabel(item);
			tier.text = label;
			tier.textColor = Data.tierColor(item);
			title.textColor = item.rarity ? Data.tierColor(item) : item.kind == "stat" ? Ui.GOLD : item.kind == "key" ? item.color : 0xffffff;
			var top:Number = Math.max(icon.y + icon.height, title.y + title.height) + 6;
			var block:String = blockFn != null ? blockFn(item) : null;
			body.htmlText = Data.describe(item) + (worn && worn != item ? compareText(item, worn) : "") +
				(block ? "\n<font color='#ff7a6a'>" + block + "</font>" : "");
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

		private static function signed(v:Number, suffix:String = ""):String {
			var t:String = (v > 0 ? "+" : "") + (Math.abs(v - Math.round(v)) < 0.05 ? String(Math.round(v)) : v.toFixed(1)) + suffix;
			return "<font color='" + (v > 0 ? "#7cff7c" : "#ff7070") + "'>" + t + "</font>";
		}

		/** A rough worth for comparing two items of the same slot. */
		public static function score(it:Object):Number {
			var v:Number = 0;
			for each (var k:String in Data.STATS.concat(Data.GEAR_STATS)) {
				if (k == "spd" && it.kind == "weapon") continue;
				var n:Number = Number(it[k]) || 0;
				v += k == "hp" || k == "mp" ? n / 5 : n;
			}
			if (it.kind == "weapon") v += (it.dmin + it.dmax) / 2 * Math.max(1, it.shots || 1) * (it.rate || 1) * 0.6;
			if (it.kind == "ability") v += (it.power || 0) * 20;
			if (it.passive) v += 6;
			return v;
		}

		/** Gains in green and losses in red against the equipped item. */
		public static function compareText(it:Object, worn:Object):String {
			var lines:Array = [];
			if (it.kind == "weapon") {
				var dps:Function = function(w:Object):Number { return (w.dmin + w.dmax) / 2 * Math.max(1, w.shots || 1) * (w.rate || 1); };
				var a:Number = dps(it), b:Number = dps(worn);
				if (b > 0 && Math.abs(a - b) / b > 0.005) lines.push("Damage " + signed(Math.round((a - b) / b * 100), "%"));
				var ra:Number = it.spd * it.life - worn.spd * worn.life;
				if (Math.abs(ra) >= 0.1) lines.push("Range " + signed(ra, " tiles"));
			}
			if (it.kind == "ability" && it.power != worn.power) lines.push("Ability power " + signed(Math.round((it.power - worn.power) * 100), "%"));
			for each (var k:String in Data.STATS.concat(Data.GEAR_STATS)) {
				if (k == "spd" && it.kind == "weapon") continue;
				var d:Number = (Number(it[k]) || 0) - (Number(worn[k]) || 0);
				if (d != 0) lines.push(Data.STAT_SHORT[k] + " " + signed(d));
			}
			var head:String = "<font color='#8a8a9a'>vs. your " + worn.name + ":</font>";
			if (!lines.length) return head + " <font color='#b8b8b8'>same stats</font>\n";
			var rows:Array = [];
			for (var i:int = 0; i < lines.length; i += 2) rows.push("  " + lines.slice(i, i + 2).join("    "));
			return head + "\n" + rows.join("\n") + "\n";
		}
	}
}
