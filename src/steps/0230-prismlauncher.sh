#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  # https://prismlauncher.org/download/linux/
  apt_source prismlauncher https://prism-launcher-for-debian.github.io/repo/prismlauncher.gpg https://prism-launcher-for-debian.github.io/repo "$CODENAME" main
  apt_install prismlauncher
fi
