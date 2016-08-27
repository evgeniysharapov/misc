#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
installDir='/usr/share/icons/Paper'
tmpDir='/tmp/paper-icons-build'
pkgUrl='https://github.com/snwh/paper-icon-theme/archive/master.tar.gz'

# Process
source "$scriptDir"/../common

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
sudo gtk-update-icon-cache -f "$installDir"

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

