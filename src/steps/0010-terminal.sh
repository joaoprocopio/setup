#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

apt_install zsh git curl starship

# --unattended stops the installer from switching shells and from starting
# zsh, which would halt install.sh. It replaces ~/.zshrc with its template,
# so this step runs before every step that writes to ~/.zshrc.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$WORK/ohmyzsh.sh"
  sh "$WORK/ohmyzsh.sh" --unattended
fi

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
  sudo chsh -s "$(command -v zsh)" "$USER"
  note "saia da sessão e entre de novo para o zsh virar o seu shell"
fi

# starship preset -o fails when the directory is missing. Each run
# overwrites starship.toml, so edits to it do not survive a rerun.
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

rc_block ~/.bashrc <<'EOF'
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
EOF
