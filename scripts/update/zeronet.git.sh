#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Dependencies:
#  msgpack-python
#  python
#  python-gevent
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
CONFIG_DIR="$HOME/.opt/config/zeronet"
INSTALL_DIR="$HOME/.opt/software/zeronet"
TMP_DIR="/tmp/zeronet-build"
PACKAGE_URL="https://github.com/HelloZeroNet/ZeroNet/archive/master.tar.gz"

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO - | tar -xz --strip-components=1

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$CONFIG_DIR"/{data,log} "$INSTALL_DIR"

mv "$TMP_DIR"/* "$INSTALL_DIR"

cat > "$INSTALL_DIR"/torrc <<EOF
# usermod -aG debian-tor $USER
ControlPort 9051
CookieAuthentication 1
EOF

cat > "$INSTALL_DIR"/zeronet-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

if type tor > /dev/null && ! pidof tor > /dev/null; then
	tor -f torrc &
fi

python zeronet.py \\
	--config_file "$CONFIG_DIR"/zeronet.conf \\
	--data_dir "$CONFIG_DIR"/data \\
	--log_dir "$CONFIG_DIR"/log \\
	"\$@"
EOF

rm -f "$BIN_DIR"/zeronet
ln -s "$INSTALL_DIR"/zeronet-wrapper.sh "$BIN_DIR"/zeronet
chmod 755 "$BIN_DIR"/zeronet

printmsg "Creating launcher..."
cat > "$HOME/.local/share/applications/opt.zeronet.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=ZeroNet
StartupNotify=false
Terminal=true
Exec=$BIN_DIR/zeronet
Icon=terminal
EOF

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

