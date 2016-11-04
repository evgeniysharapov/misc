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
#  libpcap-dev
#  libsdl1.2-dev
#  libsoundtouch-dev
#  libzzip-dev
#  lua5.1
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
tmpDir=$(mktemp -d /tmp/desmume.XXXXXXXX)
svnUrl='svn://svn.code.sf.net/p/desmume/code/trunk'
# 0.9.11 -> r5146
svnRev='latest'

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

infoMsg 'Cloning remote repository...'
if [ "$svnRev" == "latest" ]; then
	svn checkout "$svnUrl" -q .
else
	svn checkout "$svnUrl" -qr "$svnRev" .
fi

infoMsg 'Building...'
cd ./desmume

# Change firmware settings
dos2unix ./src/firmware.cpp
patch ./src/firmware.cpp <<'EOF'
--- src/firmware.cpp
+++ src/firmware.cpp
@@ -906 +906 @@
-	const char *default_nickname = "DeSmuME";
+	const char *default_nickname = "Zant";
@@ -907 +907 @@
-	const char *default_message = "DeSmuME makes you happy!";
+	const char *default_message = "Ceci n'est pas un pepe";
@@ -914 +914 @@
-	fw_config->fav_colour = 7;
+	fw_config->fav_colour = 0;
@@ -916 +916 @@
-	fw_config->birth_day = 23;
+	fw_config->birth_day = 9;
@@ -917 +917 @@
-	fw_config->birth_month = 6;
+	fw_config->birth_month = 3;
@@ -932 +932 @@
-	fw_config->language = 1;
+	fw_config->language = 5;
EOF

./autogen.sh
CFLAGS='-std=gnu++14 -O2 -march=native -mfpmath=sse' \
CXXFLAGS="$CFLAGS" LDFLAGS="$CFLAGS" \
./configure \
	--prefix="$installDir" \
	--enable-debug \
	--enable-glade \
	--enable-glx \
	--enable-hud \
	--enable-openal \
	--enable-osmesa \
	--enable-wifi
make -j $(nproc)

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir"/.local/share "$installDir"

make install

if [ ! -f "$homeDir"/.config/desmume/config.cfg ]; then
	mkdir -p "$homeDir"/.config/desmume
	cat > "$homeDir"/.config/desmume/config.cfg <<-EOF
	[View]
	ScreenLayout=1
	ShowToolbar=false
	ShowStatusbar=false
	Filter=4
	SecondaryFilter=3

	[Audio]
	Synchronization=3
	Interpolation=1

	[Config]
	FpsLimiter=true
	AudoFrameskip=true
	Frameskip=2
	EOF
fi

cat > "$installDir"/desmume-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"

"$installDir"/bin/desmume \\
	--jit-enable \\
	--jit-size 15 \\
	--preload-rom \\
	--lang 5 \\
	"\$@"
EOF

ln -fs "$installDir"/desmume-wrapper.sh "$binDir"/desmume
chmod 755 "$binDir"/desmume

infoMsg 'Creating launcher...'
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.desmume.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DeSmuME
Categories=Game;Emulator;
Keywords=nintendo;ds;emulator;
StartupNotify=true
Terminal=true
Exec=$binDir/desmume %f
#Icon=desmume
Icon=$installDir/share/pixmaps/DeSmuME.xpm
MimeType=application/x-nintendo-ds-rom;
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

