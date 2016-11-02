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
baseDir="$HOME/.opt/software/webtorrent"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp -d /tmp/webtorrent.XXXXXXXX)
pkgUrl='https://github.com'$(
	curl -sL 'https://github.com/feross/webtorrent-desktop/releases/latest' | \
	egrep -o '/feross/webtorrent-desktop/releases/download/[^>]+/WebTorrent-[^>]+-linux.zip' | \
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
wget "$pkgUrl" --show-progress -qO "webtorrent.zip"
unzip -q "webtorrent.zip"

infoMsg 'Installing...'
rm -rf "$installDir" "$baseDir"
mkdir -p "$binDir" "$homeDir"/Downloads "$installDir"

mv WebTorrent-linux-x64/* "$installDir"

if [ ! -f "$homeDir"/.config/WebTorrent/config.json ]; then
	mkdir -p "$homeDir"/.config/WebTorrent
	cat > "$homeDir"/.config/WebTorrent/config.json <<-EOF
	{
	  "prefs": {
	    "downloadPath": "$homeDir/Downloads"
	  },
	  "torrents": [],
	  "version": "999.999.999"
	}
	EOF
fi

cat > "$installDir"/webtorrent-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
cd "$installDir"

./WebTorrent "\$@"
EOF

ln -fs "$installDir"/webtorrent-wrapper.sh "$binDir"/webtorrent
chmod 755 "$binDir"/webtorrent

infoMsg 'Creating launcher...'
cat > "$HOME/.local/share/applications/opt.webtorrent.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=WebTorrent
Categories=AudioVideo;Video;Network;Player;P2P;
Keywords=torrent;stream;
StartupNotify=true
Terminal=false
Exec=$binDir/webtorrent %u
#Icon=webtorrent
Icon=$installDir/resources/app.asar.unpacked/static/WebTorrent.png
MimeType=application/x-bittorrent;x-scheme-handler/magnet;x-scheme-handler/stream-magnet;

Actions=CreateNewTorrent;OpenTorrentFile;OpenTorrentAddress;

[Desktop Action CreateNewTorrent]
Name=Create New Torrent...
Exec=$binDir/webtorrent -n

[Desktop Action OpenTorrentFile]
Name=Open Torrent File...
Exec=$binDir/webtorrent -o

[Desktop Action OpenTorrentAddress]
Name=Open Torrent Address...
Exec=$binDir/webtorrent -u
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

