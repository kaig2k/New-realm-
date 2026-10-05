package realm {
	import flash.net.SharedObject;
	import flash.utils.ByteArray;

	/** Persistent high scores (stored in the AIR app's local storage). */
	public class Save {
		private static var so:SharedObject;
		private static var fallback:Object = {};

		/** Save-file key of the logged-in account (null = the old shared save). */
		private static var account:String = null;
		/** Online: the account's save as the server keeps it (null = use this PC's save). */
		private static var remote:Object = null;
		/** Called when the online save changed and should be sent to the server. */
		public static var onRemoteChange:Function;

		/** The save in use: the server's copy when online, otherwise this PC's. */
		public static function get data():Object {
			if (remote) return remote;
			return local;
		}

		/** This PC's save for the account, even while playing online. */
		public static function get local():Object {
			if (!so) {
				try { so = SharedObject.getLocal(account ? "newrealm_acc_" + account : "newrealm"); } catch (e:Error) { so = null; }
			}
			return so ? so.data : fallback;
		}

		/** Online saves: use the server's copy (or go back to this PC's with null). */
		public static function useRemote(d:Object):void {
			remote = d;
		}

		public static function get isRemote():Boolean { return remote != null; }

		/** Switches to an account's own save file. */
		public static function useAccount(key:String):void {
			flush();
			account = key;
			so = null;
			fallback = {};
		}

		/** Moves progress from before accounts existed into the first account created. */
		public static function importLegacy():void {
			var old:SharedObject;
			try { old = SharedObject.getLocal("newrealm"); } catch (e:Error) { return; }
			if (!old || old.data.migrated) return;
			var d:Object = data;
			for (var k:String in old.data) d[k] = clone(old.data[k]);
			old.data.migrated = true;
			try { old.flush(); } catch (e2:Error) {}
			delete d.migrated;
			d.importedLegacy = true;
			flush();
		}

		/** Deep copy (AMF round trip), so saved data never aliases live game objects. */
		public static function clone(o:Object):Object {
			var b:ByteArray = new ByteArray();
			b.writeObject(o);
			b.position = 0;
			return b.readObject();
		}

		/** Saved characters (alive ones only; RotMG-style permadeath removes them). */
		public static function get chars():Array {
			if (!(data.chars is Array)) data.chars = [];
			return data.chars;
		}

		public static function storeChar(c:Object):void {
			var list:Array = chars;
			var copy:Object = clone(c);
			for (var i:int = 0; i < list.length; i++) {
				if (list[i] && list[i].id == c.id) { list[i] = copy; flush(); return; }
			}
			list.push(copy);
			flush();
		}

		public static function removeChar(id:String):void {
			var list:Array = chars;
			for (var i:int = list.length - 1; i >= 0; i--) if (!list[i] || list[i].id == id) list.splice(i, 1);
			flush();
		}

		public static function flush():void {
			if (remote) { if (onRemoteChange != null) onRemoteChange(); return; }
			try { if (so) so.flush(); } catch (e:Error) {}
		}

		/** Saves this PC's copy (settings that never go to the server). */
		public static function flushLocal():void {
			try { if (so) so.flush(); } catch (e:Error) {}
		}
	}
}
