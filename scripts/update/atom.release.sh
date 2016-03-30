#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Downloads:
#  stable: https://atom.io/download/deb
#  beta:   https://atom.io/download/deb?channel=beta
#
# Dependencies:
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
CONFIG_DIR="$HOME/.opt/config/atom"
INSTALL_DIR="$HOME/.opt/software/atom"
TMP_DIR="/tmp/atom-build"
PACKAGE_URL="https://atom.io/download/deb"

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO "atom.deb"

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$CONFIG_DIR"/{atom,github} "$INSTALL_DIR"

ar p "atom.deb" "data.tar.gz" | tar -xzC "$INSTALL_DIR"

cat > "$INSTALL_DIR"/atom-wrapper.sh <<EOF
#!/usr/bin/env bash

export ATOM_DEV_RESOURCE_PATH="$CONFIG_DIR/github"
export ATOM_HOME="$CONFIG_DIR/atom"

cd "$INSTALL_DIR"

./usr/bin/atom \\
	--safe \\
	"\$@"
EOF
cat > "$INSTALL_DIR"/apm-wrapper.sh <<EOF
#!/usr/bin/env bash

export ATOM_DEV_RESOURCE_PATH="$CONFIG_DIR/github"
export ATOM_HOME="$CONFIG_DIR/atom"

cd "$INSTALL_DIR"

./usr/bin/apm \\
	"\$@"
EOF

rm -f "$BIN_DIR"/{apm,atom}
ln -s "$INSTALL_DIR"/atom-wrapper.sh "$BIN_DIR"/atom
ln -s "$INSTALL_DIR"/apm-wrapper.sh "$BIN_DIR"/apm
chmod 755 "$BIN_DIR"/{apm,atom}

printmsg "Creating launcher..."
mkdir -p "$HOME"/.local/share/applications
cat > "$HOME"/.local/share/applications/opt.atom.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Atom
Categories=Development;IDE;TextEditor;Utility;
Keywords=atom;code;
StartupNotify=false
Terminal=false
Exec=$BIN_DIR/atom %U
Icon=$INSTALL_DIR/usr/share/pixmaps/atom.png
MimeType=text/plain;
EOF

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

