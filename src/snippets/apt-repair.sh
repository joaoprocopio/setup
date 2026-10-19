#!/usr/bin/env bash
set -euo pipefail

# Wait up to this many seconds for another apt or dpkg process to release
# its lock, instead of failing at once.
readonly lock_timeout=120

sudo dpkg --configure -a
sudo apt-get -o DPkg::Lock::Timeout="$lock_timeout" clean

# Only index files contain "_". The filter keeps `lock`, `partial/`, and
# `auxfiles/`, which a running apt process still needs.
sudo find /var/lib/apt/lists -maxdepth 1 -type f -name '*_*' -delete

sudo apt-get -o DPkg::Lock::Timeout="$lock_timeout" update
