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
CONFIG_DIR="$HOME/.opt/config/bitcoinclassic"
INSTALL_DIR="$HOME/.opt/software/bitcoinclassic"
TMP_DIR="/tmp/bitcoinclassic-build"
PACKAGE_URL=$(
	curl -s "https://api.github.com/repos/bitcoinclassic/bitcoinclassic/releases/latest?$GITHUB_OAUTH_PARAMS" | \
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

cat > "$INSTALL_DIR"/bitcoind-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./bin/bitcoind \\
	-datadir="$CONFIG_DIR" \\
	"\$@"
EOF
cat > "$INSTALL_DIR"/bitcoin-cli-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./bin/bitcoin-cli \\
	-datadir="$CONFIG_DIR" \\
	"\$@"
EOF
cat > "$INSTALL_DIR"/bitcoin-qt-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./bin/bitcoin-qt \\
	-datadir="$CONFIG_DIR" \\
	"\$@"
EOF

rm -f "$BIN_DIR"/{bitcoind,bitcoin-cli,bitcoin-qt}
ln -s "$INSTALL_DIR"/bitcoind-wrapper.sh "$BIN_DIR"/bitcoind
ln -s "$INSTALL_DIR"/bitcoin-cli-wrapper.sh "$BIN_DIR"/bitcoin-cli
ln -s "$INSTALL_DIR"/bitcoin-qt-wrapper.sh "$BIN_DIR"/bitcoin-qt
chmod 755 "$BIN_DIR"/{bitcoind,bitcoin-cli,bitcoin-qt}

printmsg "Creating launcher..."
cat > "$INSTALL_DIR"/bitcoin.svg <<EOF
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 1 1" preserveAspectRatio="xMidYMid">
	<defs>
		<linearGradient id="a" x1="0%" y1="0%" x2="0%" y2="100%">
			<stop offset="0%" stop-color="#f9aa4b"/>
			<stop offset="100%" stop-color="#f9aa4b"/>
			<!--<stop offset="100%" stop-color="#f7931a"/>-->
		</linearGradient>
	</defs>
	<path d="M63.036 39.74C58.762 56.885 41.4 67.318 24.254 63.043 7.116 58.768-3.316 41.404.96 24.262 5.23 7.117 22.593-3.318 39.733.957 56.878 5.23 67.31 22.597 63.036 39.74z" fill="url(#a)" transform="scale(.01563)"/>
	<path d="M.72.43C.73.36.68.326.61.302l.023-.09L.578.2.556.286a2.296 2.296 0 0 0-.044-.01l.022-.09L.48.175l-.023.09A1.836 1.836 0 0 1 .422.256L.346.236l-.014.06.04.01c.022.005.026.02.025.03L.372.44s.003 0 .005.002H.37L.337.583C.333.59.326.6.31.597L.27.587.244.65l.072.018.04.01-.024.09.056.015.022-.09c.015.004.03.008.044.01L.43.794.485.81l.022-.09C.6.733.67.727.7.642.726.573.7.535.65.51.686.5.713.477.72.43zM.596.604C.578.673.463.635.425.627l.03-.12c.04.008.158.027.14.098zM.612.428C.597.49.502.458.47.45L.498.34c.03.01.13.023.114.088z" fill="#fff"/>
</svg>
EOF
cat > "$HOME"/.local/share/applications/opt.bitcoinclassic.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Bitcoin Classic
Categories=Finance;
Keywords=coin;
StartupNotify=false
Terminal=false
Exec=$BIN_DIR/bitcoin-qt %u
Icon=$INSTALL_DIR/bitcoin.svg
MimeType=x-scheme-handler/bitcoin;
EOF

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

