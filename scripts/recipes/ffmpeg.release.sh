#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  flite1-dev
#  frei0r-plugins-dev
#  ladspa-sdk
#  libass-dev
#  libavc1394-dev
#  libbluray-dev
#  libbs2b-dev
#  libcaca-dev
#  libcdio-paranoia-dev
#  libdc1394-22-dev
#  libfdk-aac-dev
#  libfontconfig1-dev
#  libfreetype6-dev
#  libfribidi-dev
#  libgl1-mesa-dev
#  libgme-dev
#  libgsm1-dev
#  libiec61883-dev
#  libmodplug-dev
#  libmp3lame-dev
#  libopenal-dev
#  libopencore-amrnb-dev
#  libopencore-amrwb-dev
#  libopencv-dev
#  libopenjpeg-dev
#  libopus-dev
#  libpulse-dev
#  librtmp-dev
#  libschroedinger-dev
#  libshine-dev
#  libsoxr-dev
#  libspeex-dev
#  libssh-dev
#  libtheora-dev
#  libtwolame-dev
#  libvo-aacenc-dev
#  libvo-amrwbenc-dev
#  libvorbis-dev
#  libvpx-dev
#  libwavpack-dev
#  libwebp-dev
#  libx264-dev
#  libx265-dev
#  libxext-dev
#  libxvidcore-dev
#  libzmq3-dev
#  libzvbi-dev
#  pkg-config
#  yasm
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/software/ffmpeg"
installDir="$baseDir/install"
tmpDir=$(mktemp /tmp/ffmpeg.XXXXXXXX)
pkgUrl='http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2'
timestamp=$(curl -sI "$pkgUrl" | grep 'Last-Modified:')

# Load helpers
if [ -f "$scriptDir"/_helpers.sh ]; then
	source "$scriptDir"/_helpers.sh
else
	source <(curl -sL 'https://raw.githubusercontent.com/zant95/misc/master/scripts/recipes/_helpers.sh')
fi

# Process
if grep "$timestamp" "$installDir"/timestamp >/dev/null 2>&1; then
	infoMsg 'Up to date.'
	exit 0
fi

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir -p "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO - | tar -xj --strip-components=1

infoMsg 'Compiling...'
./configure \
	--prefix="$installDir" \
	--arch=x86_64 \
	--disable-doc \
	--disable-shared \
	--enable-static \
	--enable-gpl \
	--enable-version3 \
	--enable-nonfree \
	--enable-pthreads \
	--enable-avisynth \
	--enable-avresample \
	--enable-frei0r \
	--enable-ladspa \
	--enable-libass \
	--enable-libbluray \
	--enable-libbs2b \
	--enable-libcaca \
	--enable-libcdio \
	--enable-libdc1394 \
	--enable-libfdk-aac \
	--enable-libflite \
	--enable-libfontconfig \
	--enable-libfreetype \
	--enable-libfribidi \
	--enable-libgme \
	--enable-libgsm \
	--enable-libiec61883 \
	--enable-libmodplug \
	--enable-libmp3lame \
	--enable-libopencore-amrnb \
	--enable-libopencore-amrwb \
	--enable-libopencv \
	--enable-libopenjpeg \
	--enable-libopus \
	--enable-libpulse \
	--enable-librtmp \
	--enable-libschroedinger \
	--enable-libshine \
	--enable-libsoxr \
	--enable-libspeex \
	--enable-libssh \
	--enable-libtheora \
	--enable-libtwolame \
	--enable-libvo-amrwbenc \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libwavpack \
	--enable-libwebp \
	--enable-libx264 \
	--enable-libxvid \
	--enable-libzmq \
	--enable-libzvbi \
	--enable-openal \
	--enable-opengl \
	--enable-openssl \
	--enable-x11grab
#	--enable-libx265
make -j $(nproc)

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir"

make install

cat > "$installDir"/ffmpeg-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$installDir"

./bin/ffmpeg "\$@"
EOF
cat > "$installDir"/ffprobe-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$installDir"

./bin/ffprobe "\$@"
EOF
cat > "$installDir"/ffserver-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$installDir"

./bin/ffserver "\$@"
EOF

ln -fs "$installDir"/ffmpeg-wrapper.sh "$binDir"/ffmpeg
ln -fs "$installDir"/ffprobe-wrapper.sh "$binDir"/ffprobe
ln -fs "$installDir"/ffserver-wrapper.sh "$binDir"/ffserver
chmod 755 "$binDir"/{ffmpeg,ffprobe,ffserver}

infoMsg 'Creating timestamp...'
echo "$timestamp" > "$installDir"/timestamp

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

