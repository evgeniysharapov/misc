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

# Github API OAuth
source "$(dirname $(realpath $0))"/github.oauth.sh

# Globals
BIN_DIR="$HOME/.opt/bin"
CONFIG_DIR="$HOME/.opt/config/dogecoin"
INSTALL_DIR="$HOME/.opt/software/dogecoin"
TMP_DIR="/tmp/dogecoin-build"
PACKAGE_URL=$(
	curl -s "https://api.github.com/repos/dogecoin/dogecoin/releases/latest?$GITHUB_OAUTH_PARAMS" | \
	grep -oP '(?<="browser_download_url": ").+-linux64\.tar\.gz(?=",?$)' | \
	head -1
)

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO - | tar -xz --strip-components=1

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$INSTALL_DIR"

mv "$TMP_DIR"/* "$INSTALL_DIR"

cat > "$INSTALL_DIR"/dogecoind-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./bin/dogecoind \\
	-datadir="$CONFIG_DIR" \\
	"\$@"
EOF
cat > "$INSTALL_DIR"/dogecoin-cli-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./bin/dogecoin-cli \\
	-datadir="$CONFIG_DIR" \\
	"\$@"
EOF
cat > "$INSTALL_DIR"/dogecoin-qt-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./bin/dogecoin-qt \\
	-datadir="$CONFIG_DIR" \\
	"\$@"
EOF

rm -f "$BIN_DIR"/{dogecoind,dogecoin-cli,dogecoin-qt}
ln -s "$INSTALL_DIR"/dogecoind-wrapper.sh "$BIN_DIR"/dogecoind
ln -s "$INSTALL_DIR"/dogecoin-cli-wrapper.sh "$BIN_DIR"/dogecoin-cli
ln -s "$INSTALL_DIR"/dogecoin-qt-wrapper.sh "$BIN_DIR"/dogecoin-qt
chmod 755 "$BIN_DIR"/{dogecoind,dogecoin-cli,dogecoin-qt}

printmsg "Creating launcher..."
cat > "$INSTALL_DIR"/dogecoin.svg <<EOF
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="330" height="330" viewBox="0 0 330 330">
	<g fill="none" fill-rule="evenodd">
		<path d="M330.083 165.228c0 90.92-73.706 164.627-164.627 164.627C74.534 329.855.828 256.15.828 165.228.828 74.306 74.534.6 165.456.6c90.92 0 164.627 73.706 164.627 164.628" fill="#c2aa47"/>
		<path d="M295.13 165.23c0 71.612-58.056 129.673-129.673 129.673-71.616 0-129.677-58.06-129.677-129.674 0-71.62 58.06-129.678 129.677-129.678 71.617 0 129.674 58.058 129.674 129.677" fill="#c2aa47"/>
		<path d="M84.17 75.294h114.68s40.232 7.79 56.512 49.81c0 0 23.315 55.24-11.23 104.258 0 0-21.523 27.023-48.41 27.023H84.168v-42.74h23.274V118.1H84.61l-.44-42.806z" fill="#fff"/>
		<path d="M84.17 75.294h114.68s40.232 7.79 56.512 49.81c0 0 23.315 55.24-11.23 104.258 0 0-21.523 27.023-48.41 27.023H84.168v-42.74h23.274V118.1H84.61l-.44-42.806z" stroke="#c2aa47"/>
		<path d="M158.566 118.22h24.465s11.35 2.413 19.23 24.74c0 0 10.508 32.103-5.952 57.6 0 0-8.724 12.618-18.284 12.618h-19.04l-.418-94.957" fill="#c2aa47"/>
	</g>
</svg>
EOF
cat > "$HOME"/.local/share/applications/opt.dogecoin.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Dogecoin
Categories=Finance;
Keywords=coin;
StartupNotify=false
Terminal=false
Exec=$BIN_DIR/dogecoin-qt %u
Icon=$INSTALL_DIR/dogecoin.svg
MimeType=x-scheme-handler/dogecoin;
EOF

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

