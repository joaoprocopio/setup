#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://github.com/Schniz/fnm#installation
# --install-dir puts the binary in ~/.local/bin, which is already on PATH.
# --skip-shell stops the installer from editing ~/.zshrc; rc_block below
# writes the setup instead.
curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell

# --use-on-cd switches node on every cd. The recursive strategy looks for
# .node-version or .nvmrc in parent directories too, and falls back to the
# default version when it finds none.
rc_block ~/.zshrc <<'EOF'
eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
EOF

# The first node fnm installs becomes its default.
fnm install --lts
