#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Dependencies:
#  curl
#  wget
#

# Exit on errors
set -eu -o pipefail

# Print message methods
printmsg() {
	echo -e "\e[1;33m + \e[1;32m$1 \e[0m"
}

# Globals
BIN_DIR="$HOME/.opt/bin"
CONFIG_DIR="$HOME/.opt/config/popcorntime"
INSTALL_DIR="$HOME/.opt/software/popcorntime"
TMP_DIR="/tmp/popcorntime-build"
PACKAGE_URL="https://get.popcorntime.sh/build/"$(
	curl -sL "https://raw.githubusercontent.com/popcorn-official/popcorn-site/master/metadata.json" | \
	grep -oP '(?<="64bit": ").+-Linux-64\.tar\.xz(?=",?$)' | \
	head -1
)

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO - | tar -xJ --strip-components=1

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$INSTALL_DIR"

ESCAPED_CONFIG_DIR=$(echo "$CONFIG_DIR" | sed -e 's/\\/\\\\/g;s/\//\\\//g;s/&/\\&/g')
find "$TMP_DIR"/src -name "*.js" -type f -print0 | \
	xargs -0 sed -i "s/gui\.App\.dataPath/'$ESCAPED_CONFIG_DIR'/g"

mv "$TMP_DIR"/* "$INSTALL_DIR"

cat > "$INSTALL_DIR"/popcorntime-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./Popcorn-Time \\
	--data-path="$CONFIG_DIR" \\
	"\$@"
EOF

rm -f "$BIN_DIR"/popcorntime
ln -s "$INSTALL_DIR"/popcorntime-wrapper.sh "$BIN_DIR"/popcorntime
chmod 755 "$BIN_DIR"/popcorntime

printmsg "Creating launcher..."
cat > "$HOME/.local/share/applications/opt.popcorntime.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Popcorn Time
Categories=AudioVideo;Video;Network;Player;P2P;
Keywords=popcorn;tv;show;movie;
StartupNotify=false
Terminal=false
Exec=$BIN_DIR/popcorntime %u
Icon=$INSTALL_DIR/src/app/images/icon.png
MimeType=application/x-bittorrent;x-scheme-handler/magnet;
EOF

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

