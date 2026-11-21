#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# The dist server deletes old releases, so the update feed names the current one, https://tb-manual.torproject.org/installation/
cd "$WORK" || exit
curl -fsSL https://aus1.torproject.org/torbrowser/update_3/release/download-linux-x86_64.json -o release.json
curl -#fSL "$(jq -r .binary release.json)" -o tor-browser.tar.xz
curl -fsSL "$(jq -r .sig release.json)" -o tor-browser.tar.xz.asc

# https://support.torproject.org/tbb/how-to-verify-signature/, with a keyring of its own outside ~/.gnupg.
export GNUPGHOME="$WORK/gnupg"
install -d -m 700 "$GNUPGHOME"
gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org
gpg --verify tor-browser.tar.xz.asc tor-browser.tar.xz

# Tor Browser updates itself in place, so each account keeps its own copy.
rm -rf ~/.local/tor-browser
mkdir -p ~/.local/tor-browser
tar -xf tor-browser.tar.xz -C ~/.local/tor-browser --strip-components=1

# The launcher's shebang, ./Browser/execdesktop, resolves against the current directory.
cd ~/.local/tor-browser || exit
./start-tor-browser.desktop --register-app
