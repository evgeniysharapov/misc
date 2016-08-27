#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
installDir='/usr/share/fonts/opentype/FiraCode'
tmpDir='/tmp/firacode-font-build'
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/tonsky/FiraCode/releases/latest' | \
	egrep -o '/tonsky/FiraCode/releases/download/[^>]+/FiraCode_.+\.zip' | \
	head -1
)

# Process
source "$scriptDir"/../common

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO FiraCode.zip
unzip FiraCode.zip

infoMsg 'Installing...'
sudo rm -rf "$installDir"
sudo mkdir -p "$installDir"

sudo mv -v "$tmpDir"/otf/*.otf "$installDir"

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"
