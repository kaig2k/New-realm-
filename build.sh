#!/bin/sh
# Compile src/ into bin/NewRealm.swf using the AIR SDK.
# Usage: AIR_SDK=/path/to/AIRSDK ./build.sh [your.server.com:2050]
# Passing a server address bakes it into the game: players who open the .swf join it automatically.
# It also builds bin/EldmereLauncher.swf: the file to give players once. It downloads the latest
# game from the server every time it opens, so updates reach everyone after a git pull on the server.
set -e
cd "$(dirname "$0")"
: "${AIR_SDK:?Set AIR_SDK to your AIR SDK folder, e.g. AIR_SDK=~/AIRSDK_51 ./build.sh}"
mkdir -p bin
if [ -n "$1" ]; then
	cat > src/realm/ServerConfig.as <<EOT
package realm {
	/** Your server, baked into the game by build.sh. Empty = offline-first build. */
	public class ServerConfig {
		public static const HOME:String = "$1";
		/** The server the Eldmere launcher started this game for (the launcher passes it in). */
		public static var launched:String = "";

		/** The server this game joins by itself: baked in, or handed over by the launcher. */
		public static function get home():String { return HOME || launched; }
	}
}
EOT
fi
"$AIR_SDK/bin/amxmlc" -source-path=src -default-size=800,600 -output=bin/NewRealm.swf src/NewRealm.as
echo "Built bin/NewRealm.swf"
if [ -n "$1" ]; then
	"$AIR_SDK/bin/amxmlc" -source-path=src -default-size=1100,640 -output=bin/EldmereLauncher.swf src/Launcher.as
	echo "Players who open it join $1 automatically."
	echo "Built bin/EldmereLauncher.swf: give this to players once; it always loads the latest game from $1."
fi
