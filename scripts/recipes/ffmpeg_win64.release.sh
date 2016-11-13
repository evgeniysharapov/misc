#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  autoconf
#  automake
#  autopoint
#  build-essential
#  pkg-config
#  git
#  gperf
#  libtool
#  mingw-w64
#  mingw-w64-tools
#  ragel
#  yasm
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
installDir="$HOME/ffmpeg_win64"
tmpDir=$(mktemp -d /tmp/ffmpeg-win64.XXXXXXXX)
build=$(gcc -dumpmachine)
target='x86_64-w64-mingw32'
host="$target"
prefix="$tmpDir/build"

zlibGit='https://github.com/madler/zlib.git'
bzip2Git='https://anonscm.debian.org/git/collab-maint/bzip2.git'
lzmaGit='https://anonscm.debian.org/git/collab-maint/xz.git'
libdlfcnGit='https://github.com/dlfcn-win32/dlfcn-win32.git'
libresslGit='https://github.com/libressl-portable/portable.git'
libsdlGit='https://anonscm.debian.org/git/pkg-sdl/packages/libsdl1.2.git'
libsdl2Git='https://anonscm.debian.org/git/pkg-sdl/packages/libsdl2.git'
libpngGit='https://github.com/glennrp/libpng.git'
libxml2Git='https://github.com/gnome/libxml2.git'
libfreetypeGit='http://git.savannah.gnu.org/r/freetype/freetype2.git'
libfontconfigGit='https://anongit.freedesktop.org/git/fontconfig'
libfribidiGit='https://anonscm.debian.org/git/collab-maint/fribidi.git'
libassGit='https://anonscm.debian.org/git/pkg-multimedia/libass.git'
libfdkaacGit='https://anonscm.debian.org/git/pkg-multimedia/fdk-aac.git'
libmp3lameGit='https://anonscm.debian.org/git/pkg-multimedia/lame.git'
liboggGit='https://github.com/xiph/ogg.git'
libopusGit='https://github.com/xiph/opus.git'
libvorbisGit='https://github.com/xiph/vorbis.git'
libwavpackGit='https://anonscm.debian.org/git/pkg-multimedia/wavpack.git'
libblurayGit='https://anonscm.debian.org/git/pkg-multimedia/libbluray.git'
libtheoraGit='https://github.com/xiph/theora.git'
libvpxGit='https://github.com/webmproject/libvpx.git'
libwebpGit='https://github.com/webmproject/libwebp.git'
libx264Git='https://anonscm.debian.org/git/pkg-multimedia/x264.git'
libx265Git='https://anonscm.debian.org/git/pkg-multimedia/x265.git'
libxvidGit='https://anonscm.debian.org/git/pkg-multimedia/xvidcore.git'
ffmpegUrl='https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2'

# Methods
doGitCloneAndCd() {
	infoMsg "Building $2..."

	git clone --recursive "$1" "$tmpDir"/"$2"
	cd "$tmpDir"/"$2"
}

doGitCloneLastTagAndCd() {
	doGitCloneAndCd "$@"

	if $(git describe --tags &> /dev/null); then
		git checkout "$(git describe --abbrev=0 --tags)"
	fi
}

doConfigure() {
	if [ -f autogen.sh ]; then
		./autogen.sh
	fi

	if [ -f bootstrap ]; then
		./bootstrap
	fi

	./configure \
		--prefix="$prefix" \
		"$@"
}

doCrossConfigure() {
	doConfigure \
		--build=$build \
		--target=$target \
		--host=$host \
		--enable-static \
		--disable-shared \
		--disable-debug \
		--disable-docs \
		--disable-doc \
		--disable-examples \
		--disable-tests \
		"$@"
}

doMake() {
	nice make \
		-j $(nproc) \
		"$@"
}

doCrossMake() {
	doMake \
		-e AR=$(which ${host}-ar) \
		-e AS=$(which ${host}-as) \
		-e CC=$(which ${host}-gcc) \
		-e CXX=$(which ${host}-g++) \
		-e LD=$(which ${host}-ld) \
		-e NM=$(which ${host}-nm) \
		-e RANLIB=$(which ${host}-ranlib) \
		-e RC=$(which ${host}-windres) \
		-e STRIP=$(which ${host}-strip) \
		"$@"
}

