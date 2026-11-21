#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

system() {
  # https://docs.docker.com/engine/install/debian/
  # Removes the distro packages that conflict with Docker's own.
  mapfile -t conflicting < <(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc 2>/dev/null | cut -f1)
  if [ ${#conflicting[@]} -gt 0 ]; then
    sudo apt-get remove --yes "${conflicting[@]}"
  fi

  # The last three packages are for the rootless daemon of the accounts
  # without sudo, see user() below.
  apt_source docker https://download.docker.com/linux/debian/gpg https://download.docker.com/linux/debian "$CODENAME" stable
  apt_install \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin \
    docker-ce-rootless-extras uidmap dbus-user-session

  # https://docs.docker.com/engine/install/linux-postinstall/
  # Only the admin account joins the docker group. The group is root-equivalent,
  # and this account already has root through sudo. The other accounts must not
  # join it, and get their own rootless daemon instead.
  sudo groupadd --force docker
  sudo usermod -aG docker "$USER"
  sudo systemctl enable docker.service containerd.service
}

user() {
  if [ -n "$ADMIN" ]; then
    # The new group applies only from the next login, so sg runs the smoke test with it now.
    sg docker -c "docker run --rm hello-world"
    note "saia da sessão e entre de novo para usar o docker sem sudo"
    return
  fi

  # https://docs.docker.com/engine/security/rootless/
  # An account without sudo runs its own dockerd, with no root, as long as
  # /etc/subuid and /etc/subgid give it at least 65,536 subordinate IDs.
  # adduser normally creates that range.
  if ! grep -q "^$USER:" /etc/subuid || ! grep -q "^$USER:" /etc/subgid; then
    echo "docker: a conta $USER não tem faixa de IDs em /etc/subuid e /etc/subgid, e o docker rootless precisa de 65.536 IDs ou mais." >&2
    echo "docker: a conta admin cria a faixa, sem se sobrepor às que já existem, com: sudo usermod --add-subuids A-B --add-subgids A-B $USER" >&2
    exit 1
  fi

  # No --force: the setuptool aborts only when /var/run/docker.sock is
  # writable, and it is not for an account outside the docker group. It needs
  # a real login session, with XDG_RUNTIME_DIR, so it fails under su or sudo.
  # It creates the `rootless` CLI context and switches to it.
  dockerd-rootless-setuptool.sh install

  # Some tools ignore CLI contexts and read only DOCKER_HOST. The single
  # quotes make $XDG_RUNTIME_DIR expand when the shell starts.
  rc_block ~/.zshrc <<'EOF'
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"
EOF

  docker run --rm hello-world
  note "o docker desta conta roda só enquanto a conta está logada (sem linger, de propósito, veja o passo gnome), e portas abaixo de 1024 não funcionam no rootless: use 8080 no lugar de 80"
}

run_step "$@"
