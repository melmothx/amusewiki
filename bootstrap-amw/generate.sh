#!/bin/bash

lessc -x amw.less ../root/static/css/bootstrap.amusewiki.css
lessc -x amw.less ../root/static/css/bootstrap.css
cp bootstrap/dist/fonts/* ../root/static/fonts
cp bootstrap/dist/js/bootstrap* ../root/static/js

rm -f amw-theme.less
for theme in cerulean cosmo cyborg darkly default flatly journal lumen paper readable \
                  sandstone simplex slate spacelab superhero; do
    cat <<EOF > amw-theme.less
@import "bootstrap/less/bootstrap.less";
@import "bootswatch/$theme/variables.less";
@import "bootswatch/$theme/bootswatch.less";
@import "amw-ui.less";
EOF
    lessc -x amw-theme.less ../root/static/css/bootstrap.$theme.css || echo "Cannot generate $theme"
done
rm -f amw-theme.less
