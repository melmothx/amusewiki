#!/bin/bash

cd `dirname $0`
eval `perl -Mlocal::lib`

if [ "$1" == "" ]; then
    echo "Usage: $0 [ start | stop | restart ]"
    exit
fi

case $1 in
    start)
	    ./init-fcgi.pl start
        ./init-jobs.pl start
        sleep 5
	;;
    stop)
	    ./init-fcgi.pl stop
        ./init-jobs.pl stop
	;;
    restart)
	    ./init-fcgi.pl stop
        ./init-jobs.pl stop
        sleep 5
	    ./init-fcgi.pl start
        ./init-jobs.pl start
	;;
    *)
	echo "uh?"
	echo "Usage: $0 [ --start | --stop | --restart ]"
	exit 1
	;;
esac

