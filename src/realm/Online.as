package realm {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	/**
	 * The connection to a New Realm server (server/server.js): newline-separated
	 * JSON over a socket. Connect from the title screen; the game then talks to
	 * the server through ServerNet.
	 */
	public class Online {
		public static const DEFAULT_PORT:int = 2050;
		/** Must match VERSION in server/server.js. */
		public static const PROTOCOL:int = 11;

		private static var socket:Socket;
		private static var inBuf:ByteArray = new ByteArray();
		private static var connectDone:Function;
		private static var timeout:Timer;
		private static var queue:Array = [];
		private static var saveTimer:Timer;
		/**
		 * Keeps the connection alive on every screen (title, character select,
		 * death screen): the server drops connections that stay quiet for 45s.
		 */
		private static var keepAlive:Timer;
		/** Called when the server refused our save and sent its own copy back. */
		public static var onSaveRejected:Function;

		public static var address:String = "";

		/**
		 * What players see instead of the address: the name the server gives
		 * itself (config.json "name"). The IP is never shown in the game.
		 */
		public static function get serverName():String {
			if (welcome && welcome.serverName) return String(welcome.serverName);
			return ServerConfig.home ? "the game server" : address;
		}
		public static var connected:Boolean = false;
		/** The server's welcome: {id, name, realms: [{name, seed}], online}. */
		public static var welcome:Object;
		/** The connection to a game in progress was lost (the server restarted, most likely). */
		public static var dropped:Boolean = false;
		/** The build of the game the server handed out when we first connected, and whether it has changed since. */
		public static var firstBuild:String = null;
		public static var outdated:Boolean = false;
		/** Receives every message after the welcome (set by ServerNet). */
		private static var _onMessage:Function;
		/** Called when the connection drops. */
		public static var onClose:Function;
		/** Also called when a working connection is lost, wherever the player is (the menus use it). */
		public static var onDropped:Function;

		public static function set onMessage(fn:Function):void {
			_onMessage = fn;
			// deliver anything that arrived before the game was ready
			while (fn != null && queue.length) fn(queue.shift());
		}

		/** Saved server address (shared by all accounts on this computer). */
		public static function get lastAddress():String {
			return ServerConfig.home || Accounts.setting("server") || "localhost:" + DEFAULT_PORT;
		}

		/** How the next connection logs in: {name, password, register} or null for the remembered session. */
		private static var cred:Object;
		/** Called with (error or null) when a password change finishes. */
		private static var onPassword:Function;

		/**
		 * Connects and logs in. cred is {name, password, register:Boolean} for a
		 * login or a new account, or null to resume this PC's remembered session.
		 * done(error:String): error is null on success.
		 */
		public static function connect(addr:String, done:Function, login:Object = null):void {
			disconnect();
			cred = login;
			addr = addr.replace(/^\s+|\s+$/g, "");
			var host:String = addr, port:int = DEFAULT_PORT;
			var colon:int = addr.lastIndexOf(":");
			if (colon > 0) { host = addr.substr(0, colon); port = int(addr.substr(colon + 1)) || DEFAULT_PORT; }
			if (!host) { done("Enter the server address."); return; }
			address = host + ":" + port;
			connectDone = done;
			inBuf = new ByteArray();
			queue = [];
			welcome = null;
			socket = new Socket();
			socket.addEventListener(Event.CONNECT, onConnect);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, onData);
			socket.addEventListener(Event.CLOSE, onClosed);
			socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			timeout = new Timer(8000, 1);
			timeout.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { fail("The server didn't answer. Check the address and that the server is running."); });
			timeout.start();
			try {
				socket.connect(host, port);
			} catch (err:Error) {
				fail("Couldn't connect: " + err.message);
			}
		}

		/**
		 * Online, the account's save lives on the server and is kept apart from
		 * this PC's offline save: nothing offline is ever uploaded, and nothing
		 * online is written to this PC. A first visit starts from a fresh save.
		 */
		private static function useServerSave(m:Object):void {
			Save.onRemoteChange = queueSave;
			Save.useRemote(m.save || {});
		}

		/** Sends the save a moment after the last change (many changes become one upload). */
		private static function queueSave():void {
			if (!connected) return;
			if (!saveTimer) {
				saveTimer = new Timer(2000, 1);
				saveTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { sendSave(); });
			}
			saveTimer.reset();
			saveTimer.start();
		}

		/** Uploads the save right away (before trades, when quitting). */
		public static function sendSave():void {
			if (saveTimer) saveTimer.stop();
			if (connected && Save.isRemote) send({t: "save", data: Save.data});
		}

		/** Leaving online play: back to this PC's saves. */
		public static function signOut():void {
			sendSave();
			disconnect();
			Save.useRemote(null);
		}

		/** Logs out for good on this PC: the server forgets this PC's session. */
		public static function logout():void {
			var rem:Object = Accounts.remembered(address || lastAddress);
			if (connected && rem) { sendSave(); send({t: "logout", token: rem.token}); }
			Accounts.forget(address || lastAddress);
			disconnect();
			Save.useRemote(null);
			Accounts.logout();
		}

		/** Changes the account's password on the server. done(error or null). */
		public static function changePassword(oldPw:String, newPw:String, done:Function):void {
			if (!connected) { done("Not connected to the server."); return; }
			onPassword = done;
			send({t: "password", old: oldPw, pw: newPw});
		}

		public static function disconnect():void {
			if (timeout) { timeout.stop(); timeout = null; }
			if (socket) {
				try { socket.close(); } catch (e:Error) {}
				socket = null;
			}
			connected = false;
			welcome = null;
		}

		public static function send(o:Object):void {
			if (!socket || !socket.connected) return;
			try {
				socket.writeUTFBytes(JSON.stringify(o) + "\n");
				socket.flush();
			} catch (e:Error) {}
		}

		private static function fail(msg:String):void {
			var cb:Function = connectDone;
			connectDone = null;
			disconnect();
			if (cb != null) cb(msg);
		}

		private static function onConnect(e:Event):void {
			if (cred) {
				send({t: "hello", name: cred.name, password: cred.password, register: cred.register == true,
					legacy: cred.register ? null : Accounts.legacyToken(cred.name, address), ver: PROTOCOL});
				return;
			}
			var rem:Object = Accounts.remembered(address);
			if (!rem) { fail("Please log in."); return; }
			send({t: "hello", name: rem.name, token: rem.token, ver: PROTOCOL});
		}

		private static function onData(e:ProgressEvent):void {
			if (!socket) return;
			inBuf.position = inBuf.length;
			socket.readBytes(inBuf, inBuf.length, socket.bytesAvailable);
			// split on newlines (byte 10) so multi-byte characters never break in half
			var start:int = 0;
			for (var i:int = 0; i < inBuf.length; i++) {
				if (inBuf[i] != 10) continue;
				inBuf.position = start;
				var line:String = inBuf.readUTFBytes(i - start);
				start = i + 1;
				if (line) handle(line);
				if (!socket) return;
			}
			if (start > 0) {
				var rest:ByteArray = new ByteArray();
				if (start < inBuf.length) {
					inBuf.position = start;
					inBuf.readBytes(rest, 0, inBuf.length - start);
				}
				inBuf = rest;
			}
		}

		private static function handle(line:String):void {
			var m:Object;
			try { m = JSON.parse(line); } catch (err:Error) { return; }
			if (!welcome) {
				if (m.t == "error") {
					// a remembered session the server no longer accepts: log in again
					if (!cred) Accounts.forget(address);
					fail(m.msg);
					return;
				}
				if (m.t == "welcome") {
					welcome = m;
					// the server now hands out a different game: this copy is out of date
					if (m.build) { if (firstBuild == null) firstBuild = m.build; else if (m.build != firstBuild) outdated = true; }
					connected = true;
					if (m.session) Accounts.remember(address, m.name, m.session);
					Accounts.loggedIn(m.name);
					cred = null;
					useServerSave(m);
					if (timeout) { timeout.stop(); timeout = null; }
					if (!keepAlive) {
						keepAlive = new Timer(10000);
						keepAlive.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { if (connected) send({t: "ping", at: -1}); });
						keepAlive.start();
					}
					Accounts.setSetting("server", address);
					var cb:Function = connectDone;
					connectDone = null;
					if (cb != null) cb(null);
				}
				return;
			}
			if (m.t == "password") {
				if (m.ok && m.session) Accounts.remember(address, welcome.name, m.session);
				var pcb:Function = onPassword;
				onPassword = null;
				if (pcb != null) pcb(m.ok ? null : m.msg);
				return;
			}
			if (m.t == "saveRejected") {
				// the server keeps its own copy; go back to it
				Save.useRemote(m.data || {});
				if (onSaveRejected != null) onSaveRejected(m.reason);
				return;
			}
			if (m.t == "realms" && welcome) welcome.realms = m.list;
			// the answer to a keep-alive: nothing to do
			if (m.t == "pong" && m.at == -1) return;
			if (_onMessage != null) _onMessage(m);
			else queue.push(m);
		}

		private static function onClosed(e:Event):void {
			var was:Boolean = connected;
			connected = false;
			socket = null;
			if (connectDone != null) fail("The server closed the connection.");
			else if (was) {
				if (onClose != null) onClose();
				if (onDropped != null) onDropped();
			}
		}

		private static function onError(e:Event):void {
			fail("Couldn't reach " + (ServerConfig.home ? "the game server" : "the server at " + address) + ". " + (ServerConfig.home ? "It may be down for an update; try again in a minute." : "Check the address and that the server is running."));
		}
	}
}
