#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
installDir="$HOME/.opt/software/android-studio"
tmpDir='/tmp/android-studio-build'
pkgUrl=$(
	curl -sL 'https://developer.android.com/sdk/index.html' | \
	egrep -o 'https://dl\.google\.com/[^>]+/android-studio-ide-.+-linux\.zip' | \
	head -1
)

# Process
source "$scriptDir"/../common

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO "android-studio.zip"
unzip -q "android-studio.zip"

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$installDir"

mv android-studio/* "$installDir"

cat > "$installDir"/android-studio-wrapper.sh <<EOF
#!/usr/bin/env bash

cd "$installDir"

./bin/studio.sh "\$@"
EOF

ln -fs "$installDir"/android-studio-wrapper.sh "$binDir"/android-studio
chmod 755 "$binDir"/android-studio

infoMsg 'Creating launcher...'
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.android-studio.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Android Studio
Categories=Development;IDE;
Keywords=android;studio;ide;
StartupNotify=true
Terminal=false
Exec=$binDir/android-studio %f
#Icon=$installDir/bin/studio.png
Icon=android-sdk
MimeType=application/x-extension-iml;
StartupWMClass=jetbrains-studio
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

