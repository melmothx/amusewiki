#!/bin/sh

set -e

./script/amusewikifarm_fastcgi.pl -l var/amw.sock -n 3 2>/dev/null >/dev/null &
temp_pid=$!
echo "Started copy of the application with pid $temp_pid. If this script exits prematurely, please kill it yourself"
echo "Waiting for the backup app to come up"
sleep 20
echo "Stopping the app"
./init-all.sh stop
git pull
echo "Starting the app"
./init-all.sh start
echo "Waiting for the new app to come up"
sleep 20
# kill the old
echo "Stopping the backup app $temp_pid"
kill $temp_pid
echo "All done, no errors"
