package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldType;

	/** Title screen: scrolling realm backdrop, hero name and class selection. */
	public class Menu extends Sprite {
		private static const NAMES:Array = ["Ezra", "Vex", "Lyra", "Thorn", "Kael", "Mira", "Orin", "Sable", "Rook", "Nyx", "Bram", "Iris"];

		private var onPick:Function;
		private var bg:BitmapData;
		private var world:World;
		private var camX:Number, camY:Number;
		private var mtx:Matrix = new Matrix();
		private var nameField:TextField;
		private var classLayer:Sprite;
		private var charLayer:Sprite;

		public function Menu(onPick:Function) {
			this.onPick = onPick;
			world = new World();
			camX = world.spawnX;
			camY = world.spawnY - 10;
			bg = new BitmapData(Ui.W, Ui.H, false, 0);
			addChild(new Bitmap(bg));
			var shade:Shape = new Shape();
			shade.graphics.beginFill(0x000000, 0.55);
			shade.graphics.drawRect(0, 0, Ui.W, Ui.H);
			shade.graphics.endFill();
			addChild(shade);
			drawBackground();

			var title:TextField = Ui.text(68, Ui.GOLD, true, "center", Ui.W, true);
			title.text = "NEW REALM";
			title.y = 18;
			addChild(title);
			var sub:TextField = Ui.text(17, 0xd8d0ff, false, "center", Ui.W, true);
			sub.text = "A bullet-hell adventure inspired by Realm of the Mad God";
			sub.y = 100;
			addChild(sub);

			classLayer = new Sprite();
			addChild(classLayer);
			// hero name
			var save:Object = Save.data;
			var nl:TextField = Ui.text(15, 0xbbbbbb, true, "right", 200, true);
			nl.text = "Hero name";
			nl.x = Ui.W / 2 - 316;
			nl.y = 142;
			classLayer.addChild(nl);
			var nameBox:Shape = new Shape();
			Ui.panel(nameBox.graphics, Ui.W / 2 - 104, 136, 208, 32, 0x1c1c1c, 0x6a6a6a);
			classLayer.addChild(nameBox);
			nameField = Ui.text(18, 0xffffff, true, "center", 196);
			nameField.autoSize = "none";
			nameField.height = 28;
			nameField.x = Ui.W / 2 - 98;
			nameField.y = 138;
			nameField.type = TextFieldType.INPUT;
			nameField.selectable = true;
			nameField.mouseEnabled = true;
			nameField.maxChars = 12;
			nameField.restrict = "A-Za-z0-9";
			nameField.text = save.name || NAMES[int(Math.random() * NAMES.length)];
			classLayer.addChild(nameField);

			var pick:TextField = Ui.text(18, 0xffffff, true, "center", Ui.W, true);
			pick.text = "Choose your class";
			pick.y = 180;
			classLayer.addChild(pick);

			for (var i:int = 0; i < Data.CLASS_ORDER.length; i++) {
				var card:Sprite = makeCard(Data.CLASSES[Data.CLASS_ORDER[i]], save);
				card.x = (Ui.W - 4 * 240 - 3 * 14) / 2 + (i % 4) * 254;
				card.y = 210 + int(i / 4) * 160;
				classLayer.addChild(card);
			}

			var help:TextField = Ui.text(14, 0xcccccc, false, "center", Ui.W, true);
			help.htmlText = "<b>WASD</b> move   <b>Mouse</b> aim + shoot   <b>Space</b> ability   <b>F / G</b> health / magic potion   " +
				"<b>1-8</b> use item   <b>R</b> return to Nexus   <b>I</b> auto-fire   <b>P</b> pause\n" +
				"Start in the Nexus, step into a realm portal, clear the realm events, then face the Dark Elder in his chamber.";
			help.y = 538;
			addChild(help);

			var stats:TextField = Ui.text(15, 0xff9a40, true, "center", Ui.W, true);
			stats.text = "Account fame: " + Ui.commas(save.fame || 0) + "      Gold: " + Ui.commas(save.gold || 0) +
				"      Onrane: " + Ui.commas(save.onrane || 0) + "      Best fame: " + Ui.commas(save.bestFame || 0) + "      Heroes lost: " + (save.deaths || 0);
			stats.y = 600;
			addChild(stats);

			buildCharLayer(save);

			addEventListener(Event.ENTER_FRAME, animate);
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void {
				removeEventListener(Event.ENTER_FRAME, animate);
				bg.dispose();
			});
		}

		/** "Your Characters": continue a living character, or make a new one. */
		private function buildCharLayer(save:Object):void {
			var chars:Array = Save.chars;
			if (chars.length == 0) return;
			charLayer = new Sprite();
			addChild(charLayer);
			classLayer.visible = false;
			var t:TextField = Ui.text(20, 0xffffff, true, "center", Ui.W, true);
			t.text = "Your Characters";
			t.y = 140;
			charLayer.addChild(t);
			for (var i:int = 0; i < Math.min(8, chars.length); i++) {
				var card:Sprite = makeCharCard(chars[i]);
				card.x = (Ui.W - 4 * 240 - 3 * 14) / 2 + (i % 4) * 254;
				card.y = 180 + int(i / 4) * 120;
				charLayer.addChild(card);
			}
			var nb:Sprite = Ui.button("New Character", 220, 40, function():void {
				charLayer.visible = false;
				classLayer.visible = true;
			});
			nb.x = (Ui.W - 220) / 2;
			nb.y = 432;
			charLayer.addChild(nb);
			var back:Sprite = Ui.button("Back", 100, 30, function():void {
				classLayer.visible = false;
				charLayer.visible = true;
			}, 14);
			back.x = 20; back.y = 140;
			classLayer.addChild(back);
		}

		private function makeCharCard(c:Object):Sprite {
			var card:Sprite = new Sprite();
			var w:int = 240, h:int = 108;
			var cls:Object = Data.CLASSES[c.cls];
			var draw:Function = function(hover:Boolean):void {
				card.graphics.clear();
				Ui.panel(card.graphics, 0, 0, w, h, hover ? 0x3e3e3e : 0x262626, hover ? Ui.GOLD : 0x5a5a5a, 0.94);
			};
			draw(false);
			var spr:Bitmap = new Bitmap(Sprites.get(c.cls));
			spr.scaleX = spr.scaleY = 1.4;
			spr.x = 10; spr.y = (h - spr.height) / 2;
			card.addChild(spr);
			var nm:TextField = Ui.text(20, 0xffffff, true, "left", 0, true);
			nm.text = c.name;
			nm.x = 82; nm.y = 10;
			card.addChild(nm);
			var info:TextField = Ui.text(13, 0xbbbbbb, false, "left", 150);
			var maxed:int = 0;
			for each (var s:String in Data.STATS) if (c.stats[s] >= cls.max[s]) maxed++;
			var gear:String = c.weapon && c.weapon.rarity ? " <font color='" + Ui.hex(Data.RARITY_COLORS[c.weapon.rarity]) + "'>" + String(c.weapon.rarity).toUpperCase() + "</font>" : "";
			info.htmlText = "Lvl " + c.level + " " + cls.name + gear + "\n" + maxed + "/11 maxed   " + c.kills + " kills";
			info.x = 82; info.y = 40;
			card.addChild(info);
			card.buttonMode = true;
			card.mouseChildren = false;
			card.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			card.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			card.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onPick(c.cls, c.name, c); });
			return card;
		}

		private function makeCard(cls:Object, save:Object):Sprite {
			var c:Sprite = new Sprite();
			var w:int = 240, h:int = 150;
			var draw:Function = function(hover:Boolean):void {
				c.graphics.clear();
				Ui.panel(c.graphics, 0, 0, w, h, hover ? 0x3e3e3e : 0x262626, hover ? Ui.GOLD : 0x5a5a5a, 0.94);
				c.graphics.beginFill(0x000000, 0.25);
				c.graphics.drawRoundRect(8, 8, 78, 78, 10, 10);
				c.graphics.endFill();
			};
			draw(false);
			var spr:Bitmap = new Bitmap(Sprites.get(cls.id));
			spr.scaleX = spr.scaleY = 1.5;
			spr.x = 47 - spr.width / 2;
			spr.y = 47 - spr.height / 2;
			c.addChild(spr);
			var name:TextField = Ui.text(21, 0xffffff, true, "left", 0, true);
			name.text = cls.name;
			name.x = 94; name.y = 8;
			c.addChild(name);
			var best:int = save.bestLevel ? int(save.bestLevel[cls.id] || 0) : 0;
			var info:TextField = Ui.text(12, 0xaaaaaa, false, "left", w - 100);
			info.htmlText = "<font color='#ffd75e'><b>" + cls.ability.name + "</b></font>  " + cls.ability.desc + "\n" +
				"HP " + cls.base.hp + "  ATT " + cls.base.att + "  DEX " + cls.base.dex +
				(best > 0 ? "\n<font color='#80ff80'>Best level " + best + "</font>" : "");
			info.x = 94; info.y = 36;
			c.addChild(info);
			var desc:TextField = Ui.text(12, 0xcccccc, false, "left", w - 20);
			desc.text = cls.desc;
			desc.x = 10;
			desc.y = 96;
			c.addChild(desc);

			c.buttonMode = true;
			c.mouseChildren = false;
			c.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			c.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			c.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				var n:String = nameField.text.replace(/[^A-Za-z0-9]/g, "");
				if (!n) n = NAMES[int(Math.random() * NAMES.length)];
				Save.data.name = n;
				Save.flush();
				onPick(cls.id, n);
			});
			return c;
		}

		private function drawBackground():void {
			bg.lock();
			mtx.a = mtx.d = Game.TS / World.PX;
			mtx.tx = Math.round(Ui.W / 2 - camX * Game.TS);
			mtx.ty = Math.round(Ui.H / 2 - camY * Game.TS);
			bg.draw(world.bitmap, mtx, null, null, null, false);
			bg.unlock();
		}

		private function animate(e:Event):void {
			camY -= 0.02;
			camX += 0.008;
			if (camY < 30) camY = world.spawnY - 10;
			drawBackground();
		}
	}
}
