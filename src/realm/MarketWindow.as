package realm {
	import flash.display.Bitmap;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;

	/**
	 * The player Marketplace, full size: browse every listing as cards (search,
	 * kinds, sorting, only what your class can use, only what you can afford;
	 * mouse wheel or drag the bar to scroll), sell from your inventory, and
	 * manage your own listings and takings. The server does every sale
	 * (Game.marketBuy / marketList / marketCancel / marketCollect).
	 */
	public class MarketWindow extends Sprite {
		public static const W:int = 820, H:int = 580;
		private static const KINDS:Array = [["all", "Everything"], ["weapon", "Weapons"], ["ability", "Abilities"], ["armor", "Armor"], ["ring", "Rings"], ["other", "Other"]];
		private static const SORTS:Array = [["new", "Newest"], ["low", "Lowest price"], ["high", "Highest price"], ["rare", "Best rarity"]];
		private static const GREEN:uint = 0x6fe08f, GOLD:uint = 0xffd75e;
		private static const CARD_W:int = 150, CARD_H:int = 178, GAP:int = 8;

		private var g:Game;
		public var tab:String;
		private var kind:String = "all", sort:String = "new";
		private var mineOnly:Boolean = false, affordOnly:Boolean = false;
		private var query:String = "";
		private var sel:int = -1;

		private var head:Sprite = new Sprite();
		private var body:Sprite = new Sprite();
		private var tip:Tooltip = new Tooltip();
		private var search:TextField, price:TextField;
		// the scrolling list
		private var view:Sprite, content:Sprite, bar:Sprite;
		private var viewH:int = 0, scroll:Number = 0, dragY:Number = -1;

		public function MarketWindow(g:Game, tab:String) {
			this.g = g;
			this.tab = tab == "sell" || tab == "mine" ? tab : "buy";
			// the frame: a deep green-black panel with a gold rim and a lit header
			var gr:* = graphics;
			gr.beginFill(0x000000, 0.35);
			gr.drawRoundRect(4, 6, W, H, 18, 18);
			gr.endFill();
			Ui.panel(gr, 0, 0, W, H, 0x12161a, 0xc8a24a, 0.98);
			var m:Matrix = new Matrix();
			m.createGradientBox(W - 4, 58, Math.PI / 2, 2, 2);
			gr.beginGradientFill(GradientType.LINEAR, [0x1f4a34, 0x12161a], [0.95, 0], [0, 255], m);
			gr.drawRoundRect(2, 2, W - 4, 58, 14, 14);
			gr.endFill();
			gr.lineStyle(1, 0xc8a24a, 0.35);
			gr.moveTo(14, 96); gr.lineTo(W - 14, 96);
			gr.lineStyle();
			addChild(head);
			addChild(body);
			tip.mouseEnabled = tip.mouseChildren = false;
			tip.visible = false;
			addChild(tip);
			search = Ui.input(220, "", 30, 13);
			price = Ui.input(140, "", 9, 16);
			price.restrict = "0-9";
			for each (var f:TextField in [search, price]) {
				// typing here never moves your hero or uses items
				f.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void { e.stopPropagation(); if (e.keyCode == 27) g.closeMarket(); });
				f.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent):void { e.stopPropagation(); });
			}
			search.addEventListener(Event.CHANGE, function(e:Event):void { query = search.text.toLowerCase(); scroll = 0; build(); });
			price.addEventListener(Event.CHANGE, function(e:Event):void { build(); stage.focus = price; });
			addEventListener(MouseEvent.MOUSE_WHEEL, function(e:MouseEvent):void { scrollBy(-e.delta * 40); e.stopPropagation(); });
			refresh();
		}

		/** The server sent a new view (or gold changed): redraw everything. */
		public function refresh():void {
			drawHead();
			build();
		}

		private static function esc(s:String):String { return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;"); }

		private function get v():Object { return g.marketData; }

		private function drawHead():void {
			head.removeChildren();
			var title:TextField = Ui.text(26, GOLD, true, "left", 300, true);
			title.text = "Marketplace";
			title.x = 20; title.y = 10;
			head.addChild(title);
			var sub:TextField = Ui.text(12, 0x9fc8a8, false, "left", 360, true);
			sub.text = "Buy from other players, even while they're offline.";
			sub.x = 22; sub.y = 42;
			head.addChild(sub);
			// your gold, as a coin and a number
			var coin:Shape = new Shape();
			coin.graphics.lineStyle(2, 0x8a6a10);
			coin.graphics.beginFill(GOLD);
			coin.graphics.drawCircle(0, 0, 9);
			coin.graphics.endFill();
			coin.graphics.lineStyle(1.5, 0xb08a20);
			coin.graphics.drawCircle(0, 0, 5);
			coin.x = W - 206; coin.y = 26;
			head.addChild(coin);
			var gold:TextField = Ui.text(20, GOLD, true, "left", 150, true);
			gold.text = Ui.commas(g.gold);
			gold.x = W - 192; gold.y = 12;
			head.addChild(gold);
			var close:Sprite = Ui.button("X", 32, 28, function():void { g.closeMarket(); }, 15);
			close.x = W - 46; close.y = 12;
			head.addChild(close);
			// tabs
			var n:int = 0, mine:int = 0;
			for each (var row:Object in v ? v.list : []) { n++; if (row.mine) mine++; }
			var waiting:Boolean = v && (v.earned > 0 || v.returns > 0);
			var tabs:Array = [["buy", "Browse  (" + n + ")"], ["sell", "Sell an item"], ["mine", "My listings  (" + mine + ")" + (waiting ? "  !" : "")]];
			for (var i:int = 0; i < tabs.length; i++) head.addChild(tabButton(tabs[i][0], tabs[i][1], 18 + i * 186, 64));
		}

		private function tabButton(id:String, label:String, x:int, y:int):Sprite {
			var on:Boolean = tab == id;
			var b:Sprite = new Sprite();
			var draw:Function = function(hover:Boolean):void {
				b.graphics.clear();
				b.graphics.lineStyle(on ? 2 : 1, on ? GOLD : hover ? 0x9a9a9a : 0x4a4a4a);
				b.graphics.beginFill(on ? 0x2a4a34 : hover ? 0x2a2e32 : 0x1c2024);
				b.graphics.drawRoundRect(0, 0, 178, 28, 10, 10);
				b.graphics.endFill();
			};
			draw(false);
			var tf:TextField = Ui.text(14, on ? 0xffffff : 0xb0b0b0, true, "center", 178, true);
			tf.text = label;
			tf.y = 4;
			b.addChild(tf);
			b.x = x; b.y = y;
			b.buttonMode = true; b.mouseChildren = false;
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { tab = id; scroll = 0; g.requestMarket(); refresh(); });
			return b;
		}

		// ------------------------------------------------------------ building
		private function build():void {
			body.removeChildren();
			tip.visible = false;
			view = null;
			if (!v) { note("Opening the market...", 110); return; }
			if (tab == "buy") buildBrowse();
			else if (tab == "sell") buildSell();
			else buildMine();
		}

		private function note(text:String, y:int, x:int = 24, color:uint = 0xaaaaaa):TextField {
			var tf:TextField = Ui.text(14, color, false, "left", W - x - 24, true);
			tf.htmlText = text;
			tf.x = x; tf.y = y;
			body.addChild(tf);
			return tf;
		}

		/** A selectable line in the side bar. */
		private function sideRow(label:String, count:int, on:Boolean, y:int, fn:Function):void {
			var b:Sprite = new Sprite();
			b.graphics.beginFill(on ? 0x2a4a34 : 0xffffff, on ? 1 : 0.001);
			b.graphics.drawRoundRect(0, 0, 150, 24, 8, 8);
			b.graphics.endFill();
			if (on) { b.graphics.beginFill(GOLD); b.graphics.drawRect(0, 5, 3, 14); b.graphics.endFill(); }
			var tf:TextField = Ui.text(13, on ? 0xffffff : 0xb8b8b8, on, "left", 110, true);
			tf.text = label;
			tf.x = 10; tf.y = 3;
			b.addChild(tf);
			if (count >= 0) {
				var ct:TextField = Ui.text(12, on ? GOLD : 0x777777, true, "right", 40, true);
				ct.text = String(count);
				ct.x = 102; ct.y = 4;
				b.addChild(ct);
			}
			b.x = 14; b.y = y;
			b.buttonMode = true; b.mouseChildren = false;
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { fn(); scroll = 0; build(); });
			body.addChild(b);
		}

		private function check(label:String, on:Boolean, y:int, fn:Function):void {
			var b:Sprite = new Sprite();
			b.graphics.lineStyle(1.5, on ? GREEN : 0x777777);
			b.graphics.beginFill(on ? 0x1f4a34 : 0x1c2024);
			b.graphics.drawRoundRect(0, 3, 16, 16, 5, 5);
			b.graphics.endFill();
			if (on) { b.graphics.lineStyle(2.5, GREEN); b.graphics.moveTo(3.5, 11); b.graphics.lineTo(7, 15); b.graphics.lineTo(13, 6.5); }
			var tf:TextField = Ui.text(12, 0xc8c8c8, false, "left", 128, true);
			tf.text = label;
			tf.x = 22; tf.y = 2;
			b.addChild(tf);
			b.x = 18; b.y = y;
			b.buttonMode = true; b.mouseChildren = false;
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { fn(); scroll = 0; build(); });
			body.addChild(b);
		}

		private static function kindOf(it:Object):String {
			return ["weapon", "ability", "armor", "ring"].indexOf(it.kind) >= 0 ? it.kind : "other";
		}

		private static function rank(it:Object):Number {
			var r:int = Data.RARITIES.indexOf(it.rarity);
			return (r + 1) * 100 + int(it.tier || 0);
		}

		private function buildBrowse():void {
			var all:Array = v.list || [];
			// side bar: kinds, sorting, filters
			var t:TextField = note("<b>KIND</b>", 106, 24, 0x7a8a80);
			t.textColor = 0x7a8a80;
			var counts:Object = {all: all.length};
			for each (var r:Object in all) counts[kindOf(r.item)] = (counts[kindOf(r.item)] || 0) + 1;
			var y:int = 128;
			for each (var k:Array in KINDS) { sideRow(k[1], int(counts[k[0]] || 0), kind == k[0], y, kindFn(k[0])); y += 26; }
			y += 10;
			note("<b>SORT BY</b>", y, 24, 0x7a8a80); y += 22;
			for each (var s:Array in SORTS) { sideRow(s[1], -1, sort == s[0], y, sortFn(s[0])); y += 26; }
			y += 10;
			note("<b>SHOW</b>", y, 24, 0x7a8a80); y += 22;
			check("Only for my class", mineOnly, y, function():void { mineOnly = !mineOnly; }); y += 24;
			check("Only what I can afford", affordOnly, y, function():void { affordOnly = !affordOnly; });

			// the search box
			var mx:int = 180;
			var mag:Shape = new Shape();
			mag.graphics.lineStyle(2, 0x9a9a9a);
			mag.graphics.drawCircle(0, 0, 5);
			mag.graphics.moveTo(3.5, 3.5); mag.graphics.lineTo(8, 8);
			mag.x = mx + 10; mag.y = 117;
			body.addChild(mag);
			search.x = mx + 24; search.y = 106;
			search.width = 260;
			body.addChild(search);
			if (!search.text) {
				var ph:TextField = Ui.text(13, 0x666666, false, "left", 240);
				ph.text = "Search by name or seller...";
				ph.x = mx + 28; ph.y = 108;
				ph.mouseEnabled = false;
				body.addChild(ph);
			}
			// what matches
			var list:Array = [];
			var cls:String = g.player ? g.player.cls.id : "";
			for each (r in all) {
				if (kind != "all" && kindOf(r.item) != kind) continue;
				if (mineOnly && Data.isGear(r.item) && !Data.canUse(r.item, cls)) continue;
				if (mineOnly && !Data.isGear(r.item) && r.item.kind != "stat") continue;
				if (affordOnly && r.price > g.gold) continue;
				if (query && String(r.item.name).toLowerCase().indexOf(query) < 0 && String(r.seller).toLowerCase().indexOf(query) < 0) continue;
				list.push(r);
			}
			if (sort == "low") list.sortOn("price", Array.NUMERIC);
			else if (sort == "high") list.sortOn("price", Array.NUMERIC | Array.DESCENDING);
			else if (sort == "rare") list.sort(function(a:Object, b:Object):int { return rank(b.item) - rank(a.item) || a.price - b.price; });
			var found:TextField = Ui.text(13, 0x9a9a9a, false, "right", 300, true);
			found.htmlText = list.length == all.length ? "<b>" + list.length + "</b> for sale" : "<b>" + list.length + "</b> of " + all.length + " match";
			found.x = W - 334; found.y = 108;
			body.addChild(found);

			startList(mx, 140, W - mx - 14, H - 140 - 14);
			if (!list.length) {
				var empty:TextField = Ui.text(15, 0x888888, false, "center", W - mx - 40, true);
				empty.text = all.length ? "Nothing matches. Try another kind or clear the search." : "Nothing is for sale yet. Be the first: list something under \"Sell an item\"!";
				empty.y = 60;
				content.addChild(empty);
			}
			var cols:int = 4;
			for (var i:int = 0; i < list.length; i++) {
				var c:Sprite = card(list[i], false);
				c.x = (i % cols) * (CARD_W + GAP);
				c.y = int(i / cols) * (CARD_H + GAP);
				content.addChild(c);
			}
			endList();
		}

		private function kindFn(k:String):Function { return function():void { kind = k; }; }
		private function sortFn(s:String):Function { return function():void { sort = s; }; }

		/** One listing as a card: rarity glow, the item, its seller and price, and Buy (or Cancel for yours). */
		private function card(row:Object, mineTab:Boolean):Sprite {
			var it:Object = row.item;
			var col:uint = Data.RARITY_COLORS[it.rarity] || 0x9a9a9a;
			var c:Sprite = new Sprite();
			var bg:Shape = new Shape();
			c.addChild(bg);
			var draw:Function = function(hover:Boolean):void {
				var gg:* = bg.graphics;
				gg.clear();
				gg.lineStyle(hover ? 2 : 1.5, hover ? col : mix(col, 0x2a2a2a, 0.45));
				gg.beginFill(hover ? 0x22282c : 0x1a1e22);
				gg.drawRoundRect(0, 0, CARD_W, CARD_H, 14, 14);
				gg.endFill();
				gg.lineStyle();
				var m:Matrix = new Matrix();
				m.createGradientBox(CARD_W - 4, 74, Math.PI / 2, 2, 2);
				gg.beginGradientFill(GradientType.LINEAR, [col, col], [hover ? 0.4 : 0.26, 0], [0, 255], m);
				gg.drawRoundRect(2, 2, CARD_W - 4, 74, 12, 12);
				gg.endFill();
				// a soft glow behind the item
				gg.beginFill(col, hover ? 0.22 : 0.12);
				gg.drawCircle(CARD_W / 2, 40, 28);
				gg.endFill();
			};
			draw(false);
			var bmp:Bitmap = new Bitmap(Sprites.icon(it));
			bmp.scaleX = bmp.scaleY = 1.5;
			bmp.x = int((CARD_W - bmp.width) / 2); bmp.y = int(40 - bmp.height / 2);
			c.addChild(bmp);
			var tier:TextField = Ui.text(13, Data.tierColor(it), true, "right", 40, true);
			tier.text = Data.tierLabel(it);
			tier.x = CARD_W - 48; tier.y = 6;
			c.addChild(tier);
			var nm:TextField = Ui.text(12, col == 0x9a9a9a ? 0xffffff : col, true, "center", CARD_W - 12, true);
			nm.htmlText = esc(it.name);
			nm.x = 6; nm.y = 76;
			if (nm.height > 34) { nm.htmlText = esc(String(it.name).slice(0, 34)) + "..."; }
			c.addChild(nm);
			var who:TextField = Ui.text(11, 0x888888, false, "center", CARD_W - 12, true);
			who.htmlText = mineTab ? (row.left > 86400000 ? Math.ceil(row.left / 86400000) + " days left" : row.left > 0 ? "last day" : "ending soon") : "by " + esc(row.seller);
			who.x = 6; who.y = 110;
			c.addChild(who);
			var pr:TextField = Ui.text(15, GOLD, true, "center", CARD_W - 12, true);
			pr.text = Ui.commas(row.price) + " g";
			pr.x = 6; pr.y = 124;
			c.addChild(pr);
			var can:Boolean = mineTab || (!row.mine && g.gold >= row.price);
			var btn:Sprite = Ui.button(mineTab ? "Cancel" : row.mine ? "Yours" : g.gold >= row.price ? "Buy" : "Need gold", CARD_W - 20, 26,
				mineTab ? function():void { g.marketCancel(row); } : row.mine ? function():void {} : function():void { g.marketBuy(row); }, 13);
			btn.x = 10; btn.y = CARD_H - 34;
			btn.alpha = can ? 1 : 0.45;
			c.addChild(btn);
			c.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); tip.visible = false; });
			c.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); showTip(it, mineTab ? "Your listing" : "Sold by " + row.seller + " for " + Ui.commas(row.price) + " gold", c); });
			return c;
		}

		private static function mix(a:uint, b:uint, t:Number):uint {
			var r:int = ((a >> 16) & 255) * (1 - t) + ((b >> 16) & 255) * t;
			var gg:int = ((a >> 8) & 255) * (1 - t) + ((b >> 8) & 255) * t;
			var bb:int = (a & 255) * (1 - t) + (b & 255) * t;
			return (r << 16) | (gg << 8) | bb;
		}

		private function showTip(it:Object, hint:String, near:Sprite):void {
			tip.show(it, hint, Data.isGear(it) && g.player && Data.canUse(it, g.player.cls.id) ? g.player[it.kind] : null);
			var p:Point = globalToLocal(near.localToGlobal(new Point(near.width + 6, 0)));
			if (p.x + tip.width > W - 4) p = globalToLocal(near.localToGlobal(new Point(-tip.width - 6, 0)));
			tip.x = Math.max(4, p.x);
			tip.y = Math.max(4, Math.min(H - tip.height - 4, p.y));
			tip.visible = true;
			setChildIndex(tip, numChildren - 1);
		}

		// ------------------------------------------------------------ the scrolling area
		private function startList(x:int, y:int, w:int, h:int):void {
			view = new Sprite();
			view.x = x; view.y = y;
			var mask:Shape = new Shape();
			mask.graphics.beginFill(0);
			mask.graphics.drawRect(0, -4, w, h + 4);
			mask.graphics.endFill();
			view.addChild(mask);
			content = new Sprite();
			content.mask = mask;
			view.addChild(content);
			viewH = h;
			bar = new Sprite();
			bar.x = w - 8;
			view.addChild(bar);
			body.addChild(view);
		}

		private function endList():void {
			// (a bit of room at the bottom, then the bar if there's more than fits)
			var most:Number = Math.max(0, content.height + 6 - viewH);
			scroll = Math.max(0, Math.min(most, scroll));
			content.y = -scroll;
			bar.graphics.clear();
			bar.removeEventListener(MouseEvent.MOUSE_DOWN, barDown);
			if (most <= 0) return;
			bar.graphics.beginFill(0xffffff, 0.08);
			bar.graphics.drawRoundRect(0, 0, 8, viewH, 6, 6);
			var th:Number = Math.max(30, viewH * viewH / (viewH + most));
			bar.graphics.beginFill(GOLD, 0.75);
			bar.graphics.drawRoundRect(0, (viewH - th) * scroll / most, 8, th, 6, 6);
			bar.graphics.endFill();
			bar.buttonMode = true;
			bar.addEventListener(MouseEvent.MOUSE_DOWN, barDown);
		}

		private function scrollBy(d:Number):void {
			if (!view) return;
			scroll += d;
			endList();
		}

		/** The stage a scroll-bar drag listens on (kept, so the listeners go even if we're closed mid-drag). */
		private var dragStage:flash.display.Stage;

		private function barDown(e:MouseEvent):void {
			dragY = bar.mouseY;
			dragStage = stage;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, barMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, barUp);
			barMove(null);
			e.stopPropagation();
		}

		private function barMove(e:MouseEvent):void {
			if (!view || !stage) return;
			var most:Number = Math.max(0, content.height + 6 - viewH);
			scroll = most * Math.max(0, Math.min(1, view.mouseY / viewH));
			endList();
		}

		private function barUp(e:MouseEvent):void {
			if (dragStage) { dragStage.removeEventListener(MouseEvent.MOUSE_MOVE, barMove); dragStage.removeEventListener(MouseEvent.MOUSE_UP, barUp); dragStage = null; }
		}

		// ------------------------------------------------------------ selling
		private function buildSell():void {
			var inv:Array = g.player ? g.player.inv : [];
			note("<b>YOUR INVENTORY</b>   <font color='#777777'>click an item to sell it</font>", 106, 24, 0x7a8a80);
			var n:int = 0;
			for (var i:int = 0; i < inv.length; i++) {
				var it:Object = inv[i];
				var b:Sprite = slotBox(it, i);
				b.x = 24 + (i % 4) * 62; b.y = 134 + int(i / 4) * 62;
				body.addChild(b);
				if (it && it.sid && !it.locked) n++;
			}
			var rows:int = Math.ceil(inv.length / 4);
			var tips:TextField = note("Starter gear can't be sold. Locked items (the padlock) have to be unlocked first: right-click them in your inventory.", 140 + rows * 62, 24, 0x777777);
			tips.width = 250;
			tips.textColor = 0x777777;
			// the selected item, big, with its price
			var px:int = 310, pw:int = W - px - 20;
			var panel:Shape = new Shape();
			Ui.panel(panel.graphics, 0, 0, pw, H - 124, 0x181c20, 0x3a4a40, 1);
			panel.x = px; panel.y = 106;
			body.addChild(panel);
			var s:Object = sel >= 0 && sel < inv.length ? inv[sel] : null;
			if (!s || !s.sid || s.locked) {
				sel = -1;
				var pick:TextField = Ui.text(16, 0x8a8a8a, false, "center", pw - 40, true);
				pick.text = n ? "Pick an item on the left to sell it." : "Nothing in your inventory can be sold right now.";
				pick.x = px + 20; pick.y = 260;
				body.addChild(pick);
				return;
			}
			var col:uint = Data.RARITY_COLORS[s.rarity] || 0xffffff;
			var glow:Shape = new Shape();
			glow.graphics.beginFill(col, 0.14);
			glow.graphics.drawCircle(0, 0, 48);
			glow.graphics.endFill();
			glow.x = px + 70; glow.y = 176;
			body.addChild(glow);
			var big:Bitmap = new Bitmap(Sprites.icon(s));
			big.scaleX = big.scaleY = 2;
			big.x = px + 70 - big.width / 2; big.y = 176 - big.height / 2;
			body.addChild(big);
			var nm:TextField = Ui.text(18, col, true, "left", pw - 150, true);
			nm.htmlText = esc(s.name) + "  <font size='14' color='" + Ui.hex(Data.tierColor(s)) + "'>" + Data.tierLabel(s) + "</font>";
			nm.x = px + 136; nm.y = 130;
			body.addChild(nm);
			var desc:TextField = Ui.text(12, 0xbbbbbb, false, "left", pw - 150, true);
			desc.htmlText = Data.describe(s);
			desc.x = px + 136; desc.y = nm.y + nm.height + 2;
			body.addChild(desc);
			// what it's worth (below the description, however long it is)
			var y:int = Math.max(250, desc.y + desc.height + 12);
			var same:Array = [];
			for each (var r:Object in v.list) if (r.item.name == s.name) same.push(r.price);
			same.sort(Array.NUMERIC);
			var ref:TextField = Ui.text(13, 0xaaaaaa, false, "left", pw - 40, true);
			ref.htmlText = "The merchant would pay <font color='#ffd75e'>" + Ui.commas(Data.sellValue(s)) + " g</font>." +
				(same.length ? "  Cheapest " + esc(s.name) + " for sale: <font color='#ffd75e'>" + Ui.commas(same[0]) + " g</font> (" + same.length + " listed)." : "  Nobody else is selling one.");
			ref.x = px + 20; ref.y = y;
			body.addChild(ref);
			y += ref.height + 14;
			var pl:TextField = Ui.text(15, 0xffffff, true, "left", 120, true);
			pl.text = "Your price:";
			pl.x = px + 20; pl.y = y + 3;
			body.addChild(pl);
			price.x = px + 130; price.y = y;
			body.addChild(price);
			var gl:TextField = Ui.text(15, GOLD, true, "left", 30, true);
			gl.text = "g";
			gl.x = px + 276; gl.y = y + 3;
			body.addChild(gl);
			// quick prices
			var qx:int = px + 20;
			y += 36;
			for each (var q:int in [100, 500, 1000, 5000, 10000]) {
				var qb:Sprite = Ui.button("+" + (q >= 1000 ? q / 1000 + "k" : String(q)), 62, 24, addFn(q), 12);
				qb.x = qx; qb.y = y;
				body.addChild(qb);
				qx += 68;
			}
			var clr:Sprite = Ui.button("Clear", 62, 24, function():void { price.text = ""; build(); }, 12);
			clr.x = qx; clr.y = y;
			body.addChild(clr);
			y += 40;
			var pv:int = int(price.text);
			var gets:TextField = Ui.text(14, pv > 0 ? 0x9cff7a : 0x8a8a8a, false, "left", pw - 40, true);
			gets.htmlText = pv > 0 ? "When it sells you get <b>" + Ui.commas(int(pv * (1 - v.fee))) + " gold</b> (the Marketplace keeps " + int(v.fee * 100) + "%)."
				: "Type a price, or use the buttons.";
			gets.x = px + 20; gets.y = y;
			body.addChild(gets);
			y += 34;
			var list:Sprite = bigButton("List it for sale", pw - 40, 44, GREEN, function():void {
				var p:int = int(price.text);
				if (p < 1) { g.msg("Type a price in gold first.", 0xff8080); return; }
				if (g.marketList(sel, p)) { sel = -1; price.text = ""; }
			});
			list.x = px + 20; list.y = y;
			list.alpha = pv > 0 ? 1 : 0.5;
			body.addChild(list);
			var info:TextField = Ui.text(11, 0x777777, false, "center", pw - 40, true);
			info.text = "Up to " + v.max + " listings at once, for a week each. Unsold items come back to you under My listings.";
			info.x = px + 20; info.y = y + 52;
			body.addChild(info);
		}

		private function addFn(q:int):Function { return function():void { price.text = String(Math.min(999999999, int(price.text) + q)); build(); }; }

		private function slotBox(it:Object, i:int):Sprite {
			var b:Sprite = new Sprite();
			var ok:Boolean = it && it.sid && !it.locked;
			var on:Boolean = i == sel;
			b.graphics.lineStyle(on ? 3 : 1, on ? GREEN : 0x1a1a1a);
			b.graphics.beginFill(!it ? 0x2a2e32 : ok ? 0x4a4e52 : 0x3a2a2a);
			b.graphics.drawRoundRect(0, 0, 56, 56, 10, 10);
			b.graphics.endFill();
			if (!it) return b;
			var bmp:Bitmap = new Bitmap(Sprites.icon(it));
			bmp.x = int((56 - bmp.width) / 2); bmp.y = int((56 - bmp.height) / 2);
			if (!ok) bmp.alpha = 0.45;
			b.addChild(bmp);
			var tg:TextField = Ui.text(12, Data.tierColor(it), true, "right", 30, true);
			tg.text = Data.tierLabel(it);
			tg.x = 22; tg.y = 36;
			b.addChild(tg);
			if (it.locked) {
				var lk:Shape = new Shape();
				lk.graphics.lineStyle(1.5, GOLD);
				lk.graphics.drawRoundRect(-3.5, -9, 7, 9, 6, 6);
				lk.graphics.lineStyle(1, 0x1a1408);
				lk.graphics.beginFill(GOLD);
				lk.graphics.drawRoundRect(-6, -4, 12, 9, 3, 3);
				lk.graphics.endFill();
				lk.x = 46; lk.y = 13;
				b.addChild(lk);
			}
			b.buttonMode = true; b.mouseChildren = false;
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
				showTip(it, !it.sid ? "Starter gear can't be sold." : it.locked ? "Locked: right-click it in your inventory to unlock it." : "Click to sell this.", b);
			});
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { tip.visible = false; });
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				if (!ok) return;
				sel = i;
				build();
				if (stage) stage.focus = price;
			});
			return b;
		}

		private function bigButton(label:String, w:int, h:int, col:uint, fn:Function):Sprite {
			var b:Sprite = new Sprite();
			var draw:Function = function(hover:Boolean):void {
				b.graphics.clear();
				var m:Matrix = new Matrix();
				m.createGradientBox(w, h, Math.PI / 2);
				b.graphics.lineStyle(2, hover ? 0xffffff : mix(col, 0xffffff, 0.3));
				b.graphics.beginGradientFill(GradientType.LINEAR, [mix(col, 0x000000, hover ? 0.2 : 0.35), mix(col, 0x000000, hover ? 0.5 : 0.65)], [1, 1], [0, 255], m);
				b.graphics.drawRoundRect(0, 0, w, h, 14, 14);
				b.graphics.endFill();
			};
			draw(false);
			var tf:TextField = Ui.text(18, 0xffffff, true, "center", w, true);
			tf.text = label;
			tf.y = (h - tf.height) / 2;
			b.addChild(tf);
			b.buttonMode = true; b.mouseChildren = false;
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { fn(); });
			return b;
		}

		// ------------------------------------------------------------ your listings
		private function buildMine():void {
			// takings and returned items waiting
			var box:Shape = new Shape();
			var waiting:Boolean = v.earned > 0 || v.returns > 0;
			Ui.panel(box.graphics, 0, 0, W - 40, 64, waiting ? 0x1f3a28 : 0x181c20, waiting ? GOLD : 0x3a4a40, 1);
			box.x = 20; box.y = 106;
			body.addChild(box);
			var wt:TextField = Ui.text(15, 0xffffff, true, "left", 480, true);
			wt.htmlText = waiting ? "Waiting for you: <font color='#ffd75e'>" + Ui.commas(v.earned) + " gold</font>" + (v.returns ? " and " + v.returns + " returned item" + (v.returns == 1 ? "" : "s") : "")
				: "<font color='#9a9a9a'>Nothing waiting. Gold from sales lands here, even while you're offline.</font>";
			wt.x = 36; wt.y = 116;
			body.addChild(wt);
			var sales:Array = v.sales || [];
			var st:TextField = Ui.text(11, 0x9cff7a, false, "left", 500, true);
			var lines:Array = [];
			for (var i:int = 0; i < Math.min(2, sales.length); i++) lines.push("Sold " + esc(sales[i].name) + " for " + Ui.commas(sales[i].price) + " g (you got " + Ui.commas(sales[i].got) + " g)");
			st.htmlText = lines.join("<br>");
			st.x = 36; st.y = 138;
			body.addChild(st);
			if (waiting) {
				var cb:Sprite = bigButton("Collect", 150, 40, GOLD, function():void { g.marketCollect(); });
				cb.x = W - 190; cb.y = 118;
				body.addChild(cb);
			}
			var mine:Array = [];
			for each (var r:Object in v.list) if (r.mine) mine.push(r);
			var hd:TextField = note("<b>FOR SALE</b>   <font color='#777777'>" + mine.length + " of " + v.max + "</font>", 180, 24, 0x7a8a80);
			hd.textColor = 0x7a8a80;
			startList(24, 206, W - 38, H - 206 - 14);
			if (!mine.length) {
				var e:TextField = Ui.text(15, 0x888888, false, "center", W - 60, true);
				e.text = "You have nothing for sale. Pick something under \"Sell an item\".";
				e.y = 60;
				content.addChild(e);
			}
			var cols:int = 5;
			for (i = 0; i < mine.length; i++) {
				var c:Sprite = card(mine[i], true);
				c.x = (i % cols) * (CARD_W + GAP);
				c.y = int(i / cols) * (CARD_H + GAP);
				content.addChild(c);
			}
			endList();
		}
	}
}
