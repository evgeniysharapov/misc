#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  autoconf
#  automake
#  build-essential
#  dos2unix
#  gettext
#  intltool
#  libagg-dev
#  libasound2-dev
#  libglade2-dev
#  libglib2.0-dev
#  libglu1-mesa-dev
#  libgtk2.0-dev
#  libgtkglext1-dev
#  liblua5.1-0-dev
#  libosmesa6-dev
#  libsdl1.2-dev
#  subversion
#  zlib1g-dev
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/software/desmume"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp /tmp/desmume.XXXXXXXX)
svnUrl='svn://svn.code.sf.net/p/desmume/code/trunk'
# 0.9.11 -> r5146
svnRev='latest'

# Process
source "$scriptDir"/../common

infoMsg 'Preparing workspace...'
rm -rf "$tmpDir"
mkdir "$tmpDir"
cd "$tmpDir"

infoMsg 'Downloading package...'
if [ "$svnRev" == "latest" ]; then
	svn checkout "$svnUrl" .
else
	svn checkout "$svnUrl" -r "$svnRev" .
fi

infoMsg 'Building...'
cd ./desmume

# Change default language to spanish
dos2unix ./src/firmware.cpp
patch ./src/firmware.cpp <<'EOF'
--- firmware.cpp
+++ firmware.cpp
@@ -932 +932 @@
-	fw_config->language = 1;
+	fw_config->language = 5;
EOF

./autogen.sh
CFLAGS='-O2 -march=native -mfpmath=sse -std=gnu++14' CXXFLAGS="$CFLAGS" \
./configure \
	--prefix="$installDir" \
	--enable-glx \
	--enable-hud \
	--enable-openal \
	--enable-wifi \
	--enable-debug
make -j $(nproc)

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir"/.local/share "$installDir"

make install

cat > "$installDir"/desmume-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
cd "$installDir"

./bin/desmume \\
	--jit-enable \\
	--jit-size 10 \\
	--preload-rom \\
	"\$@"
EOF

if [ ! -f "$homeDir"/.config/desmume/config.cfg ]; then
	mkdir -p "$homeDir"/.config/desmume
	cat > "$homeDir"/.config/desmume/config.cfg <<-EOF
	[View]
	ScreenLayout=1
	ShowToolbar=false
	ShowStatusbar=false
	Filter=18
	SecondaryFilter=3
	EOF
fi

ln -fs "$installDir"/desmume-wrapper.sh "$binDir"/desmume
chmod 755 "$binDir"/desmume

infoMsg 'Creating launcher...'
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.desmume.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DeSmuME
Categories=Game;Emulator;
Keywords=nintendo;ds;emulator
StartupNotify=true
Terminal=false
Exec=$binDir/desmume %f
#Icon=DeSmuME
Icon=$installDir/share/pixmaps/DeSmuME.xpm
MimeType=application/x-nintendo-ds-rom;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

