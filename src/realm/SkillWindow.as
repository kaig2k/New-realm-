package realm {
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;

	/**
	 * The skill tree (T / star tab), drawn as five constellations on a night sky:
	 * each branch climbs four tiers, joined by star-lines that light up as you
	 * open them. Tiers open with points spent in their branch, and the deeper the
	 * skill the more each rank costs (Data.SKILL_COSTS); capstones need level 20.
	 */
	public class SkillWindow extends Sprite {
		public static const W:int = 960, H:int = 600;
		private static const COL_W:int = 184, X0:int = 20, TIER_Y:Array = [178, 270, 362, 460], R:int = 23;
		private static const RESET_COST:int = 1000;

		private var g:Game;
		private var sky:Shape = new Shape();
		private var twinkle:Array = [];
		private var lines:Shape = new Shape();
		private var body:Sprite = new Sprite();
		private var head:Sprite = new Sprite();
		private var info:TextField;
		private var pulses:Array = [];
		private var t:Number = 0;

		public function SkillWindow(g:Game) {
			this.g = g;
			drawSky();
			addChild(sky);
			lines.filters = [new GlowFilter(0xffffff, 0.5, 6, 6, 1.5)];
			addChild(lines);
			addChild(body);
			addChild(head);
			// the details of whatever you point at
			var ib:Shape = new Shape();
			ib.graphics.beginFill(0x000000, 0.45);
			ib.graphics.drawRoundRect(16, H - 64, W - 32, 50, 12, 12);
			ib.graphics.endFill();
			addChild(ib);
			info = Ui.text(13, 0xc8c8d8, false, "left", W - 56, true);
			info.x = 28; info.y = H - 58;
			addChild(info);
			addEventListener(Event.ENTER_FRAME, animate);
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void { removeEventListener(Event.ENTER_FRAME, animate); });
			refresh();
		}

		/** A night sky: deep blue, a nebula behind each branch, and stars (the same every time). */
		private function drawSky():void {
			var gr:* = sky.graphics;
			gr.beginFill(0x000000, 0.4);
			gr.drawRoundRect(5, 7, W, H, 20, 20);
			gr.endFill();
			var m:Matrix = new Matrix();
			m.createGradientBox(W, H, Math.PI / 2);
			gr.lineStyle(2, 0x6a7ac8);
			gr.beginGradientFill(GradientType.LINEAR, [0x0c1030, 0x070814], [1, 1], [0, 255], m);
			gr.drawRoundRect(0, 0, W, H, 18, 18);
			gr.endFill();
			gr.lineStyle();
			for (var b:int = 0; b < Data.SKILL_BRANCHES.length; b++) {
				var cx:Number = X0 + b * COL_W + COL_W / 2;
				var nm:Matrix = new Matrix();
				nm.createGradientBox(260, 420, 0, cx - 130, 110);
				gr.beginGradientFill(GradientType.RADIAL, [Data.SKILL_BRANCHES[b].col, Data.SKILL_BRANCHES[b].col], [0.13, 0], [0, 255], nm);
				gr.drawEllipse(cx - 130, 110, 260, 420);
				gr.endFill();
			}
			var seed:uint = 1234567;
			var rnd:Function = function():Number { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };
			for (var i:int = 0; i < 260; i++) {
				var sx:Number = 6 + rnd() * (W - 12), sy:Number = 6 + rnd() * (H - 12), big:Boolean = rnd() < 0.08;
				gr.beginFill(0xffffff, big ? 0.9 : 0.15 + rnd() * 0.45);
				gr.drawCircle(sx, sy, big ? 1.4 : 0.6 + rnd() * 0.6);
				gr.endFill();
				if (big && twinkle.length < 18) {
					var tw:Shape = new Shape();
					tw.graphics.beginFill(0xffffff, 0.8);
					tw.graphics.moveTo(0, -5); tw.graphics.lineTo(1, -1); tw.graphics.lineTo(5, 0); tw.graphics.lineTo(1, 1);
					tw.graphics.lineTo(0, 5); tw.graphics.lineTo(-1, 1); tw.graphics.lineTo(-5, 0); tw.graphics.lineTo(-1, -1);
					tw.graphics.endFill();
					tw.x = sx; tw.y = sy;
					tw.name = String(rnd() * 6.28);
					twinkle.push(tw);
					addChild(tw);
				}
			}
		}

		private function animate(e:Event):void {
			t += 1 / 30;
			for each (var tw:Shape in twinkle) { var a:Number = 0.5 + 0.5 * Math.sin(t * 1.7 + Number(tw.name)); tw.alpha = a; tw.scaleX = tw.scaleY = 0.5 + a * 0.6; }
			// skills you can learn right now breathe
			for each (var p:Object in pulses) p.glow.alpha = 0.45 + 0.4 * Math.sin(t * 4 + p.k);
		}

		private function resetTree():void {
			var p:Player = g.player;
			if (Data.skillSpent(p.skills) == 0) { g.msg("You haven't spent any skill points yet.", 0xaaaaaa); return; }
			if (g.gold < RESET_COST) { g.msg("Resetting the tree costs " + RESET_COST + " gold.", 0xff8080); return; }
			g.addGold(-RESET_COST);
			g.msg("Skill tree reset: " + p.resetSkills() + " points refunded.", 0x80e0ff);
			refresh();
		}

		public function refresh():void {
			var p:Player = g.player;
			// ---- header: title, the points orb, progress to the next point, reset and close
			head.removeChildren();
			var title:TextField = Ui.text(26, 0xe0e8ff, true, "left", 300, true);
			title.text = "Skill Tree";
			title.x = 22; title.y = 12;
			head.addChild(title);
			var sub:TextField = Ui.text(12, 0x8a96c8, false, "left", 420, true);
			sub.text = "Five constellations. Deeper stars cost more points a rank.";
			sub.x = 24; sub.y = 46;
			head.addChild(sub);
			var orb:Shape = new Shape();
			var om:Matrix = new Matrix();
			om.createGradientBox(56, 56, 0, -28, -28);
			orb.graphics.beginGradientFill(GradientType.RADIAL, [0xb0f0ff, 0x2a6aa8], [1, 1], [0, 255], om);
			orb.graphics.drawCircle(0, 0, 26);
			orb.graphics.endFill();
			orb.filters = [new GlowFilter(0x80e0ff, p.skillPoints > 0 ? 0.9 : 0.3, 18, 18, 2)];
			orb.x = W / 2 + 40; orb.y = 40;
			head.addChild(orb);
			var pts:TextField = Ui.text(22, 0xffffff, true, "center", 56, true);
			pts.text = String(p.skillPoints);
			pts.x = orb.x - 28; pts.y = orb.y - 16;
			head.addChild(pts);
			var pl:TextField = Ui.text(12, 0xc8d8ff, false, "left", 220, true);
			pl.htmlText = "<b>skill point" + (p.skillPoints == 1 ? "" : "s") + "</b><br>" + (p.level >= Player.MAX_LEVEL ? "next in " + Ui.commas(Math.max(0, p.nextPointXp - p.ascXp)) + " XP" : "+1 every level up");
			pl.x = orb.x + 34; pl.y = orb.y - 18;
			head.addChild(pl);
			if (p.level >= Player.MAX_LEVEL) {
				var bar:Shape = new Shape();
				bar.graphics.beginFill(0x1a2040);
				bar.graphics.drawRoundRect(0, 0, 130, 6, 6, 6);
				bar.graphics.beginFill(0x80e0ff);
				bar.graphics.drawRoundRect(0, 0, 130 * Math.min(1, p.ascXp / Math.max(1, p.nextPointXp)), 6, 6, 6);
				bar.graphics.endFill();
				bar.x = orb.x + 36; bar.y = orb.y + 18;
				head.addChild(bar);
			}
			var reset:Sprite = Ui.button("Reset (" + RESET_COST + "g)", 116, 28, resetTree, 12);
			reset.x = W - 172; reset.y = 14;
			head.addChild(reset);
			var asc:Sprite = Ui.button(p.ascended ? "✦ Ascend" : "Ascension", 100, 28, function():void { g.toggleSkills(); g.toggleAscend(); }, 12);
			asc.x = W - 280; asc.y = 14;
			head.addChild(asc);
			var close:Sprite = Ui.button("X", 32, 28, function():void { g.toggleSkills(); }, 14);
			close.x = W - 48; close.y = 14;
			head.addChild(close);

			// ---- the constellations
			body.removeChildren();
			lines.graphics.clear();
			pulses = [];
			for (var b:int = 0; b < Data.SKILL_BRANCHES.length; b++) drawBranch(b);
			info.htmlText = "<font color='#8a96c8'>Point at a star to read it, click to learn a rank. A tier opens once you've spent enough points in its branch; capstones (the big stars) need level 20.</font>";
		}

		/** Where skill sk sits (its centre). */
		private function spot(sk:Object):Array {
			var cx:Number = X0 + sk.b * COL_W + COL_W / 2;
			var row:Array = [];
			for each (var o:Object in Data.SKILLS) if (o.b == sk.b && o.t == sk.t) row.push(o);
			var i:int = row.indexOf(sk);
			var dx:Number = row.length == 1 ? 0 : (i == 0 ? -44 : 44);
			// (a gentle zig-zag, like a real constellation)
			var dy:Number = row.length == 1 ? 0 : (i == 0 ? -5 : 5) * (sk.t % 2 ? -1 : 1);
			return [cx + dx, TIER_Y[sk.t] + dy];
		}

		private function drawBranch(b:int):void {
			var p:Player = g.player;
			var br:Object = Data.SKILL_BRANCHES[b];
			var cx:Number = X0 + b * COL_W + COL_W / 2;
			var spent:int = Data.skillSpent(p.skills, b);
			// its emblem and name
			var em:Shape = new Shape();
			star(em.graphics, 0, 0, 11, 5, br.col, 1);
			em.filters = [new GlowFilter(br.col, 0.8, 10, 10, 2)];
			em.x = cx; em.y = 96;
			body.addChild(em);
			var nm:TextField = Ui.text(17, br.col, true, "center", COL_W, true);
			nm.text = br.name;
			nm.x = cx - COL_W / 2; nm.y = 108;
			body.addChild(nm);
			var ds:TextField = Ui.text(10, 0x8a96c8, false, "center", COL_W - 10, true);
			ds.htmlText = br.desc + "  ·  <font color='" + Ui.hex(br.col) + "'><b>" + spent + "</b> pts</font>";
			ds.x = cx - COL_W / 2 + 5; ds.y = 130;
			body.addChild(ds);
			// star-lines from each tier up to the next (lit once the higher tier is open)
			var tiers:Array = [[], [], [], []];
			for each (var sk:Object in Data.SKILLS) if (sk.b == b) tiers[sk.t].push(sk);
			for (var ti:int = 0; ti < 3; ti++) {
				var open:Boolean = spent >= Data.SKILL_TIER_REQ[ti + 1];
				for each (var a:Object in tiers[ti]) for each (var c:Object in tiers[ti + 1]) {
					var pa:Array = spot(a), pc:Array = spot(c);
					lines.graphics.lineStyle(open ? 2 : 1, open ? br.col : 0x3a4070, open ? 0.85 : 0.6);
					lines.graphics.moveTo(pa[0], pa[1]);
					lines.graphics.lineTo(pc[0], pc[1]);
				}
				if (tiers[ti].length == 2) {
					var p0:Array = spot(tiers[ti][0]), p1:Array = spot(tiers[ti][1]);
					lines.graphics.lineStyle(1, spent >= Data.SKILL_TIER_REQ[ti] ? br.col : 0x3a4070, 0.35);
					lines.graphics.moveTo(p0[0], p0[1]);
					lines.graphics.lineTo(p1[0], p1[1]);
				}
			}
			lines.graphics.lineStyle();
			// what each locked tier needs
			for (ti = 1; ti < 4; ti++) {
				if (spent >= Data.SKILL_TIER_REQ[ti]) continue;
				// (between the tier's two stars; above the capstone)
				var lk:TextField = Ui.text(10, 0x8a94c8, true, "center", 60, true);
				lk.htmlText = ti == 3 ? "needs " + Data.SKILL_TIER_REQ[ti] + " pts" : "needs<br>" + Data.SKILL_TIER_REQ[ti] + " pts";
				lk.x = cx - 30; lk.y = ti == 3 ? TIER_Y[ti] - 50 : TIER_Y[ti] - 14;
				if (ti == 3) { lk.width = 100; lk.x = cx - 50; }
				body.addChild(lk);
			}
			for each (sk in Data.SKILLS) if (sk.b == b) body.addChild(node(sk, br.col));
		}

		/** A star shape (points spikes) into graphics gr. */
		private static function star(gr:*, x:Number, y:Number, r:Number, points:int, col:uint, alpha:Number):void {
			gr.beginFill(col, alpha);
			for (var i:int = 0; i <= points * 2; i++) {
				var a:Number = -Math.PI / 2 + i * Math.PI / points, rr:Number = i % 2 ? r * 0.45 : r;
				if (i == 0) gr.moveTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr);
				else gr.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr);
			}
			gr.endFill();
		}

		private static function hexagon(gr:*, r:Number):void {
			for (var i:int = 0; i <= 6; i++) {
				var a:Number = Math.PI / 6 + i * Math.PI / 3;
				if (i == 0) gr.moveTo(Math.cos(a) * r, Math.sin(a) * r);
				else gr.lineTo(Math.cos(a) * r, Math.sin(a) * r);
			}
		}

		private function node(sk:Object, col:uint):Sprite {
			var p:Player = g.player;
			var r:int = p.rank(sk.id);
			var full:Boolean = r >= sk.max;
			var why:String = p.skillBlock(sk.id);
			var tierOpen:Boolean = Data.skillSpent(p.skills, sk.b) >= Data.SKILL_TIER_REQ[int(sk.t)] && !(sk.cap && p.level < Player.MAX_LEVEL);
			var can:Boolean = !full && why == null;
			var cost:int = Data.skillCost(sk);
			var rad:Number = sk.cap ? R + 7 : R;
			var at:Array = spot(sk);
			var n:Sprite = new Sprite();
			n.x = at[0]; n.y = at[1];
			// a soft halo: steady once learned, breathing when you can learn it
			var glow:Shape = new Shape();
			var gm:Matrix = new Matrix();
			gm.createGradientBox(rad * 4, rad * 4, 0, -rad * 2, -rad * 2);
			glow.graphics.beginGradientFill(GradientType.RADIAL, [full ? 0xffd75e : col, full ? 0xffd75e : col], [0.55, 0], [0, 255], gm);
			glow.graphics.drawCircle(0, 0, rad * 2);
			glow.graphics.endFill();
			glow.visible = r > 0 || can;
			glow.alpha = r > 0 ? 0.7 : 0.5;
			n.addChild(glow);
			if (can) pulses.push({glow: glow, k: sk.b * 1.3 + sk.t});
			// the star's body
			var face:Shape = new Shape();
			var edge:uint = full ? 0xffd75e : r > 0 ? col : tierOpen ? 0x9aa4d8 : 0x3a4070;
			face.graphics.lineStyle(sk.cap ? 3 : 2, edge, 1);
			var fm:Matrix = new Matrix();
			fm.createGradientBox(rad * 2, rad * 2, Math.PI / 2, -rad, -rad);
			face.graphics.beginGradientFill(GradientType.LINEAR, r > 0 ? [mix(col, 0x000000, 0.35), mix(col, 0x000000, 0.75)] : tierOpen ? [0x2a3060, 0x141832] : [0x161a30, 0x0c0e1c], [1, 1], [0, 255], fm);
			if (sk.cap) {
				// capstones are many-pointed stars
				var pts:int = 8;
				for (var i:int = 0; i <= pts * 2; i++) {
					var a:Number = -Math.PI / 2 + i * Math.PI / pts, rr:Number = i % 2 ? rad * 0.78 : rad;
					if (i == 0) face.graphics.moveTo(Math.cos(a) * rr, Math.sin(a) * rr);
					else face.graphics.lineTo(Math.cos(a) * rr, Math.sin(a) * rr);
				}
			} else hexagon(face.graphics, rad);
			face.graphics.endFill();
			n.addChild(face);
			// ranks as little stars around the bottom
			for (i = 0; i < sk.max; i++) {
				var ra:Number = Math.PI / 2 + (i - (sk.max - 1) / 2) * 0.32;
				var pip:Shape = new Shape();
				star(pip.graphics, 0, 0, 4, 4, i < r ? (full ? 0xffd75e : col) : 0x30365c, 1);
				pip.x = Math.cos(ra) * (rad + 7); pip.y = Math.sin(ra) * (rad + 7);
				n.addChild(pip);
			}
			var rt:TextField = Ui.text(sk.cap ? 15 : 13, full ? 0xffd75e : r > 0 ? 0xffffff : tierOpen ? 0xb8c0e8 : 0x4a5280, true, "center", 60, true);
			rt.text = full ? (sk.max == 1 ? "ON" : "MAX") : r + "/" + sk.max;
			rt.x = -30; rt.y = -10;
			n.addChild(rt);
			// its cost a rank, in a little diamond
			if (!full) {
				var cb:Shape = new Shape();
				cb.graphics.lineStyle(1, can ? 0xffffff : 0x4a5280);
				cb.graphics.beginFill(can ? col : 0x161a30);
				cb.graphics.moveTo(0, -9); cb.graphics.lineTo(9, 0); cb.graphics.lineTo(0, 9); cb.graphics.lineTo(-9, 0); cb.graphics.lineTo(0, -9);
				cb.graphics.endFill();
				cb.x = rad * 0.8; cb.y = -rad * 0.8;
				n.addChild(cb);
				var ct:TextField = Ui.text(10, can ? 0x000000 : 0x8a96c8, true, "center", 20, false);
				ct.text = String(cost);
				ct.x = cb.x - 10; ct.y = cb.y - 8;
				n.addChild(ct);
			}
			var lab:TextField = Ui.text(11, r > 0 ? (sk.cap ? 0xffd75e : 0xffffff) : tierOpen ? 0xb8c0e8 : 0x4a5280, true, "center", 96, true);
			lab.text = sk.name;
			lab.x = -48; lab.y = rad + 12;
			n.addChild(lab);
			if (sk.id == "highstakes" && r > 0) {
				var tog:Sprite = Ui.button(p.highStakes ? "ON" : "OFF", 44, 18, function():void {
					p.highStakes = !p.highStakes;
					g.msg("High Stakes " + (p.highStakes ? "ON: every drop is a gamble." : "OFF: drops are safe."), p.highStakes ? 0xffd040 : 0xaaaaaa);
					refresh();
				}, 11);
				tog.name = "tog";
				tog.x = 34; tog.y = -6;
				n.addChild(tog);
			}
			n.buttonMode = !full;
			n.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				for (var o:* = e.target; o && o != n; o = o.parent) if (o.name == "tog") return;
				if (full) return;
				if (p.spendSkill(sk.id, g)) refresh();
				else info.htmlText = "<font color='#ff9090'>" + p.skillBlock(sk.id) + "</font>";
			});
			n.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
				face.filters = [new GlowFilter(0xffffff, 0.6, 8, 8, 2)];
				var br:Object = Data.SKILL_BRANCHES[sk.b];
				info.htmlText = "<font color='" + Ui.hex(sk.cap ? 0xffd75e : col) + "' size='15'><b>" + sk.name + "</b></font>  <font color='#8a96c8'>" + br.name +
					(sk.cap ? " capstone" : ", tier " + (int(sk.t) + 1)) + "  ·  rank " + r + "/" + sk.max + "  ·  " + cost + " point" + (cost == 1 ? "" : "s") + " a rank</font><br>" +
					sk.desc + (sk.max > 1 ? " <font color='#8a96c8'>(per rank)</font>" : "") +
					(full ? "  <font color='#80e080'>Maxed.</font>" : why ? "  <font color='#ff9090'>" + why + "</font>" : "  <font color='#80e0ff'>Click to learn.</font>");
			});
			n.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { face.filters = []; });
			return n;
		}

		private static function mix(a:uint, b:uint, k:Number):uint {
			var r:int = ((a >> 16) & 255) * (1 - k) + ((b >> 16) & 255) * k;
			var gg:int = ((a >> 8) & 255) * (1 - k) + ((b >> 8) & 255) * k;
			var bb:int = (a & 255) * (1 - k) + (b & 255) * k;
			return (r << 16) | (gg << 8) | bb;
		}
	}
}
