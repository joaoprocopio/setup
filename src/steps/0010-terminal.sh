#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  apt_install zsh git curl starship
fi

# --unattended keeps the installer from switching shells and starting zsh. It replaces ~/.zshrc, so this step runs first.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$WORK/ohmyzsh.sh"
  sh "$WORK/ohmyzsh.sh" --unattended
fi

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  if is_admin; then
    sudo chsh -s "$(command -v zsh)" "$USER"
    note "log out and back in to make zsh your shell"
  else
    note "ask the admin account to run \`sudo chsh -s $(command -v zsh) $USER\`, then log out and back in"
  fi
fi

# Each run overwrites starship.toml.
mkdir -p ~/.config
starship preset plain-text-symbols -o ~/.config/starship.toml

rc_block ~/.zshrc <<'EOF'
alias docker-compose="docker compose"
alias k="kubectl"
alias dk="docker"
alias dkc="docker compose"
alias ls="ls --color=auto"
alias ll="ls -lhaF --group-directories-first"

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

eval "$(starship init zsh)"
EOF

# Every zsh reads ~/.zshenv, so an unmatched glob in `zsh -c` passes through instead of aborting.
rc_block ~/.zshenv <<'EOF'
setopt NO_NOMATCH
EOF

rc_block ~/.bashrc <<'EOF'
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
EOF
