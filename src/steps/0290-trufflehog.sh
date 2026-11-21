#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Secret scanner, https://github.com/trufflesecurity/trufflehog#using-installation-script
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b "$HOME/.local/bin"

rc_block ~/.zshrc <<'EOF'
source <("$HOME/.local/bin/trufflehog" --completion-script-zsh)
EOF
