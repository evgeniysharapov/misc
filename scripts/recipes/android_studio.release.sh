#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  bridge-utils
#  libvirt-bin
#  qemu-kvm
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/software/android-studio"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp /tmp/android-studio.XXXXXXXX)
pkgUrl=$(
	curl -sL 'https://developer.android.com/sdk/index.html' | \
	egrep -o 'https://dl\.google\.com/[^>]+/android-studio-ide-.+-linux\.zip' | \
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
wget "$pkgUrl" --show-progress -qO "android-studio.zip"
unzip -q "android-studio.zip"

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir"

cat > android-studio/bin/custom.vmoptions <<EOF
-Duser.home=$homeDir
EOF

mv android-studio/* "$installDir"

cat > "$installDir"/android-studio-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
export STUDIO_VM_OPTIONS="$installDir/bin/custom.vmoptions"
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

