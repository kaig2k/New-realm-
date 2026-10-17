package realm {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	/**
	 * The Boss Maker's live preview: the boss in its arena (the Map Builder map, or the
	 * test fight's default one), moving and firing its attacks as they're edited, at a
	 * hero you steer with the mouse (or one that strafes by itself). Under it, the boss's
	 * health with every phase marked on it: click the bar to jump to any health, or let
	 * the boss lose health by itself and watch the phases turn over.
	 *
	 * The patterns are the Boss Maker's own (BossEditor.toDef), fired the way Enemy fires
	 * them: same shapes, speeds, gaps and timings.
	 */
	public class BossPreview extends Sprite {
		public static const W:int = 540, H:int = 288;
		private static const DEG:Number = Math.PI / 180;
		private static const BAR_Y:int = H + 14, BAR_H:int = 20;
		private static const ORIGIN:Point = new Point(0, 0);

		private var def:Object;
		private var mapObj:Object;
		private var world:World;
		private var scale:Number = 12;
		private var ground:BitmapData;
		private var canvas:BitmapData = new BitmapData(W, H, false, 0);
		private var fx:Shape = new Shape();
		private var bossBmp:Bitmap = new Bitmap();
		private var heroBmp:Bitmap = new Bitmap();
		private var bar:Sprite = new Sprite();
		private var barLabels:Sprite = new Sprite();
		private var sayTf:TextField;
		private var bannerTf:TextField;
		private var statTf:TextField;
		private var controls:Sprite = new Sprite();

		// the fight
		private var bx:Number, by:Number, homeX:Number, homeY:Number;
		private var hx:Number, hy:Number, heroA:Number = 0;
		private var hp:Number = 1;
		private var phase:int = -1;
		private var timers:Array = [], spins:Array = [];
		private var shots:Array = [], markers:Array = [], minions:Array = [];
		private var orbitA:Number = 0, chargeT:Number = 0, wanderA:Number = 0, wanderT:Number = 0, shieldT:Number = 0;
		private var sayT:Number = 0, bannerT:Number = 0, flashT:Number = 0;
		private var playing:Boolean = true, speed:Number = 1, drain:Boolean = true;
		private var mouseIn:Boolean = false;
		private var hits:int = 0, taken:int = 0, clock:Number = 0;
		private var heroCls:String = "wizard";

		public function BossPreview() {
			addChild(new Bitmap(canvas));
			addChild(fx);
			addChild(bossBmp);
			addChild(heroBmp);
			sayTf = Ui.text(13, 0xffffff, true, "center", 300, true);
			addChild(sayTf);
			bannerTf = Ui.text(20, 0xffd75e, true, "center", W, true);
			bannerTf.y = 10;
			addChild(bannerTf);
			statTf = Ui.text(11, 0xc8c8d8, false, "right", 300, true);
			statTf.x = W - 306; statTf.y = H - 18;
			addChild(statTf);
			var frame:Shape = new Shape();
			frame.graphics.lineStyle(2, 0x4a4a5a);
			frame.graphics.drawRect(0, 0, W, H);
			addChild(frame);
			bar.y = BAR_Y;
			bar.buttonMode = true;
			bar.addEventListener(MouseEvent.MOUSE_DOWN, barClick);
			addChild(bar);
			barLabels.y = BAR_Y + BAR_H + 2;
			addChild(barLabels);
			controls.y = BAR_Y + BAR_H + 22;
			addChild(controls);
			buildControls();
			var hit:Sprite = new Sprite();
			hit.graphics.beginFill(0, 0);
			hit.graphics.drawRect(0, 0, W, H);
			hit.graphics.endFill();
			addChildAt(hit, 1);
			hit.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { mouseIn = true; });
			hit.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { mouseIn = false; });
			addEventListener(Event.ENTER_FRAME, tick);
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void {
				removeEventListener(Event.ENTER_FRAME, tick);
				if (ground) ground.dispose();
				canvas.dispose();
			});
		}

		/** The boss as the editor has it now (BossEditor.toDef), its arena map, and the class you test with. */
		public function setBoss(d:Object, map:Object, cls:String):void {
			var newMap:Boolean = map != mapObj || !world;
			def = d;
			heroCls = cls || "wizard";
			heroBmp.bitmapData = Sprites.get(heroCls);
			heroBmp.scaleX = heroBmp.scaleY = scale / Game.TS;
			if (newMap) { mapObj = map; buildArena(); reset(); }
			var bd:BitmapData = Sprites.get(def.spr);
			bossBmp.bitmapData = bd;
			bossBmp.scaleX = bossBmp.scaleY = scale / Game.TS;
			// (the phase list may have changed: re-pick, keeping the health it's at)
			while (timers.length < 8) { timers.push(0); spins.push(0); }
			var was:int = phase;
			phase = -1;
			setPhase(phaseAt(hp), was);
			drawBar();
		}

		/** Jumps to a phase (the editor's phase tabs): its health, a fresh start of its attacks. */
		public function showPhase(i:int):void {
			if (!def || i < 0 || i >= def.phases.length) return;
			hp = i == 0 ? 1 : Number(def.phases[i].hp) - 0.001;
			phase = -1;
			setPhase(phaseAt(hp), -1);
			shots.length = 0; markers.length = 0;
			drawBar();
		}

		// ------------------------------------------------------------ the arena
		private function buildArena():void {
			var m:Object = mapObj || Game.defaultArena();
			var prev:Object = World.customMap;
			World.customMap = m;
			world = new World("custom", "preview");
			World.customMap = prev;
			scale = Math.max(6, Math.min(16, Math.min((W - 8) / m.w, (H - 8) / m.h)));
			var cx:Number = world.mapX + m.w / 2, cy:Number = world.mapY + m.h / 2;
			if (ground) ground.dispose();
			ground = new BitmapData(W, H, false, 0xff0b0a10);
			var mtx:Matrix = new Matrix(scale / World.PX, 0, 0, scale / World.PX, W / 2 - cx * scale, H / 2 - cy * scale);
			// (the world builds only a couple of its ground chunks a call: enough calls for the whole arena)
			for (var pass:int = 0; pass < 24; pass++) world.drawGround(ground, mtx, cx, cy, Math.sqrt(W * W + H * H) / 2 / scale + 2);
			// the arena's objects (pillars, braziers, trees...)
			var om:Matrix = new Matrix();
			for (var y:int = 0; y < m.h; y++) for (var x:int = 0; x < m.w; x++) {
				var o:int = int(m.objs[y * m.w + x]);
				if (o <= 0 || !World.OBJ_NAMES[o]) continue;
				var ob:BitmapData = Sprites.get(World.OBJ_NAMES[o]);
				if (!ob) continue;
				var s:Number = scale / Game.TS;
				om.identity(); om.scale(s, s);
				om.translate(sx(world.mapX + x + 0.5) - ob.width * s / 2, sy(world.mapY + y + 1) - ob.height * s);
				ground.draw(ob, om);
			}
			homeX = world.mapX + m.boss[0] + 0.5; homeY = world.mapY + m.boss[1] + 0.5;
		}

		private function sx(x:Number):Number { var m:Object = mapObj || Game.defaultArena(); return W / 2 + (x - (world.mapX + m.w / 2)) * scale; }
		private function sy(y:Number):Number { var m:Object = mapObj || Game.defaultArena(); return H / 2 + (y - (world.mapY + m.h / 2)) * scale; }
		private function wx(px:Number):Number { var m:Object = mapObj || Game.defaultArena(); return (px - W / 2) / scale + world.mapX + m.w / 2; }
		private function wy(py:Number):Number { var m:Object = mapObj || Game.defaultArena(); return (py - H / 2) / scale + world.mapY + m.h / 2; }

		private function reset():void {
			bx = homeX; by = homeY;
			hx = world.spawnX; hy = world.spawnY;
			hp = 1; phase = -1; clock = 0; hits = 0; taken = 0;
			shots.length = 0; markers.length = 0; minions.length = 0;
			timers.length = 0; spins.length = 0;
			for (var i:int = 0; i < 8; i++) { timers.push(0); spins.push(0); }
			if (def) setPhase(0, -1);
		}

		// ------------------------------------------------------------ phases
		private function phaseAt(h:Number):int {
			var k:int = 0;
			for (var i:int = 0; i < def.phases.length; i++) if (h <= Number(def.phases[i].hp) + 1e-6) k = i;
			return k;
		}

		private function setPhase(k:int, was:int):void {
			if (k == phase) return;
			phase = k;
			var ph:Object = def.phases[k];
			for (var i:int = 0; i < timers.length; i++) timers[i] = (ph.attacks[i] ? Number(ph.attacks[i].cd) : 1) * (0.4 + i * 0.2);
			if (was >= 0 && k != was) {
				bannerTf.text = k > 0 ? "Phase " + (k + 1) + (ph.banner ? ": " + ph.banner : "") : "Phase 1";
				bannerT = 2;
				flashT = 0.5;
				shieldT = ph.shield || 0;
			}
			if (ph.say) { sayTf.text = "\"" + ph.say + "\""; sayT = 3; }
		}

		// ------------------------------------------------------------ the bar
		private static const PHASE_COLS:Array = [0xff6050, 0xffa030, 0xd060ff, 0x50b0ff];

		private function drawBar():void {
			var g:* = bar.graphics;
			g.clear();
			barLabels.removeChildren();
			if (!def) return;
			// each phase's stretch of health in its own colour, the health left bright
			for (var i:int = 0; i < def.phases.length; i++) {
				var top:Number = i == 0 ? 1 : Number(def.phases[i].hp);
				var bot:Number = i + 1 < def.phases.length ? Number(def.phases[i + 1].hp) : 0;
				var col:uint = PHASE_COLS[i % PHASE_COLS.length];
				g.beginFill(Sprites.shade(col, 0.28));
				g.drawRect(bot * W, 0, (top - bot) * W, BAR_H);
				g.endFill();
				var lit:Number = Math.max(bot, Math.min(top, hp));
				if (lit > bot) {
					g.beginFill(i == phase ? col : Sprites.shade(col, 0.7));
					g.drawRect(bot * W, 0, (lit - bot) * W, BAR_H);
					g.endFill();
				}
				// the line where this phase starts, and its name
				if (i > 0) {
					g.lineStyle(2, 0xffffff, 0.9);
					g.moveTo(top * W, -3); g.lineTo(top * W, BAR_H + 3);
					g.lineStyle();
				}
				var lab:TextField = Ui.text(11, i == phase ? 0xffffff : 0x9a9aaa, true, "center", 120, true);
				lab.text = "Phase " + (i + 1) + " · " + Math.round(top * 100) + "%";
				lab.x = Math.max(0, Math.min(W - 120, (top + bot) / 2 * W - 60));
				barLabels.addChild(lab);
			}
			g.lineStyle(1, 0x000000);
			g.drawRect(0, 0, W, BAR_H);
			g.lineStyle();
			// where the boss's health is now
			g.beginFill(0xffffff);
			g.moveTo(hp * W, -2); g.lineTo(hp * W - 5, -8); g.lineTo(hp * W + 5, -8);
			g.endFill();
		}

		private function barClick(e:MouseEvent):void {
			hp = Math.max(0.001, Math.min(1, bar.mouseX / W));
			setPhase(phaseAt(hp), phase);
			drawBar();
		}

		private function buildControls():void {
			controls.removeChildren();
			var items:Array = [
				[playing ? "Pause" : "Play", 70, function():void { playing = !playing; buildControls(); }],
				["Speed " + speed + "x", 80, function():void { speed = speed == 1 ? 2 : speed == 2 ? 0.5 : 1; buildControls(); }],
				[drain ? "Health drains: On" : "Health drains: Off", 140, function():void { drain = !drain; buildControls(); }],
				["Restart", 76, function():void { reset(); drawBar(); }]
			];
			var x:int = 0;
			for each (var it:Array in items) {
				var b:Sprite = Ui.button(it[0], it[1], 26, it[2], 12);
				b.x = x;
				controls.addChild(b);
				x += it[1] + 6;
			}
			var tip:TextField = Ui.text(11, 0x8a8a9a, false, "left", W - x);
			tip.text = "Mouse over the arena to steer the hero. Click the bar to jump to any health.";
			tip.x = x + 4; tip.y = -1;
			tip.wordWrap = true;
			controls.addChild(tip);
		}

		// ------------------------------------------------------------ the simulation
		private function tick(e:Event):void {
			if (!def || !world) return;
			var dt:Number = playing ? Ui.FRAME * speed : 0;
			if (dt > 0) step(dt);
			render();
		}

		private function step(dt:Number):void {
			clock += dt;
			var ph:Object = def.phases[phase];
			// the boss loses health by itself (a fight of about a minute and a half), and turns phases
			if (drain && shieldT <= 0) {
				hp -= dt / 90;
				if (hp <= 0) { reset(); bannerTf.text = "Defeated! Starting again"; bannerT = 2; }
				setPhase(phaseAt(hp), phase);
				drawBar();
			}
			if (shieldT > 0) shieldT -= dt;
			if (bannerT > 0) bannerT -= dt;
			if (sayT > 0) sayT -= dt;
			if (flashT > 0) flashT -= dt;
			moveHero(dt);
			moveBoss(dt, ph);
			// attacks
			if (shieldT <= 0) for (var i:int = 0; i < ph.attacks.length; i++) {
				timers[i] -= dt;
				if (timers[i] <= 0) { timers[i] += Math.max(0.05, Number(ph.attacks[i].cd)); fire(ph.attacks[i], i); }
			}
			// bullets
			for (var s:int = shots.length - 1; s >= 0; s--) {
				var b:Object = shots[s];
				b.x += b.vx * dt; b.y += b.vy * dt; b.life -= dt;
				var gone:Boolean = b.life <= 0 || world.blocksShot(b.x, b.y);
				if (!gone) {
					var dx:Number = b.x - hx, dy:Number = b.y - hy;
					if (dx * dx + dy * dy < (b.r + 0.35) * (b.r + 0.35)) { gone = true; hits++; taken += b.dmg; }
				}
				if (gone) shots.splice(s, 1);
			}
			// ground blasts
			for (var m:int = markers.length - 1; m >= 0; m--) {
				var mk:Object = markers[m];
				mk.t -= dt;
				if (mk.t > 0) continue;
				var ddx:Number = mk.x - hx, ddy:Number = mk.y - hy;
				if (ddx * ddx + ddy * ddy < mk.r * mk.r) { hits++; taken += mk.dmg; }
				var a:Object = mk.a;
				for (var k:int = 0; k < (a.burst || 0); k++) {
					var t:Number = mk.base + k * Math.PI * 2 / a.burst;
					addShot(mk.x, mk.y, t, a.bspd || 4, a.blife || 1.5, a, int(mk.dmg * 0.6));
				}
				markers.splice(m, 1);
			}
			// minions shamble toward the hero
			for each (var mn:Object in minions) {
				var mdx:Number = hx - mn.x, mdy:Number = hy - mn.y, md:Number = Math.sqrt(mdx * mdx + mdy * mdy) || 1;
				if (md > 1.2) { mn.x += mdx / md * 2.2 * dt; mn.y += mdy / md * 2.2 * dt; }
			}
		}

		private function moveHero(dt:Number):void {
			var tx:Number, ty:Number;
			if (mouseIn) { tx = wx(mouseX); ty = wy(mouseY); }
			else {
				// strafe round the arena, a fair way from the boss
				heroA += dt * 0.7;
				tx = homeX + Math.cos(heroA) * 6.5; ty = homeY + 5 + Math.sin(heroA) * 3.5;
			}
			var dx:Number = tx - hx, dy:Number = ty - hy, d:Number = Math.sqrt(dx * dx + dy * dy);
			if (d < 0.05) return;
			var v:Number = Math.min(d, 7 * dt);
			var nx:Number = hx + dx / d * v, ny:Number = hy + dy / d * v;
			if (world.walkable(nx, hy)) hx = nx;
			if (world.walkable(hx, ny)) hy = ny;
		}

		private function moveBoss(dt:Number, ph:Object):void {
			var ux:Number = hx - bx, uy:Number = hy - by, dist:Number = Math.sqrt(ux * ux + uy * uy) || 1;
			ux /= dist; uy /= dist;
			var mvx:Number = 0, mvy:Number = 0;
			switch (ph.move) {
				case "chase": if (dist > 3) { mvx = ux; mvy = uy; } break;
				case "orbit":
					orbitA += dt * 0.6;
					var ox:Number = homeX + Math.cos(orbitA) * 4.5 - bx, oy:Number = homeY + Math.sin(orbitA) * 4.5 - by;
					var od:Number = Math.sqrt(ox * ox + oy * oy) || 1;
					mvx = ox / od * Math.min(1, od); mvy = oy / od * Math.min(1, od);
					break;
				case "charge":
					chargeT -= dt;
					if (chargeT <= 0) chargeT = 3;
					if (chargeT < 0.6) { mvx = ux * 3; mvy = uy * 3; }
					break;
				case "center": mvx = (homeX - bx) * 0.5; mvy = (homeY - by) * 0.5; break;
				case "still": break;
				default:
					wanderT -= dt;
					if (wanderT <= 0) { wanderT = 1.5 + Math.random() * 1.5; wanderA = Math.random() * Math.PI * 2; }
					mvx = Math.cos(wanderA) * 0.6; mvy = Math.sin(wanderA) * 0.6;
			}
			// bosses keep near home
			var leash:Number = ph.move == "chase" || ph.move == "charge" ? 64 : 25;
			var lx:Number = homeX - bx, ly:Number = homeY - by;
			if (lx * lx + ly * ly > leash) { mvx = lx * 0.2; mvy = ly * 0.2; }
			if (shieldT > 0 && ph.move != "orbit") { mvx = 0; mvy = 0; }
			var spd:Number = Number(def.spd) || 1;
			var nx:Number = bx + mvx * spd * dt, ny:Number = by + mvy * spd * dt;
			if (world.walkable(nx, by)) bx = nx;
			if (world.walkable(bx, ny)) by = ny;
		}

		private function fire(a:Object, i:int):void {
			var dx:Number = hx - bx, dy:Number = hy - by;
			var ang:Number = Math.atan2(dy, dx), dist:Number = Math.sqrt(dx * dx + dy * dy);
			var n:int = a.n || 1, k:int, t:Number;
			var spin0:Number = a.p == "rain" || a.p == "wall" ? Math.random() * 1000 : spins[i];
			switch (a.p) {
				case "summon":
					var alive:int = 0;
					for each (var mn:Object in minions) if (mn.what == a.what) alive++;
					for (k = 0; k < a.n && alive + k < (a.max || 6); k++)
						minions.push({x: bx + Math.random() * 2 - 1, y: by + Math.random() * 2 - 1, what: a.what, bd: Sprites.get(Data.ENEMIES[a.what] ? Data.ENEMIES[a.what].spr : "skeleton")});
					return;
				case "aimed":
					for (k = 0; k < n; k++) {
						t = n > 1 ? ang + (k / (n - 1) - 0.5) * a.arc * DEG : ang;
						addShot(bx, by, t, a.spd, a.life, a, a.dmg);
					}
					break;
				case "flower":
					for (k = 0; k < n; k++) addShot(bx, by, spin0 + k * Math.PI * 2 / n, k % 2 == 0 ? a.spd : a.spd * (a.slow || 0.55), a.life, a, a.dmg);
					break;
				case "wall":
					var gap:int = int(spin0) % n;
					var px:Number = -Math.sin(ang), py:Number = Math.cos(ang);
					for (k = 0; k < n; k++) {
						if (Math.abs(k - gap) <= (a.hole || 1) - 1) continue;
						var off:Number = (k - (n - 1) / 2) * (a.spacing || 0.7);
						addShot(bx + px * off, by + py * off, ang, a.spd, a.life, a, a.dmg);
					}
					break;
				case "nova":
					var nd:Number = Math.min(dist, a.reach || 9);
					markers.push({x: bx + Math.cos(ang) * nd, y: by + Math.sin(ang) * nd, r: a.radius || 1.6, t: a.delay || 1, t0: a.delay || 1, a: a, dmg: a.dmg, base: spin0, col: a.col});
					break;
				case "rain":
					var rd:Number = Math.min(dist, a.reach || 9);
					var cx:Number = bx + Math.cos(ang) * rd, cy:Number = by + Math.sin(ang) * rd;
					for (k = 0; k < n; k++) {
						var ra:Number = Math.random() * Math.PI * 2, rr:Number = k == 0 ? 0 : 1 + Math.random() * (a.spread || 4);
						markers.push({x: cx + Math.cos(ra) * rr, y: cy + Math.sin(ra) * rr, r: a.radius || 1.2, t: (a.delay || 1) + k * (a.stagger || 0.12), t0: (a.delay || 1) + k * (a.stagger || 0.12), a: a, dmg: a.dmg, base: ra, col: a.col});
					}
					break;
				default: // ring, spiral
					for (k = 0; k < n; k++) addShot(bx, by, spin0 + k * Math.PI * 2 / n, a.spd, a.life, a, a.dmg);
			}
			if (a.p == "ring" || a.p == "spiral" || a.p == "flower") spins[i] += (a.rot || 0) * DEG;
		}

		private function addShot(x:Number, y:Number, t:Number, spd:Number, life:Number, a:Object, dmg:int):void {
			if (shots.length > 600) return;
			shots.push({x: x, y: y, vx: Math.cos(t) * spd, vy: Math.sin(t) * spd, life: life || 1.5, r: a.r || 0.22, col: a.col, dmg: dmg});
		}

		// ------------------------------------------------------------ drawing
		private function render():void {
			canvas.copyPixels(ground, ground.rect, ORIGIN);
			var g:* = fx.graphics;
			g.clear();
			// ground blasts: a ring that fills as it comes
			for each (var mk:Object in markers) {
				var f:Number = 1 - Math.max(0, mk.t) / mk.t0;
				g.lineStyle(1.5, mk.col, 0.9);
				g.beginFill(mk.col, 0.12 + 0.25 * f);
				g.drawCircle(sx(mk.x), sy(mk.y), mk.r * scale);
				g.endFill();
				g.lineStyle();
				g.beginFill(mk.col, 0.35);
				g.drawCircle(sx(mk.x), sy(mk.y), mk.r * scale * f);
				g.endFill();
			}
			// the shield a boss raises between phases
			if (shieldT > 0) {
				g.lineStyle(2, 0xffffff, 0.5 + 0.4 * Math.sin(clock * 12));
				g.drawCircle(sx(bx), sy(by), 1.6 * scale);
				g.lineStyle();
			}
			// minions
			for each (var mn:Object in minions) {
				g.beginBitmapFill(mn.bd, new Matrix(scale / Game.TS, 0, 0, scale / Game.TS, sx(mn.x) - mn.bd.width * scale / Game.TS / 2, sy(mn.y) - mn.bd.height * scale / Game.TS / 2), false, false);
				g.drawRect(sx(mn.x) - mn.bd.width * scale / Game.TS / 2, sy(mn.y) - mn.bd.height * scale / Game.TS / 2, mn.bd.width * scale / Game.TS, mn.bd.height * scale / Game.TS);
				g.endFill();
			}
			// bullets: their colour, with a bright core
			for each (var b:Object in shots) {
				var r:Number = Math.max(2, b.r * scale * 1.3);
				g.beginFill(0x000000, 0.5);
				g.drawCircle(sx(b.x), sy(b.y), r + 1);
				g.endFill();
				g.beginFill(b.col);
				g.drawCircle(sx(b.x), sy(b.y), r);
				g.endFill();
				g.beginFill(0xffffff, 0.8);
				g.drawCircle(sx(b.x), sy(b.y), r * 0.4);
				g.endFill();
			}
			// a flash as a new phase begins
			if (flashT > 0) {
				g.beginFill(0xffffff, flashT * 0.5);
				g.drawRect(0, 0, W, H);
				g.endFill();
			}
			if (bossBmp.bitmapData) {
				bossBmp.x = sx(bx) - bossBmp.width / 2; bossBmp.y = sy(by) - bossBmp.height / 2;
			}
			if (heroBmp.bitmapData) {
				heroBmp.x = sx(hx) - heroBmp.width / 2; heroBmp.y = sy(hy) - heroBmp.height / 2;
			}
			sayTf.visible = sayT > 0;
			sayTf.x = Math.max(0, Math.min(W - 300, sx(bx) - 150)); sayTf.y = Math.max(0, sy(by) - bossBmp.height / 2 - 22);
			bannerTf.visible = bannerT > 0;
			bannerTf.alpha = Math.min(1, bannerT);
			var mins:Number = Math.max(clock, 1) / 60;
			statTf.text = "Hits on the hero: " + hits + "  ·  " + Ui.commas(int(taken / mins)) + " damage a minute  ·  " + shots.length + " bullets";
		}
	}
}
