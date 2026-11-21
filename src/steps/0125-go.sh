#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://go.dev/doc/install, with the hash from https://go.dev/dl/?mode=json
GO_VERSION=1.27.4
GO_SHA256=7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840

if is_admin; then
  curl -#fSL "https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz" -o "$WORK/go.tar.gz"
  echo "$GO_SHA256  $WORK/go.tar.gz" | sha256sum --check

  # Extracting over the old tree leaves files from the previous version behind.
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$WORK/go.tar.gz"
fi

rc_block ~/.zshrc <<'EOF'
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
EOF

/usr/local/go/bin/go version
