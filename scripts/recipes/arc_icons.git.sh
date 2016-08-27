#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  pkg-config
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
installDir='/usr/share/icons'
tmpDir='/tmp/arc-icon-theme-build'
pkgUrl='https://github.com/horst3180/arc-icon-theme/archive/master.tar.gz'

# Process
source "$scriptDir"/../common

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO - | tar -xz --strip-components=1

infoMsg 'Building...'
./autogen.sh --prefix=/usr

sed -i 's|^\(Inherits=\).*|\1Paper,Moka,elementary,Adwaita,gnome,hicolor|g' \
	./Arc/index.theme

infoMsg 'Installing...'
sudo rm -rf "$installDir"/Arc

sudo make install
sudo gtk-update-icon-cache -f "$installDir"/Arc

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"
