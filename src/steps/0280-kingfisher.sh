#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  # Secret scanner. No apt repository backs this .deb, so rerun the step to update it.
  deb_install kingfisher https://github.com/mongodb/kingfisher/releases/latest/download/kingfisher-linux-x64.deb
fi
