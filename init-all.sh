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

home_dir=`pwd`

mkdir -p opt/cache

prepare_app () {
# this looks like a bit of an overkill, but better have the files
# locally, without adding more work to the sysadmin

    js_dir="root/static/js"
    js_validate_dir="$js_dir/validate"
    js_validate_zip="jquery-validation-1.14.0.zip"
    ckeditor_version=4.4.3
    ckeditor_zip=ckeditor_${ckeditor_version}_standard.zip

    mkdir -p $js_validate_dir;
    # check if jquery validate is installed

    if  [ ! -f "$js_validate_dir/dist/jquery.validate.js" ]; then
        cd $js_validate_dir
        wget http://jqueryvalidation.org/files/$js_validate_zip
        unzip $js_validate_zip
        cd $home_dir
    fi

    if [ ! -f "$js_dir/ckeditor/ckeditor.js" ]; then
        cd $js_dir
        wget http://download.cksource.com/CKEditor/CKEditor/CKEditor%20$ckeditor_version/$ckeditor_zip
        unzip $ckeditor_zip
        cd $home_dir
    fi

    # perl dependencies. Probably switch to use carton

    cpanm --installdeps .
    ./script/dh-upgrade
}

# echo `pwd`

start_all () {
    prepare_app
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

