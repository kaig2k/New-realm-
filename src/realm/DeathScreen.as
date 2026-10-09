package realm {
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class DeathScreen extends Sprite {
		private var onDone:Function;
		private var reveal:Array = [];
		private var t:Number = 0;
		private var fameTf:TextField;
		private var fameTotal:int;
		/** Advice for new players, one shown at random. */
		private static const TIPS:Array = [
			"press R (or step into the Nexus portal) to escape to safety whenever a fight goes badly. It's always better than dying.",
			"drink a health potion (F) early, not at the last moment. The fountain in the Nexus refills you for free.",
			"stay near the beach and lowlands until you're level 10 or so. The middle of the realm is much more dangerous.",
			"red rings on the ground mean a blast is coming there. Step out of them.",
			"Defense makes every hit hurt less. Stat potions from bosses raise your stats for good.",
			"party up with other players: everyone who hits a monster gets their own loot."
		];

		public function DeathScreen(info:Object, onDone:Function) {
			this.onDone = onDone;
			graphics.beginFill(0x0c0a10);
			graphics.drawRect(0, 0, Ui.W, Ui.H);
			graphics.endFill();
			var bonuses:Array = info.bonuses || [];
			var listH:int = bonuses.length ? 30 + bonuses.length * 22 : 0;
			// what killed you: the damage you took in your last 5 seconds
			var recap:Array = info.recap && info.recap.list ? info.recap.list : [];
			var recapH:int = recap.length ? 34 + recap.length * 20 : 0;
			listH += recapH;
			// with a long bonus list the gravestone is dropped to make room
			// new players: what they keep, and a tip for next time
			var tipH:int = info.newbie ? 92 : 0;
			var compact:Boolean = bonuses.length > 3 || listH + tipH > 150;
			var panelH:int = 520 + listH + tipH - (compact ? 100 : 0);
			var top:int = Math.max(4, int((Ui.H - panelH) / 2));
			Ui.panel(graphics, Ui.W / 2 - 290, top, 580, panelH, 0x1e1e22, 0x4a4a4a);

			var grave:Bitmap = new Bitmap(Sprites.get("grave"));
			grave.scaleX = grave.scaleY = 2;
			grave.x = Ui.W / 2 - grave.width / 2;
			grave.y = top + 24;
			if (!compact) addChild(grave);
			if (compact) top -= 100;

			var t:TextField = Ui.text(44, 0xe03030, true, "center", Ui.W, true);
			t.text = "You Died";
			t.y = top + 124;
			addChild(t);

			var mins:int = int(info.time / 60), secs:int = int(info.time % 60);
			var body:TextField = Ui.text(18, 0xdddddd, false, "center", Ui.W, true);
			body.htmlText = "<b>" + info.name + "</b>, a level " + info.level + " " + info.cls + ",\nwas killed by <font color='#ff9a2e'><b>" + info.killer + (info.killedWith ? "'s " + info.killedWith : "") + "</b></font>\n\n" +
				"Monsters slain: <b>" + info.kills + "</b>      Overlords slain: <b>" + info.bosses + "</b>\n" +
				"Time survived: <b>" + mins + "m " + (secs < 10 ? "0" : "") + secs + "s</b>";
			body.y = top + 190;
			addChild(body);

			var y:int = top + 334;
			if (recap.length) {
				var rh:TextField = Ui.text(15, 0xff7060, true, "center", Ui.W, true);
				rh.htmlText = "Your last 5 seconds: <font color='#ffffff'>" + Ui.commas(info.recap.total) + "</font> damage taken";
				rh.y = y;
				addChild(rh);
				y += 26;
				for each (var hit:Object in recap) {
					var who:TextField = Ui.text(13, 0xe8e0c8, true, "left", 330, true);
					who.htmlText = hit.src + (hit.atk ? "  <font color='#a0a0a8'>" + hit.atk + "</font>" : "") +
						(hit.n > 1 ? "  <font color='#808088'>x" + hit.n + "</font>" : "") +
						(hit.eff ? "  <font color='#c080ff'>(" + hit.eff + ")</font>" : "");
					who.x = Ui.W / 2 - 250; who.y = y;
					addChild(who);
					var amt0:TextField = Ui.text(13, 0xff6050, true, "right", 120, true);
					amt0.text = "-" + Ui.commas(hit.d);
					amt0.x = Ui.W / 2 + 130; amt0.y = y;
					addChild(amt0);
					// a bar showing its share of the damage
					graphics.beginFill(0x5a1a1a);
					graphics.drawRect(Ui.W / 2 + 90, y + 6, 40 * hit.d / Math.max(1, info.recap.total), 8);
					graphics.endFill();
					y += 20;
				}
				graphics.lineStyle(1, 0x4a4a4a);
				graphics.moveTo(Ui.W / 2 - 250, y + 4);
				graphics.lineTo(Ui.W / 2 + 250, y + 4);
				graphics.lineStyle();
				y += 10;
			}
			if (bonuses.length) {
				// RotMG-style fame bonus breakdown
				var rows:Array = [["Base fame", "", Ui.commas(info.baseFame || 0)]];
				for each (var b:Object in bonuses) rows.push([b.name, b.desc + " (+" + b.pct + "%)", "+" + Ui.commas(b.fame)]);
				for (var r:int = 0; r < rows.length; r++) {
					var name:TextField = Ui.text(15, r == 0 ? 0xdddddd : 0xffd75e, true, "left", 160, true);
					name.text = rows[r][0];
					name.x = Ui.W / 2 - 250; name.y = y;
					addChild(name);
					var desc:TextField = Ui.text(13, 0x999999, false, "left", 260, true);
					desc.text = rows[r][1];
					desc.x = Ui.W / 2 - 100; desc.y = y + 2;
					addChild(desc);
					var amt:TextField = Ui.text(15, r == 0 ? 0xdddddd : 0xff9a2e, true, "right", 90, true);
					amt.text = rows[r][2];
					amt.x = Ui.W / 2 + 160; amt.y = y;
					addChild(amt);
					y += 22;
				}
				graphics.lineStyle(1, 0x4a4a4a);
				graphics.moveTo(Ui.W / 2 - 250, y + 4);
				graphics.lineTo(Ui.W / 2 + 250, y + 4);
				graphics.lineStyle();
				y += 8;
			}

			var fameIcon:Bitmap = new Bitmap(Sprites.get("fame"));
			var fame:TextField = Ui.text(34, 0xff9a2e, true, "center", Ui.W, true);
			fame.text = Ui.commas(info.fame) + " Fame";
			var fameW:Number = fame.textWidth;
			fame.text = "0 Fame";
			fameTf = fame;
			fameTotal = info.fame;
			fame.y = y + 12;
			addChild(fame);
			fameIcon.x = Ui.W / 2 - fameW / 2 - 44;
			fameIcon.y = y + 22;
			addChild(fameIcon);
			if (info.best) {
				var best:TextField = Ui.text(17, Ui.GOLD, true, "center", Ui.W, true);
				best.text = "New personal best!";
				best.y = y + 58;
				addChild(best);
			}

			if (info.newbie) {
				var tip:TextField = Ui.text(13, 0xc8e8c8, false, "center", 520, true);
				tip.htmlText = "Every hero can fall: it's part of Eldmere. <b>You keep</b> your gold, Aether, the fame you just earned, your vault, pets and unlocks.\n" +
					"<font color='#ffd75e'>Tip:</font> " + TIPS[int(Math.random() * TIPS.length)];
				tip.x = Ui.W / 2 - 260; tip.y = y + 100;
				addChild(tip);
				y += tipH;
			}
			var btn:Sprite = Ui.button("Return to Menu", 240, 46, finish);
			btn.x = Ui.W / 2 - 120;
			btn.y = y + 116;
			addChild(btn);

			// fade in from black, then reveal each line in turn (like RotMG's death screen)
			for (var ci:int = 0; ci < numChildren; ci++) {
				var ch:DisplayObject = getChildAt(ci);
				reveal.push({o: ch, y: ch.y});
				ch.alpha = 0;
			}
			alpha = 0;
			addEventListener(Event.ENTER_FRAME, animate);
			addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void {
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			});
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void {
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
				removeEventListener(Event.ENTER_FRAME, animate);
			});
		}

		private function animate(e:Event):void {
			t += 1 / 60;
			alpha = Math.min(1, t / 0.9);
			for (var i:int = 0; i < reveal.length; i++) {
				var k:Number = Math.max(0, Math.min(1, (t - 0.7 - i * 0.07) / 0.4));
				var ease:Number = 1 - (1 - k) * (1 - k);
				reveal[i].o.alpha = ease;
				reveal[i].o.y = reveal[i].y + (1 - ease) * 14;
			}
			var f:Number = Math.max(0, Math.min(1, (t - 1.4) / 1.3));
			fameTf.text = Ui.commas(int(fameTotal * (1 - (1 - f) * (1 - f)))) + " Fame";
			if (t > 4) removeEventListener(Event.ENTER_FRAME, animate);
		}

		private function onKey(e:KeyboardEvent):void {
			if (t < 0.8) return;
			if (e.keyCode == Keyboard.ENTER) finish();
		}

		private function finish():void {
			var f:Function = onDone;
			onDone = null;
			if (f != null) f();
		}
	}
}
