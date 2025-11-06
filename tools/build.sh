#!/bin/bash -e

# shellcheck disable=SC1091

. tools/vars.sh

## Buildtime/Input Variables ##

ROOTDIR="$PWD"
if [ "$PLATFORM" = "android" ]; then
	: "${ANDROID_NDK_ROOT:?-- You must supply the ANDROID_NDK_ROOT environment variable.}"
	: "${ANDROID_API:=23}"
	DEFAULT_ARCH=arm64-v8a
else
	DEFAULT_ARCH=amd64
fi

: "${PLATFORM:?-- You must supply the PLATFORM environment variable.}"
: "${ARCH:=$DEFAULT_ARCH}"
: "${OUT_DIR:=$PWD/out}"
: "${BUILD_DIR:=$PWD/build}"

## Platform Stuff ##

[ "$PLATFORM" = "freebsd" ] && EXTRA_CMAKE_FLAGS=(-DSDL_ALSA=OFF -DSDL_PULSEAUDIO=OFF -DSDL_OSS=ON -DSDL_X11=ON -DTHREADS_PREFER_PTHREAD_FLAG=ON)
[ "$PLATFORM" = "openbsd" ] && EXTRA_CMAKE_FLAGS=(-DCMAKE_C_FLAGS="-L/usr/local/lib")
[ "$PLATFORM" = "solaris" ] && export PKG_CONFIG_PATH=/usr/lib/64/pkgconfig && EXTRA_CMAKE_FLAGS=(-DSDL_HIDAPI=OFF)

case "$PLATFORM" in
	linux) EXTRA_CMAKE_FLAGS+=(-DCMAKE_INSTALL_LIBDIR=lib);;
	windows | mingw) ;;
	*) EXTRA_CMAKE_FLAGS+=(-DCMAKE_INSTALL_LIBDIR=lib -DSDL_IBUS=OFF -DSDL_WAYLAND=OFF -DSDL_PIPEWIRE=OFF -DSDL_ALSA=OFF -DSDL_LIBUDEV=OFF -DSDL_DBUS=OFF) ;;
esac

## Utility Functions ##

# extract the archive + apply patches
extract() {
	echo "-- Extracting $PRETTY_NAME $VERSION"
	rm -fr "$DIRECTORY"

	case "$ARTIFACT" in
		*.zip) unzip "$ROOTDIR/$ARTIFACT" >/dev/null ;;
		*.tar.*) tar xf "$ROOTDIR/$ARTIFACT" >/dev/null ;;
		*.7z) 7z x "$ROOTDIR/$ARTIFACT" >/dev/null ;;
		*) echo "-- Unsupported extension ${ARTIFACT##.*}"; exit 1 ;;
	esac

	## Patches ##
	pushd "$DIRECTORY" >/dev/null

	# thanks solaris
	sed 's/LINUX OR FREEBSD/LINUX/' CMakeLists.txt > cmake.tmp && mv cmake.tmp CMakeLists.txt

	# thanks microsoft
	patch -p1 < "$ROOTDIR"/.patch/0001-sdl-endian.patch

	popd >/dev/null
}

# generate sha1, 256, and 512 sums for a file
sums() {
	for file in "$@"; do
		for algo in 1 256 512; do
			if ! command -v sha${algo}sum >/dev/null 2>&1; then
				sha${algo} "$file" | awk '{print $4}' | tr -d "\n" > "$file".sha${algo}sum
			else
				sha${algo}sum "$file" | cut -d " " -f1 | tr -d "\n" > "$file".sha${algo}sum
			fi
		done
	done
}

# download
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ARTIFACT"
download() {
	while true; do
		if [ ! -f "$ARTIFACT" ]; then
			curl "$DOWNLOAD_URL" -o "$ARTIFACT" && break
			echo "-- -- Download failed, trying again in 5 seconds..."
			sleep 5
		else
			break
		fi
	done
}

# false if on windows
unix() {
	case "$PLATFORM" in
		windows|mingw) false ;;
		*) true ;;
	esac
}

## Build Functions ##

