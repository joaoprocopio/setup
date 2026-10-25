#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://github.com/yt-dlp/yt-dlp#installation
# uv puts yt-dlp in ~/.local/bin, and `uv tool upgrade yt-dlp` updates it.
# The default extra brings yt-dlp-ejs, which solves YouTube's JavaScript
# challenges. ffmpeg, which merges audio and video, comes from the base step.
uv tool install --upgrade "yt-dlp[default]"

# yt-dlp-ejs needs a JavaScript runtime, and yt-dlp enables only deno by
# default. This enables the node that the fnm step installs.
mkdir -p ~/.config/yt-dlp
rc_block ~/.config/yt-dlp/config <<'EOF2'
--js-runtimes node
EOF2
