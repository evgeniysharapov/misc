#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  gnome-themes-standard
#  gtk2-engines-murrine
#  libgtk-3-dev
#  pkg-config
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
installDir='/usr/share/themes'
tmpDir=$(mktemp -d /tmp/arc-gtk-theme.XXXXXXXX)
pkgUrl='https://github.com/horst3180/arc-theme/archive/master.tar.gz'

# Load helpers
if [ -f "$scriptDir"/_helpers.sh ]; then
	source "$scriptDir"/_helpers.sh
else
	source <(curl -sL 'https://raw.githubusercontent.com/zant95/misc/master/scripts/recipes/_helpers.sh')
fi

# Process
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO - | tar -xz --strip-components=1

infoMsg 'Building...'
./autogen.sh --prefix=/usr

infoMsg 'Installing...'
sudo rm -rf "$installDir"/{Arc,Arc-Darker,Arc-Dark}

sudo make install

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

