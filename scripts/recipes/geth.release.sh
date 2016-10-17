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
baseDir="$HOME/.opt/software/geth"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp /tmp/geth.XXXXXXXX)
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/ethereum/go-ethereum/releases/latest' | \
	egrep -o '/ethereum/go-ethereum/archive/[^>]+\.tar\.gz' | \
	head -1
)

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

infoMsg 'Building...'
make -j $(nproc) geth
./build/bin/geth version

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir"

mv "$tmpDir"/build/bin/* "$installDir"

cat > "$installDir"/geth-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
cd "$installDir"

./geth \\
	--support-dao-fork \\
	"\$@"
EOF

ln -fs "$installDir"/geth-wrapper.sh "$binDir"/geth
chmod 755 "$binDir"/geth

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

