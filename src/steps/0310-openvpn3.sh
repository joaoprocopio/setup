#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

system() {
  # https://community.openvpn.net/Pages/OpenVPN3Linux
  apt_source openvpn3 https://packages.openvpn.net/packages-repo.gpg https://packages.openvpn.net/openvpn3/debian "$CODENAME" main
  apt_install openvpn3-client
}

user() {
  note "rode \`openvpn3 config-import --config <arquivo>.ovpn --persistent\` para importar o seu perfil"
}

run_step "$@"
