#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Postman updates itself in place, so you own /opt/Postman, not root.
sudo rm -rf /opt/Postman
sudo install -d -o "$USER" /opt/Postman
curl -#fSL 'https://dl.pstmn.io/download/latest/linux_64' | tar -xz -C /opt/Postman --strip-components=1

mkdir -p ~/.local/share/applications
cat >~/.local/share/applications/Postman.desktop <<'EOF'
[Desktop Entry]
Categories=Development;
Comment=Supercharge your API workflow
Exec=/opt/Postman/Postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Name=Postman
Terminal=false
Type=Application
Version=1.0
EOF
