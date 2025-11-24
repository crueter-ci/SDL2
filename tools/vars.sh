#!/bin/sh -e

## Common variables ##

# In some projects you will want to fetch latest from gh/fj api
VERSION="2.32.10"
export COMMIT="a65111bd2d8aa18290f4a2146f3dcd46291a7574"
export PRETTY_NAME="SDL2"
export FILENAME="SDL2"
export REPO="libsdl-org/SDL"
export DIRECTORY="SDL-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$VERSION-$SHORTSHA"
