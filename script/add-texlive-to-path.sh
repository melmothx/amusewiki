homedir=`pwd`
if find local/texlive/*/bin > /dev/null 2>&1 ; then
    localtex=`find local/texlive/*/bin -name xetex | sort | tail -1`
    if [ -n "$localtex" ]; then
        texlivebin=`dirname $localtex`
        export PATH=$homedir/$texlivebin:$PATH
        echo "PATH is now $PATH"
    fi
fi

if ! which xetex >/dev/null 2>&1 ; then
    amusewikitexlive="/opt/amusewiki-texlive/current/bin/arch"
    if [ -d "$amusewikitexlive" ]; then
        export PATH=$amusewikitexlive:$PATH
        echo "PATH is now $PATH"
    fi
fi

if ! which xetex >/dev/null 2>&1; then
    echo "Missing xetex executable in $PATH"
    exit 2
fi
