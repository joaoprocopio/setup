#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  # https://github.com/cli/cli/blob/trunk/docs/install_linux.md
  apt_source github-cli https://cli.github.com/packages/githubcli-archive-keyring.gpg https://cli.github.com/packages stable main
  apt_install gh
fi

note "run \`gh auth login\`"
