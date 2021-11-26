#!/bin/bash -e
if [ -z $1 ]; then
    echo "You need to provide a commit message"
    exit
fi

git submodule foreach git commit -am "$1"
git commit -am "$1"
