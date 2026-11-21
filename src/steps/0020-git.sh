#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  apt_install git
fi

# Each account types its own identity once, so no email lands in this public repository.
for key in user.name user.email; do
  if ! git config --global "$key" >/dev/null; then
    read -rp "git $key: " value
    [ -n "$value" ] || { echo "git: $key is empty" >&2; exit 1; }
    git config --global "$key" "$value"
  fi
done

printf '%s\n' '**/.idea/**' '**/.vscode/**' >~/.gitignore

# git config edits one key at a time, so keys from other tools survive.
git config --global init.defaultBranch main
git config --global core.excludesfile ~/.gitignore
git config --global core.autocrlf false
git config --global push.autoSetupRemote true
