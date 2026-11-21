#!/usr/bin/env bash
# profile: pessoal
source "$(dirname "$0")/../lib.sh"

system() {
  deb_install discord 'https://discord.com/api/download/stable?platform=linux&format=deb'
}

run_step "$@"
