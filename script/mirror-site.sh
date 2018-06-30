#!/bin/bash

# Simple client to create a static mirror of an amusewiki instance.

echo "Replaced by mirror-site.pl in the same amusewiki directory"

cd $(dirname $0) || exit 2;
basedir=$(pwd);
$basedir/mirror-site.pl "$@"
