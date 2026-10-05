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

			// hero name
			var save:Object = Save.data;
			var nl:TextField = Ui.text(15, 0xbbbbbb, true, "right", 200, true);
			nl.text = "Hero name";
			nl.x = Ui.W / 2 - 316;
			nl.y = 142;
			addChild(nl);
			var nameBox:Shape = new Shape();
			Ui.panel(nameBox.graphics, Ui.W / 2 - 104, 136, 208, 32, 0x1c1c1c, 0x6a6a6a);
			addChild(nameBox);
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
			addChild(nameField);

			var pick:TextField = Ui.text(18, 0xffffff, true, "center", Ui.W, true);
			pick.text = "Choose your class";
			pick.y = 180;
			addChild(pick);

			for (var i:int = 0; i < Data.CLASS_ORDER.length; i++) {
				var card:Sprite = makeCard(Data.CLASSES[Data.CLASS_ORDER[i]], save);
				card.x = (Ui.W - 4 * 230 - 3 * 18) / 2 + i * 248;
				card.y = 214;
				addChild(card);
			}

			var help:TextField = Ui.text(14, 0xcccccc, false, "center", Ui.W, true);
			help.htmlText = "<b>WASD</b> move   <b>Mouse</b> aim + shoot   <b>Space</b> ability   <b>F / G</b> health / magic potion   " +
				"<b>1-8</b> use item   <b>R</b> return to Haven   <b>I</b> auto-fire   <b>P</b> pause\n" +
				"Stand on loot bags and click their items in the sidebar. Slay enough monsters and the Cube Overlord appears.";
			help.y = 546;
			addChild(help);

			var stats:TextField = Ui.text(15, 0xff9a40, true, "center", Ui.W, true);
			stats.text = "Best fame: " + Ui.commas(save.bestFame || 0) + "      Heroes lost: " + (save.deaths || 0);
			stats.y = 600;
			addChild(stats);

			addEventListener(Event.ENTER_FRAME, animate);
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void {
				removeEventListener(Event.ENTER_FRAME, animate);
				bg.dispose();
			});
		}

		private function makeCard(cls:Object, save:Object):Sprite {
			var c:Sprite = new Sprite();
			var w:int = 230, h:int = 316;
			var draw:Function = function(hover:Boolean):void {
				c.graphics.clear();
				Ui.panel(c.graphics, 0, 0, w, h, hover ? 0x3e3e3e : 0x262626, hover ? Ui.GOLD : 0x5a5a5a, 0.94);
				c.graphics.beginFill(0x000000, 0.25);
				c.graphics.drawRoundRect(14, 14, w - 28, 110, 10, 10);
				c.graphics.endFill();
			};
			draw(false);
			var spr:Bitmap = new Bitmap(Sprites.get(cls.id));
			spr.scaleX = spr.scaleY = 2;
			spr.x = (w - spr.width) / 2;
			spr.y = 20;
			c.addChild(spr);
			var name:TextField = Ui.text(24, 0xffffff, true, "center", w, true);
			name.text = cls.name;
			name.y = 128;
			c.addChild(name);
			var desc:TextField = Ui.text(13, 0xcccccc, false, "center", w - 24);
			desc.text = cls.desc;
			desc.x = 12;
			desc.y = 162;
			c.addChild(desc);
			var info:TextField = Ui.text(13, 0xaaaaaa, false, "center", w - 24);
			var best:int = save.bestLevel ? int(save.bestLevel[cls.id] || 0) : 0;
			info.htmlText = "<b>HP</b> " + cls.base.hp + "   <b>ATT</b> " + cls.base.att + "   <b>DEX</b> " + cls.base.dex + "\n" +
				"<font color='#ffd75e'><b>" + cls.ability.name + "</b></font>: " + cls.ability.desc +
				(best > 0 ? "\n<font color='#80ff80'>Best level: " + best + "</font>" : "");
			info.x = 12;
			info.y = 226;
			c.addChild(info);

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
