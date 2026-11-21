#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

system() {
  apt_install git
}

user() {
  # The identity comes from the profile file, which stays out of this public
  # repository, so each account commits as its own person.
  if [ -z "${GIT_NAME:-}" ] || [ -z "${GIT_EMAIL:-}" ]; then
    echo "git: falta GIT_NAME ou GIT_EMAIL em $PROFILE_FILE; rode src/install.sh para escolher o perfil" >&2
    exit 1
  fi

  printf '%s\n' '**/.idea/**' '**/.vscode/**' >~/.gitignore

  # git config edits one key at a time, so keys written by other tools, such
  # as the credential helper from `gh auth setup-git`, survive a second run.
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  git config --global init.defaultBranch main
  git config --global core.excludesfile ~/.gitignore
  git config --global core.autocrlf false
  git config --global push.autoSetupRemote true
}

run_step "$@"
