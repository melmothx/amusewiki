#!/bin/bash
set -e
set -x
for i in bootstrap/dist/js/bootstrap.bundle.*; do
    cp $i ../root/static/js/bs5-$(basename $i)
done

# these are not ported yet: robotojournal purplejournal
for theme in amusecosmo amusewiki amusejournal; do
    if [ -f $theme.scss ]; then
        ./dart-sass/sass --style compressed $theme.scss ../root/static/css/bootstrap.$theme-bs5.css
    else
        echo "Missing $theme.scss";
    fi
done

rm -f amw-theme.scss
for theme in bootswatch/dist/*; do
    cat <<EOF > amw-theme.scss
@import "$theme/_variables";
@import "bootstrap/scss/bootstrap";
@import "$theme/_bootswatch";
@import "amw-ui";
EOF
    echo "Generating $theme from amw-theme.scss"
    ./dart-sass/sass --style compressed amw-theme.scss ../root/static/css/bootstrap.$(basename $theme)-bs5.css || echo "Cannot generate $theme"
done
rm -f amw-theme.scss
