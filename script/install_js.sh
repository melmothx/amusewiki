#!/bin/sh
set -e
home_dir=`pwd`
js_dir="root/static/js"

if [ "x$1" = "x--clean" ]; then
    rm -rf $js_dir/highlight
fi

if [ ! -d "$js_dir/highlight" ]; then
    cd $js_dir
    if [ -d "/usr/share/javascript/highlight.js" ]; then
        ln -s /usr/share/javascript/highlight.js highlight
    else
        mkdir highlight
        cd highlight
        wget https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/highlight.min.js
        mkdir styles
        wget -O styles/default.css https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/styles/default.min.css
    fi
    cd "$home_dir"
fi
