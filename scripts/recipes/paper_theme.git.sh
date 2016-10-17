#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
installDir='/usr/share/themes/Paper'
tmpDir=$(mktemp /tmp/paper-gtk-theme.XXXXXXXX)
pkgUrl='https://github.com/snwh/paper-gtk-theme/archive/master.tar.gz'

# Load helpers
if [ -f "$scriptDir"/_helpers.sh ]; then
	source "$scriptDir"/_helpers.sh
else
	source <(curl -sL 'https://raw.githubusercontent.com/zant95/misc/master/scripts/recipes/_helpers.sh')
fi

# Process
infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO - | tar -xz --strip-components=1

infoMsg 'Installing...'
sudo rm -rf "$installDir"
sudo mkdir -p "$installDir"

sudo mv "$tmpDir"/Paper/* "$installDir"

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

