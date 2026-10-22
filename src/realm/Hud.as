package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.getTimer;

	/** The right-hand sidebar, laid out like RotMG. */
	public class Hud extends Sprite {
		public static const W:int = 240;
		private static const MINI_H:int = 176;
		private static const ZOOMS:Array = [1, 2, 4];
		private static const MINI_X:int = 9, MINI_Y:int = 7, MINI_W:int = W - 16;
		public static const BG_TOP:uint = 0x1c1530;
		public static const BG_BOT:uint = 0x0d0a16;
		public static const GOLD:uint = 0xb8913e;
		public static const GOLD_HI:uint = 0xf2d68a;
		public static const EDGE:uint = 0x4a3c70;

		private static const I_TEMPLE:Array = ["...WW...", "..WWWW..", "WWWWWWWW", ".W.WW.W.", ".W.WW.W.", ".W.WW.W.", "WWWWWWWW", "........"];
		private static const I_PACK:Array = ["..WWWW..", ".W....W.", "WWWWWWWW", "WWWDDWWW", "WWWWWWWW", "WWWWWWWW", ".WWWWWW.", "........"];
		private static const I_STAR:Array = ["...W....", "...W....", ".WWWWW..", "..WWW...", "..W.W...", ".W...W..", "........", "........"];
		private static const I_PEOPLE:Array = ["..W..W..", ".WWWWWW.", "..W..W..", "........", ".WW..WW.", "WWWWWWWW", "WWWWWWWW", "........"];
		private static const I_BOOK:Array = ["WWW.WWW.", "W.WWW.W.", "W.WWW.W.", "WWWWWWW.", "W.WWW.W.", "W.WWW.W.", "WWW.WWW.", "........"];
		private static const I_CHART:Array = ["........", "......W.", "......W.", "...W..W.", "...W..W.", "W..W..W.", "W..W..W.", "WWWWWWWW"];

		private var g:Game;
		private var mini:BitmapData;
		private var miniDots:Shape;
		/** Over the minimap: hover a player for their name, click to teleport to them. */
		private var miniHit:Sprite;
		private var miniLabel:TextField;
		/** The players drawn on the minimap last time: {rp, x, y}. */
		private var marks:Array = [];
		/** Which way you're heading (radians), and where you were, for your own arrow. */
		private var myHeading:Number = -Math.PI / 2;
		private var lastPx:Number = NaN, lastPy:Number = NaN;
		private var zoom:int = 1;
		private var frameN:int = 0;
		private var nameTf:TextField;
		private var subTf:TextField;
		private var zoneTf:TextField, onlineTf:TextField;
		private var medal:Shape;
		private var lvlBadge:TextField;
		private var lastXpFrac:Number = -1, lastLevel:int = -1;
		private var bagLegend:Sprite, statusLegend:Sprite;
		private var lastFame:int = -1;
		/** Over the medallion: the low-HP throb and the level-up flash. */
		private var medalFx:Shape;
		private var lvlFlash:Number = 0;
		private var sparks:Array = [];
		private var fog:BitmapData;
		private var btnHint:TextField;
		// the status panel shown where the loot grid goes when no bag is near
		private var statusBox:Sprite;
		private var petPic:Bitmap;
		private var petTf:TextField, blessTf:TextField, luckTf:TextField;
		private var portrait:Bitmap;
		private var lvlBar:Bar, hpBar:Bar, mpBar:Bar, ptBar:Bar, sgBar:Bar;
		private var equip:Vector.<Slot> = new Vector.<Slot>();
		private var invSlots:Vector.<Slot> = new Vector.<Slot>();
		private var bagSlots:Vector.<Slot> = new Vector.<Slot>();
		private var hpPot:PotSlot, mpPot:PotSlot;
		private var invPage:Sprite, statPage:Sprite, skillPage:Sprite;
		private var skillTf:TextField;
		private var lastSkills:String = "";
		private var statTf:TextField;
		private var luckTip:Sprite, luckTipTf:TextField;
		private var tabs:Array = [];
		private var packBtn:Sprite;
		private var packTf:TextField;
		private var bagBox:Shape;
		private var tip:Tooltip;
		private var hover:Slot;
		// drag and drop
		private var dragSlot:Slot;
		private var dragging:Boolean = false;
		private var dragGhost:Bitmap;
		private var downX:Number, downY:Number;
		private var lastStats:String = "";
		private var lastBag:LootBag;

		public function Hud(g:Game) {
			this.g = g;
			// deep violet, darker toward the bottom, with a gold seam on the left
			var bm:Matrix = new Matrix();
			bm.createGradientBox(W, Ui.H, Math.PI / 2);
			graphics.beginGradientFill("linear", [BG_TOP, BG_BOT], [1, 1], [0, 255], bm);
			graphics.drawRect(0, 0, W, Ui.H);
			graphics.endFill();
			// a faint diamond lattice
			graphics.lineStyle(1, 0x8a70c0, 0.05);
			for (var dl:int = -Ui.H; dl < W; dl += 24) {
				graphics.moveTo(dl, 0); graphics.lineTo(dl + Ui.H, Ui.H);
				graphics.moveTo(dl + Ui.H, 0); graphics.lineTo(dl, Ui.H);
			}
			graphics.lineStyle();
			graphics.beginFill(0x000000);
			graphics.drawRect(0, 0, 2, Ui.H);
			graphics.endFill();
			graphics.beginFill(GOLD, 0.7);
			graphics.drawRect(2, 0, 1, Ui.H);
			graphics.endFill();

			// --- minimap, set in a gold frame
			mini = new BitmapData(MINI_W, MINI_H - 14, false, 0);
			var miniBmp:Bitmap = new Bitmap(mini);
			miniBmp.x = MINI_X; miniBmp.y = MINI_Y;
			addChild(miniBmp);
			// unexplored ground: violet fog with a faint lattice (copied under the map each draw)
			fog = new BitmapData(mini.width, mini.height, false, 0x100c1a);
			var fs:Shape = new Shape();
			fs.graphics.lineStyle(1, 0x231b38);
			for (var fl:int = -mini.height; fl < mini.width; fl += 12) {
				fs.graphics.moveTo(fl, 0); fs.graphics.lineTo(fl + mini.height, mini.height);
				fs.graphics.moveTo(fl + mini.height, 0); fs.graphics.lineTo(fl, mini.height);
			}
			fog.draw(fs);
			// darker toward the edges
			var vig:Shape = new Shape();
			var vm:Matrix = new Matrix();
			vm.createGradientBox(mini.width * 1.3, mini.height * 1.3, 0, -mini.width * 0.15, -mini.height * 0.15);
			vig.graphics.beginGradientFill("radial", [0x05030a, 0x05030a], [0, 0.7], [140, 255], vm);
			vig.graphics.drawRect(0, 0, mini.width, mini.height);
			vig.graphics.endFill();
			vig.x = MINI_X; vig.y = MINI_Y;
			addChild(vig);
			miniDots = new Shape();
			miniDots.x = MINI_X; miniDots.y = MINI_Y;
			addChild(miniDots);
			var mf:Shape = new Shape();
			frame(mf.graphics, MINI_X - 1, MINI_Y - 1, MINI_W + 2, mini.height + 2);
			// the place name on a dark ribbon along the bottom
			mf.graphics.beginFill(0x000000, 0.55);
			mf.graphics.drawRect(MINI_X, MINI_Y + mini.height - 17, MINI_W, 17);
			mf.graphics.endFill();
			addChild(mf);
			zoneTf = Ui.text(11, GOLD_HI, true, "left", 0, true);
			zoneTf.x = MINI_X + 4; zoneTf.y = MINI_Y + mini.height - 17;
			addChild(zoneTf);
			onlineTf = Ui.text(11, 0xb8a8e0, true, "right", 90, true);
			onlineTf.x = MINI_X + MINI_W - 94; onlineTf.y = zoneTf.y;
			addChild(onlineTf);
			miniHit = new Sprite();
			miniHit.graphics.beginFill(0, 0);
			miniHit.graphics.drawRect(0, 0, MINI_W, mini.height);
			miniHit.graphics.endFill();
			miniHit.x = MINI_X; miniHit.y = MINI_Y;
			miniHit.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void { miniHover(e.localX, e.localY); });
			miniHit.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { miniLabel.visible = false; miniHit.buttonMode = false; });
			miniHit.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				var m:Object = markAt(e.localX, e.localY);
				if (m) g.teleportTo(m.rp);
			});
			addChild(miniHit);
			miniLabel = Ui.text(12, 0xffffff, true, "left", 0, true);
			miniLabel.autoSize = "left";
			miniLabel.background = true;
			miniLabel.backgroundColor = 0x14141c;
			miniLabel.border = true;
			miniLabel.borderColor = 0x55556a;
			miniLabel.visible = false;
			miniLabel.mouseEnabled = false;
			addChild(miniLabel);
			addChild(zoomButton("+", MINI_X + MINI_W - 22, MINI_Y + 4, 1));
			addChild(zoomButton("-", MINI_X + MINI_W - 22, MINI_Y + 26, -1));
			setChildIndex(miniLabel, numChildren - 1);

			// --- name row: portrait medallion (its ring fills with XP), name and class, buttons
			var y:int = MINI_H + 4;
			medal = new Shape();
			medal.x = 25; medal.y = y + 19;
			addChild(medal);
			portrait = new Bitmap(Sprites.get(g.player.spriteId));
			portrait.scaleX = portrait.scaleY = 0.62;
			portrait.x = medal.x - portrait.width / 2;
			portrait.y = medal.y - portrait.height / 2;
			addChild(portrait);
			medalFx = new Shape();
			medalFx.x = medal.x; medalFx.y = medal.y;
			lvlBadge = Ui.text(10, 0xffffff, true, "center", 20, true);
			lvlBadge.x = medal.x + 6; lvlBadge.y = medal.y + 8;
			addChild(lvlBadge);
			nameTf = Ui.text(20, 0xffffff, true, "left", 0, true);
			nameTf.x = 50;
			nameTf.y = y - 2;
			addChild(nameTf);
			subTf = Ui.text(11, 0xb8a8e0, true, "left", 0, true);
			subTf.x = 51;
			subTf.y = y + 23;
			addChild(subTf);
			addChild(iconButton(I_TEMPLE, W - 20, y + 9, "Nexus", function():void { g.nexus(); }));
			addChild(iconButton(I_PEOPLE, W - 50, y + 9, "Friends & Guild", function():void { g.toggleSocial(); }));
			addChild(iconButton(I_BOOK, W - 80, y + 9, "Wiki", function():void { g.toggleWiki(); }));
			addChild(medalFx);

			// --- bars: a thin XP line, then HP and MP, then Ward and Fervor
			y = MINI_H + 46;
			lvlBar = new Bar(228, 10, 0x9a6ae0, 0, 9, "", "center");
			lvlBar.x = 8; lvlBar.y = y;
			addChild(lvlBar);
			hpBar = new Bar(228, 23, 0xe0303e, 0, 14, "HP");
			hpBar.x = 8; hpBar.y = y + 14;
			addChild(hpBar);
			mpBar = new Bar(228, 23, 0x3a64f0, 0, 14, "MP");
			mpBar.x = 8; mpBar.y = y + 41;
			addChild(mpBar);
			hpBar.trail = mpBar.trail = true;
			// Ward (WD, from Warding) and Fervor (FV) bars
			ptBar = new Bar(112, 15, 0xdcdcf4, 0, 10, "WD", "left");
			ptBar.x = 8; ptBar.y = y + 68;
			addChild(ptBar);
			sgBar = new Bar(112, 15, 0xe0b030, 0, 10, "FV", "left");
			sgBar.x = 124; sgBar.y = y + 68;
			addChild(sgBar);

			// --- equipment
			y = MINI_H + 138;
			var eq:Shape = new Shape();
			glass(eq.graphics, 4, y, 232, 58);
			addChild(eq);
			addChild(legend("EQUIPMENT", y));
			var kinds:Array = ["weapon", "ability", "armor", "ring"];
			for (var i:int = 0; i < 4; i++) {
				equip.push(makeSlot(kinds[i], i, 10 + i * 56, y + 6, false));
				addChild(equip[i]);
			}

			// --- tabs (icon buttons)
			y += 62;
			tabs.push(makeTab(I_PACK, 8, y, 0));
			tabs.push(makeTab(I_CHART, 46, y, 1));
			tabs.push(makeTab(I_STAR, 84, y, 2));
			// backpack page toggle
			packBtn = new Sprite();
			glass(packBtn.graphics, 0, 0, 104, 24, GOLD, 8);
			packTf = Ui.text(12, GOLD_HI, true, "center", 104, true);
			packTf.y = 3;
			packBtn.addChild(packTf);
			packBtn.x = 128; packBtn.y = y;
			packBtn.buttonMode = true;
			packBtn.mouseChildren = false;
			packBtn.visible = false;
			packBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				var pl:Player = g.player;
				if (!pl.backpack) return;
				pl.packPage = 1 - pl.packPage;
				selectTab(0);
				refresh();
			});
			addChild(packBtn);

			// --- inventory page
			y += 28;
			invPage = new Sprite();
			addChild(invPage);
			var s:Slot;
			for (i = 0; i < 8; i++) {
				s = makeSlot("inv", i, 10 + (i % 4) * 56, y + int(i / 4) * 52, true);
				invPage.addChild(s);
				invSlots.push(s);
			}
			hpPot = new PotSlot(true);
			hpPot.x = 10; hpPot.y = y + 104;
			hpPot.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.slotClick("pot", 0, false); });
			invPage.addChild(hpPot);
			mpPot = new PotSlot(false);
			mpPot.x = 122; mpPot.y = y + 104;
			mpPot.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { g.slotClick("pot", 1, false); });
			invPage.addChild(mpPot);

			// --- stats page
			statPage = new Sprite();
			glass(statPage.graphics, 4, y - 2, 232, 140);
			statTf = Ui.text(13, 0xdddddd, true, "left", 214);
			statTf.x = 14; statTf.y = y + 2;
			statPage.addChild(statTf);
			statPage.visible = false;
			addChild(statPage);
			// hovering the LUCK line: where all your loot luck comes from
			luckTip = new Sprite();
			luckTip.mouseEnabled = luckTip.mouseChildren = false;
			luckTipTf = Ui.text(12, 0xeeeeee, false, "left", 230, true);
			luckTipTf.x = 10; luckTipTf.y = 8;
			luckTip.addChild(luckTipTf);
			luckTip.visible = false;
			addChild(luckTip);
			// (the text itself takes no mouse: the panel behind it does)
			statPage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void {
				var line:int = statTf.getLineIndexAtPoint(statTf.mouseX, statTf.mouseY);
				if (line == 5) showLuckTip(); else luckTip.visible = false;
			});
			statPage.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { luckTip.visible = false; });

			// --- skill tree page (Awakening)
			skillPage = new Sprite();
			glass(skillPage.graphics, 4, y - 2, 232, 140);
			skillTf = Ui.text(12, 0x80e0ff, false, "left", 220);
			skillTf.x = 10; skillTf.y = y;
			skillPage.addChild(skillTf);
			var openTree:Sprite = Ui.button("Open Skill Tree  [T]", 200, 26, function():void { g.toggleSkills(); }, 13);
			openTree.x = 20; openTree.y = y + 104;
			skillPage.addChild(openTree);
			skillPage.visible = false;
			addChild(skillPage);

			// --- loot bag grid (always shown, like the backpack area)
			y += 142;
			bagBox = new Shape();
			addChild(bagBox);
			bagLegend = legend("LOOT", y);
			addChild(bagLegend);
			statusLegend = legend("STATUS", y);
			addChild(statusLegend);
			statusBox = new Sprite();
			statusBox.mouseEnabled = statusBox.mouseChildren = false;
			petPic = new Bitmap();
			petPic.x = 12; petPic.y = y + 8;
			statusBox.addChild(petPic);
			petTf = Ui.text(12, 0xffffff, true, "left", 0, true);
			petTf.x = 44; petTf.y = y + 12;
			statusBox.addChild(petTf);
			blessTf = Ui.text(11, 0xb8a8e0, true, "left", 216, true);
			blessTf.x = 12; blessTf.y = y + 40;
			statusBox.addChild(blessTf);
			luckTf = Ui.text(11, 0xb8a8e0, true, "left", 216, true);
			luckTf.x = 12; luckTf.y = y + 60;
			statusBox.addChild(luckTf);
			addChild(statusBox);
			for (i = 0; i < 8; i++) {
				s = makeSlot("bag", i, 12 + (i % 4) * 56, y + 4 + int(i / 4) * 44, false);
				s.scaleX = s.scaleY = 0.84;
				addChild(s);
				bagSlots.push(s);
			}
			drawBagBox(false, y);

			tip = new Tooltip();
			addChild(tip);
			// the panel's vector art drawn once into bitmaps: re-rasterised every frame, the gradients and
			// lattice cost more than the whole game view (only what's redrawn often stays vector)
			bake(this);
			for (var ci:int = 0; ci < numChildren; ci++) {
				var cs:Shape = getChildAt(ci) as Shape;
				if (cs && cs != miniDots && cs != medalFx) cs.cacheAsBitmap = true;
			}
		}

		/** Moves what's drawn on a sprite's own graphics into a child shape kept as a bitmap. */
		public static function bake(sp:Sprite):void {
			var bg:Shape = new Shape();
			bg.graphics.copyFrom(sp.graphics);
			sp.graphics.clear();
			bg.cacheAsBitmap = true;
			sp.addChildAt(bg, 0);
		}

		private var bagY:int;

		private function drawBagBox(active:Boolean, y:int = -1):void {
			if (y >= 0) bagY = y;
			bagBox.graphics.clear();
			glass(bagBox.graphics, 4, bagY, 232, Ui.H - bagY - 4, active ? GOLD : EDGE, 10, active ? 0x2c2014 : 0);
			if (!active) {
				// thin dividers between the status rows
				for each (var dy:int in [34, 56]) {
					bagBox.graphics.beginFill(EDGE, 0.5);
					bagBox.graphics.drawRect(14, bagY + dy, 212, 1);
					bagBox.graphics.endFill();
				}
			}
			bagLegend.visible = active;
			statusLegend.visible = statusBox.visible = !active;
			for each (var s:Slot in bagSlots) s.visible = active;
		}

		/** A dark glass panel: a soft top-lit gradient, a violet (or gold) edge and a thin highlight. */
		public static function glass(g:*, x:Number, y:Number, w:Number, h:Number, edge:uint = EDGE, r:Number = 10, tint:uint = 0):void {
			var m:Matrix = new Matrix();
			m.createGradientBox(w, h, Math.PI / 2, x, y);
			g.lineStyle(1, 0x05030a);
			g.beginGradientFill("linear", tint ? [tint, 0x0e0a16] : [0x241c38, 0x120e1e], [0.92, 0.92], [0, 255], m);
			g.drawRoundRect(x, y, w, h, r * 2, r * 2);
			g.endFill();
			g.lineStyle(1, edge, 0.85);
			g.drawRoundRect(x + 1, y + 1, w - 2, h - 2, r * 2 - 2, r * 2 - 2);
			g.lineStyle(1, 0xffffff, 0.07);
			g.moveTo(x + r, y + 2); g.lineTo(x + w - r, y + 2);
			g.lineStyle();
		}

		/** A gold frame with small diamonds at the corners. */
		private static function frame(g:*, x:Number, y:Number, w:Number, h:Number):void {
			g.lineStyle(3, 0x05030a);
			g.drawRect(x - 1, y - 1, w + 2, h + 2);
			g.lineStyle(1, GOLD);
			g.drawRect(x, y, w, h);
			g.lineStyle();
			for each (var c:Array in [[x, y], [x + w, y], [x, y + h], [x + w, y + h]]) diamond(g, c[0], c[1], 4);
		}

		private static function diamond(g:*, x:Number, y:Number, r:Number):void {
			g.lineStyle(1, 0x05030a);
			g.beginFill(GOLD_HI);
			g.moveTo(x, y - r); g.lineTo(x + r, y); g.lineTo(x, y + r); g.lineTo(x - r, y); g.lineTo(x, y - r);
			g.endFill();
			g.lineStyle();
		}

		/** A small spaced-out gold caption sitting on a panel's top edge. */
		private function legend(label:String, y:int):Sprite {
			var sp:Sprite = new Sprite();
			sp.mouseEnabled = sp.mouseChildren = false;
			var tf:TextField = Ui.text(9, GOLD_HI, true, "left", 0, true);
			tf.text = label.split("").join(" ");
			tf.x = (W - tf.width) / 2; tf.y = y - tf.height / 2;
			var gr:* = sp.graphics;
			gr.beginFill(BG_TOP);
			gr.drawRect(tf.x - 6, y - 2, tf.width + 12, 4);
			gr.endFill();
			diamond(gr, tf.x - 8, y, 2.5);
			diamond(gr, tf.x + tf.width + 8, y, 2.5);
			sp.addChild(tf);
			return sp;
		}

		private function pix(rows:Array, color:uint, scale:int):BitmapData {
			return Sprites.build(rows, {W: color, D: 0x303030}, scale, 1);
		}

		/** A round gold button centred on (x, y), with its name shown on hover. */
		private function iconButton(rows:Array, x:int, y:int, label:String, onClick:Function):Sprite {
			var b:Sprite = new Sprite();
			var draw:Function = function(hover:Boolean):void {
				var m:Matrix = new Matrix();
				m.createGradientBox(26, 26, Math.PI / 2, -13, -13);
				b.graphics.clear();
				b.graphics.lineStyle(1, 0x05030a);
				b.graphics.beginGradientFill("linear", hover ? [0x4a3878, 0x221a38] : [0x2e2448, 0x140f22], [1, 1], [0, 255], m);
				b.graphics.drawCircle(0, 0, 13);
				b.graphics.endFill();
				b.graphics.lineStyle(1, hover ? GOLD_HI : GOLD);
				b.graphics.drawCircle(0, 0, 12);
				b.graphics.lineStyle();
				b.filters = hover ? [new GlowFilter(GOLD_HI, 0.6, 8, 8, 2)] : [];
			};
			draw(false);
			var bmp:Bitmap = new Bitmap(pix(rows, 0xf2e6c8, 2));
			bmp.x = -int(bmp.width / 2); bmp.y = -int(bmp.height / 2);
			b.addChild(bmp);
			b.x = x; b.y = y;
			b.buttonMode = true;
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onClick(); });
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
				draw(true);
				if (!btnHint) {
					btnHint = Ui.text(11, GOLD_HI, true, "left", 0, true);
					btnHint.background = true;
					btnHint.backgroundColor = 0x120e1e;
					btnHint.border = true;
					btnHint.borderColor = GOLD;
				}
				btnHint.text = " " + label + " ";
				btnHint.x = Math.min(W - btnHint.width - 4, b.x - btnHint.width / 2);
				btnHint.y = b.y + 16;
				addChild(btnHint);
			});
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
				draw(false);
				if (btnHint && btnHint.parent) removeChild(btnHint);
			});
			return b;
		}

		private function zoomButton(label:String, x:int, y:int, dir:int):Sprite {
			var b:Sprite = new Sprite();
			b.graphics.lineStyle(1, GOLD, 0.9);
			b.graphics.beginFill(0x120e1e, 0.8);
			b.graphics.drawCircle(9, 9, 9);
			b.graphics.endFill();
			var t:TextField = Ui.text(15, GOLD_HI, true, "center", 18);
			t.text = label;
			t.y = -2;
			b.addChild(t);
			b.x = x; b.y = y;
			b.buttonMode = true;
			b.mouseChildren = false;
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				zoom = Math.max(0, Math.min(ZOOMS.length - 1, zoom + dir));
				drawMinimap();
			});
			return b;
		}

		private function refreshSkills(p:Player):void {
			var key:String = p.skillPoints + "|" + p.ascXp + "|" + p.level + "|" + p.highStakes + "|" + p.bloodStacks;
			for each (var sk:Object in Data.SKILLS) key += p.rank(sk.id);
			if (key == lastSkills) return;
			lastSkills = key;
			var out:String = "<b>Skill points: " + p.skillPoints + "</b>" + (p.level >= Player.MAX_LEVEL ? "  (next " + p.ascXp + "/" + p.nextPointXp + " XP)" : "") + "\n";
			// points spent in each branch, two to a line, then the capstones you have
			var caps:Array = [];
			for (var b:int = 0; b < Data.SKILL_BRANCHES.length; b++) {
				var br:Object = Data.SKILL_BRANCHES[b];
				out += "<font color='" + Ui.hex(br.col) + "'><b>" + br.name + "</b></font> " + Data.skillSpent(p.skills, b) + (b % 2 ? "\n" : "    ");
				for each (sk in Data.SKILLS) if (sk.b == b && sk.cap && p.rank(sk.id) > 0) caps.push(sk.name);
			}
			if (Data.SKILL_BRANCHES.length % 2) out += "\n";
			if (caps.length) out += "<font color='#ffd75e'>" + caps.join(", ") + "</font>\n";
			if (p.rank("highstakes") > 0) out += "<font color='#ffd040'>High Stakes: " + (p.highStakes ? "ON" : "off") + "</font>\n";
			if (p.bloodStacks > 0) out += "<font color='#ff6a50'>Bloodlust x" + p.bloodStacks + "</font>";
			skillTf.htmlText = out;
		}

		private function makeTab(rows:Array, x:int, y:int, idx:int):Sprite {
			var t:Sprite = new Sprite();
			var bmp:Bitmap = new Bitmap(pix(rows, 0xe8e8e8, 2));
			bmp.x = (32 - bmp.width) / 2;
			bmp.y = (24 - bmp.height) / 2;
			t.addChild(bmp);
			t.x = x; t.y = y;
			t.buttonMode = true;
			t.mouseChildren = false;
			t.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { selectTab(idx); });
			addChild(t);
			drawTab(t, idx == 0);
			return t;
		}

		private function drawTab(t:Sprite, on:Boolean):void {
			t.graphics.clear();
			glass(t.graphics, 0, 0, 32, 24, on ? GOLD : EDGE, 7, on ? 0x3c2e5c : 0);
			if (on) {
				t.graphics.beginFill(GOLD_HI);
				t.graphics.drawRect(8, 21, 16, 2);
				t.graphics.endFill();
			}
		}

		private function selectTab(idx:int):void {
			for (var i:int = 0; i < tabs.length; i++) drawTab(tabs[i], i == idx);
			invPage.visible = idx == 0;
			statPage.visible = idx == 1;
			skillPage.visible = idx == 2;
			lastSkills = "";
			lastStats = "";
		}

		private function makeSlot(kind:String, idx:int, x:int, y:int, numbered:Boolean):Slot {
			var s:Slot = new Slot(kind, idx, numbered);
			s.x = x; s.y = y;
			s.addEventListener(MouseEvent.MOUSE_DOWN, onSlotDown);
			if (kind != "bag") s.addEventListener("rightMouseDown", function(e:MouseEvent):void { g.toggleLock(s.kind, s.idx); s.refreshLock(); showTip(s); });
			s.addEventListener(MouseEvent.ROLL_OVER, onSlotOver);
			s.addEventListener(MouseEvent.ROLL_OUT, onSlotOut);
			return s;
		}

		private function onSlotDown(e:MouseEvent):void {
			var s:Slot = Slot(e.currentTarget);
			// ctrl+click locks or unlocks (as does a right-click)
			if (e.ctrlKey && s.item && s.kind != "bag") { g.toggleLock(s.kind, s.idx); s.refreshLock(); showTip(s); return; }
			// shift+click keeps its shortcuts (sell at the Marketplace, quick drop); clicks on empty slots do nothing
			if (e.shiftKey || !s.item) {
				g.slotClick(s.kind, s.idx, e.shiftKey);
				refresh();
				showTip(s);
				return;
			}
			dragSlot = s;
			dragging = false;
			downX = stage.mouseX; downY = stage.mouseY;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onDragMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onDragUp);
		}

		private function onDragMove(e:MouseEvent):void {
			if (!dragSlot) return;
			if (!dragging) {
				var dx:Number = stage.mouseX - downX, dy:Number = stage.mouseY - downY;
				if (dx * dx + dy * dy < 36) return;
				dragging = true;
				dragGhost = new Bitmap(Sprites.icon(dragSlot.item));
				dragGhost.alpha = 0.9;
				addChild(dragGhost);
				dragSlot.alpha = 0.35;
				tip.visible = false;
			}
			dragGhost.x = mouseX - dragGhost.width / 2;
			dragGhost.y = mouseY - dragGhost.height / 2;
			e.updateAfterEvent();
		}

		private function onDragUp(e:MouseEvent):void {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onDragUp);
			var s:Slot = dragSlot;
			dragSlot = null;
			if (!s) return;
			s.alpha = 1;
			if (!dragging) {
				// a plain click: use, equip or pick up
				g.slotClick(s.kind, s.idx, false);
			} else {
				if (dragGhost) { removeChild(dragGhost); dragGhost = null; }
				dragging = false;
				var target:Slot = slotUnderMouse();
				if (target) g.dragToSlot(s.kind, s.idx, target.kind, target.idx);
				else if (mouseX < 0) g.dragToGround(s.kind, s.idx);
			}
			refresh();
			if (hover) showTip(hover);
		}

		private function slotUnderMouse():Slot {
			var lists:Array = [invSlots, equip, bagSlots];
			for each (var list:Vector.<Slot> in lists) {
				for each (var sl:Slot in list) {
					if (!sl.visible || !sl.parent || !sl.parent.visible) continue;
					if (sl.hitTestPoint(stage.mouseX, stage.mouseY, false)) return sl;
				}
			}
			return null;
		}

		private function onSlotOver(e:MouseEvent):void {
			hover = Slot(e.currentTarget);
			showTip(hover);
		}

		private function onSlotOut(e:MouseEvent):void {
			hover = null;
			tip.visible = false;
		}

		private function showTip(s:Slot):void {
			if (!s || !s.item) { tip.visible = false; return; }
			var drinkable:Boolean = s.item.kind == "stat" || s.item.kind == "hp" || s.item.kind == "mp";
			var hint:String = s.kind == "bag" ? (g.nearBag && g.nearBag.vault ? "Click to take out of your vault" : "Click to pick up, or drag into a slot") + (drinkable ? ". Shift+click to drink it here." : "") : s.kind == "inv" ? (s.item.locked ? "Locked (right-click or Ctrl+click to unlock)" : g.nearMarket ? "Shift+click to sell. Right-click to lock." : "Click to use or equip. Drag onto the ground to drop. Right-click to lock.") : "Equipped. Drag into your inventory to take it off." + (s.item.locked ? " Locked." : " Right-click to lock.");
			var worn:Object = null;
			if ((s.kind == "inv" || s.kind == "bag") && Data.isGear(s.item) && Data.canUse(s.item, g.player.cls.id)) worn = g.player[s.item.kind];
			tip.show(s.item, hint, worn);
			var lp:Point = globalToLocal(s.localToGlobal(new Point(0, 0)));
			tip.x = lp.x - tip.width - 8;
			tip.y = Math.max(4, Math.min(Ui.H - tip.height - 4, lp.y - 10));
			setChildIndex(tip, numChildren - 1);
		}

		public function refresh():void {
			var p:Player = g.player;
			nameTf.text = p.name;
			var pbd:BitmapData = Sprites.get(p.spriteId);
			if (portrait.bitmapData != pbd) {
				portrait.bitmapData = pbd;
				portrait.scaleX = portrait.scaleY = 0.62;
				portrait.x = medal.x - portrait.width / 2;
				portrait.y = medal.y - portrait.height / 2;
			}
			var xpFrac:Number = p.level >= Player.MAX_LEVEL ? 1 : p.xp / p.xpNext;
			if (xpFrac != lastXpFrac || p.level != lastLevel) {
				if (lastLevel > 0 && p.level > lastLevel) levelUp();
				lastXpFrac = xpFrac; lastLevel = p.level;
				drawMedal(xpFrac);
				lvlBadge.text = String(p.level);
				lastFame = -1;
			}
			if (p.level >= Player.MAX_LEVEL) lvlBar.set(1, "", "MAX LEVEL");
			else lvlBar.set(p.xp / p.xpNext, "", Ui.commas(p.xp) + " / " + Ui.commas(p.xpNext) + " XP");
			if (p.fame != lastFame) {
				lastFame = p.fame;
				// class, level and Fame on one line
				subTf.htmlText = p.cls.name + " \u00b7 Lv " + p.level + "   <font color='#ffb060'>Fame " + Ui.commas(p.fame) + "</font>";
			}
			tickMedalFx(p);
			var hb:int = p.bonus("hp"), mb:int = p.bonus("mp");
			hpBar.set(p.hp / p.maxHp, "HP", int(Math.max(0, p.hp)) + "/" + p.maxHp + (hb > 0 ? " <font color='#ffe36e'>(+" + hb + ")</font>" : ""));
			mpBar.set(p.mp / p.maxMp, "MP", int(p.mp) + "/" + p.maxMp + (mb > 0 ? " <font color='#ffe36e'>(+" + mb + ")</font>" : ""));
			ptBar.set(p.maxPt > 0 ? p.pt / p.maxPt : 0, "WD", int(p.pt) + "/" + p.maxPt);
			sgBar.set(p.surge / Player.SURGE_MAX, "FV", p.surge + "/" + Player.SURGE_MAX);

			equip[0].setItem(p.weapon);
			equip[1].setItem(p.ability);
			equip[1].setCooldown(p.abilityT > 0 ? p.abilityT / p.abilityCd : 0, p.abilityT);
			equip[2].setItem(p.armor);
			equip[3].setItem(p.ring);
			var i:int;
			if (!p.backpack) p.packPage = 0;
			packBtn.visible = p.backpack;
			var pk:String = p.packPage == 0 ? "Inventory  1 / 2" : "Backpack  2 / 2";
			if (packTf.text != pk) packTf.text = pk;
			for (i = 0; i < 8; i++) {
				invSlots[i].idx = p.packPage * 8 + i;
				invSlots[i].setItem(p.inv[p.packPage * 8 + i]);
				invSlots[i].setUpgrade(isUpgrade(p, invSlots[i].item));
			}
			hpPot.setCount(p.hpPots, "F");
			mpPot.setCount(p.mpPots, "G");

			if (skillPage.visible) refreshSkills(p);
			if (statPage.visible) {
				var st:String = statLine("hp") + statLine("mp") + "\n" + statLine("att") + statLine("def") + "\n" + statLine("spd") + statLine("dex") + "\n" +
					statLine("vit") + statLine("wis") + "\n" + statLine("mgt") + statLine("luc") + "\n" +
					statLine("prt") + "<font color='#f0c030'>LUCK</font> <font color='#ffe080'>" + g.totalLuck() + "</font>\n" +
					"<font color='#ffd75e' size='12'>Maxed " + p.maxedCount + "/11</font>   <font color='#aaaaaa' size='12'>Crit " + Math.round(p.critChance * 100) + "%  x" + p.critMult.toFixed(2) +
					(p.setPieces >= 4 ? "   <font color='#4ee08a'>Set bonus</font>" : "") + "</font>";
				if (st != lastStats) {
					lastStats = st;
					statTf.htmlText = st;
				}
			}

			var bag:LootBag = g.nearBag;
			if ((bag != null) != (lastBag != null)) drawBagBox(bag != null);
			lastBag = bag;
			for (i = 0; i < 8; i++) {
				bagSlots[i].setItem(bag && i < bag.items.length ? bag.items[i] : null);
				bagSlots[i].setUpgrade(isUpgrade(p, bagSlots[i].item));
			}
			if (hover && (!hover.item || (hover.kind == "bag" && !bag))) {
				tip.visible = false;
				hover = null;
			}

			var now:int = getTimer();
			for each (var es:Slot in equip) es.tick(now);
			if (invPage.visible) for each (es in invSlots) es.tick(now);
			if (bag) for each (es in bagSlots) es.tick(now);
			else if (frameN % 15 == 0) refreshStatus(p);
			if (++frameN % 4 == 0) drawMinimap();
			if (frameN % 30 == 1) {
				zoneTf.text = g.world.kind == "realm" ? g.world.name + " Realm" : g.world.name;
				onlineTf.htmlText = "<font color='#5ee08a'>\u25cf</font> " + (g.net.players.length + 1) + " here";
			}
		}

		private function levelUp():void {
			lvlFlash = 1;
			for (var i:int = 0; i < 18; i++) {
				var a:Number = Math.PI * 2 * i / 18 + Math.random() * 0.3;
				var sp:Number = 30 + Math.random() * 40;
				sparks.push({x: Math.cos(a) * 18, y: Math.sin(a) * 18, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, life: 0.6 + Math.random() * 0.4});
			}
		}

		/** Low HP makes the HP bar and the medallion rim throb red; a level-up rings gold and throws sparks. */
		private var medalDrawn:Boolean = false;
		private function tickMedalFx(p:Player):void {
			var low:Boolean = p.hp > 0 && p.hp < p.maxHp * 0.3;
			var throb:Number = low ? 0.5 + 0.5 * Math.sin(getTimer() / 120) : 0;
			hpBar.setPulse(throb);
			if (!low && lvlFlash <= 0 && !sparks.length && !medalDrawn) return;
			medalDrawn = low || lvlFlash > 0 || sparks.length > 0;
			var gr:* = medalFx.graphics;
			gr.clear();
			if (low) {
				gr.lineStyle(3, 0xff3040, 0.35 + throb * 0.6);
				gr.drawCircle(0, 0, 21);
				gr.lineStyle();
			}
			if (lvlFlash > 0) {
				lvlFlash = Math.max(0, lvlFlash - Ui.FRAME * 1.2);
				gr.lineStyle(3, GOLD_HI, lvlFlash);
				gr.drawCircle(0, 0, 21 + (1 - lvlFlash) * 16);
				gr.lineStyle();
				gr.beginFill(0xfff4c0, lvlFlash * 0.35);
				gr.drawCircle(0, 0, 17);
				gr.endFill();
			}
			for (var i:int = sparks.length - 1; i >= 0; i--) {
				var s:Object = sparks[i];
				s.life -= Ui.FRAME;
				if (s.life <= 0) { sparks.splice(i, 1); continue; }
				s.x += s.vx * Ui.FRAME; s.y += s.vy * Ui.FRAME;
				s.vx *= 0.94; s.vy *= 0.94;
				gr.beginFill(i % 3 ? GOLD_HI : 0xffffff, Math.min(1, s.life * 2));
				gr.drawRect(s.x - 1, s.y - 1, 2, 2);
				gr.endFill();
			}
		}

		/** Pet, shrine blessings, loot luck and kill streak, while no loot bag is near. */
		private function refreshStatus(p:Player):void {
			var pet:Object = g.pet;
			if (pet) {
				var pbd:BitmapData = Sprites.get(Sprites.petForm(pet, Save.data.petSkin || ""));
				if (petPic.bitmapData != pbd) { petPic.bitmapData = pbd; petPic.scaleX = petPic.scaleY = 26 / Math.max(1, pbd.height); }
				petTf.htmlText = (pet.name || "Pet").replace(/</g, "&lt;") + "  <font color='#b8a8e0' size='11'>Lv " + (pet.level || 1) + "</font>";
			} else {
				petPic.bitmapData = null;
				petTf.htmlText = "<font color='#6a5c90'>No pet</font>";
			}
			petTf.x = pet ? 44 : 12;
			// who leads the realms (the guild with the most realm bosses last week), and what it gives yours
			var ld:Object = g.leaders;
			blessTf.htmlText = !ld || !ld.name ? "<font color='#8a7cb0'>Realm Leaders: </font><font color='#6a5c90'>none yet</font>"
				: ld.me ? "<font color='#ffd75e'>Your guild leads the realms</font>  <font color='#b8a8e0'>+" + ld.luck + " luck +" + ld.xp + "% XP</font>"
				: "<font color='#8a7cb0'>Realm Leaders: </font><font color='#ffd75e'>" + Ui.esc(ld.name) + "</font>";
			var st:int = g.killStreak;
			luckTf.htmlText = "Loot luck <font color='#ffe080'>+" + g.totalLuck() + "</font>" + (st >= 3 ? "     Streak <font color='#ff9a50'>x" + st + "</font>" : "");
		}

		/** The portrait medallion: a dark disc, a gold rim, and an XP arc around it. */
		private function drawMedal(frac:Number):void {
			var gr:* = medal.graphics;
			gr.clear();
			gr.beginFill(0x05030a);
			gr.drawCircle(0, 0, 21);
			gr.endFill();
			gr.lineStyle(3, 0x2a2040);
			gr.drawCircle(0, 0, 18.5);
			if (frac > 0) {
				gr.lineStyle(3, 0xb48aff);
				var a0:Number = -Math.PI / 2;
				gr.moveTo(Math.cos(a0) * 18.5, Math.sin(a0) * 18.5);
				for (var i:int = 1; i <= 40; i++) {
					var a:Number = a0 + Math.PI * 2 * frac * i / 40;
					gr.lineTo(Math.cos(a) * 18.5, Math.sin(a) * 18.5);
				}
			}
			gr.lineStyle(1, GOLD);
			gr.drawCircle(0, 0, 20.5);
			gr.lineStyle();
			var m:Matrix = new Matrix();
			m.createGradientBox(32, 32, 0, -16, -20);
			gr.beginGradientFill("radial", [0x3a2c5c, 0x150f22], [1, 1], [0, 255], m);
			gr.drawCircle(0, 0, 16.5);
			gr.endFill();
			// the level badge
			gr.lineStyle(1, GOLD);
			gr.beginFill(0x2a1c48);
			gr.drawCircle(16, 14, 8);
			gr.endFill();
			gr.lineStyle();
		}

		/** Gear your class can use that beats what you have on in that slot. */
		private function isUpgrade(p:Player, it:Object):Boolean {
			if (!it || !Data.isGear(it) || !Data.canUse(it, p.cls.id) || p.climbBlock(it)) return false;
			var worn:Object = p[it.kind];
			return !worn || Tooltip.score(it) > Tooltip.score(worn) * 1.02 + 0.5;
		}

		/** The loot luck breakdown, beside the stats panel. */
		private function showLuckTip():void {
			var parts:Array = g.luckParts();
			var out:String = "<font size='14' color='#f0c030'><b>Loot luck: " + g.totalLuck() + "</b></font><br>";
			for each (var pt:Array in parts) {
				var v:int = int(pt[1]);
				out += (v > 0 ? "<font color='#ffe080'>+" + v + "</font>  " : "<font color='#777777'>+0</font>  ") + "<font color='" + (v > 0 ? "#eeeeee" : "#888888") + "'>" + pt[0] + "</font><br>";
			}
			out += "<font size='11' color='#a8a8a8'>More common drops: +" + g.totalLuck() + "%. Rarest drops (uniques, Godly): +" +
				Math.round(Math.min(160, g.totalLuck()) / 4) + "% (at most +40%). Gear, streak, blessings and pet count up to " + Game.LUCK_REPORTED_MAX + " together.</font>";
			luckTipTf.htmlText = out;
			var w:int = 250, h:int = int(luckTipTf.height) + 16;
			luckTip.graphics.clear();
			Ui.panel(luckTip.graphics, 0, 0, w, h, 0x1a1a1a, 0xf0c030);
			luckTip.x = -w - 6;
			luckTip.y = statPage.y + statTf.y + 70;
			luckTip.visible = true;
		}

		private function statLine(key:String):String {
			var p:Player = g.player;
			var b:int = p.bonus(key);
			var maxed:Boolean = p.stats[key] >= p.cls.max[key];
			var v:String = String(p.stat(key));
			while (v.length < 4) v += " ";
			// how far the base stat is from the class maximum
			var left:int = Math.ceil(p.cls.max[key] - p.stats[key]);
			return "<font color='#9a9a9a'>" + Data.STAT_SHORT[key] + "</font> <font color='" + (maxed ? "#ffd75e" : "#ffffff") + "'>" + p.stat(key) + "</font>" +
				(b > 0 ? "<font color='#6fd06f'>+" + b + "</font>" : "") +
				(maxed ? "" : " <font color='#8a8a9a' size='11'>" + left + " left</font>") + "    ";
		}

		private function drawMinimap():void {
			var p:Player = g.player;
			var mw:int = mini.width, mh:int = mini.height;
			var n:int = g.world.N;
			// zoom 0 fits the whole map
			var z:Number = zoom == 0 ? Math.min(1, Math.min(mw / n, mh / n)) : ZOOMS[zoom];
			var ox:Number = Math.round(mw / 2 - p.x * z), oy:Number = Math.round(mh / 2 - p.y * z);
			if (zoom == 0) { ox = Math.round((mw - n * z) / 2); oy = Math.round((mh - n * z) / 2); }
			mini.copyPixels(fog, fog.rect, new Point(0, 0));
			mini.draw(g.world.seen, new Matrix(z, 0, 0, z, ox, oy), null, null, null, false);

			var gr:* = miniDots.graphics;
			gr.clear();
			var ds:Number = Math.max(2, z * 0.8);
			for each (var e:Enemy in g.enemies) {
				if (e.isBoss) continue;
				var ex:Number = ox + e.x * z, ey:Number = oy + e.y * z;
				if (ex < 0 || ey < 0 || ex > mw || ey > mh) continue;
				gr.beginFill(0xe02020);
				gr.drawRect(ex - ds / 2, ey - ds / 2, ds, ds);
				gr.endFill();
			}
			for each (var b:LootBag in g.bags) {
				var lx:Number = ox + b.x * z, ly:Number = oy + b.y * z;
				if (lx < 0 || ly < 0 || lx > mw || ly > mh) continue;
				gr.beginFill(b.spr == "bag_white" ? 0xffffff : 0xc08040);
				gr.drawRect(lx - ds / 2, ly - ds / 2, ds, ds);
				gr.endFill();
			}
			// shrines you've seen: a small dot in the blessing's colour
			for each (var sh:Object in g.world.shrines) {
				if ((g.world.seen.getPixel32(int(sh.x), int(sh.y)) >>> 24) == 0) continue;
				var hx:Number = ox + sh.x * z, hy:Number = oy + sh.y * z;
				if (hx < 0 || hy < 0 || hx > mw || hy > mh) continue;
				gr.lineStyle(1, 0x000000);
				gr.beginFill(sh.cd > 0 ? 0x606060 : {might: 0xff4040, haste: 0x40e0ff, fortune: 0xffd040, vigor: 0x50e070, arcana: 0xb060ff}[sh.kind]);
				gr.drawCircle(hx, hy, Math.max(2.5, ds));
				gr.endFill();
				gr.lineStyle();
			}
			// landmarks you've seen: a coloured diamond, grey once cleared
			for each (var st:Object in g.world.sites) {
				if (!st.found && (g.world.seen.getPixel32(int(st.x), int(st.y)) >>> 24) == 0) continue;
				var sx:Number = ox + st.x * z, sy:Number = oy + st.y * z;
				if (sx < 0 || sy < 0 || sx > mw || sy > mh) continue;
				var sr:Number = Math.max(3, ds * 1.6);
				gr.lineStyle(1, 0x000000);
				gr.beginFill(st.cleared ? 0x707070 : st.color);
				gr.moveTo(sx, sy - sr); gr.lineTo(sx + sr, sy); gr.lineTo(sx, sy + sr); gr.lineTo(sx - sr, sy); gr.lineTo(sx, sy - sr);
				gr.endFill();
				gr.lineStyle();
			}
			// other players: arrows pointing the way they're going (yellow, like RotMG; party blue, guild green)
			marks.length = 0;
			for each (var rp:RemotePlayer in g.net.players) {
				var seen:Boolean = g.shown(rp);
				var mpx:Number = seen ? rp.x : rp.mapX, mpy:Number = seen ? rp.y : rp.mapY;
				if (isNaN(mpx)) continue;
				var rx:Number = ox + mpx * z, ry:Number = oy + mpy * z;
				if (rx < 0 || ry < 0 || rx > mw || ry > mh) continue;
				arrow(gr, rx, ry, rp.heading, 4.5, g.net.inParty(rp) ? 0x7fd8ff : g.net.inGuild(rp) ? 0x60ff60 : 0xffe040);
				marks.push({rp: rp, x: rx, y: ry});
			}
			if (g.boss) {
				var bx:Number = Math.max(4, Math.min(mw - 4, ox + g.boss.x * z));
				var by:Number = Math.max(4, Math.min(mh - 4, oy + g.boss.y * z));
				gr.lineStyle(1, 0x000000);
				gr.beginFill(0xff40ff);
				gr.drawRect(bx - 4, by - 4, 8, 8);
				gr.endFill();
				gr.lineStyle();
			}
			// your arrow: turns to the way you're walking
			if (!isNaN(lastPx)) {
				var mdx:Number = p.x - lastPx, mdy:Number = p.y - lastPy;
				if (mdx * mdx + mdy * mdy > 0.0004 && mdx * mdx + mdy * mdy < 9) myHeading = Math.atan2(mdy, mdx);
			}
			lastPx = p.x; lastPy = p.y;
			arrow(gr, ox + p.x * z, oy + p.y * z, myHeading, 6, 0x4aa0ff);
		}

		/** A minimap arrow at (x, y) pointing at angle ang (radians, 0 = east). */
		private static function arrow(gr:*, x:Number, y:Number, ang:Number, r:Number, color:uint):void {
			var c:Number = Math.cos(ang), sn:Number = Math.sin(ang);
			// the shape pointing east: tip, back corners and the notch
			var pts:Array = [[r, 0], [-r * 0.85, r * 0.85], [-r * 0.35, 0], [-r * 0.85, -r * 0.85]];
			gr.lineStyle(1, 0x000000);
			gr.beginFill(color);
			for (var i:int = 0; i <= pts.length; i++) {
				var q:Array = pts[i % pts.length];
				var ax:Number = x + q[0] * c - q[1] * sn, ay:Number = y + q[0] * sn + q[1] * c;
				if (i == 0) gr.moveTo(ax, ay); else gr.lineTo(ax, ay);
			}
			gr.endFill();
			gr.lineStyle();
		}

		/** The player marker nearest (x, y) on the minimap, if one is close enough. */
		private function markAt(x:Number, y:Number):Object {
			var best:Object = null, bd:Number = 9 * 9;
			for each (var m:Object in marks) {
				var dx:Number = m.x - x, dy:Number = m.y - y, d:Number = dx * dx + dy * dy;
				if (d < bd && g.net.players.indexOf(m.rp) >= 0) { bd = d; best = m; }
			}
			return best;
		}

		private function miniHover(x:Number, y:Number):void {
			var m:Object = markAt(x, y);
			miniHit.buttonMode = m != null;
			if (!m) { miniLabel.visible = false; return; }
			var rp:RemotePlayer = m.rp;
			var lv:String = rp.profile && rp.profile.level ? " (" + rp.profile.level + ")" : "";
			miniLabel.htmlText = " " + rp.name.replace(/</g, "&lt;") + lv + "  <font color='#9a7cff'>click to teleport</font> ";
			miniLabel.x = Math.max(2, Math.min(W - miniLabel.width - 2, miniHit.x + m.x - miniLabel.width / 2));
			miniLabel.y = miniHit.y + (m.y > mini.height - 24 ? m.y - 24 : m.y + 8);
			miniLabel.visible = true;
		}
		/**
		 * Taking loot: the item's icon arcs from its bag slot to where it went
		 * ("hp" / "mp" for the potion slots, else an inventory index).
		 */
		public function flyItem(item:Object, bagIdx:int, to:*):void {
			if (bagIdx < 0 || bagIdx >= bagSlots.length) return;
			var from:Sprite = bagSlots[bagIdx];
			var dest:Sprite = to == "hp" ? hpPot : to == "mp" ? mpPot : null;
			if (!dest) {
				var k:int = int(to);
				var p:Player = g.player;
				dest = int(k / 8) == p.packPage && invPage.visible ? invSlots[k % 8] : packBtn;
			}
			var a:Point = globalToLocal(from.localToGlobal(new Point(from.width / from.scaleX / 2, from.height / from.scaleY / 2)));
			var b:Point = globalToLocal(dest.localToGlobal(new Point(dest.width / 2, dest.height / 2)));
			var bmp:Bitmap = new Bitmap(Sprites.icon(item));
			addChild(bmp);
			var t:Number = 0;
			bmp.addEventListener(Event.ENTER_FRAME, function(e:Event):void {
				t += Ui.FRAME / 0.28;
				if (t >= 1) {
					bmp.removeEventListener(Event.ENTER_FRAME, arguments.callee);
					if (bmp.parent) removeChild(bmp);
					return;
				}
				var q:Number = t * t * (3 - 2 * t);
				var sc:Number = 1 + Math.sin(t * Math.PI) * 0.35;
				bmp.scaleX = bmp.scaleY = sc;
				bmp.x = a.x + (b.x - a.x) * q - bmp.width / 2;
				bmp.y = a.y + (b.y - a.y) * q - Math.sin(t * Math.PI) * 40 - bmp.height / 2;
				bmp.alpha = t > 0.8 ? (1 - t) / 0.2 : 1;
			});
		}
	}
}

