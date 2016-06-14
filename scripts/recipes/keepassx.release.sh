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
#  libqt5x11extras5-dev
#  libxtst-dev
#  pkg-config
#  qt4-default
#  qtbase5-dev
#  qttools5-dev
#  zlib1g-dev
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
confDir="$HOME/.opt/config/keepassx"
installDir="$HOME/.opt/software/keepassx"
tmpDir='/tmp/keepassx-build'
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/keepassx/keepassx/releases' | \
	egrep -o '/keepassx/keepassx/archive/[^>]+\.tar\.gz' | \
	head -1
)

# Process
source "$scriptDir"/../common

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir "$tmpDir"
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
mkdir -p "$binDir" "$confDir" "$installDir"

DESTDIR="$installDir" make install

cat > "$installDir"/keepassx-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$installDir"

./usr/local/bin/keepassx \\
	--config "$confDir"/keepassx.ini \\
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
StartupNotify=false
Terminal=false
Exec=$binDir/keepassx %f
#Icon=$installDir/usr/local/share/icons/hicolor/scalable/apps/keepassx.svgz
Icon=keepassx
MimeType=application/x-keepass2;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

