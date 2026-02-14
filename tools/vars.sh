#!/bin/sh -e

## Common variables ##

# In some projects you will want to fetch latest from gh/fj api
VERSION="2.32.10"
export COMMIT="cf5dabd6eaa1b7949b73eaf5268ae1c5e01ba3b6"
export PRETTY_NAME="SDL2"
export FILENAME="SDL2"
export REPO="libsdl-org/SDL"
export DIRECTORY="SDL-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$VERSION-$SHORTSHA"
