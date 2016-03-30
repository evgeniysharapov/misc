#!/usr/bin/env bash

# Author:
#  Héctor Molinero Fernández <hector@molinero.xyz>.
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  curl
#  gnome-themes-standard
#  gtk2-engines-murrine
#  libgtk-3-dev
#  pkg-config
#

# Exit on errors
set -eu -o pipefail

# Print message methods
printmsg() {
	echo -e "\e[1;33m + \e[1;32m$1 \e[0m"
}

# Globals
INSTALL_DIR="/usr/share/themes"
TMP_DIR="/tmp/arc-theme-build"
PACKAGE_URL="https://github.com/horst3180/arc-theme/archive/master.tar.gz"

# Process
printmsg "Preparing workspace..."
rm -rf "$TMP_DIR"
mkdir "$TMP_DIR"
cd "$TMP_DIR"

printmsg "Downloading package..."
wget "$PACKAGE_URL" --show-progress -qO - | tar -xz --strip-components=1

printmsg "Building..."
./autogen.sh --prefix=/usr

printmsg "Installing..."
sudo rm -rf "$INSTALL_DIR"/{Arc,Arc-Darker,Arc-Dark}

sudo make install

printmsg "Removing temp files..."
rm -rf "$TMP_DIR"

