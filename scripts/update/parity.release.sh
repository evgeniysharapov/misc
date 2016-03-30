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
CONFIG_DIR="$HOME/.opt/config/parity"
INSTALL_DIR="$HOME/.opt/software/parity"
TMP_DIR="/tmp/parity-build"
PACKAGE_URL=$(
	curl -s "https://api.github.com/repos/ethcore/parity/releases/latest?$GITHUB_OAUTH_PARAMS" | \
	grep -oP '(?<="browser_download_url": ").+_amd64\.deb(?=",?$)' | \
	head -1
)

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO "parity.deb"

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$INSTALL_DIR"

ar p "parity.deb" "data.tar.xz" | tar -xJC "$INSTALL_DIR"

cat > "$INSTALL_DIR"/parity-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$CONFIG_DIR"
cd "$INSTALL_DIR"

./usr/bin/parity "\$@"
EOF

rm -f "$BIN_DIR"/parity
ln -s "$INSTALL_DIR"/parity-wrapper.sh "$BIN_DIR"/parity
chmod 755 "$BIN_DIR"/parity

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

