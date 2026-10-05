#!/bin/sh
# Compile src/ into bin/NewRealm.swf using the AIR SDK.
# Usage: AIR_SDK=/path/to/AIRSDK ./build.sh
set -e
cd "$(dirname "$0")"
: "${AIR_SDK:?Set AIR_SDK to your AIR SDK folder, e.g. AIR_SDK=~/AIRSDK_51 ./build.sh}"
mkdir -p bin
"$AIR_SDK/bin/amxmlc" -source-path=src -default-size=800,600 -output=bin/NewRealm.swf src/NewRealm.as
echo "Built bin/NewRealm.swf"
