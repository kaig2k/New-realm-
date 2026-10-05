package realm {
	import flash.net.SharedObject;

	/**
	 * Local accounts. The game has no server, so accounts live on this computer:
	 * a registry of usernames with salted SHA-256 password hashes, and one save
	 * file per account (characters, vault, gold, fame, pets...).
	 */
	public class Accounts {
		private static const REGISTRY:String = "newrealm_accounts";
		private static const ROUNDS:int = 500;
		private static var so:SharedObject;
		private static var fallback:Object = {};

		/** Display name of the logged-in account, or null. */
		public static var current:String = null;

		private static function get reg():Object {
			if (!so) {
				try { so = SharedObject.getLocal(REGISTRY); } catch (e:Error) { so = null; }
			}
			var d:Object = so ? so.data : fallback;
			if (!d.accounts) d.accounts = {};
			return d;
		}

		private static function flush():void {
			try { if (so) so.flush(); } catch (e:Error) {}
		}

		public static function key(name:String):String {
			return name.toLowerCase();
		}

		private static function hashPw(salt:String, pw:String):String {
			var h:String = salt + ":" + pw;
			for (var i:int = 0; i < ROUNDS; i++) h = Sha256.hash(salt + h);
			return h;
		}

		private static function makeSalt():String {
			var s:String = "";
			for (var i:int = 0; i < 16; i++) s += int(Math.random() * 16).toString(16);
			return s;
		}

		public static function exists(name:String):Boolean {
			return reg.accounts[key(name)] != null;
		}

		public static function get count():int {
			var n:int = 0;
			for (var k:String in reg.accounts) n++;
			return n;
		}

		/** Creates an account and logs in. Returns an error message, or null on success. */
		public static function register(name:String, pw:String, confirm:String, remember:Boolean):String {
			if (!/^[A-Za-z0-9]{3,12}$/.test(name)) return "Usernames are 3-12 letters or numbers.";
			if (pw.length < 4) return "Passwords need at least 4 characters.";
			if (pw != confirm) return "The passwords don't match.";
			if (exists(name)) return "That username is already taken.";
			var salt:String = makeSalt();
			var first:Boolean = count == 0;
			reg.accounts[key(name)] = {name: name, salt: salt, hash: hashPw(salt, pw), created: new Date().time};
			flush();
			startSession(name, remember);
			if (first) Save.importLegacy();
			return null;
		}

		/** Returns an error message, or null on success. */
		public static function login(name:String, pw:String, remember:Boolean):String {
			var a:Object = reg.accounts[key(name)];
			if (!a) return "No account with that username.";
			if (hashPw(a.salt, pw) != a.hash) return "Wrong password.";
			startSession(a.name, remember);
			return null;
		}

		private static function startSession(name:String, remember:Boolean):void {
			current = name;
			reg.lastUser = remember ? name : null;
			flush();
			Save.useAccount(key(name));
			Save.data.lastLogin = new Date().time;
			Save.flush();
		}

		public static function logout():void {
			current = null;
			reg.lastUser = null;
			flush();
			Save.useAccount(null);
		}

		/** Logs back in to a remembered account. */
		public static function autoLogin():Boolean {
			var last:String = reg.lastUser;
			if (!last || !exists(last)) return false;
			current = reg.accounts[key(last)].name;
			Save.useAccount(key(last));
			return true;
		}

		/** Changes the password after checking the old one. Returns an error, or null. */
		public static function changePassword(oldPw:String, newPw:String, confirm:String):String {
			if (!current) return "Not logged in.";
			var a:Object = reg.accounts[key(current)];
			if (hashPw(a.salt, oldPw) != a.hash) return "Current password is wrong.";
			if (newPw.length < 4) return "Passwords need at least 4 characters.";
			if (newPw != confirm) return "The new passwords don't match.";
			a.salt = makeSalt();
			a.hash = hashPw(a.salt, newPw);
			flush();
			return null;
		}
	}
}
