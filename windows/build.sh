#!/bin/sh -e

# shellcheck disable=SC1091
. tools/common.sh

OUT_DIR=${OUT_DIR:-"$PWD/out"}
ARCH=${ARCH:-amd64}
BUILD_DIR=${BUILD_DIR:-"$PWD/build"}
ROOTDIR="$PWD"
PLATFORM="${PLATFORM:-windows}"

configure() {
    echo "-- Configuring SDL2..."

    cmake -S . -B "$BUILD_DIR" \
        -DSDL_WERROR=OFF \
        -DSDL_TEST=OFF \
        -DSDL2_DISABLE_SDL2MAIN=ON \
        -DSDL_VENDOR_INFO="crueter's CI" \
        -DSDL2_DISABLE_INSTALL=OFF \
        -DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
        -DSDL_SHARED=ON \
        -DSDL_STATIC=ON \
        -G "Ninja" \
        -DCMAKE_BUILD_TYPE=Release
}

build() {
    echo "-- Building..."

    cmake --build "$BUILD_DIR" --config Release --parallel
}

copy_build_artifacts() {
    echo "-- Copying artifacts..."
    cmake --install "$BUILD_DIR"

    cd "$OUT_DIR"
    rm -r lib/pkgconfig
    mv bin/SDL2.dll lib/libSDL2.dll

    if ! command -v clang-cl >/dev/null 2>&1
    then
        rm -r lib/cmake
        mv lib/libSDL2.a lib/libSDL2_static.lib
        mv lib/libSDL2.dll.a lib/libSDL2.lib
        rm -r bin
    else
        rm -r cmake
        mv lib/SDL2.lib lib/libSDL2.lib
        mv lib/SDL2-static.lib lib/libSDL2_static.lib
        rm -r bin
    fi

    cd "$ROOTDIR"
}

copy_cmake() {
    cp "$ROOTDIR/CMakeLists.txt" "$OUT_DIR"
}

package() {
    echo "-- Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL="$FILENAME-$PLATFORM-$ARCH-$VERSION.tar"

    cd "$OUT_DIR"
    tar cf "$ROOTDIR/artifacts/$TARBALL" ./*

    cd "$ROOTDIR/artifacts"
    zstd -10 "$TARBALL"
    rm "$TARBALL"

    "$ROOTDIR"/tools/sums.sh "$TARBALL.zst"
}

./tools/download.sh

[ -e "$BUILD_DIR" ] && rm -fr "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

extract

cd "$FILENAME-$VERSION-$ARCH"

configure

# Delete existing build artifacts
rm -fr "$OUT_DIR"
mkdir -p "$OUT_DIR" || exit 1

build
copy_build_artifacts
copy_cmake

package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"
