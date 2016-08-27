#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  python
#  python-gevent
#  python-msgpack
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
homeDir="$HOME/.opt/config/zeronet"
installDir="$HOME/.opt/software/zeronet"
tmpDir='/tmp/zeronet-build'
pkgUrl='https://github.com/HelloZeroNet/ZeroNet/archive/master.tar.gz'

# Process
source "$scriptDir"/../common

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO - | tar -xz --strip-components=1

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir"

mv "$tmpDir"/* "$installDir"

cat > "$installDir"/torrc <<EOF
# usermod -aG debian-tor $USER
ControlPort 9051
CookieAuthentication 1
EOF

cat > "$installDir"/zeronet-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
cd "$installDir"

if type tor > /dev/null && ! pidof tor > /dev/null; then
	tor -f torrc &
fi

python zeronet.py \\
	--config_file "$homeDir"/zeronet.conf \\
	--data_dir "$homeDir"/data \\
	--log_dir "$homeDir"/log \\
	"\$@"
EOF

ln -fs "$installDir"/zeronet-wrapper.sh "$binDir"/zeronet
chmod 755 "$binDir"/zeronet

infoMsg 'Creating launcher...'
cat > "$HOME/.local/share/applications/opt.zeronet.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=ZeroNet
StartupNotify=false
Terminal=true
Exec=$binDir/zeronet
Icon=terminal
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

