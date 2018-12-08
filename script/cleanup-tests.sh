#!/bin/sh

# as per doc, repos starting with 0 are tests.
for i in repo/0*; do
    echo "Removing $i"
    rm -rf "$i"
done

