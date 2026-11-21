#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Secret scanner, https://github.com/gitleaks/gitleaks#installing, from the release, because Debian's package is years behind and upstream has no install script.
tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/gitleaks/gitleaks/releases/latest)"
version="${tag##*/v}"
tarball="gitleaks_${version}_linux_x64.tar.gz"
base="https://github.com/gitleaks/gitleaks/releases/download/v$version"

curl -#fSL "$base/$tarball" -o "$WORK/$tarball"
curl -fsSL "$base/gitleaks_${version}_checksums.txt" -o "$WORK/checksums.txt"
(cd "$WORK" && grep -F "  $tarball" checksums.txt | sha256sum --check --strict -)

mkdir "$WORK/gitleaks"
tar -xzf "$WORK/$tarball" -C "$WORK/gitleaks" gitleaks
install -m 0755 "$WORK/gitleaks/gitleaks" "$HOME/.local/bin/gitleaks"

rc_block ~/.zshrc <<'EOF'
source <("$HOME/.local/bin/gitleaks" completion zsh)
EOF
