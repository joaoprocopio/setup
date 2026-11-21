#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

if is_admin; then
  apt_install ffmpeg obs-studio
fi
