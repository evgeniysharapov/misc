#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  build-essential
#  golang
#  libgmp-dev
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
confDir="$HOME/.opt/config/geth"
tmpDir='/tmp/geth-build'
installDir="$HOME/.opt/software/geth"
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/ethereum/go-ethereum/releases/latest' | \
	egrep -o '/ethereum/go-ethereum/archive/[^>]+\.tar\.gz' | \
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

infoMsg 'Building...'
make geth
#make test
./build/bin/geth version

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$confDir" "$installDir"

mv "$tmpDir"/build/bin/* "$installDir"

cat > "$installDir"/geth-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$installDir"

./geth \\
	--datadir "$confDir" \\
	--ipcpath "$confDir"/geth.ipc \\
	"\$@"
EOF

ln -fs "$installDir"/geth-wrapper.sh "$binDir"/geth
chmod 755 "$binDir"/geth

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

