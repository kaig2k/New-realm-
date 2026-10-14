package realm {
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;

	/**
	 * Ascension (/ascend, or the button in the Skill Tree): a level 20 hero with
	 * every stat maxed starts again at level 1, keeping its gear, for a point in the
	 * account's tree and an aura that grows with every ascension. The tree's perks
	 * are for every hero. The server does both (handlers.ascend, ascSpend).
	 */
	public class AscendWindow extends Sprite {
		public static const W:int = 640, H:int = 520;
		private var g:Game;
		private var armed:Boolean = false;

		public function AscendWindow(g:Game) {
			this.g = g;
			refresh();
		}

		public function refresh():void {
			removeChildren();
			graphics.clear();
			var m:Matrix = new Matrix();
			m.createGradientBox(W, H, Math.PI / 2);
			graphics.lineStyle(2, 0xffd75e);
			graphics.beginGradientFill(GradientType.LINEAR, [0x2a2010, 0x100c08], [0.98, 0.98], [0, 255], m);
			graphics.drawRoundRect(0, 0, W, H, 18, 18);
			graphics.endFill();
			graphics.lineStyle();
			var p:Player = g.player;
			var asc:Object = Save.data.asc || {pts: 0, r: {}};
			var title:TextField = Ui.text(28, 0xffd75e, true, "center", W, true);
			title.text = "Ascension";
			title.y = 10;
			title.filters = [new GlowFilter(0xffa020, 0.8, 14, 14, 2)];
			addChild(title);
			var close:Sprite = Ui.button("X", 32, 28, function():void { g.toggleAscend(); }, 14);
			close.x = W - 46; close.y = 12;
			addChild(close);
			// ---- this hero
			var n:int = p.asc;
			var aura:Shape = new Shape();
			var col:uint = n > 0 ? Data.ASC_AURAS[Math.min(4, n)] : 0x6a5a3a;
			aura.graphics.beginFill(col, 0.18);
			aura.graphics.drawEllipse(-46, -14, 92, 28);
			aura.graphics.endFill();
			aura.graphics.lineStyle(2, col, 0.8);
			aura.graphics.drawEllipse(-36, -10, 72, 20);
			aura.x = 70; aura.y = 128;
			addChild(aura);
			var bm:flash.display.Bitmap = new flash.display.Bitmap(p.sprite);
			bm.scaleX = bm.scaleY = 1.6;
			bm.x = 70 - bm.width / 2; bm.y = 128 - bm.height + 6;
			addChild(bm);
			var can:Boolean = Data.canAscend({cls: p.cls.id, level: p.level, stats: p.stats});
			var info:TextField = Ui.text(13, 0xe8dcc0, false, "left", W - 170, true);
			info.htmlText = "<font size='17' color='#ffd75e'><b>" + p.name + "</b></font>" + (n ? "  <font color='" + Ui.hex(col) + "'>Ascended " + n + "×</font>" : "") +
				"<br>Level <b>" + p.level + "</b> / 20  ·  <b>" + p.maxedCount + "</b> / 11 stats maxed" +
				"<br><font color='#b8a888'>Ascending: back to level 1 with your class's starting stats. You keep your gear and inventory. +1 Ascension point and a brighter aura.</font>";
			info.x = 140; info.y = 58;
			addChild(info);
			var ab:Sprite = Ui.button(can ? (armed ? "Sure? Click again to Ascend" : "Ascend " + p.name) : "Needs level 20 and 11/11 maxed", 300, 34, function():void {
				if (!can) { g.msg("Only a level 20 hero with every stat maxed can ascend.", 0xff8080); return; }
				if (!armed) { armed = true; refresh(); return; }
				armed = false;
				g.ascend();
			}, 14);
			ab.x = 140; ab.y = 162;
			ab.alpha = can ? 1 : 0.5;
			addChild(ab);
			// ---- the account's tree
			var th:TextField = Ui.text(15, 0xffd75e, true, "left", W - 40, true);
			th.htmlText = "THE ASCENDANT TREE  <font color='#ffffff'>" + int(asc.pts) + " point" + (int(asc.pts) == 1 ? "" : "s") + " to spend</font>  <font size='11' color='#a89878'>(for every hero, for good)</font>";
			th.x = 24; th.y = 210;
			addChild(th);
			for (var i:int = 0; i < Data.ASC_PERKS.length; i++) {
				var pk:Object = Data.ASC_PERKS[i];
				var r:int = Data.ascRank(asc, pk.id);
				var x:int = 24 + (i % 2) * 300, y:int = 240 + int(i / 2) * 88;
				var box:Shape = new Shape();
				Ui.panel(box.graphics, 0, 0, 290, 80, 0x1e1810, r > 0 ? pk.col : 0x4a3e2a, 1);
				box.x = x; box.y = y;
				addChild(box);
				var nt:TextField = Ui.text(14, r > 0 ? pk.col : 0xd8c8a8, true, "left", 210, true);
				nt.htmlText = pk.name + "<br><font size='12' color='#c8b898'>" + pk.desc + " a rank<br>now: " + total(pk, r) + "</font>";
				nt.x = x + 10; nt.y = y + 8;
				addChild(nt);
				for (var k:int = 0; k < pk.max; k++) {
					var pip:Shape = new Shape();
					pip.graphics.lineStyle(1, 0x000000);
					pip.graphics.beginFill(k < r ? pk.col : 0x3a3020);
					pip.graphics.moveTo(0, -6); pip.graphics.lineTo(6, 0); pip.graphics.lineTo(0, 6); pip.graphics.lineTo(-6, 0); pip.graphics.lineTo(0, -6);
					pip.graphics.endFill();
					pip.x = x + 18 + k * 16; pip.y = y + 67;
					addChild(pip);
				}
				if (r < pk.max) {
					var sb:Sprite = Ui.button("+1", 54, 30, spendFn(pk.id), 15);
					sb.x = x + 226; sb.y = y + 22;
					sb.alpha = int(asc.pts) > 0 ? 1 : 0.4;
					addChild(sb);
				} else {
					var mx:TextField = Ui.text(12, pk.col, true, "right", 70, true);
					mx.text = "MAX";
					mx.x = x + 206; mx.y = y + 28;
					addChild(mx);
				}
			}
		}

		private static function total(pk:Object, r:int):String {
			var d:String = String(pk.desc);
			var num:Number = Number(d.replace(/[^0-9.]/g, ""));
			return r ? d.replace(/[0-9.]+/, String(Math.round(num * r * 100) / 100)) : "nothing yet";
		}

		private function spendFn(id:String):Function {
			return function():void {
				if (int((Save.data.asc || {}).pts) <= 0) { g.msg("You have no Ascension points: ascend a maxed hero to earn one.", 0xff8080); return; }
				Online.send({t: "ascSpend", id: id});
			};
		}
	}
}
