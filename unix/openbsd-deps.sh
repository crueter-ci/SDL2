#!/bin/sh -e

pkg_add -u

pkg_add cmake ninja bison gawk gsed \
	libiconv freetype libogg libvorbis flac libsndfile \
	opus mpg123 pulseaudio libusb1 lxrandr