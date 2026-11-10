#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Secret scanner, https://github.com/gitleaks/gitleaks#installing
# Debian packages a release years behind, and upstream ships no installer
# script, so this installs the latest release into ~/.local/bin after
# checking its SHA-256. Run this step again to update it.
# GitHub redirects releases/latest to the page of the newest tag.
tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/gitleaks/gitleaks/releases/latest)"
version="${tag##*/v}"
tarball="gitleaks_${version}_linux_x64.tar.gz"
base="https://github.com/gitleaks/gitleaks/releases/download/v$version"

curl -#fSL "$base/$tarball" -o "$WORK/$tarball"
curl -fsSL "$base/gitleaks_${version}_checksums.txt" -o "$WORK/checksums.txt"
(cd "$WORK" && grep -F "  $tarball" checksums.txt | sha256sum --check --strict -)

mkdir "$WORK/gitleaks"
tar -xzf "$WORK/$tarball" -C "$WORK/gitleaks" gitleaks
install -m 0755 "$WORK/gitleaks/gitleaks" "$HOME/.local/bin/gitleaks"

rc_block ~/.zshrc <<'EOF2'
source <("$HOME/.local/bin/gitleaks" completion zsh)
EOF2