import flash.display.Bitmap;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.text.TextField;
import flash.utils.getTimer;

import realm.Data;
import realm.Hud;
import realm.Sprites;
import realm.Ui;

/** RotMG-style bar: short label on the left, value centred (or after the label). */
class Bar extends Sprite {
	private var fill:Shape = new Shape();
	/** What was just lost: a pale piece that waits a moment, then drains away. */
	private var ghost:Shape = new Shape();
	private var ghostFrac:Number = -1;
	private var ghostHold:Number = 0;
	private var lastT:int = 0;
	/** Show the drain-behind piece (HP and MP). */
	public var trail:Boolean = false;
	private var labelTf:TextField;
	private var valueTf:TextField;
	private var w:int, h:int;
	private var valueAlign:String;
	private var lastFrac:Number = -1;
	private var lastLabel:String = "";
	private var lastValue:String = "";

	public function Bar(w:int, h:int, color:uint, back:uint, size:int, label:String = "", valueAlign:String = "center", textColor:uint = 0xffffff) {
		this.w = w;
		this.h = h;
		this.valueAlign = valueAlign;
		// a recessed dark track (tinted by the bar's colour unless a back colour is given)
		var r:Number = Math.min(h, 10);
		var m:Matrix = new Matrix();
		m.createGradientBox(w, h, Math.PI / 2);
		graphics.lineStyle(1, 0x05030a);
		graphics.beginGradientFill("linear", [0x07050c, back || mix(color, 0x0a0812, 0.82)], [1, 1], [0, 255], m);
		graphics.drawRoundRect(0, 0, w, h, r, r);
		graphics.endFill();
		graphics.lineStyle(1, 0xffffff, 0.06);
		graphics.moveTo(r / 2, h); graphics.lineTo(w - r / 2, h);
		graphics.lineStyle();
		ghost.graphics.beginFill(0xfff0d0, 0.75);
		ghost.graphics.drawRoundRect(1, 1, w - 1, h - 1, r - 1, r - 1);
		ghost.graphics.endFill();
		ghost.visible = false;
		addChild(ghost);
		// the fill: lit from above, a glossy top half and fine notches every tenth
		fill.graphics.beginGradientFill("linear", [mix(color, 0xffffff, 0.28), color, mix(color, 0x000000, 0.45)], [1, 1, 1], [0, 110, 255], m);
		fill.graphics.drawRoundRect(1, 1, w - 1, h - 1, r - 1, r - 1);
		fill.graphics.endFill();
		fill.graphics.beginFill(0xffffff, 0.16);
		fill.graphics.drawRoundRect(3, 2, w - 6, (h - 2) * 0.42, r - 3, r - 3);
		fill.graphics.endFill();
		if (w > 150) for (var n:int = 1; n < 10; n++) {
			fill.graphics.beginFill(0x000000, 0.18);
			fill.graphics.drawRect(int(w * n / 10), 2, 1, h - 3);
			fill.graphics.endFill();
		}
		addChild(fill);
		labelTf = Ui.text(size, 0xffffff, true, "left", 0, true);
		labelTf.x = 5;
		addChild(labelTf);
		Hud.bake(this);
		valueTf = Ui.text(size, 0xffffff, true, valueAlign, valueAlign == "center" ? w : 0, true);
		addChild(valueTf);
		mouseChildren = false;
		if (label) set(0, label, "");
	}

