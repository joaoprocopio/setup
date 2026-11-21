#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  # https://docs.docker.com/engine/install/debian/
  mapfile -t conflicting < <(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc 2>/dev/null | cut -f1)
  if [ ${#conflicting[@]} -gt 0 ]; then
    sudo apt-get remove --yes "${conflicting[@]}"
  fi

  # The last three packages run the rootless daemon of a --no-admin account.
  apt_source docker https://download.docker.com/linux/debian/gpg https://download.docker.com/linux/debian "$CODENAME" stable
  apt_install \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin \
    docker-ce-rootless-extras uidmap dbus-user-session

  # The docker group is root-equivalent, so only the account that already has sudo joins it, https://docs.docker.com/engine/install/linux-postinstall/
  sudo groupadd --force docker
  sudo usermod -aG docker "$USER"
  sudo systemctl enable docker.service containerd.service

  # sg applies the new group now, before the next login.
  sg docker -c "docker run --rm hello-world"
  note "log out and back in to use docker without sudo"
else
  # https://docs.docker.com/engine/security/rootless/
  if ! grep -q "^$USER:" /etc/subuid || ! grep -q "^$USER:" /etc/subgid; then
    echo "docker: $USER has no range in /etc/subuid and /etc/subgid, and rootless docker needs 65,536 IDs." >&2
    echo "docker: from the admin account, run: sudo usermod --add-subuids A-B --add-subgids A-B $USER" >&2
    exit 1
  fi

  # Needs a real login session with XDG_RUNTIME_DIR, so it fails under su or sudo.
  dockerd-rootless-setuptool.sh install

  # Some tools ignore docker contexts and read only DOCKER_HOST.
  rc_block ~/.zshrc <<'EOF'
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"
EOF

  docker run --rm hello-world
  note "rootless docker runs only while you are logged in, and ports below 1024 fail: use 8080, not 80"
fi
