#!/bin/sh
# Launch the game with the AIR Debug Launcher.
# Usage: AIR_SDK=/path/to/AIRSDK ./run.sh
set -e
cd "$(dirname "$0")"
: "${AIR_SDK:?Set AIR_SDK to your AIR SDK folder}"
"$AIR_SDK/bin/adl" NewRealm-app.xml bin
