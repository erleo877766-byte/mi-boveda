#!/bin/bash
set -x -e

cd scripts/bitbox_flutter

bash ./build_bindings.sh --dont-install

FILE=go/api/api.aar
if [ -f "$FILE" ]; then
    echo "$FILE exists."
    mkdir -p android/libs
    cp "$FILE" android/libs/
else
    echo "ERROR: $FILE not found!"
    exit 1
fi
