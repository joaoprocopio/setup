#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

system() {
  # https://github.com/cli/cli/blob/trunk/docs/install_linux.md
  apt_source github-cli https://cli.github.com/packages/githubcli-archive-keyring.gpg https://cli.github.com/packages stable main
  apt_install gh
}

user() {
  note "rode \`gh auth login\`"
}

run_step "$@"
