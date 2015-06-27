#!/bin/bash

lessc -x amw.less ../root/static/css/bootstrap.css
cp bootstrap/dist/fonts/* ../root/static/fonts
cp bootstrap/dist/js/bootstrap* ../root/static/js
