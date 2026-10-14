package realm {
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;

	/**
	 * Your pet at a glance (J): its stage, skill and path, and its bag. Adult pets
	 * carry 2 items and Ascended ones 4: click one of your items to hand it over,
	 * click one in the bag to take it back. (Evolving is done at the Pet Yard.)
	 */
	public class PetWindow extends Sprite {
		public static const W:int = 420;
		private var g:Game;
		private var body:Sprite = new Sprite();
		private var tip:Tooltip = new Tooltip();

		public function PetWindow(g:Game) {
			this.g = g;
			addChild(body);
			tip.mouseEnabled = tip.mouseChildren = false;
			tip.visible = false;
			addChild(tip);
			refresh();
		}

		public function refresh():void {
			body.removeChildren();
			graphics.clear();
			var pt:Object = g.pet;
			var y:int = 12;
			if (!pt) {
				Ui.panel(graphics, 0, 0, W, 110, 0x1e1e26, 0xc8a8ff, 0.97);
				var none:TextField = Ui.text(14, 0xcccccc, false, "center", W - 30, true);
				none.text = "You have no pet with you. Hatch one at the Pet Yard in the Nexus.";
				none.x = 15; none.y = 30;
				body.addChild(none);
				addClose(110);
				return;
			}
			var r:Object = Data.PET_RARITIES[pt.rarity];
			var sk:Object = Data.PET_SKILLS[pt.species];
			var st:int = Data.petStage(pt);
			var slots:int = Data.petBagSlots(pt);
			var inv:Array = g.player.inv;
			var h:int = 150 + (slots > 0 ? 70 + Math.ceil(inv.length / 8) * 50 + 30 : 40);
			Ui.panel(graphics, 0, 0, W, h, 0x1e1e26, r.col, 0.97);
			var glow:Shape = new Shape();
			glow.graphics.beginFill(r.col, 0.15);
			glow.graphics.drawCircle(56, 62, 40);
			glow.graphics.endFill();
			body.addChild(glow);
			var key:String = Sprites.petSprite(pt.species, Save.data.petSkin);
			var pic:Bitmap = new Bitmap(Sprites.get(key));
			pic.scaleX = pic.scaleY = Data.PET_STAGES[st].scale * 1.3;
			pic.x = 56 - pic.width / 2; pic.y = 62 - pic.height / 2;
			body.addChild(pic);
			var t:TextField = Ui.text(18, r.col, true, "left", W - 130, true);
			t.text = Data.petTitle(pt);
			t.x = 110; t.y = y;
			body.addChild(t);
			var path:String = Data.petPath(pt);
			var info:TextField = Ui.text(12, 0xcccccc, false, "left", W - 124, true);
			info.htmlText = r.name + "  ·  level " + pt.level + "/" + r.max + "  ·  stage " + (st + 1) + " of " + (Data.petMaxStage(pt) + 1) + "<br>" +
				"<font color='#ffd080'>" + sk.skill + "</font>: " + (st > 0 ? sk.desc : "<font color='#888888'>wakes up at Juvenile</font>") +
				(path ? "<br><font color='" + (path == "b" ? "#ff8a70" : "#80e0ff") + "'>" + sk[path].name + "</font>: " + sk[path].desc : "") +
				(Data.petDef(pt) ? "<br><font color='#9fd0ff'>+" + Data.petDef(pt) + " Defense for you</font>" : "") +
				(st < Data.petMaxStage(pt) ? "<br><font color='#60f0a0'>Next: " + Data.PET_STAGES[st + 1].name + " at level " + Data.PET_STAGES[st + 1].lv + " with " + Data.PET_STAGES[st + 1].stones + " Evolution Stone" + (Data.PET_STAGES[st + 1].stones == 1 ? "" : "s") + " (Pet Yard)</font>" : "");
			info.x = 110; info.y = y + 28;
			body.addChild(info);
			y = 140;
			if (slots <= 0) {
				var nb:TextField = Ui.text(12, 0x888888, false, "center", W - 30, true);
				nb.text = "Adult pets carry 2 items, Ascended pets 4.";
				nb.x = 15; nb.y = y;
				body.addChild(nb);
				addClose(h);
				return;
			}
			if (!pt.bag) pt.bag = [];
			while (pt.bag.length < slots) pt.bag.push(null);
			var bh:TextField = Ui.text(13, 0xc8a8ff, true, "left", W - 30, true);
			bh.htmlText = "Carried  <font size='11' color='#888888'>click to take it back</font>";
			bh.x = 16; bh.y = y;
			body.addChild(bh);
			y += 22;
			var i:int;
			for (i = 0; i < slots; i++) body.addChild(slot(pt.bag[i], 16 + i * 50, y, bagFn(i), "Click to take it back."));
			y += 56;
			var ih:TextField = Ui.text(13, 0xdddddd, true, "left", W - 30, true);
			ih.htmlText = "Your inventory  <font size='11' color='#888888'>click to give it to your pet</font>";
			ih.x = 16; ih.y = y;
			body.addChild(ih);
			y += 22;
			for (i = 0; i < inv.length; i++) body.addChild(slot(inv[i], 16 + (i % 8) * 50, y + int(i / 8) * 50, invFn(i), "Click to give it to your pet."));
			addClose(h);
		}

		private function addClose(h:int):void {
			var c:Sprite = Ui.button("X", 30, 26, function():void { g.togglePet(); }, 14);
			c.x = W - 40; c.y = 8;
			body.addChild(c);
		}

		private function slot(it:Object, x:int, y:int, fn:Function, hint:String):Sprite {
			var s:ItemSlot = new ItemSlot(0, 0x545454);
			s.scaleX = s.scaleY = 46 / ItemSlot.SIZE;
			s.setItem(it);
			s.x = x; s.y = y;
			s.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { fn(); });
			s.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
				if (!it) return;
				tip.show(it, hint);
				var p:Point = globalToLocal(s.localToGlobal(new Point(0, 0)));
				tip.x = Math.min(W - tip.width, p.x);
				tip.y = p.y + 50;
				tip.visible = true;
				setChildIndex(tip, numChildren - 1);
			});
			s.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { tip.visible = false; });
			return s;
		}

		private function bagFn(i:int):Function {
			return function():void {
				var pt:Object = g.pet;
				if (!pt || !pt.bag[i]) return;
				var free:int = g.player.freeSlot();
				if (free < 0) { g.msg("Your inventory is full.", 0xff8080); return; }
				g.player.inv[free] = pt.bag[i];
				pt.bag[i] = null;
				changed();
			};
		}

		private function invFn(i:int):Function {
			return function():void {
				var pt:Object = g.pet;
				var it:Object = g.player.inv[i];
				if (!pt || !it) return;
				var free:int = pt.bag.indexOf(null);
				if (free < 0) { g.msg("Your pet can't carry any more.", 0xff8080); return; }
				pt.bag[free] = it;
				g.player.inv[i] = null;
				changed();
			};
		}

		private function changed():void {
			Sfx.play("loot", 0.4);
			g.refreshHud();
			g.saveCharacter();
			refresh();
		}
	}
}
