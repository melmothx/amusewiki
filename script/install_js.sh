#!/bin/sh
set -e
home_dir=`pwd`
js_dir="root/static/js"
ckeditor_version=4.4.3
ckeditor_zip=ckeditor_${ckeditor_version}_standard.zip

if [ "x$1" = "x--clean" ]; then
    rm -rf $js_dir/ckeditor
    rm -rf $js_dir/highlight
fi

if [ ! -d "$js_dir/ckeditor" ]; then
    cd $js_dir
    if [ -f "/usr/share/javascript/ckeditor/ckeditor.js" ]; then
        ln -s /usr/share/javascript/ckeditor
    else
        wget https://download.cksource.com/CKEditor/CKEditor/CKEditor%20$ckeditor_version/$ckeditor_zip
        unzip $ckeditor_zip
    fi
    cd "$home_dir"
fi

if [ ! -d "$js_dir/highlight" ]; then
    cd $js_dir
    if [ -d "/usr/share/javascript/highlight.js" ]; then
        ln -s /usr/share/javascript/highlight.js highlight
    else
        mkdir highlight
        cd highlight
        wget https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.1.0/highlight.min.js
        mkdir styles
        wget -O styles/default.css https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.1.0/styles/default.min.css
    fi
    cd "$home_dir"
fi
