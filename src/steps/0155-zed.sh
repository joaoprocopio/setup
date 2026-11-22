#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Official installer, which unpacks into ~/.local/zed.app and adds the desktop file: https://zed.dev/docs/linux
curl -fsSL https://zed.dev/install.sh -o "$WORK/zed-install.sh"
TMPDIR="$WORK" sh "$WORK/zed-install.sh"
