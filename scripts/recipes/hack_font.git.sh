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
tmpDir='/tmp/hack-font-build'
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/chrissimpkins/Hack/releases/latest' | \
	egrep -o '/chrissimpkins/Hack/releases/download/[^>]+/Hack-.+-otf\.tar\.gz' | \
	head -1
)

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

sudo mv -v "$tmpDir"/*.otf "$installDir"

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

