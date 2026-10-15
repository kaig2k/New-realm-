package realm {
	/**
	 * Rebindable controls. Every action has a default key; the player's own
	 * choices are saved with the account. Esc, Enter and the admin key
	 * (`) are fixed.
	 */
	public class Keys {
		public static const ACTIONS:Array = [
			{id: "up", name: "Move up", key: 87},
			{id: "down", name: "Move down", key: 83},
			{id: "left", name: "Move left", key: 65},
			{id: "right", name: "Move right", key: 68},
			{id: "ability", name: "Use ability", key: 32},
			{id: "hp", name: "Health potion", key: 70},
			{id: "mp", name: "Magic potion", key: 71},
			{id: "nexus", name: "Return to Nexus", key: 82},
			{id: "interact", name: "Interact (portals)", key: 88},
			{id: "realm", name: "Go to a realm", key: 86},
			{id: "glands", name: "Jump to the Godlands", key: 72},
			{id: "autofire", name: "Auto-fire", key: 73},
			{id: "rotl", name: "Rotate camera left", key: 81},
			{id: "rotr", name: "Rotate camera right", key: 69},
			{id: "camreset", name: "Reset camera", key: 90},
			{id: "zoomout", name: "Zoom out", key: 189},
			{id: "zoomin", name: "Zoom in", key: 187},
			{id: "social", name: "Party & guild", key: 76},
			{id: "wiki", name: "Boss wiki", key: 75},
			{id: "skills", name: "Skill tree", key: 84},
			{id: "oracle", name: "The Oracle (boss record)", key: 79},
			{id: "pet", name: "Your pet (and its bag)", key: 74},
			{id: "mute", name: "Mute sound", key: 77},
			{id: "menu", name: "Open menu (also Esc)", key: 80},
			{id: "slot1", name: "Inventory slot 1", key: 49},
			{id: "slot2", name: "Inventory slot 2", key: 50},
			{id: "slot3", name: "Inventory slot 3", key: 51},
			{id: "slot4", name: "Inventory slot 4", key: 52},
			{id: "slot5", name: "Inventory slot 5", key: 53},
			{id: "slot6", name: "Inventory slot 6", key: 54},
			{id: "slot7", name: "Inventory slot 7", key: 55},
			{id: "slot8", name: "Inventory slot 8", key: 56}
		];
		/** Keys that can't be bound: Esc, Enter, the admin key. */
		public static const FIXED:Array = [27, 13, 192, 223];

		private static var map:Object;

		private static function load():void {
			map = {};
			for each (var a:Object in ACTIONS) map[a.id] = a.key;
			var saved:Object = Save.data.keys;
			if (saved) for (var id:String in saved) if (map[id] != undefined && saved[id] > 0) map[id] = int(saved[id]);
		}

		/** The key code bound to an action. */
		public static function k(id:String):uint {
			if (!map) load();
			return map[id];
		}

		/** The action currently bound to this key, or null. */
		public static function actionFor(code:uint):String {
			if (!map) load();
			for (var id:String in map) if (map[id] == code) return id;
			return null;
		}

		/** Binds a key; an action that had it swaps to this action's old key. Returns false for fixed keys. */
		public static function bind(id:String, code:uint):Boolean {
			if (FIXED.indexOf(int(code)) >= 0) return false;
			if (!map) load();
			var old:uint = map[id];
			var other:String = actionFor(code);
			if (other && other != id) map[other] = old;
			map[id] = code;
			save();
			return true;
		}

		public static function resetAll():void {
			delete Save.data.keys;
			Save.flush();
			load();
		}

		/** Keys offered when an action has to move off a key another uses (letters, then digits, then F keys). */
		private static const SPARE:Array = [66, 67, 78, 85, 89, 71, 72, 74, 75, 76, 79, 80, 81, 69, 90, 77, 84, 86, 88, 73,
			48, 57, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123];

		/** The other action on the same key as this one, or null (two on one key: one of them stops working). */
		public static function clash(id:String):String {
			if (!map) load();
			for (var o:String in map) if (o != id && map[o] == map[id]) return o;
			return null;
		}

		/**
		 * Two actions on one key happen when a new action arrives with a default key a player
		 * had already given to something else. The player's own choice keeps the key; the other
		 * moves to a free one (and is saved there). Returns a line for each, to tell the player.
		 */
		public static function fixClashes():Array {
			if (!map) load();
			var saved:Object = Save.data.keys || {};
			var notes:Array = [];
			for each (var a:Object in ACTIONS) {
				var other:String = clash(a.id);
				if (!other) continue;
				// which moves: the one the player didn't choose (or, if both were chosen, the later one)
				var mover:String = saved[a.id] != undefined && saved[other] == undefined ? other : a.id;
				var keep:String = mover == a.id ? other : a.id;
				var taken:uint = map[mover];
				var free:int = -1;
				for each (var code:int in SPARE) if (!actionFor(code)) { free = code; break; }
				if (free < 0) continue;
				map[mover] = free;
				notes.push(action(mover).name + " shared " + name(taken) + " with " + action(keep).name + ", so it's on " + name(free) + " now (change it in Menu > Controls).");
			}
			if (notes.length) save();
			return notes;
		}

		/** Forget the cached map (another account logged in). */
		public static function reload():void { map = null; }

		private static function save():void {
			var o:Object = {};
			for each (var a:Object in ACTIONS) if (map[a.id] != a.key) o[a.id] = map[a.id];
			Save.data.keys = o;
			Save.flush();
		}

		public static function action(id:String):Object {
			for each (var a:Object in ACTIONS) if (a.id == id) return a;
			return null;
		}

		/** A key's name for the menus: "W", "Space", "F5", "Num 3"... */
		public static function name(code:uint):String {
			if (code >= 65 && code <= 90 || code >= 48 && code <= 57) return String.fromCharCode(code);
			if (code >= 96 && code <= 105) return "Num " + (code - 96);
			if (code >= 112 && code <= 123) return "F" + (code - 111);
			var names:Object = {32: "Space", 13: "Enter", 16: "Shift", 17: "Ctrl", 18: "Alt", 9: "Tab", 20: "Caps Lock", 8: "Backspace",
				37: "Left", 38: "Up", 39: "Right", 40: "Down", 186: ";", 187: "=", 188: ",", 189: "-", 190: ".", 191: "/", 219: "[",
				220: "\\", 221: "]", 222: "'", 106: "Num *", 107: "Num +", 109: "Num -", 110: "Num .", 111: "Num /",
				45: "Insert", 46: "Delete", 36: "Home", 35: "End", 33: "Page Up", 34: "Page Down"};
			return names[code] || "Key " + code;
		}
	}
}
