package realm {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.text.TextField;

	/**
	 * Creator Tools (home screen): build boss arenas, draw sprites and make
	 * your own boss fights, then try them in a test fight. Everything is
	 * saved on this PC.
	 */
	public class CreatorScreen extends Sprite {
		private static const TABS:Array = [
			{id: "bosses", name: "Boss Maker", kind: "bosses", col: 0xff6a50,
				desc: "Make a boss: its look, health and speed, then up to 4 phases of attacks. Test Fight drops you into its arena with a strong hero."},
			{id: "maps", name: "Map Builder", kind: "maps", col: 0x60c0ff,
				desc: "Paint a boss arena tile by tile: floors, walls, water, lava and decorations. Mark where you start and where the boss stands."},
			{id: "sprites", name: "Sprite Editor", kind: "sprites", col: 0x80e080,
				desc: "Draw a 16x16 pixel sprite with up to 16 colours. Use it for your bosses in the Boss Maker."}
		];

		private var onBack:Function;
		private var onTest:Function;
		private var tab:String;
		private var hub:Sprite = new Sprite();
		private var editor:Sprite;

		public function CreatorScreen(onBack:Function, onTest:Function, tab:String = "bosses") {
			this.onBack = onBack;
			this.onTest = onTest;
			this.tab = tab;
			addChild(new Backdrop(0.65));
			addChild(hub);
			showHub();
		}

		private function showHub():void {
			if (editor) { removeChild(editor); editor = null; }
			hub.visible = true;
			hub.removeChildren();
			var title:TextField = Ui.text(40, Ui.GOLD, true, "center", Ui.W, true);
			title.text = "Creator Tools";
			title.y = 18;
			hub.addChild(title);
			var back:Sprite = Ui.button("Home", 110, 34, function():void { onBack(); }, 15);
			back.x = 20; back.y = 20;
			hub.addChild(back);
			var t:Object;
			for (var i:int = 0; i < TABS.length; i++) {
				t = TABS[i];
				var tb:Sprite = Ui.button(t.name, 200, 38, tabFn(t.id), 17);
				tb.x = Ui.W / 2 - 320 + i * 220; tb.y = 82;
				tb.alpha = t.id == tab ? 1 : 0.55;
				hub.addChild(tb);
			}
			for each (t in TABS) if (t.id == tab) break;
			Ui.panel(hub.graphics, 120, 136, Ui.W - 240, 480, 0x1c1e24, t.col, 0.95);
			var desc:TextField = Ui.text(14, 0xc8c8c8, false, "center", Ui.W - 300);
			desc.text = t.desc;
			desc.x = 150; desc.y = 148;
			hub.addChild(desc);
			var nb:Sprite = Ui.button("+ New", 160, 34, function():void { open(tab, null); }, 16);
			nb.x = (Ui.W - 160) / 2; nb.y = 196;
			hub.addChild(nb);
			var names:Array = CreatorData.names(t.kind);
			if (!names.length) {
				var none:TextField = Ui.text(14, 0x888888, false, "center", Ui.W);
				none.text = "Nothing saved yet.";
				none.y = 250;
				hub.addChild(none);
			}
			for (i = 0; i < names.length && i < 16; i++) hub.addChild(row(t, names[i], i));
		}

		private function tabFn(id:String):Function {
			return function():void { tab = id; showHub(); };
		}

		/** One saved thing: its name (and picture), Edit, Test (bosses) and Delete. */
		private function row(t:Object, name:String, i:int):Sprite {
			var r:Sprite = new Sprite();
			var col:int = i % 2, ry:int = int(i / 2);
			r.x = 150 + col * 410; r.y = 244 + ry * 44;
			Ui.panel(r.graphics, 0, 0, 390, 38, 0x262830, 0x4a4a5a);
			var label:TextField = Ui.text(15, 0xffffff, true, "left", 160, true);
			label.text = name;
			label.x = 44; label.y = 8;
			r.addChild(label);
			var spr:String = null;
			if (t.kind == "sprites") spr = CreatorData.useSprite(name);
			else if (t.kind == "bosses") {
				var b:Object = CreatorData.load("bosses", name);
				spr = b && b.sprite ? (b.sprite.indexOf("cs:") == 0 ? CreatorData.useSprite(b.sprite.substr(3)) : b.sprite) : null;
			}
			if (spr) {
				var bm:Bitmap = new Bitmap(Sprites.get(spr));
				var sc:Number = Math.min(1, 34 / Math.max(bm.width, bm.height));
				bm.scaleX = bm.scaleY = sc;
				bm.x = 4 + (34 - bm.width) / 2; bm.y = 2 + (34 - bm.height) / 2;
				r.addChild(bm);
			}
			var x:int = 390 - 6;
			var del:Sprite = Ui.button("Delete", 64, 28, function():void {
				CreatorData.remove(t.kind, name);
				showHub();
			}, 12);
			x -= 64; del.x = x; del.y = 5;
			r.addChild(del);
			var ed:Sprite = Ui.button("Edit", 54, 28, function():void { open(t.id, name); }, 12);
			x -= 60; ed.x = x; ed.y = 5;
			r.addChild(ed);
			if (t.kind == "bosses") {
				var te:Sprite = Ui.button("Test Fight", 90, 28, function():void { test(name); }, 12);
				x -= 96; te.x = x; te.y = 5;
				r.addChild(te);
			}
			return r;
		}

		private function open(id:String, name:String):void {
			hub.visible = false;
			var done:Function = function():void { showHub(); };
			if (id == "maps") editor = new MapEditor(name, done);
			else if (id == "sprites") editor = new SpriteEditor(name, done);
			else editor = new BossEditor(name, done, test);
			addChild(editor);
		}

		/** Starts a test fight with a saved boss. */
		public function test(name:String):void {
			var b:Object = CreatorData.load("bosses", name);
			if (!b) return;
			var map:Object = b.map ? CreatorData.load("maps", b.map) : null;
			onTest({name: b.name || name, def: BossEditor.toDef(b), map: map, cls: b.cls || "wizard"});
		}
	}
}
