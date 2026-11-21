#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://ghostty.org/docs/install/build
GHOSTTY_VERSION="1.3.1"
GHOSTTY_PUBLIC_KEY="RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV"
GHOSTTY_DIR="ghostty-$GHOSTTY_VERSION"

# Ghostty builds only with the minimum_zig_version in its build.zig.zon, so Zig lives in $WORK.
ZIG_VERSION="0.15.2"
ZIG_PUBLIC_KEY="RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U"
ZIG_DIR="zig-x86_64-linux-$ZIG_VERSION"

# Downloads <url> and <url>.minisig into the current directory and checks the signature.
fetch_signed() {
  curl -#fSLO "$1"
  curl -fsSLO "$1.minisig"
  minisign -Vm "$(basename "$1")" -P "$2"
}

if is_admin; then
  # https://ghostty.org/docs/install/build#debian-and-ubuntu, plus libegl-dev for the system EGL.
  apt_install minisign \
    libgtk-4-dev libgtk4-layer-shell-dev libadwaita-1-dev libegl-dev gettext libxml2-utils blueprint-compiler
fi

cd "$WORK" || exit

fetch_signed "https://ziglang.org/download/$ZIG_VERSION/$ZIG_DIR.tar.xz" "$ZIG_PUBLIC_KEY"
tar -xf "$ZIG_DIR.tar.xz"

fetch_signed "https://release.files.ghostty.org/$GHOSTTY_VERSION/$GHOSTTY_DIR.tar.gz" "$GHOSTTY_PUBLIC_KEY"
tar -xf "$GHOSTTY_DIR.tar.gz"

cd "$GHOSTTY_DIR" || exit
# -p also sets the binary path in the desktop file and the D-Bus and systemd services.
"$WORK/$ZIG_DIR/zig" build -p "$HOME/.local" -Doptimize=ReleaseFast

# Follows the GNOME light or dark preference without a restart.
mkdir -p "$HOME/.config/ghostty"
rc_block "$HOME/.config/ghostty/config" <<'CONF'
theme = light:Adwaita,dark:Adwaita Dark
CONF
