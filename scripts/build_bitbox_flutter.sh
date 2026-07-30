#!/bin/bash
set -x -e

cd scripts/bitbox_flutter

bash ./build_bindings.sh --dont-install

FILE=go/api/api.aar
if [ -f "$FILE" ]; then
    echo "$FILE exists."
else
    echo "ERROR: $FILE not found!"
    exit 1
fi
