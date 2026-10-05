package realm {
	import flash.net.SharedObject;

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

		public static function flush():void {
			try { if (so) so.flush(); } catch (e:Error) {}
		}
	}
}
