package realm {
	/**
	 * Your server, baked into the game. When HOME is set, players who open the
	 * .swf connect to it automatically once they're logged in: no address to type.
	 * Leave it empty for an offline-first build with the normal Play Online button.
	 *
	 * Set it by building with the address: build.bat play.example.com:2050
	 * (or ./build.sh play.example.com:2050), or edit the line below and build.
	 */
	public class ServerConfig {
		public static const HOME:String = "";
		/** The server the Eldmere launcher started this game for (the launcher passes it in). */
		public static var launched:String = "";

		/** The server this game joins by itself: baked in, or handed over by the launcher. */
		public static function get home():String { return HOME || launched; }
	}
}