# cmake
configure() {
	[ "$PLATFORM" = android ] && return

	echo "-- Configuring..."

	cmake -S . -B "$BUILD_DIR" \
		-DSDL_WERROR=OFF \
		-DSDL_TEST=OFF \
		-DSDL_VENDOR_INFO="crueter's CI" \
		-DSDL2_DISABLE_INSTALL=OFF \
		-DSDL2_DISABLE_SDL2MAIN=ON \
		-DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
		-DSDL_SHARED=ON \
		-DSDL_STATIC=ON \
		-G "Ninja" \
		-DCMAKE_BUILD_TYPE=Release \
		"${EXTRA_CMAKE_FLAGS[@]}"
}

build() {
	echo "-- Building..."

	if [ "$PLATFORM" = android ]; then
		export PATH="$ANDROID_NDK_ROOT:$PATH"

		hosts="linux-x86_64 linux-x86 darwin-x86_64 darwin-x86 windows-x86_64"
		for host in $hosts; do
			if [ -d "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin" ]; then
				ANDROID_TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin"
				export PATH="$ANDROID_TOOLCHAIN:$PATH"
				break
			fi
		done

		sed -i "s/armeabi-v7a arm64-v8a x86 x86_64/$ARCH/" build-scripts/androidbuildlibs.sh
		sed -i 's/SDL2 SDL2_main/SDL2 SDL2_static/' build-scripts/androidbuildlibs.sh
		sed -i "s/android-16/android-$ANDROID_API/" build-scripts/androidbuildlibs.sh
		build-scripts/androidbuildlibs.sh -j"$(nproc)"
	else
		cmake --build "$BUILD_DIR" --config Release --parallel
	fi
}

strip_libs() {
	case "$PLATFORM" in
		windows|mingw) ;;
		android) find "$OUT_DIR" -name "*.so" -exec llvm-strip --strip-all {} \; ;;
		*) find "$OUT_DIR" -name "*.so" -exec strip {} \;
	esac
}

## Packaging ##
copy_build_artifacts() {
    echo "-- Copying artifacts..."

	if [ "$PLATFORM" = android ]; then
	    mkdir "$OUT_DIR"/lib "$OUT_DIR"/include
		cp "build/android/obj/local/$ARCH"/libSDL2* "$OUT_DIR"/lib
		cp include/*.h "$OUT_DIR"/include
		return
	fi

    cmake --install "$BUILD_DIR"

    echo "-- Cleaning..."
    rm -rf "$OUT_DIR"/lib/pkgconfig
    rm -rf "$OUT_DIR"/lib/cmake
    rm -rf "$OUT_DIR"/cmake

	if unix; then
		rm -rf "$OUT_DIR"/libdata
		rm -rf "$OUT_DIR"/share
		find "$OUT_DIR/lib" -type l -exec rm {} \;
		mv "$OUT_DIR/lib"/*.so* "$OUT_DIR/lib/libSDL2.so"
	else
	    mv bin/SDL2.dll lib/libSDL2.dll
		if ! command -v clang-cl >/dev/null 2>&1; then
			mv "$OUT_DIR"/lib/libSDL2.a "$OUT_DIR"/lib/libSDL2_static.lib
			mv "$OUT_DIR"/lib/libSDL2.dll.a "$OUT_DIR"/lib/libSDL2.lib
		else
			mv "$OUT_DIR"/lib/SDL2.lib "$OUT_DIR"/lib/libSDL2.lib
			mv "$OUT_DIR"/lib/SDL2-static.lib "$OUT_DIR"/lib/libSDL2_static.lib
		fi
	fi

	rm -rf "${OUT_DIR:?}/bin"
}

copy_cmake() {
    cp "$ROOTDIR/CMakeLists.txt" "$OUT_DIR"
}

package() {
    echo "-- Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

	TARBALL=$FILENAME-$PLATFORM-$ARCH-$VERSION.tar

    cd "$OUT_DIR"
    tar cf "$ROOTDIR/artifacts/$TARBALL" ./*

    cd "$ROOTDIR/artifacts"
    zstd -10 "$TARBALL"
    rm "$TARBALL"

    sums "$TARBALL.zst"
}

## Cleanup ##
rm -rf "$BUILD_DIR" "$OUT_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

## Download + Extract ##
cd "$BUILD_DIR"
download
extract

## Configure ##
cd "$DIRECTORY"
configure

## Build ##
build

## Package ##
copy_build_artifacts
copy_cmake

strip_libs
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"
