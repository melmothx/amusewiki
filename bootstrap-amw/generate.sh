#!/bin/bash

cp bootstrap/dist/js/bootstrap.bundle.* ../root/static/js
for theme in amusecosmo amusewiki amusejournal; do
    sass $theme.scss ../root/static/css/bootstrap.$theme.css
done

rm -f amw-theme.scss
for theme in bootswatch/dist/*; do
    theme=$(basename $theme);
    cat <<EOF > amw-theme.scss
@import "bootswatch/dist/$theme/variables";
@import "bootstrap/scss/bootstrap";
@import "bootswatch/dist/$theme/bootswatch";
@import "amw-ui";
EOF
    echo "Generating $theme from amw-theme.scss"
    sass amw-theme.scss ../root/static/css/bootstrap.$theme.css || echo "Cannot generate $theme"
done
rm -f amw-theme.scss
