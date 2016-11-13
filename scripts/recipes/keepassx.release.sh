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
#  libgcrypt20-dev
#  libqt4-dev
#  libqt5x11extras5-dev
#  libxi-dev
#  libxtst-dev
#  qtbase5-dev
#  qttools5-dev
#  qttools5-dev-tools
#  zlib1g-dev
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/keepassx"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp -d /tmp/keepassx.XXXXXXXX)
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/keepassx/keepassx/releases' | \
	egrep -o '/keepassx/keepassx/archive/[^>]+\.tar\.gz' | \
	head -1
)

# Load helpers
if [ -f "$scriptDir"/_helpers.sh ]; then
	source "$scriptDir"/_helpers.sh
else
	source <(curl -sL 'https://raw.githubusercontent.com/zant95/misc/master/scripts/recipes/_helpers.sh')
fi

# Process
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO - | tar -xz --strip-components=1

infoMsg 'Building...'
mkdir build
cd build
cmake ..
make -j $(nproc)
make test

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir"/.config "$installDir"

DESTDIR="$installDir" make install

cat > "$homeDir"/.config/Trolltech.conf <<EOF
[Qt]
style=GTK+
EOF

cat > "$installDir"/keepassx-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
export LD_LIBRARY_PATH="$installDir/usr/local/lib"

"$installDir"/usr/local/bin/keepassx \\
	--config "$homeDir"/keepassx.ini \\
	"\$@"
EOF

ln -fs "$installDir"/keepassx-wrapper.sh "$binDir"/keepassx
chmod 755 "$binDir"/keepassx

infoMsg 'Creating launcher...'
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.keepassx.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=KeePassX
Categories=Utility;
Keywords=password;
StartupNotify=true
Terminal=false
Exec=$binDir/keepassx %f
Icon=keepassx
#Icon=$installDir/usr/local/share/icons/hicolor/scalable/apps/keepassx.svgz
MimeType=application/x-keepass2;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

