#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Agent development environment, https://orca.dev/
# The .deb name carries the version and no apt repository backs it, so apt
# never updates it. Run this step again to install the latest release.
DEB_URL="$(curl -fsSL https://api.github.com/repos/stablyai/orca/releases/latest |
  jq -r '.assets[].browser_download_url | select(endswith("_amd64.deb"))')"
deb_install orca "$DEB_URL"
