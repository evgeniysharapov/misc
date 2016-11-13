#!/bin/sh

# Author:     Héctor Molinero Fernández <hector@molinero.xyz>
# Repository: https://github.com/zant95/misc
# License:    MIT, https://opensource.org/licenses/MIT
#

# Exit on errors
set -eu

logMsg() {
	printf -- '   - %s\n' "$@"
}

infoMsg() {
	printf -- '\033[1;33m + \033[1;32m%s \033[0m\n' "$@"
}

errorMsg() {
	printf -- '\033[1;33m + \033[1;31m%s \033[0m\n' "$@"
}

promptMsg() {
	printf -- '\033[1;33m + \033[1;33m%s \033[0m[y/N]: ' "$@"
	read answer
	case "$answer" in
		[yY]|[yY][eE][sS]) return 0 ;;
		*) return 1 ;;
	esac
}

