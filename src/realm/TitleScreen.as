package realm {
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;

	/**
	 * The home screen (RotMG's title screen): logo, PLAY, and the account controls.
	 * PLAY goes to character select once you're logged in.
	 */
	public class TitleScreen extends Sprite {
		public static const VERSION:String = "v1.1";

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

			// a row of heroes standing under the logo
			var ids:Array = Data.CLASS_ORDER;
			for (var i:int = 0; i < ids.length; i++) {
				var hb:Bitmap = new Bitmap(Sprites.get(ids[i], 0, i >= ids.length / 2));
				hb.scaleX = hb.scaleY = 1.1;
				hb.x = Ui.W / 2 - (ids.length * 70) / 2 + i * 70 + 14;
				hb.y = 300;
				addChild(hb);
				heroes.push(hb);
			}

			var logo:TextField = Ui.text(96, Ui.GOLD, true, "center", Ui.W, true);
			logo.text = "NEW REALM";
			logo.y = 90;
			addChild(logo);
			var tag:TextField = Ui.text(19, 0xe8e0ff, true, "center", Ui.W, true);
			tag.text = "Fight your way across the realms of " + Data.WORLD_NAME;
			tag.y = 212;
			addChild(tag);

			var play:Sprite = Ui.button("PLAY", 260, 64, clickPlay, 32);
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
			ver.text = "New Realm " + VERSION + "  -  online: your characters are saved on the server";
			ver.x = 14; ver.y = Ui.H - 26;
			addChild(ver);

			addEventListener(Event.ENTER_FRAME, animate);
			addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void {
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
			});
			addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void {
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

		private function animate(e:Event):void {
			t += 1 / 60;
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
			return ServerConfig.HOME || Accounts.setting("server");
		}

		private function refreshOnline():void {
			onlineLayer.removeChildren();
			var tf:TextField = Ui.text(15, 0xdddddd, true, "center", Ui.W, true);
			tf.htmlText = Online.connected ? "Online: <font color='#5ae06a'>" + Online.address + "</font>  (" + Online.welcome.online + " playing)"
				: connecting ? "Connecting to the server..."
				: netError ? "<font color='#ff8080'>Couldn't reach the server.</font> Press PLAY to try again."
				: "Log in or create an account to play.";
			tf.y = 478;
			onlineLayer.addChild(tf);
			// builds without a baked-in server can switch servers here
			if (!ServerConfig.HOME) {
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
			if (Online.connected) onPlay();
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
			return ServerConfig.HOME ? labels : labels.concat(["Server address"]);
		}

		private function serverField(i:int):String {
			return ServerConfig.HOME || String(fields[i].text).replace(/^\s+|\s+$/g, "");
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
