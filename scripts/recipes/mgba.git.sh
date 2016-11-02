#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  cmake
#  ffmpeg
#  imagemagick
#  libavcodec-dev
#  libavformat-dev
#  libavresample-dev
#  libedit-dev
#  libepoxy-dev
#  libmagickwand-dev
#  libminizip-dev
#  libpng12-dev
#  libsdl2-dev
#  libzip-dev
#  qtbase5-dev
#  qtmultimedia5-dev
#  zlib1g-dev
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/software/mgba"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp -d /tmp/mgba.XXXXXXXX)
pkgUrl='https://github.com/mgba-emu/mgba/archive/master.tar.gz'

# Load helpers
if [ -f "$scriptDir"/_helpers.sh ]; then
	source "$scriptDir"/_helpers.sh
else
	source <(curl -sL 'https://raw.githubusercontent.com/zant95/misc/master/scripts/recipes/_helpers.sh')
fi

# Process
infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO - | tar -xz --strip-components=1

infoMsg 'Building...'
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH="$installDir" ..

make -j $(nproc)

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir"

make install

cat > "$installDir"/mgba-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
cd "$installDir"

./bin/mgba-qt "\$@"
EOF

ln -fs "$installDir"/mgba-wrapper.sh "$binDir"/mgba
chmod 755 "$binDir"/mgba

infoMsg 'Creating launcher...'
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.mgba.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=mGBA
Categories=Game;Emulator;
Keywords=nintendo;gba,gbc;emulator;
StartupNotify=true
Terminal=false
Exec=$binDir/mgba %f
Icon=mgba
#Icon=$installDir/usr/local/share/icons/hicolor/512x512/apps/mgba.png
MimeType=application/x-gameboy-advance-rom;application/x-agb-rom;application/x-gba-rom;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