	private var pulse:Shape;
	/** A red throb over the fill (0 = off). */
	public function setPulse(a:Number):void {
		if (a <= 0 && !pulse) return;
		if (!pulse) {
			pulse = new Shape();
			pulse.graphics.beginFill(0xffb0b0);
			pulse.graphics.drawRoundRect(1, 1, w - 1, h - 1, Math.min(h, 10) - 1, Math.min(h, 10) - 1);
			pulse.graphics.endFill();
			addChildAt(pulse, getChildIndex(fill) + 1);
		}
		pulse.visible = a > 0;
		pulse.scaleX = fill.scaleX;
		pulse.alpha = a * 0.35;
		// (a filter set every frame redraws the bar every frame: only while it throbs, and one filter reused)
		if (a > 0) {
			if (!glowF) glowF = new GlowFilter(0xff3040, 0.9, 10, 10, 2);
			glowF.alpha = a * 0.9;
			filters = [glowF];
			glowOn = true;
		} else if (glowOn) {
			filters = [];
			glowOn = false;
		}
	}
	private var glowF:GlowFilter;
	private var glowOn:Boolean = false;

	/** Blend a toward b by t (0..1). */
	public static function mix(a:uint, b:uint, t:Number):uint {
		var r:int = ((a >> 16) & 255) * (1 - t) + ((b >> 16) & 255) * t;
		var g:int = ((a >> 8) & 255) * (1 - t) + ((b >> 8) & 255) * t;
		var bl:int = (a & 255) * (1 - t) + (b & 255) * t;
		return (r << 16) | (g << 8) | bl;
	}

