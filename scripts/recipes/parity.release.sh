#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/parity"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp -d /tmp/parity.XXXXXXXX)
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/ethcore/parity/releases/latest' | \
	egrep -o '/ethcore/parity/releases/download/[^>]+/parity_.+\_amd64\.deb' | \
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
wget "$pkgUrl" --show-progress -qO 'parity.deb'

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir"

ar p 'parity.deb' 'data.tar.xz' | tar -xJC "$installDir"

cat > "$installDir"/parity-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"

"$installDir"/usr/bin/parity "\$@"
EOF

ln -fs "$installDir"/parity-wrapper.sh "$binDir"/parity
chmod 755 "$binDir"/parity

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

