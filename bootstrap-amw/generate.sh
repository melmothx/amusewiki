#!/bin/bash

# cp bootstrap/dist/fonts/* ../root/static/fonts
cp bootstrap/dist/js/bootstrap* ../root/static/js
lessc -x amusewiki.less ../root/static/css/bootstrap.css
for theme in amusecosmo amusewiki amusejournal; do
    lessc -x $theme.less ../root/static/css/bootstrap.$theme.css
done

rm -f amw-theme.less
for theme in cerulean cosmo cyborg darkly default flatly journal lumen paper readable \
                  sandstone simplex slate spacelab superhero united yeti; do
    cat <<EOF > amw-theme.less
@import "bootstrap.less";
@import "bootswatch/$theme/variables.less";
@import "bootswatch/$theme/bootswatch.less";
@import "amw-ui.less";
EOF
    lessc -x amw-theme.less ../root/static/css/bootstrap.$theme.css || echo "Cannot generate $theme"
done
rm -f amw-theme.less
