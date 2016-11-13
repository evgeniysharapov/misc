#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
installDir='/usr/share/fonts/opentype/Hack'
tmpDir=$(mktemp -d /tmp/hack-font.XXXXXXXX)
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/chrissimpkins/Hack/releases/latest' | \
	egrep -o '/chrissimpkins/Hack/releases/download/[^>]+/Hack-.+-otf\.tar\.gz' | \
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
wget "$pkgUrl" --show-progress -qO - | tar -xz --strip-components=1

infoMsg 'Installing...'
sudo rm -rf "$installDir"
sudo mkdir -p "$installDir"

sudo mv -v "$tmpDir"/*.otf "$installDir"

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

