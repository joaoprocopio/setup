#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  # https://community.openvpn.net/Pages/OpenVPN3Linux
  apt_source openvpn3 https://packages.openvpn.net/packages-repo.gpg https://packages.openvpn.net/openvpn3/debian "$CODENAME" main
  apt_install openvpn3-client
fi

note "run \`openvpn3 config-import --config <file>.ovpn --persistent\` to import your profile"
