#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Downloads:
#  linux64-stable: http://go.microsoft.com/fwlink/?LinkID=620884
#  linux64-insider: https://go.microsoft.com/fwlink/?LinkId=723968
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
confDir="$HOME/.opt/config/vscode"
installDir="$HOME/.opt/software/vscode"
tmpDir='/tmp/vscode-build'
pkgUrl='http://go.microsoft.com/fwlink/?LinkID=620884'

# Process
source "$scriptDir"/../common

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir -p "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
wget "$pkgUrl" --show-progress -qO vscode.zip
unzip vscode.zip
mv ./VSCode-linux-x64/* ./
rm -rf ./VSCode-linux-x64 vscode.zip

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$confDir" "$installDir"

mv "$tmpDir"/* "$installDir"

cat > "$installDir"/vscode-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$confDir"
export XDG_CONFIG_HOME="$confDir"
cd "$installDir"

./code "\$@"
EOF

ln -fs "$installDir"/vscode-wrapper.sh "$binDir"/vscode
chmod 755 "$binDir"/vscode

infoMsg 'Creating launcher...'
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.vscode.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Visual Studio Code
Categories=Development;IDE;TextEditor;Utility;
Keywords=code;vscode;
StartupNotify=false
Terminal=false
Exec=$binDir/vscode
Icon=$installDir/resources/app/resources/linux/code.png
MimeType=text/plain;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

