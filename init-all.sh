#!/bin/bash

set -e
cd `dirname $0`

if [ "$1" == "" ]; then
    echo "Usage: $0 [ start | stop | restart | reboot ]"
    exit 2
fi

if [ ! -f "lib/AmuseWikiFarm.pm" ]; then
    echo "In the wrong directory!";
    exit 2
fi

mkdir -p opt/cache

start_all () {
    rm -fv current_version_is_*.txt
    amw_version=`perl -I lib -MAmuseWikiFarm -e 'print $AmuseWikiFarm::VERSION'`
    touch current_version_is_$amw_version.txt
    rm -rfv var/cache/*
	./init-fcgi.pl start
    ./script/jobber.pl start
    sleep 5
}

stop_all () {
    ./script/jobber.pl stop
	./init-fcgi.pl stop
}

case $1 in
    reboot)
        rm -fv ./var/*.pid
        start_all
    ;;
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
	echo "Usage: $0 [ start | stop | restart ]"
	exit 1
	;;
esac

