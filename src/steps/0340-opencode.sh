#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://opencode.ai/docs/#install
curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path

rc_block ~/.zshrc <<'EOF'
export PATH="$HOME/.opencode/bin:$PATH"
EOF
