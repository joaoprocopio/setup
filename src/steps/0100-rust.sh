#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# -y skips the installer's menu. --no-modify-path leaves the shell profiles
# to rc_block below.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

rc_block ~/.zshrc <<'EOF'
. "$HOME/.cargo/env"
EOF

. "$HOME/.cargo/env"

rustup update
rustup component add rust-analyzer
