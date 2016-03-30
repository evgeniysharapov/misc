#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Dependencies:
#  build-essential
#  curl
#  golang
#  libgmp3-dev
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
CONFIG_DIR="$HOME/.opt/config/geth"
TMP_DIR="/tmp/geth-build"
INSTALL_DIR="$HOME/.opt/software/geth"
PACKAGE_URL=$(
	curl -s "https://api.github.com/repos/ethereum/go-ethereum/releases/latest?$GITHUB_OAUTH_PARAMS" | \
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
make geth
make test
./build/bin/geth version

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$INSTALL_DIR"

mv "$TMP_DIR"/build/bin/* "$INSTALL_DIR"

cat > "$INSTALL_DIR"/geth-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./geth \\
	--datadir "$CONFIG_DIR" \\
	--ipcpath "$CONFIG_DIR"/geth.ipc \\
	"\$@"
EOF

rm -f "$BIN_DIR"/geth
ln -s "$INSTALL_DIR"/geth-wrapper.sh "$BIN_DIR"/geth
chmod 755 "$BIN_DIR"/geth

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

