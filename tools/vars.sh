#!/bin/sh -e

## Common variables ##

# In some projects you will want to fetch latest from gh/fj api
VERSION="2.28.4"
export COMMIT="cc016b0046d563287f0aa9f09b958b5e70d43696"
export PRETTY_NAME="SDL2"
export FILENAME="SDL2"
export REPO="libsdl-org/SDL"
export DIRECTORY="SDL-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$VERSION-$SHORTSHA"
