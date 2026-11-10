#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Secret scanner, https://github.com/trufflesecurity/trufflehog#using-installation-script
# Installs the latest release into ~/.local/bin after checking its SHA-256.
# Run this step again to update it.
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b "$HOME/.local/bin"

rc_block ~/.zshrc <<'EOF2'
source <("$HOME/.local/bin/trufflehog" --completion-script-zsh)
EOF2
