#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Dependencies:
#  curl
#  wget
#  asar (npm)
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
CONFIG_DIR="$HOME/.opt/config/mist"
INSTALL_DIR="$HOME/.opt/software/mist"
TMP_DIR="/tmp/mist-build"
ICON_URL="https://raw.githubusercontent.com/ethereum/mist/master/icons/wallet/icon2x.png"
PACKAGE_URL=$(
	curl -s "https://api.github.com/repos/ethereum/mist/releases?$GITHUB_OAUTH_PARAMS" | \
	grep -oP '(?<="browser_download_url": ").+-linux64-.+(?=",?$)' | \
	head -1
)

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO "mist.zip"
wget "$ICON_URL" --show-progress -qO "mist.png"
unzip -q "mist.zip"

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$CONFIG_DIR"/{appData,cache,home,userData} "$INSTALL_DIR"

asar extract Ethereum-Wallet-*/resources/app.asar app_tmp
asar extract Ethereum-Wallet-*/resources/atom.asar atom_tmp

ESCAPED_CONFIG_DIR=$(echo "$CONFIG_DIR" | sed -e 's/\\/\\\\/g;s/\//\\\//g;s/&/\\&/g')
find "$TMP_DIR"/{app_tmp,atom_tmp} -name "*.js" -type f -print0 | \
	xargs -0 sed -ri "s/app\.getPath\('(appData|cache|home|userData)'\)/'$ESCAPED_CONFIG_DIR\/\1'/g"

#
# TODO
# /* app.asar/modules/ethereumNodes.js: */
#
# if (type === 'geth') {
# 	args.push('--datadir', '"$CONFIG_DIR/home/.ethereum"', '--ipcpath', '"$CONFIG_DIR/home/.ethereum/geth.ipc"');
# }
#

asar pack app_tmp Ethereum-Wallet-*/resources/app.asar >/dev/null
asar pack atom_tmp Ethereum-Wallet-*/resources/atom.asar >/dev/null

mv {mist.png,Ethereum-Wallet-*/*} "$INSTALL_DIR"

cat > "$INSTALL_DIR"/mist-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./Ethereum-Wallet \\
	--ignore-gpu-blacklist \\
	"\$@"
EOF

rm -f "$BIN_DIR"/mist
ln -s "$INSTALL_DIR"/mist-wrapper.sh "$BIN_DIR"/mist
chmod 755 "$BIN_DIR"/mist

printmsg "Creating launcher..."
cat > "$HOME/.local/share/applications/opt.mist.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Mist Browser
StartupNotify=false
Terminal=true
Exec=$BIN_DIR/mist %u
Icon=$INSTALL_DIR/mist.png
EOF

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

