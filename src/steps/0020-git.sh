#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

apt_install git

printf '%s\n' '**/.idea/**' '**/.vscode/**' >~/.gitignore

# git config edits one key at a time, so keys written by other tools, such
# as the credential helper from `gh auth setup-git`, survive a second run.
git config --global user.name joaoprocopio
git config --global user.email joaovitorcprocopio@gmail.com
git config --global init.defaultBranch main
git config --global core.excludesfile ~/.gitignore
git config --global core.autocrlf false
git config --global push.autoSetupRemote true
