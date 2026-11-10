#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://tb-manual.torproject.org/installation/
# The Tor Project deletes old releases from its dist server, so the step
# asks the update feed for the current one.
cd "$WORK"
curl -fsSL https://aus1.torproject.org/torbrowser/update_3/release/download-linux-x86_64.json -o release.json
curl -#fSL "$(jq -r .binary release.json)" -o tor-browser.tar.xz
curl -fsSL "$(jq -r .sig release.json)" -o tor-browser.tar.xz.asc

# https://support.torproject.org/tbb/how-to-verify-signature/
# A keyring of its own keeps the signing key out of your ~/.gnupg.
export GNUPGHOME="$WORK/gnupg"
install -d -m 700 "$GNUPGHOME"
gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org
gpg --verify tor-browser.tar.xz.asc tor-browser.tar.xz

# Tor Browser updates itself in place, so you own /opt/tor-browser, not root.
sudo rm -rf /opt/tor-browser
sudo install -d -o "$USER" /opt/tor-browser
tar -xf tor-browser.tar.xz -C /opt/tor-browser --strip-components=1

# The launcher's shebang, ./Browser/execdesktop, resolves against the
# current directory, so the step runs it from /opt/tor-browser.
cd /opt/tor-browser
./start-tor-browser.desktop --register-app
