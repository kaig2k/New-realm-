package realm {
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;

	/**
	 * The Endless Abyss: a boss wave is cleared, pick one of three boons for the rest
	 * of the run (the server offered them and checks the pick).
	 */
	public class BoonPicker extends Sprite {
		public static const W:int = 540, H:int = 210;

		public function BoonPicker(g:Game, wave:int, choices:Array) {
			var m:Matrix = new Matrix();
			m.createGradientBox(W, H, Math.PI / 2);
			graphics.lineStyle(2, 0xa060ff);
			graphics.beginGradientFill(GradientType.LINEAR, [0x1e1030, 0x0a0614], [0.95, 0.95], [0, 255], m);
			graphics.drawRoundRect(0, 0, W, H, 16, 16);
			graphics.endFill();
			var t:TextField = Ui.text(20, 0xd080ff, true, "center", W, true);
			t.text = "Wave " + wave + " cleared!";
			t.y = 10;
			t.filters = [new GlowFilter(0x8030ff, 0.8, 10, 10, 2)];
			addChild(t);
			var s:TextField = Ui.text(12, 0xc8b8e0, false, "center", W, true);
			s.text = "Choose a boon for the rest of this run. The next wave is coming...";
			s.y = 40;
			addChild(s);
			for (var i:int = 0; i < choices.length; i++) addChild(card(g, Data.findBoon(choices[i]), 18 + i * 172, 70));
		}

		private function card(g:Game, b:Object, x:int, y:int):Sprite {
			var c:Sprite = new Sprite();
			c.x = x; c.y = y;
			c.buttonMode = true;
			c.mouseChildren = false;
			var draw:Function = function(hover:Boolean):void {
				c.graphics.clear();
				c.graphics.lineStyle(2, hover ? 0xffffff : b.col, 1);
				c.graphics.beginFill(hover ? 0x2e1e48 : 0x1a1028, 1);
				c.graphics.drawRoundRect(0, 0, 160, 120, 12, 12);
				c.graphics.endFill();
				c.graphics.lineStyle();
				c.graphics.beginFill(b.col, 0.9);
				c.graphics.moveTo(80, 14); c.graphics.lineTo(92, 28); c.graphics.lineTo(80, 42); c.graphics.lineTo(68, 28); c.graphics.lineTo(80, 14);
				c.graphics.endFill();
			};
			draw(false);
			var n:TextField = Ui.text(15, b.col, true, "center", 160, true);
			n.text = b.name;
			n.y = 50;
			c.addChild(n);
			var d:TextField = Ui.text(13, 0xffffff, false, "center", 160, true);
			d.text = b.desc;
			d.y = 78;
			c.addChild(d);
			c.addEventListener("mouseOver", function(e:*):void { draw(true); });
			c.addEventListener("mouseOut", function(e:*):void { draw(false); });
			c.addEventListener("click", function(e:*):void { g.pickBoon(b.id); });
			return c;
		}
	}
}
