#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

rc_block ~/.zshrc <<'EOF'
. "$HOME/.cargo/env"
EOF

# shellcheck source=/dev/null
. "$HOME/.cargo/env"

rustup update
rustup component add rust-analyzer
