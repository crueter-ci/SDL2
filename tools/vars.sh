#!/bin/sh -e

## Common variables ##

# In some projects you will want to fetch latest from gh/fj api
VERSION="2.32.10"
export COMMIT="38e00946370a5f6e2d6c762cd9dcf6ec8ea3824d"
export PRETTY_NAME="SDL2"
export FILENAME="SDL2"
export REPO="libsdl-org/SDL"
export DIRECTORY="SDL-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$VERSION-$SHORTSHA"
