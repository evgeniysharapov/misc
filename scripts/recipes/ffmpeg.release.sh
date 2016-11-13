#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  pkg-config
#  flite1-dev
#  frei0r-plugins-dev
#  i965-va-driver
#  ladspa-sdk
#  libasound2-dev
#  libass-dev
#  libavc1394-dev
#  libavcodec-dev
#  libbluray-dev
#  libbs2b-dev
#  libbz2-dev
#  libc6-dev
#  libcaca-dev
#  libcdio-paranoia-dev
#  libchromaprint-dev
#  libcrystalhd-dev
#  libdc1394-22-dev
#  libebur128-dev
#  libfdk-aac-dev
#  libfontconfig1-dev
#  libfreetype6-dev
#  libfribidi-dev
#  libgl1-mesa-dev
#  libgme-dev
#  libgsm1-dev
#  libiec61883-dev
#  libjack-jackd2-dev
#  libleptonica-dev
#  liblzma-dev
#  libmodplug-dev
#  libmp3lame-dev
#  libnetcdf-dev
#  libomxil-bellagio-dev
#  libopenal-dev
#  libopencore-amrnb-dev
#  libopencore-amrwb-dev
#  libopencv-dev
#  libopenjpeg-dev
#  libopus-dev
#  libpulse-dev
#  librtmp-dev
#  librubberband-dev
#  libschroedinger-dev
#  libsctp-dev
#  libsdl2-dev
#  libshine-dev
#  libsmbclient-dev
#  libsnappy-dev
#  libsoxr-dev
#  libspeex-dev
#  libssh-dev
#  libtesseract-dev
#  libtheora-dev
#  libtwolame-dev
#  libv4l-dev
#  libva-dev
#  libvdpau-dev
#  libvdpau-va-gl1
#  libvo-aacenc-dev
#  libvo-amrwbenc-dev
#  libvorbis-dev
#  libvpx-dev
#  libwavpack-dev
#  libwebp-dev
#  libx11-dev
#  libx264-dev
#  libx265-dev
#  libxext-dev
#  libxvidcore-dev
#  libxvmc-dev
#  libzmq3-dev
#  libzvbi-dev
#  ocl-icd-opencl-dev
#  yasm
#  zlib1g-dev
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/ffmpeg"
installDir="$baseDir/install"
tmpDir=$(mktemp -d /tmp/ffmpeg.XXXXXXXX)
pkgUrl='https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2'

# Load helpers
if [ -f "$scriptDir"/_helpers.sh ]; then
	source "$scriptDir"/_helpers.sh
else
	source <(curl -sL 'https://raw.githubusercontent.com/zant95/misc/master/scripts/recipes/_helpers.sh')
fi

# Process
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO - | tar -xj --strip-components=1

infoMsg 'Compiling...'
./configure \
	--prefix="$installDir" \
	--arch=$(uname -m) \
	--cpu=host \
	--toolchain=hardened \
	--enable-hardcoded-tables \
	--enable-pthreads \
	--disable-debug \
	--disable-doc \
	--disable-shared \
	--enable-static \
	--enable-gpl \
	--enable-version3 \
	--enable-nonfree \
	--enable-avisynth \
	--enable-avresample \
	--enable-chromaprint \
	--enable-frei0r \
	--enable-ladspa \
	--enable-ladspa \
	--enable-libass \
	--enable-libbluray \
	--enable-libbs2b \
	--enable-libcaca \
	--enable-libcdio \
	--enable-libdc1394 \
	--enable-libebur128 \
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
	--enable-librubberband \
	--enable-libschroedinger \
	--enable-libshine \
	--enable-libsmbclient \
	--enable-libsnappy \
	--enable-libsoxr \
	--enable-libspeex \
	--enable-libssh \
	--enable-libtesseract \
	--enable-libtheora \
	--enable-libtwolame \
	--enable-libv4l2 \
	--enable-libvo-amrwbenc \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libwavpack \
	--enable-libwebp \
	--enable-libx264 \
	--enable-libx265 \
	--enable-libxcb \
	--enable-libxcb-shape \
	--enable-libxcb-shm \
	--enable-libxcb-xfixes \
	--enable-libxvid \
	--enable-libzmq \
	--enable-libzvbi \
	--enable-netcdf \
	--enable-omx \
	--enable-omx-rpi \
	--enable-openal \
	--enable-opencl \
	--enable-opengl \
	--enable-openssl \
	--enable-x11grab

# TODO
#	--enable-libilbc
#	--enable-libkvazaar
#	--enable-libmfx
#	--enable-libvidstab
#	--enable-libxavs
#	--enable-libzimg

make -j $(nproc)

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir"

make install

cat > "$installDir"/ffmpeg-wrapper.sh <<EOF
#!/usr/bin/env bash

export LD_LIBRARY_PATH="$installDir/lib"

"$installDir"/bin/ffmpeg \\
	-hide_banner \\
	"\$@"
EOF

cat > "$installDir"/ffplay-wrapper.sh <<EOF
#!/usr/bin/env bash

export LD_LIBRARY_PATH="$installDir/lib"

"$installDir"/bin/ffplay \\
	-hide_banner \\
	"\$@"
EOF

cat > "$installDir"/ffprobe-wrapper.sh <<EOF
#!/usr/bin/env bash

export LD_LIBRARY_PATH="$installDir/lib"

"$installDir"/bin/ffprobe \\
	-hide_banner \\
	"\$@"
EOF

cat > "$installDir"/ffserver-wrapper.sh <<EOF
#!/usr/bin/env bash

export LD_LIBRARY_PATH="$installDir/lib"

"$installDir"/bin/ffserver \\
	-hide_banner \\
	"\$@"
EOF

ln -fs "$installDir"/ffmpeg-wrapper.sh "$binDir"/ffmpeg
ln -fs "$installDir"/ffplay-wrapper.sh "$binDir"/ffplay
ln -fs "$installDir"/ffprobe-wrapper.sh "$binDir"/ffprobe
ln -fs "$installDir"/ffserver-wrapper.sh "$binDir"/ffserver
chmod 755 "$binDir"/{ffmpeg,ffplay,ffprobe,ffserver}

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

