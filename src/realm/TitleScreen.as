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
		public static const VERSION:String = "v1.0";

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
			ver.text = "New Realm " + VERSION + "  -  single player, saves are stored on this computer";
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
			// first launch: go straight to account creation
			if (!Accounts.current && Accounts.count == 0) showRegister();
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

		private function refreshOnline():void {
			onlineLayer.removeChildren();
			var tf:TextField = Ui.text(15, 0xdddddd, true, "center", Ui.W, true);
			tf.htmlText = Online.connected ? "Online: <font color='#5ae06a'>" + Online.address + "</font>  (" + Online.welcome.online + " playing)"
				: "Playing offline. Join a server to play with friends.";
			tf.y = 478;
			onlineLayer.addChild(tf);
			var b:Sprite = Online.connected ? Ui.button("Disconnect", 170, 34, function():void { Online.signOut(); refreshOnline(); }, 15)
				: Ui.button("Play Online", 170, 34, showServer, 15);
			b.x = (Ui.W - 170) / 2;
			b.y = 506;
			onlineLayer.addChild(b);
		}

		private function showServer():void {
			if (!Accounts.current) { showLogin(); return; }
			openDialog("Play Online", ["Server address (ask the host)"], [false], "Connect", function():void {
				errorTf.textColor = 0xcccccc;
				errorTf.text = "Connecting...";
				Online.connect(fields[0].text, function(err:String):void {
					errorTf.textColor = 0xff7070;
					if (err) { errorTf.text = err; return; }
					done();
					refreshOnline();
					onPlay();
				});
			}, null, null, {maxChars: 80, restrict: "A-Za-z0-9.:\\-", values: [Online.lastAddress]});
		}

		private function clickPlay():void {
			if (Accounts.current) onPlay();
			else showLogin();
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
				b1 = Ui.button("Log out", 130, 32, function():void { Online.signOut(); Accounts.logout(); refreshAccount(); refreshOnline(); }, 15);
				b2 = Ui.button("Password", 130, 32, showChangePassword, 15);
			} else {
				info.text = "Not logged in";
				b1 = Ui.button("Log in", 130, 32, showLogin, 15);
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

		private function showLogin():void {
			openDialog("Log In", ["Username", "Password"], [false, true], "Log in", function():void {
				var err:String = Accounts.login(fields[0].text, fields[1].text, true);
				if (err) errorTf.text = err;
				else { done(); onPlay(); }
			}, "No account yet? Register", showRegister);
		}

		private function showRegister():void {
			openDialog("Create Account", ["Username (3-12 letters or numbers)", "Password", "Confirm password"], [false, true, true], "Create", function():void {
				var err:String = Accounts.register(fields[0].text, fields[1].text, fields[2].text, true);
				if (err) errorTf.text = err;
				else { done(); onPlay(); }
			}, Accounts.count > 0 ? "Already have an account? Log in" : null, showLogin);
		}

		private function showChangePassword():void {
			openDialog("Change Password", ["Current password", "New password", "Confirm new password"], [true, true, true], "Change", function():void {
				var err:String = Accounts.changePassword(fields[0].text, fields[1].text, fields[2].text);
				if (err) errorTf.text = err;
				else done();
			});
		}
	}
}
