package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;

	/**
	 * The Oracle (O, or /oracle): every boss you've killed, how many times, and
	 * everything it has dropped for you, with its unique drops as a collection
	 * to complete. The server keeps the record as the kills happen (oracle.js).
	 */
	public class OracleWindow extends Sprite {
		public static const W:int = 820, H:int = 580;
		private static const VIOLET:uint = 0xb9a9ff, LIST_W:int = 262;
		private static const CATS:Array = ["Realm Events", "Dungeons", "Hard Dungeons", "Finales", "Raids"];

		private var g:Game;
		private var o:Object;
		private var tab:String = "bosses";
		private var sel:String;
		private var groups:Array;
		private var head:Sprite = new Sprite(), body:Sprite = new Sprite();
		private var tip:Tooltip = new Tooltip();
		private var listArea:ScrollArea, dropArea:ScrollArea;

		public function OracleWindow(g:Game, o:Object) {
			this.g = g;
			// (the Wiki's boss list, minus its non-monster entries like the weekly vault)
			groups = [];
			for each (var gl:Array in WikiWindow.collect().slice(0, CATS.length)) groups.push(gl.filter(function(e:Object, ...r):Boolean { return Data.ENEMIES[e.id] != null; }));
			var gr:* = graphics;
			gr.beginFill(0x000000, 0.35);
			gr.drawRoundRect(4, 6, W, H, 18, 18);
			gr.endFill();
			Ui.panel(gr, 0, 0, W, H, 0x14121c, 0x8a78d8, 0.98);
			var m:Matrix = new Matrix();
			m.createGradientBox(W - 4, 70, Math.PI / 2, 2, 2);
			gr.beginGradientFill(GradientType.LINEAR, [0x3a2a6a, 0x14121c], [0.95, 0], [0, 255], m);
			gr.drawRoundRect(2, 2, W - 4, 70, 14, 14);
			gr.endFill();
			addChild(head);
			addChild(body);
			tip.mouseEnabled = tip.mouseChildren = false;
			tip.visible = false;
			addChild(tip);
			setData(o);
		}

		/** New data from the server (the window stays where it was). */
		public function setData(data:Object):void {
			o = data || {b: {}, log: []};
			if (!o.b) o.b = {};
			if (!sel) {
				// start on the boss you've killed most
				var most:int = 0;
				for (var id:String in o.b) if (o.b[id].k > most) { most = o.b[id].k; sel = id; }
				if (!sel && groups[0].length) sel = groups[0][0].id;
			}
			drawHead();
			build();
		}

		private static function esc(s:String):String { return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;"); }

		private static function ago(t:Number):String {
			var s:int = Math.max(0, ((new Date()).time - t) / 1000);
			return s < 60 ? "just now" : s < 3600 ? int(s / 60) + "m ago" : s < 86400 ? int(s / 3600) + "h ago" : int(s / 86400) + "d ago";
		}

		/** The unique and Godly drops a boss can give (what the collection is made of). */
		private static function specials(id:String):Array {
			var d:Object = Data.ENEMIES[id];
			var out:Array = [];
			if (!d) return out;
			var ids:Array = (d.uniques || []).concat();
			if (id == "zealot_a" && Data.ENEMIES.zealot_b && Data.ENEMIES.zealot_b.uniques) ids = ids.concat(Data.ENEMIES.zealot_b.uniques);
			for each (var u:String in ids) { var it:Object = Uniques.make(u); if (it) out.push(it); }
			for each (var gd:Array in d.godly || []) out.push(Godly.make(gd[0], gd[1]));
			return out;
		}

		private function found(id:String, it:Object):int {
			var b:Object = o.b[id];
			if (!b || !b.d) return 0;
			var d:Object = b.d[it.name];
			return d ? int(d.c) : 0;
		}

		private function drawHead():void {
			head.removeChildren();
			// the eye
			var eye:Shape = new Shape();
			eye.graphics.lineStyle(2.5, VIOLET);
			eye.graphics.moveTo(-16, 0); eye.graphics.curveTo(0, -14, 16, 0); eye.graphics.curveTo(0, 14, -16, 0);
			eye.graphics.lineStyle();
			eye.graphics.beginFill(VIOLET); eye.graphics.drawCircle(0, 0, 6); eye.graphics.endFill();
			eye.graphics.beginFill(0x14121c); eye.graphics.drawCircle(0, 0, 2.5); eye.graphics.endFill();
			eye.x = 38; eye.y = 32;
			head.addChild(eye);
			var title:TextField = Ui.text(26, 0xe8e0ff, true, "left", 300, true);
			title.text = "The Oracle";
			title.x = 64; title.y = 10;
			head.addChild(title);
			var kills:int = 0, bosses:int = 0, have:int = 0, all:int = 0;
			for (var id:String in o.b) { kills += int(o.b[id].k); bosses++; }
			var total:int = 0;
			for each (var list:Array in groups) for each (var e:Object in list) {
				total++;
				for each (var it:Object in specials(e.id)) { all++; if (found(e.id, it)) have++; }
			}
			var sub:TextField = Ui.text(13, 0xb0a8d0, false, "left", 560, true);
			sub.htmlText = "<b>" + Ui.commas(kills) + "</b> boss kills  ·  <b>" + bosses + "</b> of " + total + " bosses slain  ·  <b>" + have + "</b> of " + all + " unique drops found";
			sub.x = 66; sub.y = 42;
			head.addChild(sub);
			var close:Sprite = Ui.button("X", 32, 28, function():void { g.closeOracle(); }, 15);
			close.x = W - 46; close.y = 12;
			head.addChild(close);
			var tabs:Array = [["bosses", "Bosses"], ["log", "Rare drops (" + (o.log ? o.log.length : 0) + ")"]];
			for (var i:int = 0; i < tabs.length; i++) {
				var b:Sprite = Ui.button((tab == tabs[i][0] ? "> " : "") + tabs[i][1], 170, 28, tabFn(tabs[i][0]), 14);
				b.x = W - 400 + i * 176; b.y = 74;
				b.alpha = tab == tabs[i][0] ? 1 : 0.65;
				head.addChild(b);
			}
		}

		private function tabFn(t:String):Function { return function():void { tab = t; drawHead(); build(); }; }

		private function build():void {
			var keep:Number = listArea ? listArea.scroll : 0;
			body.removeChildren();
			tip.visible = false;
			if (tab == "log") { buildLog(); return; }
			// ---- the boss list, by where they're found
			var lb:Shape = new Shape();
			Ui.panel(lb.graphics, 0, 0, LIST_W, H - 124, 0x1a1824, 0x3a3456, 1);
			lb.x = 14; lb.y = 110;
			body.addChild(lb);
			listArea = new ScrollArea(LIST_W - 8, H - 132);
			listArea.x = 18; listArea.y = 114;
			body.addChild(listArea);
			var y:int = 0;
			for (var ci:int = 0; ci < groups.length; ci++) {
				var hd:TextField = Ui.text(11, 0x8a80b0, true, "left", 200, true);
				hd.text = String(CATS[ci]).toUpperCase();
				hd.x = 6; hd.y = y + 4;
				listArea.content.addChild(hd);
				y += 22;
				for each (var e:Object in groups[ci]) { listArea.content.addChild(bossRow(e.id, y)); y += 34; }
				y += 6;
			}
			listArea.update(keep);
			buildBoss();
		}

		private function bossRow(id:String, y:int):Sprite {
			var d:Object = Data.ENEMIES[id];
			var rec:Object = o.b[id];
			var on:Boolean = id == sel;
			var r:Sprite = new Sprite();
			r.graphics.beginFill(on ? 0x3a2a6a : 0xffffff, on ? 1 : 0.001);
			r.graphics.drawRoundRect(0, 0, LIST_W - 22, 32, 8, 8);
			r.graphics.endFill();
			if (on) { r.graphics.beginFill(VIOLET); r.graphics.drawRect(0, 6, 3, 20); r.graphics.endFill(); }
			var bd:BitmapData = Sprites.get(d.spr);
			var pic:Bitmap = new Bitmap(bd);
			var sc:Number = Math.min(1, 28 / Math.max(bd.width, bd.height));
			pic.scaleX = pic.scaleY = sc;
			pic.x = 8 + (28 - bd.width * sc) / 2; pic.y = 2 + (28 - bd.height * sc) / 2;
			if (!rec) pic.transform.colorTransform = new ColorTransform(0.25, 0.25, 0.3, 0.8);
			r.addChild(pic);
			var nm:TextField = Ui.text(12, rec ? (d.col || 0xffffff) : 0x6a6a7a, true, "left", 160, true);
			nm.text = d.name;
			nm.x = 42; nm.y = 7;
			r.addChild(nm);
			if (rec) {
				var k:TextField = Ui.text(12, 0xe8e0ff, true, "right", 50, true);
				k.text = "x" + Ui.commas(rec.k);
				k.x = LIST_W - 80; k.y = 7;
				r.addChild(k);
			}
			r.y = y;
			r.buttonMode = true; r.mouseChildren = false;
			r.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { sel = id; build(); });
			return r;
		}

		private function where(id:String):String {
			for each (var list:Array in groups) for each (var e:Object in list) if (e.id == id) return e.where;
			return "";
		}

		private function buildBoss():void {
			var x0:int = LIST_W + 30, pw:int = W - x0 - 14;
			var d:Object = Data.ENEMIES[sel];
			if (!d) return;
			var rec:Object = o.b[sel];
			// the boss itself, big, on a glow
			var col:uint = d.col || VIOLET;
			var glow:Shape = new Shape();
			glow.graphics.beginFill(col, 0.12);
			glow.graphics.drawCircle(0, 0, 50);
			glow.graphics.beginFill(col, 0.1);
			glow.graphics.drawCircle(0, 0, 34);
			glow.graphics.endFill();
			glow.x = x0 + 56; glow.y = 166;
			body.addChild(glow);
			var bd:BitmapData = Sprites.get(d.spr);
			var pic:Bitmap = new Bitmap(bd);
			var sc:Number = Math.min(2, 92 / Math.max(bd.width, bd.height));
			pic.scaleX = pic.scaleY = sc;
			pic.x = x0 + 56 - bd.width * sc / 2; pic.y = 166 - bd.height * sc / 2;
			if (!rec) pic.transform.colorTransform = new ColorTransform(0.2, 0.2, 0.25, 0.85);
			body.addChild(pic);
			var nm:TextField = Ui.text(22, rec ? col : 0x8a8a9a, true, "left", pw - 130, true);
			nm.text = d.name;
			nm.x = x0 + 124; nm.y = 112;
			body.addChild(nm);
			var wh:TextField = Ui.text(12, 0x9a90c0, false, "left", pw - 130, true);
			wh.text = where(sel);
			wh.x = x0 + 126; wh.y = nm.y + nm.height;
			body.addChild(wh);
			var st:TextField = Ui.text(14, 0xffffff, false, "left", pw - 130, true);
			st.htmlText = rec ? "Slain <font color='#ffd75e'><b>" + Ui.commas(rec.k) + "</b></font> time" + (rec.k == 1 ? "" : "s") +
				"<br><font size='12' color='#9a9a9a'>First " + ago(rec.f) + "  ·  last " + ago(rec.l) + "</font>"
				: "<font color='#8a8a9a'>You haven't slain this one yet.</font>";
			st.x = x0 + 126; st.y = wh.y + wh.height + 6;
			body.addChild(st);
			// ---- its unique drops: a collection
			var sp:Array = specials(sel);
			var y:int = 232;
			var sh:TextField = Ui.text(11, 0x8a80b0, true, "left", pw, true);
			var have:int = 0;
			for each (var it0:Object in sp) if (found(sel, it0)) have++;
			sh.htmlText = "UNIQUE DROPS  <font color='" + (sp.length && have == sp.length ? "#ffd75e" : "#6a6a7a") + "'>" + have + " / " + sp.length + (sp.length && have == sp.length ? "  COMPLETE!" : "") + "</font>";
			sh.x = x0; sh.y = y;
			body.addChild(sh);
			y += 20;
			if (!sp.length) {
				var none:TextField = Ui.text(12, 0x6a6a7a, false, "left", pw, true);
				none.text = "This boss has no unique drops.";
				none.x = x0; none.y = y;
				body.addChild(none);
				y += 22;
			}
			for (var i:int = 0; i < sp.length; i++) {
				var c:Sprite = collectBox(sp[i], found(sel, sp[i]));
				c.x = x0 + (i % 8) * 60; c.y = y + int(i / 8) * 60;
				body.addChild(c);
			}
			if (sp.length) y += Math.ceil(sp.length / 8) * 60 + 6;
			// ---- everything it has dropped for you
			var ah:TextField = Ui.text(11, 0x8a80b0, true, "left", pw, true);
			ah.text = "EVERYTHING IT HAS DROPPED FOR YOU";
			ah.x = x0; ah.y = y;
			body.addChild(ah);
			y += 20;
			var bg:Shape = new Shape();
			Ui.panel(bg.graphics, 0, 0, pw, H - y - 14, 0x1a1824, 0x3a3456, 1);
			bg.x = x0; bg.y = y;
			body.addChild(bg);
			dropArea = new ScrollArea(pw - 8, H - y - 22);
			dropArea.x = x0 + 4; dropArea.y = y + 4;
			body.addChild(dropArea);
			var rows:Array = [];
			if (rec && rec.d) for (var n:String in rec.d) rows.push({n: n, c: int(rec.d[n].c), r: String(rec.d[n].r || ""), u: rec.d[n].u});
			var rank:Function = function(r:Object):int { return r.u ? 100 : Data.RARITIES.indexOf(r.r) + 1; };
			rows.sort(function(a:Object, b:Object):int { return rank(b) - rank(a) || b.c - a.c; });
			if (!rows.length) {
				var e:TextField = Ui.text(13, 0x6a6a7a, false, "left", pw - 30, true);
				e.text = rec ? "Nothing yet: it has never dropped anything for you." : "Slay it to start its record.";
				e.x = 10; e.y = 8;
				dropArea.content.addChild(e);
			}
			for (i = 0; i < rows.length; i++) {
				var row:Object = rows[i];
				var tf:TextField = Ui.text(12, Data.RARITY_COLORS[row.r] || 0xd8d8e0, row.r != "", "left", (pw - 30) / 2, true);
				tf.htmlText = esc(row.n) + "  <font color='#8a8a9a'>x" + row.c + "</font>";
				tf.x = 10 + (i % 2) * ((pw - 20) / 2); tf.y = 6 + int(i / 2) * 20;
				dropArea.content.addChild(tf);
			}
			dropArea.update(0);
		}

		/** A unique drop: in full colour (with how many) once found, a dark shape until then. */
		private function collectBox(it:Object, n:int):Sprite {
			var b:Sprite = new Sprite();
			var col:uint = Data.RARITY_COLORS[it.rarity] || 0xffffff;
			b.graphics.lineStyle(n ? 2 : 1, n ? col : 0x3a3456);
			b.graphics.beginFill(n ? 0x2a2440 : 0x16141e);
			b.graphics.drawRoundRect(0, 0, 54, 54, 10, 10);
			b.graphics.endFill();
			var bmp:Bitmap = new Bitmap(Sprites.icon(it));
			bmp.x = int((54 - bmp.width) / 2); bmp.y = int((54 - bmp.height) / 2);
			if (!n) bmp.transform.colorTransform = new ColorTransform(0, 0, 0, 0.7, 40, 36, 60, 0);
			b.addChild(bmp);
			if (n) {
				var c:TextField = Ui.text(11, 0xffffff, true, "right", 40, true);
				c.text = "x" + n;
				c.x = 10; c.y = 36;
				b.addChild(c);
			} else {
				var q:TextField = Ui.text(18, 0x6a6080, true, "center", 54, true);
				q.text = "?";
				q.y = 14;
				b.addChild(q);
			}
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
				tip.show(it, n ? "Found " + n + " time" + (n == 1 ? "" : "s") : "Not found yet");
				var p:Point = globalToLocal(b.localToGlobal(new Point(60, 0)));
				if (p.x + tip.width > W - 4) p.x -= tip.width + 66;
				tip.x = p.x; tip.y = Math.max(4, Math.min(H - tip.height - 4, p.y));
				tip.visible = true;
				setChildIndex(tip, numChildren - 1);
			});
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { tip.visible = false; });
			return b;
		}

		private function buildLog():void {
			var bg:Shape = new Shape();
			Ui.panel(bg.graphics, 0, 0, W - 28, H - 124, 0x1a1824, 0x3a3456, 1);
			bg.x = 14; bg.y = 110;
			body.addChild(bg);
			var area:ScrollArea = new ScrollArea(W - 36, H - 132);
			area.x = 18; area.y = 114;
			body.addChild(area);
			var log:Array = o.log || [];
			if (!log.length) {
				var e:TextField = Ui.text(14, 0x6a6a7a, false, "center", W - 60, true);
				e.text = "No rare drops yet. Every Runed, Bonded, Eldritch, Starforged, Primordial, Godly and unique item a boss drops for you shows up here.";
				e.y = 40;
				area.content.addChild(e);
			}
			for (var i:int = 0; i < log.length; i++) {
				var l:Object = log[i];
				var r:Sprite = new Sprite();
				r.graphics.beginFill(i % 2 ? 0x201c2c : 0x1a1824);
				r.graphics.drawRoundRect(0, 0, W - 52, 30, 8, 8);
				r.graphics.endFill();
				var col:uint = Data.RARITY_COLORS[l.r] || 0xffffff;
				r.graphics.beginFill(col);
				r.graphics.drawCircle(14, 15, 4);
				r.graphics.endFill();
				var tf:TextField = Ui.text(13, col, true, "left", 460, true);
				tf.htmlText = esc(l.name) + (l.u ? "  <font size='11' color='#ffd75e'>UNIQUE</font>" : "");
				tf.x = 28; tf.y = 6;
				r.addChild(tf);
				var fr:TextField = Ui.text(12, 0x9a90c0, false, "right", 280, true);
				fr.text = "from " + l.from + "  ·  " + ago(l.at);
				fr.x = W - 340; fr.y = 7;
				r.addChild(fr);
				r.y = i * 32;
				area.content.addChild(r);
			}
			area.update(0);
		}
	}
}
