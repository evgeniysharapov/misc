#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  curl
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
BIN_DIR="$HOME/.opt/bin"
INSTALL_DIR="$HOME/.opt/software/ffmpeg"
TMP_DIR="/tmp/ffmpeg-build"
PACKAGE_URL="http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2"
TIMESTAMP=$(curl -sI "$PACKAGE_URL" | grep "Last-Modified:")

# Process
if grep "$TIMESTAMP" "$INSTALL_DIR/TIMESTAMP" >/dev/null 2>&1; then
	printmsg "Up to date."
	exit 0
fi

printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO - | tar -xj --strip-components=1

printmsg "Compiling..."
./configure \
	--prefix="$INSTALL_DIR" \
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

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

make install

cat > "$INSTALL_DIR"/ffmpeg-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./bin/ffmpeg "\$@"
EOF
cat > "$INSTALL_DIR"/ffprobe-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./bin/ffprobe "\$@"
EOF
cat > "$INSTALL_DIR"/ffserver-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./bin/ffserver "\$@"
EOF

rm -f "$BIN_DIR"/{ffmpeg,ffprobe,ffserver}
ln -s "$INSTALL_DIR"/ffmpeg-wrapper.sh "$BIN_DIR"/ffmpeg
ln -s "$INSTALL_DIR"/ffprobe-wrapper.sh "$BIN_DIR"/ffprobe
ln -s "$INSTALL_DIR"/ffserver-wrapper.sh "$BIN_DIR"/ffserver
chmod 755 "$BIN_DIR"/{ffmpeg,ffprobe,ffserver}

printmsg "Creating timestamp..."
echo "$TIMESTAMP" > "$INSTALL_DIR"/TIMESTAMP

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

