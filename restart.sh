#!/bin/sh
# Restart the Eldmere server with a countdown, then update it.
#
#   sh restart.sh          restart in 5 minutes
#   sh restart.sh 2        restart in 2 minutes
#   sh restart.sh now      restart straight away
#   sh restart.sh cancel   call off a restart that's coming
#
# Everyone in game sees the countdown, and no new realm events start in the last
# two minutes. At zero the server gets the latest update (git pull), saves and
# stops; systemd starts it again on the new version and players rejoin.
# (Run it on the VPS: the server only takes this from the machine it runs on.)
PORT=${PORT:-2050}
curl -s "http://127.0.0.1:$PORT/restart?m=${1:-5}" || echo "Couldn't reach the server on port $PORT. Is it running?"
