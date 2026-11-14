#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://support.mozilla.org/kb/install-firefox-linux#w_install-firefox-deb-package-for-debian-based-distributions
# Mozilla's own repository ships the rapid release, which Debian's
# firefox-esr trails by months.
apt_source mozilla https://packages.mozilla.org/apt/repo-signing-key.gpg https://packages.mozilla.org/apt mozilla main

# The pin makes apt prefer Mozilla's packages over any Debian package of
# the same name.
sudo tee /etc/apt/preferences.d/mozilla >/dev/null <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

apt_install firefox
