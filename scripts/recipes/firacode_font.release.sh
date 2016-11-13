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
tmpDir=$(mktemp -d /tmp/firacode-font.XXXXXXXX)
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/tonsky/FiraCode/releases/latest' | \
	egrep -o '/tonsky/FiraCode/releases/download/[^>]+/FiraCode_.+\.zip' | \
	head -1
)

# Load helpers
if [ -f "$scriptDir"/_helpers.sh ]; then
	source "$scriptDir"/_helpers.sh
else
	source <(curl -sL 'https://raw.githubusercontent.com/zant95/misc/master/scripts/recipes/_helpers.sh')
fi

# Process
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