doCrossCMake() {
	cmake \
		-D CMAKE_FIND_LIBRARY_SUFFIXES='.a' \
		-D CMAKE_EXE_LINKER_FLAGS='-static' \
		-D BUILD_SHARED_LIBS=OFF \
		-D CMAKE_VERBOSE_MAKEFILE=ON \
		-D CMAKE_SYSTEM_NAME=Windows \
		-D GNU_HOST=$host \
		-D CMAKE_C_COMPILER=$(which ${host}-gcc) \
		-D CMAKE_CXX_COMPILER=$(which ${host}-g++) \
		-D CMAKE_RC_COMPILER=$(which ${host}-windres) \
		-D CMAKE_AR=$(which ${host}-ar) \
		-D CMAKE_AS=$(which ${host}-as) \
		-D CMAKE_LD=$(which ${host}-ld) \
		-D CMAKE_RANLIB=$(which ${host}-ranlib) \
		-D CMAKE_STRIP=$(which ${host}-strip) \
		-D CMAKE_INSTALL_PREFIX="$prefix" \
		-D CMAKE_FIND_ROOT_PATH=/usr/${host} \
		-D CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-D CMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-D CMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		"$@"

	doMake install
}

addIncludeDir() {
	CPPFLAGS="$CPPFLAGS -I$prefix/include -I$prefix/include/$1"
	CFLAGS="$CPPFLAGS"
	CXXFLAGS="$CPPFLAGS"
}

# Load helpers
if [ -f "$scriptDir"/_helpers.sh ]; then
	source "$scriptDir"/_helpers.sh
else
	source <(curl -sL 'https://raw.githubusercontent.com/zant95/misc/master/scripts/recipes/_helpers.sh')
fi

# Process
export PATH="$PATH:$prefix/bin"
export PKG_CONFIG_LIBDIR=''
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"
export LDFLAGS="-L$prefix/lib"
export CPPFLAGS="-g -O2 -I$prefix/include"
export CFLAGS="$CPPFLAGS"
export CXXFLAGS="$CPPFLAGS"

# ZLIB #########################################################################

doGitCloneLastTagAndCd "$zlibGit" zlib

doConfigure \
	--static
doCrossMake install \
	-e ARFLAGS=rcs

# BZIP2 ########################################################################

doGitCloneLastTagAndCd "$bzip2Git" bzip2

sed -i '/#[[:blank:]]*include/s/\\/\//g' *.c *.h
doCrossMake install \
	-e PREFIX="$prefix"

# LZMA #######################################################################

#doGitCloneLastTagAndCd "$lzmaGit" lzma

#doConfigure \
#	--build=$build
#doMake install

#addIncludeDir lzma

# LIBDLFCN ######################################################################

doGitCloneAndCd "$libdlfcnGit" libdlfcn

doConfigure \
	--prefix="$prefix" \
	--cross-prefix=${host}- \
	--disable-shared \
	--enable-static
doMake
doMake install

# LIBRESSL ######################################################################

doGitCloneAndCd "$libresslGit" libressl

doCrossConfigure
doMake install

addIncludeDir openssl

# SDL #########################################################################

#doGitCloneLastTagAndCd "$libsdlGit" libsdl

#doCrossConfigure
#doMake install

# ffmpeg expects ${host}-sdl-config
#ln -s "$prefix"/bin/sdl-config "$prefix"/bin/${host}-sdl-config

#addIncludeDir SDL

# SDL2 #########################################################################

#doGitCloneLastTagAndCd "$libsdl2Git" libsdl2

#doCrossConfigure \
#	--disable-render-d3d
#doMake install

# ffmpeg expects ${host}-sdl2-config
#ln -s "$prefix"/bin/sdl2-config "$prefix"/bin/${host}-sdl2-config

#addIncludeDir SDL2

# LIBPNG #######################################################################

doGitCloneLastTagAndCd "$libpngGit" libpng

doCrossConfigure
doMake install

addIncludeDir libpng16

# LIBXML2 ######################################################################

doGitCloneLastTagAndCd "$libxml2Git" libxml2

doCrossConfigure \
	--without-python
doMake install

addIncludeDir libxml2

# LIBFREETYPE ##################################################################

doGitCloneLastTagAndCd "$libfreetypeGit" libfreetype

doCrossConfigure
doMake install

addIncludeDir freetype2

# LIBFONTCONFIG ################################################################

doGitCloneLastTagAndCd "$libfontconfigGit" libfontconfig

doCrossConfigure \
	--enable-libxml2
doMake install

addIncludeDir fontconfig

# LIBFRIBIDI ###################################################################

doGitCloneLastTagAndCd "$libfribidiGit" libfribidi

doCrossConfigure
doMake install

addIncludeDir fribidi

# LIBASS #######################################################################

doGitCloneLastTagAndCd "$libassGit" libass

doCrossConfigure \
	--disable-asm \
	--disable-harfbuzz
doMake install

addIncludeDir ass

# LIBFDK-AAC ###################################################################

doGitCloneLastTagAndCd "$libfdkaacGit" libfdk_aac

doCrossConfigure
doMake install

addIncludeDir fdk-aac

# LIBMP3LAME ###################################################################

doGitCloneLastTagAndCd "$libmp3lameGit" libmp3lame

doCrossConfigure \
	--disable-frontend
doMake install

addIncludeDir lame

# LIBOGG #######################################################################

