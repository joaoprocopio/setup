#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://herdr.dev
curl -fsSL https://herdr.dev/install.sh | sh

rc_block ~/.zshrc <<'EOF'
source <("$HOME/.local/bin/herdr" completion zsh)
EOF
