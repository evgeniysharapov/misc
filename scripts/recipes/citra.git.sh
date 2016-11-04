#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  build-essential
#  cmake
#  git
#  libboost-dev
#  libpthread-stubs0-dev
#  libqt5opengl5-dev
#  libsdl2-dev
#  libxkbcommon-x11-dev
#  qtbase5-dev
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/software/citra"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp -d /tmp/citra.XXXXXXXX)
#gitUrl='https://github.com/citra-emu/citra'
gitUrl='https://github.com/citra-emu/citra-bleeding-edge'

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

infoMsg 'Cloning remote repository...'
git clone --recursive "$gitUrl" .

infoMsg 'Building...'
mkdir build && cd build
cmake .. \
	-DCMAKE_CXX_FLAGS="-O2 -std=gnu++14 -march=native" \
	-DCMAKE_BUILD_TYPE=Release
make -j $(nproc)

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir"

mv -t "$installDir" \
	"$tmpDir"/build/src/{citra/citra,citra_qt/citra-qt} \
	"$tmpDir"/dist/citra.svg

if [ ! -f "$homeDir"/.config/citra-emu/qt-config.ini ]; then
	mkdir -p "$homeDir"/.config/citra-emu
	cat > "$homeDir"/.config/citra-emu/qt-config.ini <<-EOF
	[System]
	region_value=2
	EOF
fi

cat > "$installDir"/citra-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"

"$installDir"/citra-qt "\$@"
EOF

ln -fs "$installDir"/citra-wrapper.sh "$binDir"/citra
chmod 755 "$binDir"/citra

infoMsg 'Creating launcher...'
cat > "$HOME/.local/share/applications/opt.citra.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Citra
Categories=Game;Emulator;
Keywords=nintendo;3ds;emulator;
StartupNotify=true
Terminal=true
Exec=$binDir/citra %f
#Icon=citra
Icon=$installDir/citra.svg
MimeType=application/x-ctr-3dsx;application/x-ctr-cci;application/x-ctr-cia;application/x-ctr-cxi;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

