#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Terminal workspace manager for AI coding agents, https://herdr.dev/tui/docs/install/
# Installs the latest release into ~/.local/bin after checking its SHA-256.
# Run this step again to update it, or run `herdr update`.
curl -fsSL https://herdr.dev/install.sh | sh

rc_block ~/.zshrc <<'EOF2'
source <("$HOME/.local/bin/herdr" completion zsh)
EOF2

# config.toml is deep-merged instead of copied, so keys set in Herdr's
# settings or by hand survive and keys set here win. yq comes from the yq
# step, and its merge replaces an array such as [[keys.command]] whole.
config=~/.config/herdr/config.toml
live=()
if [ -f "$config" ]; then live=("$config"); fi
"$HOME/.local/bin/yq" -p toml -o toml eval-all '. as $s ireduce ({}; . * $s)' \
  "${live[@]}" "$ASSETS/config.toml" >"$WORK/config.toml"
mkdir -p ~/.config/herdr
rsync --checksum --itemize-changes "$WORK/config.toml" "$config"
"$HOME/.local/bin/herdr" config check

note "um server do herdr que já está rodando só lê a config nova depois de \`herdr server reload-config\`"
