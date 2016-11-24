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
#  frei0r-plugins-dev
#  i965-va-driver
#  libass-dev
#  libavcodec-dev
#  libbluray-dev
#  libcaca-dev
#  libebur128-dev
#  libfdk-aac-dev
#  libfontconfig1-dev
#  libfreetype6-dev
#  libfribidi-dev
#  libgl1-mesa-dev
#  libjack-jackd2-dev
#  liblzma-dev
#  libmp3lame-dev
#  libopenal-dev
#  libopencv-dev
#  libopus-dev
#  libsctp-dev
#  libsdl2-dev
#  libtheora-dev
#  libtwolame-dev
#  libva-dev
#  libvdpau-dev
#  libvdpau-va-gl1
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
	--enable-zlib \
	--enable-bzlib \
	--enable-openssl \
	--enable-avisynth \
	--enable-avresample \
	--enable-fontconfig \
	--enable-frei0r \
	--enable-gray \
	--enable-libass \
	--enable-libbluray \
	--enable-libcaca \
	--enable-libfdk-aac \
	--enable-libfontconfig \
	--enable-libfreetype \
	--enable-libfribidi \
	--enable-libmp3lame \
	--enable-libopencv \
	--enable-libopus \
	--enable-libtheora \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libwavpack \
	--enable-libwebp \
	--enable-libx264 \
	--enable-libx265 \
	--enable-libxvid \
	--enable-openal \
	--enable-opencl \
	--enable-opengl

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