	public function set(frac:Number, label:String, value:String):void {
		if (frac < 0) frac = 0;
		if (frac > 1) frac = 1;
		var now:int = getTimer();
		var dt:Number = lastT ? Math.min(0.1, (now - lastT) / 1000) : 0;
		lastT = now;
		if (!trail || ghostFrac < 0 || frac >= ghostFrac) { ghostFrac = frac; ghostHold = 0.4; }
		else if (lastFrac >= 0 && frac < lastFrac) ghostHold = Math.max(ghostHold, 0.25);
		else if (ghostHold > 0) ghostHold -= dt;
		else ghostFrac = Math.max(frac, ghostFrac - dt * (0.25 + (ghostFrac - frac) * 2));
		ghost.visible = ghostFrac - frac > 0.002;
		if (ghost.visible) { ghost.scaleX = ghostFrac; ghost.alpha = Math.min(1, ghostHold > 0 ? 1 : 0.4 + (ghostFrac - frac) * 6); }
		if (frac != lastFrac) { fill.scaleX = frac; lastFrac = frac; }
		if (label != lastLabel) {
			labelTf.text = label;
			labelTf.y = (h - labelTf.height) / 2;
			lastLabel = label;
			lastValue = "";
		}
		if (value != lastValue) {
			valueTf.htmlText = value;
			valueTf.y = (h - valueTf.height) / 2;
			valueTf.x = valueAlign == "center" ? 0 : labelTf.x + labelTf.width + 2;
			lastValue = value;
		}
	}
}

