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
INSTALL_DIR="/usr/share/themes/Paper"
TMP_DIR="/tmp/paper-theme-build"
PACKAGE_URL="https://github.com/snwh/paper-gtk-theme/archive/master.tar.gz"

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO - | tar -xz --strip-components=1

printmsg "Installing..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

sudo mv "$TMP_DIR"/Paper/* "$INSTALL_DIR"

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

