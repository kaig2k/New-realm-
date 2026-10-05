package realm {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	/** Title screen with class selection. */
	public class Menu extends Sprite {
		private var onPick:Function;
		private var drift:Array = [];

		public function Menu(onPick:Function) {
			this.onPick = onPick;
			graphics.beginFill(0x12101c);
			graphics.drawRect(0, 0, 800, 600);
			graphics.endFill();

			// drifting background critters
			var bgIds:Array = ["pirate", "snake", "goblin", "orc", "medusa", "djinn", "beholder", "ent", "gazer", "cubelet", "crab", "elf"];
			for (var i:int = 0; i < 14; i++) {
				var b:Bitmap = new Bitmap(Sprites.get(bgIds[i % bgIds.length]));
				b.alpha = 0.18;
				b.x = Math.random() * 800;
				b.y = Math.random() * 600;
				addChild(b);
				drift.push({b: b, vx: (Math.random() - 0.5) * 30, vy: (Math.random() - 0.5) * 30});
			}

			var title:TextField = Ui.text(56, 0xffd75e, true, "center", 800, true);
			title.text = "NEW REALM";
			title.y = 26;
			addChild(title);
			var sub:TextField = Ui.text(14, 0xc8b8ff, false, "center", 800, true);
			sub.text = "A bullet-hell adventure inspired by Realm of the Mad God";
			sub.y = 100;
			addChild(sub);

			var pick:TextField = Ui.text(16, 0xffffff, true, "center", 800, true);
			pick.text = "Choose your class";
			pick.y = 140;
			addChild(pick);

			var save:Object = Save.data;
			for (i = 0; i < Data.CLASS_ORDER.length; i++) {
				var card:Sprite = makeCard(Data.CLASSES[Data.CLASS_ORDER[i]], save);
				card.x = 22 + i * 192;
				card.y = 172;
				addChild(card);
			}

			var help:TextField = Ui.text(12, 0xbbbbbb, false, "center", 800, true);
			help.htmlText = "<b>WASD</b> move   <b>Mouse</b> aim + shoot   <b>Space</b> ability   <b>F / G</b> drink HP / MP potion\n" +
				"<b>1-8</b> use inventory   <b>R</b> return to Safe Haven   <b>I</b> toggle auto-fire   <b>P</b> pause\n" +
				"Walk over loot bags and click their items in the sidebar. Slay enough monsters and the Cube Overlord appears.";
			help.y = 470;
			addChild(help);

			var stats:TextField = Ui.text(13, 0xffa040, true, "center", 800, true);
			stats.text = "Best fame: " + (save.bestFame || 0) + "     Characters lost: " + (save.deaths || 0);
			stats.y = 548;
			addChild(stats);

			addEventListener(Event.ENTER_FRAME, animate);
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void {
				removeEventListener(Event.ENTER_FRAME, animate);
			});
		}

		private function makeCard(cls:Object, save:Object):Sprite {
			var c:Sprite = new Sprite();
			var w:int = 180, h:int = 280;
			var draw:Function = function(hover:Boolean):void {
				c.graphics.clear();
				c.graphics.lineStyle(2, hover ? 0xffd75e : 0x5a5070);
				c.graphics.beginFill(hover ? 0x3a3150 : 0x241f33, 0.95);
				c.graphics.drawRoundRect(0, 0, w, h, 14, 14);
				c.graphics.endFill();
			};
			draw(false);
			var spr:Bitmap = new Bitmap(Sprites.get(cls.id));
			spr.scaleX = spr.scaleY = 2;
			spr.x = (w - spr.width) / 2;
			spr.y = 8;
			c.addChild(spr);
			var name:TextField = Ui.text(18, 0xffffff, true, "center", w);
			name.text = cls.name;
			name.y = 92;
			c.addChild(name);
			var desc:TextField = Ui.text(11, 0xcccccc, false, "center", w - 16);
			desc.text = cls.desc;
			desc.x = 8;
			desc.y = 118;
			c.addChild(desc);
			var info:TextField = Ui.text(11, 0xaaaaaa, false, "center", w - 16);
			var best:int = save.bestLevel ? int(save.bestLevel[cls.id] || 0) : 0;
			info.htmlText = "HP " + cls.base.hp + "  ATT " + cls.base.att + "  DEX " + cls.base.dex + "\n" +
				"<font color='#ffd75e'>" + cls.ability.name + "</font>: " + cls.ability.desc +
				(best > 0 ? "\n<font color='#80ff80'>Best level: " + best + "</font>" : "");
			info.x = 8;
			info.y = 186;
			c.addChild(info);

			c.buttonMode = true;
			c.mouseChildren = false;
			c.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			c.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			c.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onPick(cls.id); });
			return c;
		}

		private function animate(e:Event):void {
			for each (var d:Object in drift) {
				d.b.x += d.vx / 60;
				d.b.y += d.vy / 60;
				if (d.b.x < -40) d.b.x = 800;
				if (d.b.x > 800) d.b.x = -40;
				if (d.b.y < -40) d.b.y = 600;
				if (d.b.y > 600) d.b.y = -40;
			}
		}
	}
}
