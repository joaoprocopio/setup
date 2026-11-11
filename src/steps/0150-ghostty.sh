#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://ghostty.org/docs/install/build
GHOSTTY_VERSION="1.3.1"
GHOSTTY_PUBLIC_KEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"
GHOSTTY_DIR="ghostty-$GHOSTTY_VERSION"

# Ghostty builds with exactly one Zig version, the minimum_zig_version in
# its build.zig.zon (0.15.2 for 1.3.1), so Zig exists only for this build and
# goes away with $WORK.
ZIG_VERSION="0.15.2"
ZIG_PUBLIC_KEY="RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U"
ZIG_DIR="zig-x86_64-linux-$ZIG_VERSION"

# https://ghostty.org/docs/install/build#debian-and-ubuntu
# Ghostty also links the system EGL (pkg-config egl), which libegl-dev provides.
apt_install minisign \
  libgtk-4-dev libgtk4-layer-shell-dev libadwaita-1-dev libegl-dev gettext libxml2-utils blueprint-compiler

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

fetch_signed "https://release.files.ghostty.org/$GHOSTTY_VERSION/$GHOSTTY_DIR.tar.gz" "$GHOSTTY_PUBLIC_KEY"
tar -xf "$GHOSTTY_DIR.tar.gz"

cd "$GHOSTTY_DIR"
# 1.3.1 writes $HOME/.local/bin/ghostty into the desktop file, D-Bus and
# systemd services on its own, since it derives that path from -p.
"$WORK/$ZIG_DIR/zig" build -p "$HOME/.local" -Doptimize=ReleaseFast

# Ghostty reads the GNOME light or dark preference and swaps the theme live,
# so the terminal follows Settings > Appearance without a restart.
mkdir -p "$HOME/.config/ghostty"
rc_block "$HOME/.config/ghostty/config" <<'CONF'
theme = light:Adwaita,dark:Adwaita Dark
CONF
