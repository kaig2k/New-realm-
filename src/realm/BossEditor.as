package realm {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;

	/**
	 * Boss Maker: a boss's look and stats plus up to 4 phases of attacks.
	 * Every value is kept inside the same limits the game's own bosses use,
	 * so whatever you make can be dodged.
	 */
	public class BossEditor extends Sprite {
		private static const PATTERNS:Array = ["aimed", "ring", "spiral", "flower", "wall", "nova", "rain", "summon"];
		private static const PATTERN_NAMES:Object = {aimed: "Aimed shots", ring: "Ring", spiral: "Spiral", flower: "Flower",
			wall: "Wall with a gap", nova: "Ground blast", rain: "Meteor rain", summon: "Summon minions"};
		private static const MOVES:Array = ["chase", "orbit", "wander", "still", "charge", "center"];
		private static const MOVE_NAMES:Object = {chase: "Chases you", orbit: "Circles you", wander: "Wanders", still: "Stands still",
			charge: "Charges at you", center: "Holds the centre"};
		private static const SHAPES:Array = ["orb", "star", "blade", "ring", "dart", "arrow", "bolt", "knife"];
		private static const COLOURS:Array = [0xff4040, 0xff8030, 0xffd040, 0x80ff60, 0x40e0c0, 0x60a0ff, 0xa060ff, 0xff60c0, 0xf0f0f0, 0x9aff7a];
		private static const EFFECTS:Array = ["", "slowed", "paralyzed", "confused", "armorbroken", "bleeding"];
		private static const MINIONS:Array = ["skeleton", "imp", "cubelet", "goblin", "spider", "ghost", "orc", "lesser_demon"];

		private var onDone:Function;
		private var onTest:Function;
		private var b:Object;
		private var phase:int = 0;
		private var nameTf:TextField;
		private var info:TextField;
		private var body:Sprite = new Sprite();
		private var savedName:String;

		public function BossEditor(name:String, onDone:Function, onTest:Function) {
			this.onDone = onDone;
			this.onTest = onTest;
			savedName = name;
			b = name ? CreatorData.load("bosses", name) : null;
			if (!b) b = {name: "My Boss", sprite: "boss", hp: 8000, def: 15, spd: 1.4, col: 0xff4040, map: null, cls: "wizard",
				phases: [{hp: 100, move: "chase", say: "You dare challenge me?", attacks: [
					{p: "aimed", n: 3, spd: 8, dmg: 60, cd: 1.0, col: 0xff4040, shape: "orb", eff: ""},
					{p: "ring", n: 16, spd: 5, dmg: 50, cd: 2.0, col: 0xffd040, shape: "ring", eff: ""}]}]};
			Ui.panel(graphics, 0, 0, Ui.W, Ui.H, 0x16171c, 0xff6a50, 1);
			var title:TextField = Ui.text(24, 0xff6a50, true, "left", 300, true);
			title.text = "Boss Maker";
			title.x = 20; title.y = 16;
			addChild(title);
			var nl:TextField = Ui.text(14, 0xbbbbbb, true, "left", 60);
			nl.text = "Name";
			nl.x = 180; nl.y = 24;
			addChild(nl);
			nameTf = Ui.input(200, b.name, 24);
			nameTf.x = 230; nameTf.y = 20;
			addChild(nameTf);
			var save:Sprite = Ui.button("Save", 80, 30, function():void { store(); }, 15);
			save.x = 444; save.y = 18;
			addChild(save);
			var test:Sprite = Ui.button("Test Fight", 120, 30, function():void { if (store()) onTest(savedName); }, 15);
			test.x = 532; test.y = 18;
			addChild(test);
			var back:Sprite = Ui.button("Back", 80, 30, function():void { onDone(); }, 15);
			back.x = 660; back.y = 18;
			addChild(back);
			info = Ui.text(13, 0x9a9a9a, false, "left", 340);
			info.x = 750; info.y = 16;
			addChild(info);
			info.text = "Test Fight saves the boss and starts a practice fight.";
			addChild(body);
			rebuild();
		}

		private function store():Boolean {
			var n:String = nameTf.text.replace(/^\s+|\s+$/g, "");
			if (!n) { info.text = "Give the boss a name first."; return false; }
			b.name = n;
			if (savedName && savedName != n) CreatorData.remove("bosses", savedName);
			savedName = n;
			CreatorData.store("bosses", n, b);
			info.text = "Saved \"" + n + "\".";
			return true;
		}

		// ------------------------------------------------------------ widgets
		private function stepper(label:String, value:String, x:int, y:int, minus:Function, plus:Function, w:int = 150):void {
			var l:TextField = Ui.text(12, 0xaaaaaa, false, "left", w);
			l.text = label;
			l.x = x; l.y = y;
			body.addChild(l);
			var m:Sprite = Ui.button("-", 22, 22, function():void { minus(); rebuild(); }, 14);
			m.x = x; m.y = y + 17;
			body.addChild(m);
			var v:TextField = Ui.text(13, 0xffffff, true, "center", w - 52);
			v.text = value;
			v.x = x + 24; v.y = y + 19;
			body.addChild(v);
			var p:Sprite = Ui.button("+", 22, 22, function():void { plus(); rebuild(); }, 14);
			p.x = x + w - 26; p.y = y + 17;
			body.addChild(p);
		}

		private function cycler(label:String, value:String, x:int, y:int, step:Function, w:int = 170):void {
			stepper(label, value, x, y, function():void { step(-1); }, function():void { step(1); }, w);
		}

		private static function next(list:Array, cur:*, d:int):* {
			var i:int = list.indexOf(cur);
			return list[((i < 0 ? 0 : i) + d + list.length) % list.length];
		}

		private static function clamp(v:Number, lo:Number, hi:Number):Number { return Math.max(lo, Math.min(hi, v)); }

		// ------------------------------------------------------------ layout
		private function rebuild():void {
			body.removeChildren();
			body.graphics.clear();
			// --- left: the boss itself
			Ui.panel(body.graphics, 16, 60, 300, 568, 0x1e2026, 0x3a3a4a);
			var spr:String = b.sprite.indexOf("cs:") == 0 ? CreatorData.useSprite(b.sprite.substr(3)) : b.sprite;
			var pic:Bitmap = new Bitmap(Sprites.get(spr));
			var sc:Number = Math.min(2, 110 / Math.max(pic.width, pic.height));
			pic.scaleX = pic.scaleY = sc;
			pic.x = 166 - pic.width / 2; pic.y = 74 + (110 - pic.height) / 2;
			body.addChild(pic);
			var looks:Array = lookList();
			cycler("Look", lookName(b.sprite), 40, 194, function(d:int):void { b.sprite = next(looks, b.sprite, d); }, 252);
			stepper("Health", Ui.commas(b.hp), 40, 240, function():void { b.hp = clamp(b.hp - (b.hp > 20000 ? 5000 : 1000), 1000, 200000); },
				function():void { b.hp = clamp(b.hp + (b.hp >= 20000 ? 5000 : 1000), 1000, 200000); }, 252);
			stepper("Defense", String(b.def), 40, 286, function():void { b.def = clamp(b.def - 5, 0, 80); }, function():void { b.def = clamp(b.def + 5, 0, 80); }, 252);
			stepper("Move speed", Number(b.spd).toFixed(1), 40, 332, function():void { b.spd = clamp(Math.round((b.spd - 0.2) * 10) / 10, 0, 4); },
				function():void { b.spd = clamp(Math.round((b.spd + 0.2) * 10) / 10, 0, 4); }, 252);
			var maps:Array = [null].concat(CreatorData.names("maps"));
			cycler("Arena (from the Map Builder)", b.map || "Default arena", 40, 378, function(d:int):void { b.map = next(maps, b.map, d); }, 252);
			cycler("Test with", Data.CLASSES[b.cls].name, 40, 424, function(d:int):void { b.cls = next(Data.CLASS_ORDER, b.cls, d); }, 252);
			var hint:TextField = Ui.text(12, 0x8a8a9a, false, "left", 260);
			hint.text = "Draw your own look in the Sprite Editor and build arenas in the Map Builder; they show up here.";
			hint.x = 36; hint.y = 474;
			body.addChild(hint);

			// --- right: phases
			Ui.panel(body.graphics, 330, 60, 754, 568, 0x1e2026, 0x3a3a4a);
			if (phase >= b.phases.length) phase = b.phases.length - 1;
			for (var i:int = 0; i < b.phases.length; i++) {
				var pt:Sprite = Ui.button("Phase " + (i + 1), 100, 28, phaseFn(i), 14);
				pt.alpha = i == phase ? 1 : 0.5;
				pt.x = 346 + i * 106; pt.y = 70;
				body.addChild(pt);
			}
			if (b.phases.length < 4) {
				var ap:Sprite = Ui.button("+ Phase", 90, 28, function():void {
					var last:Object = b.phases[b.phases.length - 1];
					b.phases.push({hp: Math.max(10, last.hp - 30), move: last.move, say: "", attacks: Save.clone(last.attacks)});
					phase = b.phases.length - 1;
					rebuild();
				}, 13);
				ap.x = 346 + b.phases.length * 106; ap.y = 70;
				body.addChild(ap);
			}
			var ph:Object = b.phases[phase];
			if (phase > 0) {
				var rp:Sprite = Ui.button("Remove phase", 120, 28, function():void { b.phases.splice(phase, 1); phase--; rebuild(); }, 12);
				rp.x = 950; rp.y = 70;
				body.addChild(rp);
				stepper("Starts at boss health", ph.hp + "%", 346, 108, function():void { ph.hp = clamp(ph.hp - 5, 5, 95); },
					function():void { ph.hp = clamp(ph.hp + 5, 5, 95); }, 160);
			} else {
				var first:TextField = Ui.text(12, 0xaaaaaa, false, "left", 160);
				first.text = "Phase 1 starts the fight.";
				first.x = 346; first.y = 118;
				body.addChild(first);
			}
			cycler("Movement", MOVE_NAMES[ph.move], 520, 108, function(d:int):void { ph.move = next(MOVES, ph.move, d); }, 180);
			var sl:TextField = Ui.text(12, 0xaaaaaa, false, "left", 200);
			sl.text = "Says when the phase starts";
			sl.x = 716; sl.y = 108;
			body.addChild(sl);
			var say:TextField = Ui.input(350, ph.say, 60, 12);
			say.x = 716; say.y = 126;
			say.addEventListener(Event.CHANGE, function(e:Event):void { ph.say = say.text; });
			body.addChild(say);

			var y:int = 164;
			for (i = 0; i < ph.attacks.length; i++) {
				attackRow(ph, i, y);
				y += 102;
			}
			if (ph.attacks.length < 4) {
				var aa:Sprite = Ui.button("+ Attack", 120, 28, function():void {
					ph.attacks.push({p: "aimed", n: 1, spd: 9, dmg: 60, cd: 1.0, col: 0xff8030, shape: "blade", eff: ""});
					rebuild();
				}, 13);
				aa.x = 346; aa.y = y + 4;
				body.addChild(aa);
			}
		}

		private function phaseFn(i:int):Function {
			return function():void { phase = i; rebuild(); };
		}

		private function attackRow(ph:Object, i:int, y:int):void {
			var a:Object = ph.attacks[i];
			Ui.panel(body.graphics, 342, y, 730, 94, 0x262830, 0x4a4a5a);
			cycler("Attack " + (i + 1), PATTERN_NAMES[a.p], 352, y + 4, function(d:int):void { a.p = next(PATTERNS, a.p, d); fit(a); }, 190);
			var maxN:int = maxCount(a.p);
			stepper(a.p == "summon" ? "Minions" : a.p == "wall" ? "Wall width" : "Bullets", String(a.n), 554, y + 4,
				function():void { a.n = clamp(a.n - 1, 1, maxN); }, function():void { a.n = clamp(a.n + 1, 1, maxN); }, 120);
			if (a.p != "summon") {
				stepper("Speed", String(a.spd), 686, y + 4, function():void { a.spd = clamp(a.spd - 1, 3, a.p == "rain" || a.p == "nova" ? 8 : 12); },
					function():void { a.spd = clamp(a.spd + 1, 3, a.p == "rain" || a.p == "nova" ? 8 : 12); }, 110);
				stepper("Damage", String(a.dmg), 808, y + 4, function():void { a.dmg = clamp(a.dmg - 10, 10, 250); },
					function():void { a.dmg = clamp(a.dmg + 10, 10, 250); }, 120);
			}
			var minCd:Number = a.p == "spiral" ? 0.08 : a.p == "aimed" ? 0.25 : a.p == "summon" ? 4 : 0.5;
			var cdStep:Number = a.cd < 0.5 ? 0.05 : 0.25;
			stepper("Every (s)", Number(a.cd).toFixed(2), 940, y + 4, function():void { a.cd = clamp(Math.round((a.cd - cdStep) * 100) / 100, minCd, 12); },
				function():void { a.cd = clamp(Math.round((a.cd + cdStep) * 100) / 100, minCd, 12); }, 120);
			if (a.p == "summon") {
				cycler("Minion", Data.ENEMIES[a.what || MINIONS[0]].name, 352, y + 50, function(d:int):void { a.what = next(MINIONS, a.what || MINIONS[0], d); }, 190);
			} else {
				var sw:Sprite = new Sprite();
				sw.graphics.lineStyle(2, 0xffffff);
				sw.graphics.beginFill(a.col);
				sw.graphics.drawRect(0, 0, 24, 22);
				sw.graphics.endFill();
				var cl:TextField = Ui.text(12, 0xaaaaaa, false, "left", 80);
				cl.text = "Colour";
				cl.x = 352; cl.y = y + 50;
				body.addChild(cl);
				sw.x = 352; sw.y = y + 67;
				sw.buttonMode = true;
				sw.addEventListener("click", function(e:Event):void { a.col = next(COLOURS, a.col, 1); rebuild(); });
				body.addChild(sw);
				var prev:Bitmap = new Bitmap(Sprites.projectile(a.shape, a.col, 3)[0]);
				prev.x = 384; prev.y = y + 66;
				body.addChild(prev);
				cycler("Bullet shape", a.shape, 420, y + 50, function(d:int):void { a.shape = next(SHAPES, a.shape, d); }, 140);
				cycler("Effect on hit", a.eff ? Player.STATUS_NAMES[a.eff] : "None", 574, y + 50, function(d:int):void { a.eff = next(EFFECTS, a.eff || "", d); }, 170);
			}
			var del:Sprite = Ui.button("Delete", 70, 26, function():void {
				if (ph.attacks.length <= 1) { info.text = "A phase needs at least one attack."; return; }
				ph.attacks.splice(i, 1);
				rebuild();
			}, 12);
			del.x = 990; del.y = y + 62;
			body.addChild(del);
		}

		private static function maxCount(p:String):int {
			return {aimed: 9, ring: 28, spiral: 10, flower: 28, wall: 12, nova: 16, rain: 8, summon: 4}[p] || 8;
		}

		/** Keeps an attack's numbers sensible after its pattern changes. */
		private static function fit(a:Object):void {
			a.n = clamp(a.n, 1, maxCount(a.p));
			if (a.p == "ring" || a.p == "flower") a.n = Math.max(a.n, 8);
			if (a.p == "summon") { a.cd = Math.max(a.cd, 5); a.n = Math.min(a.n, 2); }
			if (a.p == "spiral") a.cd = Math.min(Math.max(a.cd, 0.08), 0.3);
			if ((a.p == "rain" || a.p == "nova") && a.spd > 8) a.spd = 8;
		}

		/** Boss looks: every boss sprite in the game, then your own drawings. */
		private static function lookList():Array {
			var seen:Object = {}, out:Array = [];
			for each (var d:Object in Data.ENEMIES) {
				if (d.ai != "boss" || !d.spr || seen[d.spr] || String(d.spr).indexOf("cs_") == 0) continue;
				seen[d.spr] = true;
				out.push(d.spr);
			}
			out.sort();
			for each (var n:String in CreatorData.names("sprites")) out.push("cs:" + n);
			return out;
		}

		private static function lookName(s:String):String {
			if (s.indexOf("cs:") == 0) return s.substr(3) + " (yours)";
			for each (var d:Object in Data.ENEMIES) if (d.spr == s && d.ai == "boss") return d.name;
			return s;
		}

		// ------------------------------------------------------------ the fight
		/** Turns a saved boss into the enemy definition the game runs. */
		public static function toDef(b:Object):Object {
			var spr:String = b.sprite.indexOf("cs:") == 0 ? CreatorData.useSprite(b.sprite.substr(3)) : b.sprite;
			var phases:Array = [];
			for (var i:int = 0; i < b.phases.length; i++) {
				var ph:Object = b.phases[i];
				var list:Array = [];
				for each (var a:Object in ph.attacks) list.push(attack(a));
				var o:Object = {hp: i == 0 ? 1 : ph.hp / 100, move: ph.move, attacks: list};
				if (ph.say) o.say = ph.say;
				if (i > 0) { o.shield = 1.5; o.banner = b.name + " grows stronger!"; }
				phases.push(o);
			}
			// later phases must start lower down
			phases.sortOn("hp", Array.NUMERIC | Array.DESCENDING);
			return {name: b.name, spr: spr, hp: b.hp, def: b.def, spd: b.spd, r: 0.9, ai: "boss", aggro: 22, range: 18,
				drop: 0, xp: 0, gold: 0, col: b.col || 0xff4040, phases: phases};
		}

		private static function attack(a:Object):Object {
			var spd:Number = clamp(a.spd, 3, 12), n:int = clamp(a.n, 1, maxCount(a.p));
			var o:Object;
			switch (a.p) {
				case "aimed": o = {p: "aimed", n: n, arc: n > 1 ? Math.min(90, n * 12) : 0, spd: spd, life: 11 / spd}; break;
				case "ring": o = {p: "ring", n: n, rot: 7, spd: spd, life: 11 / spd}; break;
				case "spiral": o = {p: "spiral", n: n, rot: 11, spd: spd, life: 11 / spd}; break;
				case "flower": o = {p: "flower", n: n, rot: 9, spd: spd, life: 11 / spd}; break;
				case "wall": o = {p: "wall", n: Math.max(4, n), spd: spd, life: 13 / spd, hole: 3}; break;
				case "nova": o = {p: "nova", radius: 3, delay: 1.0, burst: n, bspd: spd * 0.6, blife: 1.4}; break;
				case "rain": o = {p: "rain", n: n, spread: 6, radius: 1.2, delay: 1.1, burst: 0}; break;
				case "summon": return {p: "summon", what: a.what || MINIONS[0], n: n, cd: Math.max(4, a.cd), max: 6};
			}
			o.dmg = clamp(a.dmg, 10, 250);
			o.cd = Math.max(a.p == "spiral" ? 0.08 : a.p == "aimed" ? 0.25 : 0.5, a.cd);
			o.r = 0.22;
			o.col = a.col;
			o.shape = a.shape || "orb";
			if (a.eff) o.eff = a.eff;
			return o;
		}
	}
}
