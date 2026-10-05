#!/bin/sh
# Package a standalone app (captive runtime bundle) into dist/NewRealm.
# Creates a self-signed certificate on first run.
set -e
cd "$(dirname "$0")"
: "${AIR_SDK:?Set AIR_SDK to your AIR SDK folder}"
if [ ! -f cert.p12 ]; then
	"$AIR_SDK/bin/adt" -certificate -cn NewRealm 2048-RSA cert.p12 newrealm
fi
mkdir -p dist
"$AIR_SDK/bin/adt" -package -storetype pkcs12 -keystore cert.p12 -storepass newrealm \
	-target bundle dist/NewRealm NewRealm-app.xml -C bin NewRealm.swf
echo "Packaged into dist/NewRealm"
