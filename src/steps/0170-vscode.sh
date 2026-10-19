#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# The package also adds Microsoft's apt repository, so apt keeps it updated.
deb_install vscode 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
