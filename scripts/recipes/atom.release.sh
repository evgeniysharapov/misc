#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Downloads:
#  stable: https://atom.io/download/deb
#  beta:   https://atom.io/download/deb?channel=beta
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/software/atom"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp /tmp/atom.XXXXXXXX)
pkgUrl='https://atom.io/download/deb'

# Load helpers
if [ -f "$scriptDir"/_helpers.sh ]; then
	source "$scriptDir"/_helpers.sh
else
	source <(curl -sL 'https://raw.githubusercontent.com/zant95/misc/master/scripts/recipes/_helpers.sh')
fi

# Process
infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir -p "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO 'atom.deb'

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir"

ar p 'atom.deb' 'data.tar.gz' | tar -xzC "$installDir"

cat > "$installDir"/atom-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
cd "$installDir"

./usr/bin/atom \\
	--safe \\
	"\$@"
EOF
cat > "$installDir"/apm-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
cd "$installDir"

./usr/bin/apm "\$@"
EOF

ln -fs "$installDir"/atom-wrapper.sh "$binDir"/atom
ln -fs "$installDir"/apm-wrapper.sh "$binDir"/apm
chmod 755 "$binDir"/{apm,atom}

infoMsg 'Creating launcher...'
mkdir -p "$HOME"/.local/share/applications
cat > "$HOME"/.local/share/applications/opt.atom.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Atom
Categories=Development;IDE;TextEditor;Utility;
Keywords=atom;code;
StartupNotify=true
Terminal=false
Exec=$binDir/atom %U
Icon=$installDir/usr/share/pixmaps/atom.png
MimeType=text/plain;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

