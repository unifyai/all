#!/bin/bash -e
if [ -z $1 ]; then
    echo "You need to provide a commit message"
    exit
fi

git add -A .
git commit -m "$1"
git push
