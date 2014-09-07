#!/bin/bash

set -e

cgitversion="v0.10.2"

cd $(dirname $(dirname $0));
amw_home=$(pwd);
echo "Base dir is $amw_home";
if [ ! -d lib/AmuseWikiFarm ]; then
    echo "This script is buggy, couldn't find the app dir";
    exit 2
fi

optdir=$amw_home/opt
srcdir=$optdir/src
cachedir=$optdir/cache/cgit
etcdir=$optdir/etc
cgitrc=$etcdir/cgitrc
libdir=$optdir/usr


mkdir -p $srcdir
cd $srcdir

if [ ! -d cgit ]; then
    git clone git://git.zx2c4.com/cgit
    cd cgit
    git submodule init
    cd $srcdir
    echo "In $(pwd)"
fi

cd cgit
git checkout $cgitversion
git submodule update

make clean
make CGIT_SCRIPT_PATH=$amw_home/root/git CGIT_CONFIG=$cgitrc \
    CACHE_ROOT=$cachedir prefix=$libdir install

cd $amw_home

mkdir -p $cachedir

echo "*******************************************************"
echo "**** Please chown $cachedir to www-data ****"
echo "*******************************************************"

# strip the cgi to have a smaller one
if [ -f $amw_home/root/git/cgit.cgi ]; then
    strip --strip-unneeded $amw_home/root/git/cgit.cgi
else
    echo "cgi not installed, bailing out"
    exit 2
fi

echo "The configuration file is $cgitrc"
if [ ! -f $cgitrc ]; then
    mkdir -p $etcdir
    cp $amw_home/doc/cgitrc.example $cgitrc
    echo >> $cgitrc
    script/generate-cgit-repolist.pl >> $cgitrc
fi

if [ ! -d $amw_home/root/static/cgit ]; then
    mkdir -p $amw_home/root/static/cgit
fi

for i in cgit.css cgit.png; do
    mv -v $amw_home/root/git/$i $amw_home/root/static/cgit
done
