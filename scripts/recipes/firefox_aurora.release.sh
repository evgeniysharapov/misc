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
baseDir="$HOME/.opt/software/firefox-aurora"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp /tmp/firefox-aurora.XXXXXXXX)
pkgUrl='https://download.mozilla.org/?lang=en-US&os=linux64&product=firefox-aurora-latest-ssl'

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
wget "$pkgUrl" --show-progress -qO - | tar -xj --strip-components=1

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir"

mv "$tmpDir"/* "$installDir"

cat > "$installDir"/firefox-aurora-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
cd "$installDir"

./firefox "\$@"
EOF

ln -fs "$installDir"/firefox-aurora-wrapper.sh "$binDir"/firefox-aurora
chmod 755 "$binDir"/firefox-aurora

infoMsg 'Creating launcher...'
mkdir -p "$HOME"/.local/share/applications
cat > "$HOME"/.local/share/applications/opt.firefox-aurora.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Mozilla Firefox Developer
GenericName=Web Browser
Categories=Network;WebBrowser;
Keywords=Internet;WWW;Browser;Web;Explorer;
Terminal=false
X-MultipleArgs=false
StartupNotify=true
StartupWMClass=firefox-aurora
Exec=$binDir/firefox-aurora %u
#Icon=$installDir/browser/icons/mozicon128.png
Icon=firefox-aurora
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
Actions=NewWindow;NewPrivateWindow;

[Desktop Action NewWindow]
Name=Open a New Window
OnlyShowIn=Unity;
Exec=$binDir/firefox-aurora -new-window

[Desktop Action NewPrivateWindow]
Name=Open a New Private Window
OnlyShowIn=Unity;
Exec=$binDir/firefox-aurora -private-window
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

