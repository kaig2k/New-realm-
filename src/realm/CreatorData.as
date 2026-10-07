package realm {
	import flash.net.SharedObject;

	/**
	 * What you make with the creator tools: boss arenas, sprites and boss
	 * fights. Kept on this PC only (it never goes to the game server).
	 */
	public class CreatorData {
		private static var so:SharedObject;
		private static var fallback:Object = {};

		public static function get data():Object {
			if (!so) {
				try { so = SharedObject.getLocal("newrealm_creator"); } catch (e:Error) { so = null; }
			}
			var d:Object = so ? so.data : fallback;
			if (!d.maps) d.maps = {};
			if (!d.sprites) d.sprites = {};
			if (!d.bosses) d.bosses = {};
			return d;
		}

		public static function flush():void {
			try { if (so) so.flush(); } catch (e:Error) {}
		}

		/** Saved names of one kind ("maps", "sprites" or "bosses"), sorted. */
		public static function names(kind:String):Array {
			var a:Array = [];
			for (var k:String in data[kind]) a.push(k);
			a.sort(Array.CASEINSENSITIVE);
			return a;
		}

		public static function load(kind:String, name:String):Object {
			var o:Object = data[kind][name];
			return o ? Save.clone(o) : null;
		}

		public static function store(kind:String, name:String, o:Object):void {
			data[kind][name] = Save.clone(o);
			flush();
		}

		public static function remove(kind:String, name:String):void {
			delete data[kind][name];
			flush();
		}

		/** A custom sprite is drawn under the id "cs_<name>"; registers it and returns the id. */
		public static function useSprite(name:String):String {
			var s:Object = data.sprites[name];
			if (!s) return "cubelet";
			Sprites.custom("cs_" + name, s.rows, s.pal);
			return "cs_" + name;
		}
	}
}
