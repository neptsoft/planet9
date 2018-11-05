#!/bin/sh

# If we have any custom NPM modules we want to install,
# add them
if [ -f package.json ]; then
    npm i
fi

mkdir log
chown node log
