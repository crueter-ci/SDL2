#!/bin/sh

# Downloads the specified version of SDL2.
# Requires: wget

# shellcheck disable=SC1091
. tools/common.sh || exit 1

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ARTIFACT"

while true; do
   if [ ! -f "$ARTIFACT" ]; then
       wget "$DOWNLOAD_URL" -O "$ARTIFACT" && exit 0
       echo "-- -- Download failed, trying again in 5 seconds..."
       sleep 5
    else
        exit 0
    fi
done
