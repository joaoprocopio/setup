#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

needs yq "$HOME/.local/bin/yq"

# Terminal workspace manager for AI coding agents, https://herdr.dev/tui/docs/install/
curl -fsSL https://herdr.dev/install.sh | sh

rc_block ~/.zshrc <<'EOF'
source <("$HOME/.local/bin/herdr" completion zsh)
EOF

# Deep-merges instead of copying, so keys set in Herdr survive. The merge replaces an array whole.
config=~/.config/herdr/config.toml
live=()
if [ -f "$config" ]; then live=("$config"); fi
# shellcheck disable=SC2016
"$HOME/.local/bin/yq" -p toml -o toml eval-all '. as $s ireduce ({}; . * $s)' \
  "${live[@]}" "$ASSETS/config.toml" >"$WORK/config.toml"
mkdir -p ~/.config/herdr
rsync --checksum --itemize-changes "$WORK/config.toml" "$config"
"$HOME/.local/bin/herdr" config check

note "a running herdr server reads the new config only after \`herdr server reload-config\`"
