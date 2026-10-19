#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://ghostty.org/docs/install/build
GHOSTTY_VERSION="1.3.1"
GHOSTTY_PUBLIC_KEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"

# Each Ghostty release builds with exactly one Zig version (1.3.x needs
# 0.15.2), so Zig exists only for this build and goes away with $WORK.
ZIG_VERSION="0.15.2"
ZIG_PUBLIC_KEY="RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U"
ZIG_DIR="zig-x86_64-linux-$ZIG_VERSION"

# https://ghostty.org/docs/install/build#debian-and-ubuntu
apt_install minisign \
  libgtk-4-dev libgtk4-layer-shell-dev libadwaita-1-dev gettext libxml2-utils blueprint-compiler

# Downloads <url> and its .minisig into the current directory, then checks
# the signature against <public-key>.
# usage: fetch_signed <url> <public-key>
fetch_signed() {
  curl -#fSLO "$1"
  curl -fsSLO "$1.minisig"
  minisign -Vm "$(basename "$1")" -P "$2"
}

cd "$WORK"

fetch_signed "https://ziglang.org/download/$ZIG_VERSION/$ZIG_DIR.tar.xz" "$ZIG_PUBLIC_KEY"
tar -xf "$ZIG_DIR.tar.xz"

fetch_signed "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz" "$GHOSTTY_PUBLIC_KEY"
tar -xf "ghostty-$GHOSTTY_VERSION.tar.gz"

cd "ghostty-$GHOSTTY_VERSION"
"$WORK/$ZIG_DIR/zig" build -p "$HOME/.local" -Doptimize=ReleaseFast

# Ghostty reads the GNOME light or dark preference and swaps the theme live,
# so the terminal follows Settings > Appearance without a restart.
mkdir -p "$HOME/.config/ghostty"
rc_block "$HOME/.config/ghostty/config" <<'CONF'
theme = light:Adwaita,dark:Adwaita Dark
CONF
