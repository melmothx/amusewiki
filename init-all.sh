#!/bin/bash

cd `dirname $0`

if [ "$1" == "" ]; then
    echo "Usage: $0 [ start | stop | restart ]"
    exit
fi

start_all () {
	./init-fcgi.pl start
    ./script/jobber.pl start
    sleep 5
}

stop_all () {
	./init-fcgi.pl stop
    ./script/jobber.pl stop
}

case $1 in
    start)
        start_all
	;;
    stop)
        stop_all
	;;
    restart)
        stop_all
        start_all
	;;
    *)
	echo "uh?"
	echo "Usage: $0 [ --start | --stop | --restart ]"
	exit 1
	;;
esac

