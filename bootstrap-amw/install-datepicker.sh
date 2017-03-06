#!/bin/bash
target=../root/static/js/datepicker
mkdir -p $target
mkdir -p $target/locales
cp bootstrap-datepicker/dist/js/bootstrap-datepicker.min.js $target
cp bootstrap-datepicker/dist/locales/bootstrap-datepicker.??.min.js $target/locales
