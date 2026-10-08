package realm {
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.display.GradientType;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;

	/**
	 * The home screen (RotMG's title screen): logo, PLAY, and the account controls.
	 * PLAY goes to character select once you're logged in.
	 */
	public class TitleScreen extends Sprite {
		public static const VERSION:String = "v1.1";
		/** Eldmere's pixel-art title (castle in the portal over the name band), shown when this is the Eldmere server. */
		[Embed(source="../../assets/branding/title_logo.png")]
		private static const TITLE_ART:Class;

		private var onPlay:Function;
		private var accountLayer:Sprite;
		private var dialog:Sprite;
		private var errorTf:TextField;
		private var fields:Array;
		private var submit:Function;
		private var heroes:Array = [];

		public function TitleScreen(onPlay:Function) {
			this.onPlay = onPlay;
			addChild(new Backdrop(0.4));
			buildArt();

			// a row of heroes standing under the logo
			var ids:Array = Data.CLASS_ORDER;
			var ground:Shape = new Shape();
			var gmx:Matrix = new Matrix();
			gmx.createGradientBox(ids.length * 80, 60, 0, Ui.W / 2 - ids.length * 40, 318);
			ground.graphics.beginGradientFill(GradientType.RADIAL, [0xffb040, 0xffb040], [0.28, 0], [0, 255], gmx);
			ground.graphics.drawEllipse(Ui.W / 2 - ids.length * 40, 318, ids.length * 80, 60);
			ground.graphics.endFill();
			for (var gi:int = 0; gi < ids.length; gi++) {
				ground.graphics.beginFill(0x000000, 0.35);
				ground.graphics.drawEllipse(Ui.W / 2 - (ids.length * 70) / 2 + gi * 70 + 20, 350, 40, 10);
				ground.graphics.endFill();
			}
			addChild(ground);
			for (var i:int = 0; i < ids.length; i++) {
				var hb:Bitmap = new Bitmap(Sprites.get(ids[i], 0, i >= ids.length / 2));
				hb.scaleX = hb.scaleY = 1.1;
				hb.x = Ui.W / 2 - (ids.length * 70) / 2 + i * 70 + 14;
				hb.y = 300;
				addChild(hb);
				heroes.push(hb);
			}

			logo = new Logo(Online.connected ? Online.serverName : Data.WORLD_NAME, 118);
			logo.x = Ui.W / 2;
			logo.y = 58;
			addChild(logo);
			art = new TITLE_ART() as Bitmap;
			art.smoothing = false;
			art.scaleX = art.scaleY = 2;
			art.x = int((Ui.W - art.width) / 2);
			art.y = 6;
			art.filters = [artGlow, artShadow];
			addChild(art);
			showTitle();
			var tag:TextField = Ui.text(17, 0xf0e4c0, true, "center", Ui.W, true);
			tag.text = "FIGHT YOUR WAY ACROSS THE REALMS";
			tag.y = 266;
			addChild(tag);
			// ornaments either side of the tagline
			var orn:Shape = new Shape();
			var half:Number = tag.textWidth / 2 + 18;
			for (var sd:int = -1; sd <= 1; sd += 2) {
				var ox:Number = Ui.W / 2 + sd * half, oy:Number = tag.y + tag.height / 2;
				orn.graphics.lineStyle(2, 0xffc040, 0.8);
				orn.graphics.moveTo(ox, oy); orn.graphics.lineTo(ox + sd * 120, oy);
				orn.graphics.lineStyle(1, 0xffc040, 0.35);
				orn.graphics.moveTo(ox + sd * 10, oy + 4); orn.graphics.lineTo(ox + sd * 90, oy + 4);
				orn.graphics.lineStyle(1.5, 0x2a1200);
				orn.graphics.beginFill(0xffd75e);
				var dx:Number = ox + sd * 128;
				orn.graphics.moveTo(dx, oy - 6); orn.graphics.lineTo(dx + 6, oy); orn.graphics.lineTo(dx, oy + 6); orn.graphics.lineTo(dx - 6, oy); orn.graphics.lineTo(dx, oy - 6);
				orn.graphics.endFill();
			}
			addChildAt(orn, getChildIndex(tag));

			var play:Sprite = goldButton("PLAY", 260, 64, clickPlay);
			play.x = (Ui.W - 260) / 2;
			play.y = 400;
			addChild(play);

			// multiplayer: join a New Realm server
			onlineLayer = new Sprite();
			addChild(onlineLayer);
			refreshOnline();

			accountLayer = new Sprite();
			addChild(accountLayer);
			refreshAccount();

			var ver:TextField = Ui.text(13, 0xaaaaaa, false, "left", 700, true);
			ver.text = VERSION + "  -  your characters are saved on the server";
			ver.x = 14; ver.y = Ui.H - 26;
			addChild(ver);

			addEventListener(Event.ENTER_FRAME, animate);
			addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void {
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			});
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void {
				// only when the title screen itself goes (not one of its texts or buttons being redrawn)
				if (e.target != e.currentTarget) return;
				removeEventListener(Event.ENTER_FRAME, animate);
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
			});
			// the game is online-only: pick up this PC's remembered login, or ask for one
			if (Online.connected) {}
			else if (Accounts.remembered(server)) resume(null);
			else if (server && Accounts.setting("server")) showLogin();
			else showRegister();
		}

		private var t:Number = 0;
		private var logo:Logo;
		private var art:Bitmap;
		private var artGlow:GlowFilter = new GlowFilter(0xff4dff, 0.45, 18, 18, 1.4, 2);
		private var artShadow:DropShadowFilter = new DropShadowFilter(6, 90, 0x000000, 0.6, 8, 8, 1, 2);

		/** Eldmere gets its pixel-art title; any other server shows its own name in gold. */
		private function showTitle():void {
			var name:String = Online.connected ? Online.serverName : Data.WORLD_NAME;
			var ours:Boolean = String(name).toUpperCase() == Data.WORLD_NAME.toUpperCase();
			if (art) art.visible = ours;
			if (logo) { logo.visible = !ours; logo.setText(name); }
		}
		private var rune:Sprite;
		private var embers:Shape;
		private var ember:Array = [];

		/** Behind the name: a slowly turning ring of runes, rising embers and a dark vignette. */
		private function buildArt():void {
			var vig:Shape = new Shape();
			var vm:Matrix = new Matrix();
			vm.createGradientBox(Ui.W * 1.3, Ui.H * 1.5, 0, -Ui.W * 0.15, -Ui.H * 0.25);
			vig.graphics.beginGradientFill(GradientType.RADIAL, [0x000000, 0x000000, 0x000000], [0, 0.15, 0.75], [0, 150, 255], vm);
			vig.graphics.drawRect(0, 0, Ui.W, Ui.H);
			vig.graphics.endFill();
			// a darker band at the top so the name stands out
			var top:Shape = new Shape();
			var tm:Matrix = new Matrix();
			tm.createGradientBox(Ui.W, 280, Math.PI / 2, 0, 0);
			top.graphics.beginGradientFill(GradientType.LINEAR, [0x0a0612, 0x0a0612], [0.7, 0], [0, 255], tm);
			top.graphics.drawRect(0, 0, Ui.W, 280);
			top.graphics.endFill();
			addChild(top);
			addChild(vig);

			rune = new Sprite();
			var g:* = rune.graphics;
			var R:Number = 190;
			g.lineStyle(2, 0xffc040, 0.32); g.drawCircle(0, 0, R);
			g.lineStyle(1, 0xffc040, 0.22); g.drawCircle(0, 0, R - 14);
			g.lineStyle(1, 0xffc040, 0.16); g.drawCircle(0, 0, R + 12);
			for (var k:int = 0; k < 48; k++) {
				var a:Number = k / 48 * Math.PI * 2, long:Boolean = k % 6 == 0;
				g.lineStyle(long ? 2 : 1, 0xffc040, long ? 0.4 : 0.22);
				g.moveTo(Math.cos(a) * (R - 14), Math.sin(a) * (R - 14));
				g.lineTo(Math.cos(a) * (R - (long ? 30 : 20)), Math.sin(a) * (R - (long ? 30 : 20)));
			}
			// an eight-pointed star woven through the ring
			g.lineStyle(1.5, 0xffc040, 0.18);
			for (k = 0; k < 8; k++) {
				var a1:Number = k / 8 * Math.PI * 2, a2:Number = (k + 3) / 8 * Math.PI * 2;
				g.moveTo(Math.cos(a1) * (R - 14), Math.sin(a1) * (R - 14));
				g.lineTo(Math.cos(a2) * (R - 14), Math.sin(a2) * (R - 14));
			}
			for (k = 0; k < 8; k++) {
				var da:Number = k / 8 * Math.PI * 2 + Math.PI / 8;
				var px:Number = Math.cos(da) * R, py:Number = Math.sin(da) * R;
				g.lineStyle(1.5, 0x2a1200, 0.6);
				g.beginFill(0xffd75e, 0.55);
				g.moveTo(px, py - 7); g.lineTo(px + 5, py); g.lineTo(px, py + 7); g.lineTo(px - 5, py); g.lineTo(px, py - 7);
				g.endFill();
			}
			rune.x = Ui.W / 2; rune.y = 132;
			rune.scaleY = 0.62;
			rune.filters = [new GlowFilter(0xff9a20, 0.5, 10, 10, 1.5)];
			addChild(rune);

			embers = new Shape();
			embers.filters = [new GlowFilter(0xff8a20, 0.9, 6, 6, 2)];
			for (k = 0; k < 70; k++) ember.push(newEmber(true));
			addChild(embers);
		}

		private var playGlow:GlowFilter = new GlowFilter(0xffa020, 0.5, 18, 18, 1.6, 2);
		private var playBtn:Sprite;

		/** The big gold PLAY button, glowing gently. */
		private function goldButton(label:String, w:int, h:int, onClick:Function):Sprite {
			var b:Sprite = new Sprite();
			var bg:Shape = new Shape();
			b.addChild(bg);
			var tf:TextField = Ui.text(32, 0x3a1c00, true, "center", w);
			tf.text = label;
			tf.y = (h - tf.height) / 2;
			tf.filters = [new GlowFilter(0xfff4c0, 0.8, 2, 2, 3)];
			b.addChild(tf);
			b.buttonMode = true;
			b.mouseChildren = false;
			var draw:Function = function(hover:Boolean):void {
				var g:* = bg.graphics;
				g.clear();
				var m:Matrix = new Matrix();
				m.createGradientBox(w, h, Math.PI / 2, 0, 0);
				g.lineStyle(3, 0x4a2400);
				g.beginGradientFill(GradientType.LINEAR, hover ? [0xfff6c8, 0xffd040, 0xe08a10] : [0xffe48a, 0xf0b428, 0xb86a10], [1, 1, 1], [0, 130, 255], m);
				g.drawRoundRect(0, 0, w, h, 16, 16);
				g.endFill();
				g.lineStyle(1.5, 0xfff8d8, 0.8);
				g.drawRoundRect(4, 4, w - 8, h - 8, 12, 12);
				g.lineStyle();
				g.beginFill(0xffffff, hover ? 0.3 : 0.2);
				g.drawRoundRect(6, 6, w - 12, h * 0.38, 10, 10);
				g.endFill();
			};
			draw(false);
			b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
			b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
			b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onClick(); });
			playBtn = b;
			return b;
		}

		private function newEmber(anywhere:Boolean):Object {
			return {x: Math.random() * Ui.W, y: anywhere ? Math.random() * Ui.H : Ui.H + 10, vy: 18 + Math.random() * 40,
				ph: Math.random() * 6.28, r: 0.8 + Math.random() * 1.8, life: 0, col: Math.random() < 0.7 ? 0xffb040 : 0xffe9a0};
		}

		/** Seconds until we next look for the server after a restart. */
		private var retryT:Number = 3;

		private function animate(e:Event):void {
			t += 1 / 60;
			// dropped out of a game: keep knocking until the server is back, then log in again
			if (Online.dropped && !Online.connected && !connecting && !dialog && server && Accounts.remembered(server)) {
				retryT -= 1 / 60;
				if (retryT <= 0) { retryT = 5; resume(null); }
			}
			if (playBtn) {
				playGlow.alpha = 0.35 + 0.3 * Math.sin(t * 2.4);
				playGlow.blurX = playGlow.blurY = 14 + 8 * Math.sin(t * 2.4);
				playBtn.filters = [playGlow];
			}
			if (art && art.visible) {
				// the portal's neon breathes
				artGlow.alpha = 0.38 + 0.18 * Math.sin(t * 1.7);
				art.filters = [artGlow, artShadow];
			}
			if (rune) {
				rune.rotation += 0.04;
				var eg:* = embers.graphics;
				eg.clear();
				for (var n:int = 0; n < ember.length; n++) {
					var m:Object = ember[n];
					m.life += 1 / 60;
					m.y -= m.vy / 60;
					m.x += Math.sin(t * 1.3 + m.ph) * 0.35;
					if (m.y < -10) { ember[n] = newEmber(false); continue; }
					var fa:Number = Math.min(1, m.life * 2) * Math.min(1, m.y / 200) * (0.6 + 0.4 * Math.sin(t * 5 + m.ph));
					if (fa <= 0) continue;
					eg.beginFill(m.col, fa);
					eg.drawCircle(m.x, m.y, m.r);
					eg.endFill();
				}
			}
			for (var i:int = 0; i < heroes.length; i++) {
				var walk:Boolean = int(t * 3 + i) % 4 == 0;
				heroes[i].bitmapData = Sprites.get(Data.CLASS_ORDER[i], walk ? 1 : 0, i >= heroes.length / 2);
				heroes[i].y = 300 - (walk ? 3 : 0);
			}
		}

		private function onKey(e:KeyboardEvent):void {
			if (e.keyCode != Keyboard.ENTER) return;
			if (dialog && submit != null) submit();
			else if (!dialog) clickPlay();
		}

		private var onlineLayer:Sprite;

		/** Connecting to the server right now, and the last connection error. */
		private var connecting:Boolean = false;
		private var netError:String;

		/** The server this game plays on: baked into the build, or the last one used. */
		private function get server():String {
			return ServerConfig.home || Accounts.setting("server");
		}

		private function refreshOnline():void {
			showTitle();
			onlineLayer.removeChildren();
			var tf:TextField = Ui.text(15, 0xdddddd, true, "center", Ui.W, true);
			tf.htmlText = Online.outdated ? "<font color='#ffd75e'>" + Online.serverName + " has been updated!</font> Close the game and open it again to play the new version."
				: Online.dropped && !Online.connected ? "<font color='#ffd75e'>The server is restarting</font> (probably for an update). Waiting for it to come back..."
				: Online.dropped ? "<font color='#5ae06a'>" + Online.serverName + " is back!</font> Press PLAY to rejoin."
				: Online.connected ? "Online: <font color='#5ae06a'>" + Online.serverName + "</font>  (" + Online.welcome.online + " playing)"
				: connecting ? "Connecting to the server..."
				: netError ? "<font color='#ff8080'>Couldn't reach the server.</font> Press PLAY to try again."
				: "Log in or create an account to play.";
			tf.y = 478;
			onlineLayer.addChild(tf);
			// builds without a baked-in server can switch servers here
			if (!ServerConfig.home) {
				var b:Sprite = Ui.button(server ? "Server: " + server : "Choose server", 260, 30, showServer, 13);
				b.x = (Ui.W - 260) / 2;
				b.y = 508;
				onlineLayer.addChild(b);
			}
		}

		private function showServer():void {
			openDialog("Game server", ["Server address (ask the host)"], [false], "Save", function():void {
				var addr:String = fields[0].text.replace(/^\s+|\s+$/g, "");
				if (!addr) { errorTf.text = "Enter the server address."; return; }
				if (Online.connected) Online.signOut();
				Accounts.setSetting("server", addr);
				Accounts.logout();
				closeDialog();
				refreshAccount();
				refreshOnline();
				if (Accounts.remembered(addr)) resume(null); else showLogin();
			}, null, null, {maxChars: 80, restrict: "A-Za-z0-9.:\\-", values: [server || "localhost:" + Online.DEFAULT_PORT]});
		}

		private function clickPlay():void {
			// this copy of the game is older than the server's: it has to be reopened
			if (Online.outdated) { refreshOnline(); return; }
			if (Online.connected) { Online.dropped = false; onPlay(); }
			else if (server && Accounts.remembered(server)) resume(onPlay);
			else showLogin();
		}

		/** Logs back in with this PC's remembered session, then runs `then` (if any). */
		private function resume(then:Function):void {
			if (connecting) return;
			connecting = true;
			netError = null;
			refreshOnline();
			Online.connect(server, function(err:String):void {
				connecting = false;
				refreshAccount();
				if (!err) { netError = null; refreshOnline(); if (then != null) then(); return; }
				// the server no longer knows this PC's session: log in with a password
				if (!Accounts.remembered(server)) { refreshOnline(); showLogin(err); return; }
				netError = err;
				refreshOnline();
				if (then == null) return;
				openDialog("Server unavailable", [], [], "Retry", function():void { closeDialog(); resume(then); });
				errorTf.text = err;
			});
		}

		/** Logs in or registers on the server, then into the game. */
		private function serverLogin(name:String, pw:String, register:Boolean, addr:String):void {
			if (!addr) { errorTf.text = "Enter the server address."; return; }
			errorTf.textColor = 0xcccccc;
			errorTf.text = register ? "Creating your account..." : "Logging in...";
			connecting = true;
			Online.connect(addr, function(err:String):void {
				connecting = false;
				errorTf.textColor = 0xff7070;
				if (err) { errorTf.text = err; return; }
				netError = null;
				done();
				refreshOnline();
				onPlay();
			}, {name: name, password: pw, register: register});
		}

		/** Top-right account box: logged in as X, or log in / register buttons. */
		private function refreshAccount():void {
			accountLayer.removeChildren();
			accountLayer.graphics.clear();
			var w:int = 300;
			Ui.panel(accountLayer.graphics, Ui.W - w - 16, 14, w, 84, 0x1c1c22, 0x5a5a6a, 0.9);
			var info:TextField = Ui.text(15, 0xffffff, true, "center", w, true);
			info.x = Ui.W - w - 16; info.y = 22;
			accountLayer.addChild(info);
			var b1:Sprite, b2:Sprite;
			if (Accounts.current) {
				info.htmlText = "Logged in as <font color='#ffd75e'>" + Accounts.current + "</font>";
				b1 = Ui.button("Log out", 130, 32, function():void { Online.logout(); refreshAccount(); refreshOnline(); showLogin(); }, 15);
				b2 = Ui.button("Password", 130, 32, showChangePassword, 15);
			} else {
				info.text = "Not logged in";
				b1 = Ui.button("Log in", 130, 32, function():void { showLogin(); }, 15);
				b2 = Ui.button("Register", 130, 32, showRegister, 15);
			}
			b1.x = Ui.W - w - 16 + 14; b1.y = 54;
			b2.x = Ui.W - 16 - 14 - 130; b2.y = 54;
			accountLayer.addChild(b1);
			accountLayer.addChild(b2);
		}

		// ------------------------------------------------------------ dialogs
		private function openDialog(title:String, labels:Array, passwords:Array, okLabel:String, onOk:Function,
				extraLabel:String = null, onExtra:Function = null, opts:Object = null):void {
			closeDialog();
			dialog = new Sprite();
			dialog.graphics.beginFill(0x000000, 0.55);
			dialog.graphics.drawRect(0, 0, Ui.W, Ui.H);
			dialog.graphics.endFill();
			var w:int = 420, h:int = 150 + labels.length * 62;
			var px:int = (Ui.W - w) / 2, py:int = (Ui.H - h) / 2;
			Ui.panel(dialog.graphics, px, py, w, h, 0x26262c, 0x7a7a8a, 0.98);
			var tt:TextField = Ui.text(24, Ui.GOLD, true, "center", w, true);
			tt.text = title;
			tt.x = px; tt.y = py + 12;
			dialog.addChild(tt);
			fields = [];
			for (var i:int = 0; i < labels.length; i++) {
				var lab:TextField = Ui.text(14, 0xbbbbbb, true, "left", 300);
				lab.text = labels[i];
				lab.x = px + 30; lab.y = py + 54 + i * 62;
				dialog.addChild(lab);
				var box:Shape = new Shape();
				Ui.panel(box.graphics, px + 30, py + 74 + i * 62, w - 60, 32, 0x141418, 0x5a5a6a);
				dialog.addChild(box);
				var f:TextField = Ui.text(17, 0xffffff, true, "left", w - 80);
				f.autoSize = "none";
				f.height = 26;
				f.x = px + 40; f.y = py + 77 + i * 62;
				f.type = TextFieldType.INPUT;
				f.multiline = false;
				f.wordWrap = false;
				f.selectable = true;
				f.mouseEnabled = true;
				f.maxChars = passwords[i] ? 32 : opts && opts.maxChars ? opts.maxChars : 12;
				if (!passwords[i]) f.restrict = opts && opts.restrict ? opts.restrict : "A-Za-z0-9";
				if (opts && opts.values && opts.values[i]) f.text = opts.values[i];
				f.displayAsPassword = passwords[i];
				dialog.addChild(f);
				fields.push(f);
			}
			errorTf = Ui.text(14, 0xff7070, true, "center", w, true);
			errorTf.x = px; errorTf.y = py + h - 96;
			dialog.addChild(errorTf);
			submit = onOk;
			var ok:Sprite = Ui.button(okLabel, 160, 38, onOk, 17);
			ok.x = px + 30; ok.y = py + h - 56;
			dialog.addChild(ok);
			var cancel:Sprite = Ui.button("Cancel", 110, 38, closeDialog, 16);
			cancel.x = px + w - 140; cancel.y = py + h - 56;
			dialog.addChild(cancel);
			if (extraLabel) {
				var ex:TextField = Ui.text(13, 0x9ad0ff, true, "center", w, true);
				ex.htmlText = "<u>" + extraLabel + "</u>";
				ex.x = px; ex.y = py + h + 8;
				var exs:Sprite = new Sprite();
				exs.addChild(ex);
				exs.buttonMode = true;
				exs.mouseChildren = false;
				exs.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onExtra(); });
				dialog.addChild(exs);
			}
			addChild(dialog);
			if (stage) stage.focus = fields[0];
		}

		private function closeDialog():void {
			if (dialog) removeChild(dialog);
			dialog = null;
			submit = null;
			if (stage) stage.focus = stage;
		}

		private function done():void {
			closeDialog();
			refreshAccount();
		}

		/** Dialog fields, plus a server field when the build has no server baked in. */
		private function withServer(labels:Array):Array {
			return ServerConfig.home ? labels : labels.concat(["Server address"]);
		}

		private function serverField(i:int):String {
			return ServerConfig.home || String(fields[i].text).replace(/^\s+|\s+$/g, "");
		}

		private function showLogin(error:String = null):void {
			var labels:Array = withServer(["Username", "Password"]);
			openDialog("Log In", labels, [false, true, false], "Log in", function():void {
				var name:String = String(fields[0].text);
				if (!/^[A-Za-z0-9]{3,12}$/.test(name)) { errorTf.text = "Usernames are 3-12 letters or numbers."; return; }
				if (!fields[1].text) { errorTf.text = "Enter your password."; return; }
				serverLogin(name, fields[1].text, false, serverField(2));
			}, "No account yet? Register", showRegister, {maxChars: 80, restrict: "A-Za-z0-9.:\\-", values: ["", "", server || ""]});
			if (error) errorTf.text = error;
		}

		private function showRegister():void {
			var labels:Array = withServer(["Username (3-12 letters or numbers)", "Password", "Confirm password"]);
			openDialog("Create Account", labels, [false, true, true, false], "Create", function():void {
				var name:String = String(fields[0].text);
				if (!/^[A-Za-z0-9]{3,12}$/.test(name)) { errorTf.text = "Usernames are 3-12 letters or numbers."; return; }
				if (String(fields[1].text).length < 4) { errorTf.text = "Passwords need at least 4 characters."; return; }
				if (fields[1].text != fields[2].text) { errorTf.text = "The passwords don't match."; return; }
				serverLogin(name, fields[1].text, true, serverField(3));
			}, "Already have an account? Log in", function():void { showLogin(); }, {maxChars: 80, restrict: "A-Za-z0-9.:\\-", values: ["", "", "", server || ""]});
		}

		private function showChangePassword():void {
			var oldLabel:String = Online.welcome && Online.welcome.needPassword ? "Current password (leave empty: none set yet)" : "Current password";
			openDialog("Change Password", [oldLabel, "New password", "Confirm new password"], [true, true, true], "Change", function():void {
				if (String(fields[1].text).length < 4) { errorTf.text = "Passwords need at least 4 characters."; return; }
				if (fields[1].text != fields[2].text) { errorTf.text = "The new passwords don't match."; return; }
				errorTf.textColor = 0xcccccc;
				errorTf.text = "Saving...";
				Online.changePassword(fields[0].text, fields[1].text, function(err:String):void {
					errorTf.textColor = 0xff7070;
					if (err) { errorTf.text = err; return; }
					if (Online.welcome) Online.welcome.needPassword = false;
					done();
				});
			});
		}
	}
}
