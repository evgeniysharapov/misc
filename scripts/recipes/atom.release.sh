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
confDir="$HOME/.opt/config/atom"
installDir="$HOME/.opt/software/atom"
tmpDir='/tmp/atom-build'
pkgUrl='https://atom.io/download/deb'

# Process
source "$scriptDir"/../common

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir -p "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO 'atom.deb'

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$confDir"/{atom,github} "$installDir"

ar p 'atom.deb' 'data.tar.gz' | tar -xzC "$installDir"

cat > "$installDir"/atom-wrapper.sh <<EOF
#!/usr/bin/env bash

export ATOM_DEV_RESOURCE_PATH="$confDir/github"
export ATOM_HOME="$confDir/atom"

cd "$installDir"

./usr/bin/atom \\
	--safe \\
	"\$@"
EOF
cat > "$installDir"/apm-wrapper.sh <<EOF
#!/usr/bin/env bash

export ATOM_DEV_RESOURCE_PATH="$confDir/github"
export ATOM_HOME="$confDir/atom"

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
StartupNotify=false
Terminal=false
Exec=$binDir/atom %U
Icon=$installDir/usr/share/pixmaps/atom.png
MimeType=text/plain;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

