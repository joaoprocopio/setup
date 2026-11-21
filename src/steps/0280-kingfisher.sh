#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  # Secret scanner, https://github.com/mongodb/kingfisher/blob/main/docs/INSTALLATION.md, from a .deb with no apt repository, so rerun the step to update it.
  deb_install kingfisher https://github.com/mongodb/kingfisher/releases/latest/download/kingfisher-linux-x64.deb
fi
