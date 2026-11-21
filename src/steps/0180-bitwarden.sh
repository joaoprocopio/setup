#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

system() {
  deb_install bitwarden 'https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb'
}

run_step "$@"
