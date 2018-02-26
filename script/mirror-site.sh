#!/bin/bash

# Simple client to create a static mirror of an amusewiki instance.
# E.g. 
# set -x
set -e
site=$1
if [ -z "$site" ]; then
    echo "Usage: $0 https://my.site.org [ --user \"username\" --password \"password\" ]"
    exit 2;
fi

shift

sitename=$(echo $site | sed -e 's,https\?://,,')

log=$sitename/mirror.log
mkdir -p $sitename
rm -f $sitename/mirror.ts.txt
wget -x -o $log "$@" $site/mirror.ts.txt || cat $log;


if [ ! -f "$sitename/mirror.ts.txt" ]; then
    echo "Couldn't download file list"
    exit 2
fi

urls=$sitename/mirror.download
rm -f $urls

while read -r line ; do
    file=$(echo $line | cut -f 1 -d '#');
    ts=$(echo $line | cut -f 2 -d '#');
    if [ -n "$file" -a -n "$ts" ]; then
        if [ -f "$sitename/mirror/$file" ]; then
            mine=$(stat -c "%Y" "$sitename/mirror/$file")
            if [ $ts -gt $mine ]; then
                echo "$site/mirror/$file" >> $urls
            fi
        else
            echo "$site/mirror/$file" >> $urls
        fi
    fi
done < $sitename/mirror.ts.txt

if [ -f $urls ]; then
    wget -a $log "$@" -x -N -i $urls
fi




