#!/bin/sh
# Packages the Eldmere desktop client (the launcher, with its own AIR runtime) into dist/Eldmere
# for the system you run it on (a Mac app on macOS). Build the launcher first, with your server:
#     AIR_SDK=~/AIRSDK ./build.sh your.server.com:2050
set -e
cd "$(dirname "$0")"
: "${AIR_SDK:?Set AIR_SDK to your AIR SDK folder}"
[ -f bin/EldmereLauncher.swf ] || { echo "bin/EldmereLauncher.swf is missing: run ./build.sh your.server.com:2050 first"; exit 1; }
[ -f cert.p12 ] || "$AIR_SDK/bin/adt" -certificate -cn Eldmere 2048-RSA cert.p12 newrealm
mkdir -p dist
# the app description must be for at least the AIR version the launcher was compiled for
ver=$(od -An -tu1 -j3 -N1 bin/EldmereLauncher.swf | tr -d ' ')
[ "${ver:-0}" -gt 32 ] || ver=32
sed "s#application/32\.0#application/$ver.0#" Eldmere-app.xml > dist/Eldmere-app.xml
rm -rf dist/Eldmere dist/Eldmere.app
"$AIR_SDK/bin/adt" -package -storetype pkcs12 -keystore cert.p12 -storepass newrealm \
	-target bundle dist/Eldmere dist/Eldmere-app.xml -C bin EldmereLauncher.swf \
	-C assets/icons eldmere_16.png eldmere_32.png eldmere_48.png eldmere_128.png
echo "Packaged into dist/Eldmere"
