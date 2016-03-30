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
INSTALL_DIR="/usr/share/fonts/opentype/Hack"
TMP_DIR="/tmp/hack-font-build"
PACKAGE_URL="https://github.com/chrissimpkins/Hack/blob/master/build/otf/Hack-Regular.otf"

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -q

printmsg "Installing..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

sudo mv -v "$TMP_DIR"/*.otf "$INSTALL_DIR"

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

