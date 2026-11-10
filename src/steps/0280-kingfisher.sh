#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Secret scanner, https://github.com/mongodb/kingfisher/blob/main/docs/INSTALLATION.md
# The .deb has no apt repository behind it, so apt never updates it. Run this
# step again to install the latest release.
deb_install kingfisher https://github.com/mongodb/kingfisher/releases/latest/download/kingfisher-linux-x64.deb
