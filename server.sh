#!/bin/sh
# Starts the New Realm multiplayer server (needs Node.js).
cd "$(dirname "$0")" && exec node server/server.js "$@"