doGitCloneLastTagAndCd "$liboggGit" libogg

doCrossConfigure
doMake install

addIncludeDir ogg

# LIBOPUS ######################################################################

doGitCloneLastTagAndCd "$libopusGit" libopus

doCrossConfigure \
	--disable-extra-programs
doMake install

addIncludeDir opus

# LIBBLURAY ####################################################################

doGitCloneLastTagAndCd "$libblurayGit" libbluray

doCrossConfigure \
	--disable-bdjava
doMake install

addIncludeDir libbluray

# LIBWAVPACK ###################################################################

doGitCloneLastTagAndCd "$libwavpackGit" libwavpack

doCrossConfigure
doMake install

addIncludeDir wavpack

# LIBVORBIS ####################################################################

doGitCloneLastTagAndCd "$libvorbisGit" libvorbis

doCrossConfigure
doMake install

addIncludeDir vorbis

# LIBTHEORA ####################################################################

doGitCloneLastTagAndCd "$libtheoraGit" libtheora

doCrossConfigure
doMake install

addIncludeDir theora

# LIBVPX #######################################################################

doGitCloneLastTagAndCd "$libvpxGit" libvpx

CROSS="${host}-" doConfigure \
	--target='x86_64-win64-gcc' \
	--enable-runtime-cpu-detect \
	--enable-static \
	--disable-shared \
	--disable-examples \
	--disable-docs \
	--disable-install-bins \
	--disable-install-docs \
	--disable-install-srcs \
	--enable-pic \
	--enable-vp8 \
	--enable-postproc \
	--enable-vp9 \
	--enable-vp9-highbitdepth \
	--enable-experimental \
	--enable-spatial-svc
doMake install

addIncludeDir vpx

# LIBWEBP #######################################################################

doGitCloneLastTagAndCd "$libwebpGit" libwebp

doCrossConfigure
doMake install

addIncludeDir webp

# LIBX264 ######################################################################

doGitCloneLastTagAndCd "$libx264Git" libx264

doCrossConfigure \
	--cross-prefix=${host}- \
	--enable-win32thread
doMake install

# LIBX265 ######################################################################

doGitCloneLastTagAndCd "$libx265Git" libx265

cd ./build/linux
doCrossCMake \
	-G "Unix Makefiles" \
	-D "ENABLE_SHARED:BOOL=OFF" \
	-D "ENABLE_CLI:BOOL=OFF" \
	-D "HIGH_BIT_DEPTH:BOOL=ON" \
	../../source

# LIBXVID ###################################################################

doGitCloneLastTagAndCd "$libxvidGit" libxvid

cd ./build/generic
doCrossConfigure
doMake
doMake install

# force a static build
if [[ -f "$prefix"/lib/xvidcore.dll.a ]]; then
	rm "$prefix"/lib/xvidcore.dll.a
	mv "$prefix"/lib/xvidcore.a "$prefix"/lib/libxvidcore.a
fi

# FFMPEG #######################################################################

infoMsg 'Building ffmpeg...'
mkdir "$tmpDir"/ffmpeg && cd "$tmpDir"/ffmpeg
wget "$ffmpegUrl" --show-progress -qO - | tar -xj --strip-components=1

doConfigure \
	--arch=x86_64 \
	--target-os=mingw32 \
	--cross-prefix=${host}- \
	--extra-ldflags='-static-libgcc -static-libstdc++ -Wl,-Bstatic -mconsole' \
	--extra-libs='-lstdc++' \
	--extra-libs='-lws2_32' \
	--extra-libs='-loleaut32' \
	--extra-libs='-lpsapi' \
	--extra-libs='-lpthread' \
	--extra-libs='-lz' \
	--extra-libs='-lpng' \
	--extra-libs='-lxml2' \
	--pkg-config=pkg-config \
	--enable-runtime-cpudetect \
	--enable-static \
	--disable-shared \
	--disable-debug \
	--disable-doc \
	--disable-w32threads \
	--enable-gpl \
	--enable-version3 \
	--enable-nonfree \
	--enable-zlib \
	--enable-bzlib \
	--enable-openssl \
	--enable-avisynth \
	--enable-avresample \
	--enable-dxva2 \
	--enable-fontconfig \
	--enable-gray \
	--enable-libass \
	--enable-libbluray \
	--enable-libfdk-aac \
	--enable-libfreetype \
	--enable-libmp3lame \
	--enable-libtheora \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libwavpack \
	--enable-libwebp \
	--enable-libx264 \
	--enable-libx265 \
	--enable-libxvid
doMake install

################################################################################

infoMsg 'Moving to target folder...'
rm -rf "$installDir"
mkdir -p "$installDir"
cp -v "$prefix"/bin/{ffmpeg,ffplay,ffprobe,ffserver}.exe "$installDir" 2>/dev/null || true

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

