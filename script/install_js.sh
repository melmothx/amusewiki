#!/bin/sh
set -e
# set -x
home_dir=`pwd`
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
    if [ ! -f "/usr/share/javascript/ckeditor/ckeditor.js" ]; then
        cd $js_dir
        wget http://download.cksource.com/CKEditor/CKEditor/CKEditor%20$ckeditor_version/$ckeditor_zip
        unzip $ckeditor_zip
        cd $home_dir
    fi
fi
