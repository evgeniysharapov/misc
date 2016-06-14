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
confDir="$HOME/.opt/config/popcorntime"
installDir="$HOME/.opt/software/popcorntime"
tmpDir='/tmp/popcorntime-build'
pkgUrl=$(
	curl -sL 'https://popcorntime.sh/en' | \
	egrep -o 'https://[^>]+-Linux-64\.tar\.xz' | \
	head -1
)

# Process
source "$scriptDir"/../common

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO - | tar -xJ --strip-components=1

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$installDir"

ESCAPED_confDir=$(echo "$confDir" | sed -e 's/\\/\\\\/g;s/\//\\\//g;s/&/\\&/g')
find "$tmpDir"/src -name '*.js' -type f -print0 | \
	xargs -0 sed -i "s/gui\.App\.dataPath/'$ESCAPED_confDir'/g"

mv "$tmpDir"/* "$installDir"

cat > "$installDir"/popcorntime-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$installDir"

./Popcorn-Time \\
	--data-path="$confDir" \\
	"\$@"
EOF

ln -fs "$installDir"/popcorntime-wrapper.sh "$binDir"/popcorntime
chmod 755 "$binDir"/popcorntime

infoMsg 'Creating launcher...'
cat > "$HOME/.local/share/applications/opt.popcorntime.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Popcorn Time
Categories=AudioVideo;Video;Network;Player;P2P;
Keywords=popcorn;tv;show;movie;
StartupNotify=false
Terminal=false
Exec=$binDir/popcorntime %u
Icon=$installDir/src/app/images/icon.png
MimeType=application/x-bittorrent;x-scheme-handler/magnet;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

