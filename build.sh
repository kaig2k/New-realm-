#!/bin/sh
# Compile src/ into bin/NewRealm.swf using the AIR SDK.
# Usage: AIR_SDK=/path/to/AIRSDK ./build.sh [your.server.com:2050]
# Passing a server address bakes it into the game: players who open the .swf join it automatically.
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
	}
}
EOT
fi
"$AIR_SDK/bin/amxmlc" -source-path=src -default-size=800,600 -output=bin/NewRealm.swf src/NewRealm.as
echo "Built bin/NewRealm.swf"
[ -n "$1" ] && echo "Players who open it join $1 automatically."
