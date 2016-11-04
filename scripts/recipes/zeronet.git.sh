#!/usr/bin/env bash

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#
# Dependencies:
#  docker
#

# Exit on errors
set -euo pipefail

# Globals
scriptDir=$(dirname "$(readlink -f "$0")")
binDir="$HOME/.opt/bin"
baseDir="$HOME/.opt/software/zeronet"
homeDir="$baseDir/home"
installDir="$baseDir/install"
tmpDir=$(mktemp -d /tmp/zeronet.XXXXXXXX)
pkgUrl='https://github.com/HelloZeroNet/ZeroNet/archive/master.tar.gz'

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

infoMsg 'Building Docker image...'
cat > ./Dockerfile <<EOF
FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive

# Install packages
RUN \\
	apt-get update -y; \\
	apt-get install -y python python-gevent python-msgpack tor; \\
	apt-get clean; \\
	rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

# Create ZeroNet user
RUN addgroup \\
	--gid $(id -g $(whoami)) \\
	zeronet
RUN adduser \\
	--home /home/zeronet \\
	--uid $(id -u $(whoami)) \\
	--ingroup zeronet \\
	--disabled-password \\
	--gecos '' \\
	zeronet
WORKDIR /home/zeronet

# Add ZeroNet source
ADD . /home/zeronet
VOLUME /home/zeronet/data

# Configure tor
RUN \\
	echo "RunAsDaemon 1" >> .torrc; \\
	echo "ControlPort 9051" >> .torrc; \\
	echo "CookieAuthentication 1" >> .torrc

# Set ZeroNet user permissions
RUN chown -R zeronet:zeronet /home/zeronet

# Set upstart command
CMD \\
	tor -f .torrc; \\
	python zeronet.py \\
		--fileserver_ip 0.0.0.0 \\
		--fileserver_port 15441 \\
		--ui_ip 0.0.0.0 \\
		--ui_port 43110 \\
		--tor enable

# Expose ports
EXPOSE 15441
EXPOSE 43110
EOF

docker build --rm --tag zeronet .

infoMsg 'Installing...'
rm -rf "$installDir"
mkdir -p "$binDir" "$homeDir" "$installDir"

cat > "$installDir"/zeronet-wrapper.sh <<EOF
#!/usr/bin/env bash

docker run \\
	--name zeronet \\
	--publish 127.0.0.1:15441:15441 \\
	--publish 127.0.0.1:43110:43110 \\
	--volume "$homeDir":/home/zeronet/data \\
	--user zeronet \\
	--interactive \\
	--tty \\
	--rm \\
	zeronet
EOF

ln -fs "$installDir"/zeronet-wrapper.sh "$binDir"/zeronet
chmod 755 "$binDir"/zeronet

infoMsg 'Creating launcher...'
cat > "$HOME/.local/share/applications/opt.zeronet.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=ZeroNet
Categories=Internet;WWW;Web;
Keywords=internet;
StartupNotify=true
Terminal=true
Exec=$binDir/zeronet
Icon=terminal
EOF

infoMsg 'Removing temp files...'
rm -rf "$tmpDir"

