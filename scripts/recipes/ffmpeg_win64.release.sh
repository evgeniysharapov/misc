#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  git
#  libtool
#  mingw-w64
#  pkg-config
#  yasm
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
installDir="$HOME/ffmpeg_win64"
tmpDir='/tmp/ffmpeg_win64-build'
host='x86_64-w64-mingw32'
prefix="$tmpDir/build"

zlibGit='https://github.com/madler/zlib.git'
libopenjpegGit='https://github.com/uclouvain/openjpeg.git'
libwavpackGit='https://github.com/dbry/WavPack.git'
liboggGit='https://git.xiph.org/ogg.git'
libvorbisGit='https://git.xiph.org/vorbis.git'
libtheoraGit='https://git.xiph.org/theora.git'
libopusGit='https://git.xiph.org/opus.git'
libvpxUrl='http://downloads.webmproject.org/releases/webm/libvpx-1.5.0.tar.bz2'
libmp3lameGit='https://github.com/rbrito/lame.git'
libfdkaacGit='https://github.com/mstorsjo/fdk-aac.git'
libx264Git='https://git.videolan.org/git/x264.git'
libsdlGit='https://github.com/spurious/SDL-mirror.git'
ffmpegUrl='https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2'

# Methods:
doConfigure() {
	./configure \
		--prefix="$prefix" \
		"$@"
}

doMakeAndInstall() {
	nice make -j $(nproc) "$@" install
}

doCMakeAndInstall() {
	cmake \
		-D CMAKE_FIND_LIBRARY_SUFFIXES='.a' \
		-D CMAKE_EXE_LINKER_FLAGS='-static' \
		-D BUILD_SHARED_LIBS=OFF \
		-D CMAKE_VERBOSE_MAKEFILE=ON \
		-D CMAKE_SYSTEM_NAME=Windows \
		-D GNU_HOST=$host \
		-D CMAKE_RANLIB=$(which ${host}-ranlib) \
		-D CMAKE_C_COMPILER=$(which ${host}-gcc) \
		-D CMAKE_CXX_COMPILER=$(which ${host}-g++) \
		-D CMAKE_RC_COMPILER=$(which ${host}-windres) \
		-D CMAKE_INSTALL_PREFIX="$prefix" \
		-D CMAKE_FIND_ROOT_PATH=/usr/${host} \
		-D CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-D CMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-D CMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		'@' \
		.
	doMakeAndInstall
}

# Process
source "$scriptDir"/../common

export PKG_CONFIG_LIBDIR=
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"
export PATH="$PATH:$prefix/bin"

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir -p "$tmpDir"
cd "$tmpDir"

################################################################################

infoMsg 'Downloading zlib...'
git clone "$zlibGit" zlib
cd zlib

infoMsg 'Compiling zlib...'
doConfigure \
	--static
doMakeAndInstall \
	PREFIX="$prefix" \
	AR=${host}-ar \
	CC=${host}-gcc \
	CXX=${host}-g++ \
	LD=${host}-ld \
	RANLIB=${host}-ranlib \
	STRIP=${host}-strip \
	ARFLAGS=rcs
cd ..

################################################################################

infoMsg 'Downloading libopenjpeg...'
git clone "$libopenjpegGit" libopenjpeg
cd libopenjpeg

infoMsg 'Compiling libopenjpeg...'
doCMakeAndInstall
cd ..

################################################################################

infoMsg 'Downloading libwavpack...'
git clone "$libwavpackGit" libwavpack
cd libwavpack

infoMsg 'Compiling libwavpack...'
./autogen.sh
doConfigure \
	--host=$host \
	--enable-static \
	--disable-shared
doMakeAndInstall
cd ..

################################################################################

infoMsg 'Downloading libogg...'
git clone "$liboggGit" libogg
cd libogg

infoMsg 'Compiling libogg...'
./autogen.sh
doConfigure \
	--host=$host \
	--enable-static \
	--disable-shared
doMakeAndInstall
cd ..

################################################################################

infoMsg 'Downloading libvorbis...'
git clone "$libvorbisGit" libvorbis
cd libvorbis

infoMsg 'Compiling libvorbis...'
./autogen.sh
doConfigure \
	--host=$host \
	--enable-static \
	--disable-shared
doMakeAndInstall
cd ..

################################################################################

infoMsg 'Downloading libtheora...'
git clone "$libtheoraGit" libtheora
cd libtheora

infoMsg 'Compiling libtheora...'
sed -i.bak 's/double rint/double rint_disabled/' examples/encoder_example.c
./autogen.sh
doConfigure \
	--host=$host \
	--enable-static \
	--disable-shared
doMakeAndInstall
cd ..

################################################################################

infoMsg 'Downloading libopus...'
git clone "$libopusGit" libopus
cd libopus

infoMsg 'Compiling libopus...'
./autogen.sh
doConfigure \
	--host=$host \
	--enable-static \
	--disable-shared
doMakeAndInstall
cd ..

################################################################################

infoMsg 'Downloading libvpx...'
mkdir libvpx
cd libvpx
wget "$libvpxUrl" --show-progress -qO - | tar -xj --strip-components=1

infoMsg 'Compiling libvpx...'
export CROSS=${host}-
doConfigure \
	--target='x86_64-win64-gcc' \
	--enable-static \
	--disable-shared
doMakeAndInstall
unset CROSS
cd ..

################################################################################

infoMsg 'Downloading libmp3lame...'
git clone "$libmp3lameGit" libmp3lame
cd libmp3lame

infoMsg 'Compiling libmp3lame...'
doConfigure \
	--host=$host \
	--enable-static \
	--disable-shared
doMakeAndInstall
cd ..

################################################################################

infoMsg 'Downloading libfdk_aac...'
git clone "$libfdkaacGit" libfdk_aac
cd libfdk_aac

infoMsg 'Compiling libfdk_aac...'
./autogen.sh
doConfigure \
	--host=$host \
	--enable-static \
	--disable-shared
doMakeAndInstall
cd ..

################################################################################

infoMsg 'Downloading libx264...'
git clone "$libx264Git" libx264
cd libx264

infoMsg 'Compiling libx264...'
doConfigure \
	--host=$host \
	--cross-prefix=${host}- \
	--enable-static \
	--disable-shared \
	--enable-win32thread
doMakeAndInstall
cd ..

################################################################################

infoMsg 'Downloading ffmpeg...'
mkdir ffmpeg
cd ffmpeg
wget "$ffmpegUrl" --show-progress -qO - | tar -xj --strip-components=1

infoMsg 'Compiling ffmpeg...'
doConfigure \
	--arch=x86_64 \
	--target-os=mingw32 \
	--cross-prefix=${host}- \
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
doMakeAndInstall

################################################################################

infoMsg 'Moving to target folder...'
rm -rf "$installDir"
mkdir -p "$installDir"
cp "$prefix"/bin/{ffmpeg,ffprobe,ffplay}.exe "$installDir" 2>/dev/null || true

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

