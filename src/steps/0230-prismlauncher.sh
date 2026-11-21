#!/usr/bin/env bash
# profile: pessoal
source "$(dirname "$0")/../lib.sh"

system() {
  # https://prismlauncher.org/download/linux/
  apt_source prismlauncher https://prism-launcher-for-debian.github.io/repo/prismlauncher.gpg https://prism-launcher-for-debian.github.io/repo "$CODENAME" main
  apt_install prismlauncher
}

run_step "$@"
