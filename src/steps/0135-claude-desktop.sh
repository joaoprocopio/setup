#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  # https://code.claude.com/docs/en/desktop-linux
  # The package writes no claude-desktop.list while another apt source has its repository.
  apt_source claude-desktop https://downloads.claude.ai/claude-desktop/key.asc https://downloads.claude.ai/claude-desktop/apt/stable stable main
  apt_install claude-desktop
fi

# Cowork runs its tasks in a QEMU VM, and only kvm members can open /dev/vhost-vsock.
if [[ " $(id -nG "$USER") " != *" kvm "* ]]; then
  if is_admin; then
    sudo usermod -aG kvm "$USER"
    note "log out and back in, so Cowork gets the kvm group"
  else
    note "for Cowork, run \`sudo usermod -aG kvm $USER\` from the admin account, then log out and back in"
  fi
fi
