#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# The package also adds Google's apt repository, so apt keeps it updated.
deb_install chrome 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'
