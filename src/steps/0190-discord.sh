#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  deb_install discord 'https://discord.com/api/download/stable?platform=linux&format=deb'
fi
