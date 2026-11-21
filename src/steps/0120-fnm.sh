#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://github.com/Schniz/fnm#installation
curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell

# The recursive strategy reads .node-version or .nvmrc from parent directories, then falls back to the default.
rc_block ~/.zshrc <<'EOF'
eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
EOF

# The first node that fnm installs becomes the default.
fnm install --lts
