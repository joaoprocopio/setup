#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Session attach/detach for the terminal, https://zmx.sh/getting-started
# Debian has no package and upstream ships no installer script, so this
# installs the latest release into ~/.local/bin after checking its SHA-256.
# Run this step again to update it.
# GitHub redirects releases/latest to the page of the newest tag.
tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/neurosnap/zmx/releases/latest)"
version="${tag##*/v}"
tarball="zmx-${version}-linux-x86_64.tar.gz"
base="https://github.com/neurosnap/zmx/releases/download/v$version"

curl -#fSL "$base/$tarball" -o "$WORK/$tarball"
# The .sha256 file names the tarball by its path on the build machine, so
# this compares the hash alone.
expected="$(curl -fsSL "$base/$tarball.sha256" | cut -d' ' -f1)"
echo "$expected  $WORK/$tarball" | sha256sum --check --strict -

mkdir "$WORK/zmx"
tar -xzf "$WORK/$tarball" -C "$WORK/zmx" zmx
install -m 0755 "$WORK/zmx/zmx" "$HOME/.local/bin/zmx"

rc_block ~/.zshrc <<'EOF2'
source <("$HOME/.local/bin/zmx" completions zsh)
EOF2
