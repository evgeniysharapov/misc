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
baseDir="$HOME/.opt/software/android"
homeDir="$baseDir/home"
installDir="$baseDir/install/sdk"
tmpDir=$(mktemp -d /tmp/android-sdk.XXXXXXXX)
pkgUrl=$(
	curl -sL 'https://developer.android.com/studio/index.html' | \
	egrep -o 'https://dl\.google\.com/[^>]+/android-sdk_r[^>]+-linux\.tgz' | \
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
mkdir -p "$binDir" "$homeDir" "$installDir"

mv "$tmpDir"/* "$installDir"

cat > "$installDir"/android-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"
export ANDROID_HOME="$installDir"
export PATH=\${PATH}:\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools

patch "$installDir"/tools/android -so "$installDir"/tools/android.patched <<'PATCH'
--- tools/android
+++ tools/android
@@ -110 +110 @@
-exec "\$java_cmd" \\
+exec "\$java_cmd" -Duser.home='$homeDir' \\
PATCH

if ! cmp -s "$installDir"/tools/android "$installDir"/tools/android.patched ; then
	sh "$installDir"/tools/android.patched "\$@"
fi
EOF

ln -fs "$installDir"/android-wrapper.sh "$binDir"/android
chmod 755 "$binDir"/android

cat > "$installDir"/adb-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"

"$installDir"/platform-tools/adb "\$@"
EOF

ln -fs "$installDir"/adb-wrapper.sh "$binDir"/adb
chmod 755 "$binDir"/adb

cat > "$installDir"/fastboot-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"

"$installDir"/platform-tools/fastboot "\$@"
EOF

ln -fs "$installDir"/fastboot-wrapper.sh "$binDir"/fastboot
chmod 755 "$binDir"/fastboot

cat > "$installDir"/apksigner-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"

"$installDir"/build-tools/"\$(ls -v "$installDir"/build-tools | tail -1)"/apksigner "\$@"
EOF

ln -fs "$installDir"/apksigner-wrapper.sh "$binDir"/apksigner
chmod 755 "$binDir"/apksigner

cat > "$installDir"/zipalign-wrapper.sh <<EOF
#!/usr/bin/env bash

export HOME="$homeDir"
export XDG_CONFIG_HOME="$homeDir/.config"
export XDG_CACHE_HOME="$homeDir/.cache"
export XDG_DATA_HOME="$homeDir/.local/share"

"$installDir"/build-tools/"\$(ls -v "$installDir"/build-tools | tail -1)"/zipalign "\$@"
EOF

ln -fs "$installDir"/zipalign-wrapper.sh "$binDir"/zipalign
chmod 755 "$binDir"/zipalign

infoMsg 'Creating launcher...'
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/opt.android-sdk.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Android SDK Manager
Categories=Development;
Keywords=android;sdk;
StartupNotify=true
Terminal=false
Exec=$binDir/android sdk %f
Icon=android-sdk
EOF

cat > "$HOME/.local/share/applications/opt.android-avd.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Android AVD Manager
Categories=Development;
Keywords=android;avd;
StartupNotify=true
Terminal=false
Exec=$binDir/android avd %f
Icon=android-sdk
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

