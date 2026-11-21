#!/usr/bin/env bash
# profile: pessoal
source "$(dirname "$0")/../lib.sh"

system() {
  apt_install ffmpeg obs-studio
}

run_step "$@"
