#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# mikefarah's yq, https://github.com/mikefarah/yq#install, because Debian's yq is a different tool.
tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/mikefarah/yq/releases/latest)"
base="https://github.com/mikefarah/yq/releases/download/${tag##*/}"
binary=yq_linux_amd64

curl -#fSL "$base/$binary" -o "$WORK/$binary"

# The checksums file has one hash column per line of checksums_hashes_order, after the file name.
curl -fsSL "$base/checksums_hashes_order" -o "$WORK/hashes_order"
curl -fsSL "$base/checksums" -o "$WORK/checksums"
column="$(grep -nx 'SHA-256' "$WORK/hashes_order" | cut -d: -f1)"
sha256="$(awk -v name="$binary" -v col="$((column + 1))" '$1 == name { print $col }' "$WORK/checksums")"
echo "$sha256  $WORK/$binary" | sha256sum --check --strict

install -m 0755 "$WORK/$binary" "$HOME/.local/bin/yq"

rc_block ~/.zshrc <<'EOF'
source <("$HOME/.local/bin/yq" shell-completion zsh)
EOF

"$HOME/.local/bin/yq" --version
