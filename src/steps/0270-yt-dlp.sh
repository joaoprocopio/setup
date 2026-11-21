#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

needs uv

# The default extra brings yt-dlp-ejs, which solves YouTube's JavaScript challenges, https://github.com/yt-dlp/yt-dlp#installation
uv tool install --upgrade "yt-dlp[default]"

# yt-dlp-ejs needs a JavaScript runtime, and yt-dlp enables only deno by default.
mkdir -p ~/.config/yt-dlp
rc_block ~/.config/yt-dlp/config <<'EOF'
--js-runtimes node
EOF
