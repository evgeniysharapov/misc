#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
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
INSTALL_DIR="$HOME/.opt/software/firefox"
TMP_DIR="/tmp/firefox-build"
PACKAGE_URL="https://download.mozilla.org/?lang=en-US&os=linux64&product=firefox-latest"

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO "firefox.tar.bz2"

printmsg "Installing..."
rm -rf "$INSTALL_DIR"
mkdir -p "$BIN_DIR" "$INSTALL_DIR"

tar -jxf "firefox.tar.bz2" --strip-components=1 -C "$INSTALL_DIR"

cat > "$INSTALL_DIR"/firefox-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$INSTALL_DIR"

./firefox "\$@"
EOF

rm -f "$BIN_DIR"/firefox
ln -s "$INSTALL_DIR"/firefox-wrapper.sh "$BIN_DIR"/firefox
chmod 755 "$BIN_DIR"/firefox

printmsg "Creating launcher..."
mkdir -p "$HOME"/.local/share/applications
cat > "$HOME"/.local/share/applications/opt.firefox.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Mozilla Firefox
GenericName=Web Browser
Categories=Network;WebBrowser;
Keywords=Internet;WWW;Browser;Web;Explorer;
Terminal=false
X-MultipleArgs=false
StartupNotify=true
StartupWMClass=firefox
Exec=$BIN_DIR/firefox %u
#Icon=$INSTALL_DIR/browser/icons/mozicon128.png
Icon=firefox
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
Actions=NewWindow;NewPrivateWindow;

[Desktop Action NewWindow]
Name=Open a New Window
OnlyShowIn=Unity;
Exec=$BIN_DIR/firefox -new-window

[Desktop Action NewPrivateWindow]
Name=Open a New Private Window
OnlyShowIn=Unity;
Exec=$BIN_DIR/firefox -private-window
EOF

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

