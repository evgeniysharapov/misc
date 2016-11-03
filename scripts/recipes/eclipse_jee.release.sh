#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/software/eclipse-jee"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp -d /tmp/eclipse-jee.XXXXXXXX)
pkgBaseUrl='https://www.mirrorservice.org/sites/download.eclipse.org/eclipseMirror/technology/epp/downloads/release'
pkgVersion=$(curl -sL "$pkgBaseUrl/release.xml" | sed -nE 's/<present>(.+)<\/present>/\1/g;/^</!p')
pkgUrl="$pkgBaseUrl/$pkgVersion"/$(
	curl -sL "$pkgBaseUrl/$pkgVersion" | \
	egrep -o 'eclipse-jee-[^>]+-linux-gtk-x86_64\.tar\.gz' | \
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

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir" configuration/.settings

cat > configuration/.settings/org.eclipse.ui.ide.prefs <<EOF
RECENT_WORKSPACES=$HOME/Projects/Eclipse
RECENT_WORKSPACES_PROTOCOL=3
SHOW_WORKSPACE_SELECTION_DIALOG=true
eclipse.preferences.version=1
EOF

cat >> eclipse.ini <<EOF
-Duser.home=$homeDir
EOF

mv "$tmpDir"/* "$installDir"

cat > "$installDir"/eclipse-jee-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
cd "$installDir"

./eclipse \\
	--launcher.GTK_version 2 \\
	"\$@"
EOF

ln -fs "$installDir"/eclipse-jee-wrapper.sh "$binDir"/eclipse-jee
chmod 755 "$binDir"/eclipse-jee

infoMsg 'Creating launcher...'
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.eclipse-jee.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Eclipse
Categories=Development;IDE;Java;
Keywords=eclipse;ide;
StartupNotify=true
Terminal=false
Exec=$binDir/eclipse-jee %f
StartupWMClass=Eclipse
Icon=eclipse
#Icon=$installDir/eclipse.xpm
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

