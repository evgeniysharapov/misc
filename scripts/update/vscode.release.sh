#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Downloads:
#  osx:     http://go.microsoft.com/fwlink/?LinkID=620882
#  win:     http://go.microsoft.com/fwlink/?LinkID=623230
#  linux64: http://go.microsoft.com/fwlink/?LinkID=620884
#  linux32: http://go.microsoft.com/fwlink/?LinkID=620885
#  winzip:  http://go.microsoft.com/fwlink/?LinkID=623231
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
CONFIG_DIR="$HOME/.opt/config/vscode"
INSTALL_DIR="$HOME/.opt/software/vscode"
TMP_DIR="/tmp/vscode-build"
PACKAGE_URL="http://go.microsoft.com/fwlink/?LinkID=620884"

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO "vscode.zip"
unzip -q "vscode.zip"

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$INSTALL_DIR"

sed -i '/sourceMappingURL/d' VSCode-*/resources/app/out/main.js
cat >> VSCode-*/resources/app/out/main.js <<EOF
;
app.setPath('appData',		'$CONFIG_DIR/appData');
app.setPath('cache',		'$CONFIG_DIR/cache');
app.setPath('home',			'$CONFIG_DIR/home');
app.setPath('userCache',	'$CONFIG_DIR/userCache');
app.setPath('userData',		'$CONFIG_DIR/userData');
EOF

mv VSCode-*/* "$INSTALL_DIR"

cat > "$INSTALL_DIR"/vscode-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./code "\$@"
EOF

rm -f "$BIN_DIR"/vscode
ln -s "$INSTALL_DIR"/vscode-wrapper.sh "$BIN_DIR"/vscode
chmod 755 "$BIN_DIR"/vscode

printmsg "Creating launcher..."
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.vscode.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Visual Studio Code
Categories=Development;IDE;TextEditor;Utility;
Keywords=code;vscode;
StartupNotify=false
Terminal=false
Exec=$BIN_DIR/vscode
Icon=$INSTALL_DIR/resources/app/resources/linux/code.png
MimeType=text/plain;
EOF

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

