package realm {
	import flash.net.SharedObject;
	import flash.utils.ByteArray;

	/** Persistent high scores (stored in the AIR app's local storage). */
	public class Save {
		private static var so:SharedObject;
		private static var fallback:Object = {};

		public static function get data():Object {
			if (!so) {
				try { so = SharedObject.getLocal("newrealm"); } catch (e:Error) { so = null; }
			}
			return so ? so.data : fallback;
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
			try { if (so) so.flush(); } catch (e:Error) {}
		}
	}
}
