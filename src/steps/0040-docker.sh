#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://docs.docker.com/engine/install/debian/
# Removes the distro packages that conflict with Docker's own.
mapfile -t conflicting < <(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc 2>/dev/null | cut -f1)
if [ ${#conflicting[@]} -gt 0 ]; then
  sudo apt-get remove --yes "${conflicting[@]}"
fi

apt_source docker https://download.docker.com/linux/debian/gpg https://download.docker.com/linux/debian "$CODENAME" stable
apt_install \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# https://docs.docker.com/engine/install/linux-postinstall/
sudo groupadd --force docker
sudo usermod -aG docker "$USER"
sudo systemctl enable docker.service containerd.service

# The new group applies only from the next login, so sg runs the smoke test with it now.
sg docker -c "docker run --rm hello-world"
note "saia da sessão e entre de novo para usar o docker sem sudo"
