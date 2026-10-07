package realm {
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	/** The skill tree (T / star tab): three branches of upgrades, each ending in a capstone. */
	public class SkillWindow extends Sprite {
		public static const W:int = 660, H:int = 580;
		private static const COL_W:int = 196, NODE_H:int = 62, GAP:int = 22;
		private static const RESET_COST:int = 1000;

		private var g:Game;
		private var body:Sprite = new Sprite();
		private var head:TextField;
		private var info:TextField;

		public function SkillWindow(g:Game) {
			this.g = g;
			Ui.panel(graphics, 0, 0, W, H, 0x1a1c22, 0x80c8ff, 0.97);
			var title:TextField = Ui.text(22, 0x80e0ff, true, "left", 300, true);
			title.text = "Skill Tree";
			title.x = 16; title.y = 8;
			addChild(title);
			head = Ui.text(13, 0xdddddd, false, "left", 380);
			head.x = 160; head.y = 16;
			addChild(head);
			var close:Sprite = Ui.button("X", 30, 28, function():void { g.toggleSkills(); }, 14);
			close.x = W - 42; close.y = 10;
			addChild(close);
			var reset:Sprite = Ui.button("Reset (" + RESET_COST + "g)", 110, 26, resetTree, 12);
			reset.x = W - 160; reset.y = 11;
			addChild(reset);
			body.y = 50;
			addChild(body);
			info = Ui.text(13, 0xc8c8c8, false, "left", W - 32);
			info.x = 16; info.y = H - 50;
			addChild(info);
			refresh();
		}

		private function resetTree():void {
			var p:Player = g.player;
			var spent:int = 0;
			for (var id:String in p.skills) spent += p.rank(id);
			if (spent == 0) { g.msg("You haven't spent any skill points yet.", 0xaaaaaa); return; }
			if (g.gold < RESET_COST) { g.msg("Resetting the tree costs " + RESET_COST + " gold.", 0xff8080); return; }
			g.addGold(-RESET_COST);
			g.msg("Skill tree reset: " + p.resetSkills() + " points refunded.", 0x80e0ff);
			refresh();
		}

		public function refresh():void {
			var p:Player = g.player;
			head.htmlText = "<font color='#80e0ff'><b>" + p.skillPoints + "</b> skill point" + (p.skillPoints == 1 ? "" : "s") + "</font>" +
				(p.level >= Player.MAX_LEVEL ? "   next point " + p.ascXp + "/" + p.nextPointXp + " XP" : "   +1 per level up");
			while (body.numChildren) body.removeChildAt(0);
			body.graphics.clear();
			for (var b:int = 0; b < Data.SKILL_BRANCHES.length; b++) {
				var br:Object = Data.SKILL_BRANCHES[b];
				var bx:int = 16 + b * (COL_W + 16);
				var bt:TextField = Ui.text(17, br.col, true, "center", COL_W, true);
				bt.text = br.name;
				bt.x = bx; bt.y = 0;
				body.addChild(bt);
				var bd:TextField = Ui.text(11, 0x9a9a9a, false, "center", COL_W);
				bd.text = br.desc;
				bd.x = bx; bd.y = 22;
				body.addChild(bd);
				var row:int = 0;
				for each (var sk:Object in Data.SKILLS) {
					if (sk.b != b) continue;
					var ny:int = 42 + row * (NODE_H + GAP);
					if (row > 0) {
						// link to the skill above: lit once it has 2 ranks
						var par:Object = Data.skillParent(sk.id);
						body.graphics.lineStyle(4, p.rank(par.id) >= 2 ? br.col : 0x3a3a44);
						body.graphics.moveTo(bx + COL_W / 2, ny - GAP);
						body.graphics.lineTo(bx + COL_W / 2, ny);
						body.graphics.lineStyle();
					}
					body.addChild(node(sk, br.col, bx, ny));
					row++;
				}
			}
			info.htmlText = "<font color='#9a9a9a'>Click a skill to put a point in it. Each skill needs 2 ranks in the one above it; capstones (gold) need level 20.</font>";
		}

		private function node(sk:Object, col:uint, x:int, y:int):Sprite {
			var p:Player = g.player;
			var r:int = p.rank(sk.id);
			var why:String = p.skillBlock(sk.id);
			var full:Boolean = r >= sk.max;
			var locked:Boolean = !full && why != null && why.indexOf("Needs") == 0 || sk.cap && p.level < Player.MAX_LEVEL && r == 0;
			var n:Sprite = new Sprite();
			var edge:uint = full ? (sk.cap ? 0xffd75e : col) : locked ? 0x40404a : sk.cap ? 0xc8a050 : 0x8a8a9a;
			Ui.panel(n.graphics, 0, 0, COL_W, NODE_H, r > 0 ? 0x2a2e3a : 0x202228, edge, locked ? 0.6 : 1);
			if (sk.cap) {
				n.graphics.lineStyle(1, 0xffd75e, full ? 0.9 : 0.35);
				n.graphics.drawRoundRect(3, 3, COL_W - 6, NODE_H - 6, 9, 9);
				n.graphics.lineStyle();
			}
			// rank pips
			for (var i:int = 0; i < sk.max; i++) {
				n.graphics.beginFill(i < r ? col : 0x3a3a44);
				n.graphics.drawRect(COL_W - 12 - (sk.max - i) * 11, 8, 8, 8);
				n.graphics.endFill();
			}
			var t:TextField = Ui.text(14, locked ? 0x777777 : sk.cap ? 0xffd75e : 0xffffff, true, "left", COL_W - 70);
			t.text = sk.name;
			t.x = 8; t.y = 3;
			n.addChild(t);
			var d:TextField = Ui.text(11, locked ? 0x666666 : 0xb0b0b8, false, "left", COL_W - 14);
			d.text = sk.desc;
			d.x = 8; d.y = 22;
			n.addChild(d);
			if (sk.id == "highstakes" && r > 0) {
				var tog:Sprite = Ui.button(p.highStakes ? "ON" : "OFF", 44, 18, function():void {
					p.highStakes = !p.highStakes;
					g.msg("High Stakes " + (p.highStakes ? "ON: every drop is a gamble." : "OFF: drops are safe."), p.highStakes ? 0xffd040 : 0xaaaaaa);
					refresh();
				}, 11);
				tog.name = "tog";
				tog.x = COL_W - 52; tog.y = NODE_H - 22;
				n.addChild(tog);
			}
			n.x = x; n.y = y;
			n.buttonMode = !full;
			n.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				for (var o:* = e.target; o && o != n; o = o.parent) if (o.name == "tog") return;
				if (full) return;
				if (p.spendSkill(sk.id, g)) refresh();
				else info.htmlText = "<font color='#ff9090'>" + p.skillBlock(sk.id) + "</font>";
			});
			n.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
				info.htmlText = "<font color='" + Ui.hex(sk.cap ? 0xffd75e : col) + "'><b>" + sk.name + "</b></font> " + r + "/" + sk.max + ": " + sk.desc +
					(full ? "  <font color='#80e080'>(maxed)</font>" : why ? "\n<font color='#ff9090'>" + why + "</font>" : "\n<font color='#80e0ff'>Click to learn.</font>");
			});
			return n;
		}
	}
}
