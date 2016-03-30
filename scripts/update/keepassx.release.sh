#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  cmake
#  curl
#  libgcrypt20-dev
#  libqt5x11extras5-dev
#  libxtst-dev
#  pkg-config
#  qt4-default
#  qtbase5-dev
#  qttools5-dev
#  wget
#  zlib1g-dev
#

# Exit on errors
set -eu -o pipefail

# Print message methods
printmsg() {
	echo -e "\e[1;33m + \e[1;32m$1 \e[0m"
}

# Github API OAuth
source "$(dirname $(realpath $0))"/github.oauth.sh

# Globals
BIN_DIR="$HOME/.opt/bin"
CONFIG_DIR="$HOME/.opt/config/keepassx"
INSTALL_DIR="$HOME/.opt/software/keepassx"
TMP_DIR="/tmp/keepassx-build"
PACKAGE_URL=$(
	curl -s "https://api.github.com/repos/keepassx/keepassx/tags?$GITHUB_OAUTH_PARAMS" | \
	grep -oP '(?<="tarball_url": ").+(?=",?$)' | \
	head -1
)"?$GITHUB_OAUTH_PARAMS"

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO - | tar -xz --strip-components=1

printmsg "Building..."
mkdir build
cd build
cmake ..
make -j $(nproc)
make test

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$INSTALL_DIR"

DESTDIR="$INSTALL_DIR" make install

cat > "$INSTALL_DIR"/keepassx-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./usr/local/bin/keepassx \\
	--config "$CONFIG_DIR"/keepassx.ini \\
	"\$@"
EOF

rm -f "$BIN_DIR"/keepassx
ln -s "$INSTALL_DIR"/keepassx-wrapper.sh "$BIN_DIR"/keepassx
chmod 755 "$BIN_DIR"/keepassx

printmsg "Creating launcher..."
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.keepassx.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=KeePassX
Categories=Utility;
Keywords=password;
StartupNotify=false
Terminal=false
Exec=$BIN_DIR/keepassx %f
#Icon=$INSTALL_DIR/usr/local/share/icons/hicolor/scalable/apps/keepassx.svgz
Icon=keepassx
MimeType=application/x-keepass2;
EOF

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

