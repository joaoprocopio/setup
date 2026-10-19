#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://docs.cloud.google.com/sdk/docs/install-sdk#deb
apt_source google-cloud-sdk https://packages.cloud.google.com/apt/doc/apt-key.gpg https://packages.cloud.google.com/apt cloud-sdk main
apt_install google-cloud-cli

note "rode \`gcloud init\` para autenticar e escolher o projeto padrão"
