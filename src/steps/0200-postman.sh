#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

user() {
  # Postman updates itself in place, so each account keeps its own copy in
  # its home, and none of them needs root.
  rm -rf ~/.local/opt/Postman
  mkdir -p ~/.local/opt/Postman
  curl -#fSL 'https://dl.pstmn.io/download/latest/linux_64' | tar -xz -C ~/.local/opt/Postman --strip-components=1

  mkdir -p ~/.local/share/applications
  cat >~/.local/share/applications/Postman.desktop <<EOF
[Desktop Entry]
Categories=Development;
Comment=Supercharge your API workflow
Exec=$HOME/.local/opt/Postman/Postman
Icon=$HOME/.local/opt/Postman/app/resources/app/assets/icon.png
Name=Postman
Terminal=false
Type=Application
Version=1.0
EOF
}

run_step "$@"
