#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  # https://tailscale.com/docs/install/linux
  apt_source tailscale "https://pkgs.tailscale.com/stable/debian/$CODENAME.noarmor.gpg" https://pkgs.tailscale.com/stable/debian "$CODENAME" main
  apt_install tailscale

  note "run \`sudo tailscale up\` to join the tailnet"
fi