class Slot extends Sprite {
	public var kind:String;
	public var idx:int;
	public var item:Object;
	private var icon:Bitmap = new Bitmap();
	private var tierTf:TextField;
	private var numTf:TextField;

	/** The slot's face (drawBack), kept as a bitmap: it changes only with the item. */
	private var back:Shape = new Shape();

	public function Slot(kind:String, idx:int, numbered:Boolean) {
		this.kind = kind;
		this.idx = idx;
		back.cacheAsBitmap = true;
		addChild(back);
		drawBack(null, false);
		// empty gear slots show a faint mark of what goes there
		var mark:Array = MARKS[kind];
		if (mark) {
			watermark = new Bitmap(Sprites.build(mark, {W: 0xc8b8f0}, 3, 1));
			watermark.alpha = 0.16;
			watermark.x = int((48 - watermark.width) / 2);
			watermark.y = int((48 - watermark.height) / 2);
			addChild(watermark);
		}
		if (numbered) {
			numTf = Ui.text(22, 0x3e3260, true, "center", 48);
			numTf.text = String(idx + 1);
			numTf.y = 7;
			addChild(numTf);
		}
		icon.x = 6;
		icon.y = 6;
		addChild(icon);
		tierTf = Ui.text(13, 0xffffff, true, "right", 32, true);
		tierTf.x = 15;
		tierTf.y = 28;
		addChild(tierTf);
		fx = new Shape();
		addChild(fx);
		hoverFx = new Shape();
		addChildAt(hoverFx, 1);
		mouseChildren = false;
		buttonMode = true;
		addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { drawHover(1); });
		addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { drawHover(0); });
		addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { drawHover(2); });
		addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void { drawHover(1); });
	}

	private var fx:Shape;
	private var hoverFx:Shape;
	private var shimmer:Boolean = false;
	private var rim:uint = 0;

	/** 0 = idle, 1 = hovered (a soft light), 2 = pressed (brighter). */
	private function drawHover(state:int):void {
		var g:* = hoverFx.graphics;
		g.clear();
		if (!state) return;
		g.beginFill(0xd8c8ff, state == 2 ? 0.22 : 0.1);
		g.drawRoundRect(1, 1, 46, 46, 11, 11);
		g.endFill();
		g.lineStyle(1, 0xf2d68a, state == 2 ? 1 : 0.7);
		g.drawRoundRect(1, 1, 46, 46, 11, 11);
		g.lineStyle();
	}

	/** Legendary and better: a spark of light runs round the rim. */
	public function tick(now:int):void {
		if (!shimmer) return;
		var g:* = fx.graphics;
		g.clear();
		var t:Number = (now % 2400) / 2400;
		for (var i:int = 0; i < 8; i++) {
			var q:Array = rimPoint(t - i * 0.012);
			g.beginFill(i ? Bar.mix(rim, 0xffffff, 0.5) : 0xffffff, 1 - i / 8);
			g.drawCircle(q[0], q[1], i < 2 ? 1.6 : 1.1);
			g.endFill();
		}
	}

	/** A point on the slot's rim, 0..1 clockwise from the top-left. */
	private static function rimPoint(t:Number):Array {
		t = (t % 1 + 1) % 1;
		var d:Number = t * 176, s:Number = 44;
		if (d < s) return [2 + d, 1.5];
		if (d < s * 2) return [46.5, 2 + d - s];
		if (d < s * 3) return [46 - (d - s * 2), 46.5];
		return [1.5, 46 - (d - s * 3)];
	}

	private static const MARKS:Object = {
		weapon: ["......WW", ".....WWW", "....WWW.", "W..WWW..", ".WWWW...", "..WW....", ".W.WW...", "W.......", "........"],
		ability: ["..WWWW..", ".WW..WW.", "WW.WW.WW", "W.WWWW.W", "W.WWWW.W", "WW.WW.WW", ".WW..WW.", "..WWWW.."],
		armor: [".WW..WW.", "WWWWWWWW", "WWWWWWWW", ".WWWWWW.", ".WWWWWW.", ".WWWWWW.", ".WWWWWW.", "..WWWW.."],
		ring: ["...WW...", "..W..W..", "..WWWW..", ".W....W.", "W......W", "W......W", ".W....W.", "..WWWW.."]
	};
	private var watermark:Bitmap;

	/** The slot's face: dark glass, its rim in the item's rarity colour. */
	private function drawBack(it:Object, bad:Boolean):void {
		var m:Matrix = new Matrix();
		m.createGradientBox(48, 48, Math.PI / 2);
		var top:uint = bad ? 0x5a2430 : kind == "bag" ? 0x33281c : 0x2a2244;
		var bot:uint = bad ? 0x2a0e14 : kind == "bag" ? 0x17110a : 0x130f20;
		back.graphics.clear();
		back.graphics.lineStyle(1, 0x05030a);
		back.graphics.beginGradientFill("linear", [top, bot], [1, 1], [0, 255], m);
		back.graphics.drawRoundRect(0, 0, 48, 48, 12, 12);
		back.graphics.endFill();
		rim = it && it.rarity ? Data.tierColor(it) : kind == "bag" ? 0x6a5434 : Hud.EDGE;
		shimmer = it && (it.rarity == "lg" || it.rarity == "sf" || it.rarity == "ar" || it.rarity == "gd");
		if (!shimmer && fx) fx.graphics.clear();
		if (it && it.rarity) {
			// a soft glow of the rarity colour from the bottom
			var gm:Matrix = new Matrix();
			gm.createGradientBox(60, 48, 0, -6, 18);
			back.graphics.beginGradientFill("radial", [rim, rim], [0.32, 0], [0, 255], gm);
			back.graphics.drawRoundRect(1, 1, 46, 46, 11, 11);
			back.graphics.endFill();
		}
		back.graphics.lineStyle(it && it.rarity ? 1.5 : 1, rim, it && it.rarity ? 0.95 : 0.8);
		back.graphics.drawRoundRect(1, 1, 46, 46, 11, 11);
		back.graphics.lineStyle(1, 0xffffff, 0.07);
		back.graphics.moveTo(7, 2.5); back.graphics.lineTo(41, 2.5);
		back.graphics.lineStyle();
	}

	private var upArrow:Shape;
	private var cdShape:Shape;
	private var cdTf:TextField;
	private var cdLast:Number = 0;
	private var readyGlow:Number = 0;
	private var cdDrawn:Boolean = false;

	/** Ability cooldown: a dark sweep that empties clockwise, the seconds left, and a flash when ready. */
	public function setCooldown(frac:Number, secs:Number):void {
		if (!cdShape) {
			cdShape = new Shape();
			addChild(cdShape);
			cdTf = Ui.text(15, 0xffffff, true, "center", 48, true);
			cdTf.y = 14;
			addChild(cdTf);
		}
		if (frac <= 0 && cdLast > 0) readyGlow = 1;
		// (nothing to draw and nothing drawn: leave it be, a cleared shape still redraws its corner of the screen)
		if (frac <= 0 && cdLast <= 0 && readyGlow <= 0 && !cdDrawn) return;
		cdDrawn = frac > 0 || readyGlow > 0;
		cdLast = frac;
		var g:* = cdShape.graphics;
		g.clear();
		if (frac > 0) {
			g.beginFill(0x000000, 0.62);
			var a0:Number = -Math.PI / 2, a1:Number = a0 + Math.PI * 2 * frac;
			g.moveTo(24, 24);
			for (var i:int = 0; i <= 24; i++) {
				var a:Number = a0 + (a1 - a0) * i / 24;
				// a square sweep: push each ray out to the slot's edge
				var cx:Number = Math.cos(a), cy:Number = Math.sin(a);
				var k:Number = 24 / Math.max(Math.abs(cx), Math.abs(cy));
				g.lineTo(24 + cx * k, 24 + cy * k);
			}
			g.lineTo(24, 24);
			g.endFill();
			cdTf.text = secs >= 1 ? String(Math.ceil(secs)) : secs.toFixed(1);
			cdTf.visible = true;
		} else cdTf.visible = false;
		if (readyGlow > 0) {
			// ready: a gold ring swells out from the slot
			var e:Number = (1 - readyGlow) * 7;
			g.lineStyle(2, 0xf2d68a, readyGlow);
			g.drawRoundRect(1 - e, 1 - e, 46 + e * 2, 46 + e * 2, 11 + e, 11 + e);
			g.lineStyle();
			g.beginFill(0xf2d68a, readyGlow * 0.22);
			g.drawRoundRect(1, 1, 46, 46, 11, 11);
			g.endFill();
			readyGlow = Math.max(0, readyGlow - Ui.FRAME * 1.6);
		}
	}

	/** A small green arrow: better than what you have equipped. */
	public function setUpgrade(on:Boolean):void {
		if (!on && !upArrow) return;
		if (!upArrow) {
			upArrow = new Shape();
			var g:* = upArrow.graphics;
			g.lineStyle(1.5, 0x0e2a0e);
			g.beginFill(0x6cff6c);
			g.moveTo(0, -6); g.lineTo(6, 1); g.lineTo(2.5, 1); g.lineTo(2.5, 6); g.lineTo(-2.5, 6); g.lineTo(-2.5, 1); g.lineTo(-6, 1); g.lineTo(0, -6);
			g.endFill();
			upArrow.x = 10; upArrow.y = 11;
			addChild(upArrow);
		}
		upArrow.visible = on;
	}

	private var lockIcon:Shape;
	/** A small padlock on locked gear. */
	public function refreshLock():void {
		var on:Boolean = item && item.locked;
		if (!on && !lockIcon) return;
		if (!lockIcon) {
			lockIcon = new Shape();
			var g:* = lockIcon.graphics;
			g.lineStyle(2, 0x1a1408);
			g.drawRoundRect(-3.5, -9, 7, 9, 6, 6);
			g.lineStyle(1.5, 0xffd75e);
			g.drawRoundRect(-3.5, -9, 7, 9, 6, 6);
			g.lineStyle(1, 0x1a1408);
			g.beginFill(0xffd75e);
			g.drawRoundRect(-6, -4, 12, 9, 3, 3);
			g.endFill();
			g.beginFill(0x1a1408);
			g.drawRect(-1, -1.5, 2, 4);
			g.endFill();
			lockIcon.x = 39; lockIcon.y = 11;
			addChild(lockIcon);
		}
		lockIcon.visible = on;
	}

	public function setItem(it:Object):void {
		// (the same item: only redrawn when its art changed, e.g. an admin drew new art for it)
		if (it == item && (!it || icon.bitmapData == Sprites.icon(it))) { refreshLock(); return; }
		item = it;
		var bad:Boolean = it && !Data.canUse(it, Data.viewerClass);
		drawBack(it, bad);
		if (numTf) numTf.visible = !it;
		if (watermark) watermark.visible = !it;
		if (!it) {
			refreshLock();
			icon.bitmapData = null;
			tierTf.text = "";
			return;
		}
		refreshLock();
		icon.bitmapData = Sprites.icon(it);
		icon.x = int((48 - icon.width) / 2);
		icon.y = int((48 - icon.height) / 2);
		var label:String = Data.tierLabel(it);
		tierTf.text = label;
		tierTf.textColor = Data.tierColor(it);
	}
}

