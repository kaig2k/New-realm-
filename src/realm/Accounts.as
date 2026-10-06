package realm {
	import flash.net.SharedObject;

	/**
	 * Accounts live on the game server. This PC only remembers who was logged
	 * in on which server (a session token the server can revoke), plus a few
	 * computer-wide settings such as the last server address.
	 */
	public class Accounts {
		private static const REGISTRY:String = "newrealm_accounts";
		private static var so:SharedObject;
		private static var fallback:Object = {};

		/** Display name of the logged-in account, or null. */
		public static var current:String = null;

		private static function get reg():Object {
			if (!so) {
				try { so = SharedObject.getLocal(REGISTRY); } catch (e:Error) { so = null; }
			}
			var d:Object = so ? so.data : fallback;
			if (!d.sessions) d.sessions = {};
			return d;
		}

		private static function flush():void {
			try { if (so) so.flush(); } catch (e:Error) {}
		}

		/** Computer-wide settings (e.g. the last server address). */
		public static function setting(name:String):String {
			var o:Object = reg.settings || {};
			return o[name] ? String(o[name]) : null;
		}

		public static function setSetting(name:String, value:String):void {
			if (!reg.settings) reg.settings = {};
			reg.settings[name] = value;
			flush();
		}

		public static function key(name:String):String {
			return name.toLowerCase();
		}

		/** The remembered login for a server: {name, token}, or null. */
		public static function remembered(address:String):Object {
			var s:Object = reg.sessions[address];
			return s && s.name && s.token ? s : null;
		}

		public static function remember(address:String, name:String, token:String):void {
			reg.sessions[address] = {name: name, token: token};
			flush();
		}

		public static function forget(address:String):void {
			delete reg.sessions[address];
			flush();
		}

		/** The server accepted us as `name`. */
		public static function loggedIn(name:String):void {
			current = name;
			Save.useAccount(key(name));
		}

		public static function logout():void {
			current = null;
			Save.useAccount(null);
		}

		/**
		 * The per-server token an older build of the game kept in this PC's save
		 * for `name` (lets accounts made before passwords set one).
		 */
		public static function legacyToken(name:String, address:String):String {
			Save.useAccount(key(name));
			var t:Object = Save.local.serverTokens;
			return t && t[address] ? String(t[address]) : null;
		}
	}
}
