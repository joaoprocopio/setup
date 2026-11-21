#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

user() {
  # mikefarah's yq, https://github.com/mikefarah/yq#install
  # Debian's yq package is a different tool, kislyuk's Python wrapper around
  # jq. This installs the latest release binary into ~/.local/bin after
  # checking its SHA-256. Run this step again to update it.
  # GitHub redirects releases/latest to the page of the newest tag.
  tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/mikefarah/yq/releases/latest)"
  base="https://github.com/mikefarah/yq/releases/download/${tag##*/}"
  binary=yq_linux_amd64

  curl -#fSL "$base/$binary" -o "$WORK/$binary"

  # Each line of the checksums file holds a file name and then one hash per
  # line of checksums_hashes_order, so the SHA-256 column sits one past the
  # position of SHA-256 in that list.
  curl -fsSL "$base/checksums_hashes_order" -o "$WORK/hashes_order"
  curl -fsSL "$base/checksums" -o "$WORK/checksums"
  column="$(grep -nx 'SHA-256' "$WORK/hashes_order" | cut -d: -f1)"
  sha256="$(awk -v name="$binary" -v col="$((column + 1))" '$1 == name { print $col }' "$WORK/checksums")"
  echo "$sha256  $WORK/$binary" | sha256sum --check --strict

  install -m 0755 "$WORK/$binary" "$HOME/.local/bin/yq"

  rc_block ~/.zshrc <<'EOF2'
source <("$HOME/.local/bin/yq" shell-completion zsh)
EOF2

  "$HOME/.local/bin/yq" --version
}

run_step "$@"