class PotSlot extends Sprite {
	private var tf:TextField;
	private var key:TextField;
	private var last:int = -1;

	public function PotSlot(health:Boolean) {
		var col:uint = health ? 0xe0303e : 0x3a64f0;
		var m:Matrix = new Matrix();
		m.createGradientBox(108, 32, 0);
		graphics.lineStyle(1, 0x05030a);
		graphics.beginGradientFill("linear", [Bar.mix(col, 0x120e1e, 0.62), 0x1a1428, 0x120e1e], [1, 1, 1], [0, 120, 255], m);
		graphics.drawRoundRect(0, 0, 108, 32, 32, 32);
		graphics.endFill();
		graphics.lineStyle(1, Bar.mix(col, Hud.EDGE, 0.5), 0.9);
		graphics.drawRoundRect(1, 1, 106, 30, 30, 30);
		graphics.lineStyle();
		var ic:Bitmap = new Bitmap(Sprites.icon(Data.makePotion(health ? "hp" : "mp")));
		ic.scaleX = ic.scaleY = 0.75;
		ic.x = 30; ic.y = 2;
		addChild(ic);
		tf = Ui.text(18, 0xffffff, true, "left", 0, true);
		tf.x = 62; tf.y = 3;
		addChild(tf);
		key = Ui.text(11, 0xf2d68a, true);
		key.x = 10; key.y = 8;
		addChild(key);
		buttonMode = true;
		mouseChildren = false;
		Hud.bake(this);
	}

	public function setCount(n:int, k:String):void {
		if (n == last) return;
		last = n;
		tf.text = String(n);
		tf.textColor = n > 0 ? 0xffffff : 0x8a8a8a;
		key.text = k;
	}
}
