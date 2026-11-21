#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Postman updates itself in place, so each account keeps its own copy.
rm -rf ~/.local/postman
mkdir -p ~/.local/postman
curl -#fSL 'https://dl.pstmn.io/download/latest/linux_64' | tar -xz -C ~/.local/postman --strip-components=1

mkdir -p ~/.local/share/applications
cat >~/.local/share/applications/Postman.desktop <<EOF
[Desktop Entry]
Categories=Development;
Comment=Supercharge your API workflow
Exec=$HOME/.local/postman/Postman
Icon=$HOME/.local/postman/app/resources/app/assets/icon.png
Name=Postman
Terminal=false
Type=Application
Version=1.0
EOF
