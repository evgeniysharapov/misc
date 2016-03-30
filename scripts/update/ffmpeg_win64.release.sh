#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  git
#  mingw-w64
#  pkg-config
#  wget
#  yasm
#

# Exit on errors:
set -eu -o pipefail

# Print message methods
printmsg() {
	echo -e "\e[1;33m + \e[1;32m$1 \e[0m"
}

# Globals:
TARGET_DIR="$HOME/ffmpeg_win64"
TMP_DIR="/tmp/ffmpeg_win64-build"
HOST="x86_64-w64-mingw32"
PREFIX="$TMP_DIR/build"

ZLIB_GIT="https://github.com/madler/zlib.git"
LIBOPENJPEG_GIT="https://github.com/uclouvain/openjpeg.git"
LIBWAVPACK_GIT="https://github.com/dbry/WavPack.git"
LIBOGG_GIT="https://git.xiph.org/ogg.git"
LIBVORBIS_GIT="https://git.xiph.org/vorbis.git"
LIBTHEORA_GIT="https://git.xiph.org/theora.git"
LIBOPUS_GIT="https://git.xiph.org/opus.git"
LIBVPX_URL="http://downloads.webmproject.org/releases/webm/libvpx-1.5.0.tar.bz2"
LIBMP3LAME_GIT="https://github.com/rbrito/lame.git"
LIBFDK_AAC_GIT="https://github.com/mstorsjo/fdk-aac.git"
LIBX264_GIT="https://git.videolan.org/git/x264.git"
LIBSDL_GIT="https://github.com/spurious/SDL-mirror.git"
FFMPEG_URL="https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2"

# Methods:
do_configure() {
	./configure \
		--prefix="$PREFIX" \
		"$@"
}

do_make_and_install() {
	nice make -j $(nproc) "$@" install
}

do_cmake_and_install() {
	cmake \
		-D CMAKE_FIND_LIBRARY_SUFFIXES=".a" \
		-D CMAKE_EXE_LINKER_FLAGS="-static" \
		-D BUILD_SHARED_LIBS=OFF \
		-D CMAKE_VERBOSE_MAKEFILE=ON \
		-D CMAKE_SYSTEM_NAME=Windows \
		-D GNU_HOST=$HOST \
		-D CMAKE_RANLIB=$(which ${HOST}-ranlib) \
		-D CMAKE_C_COMPILER=$(which ${HOST}-gcc) \
		-D CMAKE_CXX_COMPILER=$(which ${HOST}-g++) \
		-D CMAKE_RC_COMPILER=$(which ${HOST}-windres) \
		-D CMAKE_INSTALL_PREFIX="$PREFIX" \
		-D CMAKE_FIND_ROOT_PATH=/usr/${HOST} \
		-D CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-D CMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-D CMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		"@" \
		.
	do_make_and_install
}

# Process
export PKG_CONFIG_LIBDIR=
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export PATH="$PATH:$PREFIX/bin"

printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

################################################################################

printmsg "Downloading zlib..."
git clone "$ZLIB_GIT" zlib
cd zlib

printmsg "Compiling zlib..."
do_configure \
	--static
do_make_and_install \
	PREFIX="$PREFIX" \
	AR=${HOST}-ar \
	CC=${HOST}-gcc \
	CXX=${HOST}-g++ \
	LD=${HOST}-ld \
	RANLIB=${HOST}-ranlib \
	STRIP=${HOST}-strip \
	ARFLAGS=rcs
cd ..

################################################################################

printmsg "Downloading libopenjpeg..."
git clone "$LIBOPENJPEG_GIT" libopenjpeg
cd libopenjpeg

printmsg "Compiling libopenjpeg..."
do_cmake_and_install
cd ..

################################################################################

printmsg "Downloading libwavpack..."
git clone "$LIBWAVPACK_GIT" libwavpack
cd libwavpack

printmsg "Compiling libwavpack..."
./autogen.sh
do_configure \
	--host=$HOST \
	--enable-static \
	--disable-shared
do_make_and_install
cd ..

################################################################################

printmsg "Downloading libogg..."
git clone "$LIBOGG_GIT" libogg
cd libogg

printmsg "Compiling libogg..."
./autogen.sh
do_configure \
	--host=$HOST \
	--enable-static \
	--disable-shared
do_make_and_install
cd ..

################################################################################

printmsg "Downloading libvorbis..."
git clone "$LIBVORBIS_GIT" libvorbis
cd libvorbis

printmsg "Compiling libvorbis..."
./autogen.sh
do_configure \
	--host=$HOST \
	--enable-static \
	--disable-shared
do_make_and_install
cd ..

################################################################################

printmsg "Downloading libtheora..."
git clone "$LIBTHEORA_GIT" libtheora
cd libtheora

printmsg "Compiling libtheora..."
sed -i.bak 's/double rint/double rint_disabled/' examples/encoder_example.c
./autogen.sh
do_configure \
	--host=$HOST \
	--enable-static \
	--disable-shared
do_make_and_install
cd ..

################################################################################

printmsg "Downloading libopus..."
git clone "$LIBOPUS_GIT" libopus
cd libopus

printmsg "Compiling libopus..."
./autogen.sh
do_configure \
	--host=$HOST \
	--enable-static \
	--disable-shared
do_make_and_install
cd ..

################################################################################

printmsg "Downloading libvpx..."
mkdir libvpx
cd libvpx
wget "$LIBVPX_URL" --show-progress -qO - | tar -xj --strip-components=1

printmsg "Compiling libvpx..."
export CROSS=${HOST}-
do_configure \
	--target="x86_64-win64-gcc" \
	--enable-static \
	--disable-shared
do_make_and_install
unset CROSS
cd ..

################################################################################

printmsg "Downloading libmp3lame..."
git clone "$LIBMP3LAME_GIT" libmp3lame
cd libmp3lame

printmsg "Compiling libmp3lame..."
do_configure \
	--host=$HOST \
	--enable-static \
	--disable-shared
do_make_and_install
cd ..

################################################################################

printmsg "Downloading libfdk_aac..."
git clone "$LIBFDK_AAC_GIT" libfdk_aac
cd libfdk_aac

printmsg "Compiling libfdk_aac..."
./autogen.sh
do_configure \
	--host=$HOST \
	--enable-static \
	--disable-shared
do_make_and_install
cd ..

################################################################################

printmsg "Downloading libx264..."
git clone "$LIBX264_GIT" libx264
cd libx264

printmsg "Compiling libx264..."
do_configure \
	--host=$HOST \
	--cross-prefix=${HOST}- \
	--enable-static \
	--disable-shared \
	--enable-win32thread
do_make_and_install
cd ..

################################################################################

printmsg "Downloading ffmpeg..."
mkdir ffmpeg
cd ffmpeg
wget "$FFMPEG_URL" --show-progress -qO - | tar -xj --strip-components=1

printmsg "Compiling ffmpeg..."
do_configure \
	--arch=x86_64 \
	--target-os=mingw32 \
	--cross-prefix=${HOST}- \
	--pkg-config=pkg-config \
	--disable-shared \
	--enable-static \
	--enable-gpl \
	--enable-version3 \
	--enable-nonfree \
	--enable-libfdk-aac \
	--enable-libmp3lame \
	--enable-libopenjpeg \
	--enable-libtheora \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libwavpack \
	--enable-libx264 \
	--enable-zlib
do_make_and_install

################################################################################

printmsg "Moving to target folder..."
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cp "$PREFIX"/bin/{ffmpeg,ffprobe,ffplay}.exe "$TARGET_DIR" 2>/dev/null || true

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

