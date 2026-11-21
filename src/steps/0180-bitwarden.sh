#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  deb_install bitwarden 'https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb'
fi
